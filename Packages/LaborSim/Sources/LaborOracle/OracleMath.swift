// OracleMath.swift
// LaborOracle — the independent referee for the LaborSim differential test.
//
// This is a from-scratch reimplementation of the contraction-timer rules, written
// against the spec rather than the shipping LaborKit code. It has ZERO dependencies
// (no Foundation, no LaborKit, no LaborSim) and no abstractions beyond what the rules
// themselves require. All time is whole seconds (Int64) since an arbitrary test
// epoch. Duplication relative to LaborKit is deliberate: two independent
// implementations agreeing is the whole point of the differential test.

// MARK: - Rule

public enum OracleRule: String, Sendable, CaseIterable {
    case fiveOneOne, fourOneOne, threeOneOne

    /// The frequency leg: contractions must average no more than this many seconds
    /// apart, start to start. "5-1-1" / "4-1-1" / "3-1-1" name the interval in
    /// minutes; this is that same number in seconds.
    public var intervalThresholdSeconds: Int64 {
        switch self {
        case .fiveOneOne: return 300
        case .fourOneOne: return 240
        case .threeOneOne: return 180
        }
    }

    /// The duration leg **as the rule states it**: contractions must average at
    /// least one minute long. This is the middle "1" in every "N-1-1" naming and does
    /// not vary by rule — only the interval and the rule's name change between the
    /// three. Copy quotes this number; the boolean does not.
    public var durationThresholdSeconds: Int64 { 60 }

    /// The duration leg **as the boolean measures it** (decision 0023). Timing starts
    /// at the tap, so a recorded duration runs behind the felt contraction by the
    /// thumb's start latency while start-to-start spacing cancels that latency out.
    /// The check allows ten seconds for it; the printed averages do not move.
    public var durationEvidenceThresholdSeconds: Int64 { 50 }

    /// The sustained leg: the pattern must hold for at least one hour — the final
    /// "1" in "N-1-1". Also does not vary by rule.
    public var sustainedWindowSeconds: Int64 { 3600 }

    /// The largest start-to-start gap that still counts as the same pattern
    /// (decision 0026): triple the spacing the rule promises, so the cap scales with
    /// the rule rather than being one fixed hole size for all three.
    public var sustainedGapLimitSeconds: Int64 { intervalThresholdSeconds * 3 }

    /// Fast-met's floor (decision 0040 §1): a third of the sustained hour, twenty
    /// minutes at every rule since the hour itself does not vary by rule.
    public var fastMetMinimumLengthSeconds: Int64 { sustainedWindowSeconds / 3 }
}

// MARK: - Record

/// One stored contraction. `createdBy` is the index of the action that created it —
/// records are addressed by provenance, never by position in a store, so a delete/
/// undo round-trip can restore identity even after other edits reorder the store.
public struct OracleRecord: Sendable, Equatable {
    public var createdBy: Int
    public var start: Int64
    public var end: Int64?   // nil while running

    public init(createdBy: Int, start: Int64, end: Int64? = nil) {
        self.createdBy = createdBy
        self.start = start
        self.end = end
    }
}

// MARK: - Action

/// Same case set as the simulator's ScenarioAction, rewritten here rather than
/// shared — the oracle must not import LaborSim.
public enum OracleAction: Sendable, Equatable {
    case tapStart(at: Int64)
    case tapEnd(at: Int64)
    case deleteRecord(at: Int64, createdBy: Int)
    case undoDelete(at: Int64, createdBy: Int)
    case killApp(at: Int64)
    case launchApp(at: Int64)
    case clockSet(at: Int64, deltaSeconds: Int64)
    case timezoneChange(at: Int64, identifier: String)
    case setRule(at: Int64, rule: String)
    case clearAll(at: Int64)
}

// MARK: - Mean

/// A mean kept as a sum/count rational pair rather than a pre-divided Double. A
/// comparison against a whole-second threshold (e.g. "is the average exactly 300s?")
/// is done as `sum <= threshold * count` — pure integer arithmetic — so it can never
/// be misjudged by floating-point drift from an earlier division. `value` exists only
/// for display; nothing in this file compares using it.
public struct OracleMean: Sendable, Equatable {
    public var sumSeconds: Int64
    public var count: Int

    public init(sumSeconds: Int64, count: Int) {
        self.sumSeconds = sumSeconds
        self.count = count
    }

    public var value: Double { count == 0 ? 0 : Double(sumSeconds) / Double(count) }

    /// True when the mean is <= threshold, decided without ever forming a Double.
    public func isAtMost(_ threshold: Int64) -> Bool {
        sumSeconds <= threshold * Int64(count)
    }

    /// True when the mean is >= threshold, decided without ever forming a Double.
    public func isAtLeast(_ threshold: Int64) -> Bool {
        sumSeconds >= threshold * Int64(count)
    }
}

// MARK: - Pattern

public struct OraclePattern: Sendable, Equatable {
    public var hasPattern: Bool           // false == the empty state
    public var running: OracleRecord?
    public var episode: [OracleRecord]
    public var episodeStart: Int64?
    public var patternLengthSeconds: Int64?
    public var lastIntervalSeconds: Int64?
    public var averageInterval: OracleMean?
    /// Shortest and longest in-window interval, nil below two intervals. Two fields
    /// rather than a range so a nil-ness disagreement names which end is missing.
    public var intervalMinSeconds: Int64?
    public var intervalMaxSeconds: Int64?
    public var averageDuration: OracleMean?
    /// Time since the later of the episode start and the newest continuity break,
    /// capped at the sustained hour. Zero when there is no episode.
    public var sustainedEvidenceSeconds: Int64
    public var inWindowCount: Int
    public var frequencyMet: Bool?
    public var durationMet: Bool?
    public var sustainedMet: Bool?
    public var guidelineMet: Bool?        // all three, nil when no verdict renders
    /// The early line (decision 0040): stronger than the rule on frequency and
    /// duration, early only on sustained, nil under the same evidence-floor gate
    /// `frequencyMet`/`durationMet`/`sustainedMet` share.
    public var fastMet: Bool?
    /// The latched verdict the screen presents (decision 0025, amended). A
    /// pattern-level field, not tied to `guidelineMet`'s own nil-ness: the
    /// amendment moved the latch off the guideline status precisely so it can
    /// survive `guidelineMet` going nil when the evidence floor drains mid-labor —
    /// a held verdict from nine minutes ago must not vanish just because the
    /// window that would render it fresh has thinned out.
    public var presentedMet: Bool
    /// The fast-met verdict, latched the same way and for the same reason
    /// (decision 0040 §2, reusing decision 0025's mechanism exactly).
    public var presentedFastMet: Bool

    public init(
        hasPattern: Bool,
        running: OracleRecord?,
        episode: [OracleRecord],
        episodeStart: Int64?,
        patternLengthSeconds: Int64?,
        lastIntervalSeconds: Int64?,
        averageInterval: OracleMean?,
        intervalMinSeconds: Int64?,
        intervalMaxSeconds: Int64?,
        averageDuration: OracleMean?,
        sustainedEvidenceSeconds: Int64,
        inWindowCount: Int,
        frequencyMet: Bool?,
        durationMet: Bool?,
        sustainedMet: Bool?,
        guidelineMet: Bool?,
        fastMet: Bool? = nil,
        presentedMet: Bool,
        presentedFastMet: Bool = false
    ) {
        self.hasPattern = hasPattern
        self.running = running
        self.episode = episode
        self.episodeStart = episodeStart
        self.patternLengthSeconds = patternLengthSeconds
        self.lastIntervalSeconds = lastIntervalSeconds
        self.averageInterval = averageInterval
        self.intervalMinSeconds = intervalMinSeconds
        self.intervalMaxSeconds = intervalMaxSeconds
        self.averageDuration = averageDuration
        self.sustainedEvidenceSeconds = sustainedEvidenceSeconds
        self.inWindowCount = inWindowCount
        self.frequencyMet = frequencyMet
        self.durationMet = durationMet
        self.sustainedMet = sustainedMet
        self.guidelineMet = guidelineMet
        self.fastMet = fastMet
        self.presentedMet = presentedMet
        self.presentedFastMet = presentedFastMet
    }

    /// The empty state: no live episode to report on, no verdict, nothing running.
    /// Used both when the store is empty and when the last episode has gone stale.
    fileprivate static let empty = OraclePattern(
        hasPattern: false, running: nil, episode: [], episodeStart: nil,
        patternLengthSeconds: nil, lastIntervalSeconds: nil,
        averageInterval: nil, intervalMinSeconds: nil, intervalMaxSeconds: nil,
        averageDuration: nil, sustainedEvidenceSeconds: 0, inWindowCount: 0,
        frequencyMet: nil, durationMet: nil, sustainedMet: nil, guidelineMet: nil,
        fastMet: nil, presentedMet: false, presentedFastMet: false
    )
}

// MARK: - Episode summary

public struct OracleEpisodeSummary: Sendable, Equatable {
    public var count: Int
    public var spanSeconds: Int64?            // first start to last start; nil for a lone contraction
    public var averageInterval: OracleMean?   // nil below 2 intervals
    public var averageDuration: OracleMean?   // nil below 3 usable durations

    public init(count: Int, spanSeconds: Int64?, averageInterval: OracleMean?, averageDuration: OracleMean?) {
        self.count = count
        self.spanSeconds = spanSeconds
        self.averageInterval = averageInterval
        self.averageDuration = averageDuration
    }
}

// MARK: - Trend

/// Two-window comparison (decision 0043): this hour's average against the hour
/// before it. The referee's independent restatement of
/// `PatternAnalysis.trend(for:rule:now:)` — reimplemented from the spec rather
/// than shared, the same rule every other type in this file follows.
public struct OracleTrend: Sendable, Equatable {
    public enum Direction: String, Sendable, Equatable {
        case closer, fartherApart
    }

    public var direction: Direction
    /// Both windows' means, truncated to whole seconds — the same rounding the
    /// delta test itself applies (decision 0043 §3), so a boundary scenario can
    /// never disagree with the engine over a fractional remainder neither side
    /// ever prints.
    public var currentSeconds: Int64
    public var previousSeconds: Int64

    public init(direction: Direction, currentSeconds: Int64, previousSeconds: Int64) {
        self.direction = direction
        self.currentSeconds = currentSeconds
        self.previousSeconds = previousSeconds
    }
}

/// `PatternAnalysis.stretchComparison(for:now:)` — decision 0050's across-episode
/// counterpart to `OracleTrend`, reimplemented from the spec rather than shared.
public struct OracleStretchComparison: Sendable, Equatable {
    public enum Direction: String, Sendable, Equatable {
        /// Note the third case, which `OracleTrend` has no equivalent of: inside the
        /// one-sixth band the trend caption falls silent and this one *speaks*
        /// (decision 0050 §4), so "no comparison" and "a comparison that says steady"
        /// are genuinely different outcomes the referee has to be able to tell apart.
        case closer, fartherApart, aboutTheSame
    }

    public var direction: Direction
    /// Both stretches' whole-episode means, truncated to whole seconds — the same
    /// rounding the band test applies, for the same reason `OracleTrend` states.
    public var currentSeconds: Int64
    public var previousSeconds: Int64
    /// The previous stretch's first start, as an epoch second.
    public var previousStart: Int64

    public init(
        direction: Direction, currentSeconds: Int64, previousSeconds: Int64, previousStart: Int64
    ) {
        self.direction = direction
        self.currentSeconds = currentSeconds
        self.previousSeconds = previousSeconds
        self.previousStart = previousStart
    }
}

// MARK: - Math

public enum OracleMath {

    /// Splits one episode from the next: a start-to-start gap this many seconds or
    /// less is still "the same labor," a longer quiet stretch is a new one. Shared by
    /// `episodes` (splitting) and `pattern` (staleness) so both boundaries — "is this
    /// two episodes?" and "is the last episode too old to report?" — move together.
    private static let episodeGapSeconds: Int64 = 7200

    /// How far back "in progress right now" reaches for the rolling averages.
    private static let windowSeconds: Int64 = 3600

    /// A completed contraction longer than this is more likely a mistimed stop
    /// (forgot to tap End) than a real one, so it is dropped from the duration mean
    /// to avoid skewing it. Its start time is still real signal for spacing, so it is
    /// never excluded from interval math — only from the duration mean.
    private static let suspectDurationSeconds: Int64 = 180

    /// The symmetric floor (decision 0032): shorter than this is a tap artifact — a
    /// double tap, a pocket touch — not a short contraction, and it drags down the
    /// same mean from the other side. Same treatment: out of the duration mean, still
    /// counted for spacing.
    private static let slipDurationSeconds: Int64 = 20

    private static let intervalFloorCount = 2       // >= 2 intervals
    private static let durationFloorUsable = 3
    /// One less when a suspect sits in the window: a forgotten stop-tap is itself
    /// evidence a contraction happened, and it must not be able to null the verdict
    /// it belongs to (decision 0023 §2).
    private static let durationFloorUsableWithSuspect = 2
    private static let verdictFloorInWindow = 6

    /// The frequency share (decision 0024), as a rational so the comparison stays
    /// integer: `met * denominator >= total * numerator`.
    private static let frequencyShareNumerator = 2
    private static let frequencyShareDenominator = 3

    /// The verdict latch (decision 0025): held for this long after the raw verdict
    /// last read true, sampled at this cadence.
    private static let latchReleaseSeconds: Int64 = 600
    private static let latchSampleSeconds: Int64 = 30

    // MARK: Fold

    /// Replays a scenario's actions into the records that would be live in the store
    /// afterward. Mirrors the store's own reducer exactly; see each case below.
    public static func fold(_ actions: [OracleAction]) -> [OracleRecord] {
        var live: [OracleRecord] = []
        var deleted: [Int: OracleRecord] = [:]
        // The clock offset only affects how LATER actions' `at` times map to epoch
        // time. Records already stored keep the epoch time they were stamped with —
        // a device clock change does not rewrite history.
        var offset: Int64 = 0

        for (index, action) in actions.enumerated() {
            switch action {
            case .tapStart(let at):
                let effective = at + offset
                // No-op if a contraction is already running: one running record at a
                // time, full stop.
                if live.contains(where: { $0.end == nil }) {
                    continue
                }
                live.append(OracleRecord(createdBy: index, start: effective, end: nil))

            case .tapEnd(let at):
                let effective = at + offset
                // The store fetches the running record sorted by start descending, so
                // a stop-tap closes the **latest-started** one. With the restore guard
                // above in place there is never more than one open record, so this is
                // a total order over a set of one — kept explicit because the *store*
                // states its fetch order as part of its contract, and a referee that
                // assumed uniqueness would stop refereeing it. Ties on the start
                // second fall to the later provenance.
                var runningIndex: Int? = nil
                for index in live.indices where live[index].end == nil {
                    if let current = runningIndex {
                        let isLater = live[index].start > live[current].start
                            || (live[index].start == live[current].start
                                && live[index].createdBy > live[current].createdBy)
                        if isLater { runningIndex = index }
                    } else {
                        runningIndex = index
                    }
                }
                guard let runningIndex else {
                    continue // no-op: nothing running to end
                }
                // An end stamped before its own start clamps to zero length rather
                // than storing a negative duration.
                live[runningIndex].end = max(effective, live[runningIndex].start)

            case .deleteRecord(_, let createdBy):
                guard let idx = live.firstIndex(where: { $0.createdBy == createdBy }) else {
                    continue // no-op: no live record with this provenance
                }
                deleted[createdBy] = live.remove(at: idx)

            case .undoDelete(_, let createdBy):
                guard var record = deleted.removeValue(forKey: createdBy) else {
                    continue // no-op: nothing was deleted under this key
                }
                // Reinserted with its own identity, start and end — with one
                // exception: a restore that would stack a second open record. A
                // contraction deleted mid-run, with another started in the space the
                // delete made, comes back closed at its own start. At most one record
                // is ever open, and the restore still returns the row rather than
                // swallowing it.
                if record.end == nil, live.contains(where: { $0.end == nil }) {
                    record.end = record.start
                }
                live.append(record)

            case .killApp, .launchApp, .timezoneChange, .setRule:
                // Process/display events. setRule changes which rule the *analysis*
                // uses, which is the caller's concern, not the fold's — the stored
                // records themselves are untouched.
                continue

            case .clockSet(_, let deltaSeconds):
                offset += deltaSeconds

            case .clearAll:
                live.removeAll()
                // Deliberately un-undoable: a cleared store has nothing left to
                // restore into, so the deleted-set is wiped too.
                deleted.removeAll()
            }
        }

        // Insertion-stable order; callers that need chronological order call `sorted`.
        return live
    }

    // MARK: Ordering

    /// By start ascending, ties broken by createdBy ascending. Two contractions can
    /// share a start second (a restore-while-running collision, a clock jump), and a
    /// total order that depended on store iteration order would make the referee
    /// itself nondeterministic.
    public static func sorted(_ records: [OracleRecord]) -> [OracleRecord] {
        records.sorted { lhs, rhs in
            if lhs.start != rhs.start { return lhs.start < rhs.start }
            return lhs.createdBy < rhs.createdBy
        }
    }

    // MARK: Episodes

    /// Splits chronologically-sorted records into episodes. A gap strictly greater
    /// than `episodeGapSeconds` starts a new episode; exactly that many seconds
    /// apart is still the same one — the boundary is closed on the "still together"
    /// side so a contraction landing exactly on the line is not punished for it.
    public static func episodes(_ records: [OracleRecord]) -> [[OracleRecord]] {
        let ordered = sorted(records)
        guard let first = ordered.first else { return [] }

        var result: [[OracleRecord]] = [[first]]
        var previousStart = first.start
        for record in ordered.dropFirst() {
            if record.start - previousStart > episodeGapSeconds {
                result.append([record])
            } else {
                result[result.count - 1].append(record)
            }
            previousStart = record.start
        }
        return result
    }

    // MARK: Pattern

    /// The live pattern as of `now`, judged only against the most recent episode.
    /// Rule order below matches the boundaries the tests probe; read it top to
    /// bottom as the sequence of gates a record set passes through.
    public static func pattern(records: [OracleRecord], rule: OracleRule, now: Int64) -> OraclePattern {
        var result = rawPattern(records: records, rule: rule, now: now)
        // The latch runs whenever the raw verdict currently says no — whether
        // because a status rendered and failed, or because the evidence floor
        // withdrew it entirely (decision 0025, amended); a raw-true verdict is
        // already presented, and the sampling loop would find it on its own first
        // step anyway.
        //
        // This also retires `presentedFastMet` (decision 0040 §1's last clause):
        // `result.fastMet` is already false whenever `guidelineMet` is true (see
        // `rawPattern`), so `result.presentedFastMet` is correctly false here too
        // without its own ten-minute grace period at this boundary.
        guard result.guidelineMet != true else { return result }
        result.presentedMet = presentedMet(records: records, rule: rule, now: now)
        result.presentedFastMet = presentedFastMet(records: records, rule: rule, now: now)
        return result
    }

    /// The verdict as presented, latched (decision 0025, amended). Stateless: the
    /// trailing ten minutes are re-derived from the same records at 30-second
    /// steps, each step judged against the records **as they stood at that step**
    /// — otherwise a contraction from the last ten minutes would vote in a window
    /// it had not joined, and the latch could hold a verdict that was never
    /// raw-true.
    ///
    /// The boundary is closed on the latched side: a raw-true sample exactly ten
    /// minutes back still holds, release lands one step later.
    ///
    /// **The no-figures guard.** A held verdict beside no figures at all — every
    /// average gone, not just the evidence floor — is an assertion with nothing on
    /// screen backing it, so `presentedMet` is forced false whenever `now`'s own
    /// `averageInterval` is nil, whatever a sampled past instant found.
    public static func presentedMet(records: [OracleRecord], rule: OracleRule, now: Int64) -> Bool {
        // A cheap necessary-condition pre-check, mirroring LaborKit's own — using
        // this file's restated constants rather than the engine's, because two
        // independent implementations agreeing is the whole point of the
        // differential test. For the raw verdict to have been true at any instant
        // `t` in the trailing ten minutes, that instant's own window
        // `[t - windowSeconds, t]` must have held at least `verdictFloorInWindow`
        // contractions. Every such window, for every `t` in
        // `[now - latchReleaseSeconds, now]`, is a subset of the single interval
        // `[now - windowSeconds - latchReleaseSeconds, now]` — so if that wider
        // interval holds fewer starts than the floor, no window inside it can hold
        // the floor either, and presented is provably false without computing a
        // single `rawPattern`.
        let earliestPossibleWindowStart = now - (windowSeconds + latchReleaseSeconds)
        var recentStarts = 0
        for record in records where record.start >= earliestPossibleWindowStart && record.start <= now {
            recentStarts += 1
        }
        guard recentStarts >= verdictFloorInWindow else { return false }

        let atNow = rawPattern(records: records, rule: rule, now: now)
        guard atNow.averageInterval != nil else { return false }
        if atNow.guidelineMet == true { return true }

        var elapsed = latchSampleSeconds
        while elapsed <= latchReleaseSeconds {
            let instant = now - elapsed
            let asThen = self.records(records, asOf: instant)
            if rawPattern(records: asThen, rule: rule, now: instant).guidelineMet == true {
                return true
            }
            elapsed += latchSampleSeconds
        }
        return false
    }

    /// The fast-met verdict, latched the same way `presentedMet` above is
    /// (decision 0040 §2 reuses decision 0025's mechanism exactly, ten minutes and
    /// all). The pre-check is the same subset argument `presentedMet` makes,
    /// restated rather than shared: `fastMet` lives inside the identical
    /// `inWindowCount >= verdictFloorInWindow` gate `guidelineMet` does, so the
    /// same wider interval holds the floor for both or neither.
    public static func presentedFastMet(records: [OracleRecord], rule: OracleRule, now: Int64) -> Bool {
        let earliestPossibleWindowStart = now - (windowSeconds + latchReleaseSeconds)
        var recentStarts = 0
        for record in records where record.start >= earliestPossibleWindowStart && record.start <= now {
            recentStarts += 1
        }
        guard recentStarts >= verdictFloorInWindow else { return false }

        let atNow = rawPattern(records: records, rule: rule, now: now)
        // The same no-figures guard `presentedMet` enforces: a fast-met banner
        // prints the same bound figures the met shape does (decision 0040 §3), so
        // a held verdict beside a vanished `averageInterval` would be exactly the
        // assertion-with-nothing-behind-it the guard forbids.
        guard atNow.averageInterval != nil else { return false }
        if atNow.fastMet == true { return true }

        var elapsed = latchSampleSeconds
        while elapsed <= latchReleaseSeconds {
            let instant = now - elapsed
            let asThen = self.records(records, asOf: instant)
            if rawPattern(records: asThen, rule: rule, now: instant).fastMet == true {
                return true
            }
            elapsed += latchSampleSeconds
        }
        return false
    }

    /// The record set as it stood at `instant`: nothing that had not started yet, and
    /// anything that had started but not yet ended handed back open. Deletions since
    /// `instant` are unrecoverable from a set that no longer holds them — the honest
    /// cost of deriving rather than storing, and the harmless direction.
    public static func records(_ records: [OracleRecord], asOf instant: Int64) -> [OracleRecord] {
        records.compactMap { record in
            guard record.start <= instant else { return nil }
            guard let end = record.end, end > instant else { return record }
            return OracleRecord(createdBy: record.createdBy, start: record.start, end: nil)
        }
    }

    private static func rawPattern(records: [OracleRecord], rule: OracleRule, now: Int64) -> OraclePattern {
        let allEpisodes = episodes(records)
        guard let episode = allEpisodes.last, let lastRecord = episode.last else {
            return .empty
        }

        let running = episode.last(where: { $0.end == nil })

        // Staleness shares the same threshold as episode splitting: if the gap since
        // the last contraction would already start a new episode, there is nothing
        // current to report. Strictly greater, not >=, so a reading exactly on the
        // line is still live — the same closed-boundary choice as `episodes`.
        //
        // The clock runs on *ended* contractions only: while a record is open the
        // episode is live however long it has been open, because something is
        // happening right now. Staleness answers "has this stopped", and an unfinished
        // contraction is the one state where the answer cannot be yes.
        if running == nil, now - lastRecord.start > episodeGapSeconds {
            return .empty
        }

        let episodeStart = episode[0].start
        // now-based, not last-start-based: "how long has this been going on"
        // measured from the observer's clock, not from the most recent tap. Floored
        // at zero: a clock set back past the episode's own start would otherwise
        // produce a negative age, which is not a smaller measurement but a false one.
        let patternLengthSeconds = max(0, now - episodeStart)

        // The gap between the whole episode's last two starts — not the rolling
        // window's — so "time since the last contraction" survives even when the
        // window has thinned the episode down to nothing.
        var lastIntervalSeconds: Int64?
        if episode.count >= 2 {
            lastIntervalSeconds = episode[episode.count - 1].start - episode[episode.count - 2].start
        }

        // Inclusive at exactly now - windowSeconds: "in the last hour" is
        // conventionally a closed interval, and it keeps this boundary symmetric
        // with the episode-gap boundary above.
        let windowStart = now - windowSeconds
        let inWindow = episode.filter { $0.start >= windowStart }
        let inWindowCount = inWindow.count

        // The interval basis is the window **plus the one record immediately before
        // it** (decision 0023 §3). The gap into the window's first contraction is a
        // gap the last hour contains; excluding it biased the average toward recent
        // spacing and pushed every interval floor one contraction later. So n records
        // in the window yield n intervals whenever anything precedes them, and n-1
        // only at the very start of an episode.
        var basis = inWindow
        if let entry = episode.last(where: { $0.start < windowStart }) {
            basis.insert(entry, at: 0)
        }
        var intervals: [Int64] = []
        if basis.count >= 2 {
            for i in 1..<basis.count {
                intervals.append(basis[i].start - basis[i - 1].start)
            }
        }

        var averageInterval: OracleMean?
        var intervalMinSeconds: Int64?
        var intervalMaxSeconds: Int64?
        if intervals.count >= intervalFloorCount {
            averageInterval = OracleMean(sumSeconds: intervals.reduce(0, +), count: intervals.count)
            intervalMinSeconds = intervals.min()
            intervalMaxSeconds = intervals.max()
        }

        // Usable durations: in-window, completed, and not suspect (see
        // `suspectDurationSeconds`). A suspect duration's start already contributed
        // to averageInterval above; only the duration mean drops it — and its mere
        // presence relieves the floor by one, so that a forgotten stop-tap cannot
        // null the verdict its own contraction belongs to.
        var usableDurations: [Int64] = []
        var suspectInWindow = false
        for record in inWindow {
            guard let end = record.end else { continue }
            let duration = end - record.start
            if duration > suspectDurationSeconds {
                // Only the long side relieves the floor below: a forgotten stop-tap
                // is evidence a contraction happened, a slip is evidence of nothing.
                suspectInWindow = true
            } else if duration < slipDurationSeconds {
                continue
            } else {
                usableDurations.append(duration)
            }
        }
        let durationFloor = inWindowCount >= verdictFloorInWindow && suspectInWindow
            ? durationFloorUsableWithSuspect
            : durationFloorUsable
        var averageDuration: OracleMean?
        if usableDurations.count >= durationFloor {
            averageDuration = OracleMean(sumSeconds: usableDurations.reduce(0, +), count: usableDurations.count)
        }

        // Continuity (decision 0026): the newest in-window gap over triple the rule's
        // spacing is a break, and the pattern's unbroken stretch starts at the later
        // contraction of that break. Capped at the hour, so the figure answers "how
        // much of the last hour has been pattern" and never more.
        var continuityAnchor = episodeStart
        var longestGap: Int64 = 0
        for (index, gap) in intervals.enumerated() {
            if gap > longestGap { longestGap = gap }
            if gap > rule.sustainedGapLimitSeconds {
                let breakEnd = basis[index + 1].start
                if breakEnd > continuityAnchor { continuityAnchor = breakEnd }
            }
        }
        let sustainedEvidenceSeconds = min(max(0, now - continuityAnchor), rule.sustainedWindowSeconds)

        // A verdict needs enough evidence (>= 6 in-window contractions) AND both
        // means actually computed — either gate alone can withhold a verdict, so
        // both are checked before any of the three legs are judged.
        var frequencyMet: Bool?
        var durationMet: Bool?
        var sustainedMet: Bool?
        var guidelineMet: Bool?
        var fastMet: Bool?
        if inWindowCount >= verdictFloorInWindow,
           averageInterval != nil,
           let avgDuration = averageDuration {
            // The share, not the mean: at least two thirds of the in-window gaps must
            // sit at or under the threshold. Decided in integers, so four-of-six is
            // resolved by arithmetic rather than by a Double's rounding of 0.666…
            var withinThreshold = 0
            for gap in intervals where gap <= rule.intervalThresholdSeconds {
                withinThreshold += 1
            }
            let freq = withinThreshold * frequencyShareDenominator
                >= intervals.count * frequencyShareNumerator
            let dur = avgDuration.isAtLeast(rule.durationEvidenceThresholdSeconds)
            let continuityHolds = longestGap <= rule.sustainedGapLimitSeconds
            let sustained = patternLengthSeconds >= rule.sustainedWindowSeconds && continuityHolds
            frequencyMet = freq
            durationMet = dur
            sustainedMet = sustained
            let met = freq && dur && sustained
            guidelineMet = met

            // Fast-met (decision 0040), reimplemented independently rather than
            // shared with the engine (the referee rule): the same two-thirds
            // share, evaluated at half the rule's interval threshold; the rule's
            // own duration bar, unchanged; the same continuity clause `sustained`
            // above already reads; a twenty-minute floor on how long the pattern
            // has run; and never while the full verdict already holds.
            var withinHalfThreshold = 0
            let halfThresholdSeconds = rule.intervalThresholdSeconds / 2
            for gap in intervals where gap <= halfThresholdSeconds {
                withinHalfThreshold += 1
            }
            let fastFreq = withinHalfThreshold * frequencyShareDenominator
                >= intervals.count * frequencyShareNumerator
            fastMet = fastFreq && dur && continuityHolds
                && patternLengthSeconds >= rule.fastMetMinimumLengthSeconds
                && !met
        }

        return OraclePattern(
            hasPattern: true,
            running: running,
            episode: episode,
            episodeStart: episodeStart,
            patternLengthSeconds: patternLengthSeconds,
            lastIntervalSeconds: lastIntervalSeconds,
            averageInterval: averageInterval,
            intervalMinSeconds: intervalMinSeconds,
            intervalMaxSeconds: intervalMaxSeconds,
            averageDuration: averageDuration,
            sustainedEvidenceSeconds: sustainedEvidenceSeconds,
            inWindowCount: inWindowCount,
            frequencyMet: frequencyMet,
            durationMet: durationMet,
            sustainedMet: sustainedMet,
            guidelineMet: guidelineMet,
            fastMet: fastMet,
            // The raw pattern's own presented figures are just the raw verdicts;
            // `pattern(records:rule:now:)` overrides them with the latched values
            // whenever raw currently says no.
            presentedMet: guidelineMet ?? false,
            presentedFastMet: fastMet ?? false
        )
    }

    // MARK: Episode summary

    /// A window-free digest of one episode: history judges the whole stretch, not
    /// just the last hour of it. Same "usable duration" rule as `pattern` (completed,
    /// neither too long nor too short) for the same reason — an outlier stop time
    /// shouldn't skew the average someone reviews after the fact either.
    public static func summary(of episode: [OracleRecord]) -> OracleEpisodeSummary? {
        guard !episode.isEmpty else { return nil }
        let ordered = sorted(episode)
        let count = ordered.count

        var spanSeconds: Int64?
        if count >= 2 {
            spanSeconds = ordered[count - 1].start - ordered[0].start
        }

        var averageInterval: OracleMean?
        if count - 1 >= intervalFloorCount {
            var sum: Int64 = 0
            for i in 1..<count {
                sum += ordered[i].start - ordered[i - 1].start
            }
            averageInterval = OracleMean(sumSeconds: sum, count: count - 1)
        }

        let usableDurations: [Int64] = ordered.compactMap { record in
            guard let end = record.end else { return nil }
            let duration = end - record.start
            guard duration <= suspectDurationSeconds, duration >= slipDurationSeconds else { return nil }
            return duration
        }
        var averageDuration: OracleMean?
        if usableDurations.count >= durationFloorUsable {
            averageDuration = OracleMean(sumSeconds: usableDurations.reduce(0, +), count: usableDurations.count)
        }

        return OracleEpisodeSummary(
            count: count,
            spanSeconds: spanSeconds,
            averageInterval: averageInterval,
            averageDuration: averageDuration
        )
    }

    // MARK: Trend

    /// The trend's noise floor (decision 0043 §3), restated for the referee: a
    /// delta under one-sixth of the reference average is jitter and fires
    /// nothing. `LaborKit` carries the identical constant beside its own trend
    /// function; the two are never shared (SP-194's referee rule).
    private static let trendDeltaDenominator: Int64 = 6

    /// The windowed average as of `instant`, truncated to whole seconds — the
    /// referee's counterpart to `PatternAnalysis`'s private `windowedAverage`:
    /// reconstruct what the record set held at `instant` (`records(_:asOf:)`,
    /// the same reconstruction the latch functions above already use) and read
    /// that instant's own trailing hour off `rawPattern`.
    private static func windowedAverageSeconds(
        records recordSet: [OracleRecord], rule: OracleRule, asOf instant: Int64
    ) -> Int64? {
        let visible = records(recordSet, asOf: instant)
        guard let mean = rawPattern(records: visible, rule: rule, now: instant).averageInterval
        else { return nil }
        // Truncating integer division — the same floor-toward-zero truncation
        // `Duration.components.seconds` performs on the engine's own mean, so a
        // boundary scenario cannot disagree over which whole second either side
        // rounds to.
        return mean.sumSeconds / Int64(mean.count)
    }

    /// This hour against the hour before it (decision 0043), reimplemented from
    /// the spec: `current` is `rawPattern`'s own average, `previous` is the same
    /// statistic one `sustainedWindowSeconds` earlier. Nil unless both windows
    /// clear the average's own two-interval floor, and nil again below the
    /// one-sixth delta floor — the same two gates `PatternAnalysis.trend` states,
    /// checked here independently rather than by import.
    public static func trend(records recordSet: [OracleRecord], rule: OracleRule, now: Int64) -> OracleTrend? {
        guard let current = windowedAverageSeconds(records: recordSet, rule: rule, asOf: now)
        else { return nil }

        let referenceNow = now - rule.sustainedWindowSeconds
        guard let previous = windowedAverageSeconds(records: recordSet, rule: rule, asOf: referenceNow)
        else { return nil }

        let delta = abs(current - previous)
        guard delta * trendDeltaDenominator >= previous else { return nil }

        return OracleTrend(
            direction: current < previous ? .closer : .fartherApart,
            currentSeconds: current,
            previousSeconds: previous
        )
    }

    // MARK: Stretch comparison

    /// How long ago a stretch still counts as a reference (decision 0050 §6), restated
    /// for the referee. Seven days in seconds; `LaborKit` carries the identical figure
    /// beside its own function and the two are never shared (SP-194's referee rule).
    private static let stretchComparisonMaxAgeSeconds: Int64 = 7 * 24 * 60 * 60

    /// This stretch against the one before it (decision 0050), reimplemented from the
    /// spec. Four gates, each checked here independently rather than by import: two
    /// episodes exist, the newer one is still live against the same `episodeGapSeconds`
    /// boundary `pattern` uses for staleness, the previous one began inside the age
    /// bound, and both clear the average's own two-interval floor.
    ///
    /// Where it deliberately parts from `trend`: there is no "too close to call → nil"
    /// gate. Inside the one-sixth band this returns `.aboutTheSame`, which is the whole
    /// point of the decision, so a referee that inherited `trend`'s silence there would
    /// disagree with the engine on every steady night.
    public static func stretchComparison(
        records recordSet: [OracleRecord], now: Int64
    ) -> OracleStretchComparison? {
        // Reconstruct as of `now` first, the same move `windowedAverageSeconds` makes
        // above and for the same reason: a record dated after `now` (a backwards clock
        // set) is not part of any stretch that has happened yet.
        let all = episodes(records(recordSet, asOf: now))
        guard all.count >= 2 else { return nil }
        let current = all[all.count - 1]
        let previous = all[all.count - 2]

        guard let latestStart = current.last?.start, now - latestStart <= episodeGapSeconds
        else { return nil }
        guard let previousStart = previous.first?.start,
              now - previousStart <= stretchComparisonMaxAgeSeconds
        else { return nil }

        guard let currentMean = summary(of: current)?.averageInterval,
              let previousMean = summary(of: previous)?.averageInterval
        else { return nil }

        let currentSeconds = currentMean.sumSeconds / Int64(currentMean.count)
        let previousSeconds = previousMean.sumSeconds / Int64(previousMean.count)
        let delta = abs(currentSeconds - previousSeconds)

        let direction: OracleStretchComparison.Direction
        if delta * trendDeltaDenominator < previousSeconds {
            direction = .aboutTheSame
        } else {
            direction = currentSeconds < previousSeconds ? .closer : .fartherApart
        }

        return OracleStretchComparison(
            direction: direction,
            currentSeconds: currentSeconds,
            previousSeconds: previousSeconds,
            previousStart: previousStart
        )
    }
}
