import Foundation

/// The "when to go" rule, parameterized because providers instruct differently:
/// 5-1-1 is the widely taught default for a first baby; 4-1-1 and 3-1-1 are common
/// variants. The numbers are exactly the stated rule — contractions every ≤N
/// minutes, lasting ≥1 minute, sustained for 1 hour. No fudge factors: the screen
/// shows the measurements next to the verdict, so a near-miss is visible as a
/// near-miss instead of being quietly rounded into a pass.
public enum GuidelineRule: String, CaseIterable, Codable, Sendable, Identifiable {
    case fiveOneOne
    case fourOneOne
    case threeOneOne

    public var id: String { rawValue }

    /// Start-to-start. Frequency is measured between the *beginnings* of
    /// contractions — measuring from end to next start understates it, and some
    /// timers get this wrong.
    public var intervalThreshold: Duration {
        switch self {
        case .fiveOneOne: .seconds(5 * 60)
        case .fourOneOne: .seconds(4 * 60)
        case .threeOneOne: .seconds(3 * 60)
        }
    }

    /// **The rule as stated** — "lasting about a minute". Copy names this number;
    /// `durationMet` does not (see `durationEvidenceThreshold`).
    public var durationThreshold: Duration { .seconds(60) }

    /// **What the boolean uses** (decision 0023). Timing starts at the tap, and a
    /// thumb taps start late — reaction time plus waiting to be sure it is real,
    /// measured at 3–25 s of median latency by profile — while tapping end when it
    /// ends. Recorded duration is therefore ≈ true duration − start latency, where
    /// start-to-start intervals cancel the latency out entirely. A hard 60 s gate
    /// against a systematically understated figure suppressed 46 of 221 truly-met
    /// scenarios in the first corpus run, and the suppressed users were precisely
    /// the exhausted ones.
    ///
    /// Ten seconds is the calibrated allowance: it recovers the typical-and-better
    /// population (5 suppressions at 8 s median latency) without accepting
    /// Braxton-Hicks lengths — a true 30–55 s tightening recorded minus its latency
    /// still fails at 50 s. Displayed figures are untouched: a 55 s average prints
    /// 0:55, so a near-miss stays visible as exactly what it is.
    public var durationEvidenceThreshold: Duration { .seconds(50) }

    public var sustainedWindow: Duration { .seconds(60 * 60) }

    /// The largest start-to-start gap that still counts as *the same pattern*
    /// (decision 0026): triple the spacing the rule promises. A pattern "every
    /// ≤5 minutes" with a 20-minute hole in it is not that pattern, and a fixed cap
    /// would be jitter at 5-1-1 and five missed cycles at 3-1-1 — so the multiplier
    /// scales with the rule the provider chose, exactly as the rule itself does.
    public var sustainedGapLimit: Duration { intervalThreshold * 3 }

    /// **Fast-met's floor** (decision 0040 §1): one third of the sustained window —
    /// twenty minutes at every rule, since `sustainedWindow` does not vary by rule.
    /// Below it, the evidence floor (six in window) can technically clear while the
    /// whole pattern is a ten-minute flurry, the kind false starts are made of. A
    /// third of the window is long enough that "pattern" is honest and short enough
    /// that a genuinely fast labor — which can deliver inside two hours — is told
    /// something useful in time to act.
    public var fastMetMinimumLength: Duration { sustainedWindow / 3 }

    public var label: String {
        switch self {
        case .fiveOneOne: "5-1-1"
        case .fourOneOne: "4-1-1"
        case .threeOneOne: "3-1-1"
        }
    }

    /// Where the selected rule is persisted, named once. Every surface that judges a
    /// pattern — the timer, the lock-screen intent — has to be answering the same
    /// question, and a second copy of this string is precisely how they stop
    /// (F-0013: the intent hard-coded 5-1-1 while the picker offered three).
    public static let defaultsKey = "guidelineRule"

    /// This device's rule, or the widely taught default for a first baby.
    public static func persisted(in defaults: UserDefaults = .standard) -> GuidelineRule {
        defaults.string(forKey: defaultsKey)
            .flatMap(GuidelineRule.init(rawValue:)) ?? .fiveOneOne
    }
}

/// Everything the timer screen shows, computed from the record of taps and a clock.
/// Figures are nil until there is enough evidence to mean something — the SP-053
/// rule reapplied: a confident average over two data points is a lie with decimals.
public struct LaborPattern: Equatable, Sendable {
    /// The live contraction, if one is running.
    public let running: Contraction?

    /// Contractions of the current episode, oldest first (completed and running).
    public let episode: [Contraction]

    /// When the current episode began — "how long has this been happening" starts
    /// here, not at app launch.
    public let episodeStart: Date?

    /// Elapsed since `episodeStart`. Floored at zero: a clock set backwards past the
    /// episode's own start would otherwise render a negative age, and there is no
    /// honest reading of "this has been happening for minus four minutes".
    public let patternLength: Duration?

    /// How many of the episode's contractions started inside the analysis window —
    /// the count the averages actually rest on.
    ///
    /// Exposed rather than re-derived by the screen: the window is one rule, and the
    /// guidance line has to be able to say *how much* evidence it is speaking from
    /// ("over 8 timed contractions"). A second copy of `now - sustainedWindow` living
    /// in a view is exactly the four-hand-rolled-copies problem `interval(from:to:)`
    /// exists to prevent.
    public let inWindowCount: Int

    /// Start-to-start gap between the last two contractions of the episode.
    public let lastInterval: Duration?

    /// Average start-to-start interval over the analysis window. Nil below two
    /// intervals — that is the floor for an average worth printing.
    ///
    /// Still the plain mean, and deliberately: "averaging every 4:50" is the figure
    /// providers ask for, and it stays the figure the screen prints. What changed
    /// (decision 0024) is that the *boolean* beside it no longer rests on it.
    public let averageInterval: Duration?

    /// Smallest and largest in-window start-to-start interval (decision 0024).
    ///
    /// A raw fact that makes bimodality visible instead of hiding it inside a mean:
    /// coupled back labor arrives in pairs whose mean is a value that never occurs,
    /// and "5:31–20:58" says so on the same row that prints 10:53. Nil below the
    /// same two-interval floor the average uses.
    public let intervalRange: ClosedRange<Duration>?

    /// Average duration over the analysis window, excluding suspect records
    /// (forgotten stop-taps would otherwise inflate exactly the figure the
    /// guideline needs to be honest about). Nil below three usable durations —
    /// two when a suspect is present (decision 0023 §2).
    public let averageDuration: Duration?

    /// How long the pattern has run **without a break in it**, capped at the rule's
    /// hour (decision 0026): time since the later of the episode's start and the end
    /// of the most recent continuity break inside the window.
    ///
    /// This is the quantity the tick tape renders. `patternLength` answers "how long
    /// has this been happening"; this answers "how much of it has been happening
    /// *continuously*", which is the question the sustained dimension actually asks.
    /// A lull visibly empties it.
    public let sustainedEvidence: Duration

    /// The verdict against the selected rule, or nil while the evidence floor
    /// isn't met. Per-dimension so the screen can say *which* parts of the rule
    /// the pattern meets — "frequency there, duration not yet" is actionable in a
    /// way a single boolean is not.
    public struct GuidelineStatus: Equatable, Sendable {
        public let rule: GuidelineRule
        public let frequencyMet: Bool
        public let durationMet: Bool
        public let sustainedMet: Bool

        /// **The early line** (decision 0040): strictly stronger than the rule on
        /// frequency and duration, early only on sustained. Fires iff — the
        /// evidence floor is met (it lives beside `frequencyMet` et al., inside the
        /// same floor-gated `if`); the frequency **share** holds at half the rule's
        /// interval threshold, the exact two-thirds machinery `frequencyMet` uses,
        /// evaluated at `rule.intervalThreshold / 2`; `durationMet` (unchanged —
        /// the rule's own bar, not a stricter one); no gap anywhere in the analysis
        /// window exceeds `rule.sustainedGapLimit`, the same continuity clause
        /// `sustainedMet` reads (0026); the pattern has run at least
        /// `rule.fastMetMinimumLength`; and NOT `met` — the full verdict outranks
        /// it and retires it the instant the hour completes.
        ///
        /// Half the threshold is a relational claim ("markedly inside what she was
        /// told to watch for"), never a fixed clinical number — it scales with
        /// whichever rule she chose and is the one number 0040 will defend.
        public let fastMet: Bool

        /// All three dimensions at once, as of this instant. The raw verdict: what
        /// the arithmetic says right now, and what the oracle checks exactly.
        public var met: Bool { frequencyMet && durationMet && sustainedMet }
    }

    public let guideline: GuidelineStatus?

    /// **The verdict the screen presents** (decision 0025, amended). `met`,
    /// latched: it turns true the instant `met` does and stays true until `met`
    /// has been continuously false for ten minutes. Derived statelessly — see
    /// `PatternAnalysis.presentedMet(for:rule:now:)`.
    ///
    /// A pattern-level field rather than a property of `GuidelineStatus`, and
    /// that move is the amendment: `GuidelineStatus` only exists where the
    /// evidence floor is met, so a latch living on it could not survive a window
    /// draining below the floor — exactly the retraction this decision exists to
    /// stop, and 54 of 69 measured flaps were that retraction rather than a
    /// dimension wobbling (F-0009's residual). At this surface the latch holds
    /// through a floor dip the same way it holds through a dimension wobble:
    /// decay through the floor and decay through the dimensions now read the
    /// same way.
    public let presentedMet: Bool

    /// **The fast-met verdict, latched exactly as `presentedMet` is** (decision
    /// 0040 §2: decision 0025's mechanism, the same ten minutes, reused rather
    /// than reinvented). `guideline.fastMet`, held true until it has been
    /// continuously raw-false for ten minutes. A pattern-level field for the same
    /// reason `presentedMet` is one: `guideline` only exists where the evidence
    /// floor is met, so a latch living on it could not survive a window draining
    /// below the floor.
    ///
    /// Retires immediately, not on its own ten-minute clock, the moment the raw
    /// verdict is met: `pattern(for:rule:now:)` short-circuits both latches at
    /// once when `guideline.met` is raw-true, so a fast-met banner never lingers
    /// past the instant the ordinary verdict takes over. `fastMet` is false by
    /// construction whenever `met` is true (see `GuidelineStatus.fastMet`), so
    /// nothing is lost by skipping the sampling walk there — there is no fast-true
    /// instant left for it to find.
    public let presentedFastMet: Bool

    public static let empty = LaborPattern(
        running: nil, episode: [], episodeStart: nil, patternLength: nil,
        inWindowCount: 0, lastInterval: nil, averageInterval: nil,
        intervalRange: nil, averageDuration: nil, sustainedEvidence: .zero,
        guideline: nil, presentedMet: false, presentedFastMet: false
    )
}

public enum PatternAnalysis {
    /// **The one definition of start-to-start**, which every surface must agree on:
    /// the gap between two contractions is measured beginning to beginning, the way
    /// providers measure it. Public and used by the screens as well as the analysis —
    /// four hand-rolled copies of this formula once existed, and the live readout,
    /// the timeline and History disagreeing about the same pair's interval is the
    /// one contradiction this product cannot afford.
    public static func interval(from earlier: Contraction, to later: Contraction) -> Duration {
        .seconds(later.startedAt.timeIntervalSince(earlier.startedAt))
    }

    /// Consecutive start-to-start intervals across a run ordered oldest-first.
    /// Empty for fewer than two contractions — one contraction has no gap.
    public static func startToStartIntervals(_ ordered: [Contraction]) -> [Duration] {
        zip(ordered.dropFirst(), ordered).map { interval(from: $1, to: $0) }
    }

    /// A gap of more than two hours between contraction starts ends an episode.
    /// Early labor stops and restarts across days; yesterday evening's cluster must
    /// not pollute tonight's averages, and "how long has this been happening" must
    /// answer for *this* stretch, not the pregnancy.
    public static let episodeGap: Duration = .seconds(2 * 60 * 60)

    /// Contractions needed inside the window before a guideline verdict renders.
    /// At the loosest rule's spacing (every 5 minutes) an hour holds twelve; six —
    /// half that — is the floor below which "the last hour met the rule" would rest
    /// on averages a couple of stray taps could swing.
    public static let guidelineEvidenceFloor = 6

    /// Usable durations needed before `averageDuration` prints. Three, normally —
    /// the same "an average over two points is a lie with decimals" floor the
    /// interval average uses.
    public static let durationEvidenceFloor = 3

    /// The floor when a suspect record sits in the window (decision 0023 §2).
    ///
    /// A forgotten stop-tap is itself evidence that a contraction happened and ran
    /// long. At the floor's edge — six in window, exactly three usable durations —
    /// one forgotten stop turned a fourth suspect, dropped the mean below its floor,
    /// and took the *whole* verdict with it, including the two dimensions that had
    /// nothing to do with duration (F-0007). The body had not changed; the app went
    /// quiet anyway. Relieving by one keeps the record's own evidence from nulling
    /// the reading it belongs to.
    public static let durationEvidenceFloorWithSuspect = 2

    /// **The frequency share** (decision 0024): at least this fraction of in-window
    /// intervals must sit at or under the rule's threshold. Stored as a rational and
    /// compared with integer arithmetic (`met * 3 >= total * 2`) so the exact 2/3
    /// case — four of six — is decided by the numbers rather than by a float.
    ///
    /// The mean it replaces is defeated by symmetry: coupled back labor alternating
    /// ~2 and ~8 minutes averages exactly 5:00, a value that never occurs and that
    /// no clinician reads as "every five minutes". A share cannot be gamed that way.
    /// Two-thirds is the harness-calibrated point — no measurable onset-lag cost on
    /// clean textbook streams, and the false-met probes go quiet.
    public static let frequencyShareNumerator = 2
    public static let frequencyShareDenominator = 3

    /// **The verdict's release delay** (decision 0025). Onset is immediate — the
    /// safety asymmetry forbids adding latency to the alarm side — but once the raw
    /// verdict has been true, the presented one holds until raw has been
    /// continuously false for this long. Ten minutes absorbs every wobble the corpus
    /// produced (worst observed flap spacing under 7 min) and still lets a genuine
    /// fizzle read honestly within one contraction's spacing.
    public static let latchRelease: Duration = .seconds(10 * 60)

    /// How finely the trailing window is sampled when deriving the latch. Thirty
    /// seconds is well under the timescale on which a windowed mean can cross its
    /// threshold and cross back, and it keeps the derivation to 21 evaluations.
    public static let latchSample: Duration = .seconds(30)

    /// Groups contractions (oldest first) into episodes split on `episodeGap`.
    public static func episodes(
        _ contractions: [Contraction],
        gap: Duration = episodeGap
    ) -> [[Contraction]] {
        let ordered = contractions.sorted { $0.startedAt < $1.startedAt }
        guard let first = ordered.first else { return [] }

        var result: [[Contraction]] = [[first]]
        for contraction in ordered.dropFirst() {
            let previousStart = result[result.count - 1].last!.startedAt
            let gapSeconds = contraction.startedAt.timeIntervalSince(previousStart)
            if Duration.seconds(gapSeconds) > gap {
                result.append([contraction])
            } else {
                result[result.count - 1].append(contraction)
            }
        }
        return result
    }

    /// The full pattern as of `now`, over whichever episode is still live.
    ///
    /// An episode whose last start is more than `episodeGap` ago is history, not a
    /// pattern — the readout goes back to its empty state rather than reporting
    /// stale averages as if they were happening.
    ///
    /// **Unless a contraction is running** (decision 0022): the staleness clock
    /// considers only *ended* contractions, because while a record is open the
    /// episode is live by definition. Without the guard a contraction still being
    /// timed at 2 h 1 m emptied the readout underneath its own live count — the
    /// screen offered first-launch onboarding copy over a running 121-minute timer
    /// (F-0004). This extends an episode's *visibility*, never a verdict: the
    /// sustained window and the evidence floors below are untouched.
    public static func pattern(
        for contractions: [Contraction],
        rule: GuidelineRule,
        now: Date = Date()
    ) -> LaborPattern {
        let raw = rawPattern(for: contractions, rule: rule, now: now)

        // The latch is a presentation smoother over an unchanged raw verdict, and
        // it is evaluated whenever the raw verdict says no right now — whether
        // because a `GuidelineStatus` rendered and failed, or because the evidence
        // floor withdrew the status entirely (the amendment). When raw is already
        // true the sampling loop would exit on its first step anyway, so only "the
        // raw verdict currently says no" pays the full derivation.
        //
        // This one guard retires `presentedFastMet` too (decision 0040 §1's last
        // clause): `raw.presentedFastMet` is already `false` here — `fastMet` is
        // false by construction whenever `met` is true — so returning `raw`
        // unmodified is "the ordinary verdict takes over and this state retires",
        // with no ten-minute grace period of its own at this boundary.
        guard raw.guideline?.met != true else { return raw }

        // One walk, both flags (HL-043). These were two calls doing the same work
        // twice and reading a different field off it.
        let latch = presentedLatch(for: contractions, rule: rule, now: now)
        return raw.presenting(presentedMet: latch.met, presentedFastMet: latch.fastMet)
    }

    // MARK: - The latched verdict (decision 0025)

    /// The verdict as the screen should present it: `met`, held for ten minutes
    /// after the raw verdict last said so.
    ///
    /// **Stateless, and that is the design.** No stored flag, no sticky bit — the
    /// same wall-clock truth the rest of this file runs on applies to the verdict
    /// too. The latch is *derived* from (records, rule, now) by re-evaluating the
    /// raw verdict at 30-second steps back across the trailing ten minutes, so a
    /// kill and relaunch mid-labor reproduces exactly the state that was on screen,
    /// and two devices holding the same records agree. A stored flag would have to
    /// be migrated, restored, invalidated on edit, and reasoned about at 3 am.
    ///
    /// Each past instant is judged against the records **as they stood then**
    /// (`records(_:asOf:)`): evaluating a past moment with the present record set
    /// would let contractions from the last ten minutes vote in a window they were
    /// not yet part of, and latch onto a verdict that was never raw-true. That is a
    /// false met, and false met is what the ranking law punishes.
    ///
    /// The boundary is closed on the latched side — a raw-true sample at exactly ten
    /// minutes ago still holds the verdict, and release comes one step later. Every
    /// other boundary in this engine closes the same way (a two-hour gap stays one
    /// episode, 5:00 exactly passes), and here it is also the safe direction: the
    /// error is one extra second of alarm, never one second less.
    public static func presentedMet(
        for contractions: [Contraction],
        rule: GuidelineRule,
        now: Date = Date()
    ) -> Bool {
        presentedLatch(for: contractions, rule: rule, now: now).met
    }

    /// **The fast-met verdict, latched exactly as `presentedMet` above is**
    /// (decision 0040 §2 reuses decision 0025's mechanism unchanged, ten minutes
    /// and all). Both read the same walk, which is what "structured identically"
    /// finally means now that there is only one structure.
    public static func presentedFastMet(
        for contractions: [Contraction],
        rule: GuidelineRule,
        now: Date = Date()
    ) -> Bool {
        presentedLatch(for: contractions, rule: rule, now: now).fastMet
    }

    /// **Both latched flags, from one backward walk** (HL-043).
    ///
    /// These were two functions, identical line for line except for reading `.met`
    /// or `.fastMet` off the same `rawPattern`, and `pattern(for:rule:now:)` called
    /// both — so every latched probe ran the pre-check twice, computed `atNow`
    /// twice, and walked the same ten minutes twice, re-deriving the same records
    /// and the same raw verdict at each step to read a different field off it.
    /// The harness measured that duplication at roughly 80% of LaborSim's runtime;
    /// on screen it is paid once a second by `TimelineView`.
    ///
    /// Fusing them is exact rather than approximate. Each flag asks "was the raw
    /// verdict true at *any* instant on the grid", and existence does not depend on
    /// the order the grid is walked or on which flag is being sought — so one pass
    /// that records both answers returns what two passes did. The loop now stops
    /// when **both** are known rather than when either is, which is the only
    /// behavioural difference and is invisible: it changes how soon the walk ends,
    /// never what it concludes.
    ///
    /// A cheap necessary-condition pre-check comes first, because it costs no
    /// `rawPattern` evaluation at all while everything below costs at least one.
    /// For the raw verdict to have been true at any instant `t` in the trailing ten
    /// minutes, that instant's own window `[t - sustainedWindow, t]` must have held
    /// at least `guidelineEvidenceFloor` contractions. Every such window, for every
    /// `t` in `[now - latchRelease, now]`, is a subset of the single interval
    /// `[now - sustainedWindow - latchRelease, now]` — so if that wider interval
    /// holds fewer starts than the floor, no window inside it can either, and both
    /// flags are provably false without walking the grid. It is shared between them
    /// on `fastMet`'s own argument: `fastMet` lives inside the identical
    /// `inWindow.count >= guidelineEvidenceFloor` gate `met` does — both are fields
    /// on the one `GuidelineStatus` computed inside that gate — so the wider
    /// interval either holds the floor for both or for neither.
    ///
    /// This is an optimisation, not a rule of its own: its correctness is kept
    /// honest by T0-02 oracle agreement, since `OracleMath` carries its own copy of
    /// the same arithmetic and the two are compared at every probe.
    static func presentedLatch(
        for contractions: [Contraction],
        rule: GuidelineRule,
        now: Date = Date()
    ) -> (met: Bool, fastMet: Bool) {
        let earliestPossibleWindowStart = now.addingTimeInterval(
            -(rule.sustainedWindow + latchRelease).timeInterval
        )
        let recentStarts = contractions.count {
            $0.startedAt >= earliestPossibleWindowStart && $0.startedAt <= now
        }
        guard recentStarts >= guidelineEvidenceFloor else { return (false, false) }

        let atNow = rawPattern(for: contractions, rule: rule, now: now)

        // The no-figures guard (the amendment's other half), and it applies to both
        // flags for one reason: a fast-met banner prints the same three bound figures
        // the met shape does (decision 0040 §3), so a held verdict beside three em
        // dashes would be the same assertion with nothing on screen behind it.
        // Checked against `now`'s own pattern, never a sampled past instant: a figure
        // that has since vanished cannot be resurrected by a verdict that used to
        // hold, which is why it lives here rather than only in the view — the oracle
        // and T0 both need to see it too.
        guard atNow.averageInterval != nil else { return (false, false) }

        var met = atNow.guideline?.met == true
        var fastMet = atNow.guideline?.fastMet == true

        var elapsed = latchSample
        while elapsed <= latchRelease, !(met && fastMet) {
            let instant = now.addingTimeInterval(-elapsed.timeInterval)
            let asThen = records(contractions, asOf: instant)
            let thenPattern = rawPattern(for: asThen, rule: rule, now: instant)
            if !met, thenPattern.guideline?.met == true { met = true }
            if !fastMet, thenPattern.guideline?.fastMet == true { fastMet = true }
            elapsed += latchSample
        }
        return (met, fastMet)
    }

    
    /// The record set as it stood at `instant`, reconstructed from the final one:
    /// contractions that had not started yet are dropped, and one that had started
    /// but not yet ended is handed back running, because that is what it was.
    ///
    /// Deletions and restores are invisible to this reconstruction — a record
    /// deleted since `instant` cannot be recovered from a set that no longer holds
    /// it. That is the honest cost of statelessness, and it is the harmless
    /// direction: a correction the user has already made never resurrects a verdict.
    public static func records(_ contractions: [Contraction], asOf instant: Date) -> [Contraction] {
        contractions.compactMap { record in
            guard record.startedAt <= instant else { return nil }
            guard let endedAt = record.endedAt, endedAt > instant else { return record }
            return Contraction(id: record.id, startedAt: record.startedAt, endedAt: nil)
        }
    }

    // MARK: - The raw pattern

    /// Everything `pattern(for:rule:now:)` reports, with `presentedMet` still equal
    /// to the raw `met`. Split out because the latch above evaluates this function
    /// twenty more times; keeping one implementation of the verdict — rather than a
    /// lean second copy for the sampling loop — is the same rule `interval(from:to:)`
    /// exists to enforce, and 21 evaluations of it remain far inside the frame.
    private static func rawPattern(
        for contractions: [Contraction],
        rule: GuidelineRule,
        now: Date
    ) -> LaborPattern {
        guard let episode = episodes(contractions).last,
              let latest = episode.last,
              let episodeStart = episode.first?.startedAt
        else { return .empty }

        let running = episode.last(where: { $0.endedAt == nil })
        let stale = Duration.seconds(now.timeIntervalSince(latest.startedAt)) > episodeGap
        guard running != nil || !stale else { return .empty }

        // The analysis window is the rule's sustained hour. Early in an episode the
        // window simply contains the whole episode; the screen labels accordingly.
        let windowStart = now.addingTimeInterval(-rule.sustainedWindow.timeInterval)
        let inWindow = episode.filter { $0.startedAt >= windowStart }

        // **The bridging interval** (decision 0023 §3). An interval whose *later*
        // endpoint starts in-window is last-hour evidence: it is the gap the reader
        // just lived through. Dropping it because its earlier endpoint predates the
        // window biased the average toward recent spacing and delayed every floor by
        // one contraction (F-0015). So the interval basis is the window plus the one
        // record immediately before it.
        let entry = episode.last { $0.startedAt < windowStart }
        let intervalBasis = entry.map { [$0] + inWindow } ?? inWindow
        let intervals = startToStartIntervals(intervalBasis)

        // Suspect durations are excluded, both ways a thumb misses (decision 0032):
        // a forgotten stop-tap runs long, a double tap records a few seconds, and
        // either one lands in the exact average the guideline's duration check reads.
        // Running records have no duration yet. Their *starts* still count above — a
        // tap is a tap, and a slip's start is one bad interval where its duration
        // would be one bad average.
        let usableDurations = inWindow
            .filter { !$0.isSuspect }
            .compactMap(\.duration)
        // **Only the long side relieves the floor**, and the asymmetry is the point.
        // Decision 0023 §2 relieves it because a forgotten stop-tap is itself evidence
        // that a contraction happened and ran long. A slip is evidence of nothing —
        // relieving the floor for one would let noise lower the bar for the verdict
        // it is noise in.
        let hasSuspect = inWindow.contains { $0.suspicion == .tooLong }
        let durationFloor = inWindow.count >= guidelineEvidenceFloor && hasSuspect
            ? durationEvidenceFloorWithSuspect
            : durationEvidenceFloor

        let averageInterval = intervals.count >= 2 ? intervals.mean : nil
        var intervalRange: ClosedRange<Duration>?
        if intervals.count >= 2, let shortest = intervals.min(), let longest = intervals.max() {
            intervalRange = shortest...longest
        }
        let averageDuration = usableDurations.count >= durationFloor ? usableDurations.mean : nil

        let allStarts = episode.map(\.startedAt)
        let lastInterval = allStarts.count >= 2
            ? Duration.seconds(allStarts[allStarts.count - 1].timeIntervalSince(allStarts[allStarts.count - 2]))
            : nil

        // Floored at zero (F-0011). `now` can legitimately precede `episodeStart`
        // after a backward clock set or a timezone correction; a negative age would
        // render as "-1 H -10 M" and, worse, would be a figure the screen presents as
        // a measurement. Zero is the honest floor — nothing has been happening for
        // less than no time.
        let patternLength = Duration.seconds(max(0, now.timeIntervalSince(episodeStart)))

        // Continuity (decision 0026). A gap over triple the rule's spacing is a
        // break, not jitter; the pattern's unbroken stretch is measured from the
        // later contraction of the newest such break, or from the episode's start
        // when there is none.
        var continuityAnchor = episodeStart
        for (index, gap) in intervals.enumerated() where gap > rule.sustainedGapLimit {
            continuityAnchor = max(continuityAnchor, intervalBasis[index + 1].startedAt)
        }
        //
        // One seam, stated rather than papered over: a break whose later contraction
        // sits *exactly* on the window edge reads a full hour of evidence while
        // `sustainedMet` below is false, because the dimension asks whether a break is
        // in the window and this figure asks how long since one. It lasts a single
        // second — the next tick carries that contraction out of the window and the
        // two agree again — and it errs toward the tape claiming more than the
        // verdict, never the reverse.
        let sustainedEvidence = min(
            Duration.seconds(max(0, now.timeIntervalSince(continuityAnchor))),
            rule.sustainedWindow
        )

        // The verdict needs the evidence floor and both averages. The interval mean
        // is no longer what `frequencyMet` reads, but its floor is still the claim
        // that there is enough spacing evidence to judge at all.
        var guideline: LaborPattern.GuidelineStatus?
        if inWindow.count >= guidelineEvidenceFloor,
           averageInterval != nil, let averageDuration {
            // The share, in integers: `met/total >= 2/3` without ever forming a
            // quotient, so four-of-six lands on the passing side by arithmetic
            // rather than by whatever a Double rounds 0.666… to.
            let withinThreshold = intervals.count { $0 <= rule.intervalThreshold }
            let frequencyMet = withinThreshold * frequencyShareDenominator
                >= intervals.count * frequencyShareNumerator

            // Sustained is the hour *and* the continuity: elapsed time is not a
            // sustained pattern, and six quick contractions either side of a
            // fifty-minute silence used to satisfy this (F-0010).
            let continuityHolds = (intervals.max() ?? .zero) <= rule.sustainedGapLimit
            let sustainedMet = patternLength >= rule.sustainedWindow && continuityHolds

            let durationMet = averageDuration >= rule.durationEvidenceThreshold
            let met = frequencyMet && durationMet && sustainedMet

            // Fast-met (decision 0040): the same two-thirds share machinery as
            // `frequencyMet`, evaluated at half the rule's threshold — decisively
            // tighter than the rule she chose, not a fixed clinical number.
            // Duration is the rule's own bar, unchanged. Continuity reuses
            // `sustainedMet`'s own clause: a burst-lull-burst is not a fast labor
            // any more than it is a sustained one (0026). `met` outranks it.
            let withinHalfThreshold = intervals.count { $0 <= rule.intervalThreshold / 2 }
            let fastFrequencyMet = withinHalfThreshold * frequencyShareDenominator
                >= intervals.count * frequencyShareNumerator
            let fastMet = fastFrequencyMet && durationMet && continuityHolds
                && patternLength >= rule.fastMetMinimumLength
                && !met

            guideline = LaborPattern.GuidelineStatus(
                rule: rule,
                frequencyMet: frequencyMet,
                durationMet: durationMet,
                sustainedMet: sustainedMet,
                fastMet: fastMet
            )
        }

        return LaborPattern(
            running: running,
            episode: episode,
            episodeStart: episodeStart,
            patternLength: patternLength,
            inWindowCount: inWindow.count,
            lastInterval: lastInterval,
            averageInterval: averageInterval,
            intervalRange: intervalRange,
            averageDuration: averageDuration,
            sustainedEvidence: sustainedEvidence,
            guideline: guideline,
            // The raw pattern's own presented figures are just the raw verdicts —
            // "everything `pattern(for:rule:now:)` reports, with `presentedMet`
            // still equal to the raw `met`" (see the doc comment on `rawPattern`
            // below), and the same for `presentedFastMet`/`fastMet`.
            // `pattern(for:rule:now:)` overrides both with their latched values
            // whenever raw currently says no.
            presentedMet: guideline?.met ?? false,
            presentedFastMet: guideline?.fastMet ?? false
        )
    }
}

extension LaborPattern {
    /// The same pattern carrying different presented verdicts. Exists so the
    /// latch can replace two fields of a `let`-only struct without a memberwise
    /// call site that would have to be updated every time this type grows a
    /// figure.
    fileprivate func presenting(presentedMet: Bool, presentedFastMet: Bool) -> LaborPattern {
        LaborPattern(
            running: running,
            episode: episode,
            episodeStart: episodeStart,
            patternLength: patternLength,
            inWindowCount: inWindowCount,
            lastInterval: lastInterval,
            averageInterval: averageInterval,
            intervalRange: intervalRange,
            averageDuration: averageDuration,
            sustainedEvidence: sustainedEvidence,
            guideline: guideline,
            presentedMet: presentedMet,
            presentedFastMet: presentedFastMet
        )
    }
}

// MARK: - Episode summaries

/// One past episode, condensed for the history list — the figures a provider
/// conversation actually uses: "Tuesday night, 14 contractions, averaging 4:50
/// apart, 1:02 long, over 1 h 8 m."
public struct EpisodeSummary: Equatable, Sendable {
    public let count: Int
    /// First start to last start — how long the stretch ran. **Nil for a lone
    /// contraction**, which has no span to speak of: printing "0 M" for it would be
    /// the same zero-as-measurement the averages' floors exist to prevent.
    public let span: Duration?
    /// Same evidence floors as the live readout: nil below three contractions,
    /// because a printed average must mean something in history too.
    public let averageInterval: Duration?
    /// Smallest and largest start-to-start interval over the whole episode
    /// (decision 0024, the whole-episode counterpart of `LaborPattern.intervalRange`)
    /// — the range that keeps `averageInterval` honest about a bimodal stretch a
    /// mean alone would hide. Nil below the same two-interval floor the average
    /// uses, and always present or absent *together* with it: the two describe one
    /// spread, and a sentence carrying one without the other would be printing a
    /// mean it cannot back up.
    public let intervalRange: ClosedRange<Duration>?
    public let averageDuration: Duration?
}

extension PatternAnalysis {
    /// Summarizes one episode (as `episodes(_:)` groups them). Pure and
    /// window-free — history judges the whole stretch, not the last hour.
    public static func summary(of episode: [Contraction]) -> EpisodeSummary? {
        let ordered = episode.sorted { $0.startedAt < $1.startedAt }
        guard let first = ordered.first, let last = ordered.last else { return nil }

        let intervals = startToStartIntervals(ordered)
        let usableDurations = ordered.filter { !$0.isSuspect }.compactMap(\.duration)

        var intervalRange: ClosedRange<Duration>?
        if intervals.count >= 2, let shortest = intervals.min(), let longest = intervals.max() {
            intervalRange = shortest...longest
        }

        return EpisodeSummary(
            count: ordered.count,
            span: ordered.count >= 2 ? interval(from: first, to: last) : nil,
            averageInterval: intervals.count >= 2 ? intervals.mean : nil,
            intervalRange: intervalRange,
            // No suspect relief and no bridging here: both are window rules, and
            // history has no window to bridge or to count suspects inside.
            averageDuration: usableDurations.count >= durationEvidenceFloor
                ? usableDurations.mean : nil
        )
    }
}

// MARK: - Trend (decision 0043)

/// This hour's windowed average against the hour before it — two evaluations of
/// one statistic, never a second one (decision 0043 §1). `direction` and both
/// figures are engine truth; the sentence that reads them is app-side
/// (`LaborFormat`), the same split `EpisodeSummary` keeps from
/// `LaborFormat.episodeSummaryLine`.
public struct LaborTrend: Equatable, Sendable {
    public enum Direction: Equatable, Sendable {
        /// The current window's average interval is shorter than the reference's.
        case closer
        /// The current window's average interval is longer than the reference's.
        case fartherApart
    }

    public let direction: Direction
    /// The windowed average the readout already prints.
    public let current: Duration
    /// The same statistic, one `rule.sustainedWindow` earlier.
    public let previous: Duration

    public init(direction: Direction, current: Duration, previous: Duration) {
        self.direction = direction
        self.current = current
        self.previous = previous
    }
}

extension PatternAnalysis {
    /// **The trend's noise floor** (decision 0043 §3): a delta under one-sixth of
    /// the reference average is jitter — about the size an honest thumb's
    /// tap-to-tap latency introduces (decision 0023's territory) — and prints no
    /// caption. Decided in whole seconds without ever forming a quotient:
    /// `|current − previous| * trendDeltaDenominator >= previous` fires the
    /// caption; under it, silence. The boundary is closed on the firing side —
    /// exactly one-sixth fires — the same convention every other boundary in this
    /// engine takes.
    public static let trendDeltaDenominator: Int64 = 6

    /// The windowed average as of `instant`, read off the identical code path
    /// `pattern(for:rule:now:)` uses for "now" — `records(_:asOf:)` reconstructs
    /// what the store held at `instant` (the same reconstruction the latch's own
    /// sampling loop already relies on), and `rawPattern` reads its trailing hour
    /// from there. There is no second window definition; this is `now` shifted.
    private static func windowedAverage(
        for contractions: [Contraction], rule: GuidelineRule, asOf instant: Date
    ) -> Duration? {
        rawPattern(for: records(contractions, asOf: instant), rule: rule, now: instant)
            .averageInterval
    }

    /// This hour against the hour before it (decision 0043). `current` is the
    /// average the readout already prints; `previous` is the *same statistic*, on
    /// the *same code path*, evaluated exactly one `rule.sustainedWindow` earlier.
    ///
    /// Nil unless both windows independently clear the average's own two-interval
    /// floor (§2: a caption comparing a real figure to a guess is worse than
    /// silence, and there is no em dash for an absent comparison) — which is also
    /// how a concluded or too-young episode falls silent here for free: an empty
    /// or stale `rawPattern` already withholds `averageInterval`, so nothing about
    /// episode liveness needs re-checking in this function.
    ///
    /// Nil again when the two figures are too close to be worth a sentence
    /// (§3, `trendDeltaDenominator`). A cleared delta implies `current != previous`
    /// in whole seconds, so `direction` is always well-defined wherever this
    /// returns non-nil.
    public static func trend(
        for contractions: [Contraction],
        rule: GuidelineRule,
        now: Date = Date()
    ) -> LaborTrend? {
        guard let current = windowedAverage(for: contractions, rule: rule, asOf: now)
        else { return nil }

        let referenceNow = now.addingTimeInterval(-rule.sustainedWindow.timeInterval)
        guard let previous = windowedAverage(for: contractions, rule: rule, asOf: referenceNow)
        else { return nil }

        // Whole seconds — the same truncation `LaborFormat.minutesSeconds` prints,
        // so the delta test can never disagree with the two figures the caption
        // shows, and the referee can restate this exactly in `Int64` without a
        // second rounding rule to keep in sync (SP-194).
        let currentSeconds = current.components.seconds
        let previousSeconds = previous.components.seconds
        let delta = abs(currentSeconds - previousSeconds)
        guard delta * trendDeltaDenominator >= previousSeconds else { return nil }

        return LaborTrend(
            direction: currentSeconds < previousSeconds ? .closer : .fartherApart,
            current: current,
            previous: previous
        )
    }
}

// MARK: - Tape geometry (decision 0037)

/// One contraction's position on the ember tape, normalized to the trailing window
/// `PatternAnalysis.tape(for:window:now:)` was asked for. Positions only — DesignKit
/// turns a bar into pixels; this type never speaks them, the same split `LaborPattern`
/// already keeps between measured figures and the screens that render them.
public struct TapeBar: Equatable, Sendable {
    /// Where the bar begins, as a fraction of the window: 0 is the window's left edge
    /// (the trailing hour's oldest instant), 1 is `now` at the right edge. Clipped to
    /// 0 when the contraction started before the window rather than dropped — decision
    /// 0037 §4's "bars march left and exit clipped mid-bar" is what a young tape and an
    /// aging-out bar both look like, and a dropped bar would silently lose the part of
    /// it that is still true.
    public let start: Double
    /// The bar's width, as a fraction of the window — true to scale, including a
    /// clipped bar's shortened visible span, except for the slip floor (see
    /// `PatternAnalysis.tapeSlipWidthFloor`).
    public let width: Double
    /// The contraction has not ended yet — its end (and so its width) is measured
    /// against `now` rather than a stored `endedAt`.
    public let isLive: Bool
    /// Carried through from `Contraction.suspicion` undisturbed. A suspect bar is
    /// drawn at true scale and flagged, never excluded (decision 0032 §1) — the tape
    /// is a raw-record surface and a suspect record is still a real tap at a real
    /// time.
    public let suspicion: Contraction.Suspicion?

    public init(start: Double, width: Double, isLive: Bool, suspicion: Contraction.Suspicion?) {
        self.start = start
        self.width = width
        self.isLive = isLive
        self.suspicion = suspicion
    }
}

/// The ember tape's geometry over one trailing window: every bar that has any part of
/// itself inside it, oldest first. Nothing about the analysis lives here — this is
/// presentation math over `LaborPattern`'s own raw record, same as `LaborFormat` is
/// presentation over its figures.
public struct TapeGeometry: Equatable, Sendable {
    public let bars: [TapeBar]

    public init(bars: [TapeBar]) {
        self.bars = bars
    }
}

extension PatternAnalysis {
    /// **A floor of visibility, not a lie of magnitude** (decision 0037 §5). Below
    /// this, a slip's true width is invisible on any width the tape is realistically
    /// drawn at — a contraction three or four seconds long is a sliver of a pixel on
    /// an hour-wide axis. Calibrated against the decision's own reference geometry (a
    /// 370 pt tape spanning the hour, where 1 pt is stated as the floor below which a
    /// bar stops existing) and expressed as a window fraction so the floor holds
    /// regardless of the device width DesignKit actually draws at, rather than a point
    /// value this package has no business knowing. Only a bar already under the floor
    /// is raised to it — a slip at exactly the floor or a believable contraction well
    /// above it are both left at their true width.
    public static let tapeSlipWidthFloor: Double = 1.0 / 370.0

    /// Normalizes a set of contractions to the ember tape's geometry: each bar's
    /// position and width as a fraction of the trailing `window`, right edge pinned to
    /// `now` (decision 0037 §1, §4). `window` is the caller's `rule.sustainedWindow` —
    /// this function has no opinion about which window is the right one, the same way
    /// `interval(from:to:)` has no opinion about which two contractions to measure.
    ///
    /// A contraction is included whenever any part of it falls inside the window — one
    /// that started before the window but ended inside it (or is still running) still
    /// belongs on the tape, clipped at the left edge rather than dropped (§4). One that
    /// ended before the window started, or that has not started yet relative to `now`,
    /// contributes nothing: it is not clipped, because none of it is true within the
    /// window's frame.
    public static func tape(
        for contractions: [Contraction],
        window: Duration,
        now: Date = Date()
    ) -> TapeGeometry {
        let windowSeconds = window.timeInterval
        guard windowSeconds > 0 else { return TapeGeometry(bars: []) }
        let windowStart = now.addingTimeInterval(-windowSeconds)

        let bars: [TapeBar] = contractions.compactMap { contraction in
            guard contraction.startedAt <= now else { return nil }
            let end = contraction.endedAt ?? now
            guard end >= windowStart else { return nil }

            let trueStart = contraction.startedAt.timeIntervalSince(windowStart) / windowSeconds
            let trueEnd = end.timeIntervalSince(windowStart) / windowSeconds

            // Clipped at the left edge only (§4): the right edge is `now` by
            // construction (`end` is bounded above by it), so nothing can run past 1
            // except float error, which `min` absorbs harmlessly.
            let start = max(0, trueStart)
            let clippedEnd = min(1, trueEnd)
            let width = max(clippedEnd - start, 0)

            // Only the short side gets a floor. A `.tooLong` bar dominating its
            // neighbours *is* the evidence (0037 §5) — nothing raises it, and nothing
            // shrinks it either.
            let flooredWidth = contraction.suspicion == .tooShort
                ? max(width, tapeSlipWidthFloor)
                : width

            return TapeBar(
                start: start,
                width: flooredWidth,
                isLive: contraction.endedAt == nil,
                suspicion: contraction.suspicion
            )
        }
        return TapeGeometry(bars: bars)
    }
}

// MARK: - Stretch against stretch (decision 0050)

/// This stretch's whole-episode average interval against the previous stretch's — the
/// across-episode sibling of `LaborTrend`, which compares an hour to the hour before it
/// (decision 0043). One statistic evaluated twice, never a second derivation of it
/// (F-0012); `direction` and both figures are engine truth, and the sentence that reads
/// them is app-side, the same split `EpisodeSummary` and `LaborTrend` both keep.
public struct StretchComparison: Equatable, Sendable {
    public enum Direction: Equatable, Sendable {
        /// This stretch's average interval is shorter than the previous stretch's.
        case closer
        /// This stretch's average interval is longer than the previous stretch's.
        case fartherApart
        /// **The reading decision 0050 §4 exists for.** Under the same one-sixth band
        /// `LaborTrend` treats as nothing worth a caption — and here it is the answer,
        /// not the absence of one. The trend caption is unsolicited commentary on a
        /// live pattern, so "the same as an hour ago" printed hourly is jitter-anxiety;
        /// this line answers a question the reader came to History carrying, and on the
        /// third night of prodromal labor "about the same" is the whole of it.
        case aboutTheSame
    }

    public let direction: Direction
    /// The live stretch's whole-episode average interval.
    public let current: Duration
    /// The same statistic over the stretch immediately before it.
    public let previous: Duration
    /// When that previous stretch began — the comparison dates itself for the same
    /// reason HL-026's recap does, and this one has more need of it: a comparison
    /// asserts that the older stretch is a *reference* for tonight, which a bare
    /// record never claims.
    public let previousStartedAt: Date

    public init(direction: Direction, current: Duration, previous: Duration, previousStartedAt: Date) {
        self.direction = direction
        self.current = current
        self.previous = previous
        self.previousStartedAt = previousStartedAt
    }
}

extension PatternAnalysis {
    /// **How long ago still counts as a reference** (decision 0050 §6). Seven days, the
    /// same window `ReviewPrompt` already uses for "recently in labor", so the app holds
    /// one notion of it rather than two. Beyond this the comparison is withheld
    /// entirely: a stretch from a previous pregnancy is a record she kept, and treating
    /// it as a yardstick for tonight is a claim the app has no business making.
    public static let stretchComparisonMaxAge: Duration = .seconds(7 * 24 * 60 * 60)

    /// This stretch against the one before it (decision 0050).
    ///
    /// Nil unless *all* of the following hold, and each for its own recorded reason:
    ///
    ///   - there are two stretches to compare (`episodes` splits them on `episodeGap`);
    ///   - the newer one is still live — an episode whose last start is more than
    ///     `episodeGap` ago is history, and the timer has already gone back to its empty
    ///     state, so a line reading "this stretch" would be naming one that ended;
    ///   - both clear `EpisodeSummary.averageInterval`'s own two-interval floor (§3) —
    ///     a comparison against a guess is worse than silence, and there is no em dash
    ///     for an absent comparison;
    ///   - the previous stretch began within `stretchComparisonMaxAge` (§6).
    ///
    /// Unlike `trend(for:rule:now:)` this never returns nil for being *too close to
    /// call*: that case is `.aboutTheSame`, which is the reading the whole decision
    /// turns on.
    public static func stretchComparison(
        for contractions: [Contraction],
        now: Date = Date()
    ) -> StretchComparison? {
        // Reconstruct the store as of `now` before splitting, the same first move
        // `pattern(for:rule:now:)` and `trend(for:rule:now:)` both make. Without it a
        // record dated *after* `now` — which a backwards clock set produces, and the
        // harness's chaotic profile produces on purpose — joins an episode and can
        // become "this stretch", a stretch that has not happened yet.
        let visible = records(contractions, asOf: now)
        let all = episodes(visible)
        guard all.count >= 2 else { return nil }
        let current = all[all.count - 1]
        let previous = all[all.count - 2]

        // Liveness read off the same `episodeGap` boundary `pattern(for:rule:now:)`
        // uses, so "is this stretch still happening" cannot answer differently in two
        // places. Closed on the same side, too: exactly `episodeGap` is still live.
        guard let latestStart = current.last?.startedAt,
              Duration.seconds(now.timeIntervalSince(latestStart)) <= episodeGap
        else { return nil }

        guard let previousStart = previous.first?.startedAt,
              Duration.seconds(now.timeIntervalSince(previousStart)) <= stretchComparisonMaxAge
        else { return nil }

        guard let currentAverage = summary(of: current)?.averageInterval,
              let previousAverage = summary(of: previous)?.averageInterval
        else { return nil }

        // Whole seconds, the same truncation `LaborFormat.minutesSeconds` prints, so
        // the band test can never disagree with the two figures the sentence shows —
        // and so the referee can restate it in `Int64` with no second rounding rule
        // to keep in sync (SP-194, the discipline `trend` already follows).
        let currentSeconds = currentAverage.components.seconds
        let previousSeconds = previousAverage.components.seconds
        let delta = abs(currentSeconds - previousSeconds)

        let direction: StretchComparison.Direction
        if delta * trendDeltaDenominator < previousSeconds {
            direction = .aboutTheSame
        } else {
            direction = currentSeconds < previousSeconds ? .closer : .fartherApart
        }

        return StretchComparison(
            direction: direction,
            current: currentAverage,
            previous: previousAverage,
            previousStartedAt: previousStart
        )
    }
}

// MARK: - Small helpers

extension Duration {
    var timeInterval: TimeInterval {
        TimeInterval(components.seconds) + TimeInterval(components.attoseconds) / 1e18
    }
}

extension Array where Element == Duration {
    var mean: Duration? {
        guard !isEmpty else { return nil }
        let total = reduce(TimeInterval.zero) { $0 + $1.timeInterval }
        return .seconds(total / TimeInterval(count))
    }
}
