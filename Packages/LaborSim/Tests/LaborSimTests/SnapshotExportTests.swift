#if DEBUG
import Foundation
import LaborKit
import Testing
@testable import LaborSim

/// **Layer A's other half: the bridge from the corpus to the glass.**
///
/// The engine legs answer "is the arithmetic right" over four hundred labors. They
/// cannot answer "and what does that look like at 3am on a phone", because the design's
/// running state derives from wall-clock timestamps and decision 0021 rejected
/// compressed-time UI replay outright. What crosses the gap is a *seed snapshot*: the
/// exact record set the fold held at one chosen instant, re-expressed as offsets from
/// launch `now`, which `DemoSeed` replays verbatim.
///
/// So this file tests almost nothing about LaborKit. It **derives the states worth
/// photographing** — fourteen promoted scenarios, each at the instants where the screen
/// has something to prove — and writes them where `scripts/labor-sim.sh` can seed them
/// into the real app.
///
/// Gated exactly like `ResultsWriter`: no pointer file, no output, no work. The
/// edit-test loop must not spend a minute of every run deriving screenshots nobody
/// asked for.
@Suite("Snapshot export")
struct SnapshotExportTests {

    @Test func writesTheSimulatorSeedSnapshots() throws {
        guard let root = ResultsWriter.outputRoot else {
            // The ordinary unit-test case, and asserting nothing here is the point: a
            // suite that needed the harness's output directory to pass would be a suite
            // that could not run in the edit-test loop.
            return
        }

        let directory = root.appendingPathComponent("snapshots")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        var entries: [SnapshotIndex.Entry] = []
        var unresolved: [SnapshotIndex.Unresolved] = []

        for promoted in PromotedScenarios.all {
            let manifest = ScenarioCorpus.generate(promoted.ref)
            let scan = MomentScan(manifest: manifest)

            func emit(_ moment: SnapshotMoment, at instant: Int64) throws -> Bool {
                let records = ReplayEngine.sorted(
                    ReplayEngine.fold(manifest.actions, through: instant)
                )
                // A moment resolving to an empty store has nothing to photograph —
                // except `stale`, whose entire content is that the readout went back to
                // empty while History kept everything.
                guard !records.isEmpty || moment == .stale else { return false }

                let name = "\(promoted.label)--\(moment.slug)"
                try CanonicalJSON.data(
                    SnapshotExportTests.seedSnapshot(records, at: instant, rule: manifest.rule),
                    pretty: true
                ).write(to: directory.appendingPathComponent("\(name).json"))

                entries.append(SnapshotIndex.Entry(
                    scenario: manifest.id,
                    label: promoted.label,
                    moment: moment.slug,
                    file: "\(name).json",
                    shot: "\(name).png",
                    atSeconds: instant,
                    archetype: manifest.archetype,
                    noiseProfile: manifest.noiseProfile,
                    rule: manifest.rule,
                    recordCount: records.count,
                    rationale: promoted.rationale,
                    momentRationale: moment.rationale,
                    expectedFacts: ExpectedFacts.describe(
                        records: records, at: instant, rule: manifest.rule, t0: manifest.t0
                    )
                ))
                return true
            }

            var wroteAny = false
            for moment in promoted.moments {
                guard let instant = scan.resolve(moment) else {
                    unresolved.append(SnapshotIndex.Unresolved(
                        label: promoted.label, scenario: manifest.id,
                        moment: moment.slug, reason: moment.absenceReason
                    ))
                    continue
                }
                if try emit(moment, at: instant) { wroteAny = true }
            }

            // A promoted scenario with no shot at all is a scenario silently dropped
            // from the gallery — worse than a less interesting instant, because the
            // report would look complete without it.
            if !wroteAny, let instant = scan.resolve(.peakEvidence) ?? scan.fallbackInstant {
                _ = try emit(.peakEvidence, at: instant)
            }
        }

        try CanonicalJSON.data(
            SnapshotIndex(
                version: 1,
                generatorVersion: LaborSimVersion.generator,
                promotedCount: PromotedScenarios.all.count,
                entries: entries,
                unresolved: unresolved
            ),
            pretty: true
        ).write(to: directory.appendingPathComponent("index.json"))

        let covered = Set(entries.map(\.label))
        let missing = PromotedScenarios.all.map(\.label).filter { !covered.contains($0) }
        #expect(missing.isEmpty, "no snapshot written for: \(missing)")
        #expect(entries.count >= PromotedScenarios.all.count)
    }

    /// Fourteen is the number decision 0021 states, and the searched picks below can
    /// silently come back empty if the noise model changes under them. Checked in every
    /// run, not just harness runs — this is the assertion that catches the promotion
    /// list rotting.
    @Test func fourteenScenariosArePromoted() {
        #expect(PromotedScenarios.all.count == 14)
    }

    /// The format grammar, pinned on the one copy this repo can reach from a test.
    ///
    /// `LaborFormat` lives in the app target, which has no unit-test target — only
    /// `HushlightUITests`, which drives glass rather than functions. `ExpectedFacts`
    /// duplicates the grammar so LaborSim need not depend on the app, and this pins
    /// the duplicate: the negative clamps F-0011 was filed for, the sub-minute prose
    /// branch, and the whole-hour one. The two copies are short enough to compare by
    /// eye; what this catches is either of them losing a clamp.
    @Test func theFormatGrammarClampsAndNeverPrintsAZeroInProse() {
        #expect(ExpectedFacts.minutesSeconds(.seconds(62)) == "1:02")
        #expect(ExpectedFacts.minutesSeconds(.seconds(-70)) == "0:00", "F-0011: never \"-1:-10\"")
        #expect(ExpectedFacts.hoursMinutes(.seconds(4320)) == "1 H 12 M")
        #expect(ExpectedFacts.hoursMinutes(.seconds(2880)) == "48 M")
        #expect(ExpectedFacts.hoursMinutes(.seconds(-3700)) == "0 M", "F-0011: never \"-1 M\"")

        // Elapsed-since is prose, and prose never carries a zero.
        #expect(ExpectedFacts.gap(.seconds(40)) == "under a minute")
        #expect(ExpectedFacts.gap(.seconds(-40)) == "under a minute")
        #expect(ExpectedFacts.gap(.seconds(7200)) == "2 H", "not \"2 H 0 M\"")
        #expect(ExpectedFacts.gap(.seconds(7260)) == "2 H 1 M")
        #expect(ExpectedFacts.gap(.seconds(2820)) == "47 M")
    }

    /// A promotion that names a scenario the corpus does not run is a promotion of
    /// nothing: the shot would be real and the engine numbers beside it would belong to
    /// someone else.
    @Test func everyPromotedScenarioIsInTheCorpus() {
        let corpus = Set(ScenarioCorpus.standard)
        for promoted in PromotedScenarios.all {
            #expect(corpus.contains(promoted.ref),
                    "\(promoted.label): \(promoted.ref.label) is not in the corpus")
        }
    }

    /// Labels name files, and the report's gallery links resolve through them.
    @Test func promotedLabelsAreUniqueAndFilesystemSafe() {
        var seen: Set<String> = []
        for promoted in PromotedScenarios.all {
            #expect(seen.insert(promoted.label).inserted, "duplicate label \(promoted.label)")
            #expect(
                promoted.label.allSatisfy { $0.isLowercase || $0.isNumber || $0 == "-" },
                "\(promoted.label) is not a safe file stem"
            )
        }
    }

    /// F-0019's own assertion, machine-checked rather than left as a comment: every
    /// instant the export actually resolves must sit >= 5 s clear of every boundary
    /// the record set at that instant derives. Reimplemented independently of
    /// `MomentScan`'s own boundary check — verifying a resolver's output with the
    /// exact arithmetic it used to produce that output would prove nothing about
    /// whether the arithmetic is right.
    @Test func everyResolvedMomentClearsEveryDerivedBoundary() {
        let clearance: Int64 = 5
        for promoted in PromotedScenarios.all {
            let manifest = ScenarioCorpus.generate(promoted.ref)
            let scan = MomentScan(manifest: manifest)
            let rule = HarnessBridge.rule(manifest.rule)

            for moment in promoted.moments {
                guard let instant = scan.resolve(moment) else { continue }
                let records = ReplayEngine.fold(manifest.actions, through: instant)

                for record in records {
                    #expect(
                        abs(instant - (record.start + 3600)) >= clearance,
                        """
                        \(promoted.label)/\(moment.slug): \(instant) sits on record \
                        \(record.createdBy)'s window-exit boundary (\(record.start + 3600))
                        """
                    )
                    #expect(
                        abs(instant - (record.start + 7200)) >= clearance,
                        """
                        \(promoted.label)/\(moment.slug): \(instant) sits on record \
                        \(record.createdBy)'s staleness boundary (\(record.start + 7200))
                        """
                    )
                }

                let contractions = HarnessBridge.contractions(ReplayEngine.sorted(records), t0: manifest.t0)
                let pattern = PatternAnalysis.pattern(
                    for: contractions, rule: rule, now: HarnessBridge.date(manifest.t0, instant)
                )
                if let episodeStart = pattern.episodeStart {
                    let episodeStartSeconds = Int64(episodeStart.timeIntervalSince1970) - manifest.t0
                    #expect(
                        abs(instant - (episodeStartSeconds + 3600)) >= clearance,
                        "\(promoted.label)/\(moment.slug): \(instant) sits on the sustained-hour boundary"
                    )
                }
            }
        }
    }

    // MARK: - Seeding

    /// Scenario seconds -> offsets from launch `now`.
    ///
    /// The chosen instant *is* `now`. Shifting the newest event to a fixed two minutes
    /// ago — `DemoSeed`'s convention for its own hand-picked plans — would move the
    /// clock relative to the records and with it `patternLength`, the analysis window,
    /// and therefore the verdict. The moments below are picked so the newest event
    /// already sits a sensible distance in the past; preserving the instant exactly is
    /// what makes the screenshot comparable to the engine's answer at that probe.
    ///
    /// Emits version 2 (F-0020): `rule` is the scenario's own `manifest.rule`, so
    /// `DemoSeed` persists the rule these facts were actually computed under instead
    /// of leaving the device on whatever it already had. Every caller passes the same
    /// `manifest.rule` into the paired `SnapshotIndex.Entry`, so the wire format and
    /// the index can never disagree about which rule a shot answers for.
    static func seedSnapshot(_ records: [SimRecord], at now: Int64, rule: String) -> LaborSeedSnapshot {
        LaborSeedSnapshot(
            version: 2,
            records: records.map { record in
                LaborSeedSnapshot.Record(
                    startOffsetSeconds: Double(record.start - now),
                    endOffsetSeconds: record.end.map { Double($0 - now) }
                )
            },
            rule: rule
        )
    }
}

// MARK: - The fourteen

/// One promoted scenario: which corpus row, why it earned a place on glass, and the
/// instants worth photographing in it.
struct PromotedScenario: Sendable {
    var ref: ScenarioSeedRef
    /// The file stem. Short and lowercase because it names PNGs a human scrolls past.
    var label: String
    var rationale: String
    var moments: [SnapshotMoment]
}

enum PromotedScenarios {

    /// Decision 0021's "sampled simulator pass (14 promoted scenarios)", made concrete.
    ///
    /// Most rows are addressed by name. Four are **searched** for instead — the
    /// stricter-rule row, and the forgotten-stop, kill-while-running and clock-set
    /// slices — because what makes each worth shooting is a property of the derivation
    /// (a stride into `base`, a noise draw) rather than of the archetype, and a
    /// hand-pinned index would quietly stop being that slice the first time either
    /// changed. Each search carries a fallback so the list is always fourteen.
    static let all: [PromotedScenario] = [
        PromotedScenario(
            ref: ref(.classicNullipara, 0, .typicalSolo),
            label: "classic-nullipara-typical",
            rationale: """
                The reference labor under the thumb most people actually have. \
                Everything else in this gallery is read as a departure from this row.
                """,
            moments: [.verdictMetPlus(minutes: 2), .oneShortOfFloor,
                      .runningMidContraction, .drainedWindow(minutes: 45)]
        ),
        PromotedScenario(
            ref: ref(.classicNullipara, 0, .clean),
            label: "classic-nullipara-clean",
            rationale: """
                The same body, the impossible thumb. `ScenarioSeedRef` derives its seed \
                from archetype and variant alone, so this row's true stream is \
                byte-identical to the one above and every difference between the two \
                shots is the thumb and nothing else (RUBRIC T1-05).
                """,
            moments: [.verdictMetPlus(minutes: 2), .oneShortOfFloor]
        ),
        PromotedScenario(
            ref: ref(.precipitous, 0, .exhaustedSolo),
            label: "precipitous-exhausted",
            rationale: """
                The labor with the least time to spare, recorded by the thumb with the \
                least attention left. Onset lag costs more here than anywhere.
                """,
            moments: [.verdictMetPlus(minutes: 2), .runningMidContraction]
        ),
        PromotedScenario(
            ref: ref(.prodromalFizzle, 0, .clean),
            label: "prodromal-fizzle-clean",
            rationale: """
                Never qualifies at any instant. Under `clean` a verdict cannot be blamed \
                on the recording, so any banner on this shot is the engine's own false \
                positive (RUBRIC T1-02).
                """,
            moments: [.peakEvidence, .stale]
        ),
        PromotedScenario(
            ref: ref(.prodromalNightly, 3, .typicalSolo),
            label: "prodromal-nightly-resolves",
            rationale: """
                Variant 3 is the nightly false alarm that finally was not. Bouts fourteen \
                or more hours apart, so History accumulates real sections while the timer \
                must still answer for tonight alone.
                """,
            moments: [.multiEpisode, .verdictMetPlus(minutes: 2)]
        ),
        PromotedScenario(
            ref: ref(.braxtonHicks, 0, .typicalSolo),
            label: "braxton-hicks-typical",
            rationale: """
                Built to fail every onset rule: no ramp anywhere, high jitter. The \
                screen's job here is to stay honest for hours while nothing happens.
                """,
            moments: [.peakEvidence]
        ),
        PromotedScenario(
            ref: ref(.backLaborCoupling, 1, .typicalSolo),
            label: "back-labor-coupling",
            rationale: """
                Alternating close/far pairs (W2, W10). The mean lands mid-range while \
                whole-episode `lastInterval` whipsaws between the two halves of the \
                couple; the instant those two figures most contradict each other is the \
                shot.
                """,
            moments: [.lastIntervalWhipsaw, .verdictMetPlus(minutes: 2)]
        ),
        PromotedScenario(
            ref: ref(.pretermEarly, 0, .partnerDiligent),
            label: "preterm-early-diligent",
            rationale: """
                Preterm context, recorded faithfully — so whatever the screen says is the \
                engine's answer rather than a recording artefact. The archetype that most \
                resembles Braxton Hicks and least deserves to be read as one.
                """,
            moments: [.peakEvidence]
        ),
        stricterRuleRow,
        PromotedScenario(
            ref: ref(.inductionRamp, 3, .typicalSolo),
            label: "induction-tachysystole",
            rationale: """
                Variant 3 floors the interval at 95-110 s: contractions stacking closer \
                than the uterus should allow. The timeline's density test — four rows, \
                two-digit ordinals, connectors under two minutes.
                """,
            moments: [.densestTimeline, .verdictMetPlus(minutes: 2)]
        ),
        PromotedScenario(
            ref: ref(.multiDayLatent, 0, .exhaustedSolo),
            label: "multi-day-latent-exhausted",
            rationale: """
                Bouts separated by sleep. Every gap over two hours is an episode \
                boundary, so History has to split where the body did while the timer \
                answers for the live stretch alone.
                """,
            moments: [.multiEpisode, .stale]
        ),
        forgottenStopRow,
        killMidContractionRow,
        clockHostileRow,
    ]

    // MARK: The searched rows

    /// The stricter-rule row. The corpus generates no mid-scenario `setRule` action —
    /// the noise model never emits one — so "she re-read the discharge sheet at 2am and
    /// switched to 4-1-1" is realised the only way this corpus can realise it: the same
    /// physiology seed judged under the stricter threshold, as a paired row.
    static let stricterRuleRow: PromotedScenario = {
        let picked = ScenarioCorpus.ruleCoverage.first {
            $0.archetype == .inductionRamp && $0.rule == "fourOneOne"
        } ?? ScenarioCorpus.ruleCoverage.first { $0.rule == "fourOneOne" }
            ?? ScenarioCorpus.ruleCoverage[0]
        return PromotedScenario(
            ref: picked,
            label: "rule-switch-four-one-one",
            rationale: """
                The rule-switch row: \(picked.archetype.rawValue) judged at 4-1-1 rather \
                than 5-1-1, over a body one of the base rows already judged at 5-1-1. The \
                corpus has no mid-scenario setRule action, so the paired stricter-rule \
                scenario is what a switch looks like here — and the guideline chip in the \
                header has to say which rule this screen is answering.
                """,
            moments: [.verdictMetPlus(minutes: 2), .oneShortOfFloor]
        )
    }()

    /// The forgotten stop. `chaotic` carries `pForget: 0.18`, the highest in the table.
    static let forgottenStopRow: PromotedScenario = {
        let picked = ScenarioCorpus.base.first { candidate in
            candidate.noiseProfile == .chaotic
                && !ScenarioCorpus.generate(candidate).truth.expectedSuspects.isEmpty
        } ?? ref(.classicNullipara, 0, .chaotic)
        return PromotedScenario(
            ref: picked,
            label: "chaotic-forgotten-stop",
            rationale: """
                The first chaotic row whose fold actually produces a suspect record. A \
                forgotten stop is the corpus's most consequential failure mode (W6): the \
                row stays, the averages exclude it, and the screen has to say so in words \
                rather than colour (T0-15).
                """,
            moments: [.suspectPresent, .peakEvidence]
        )
    }()

    /// The kill. Only `exhaustedSolo`, `chaotic` and `clockHostile` carry a non-zero
    /// `killCount`, and the noise model deliberately places each kill inside a running
    /// contraction — which is exactly the case T0-09 is written about.
    static let killMidContractionRow: PromotedScenario = {
        let picked = ScenarioCorpus.base.first { candidate in
            killers.contains(candidate.noiseProfile)
                && killWhileRunning(ScenarioCorpus.generate(candidate).actions) != nil
        } ?? ref(.classicNullipara, 0, .exhaustedSolo)
        return PromotedScenario(
            ref: picked,
            label: "kill-mid-contraction",
            rationale: """
                The first corpus row whose app is killed with a contraction still \
                running. T0-09 on glass: the running record must survive the relaunch \
                with its start intact and its elapsed figure still climbing.
                """,
            moments: [.afterKillWhileRunning, .peakEvidence]
        )
    }()

    /// The clock slice. `clockHostile` is the only profile carrying DST markers, and it
    /// also carries the one action that genuinely moves the device clock — a `backSet`
    /// of two to ten minutes, placed mid-contraction. The DST events themselves are
    /// `timezoneChange`, which by design moves not one stored second.
    static let clockHostileRow: PromotedScenario = {
        let picked = ScenarioCorpus.base.first { candidate in
            candidate.noiseProfile == .clockHostile
                && clockJump(ScenarioCorpus.generate(candidate).actions) != nil
        } ?? ref(.classicNullipara, 0, .clockHostile)
        return PromotedScenario(
            ref: picked,
            label: "clock-hostile-dst",
            rationale: """
                The clock-hostile row: DST markers plus a backwards device-clock set \
                landing mid-contraction. A clock change edits no stored second (W8); what \
                it can do is make `patternLength` and the intervals read impossibly, and \
                that contradiction is what the shot is for.
                """,
            moments: [.afterClockJump, .peakEvidence]
        )
    }()

    static let killers: Set<NoiseProfileID> = [.exhaustedSolo, .chaotic, .clockHostile]

    static func ref(
        _ archetype: ArchetypeID,
        _ variant: Int,
        _ profile: NoiseProfileID,
        run: Int = 0,
        rule: String = ScenarioCorpus.defaultRule
    ) -> ScenarioSeedRef {
        ScenarioSeedRef(
            archetype: archetype, paramVariant: variant,
            noiseProfile: profile, run: run, rule: rule
        )
    }

    // MARK: Action-level probes

    /// The effective instant of the first `killApp` landing while a record is running,
    /// or nil if this scenario never kills mid-contraction.
    ///
    /// One resumable walk rather than a fold per kill: a fold per kill is quadratic in
    /// the action list, and `chaotic` scenarios carry thousands of actions. A kill whose
    /// effective time moves *backwards* (a `clockSet` earlier in the list can do that)
    /// is skipped rather than probed, because the cursor only walks forwards.
    static func killWhileRunning(_ actions: [ScenarioAction]) -> Int64? {
        var cursor = ReplayEngine.Cursor(actions)
        var walked = Int64.min
        for (index, time) in effectiveTimes(actions).enumerated()
        where actions[index].kind == .killApp {
            guard time >= walked else { continue }
            walked = time
            if cursor.advance(to: time).contains(where: { $0.end == nil }) { return time }
        }
        return nil
    }

    /// The effective instant of the first device-clock change. Any magnitude: the noise
    /// model's only real clock move is a `backSet` of 120-600 s, and the hour-scale DST
    /// events are `timezoneChange`, which shifts nothing stored.
    static func clockJump(_ actions: [ScenarioAction]) -> Int64? {
        for (index, time) in effectiveTimes(actions).enumerated() {
            if case .clockSet = actions[index] { return time }
        }
        return nil
    }

    /// Action order, with each `clockSet` shifting everything after it — the same walk
    /// `ReplayEngine.Cursor` performs, and computed the same way round: an action's own
    /// effective time uses the offset as it stood *before* that action.
    static func effectiveTimes(_ actions: [ScenarioAction]) -> [Int64] {
        var offset: Int64 = 0
        var times: [Int64] = []
        times.reserveCapacity(actions.count)
        for action in actions {
            times.append(action.at + offset)
            if case let .clockSet(_, delta) = action { offset += delta }
        }
        return times
    }
}

// MARK: - Moments

/// Which instant of a scenario to photograph. Named for what is true on screen, not for
/// a probe index — the numbers move with the corpus, the states do not.
enum SnapshotMoment: Equatable, Sendable {
    /// The banner has just arrived and the screen has reordered around it.
    case verdictMetPlus(minutes: Int)
    /// Five in the window against a floor of six: every derived figure withheld, one tap
    /// from a verdict. The em-dash state T0-11 exists for.
    case oneShortOfFloor
    /// A suspect record sits inside the timer's four visible rows.
    case suspectPresent
    /// A contraction is running with enough elapsed to render as a reading.
    case runningMidContraction
    /// Taps stopped after the verdict and the window is draining (W5, the drive gap).
    case drainedWindow(minutes: Int)
    /// Past the two-hour staleness boundary: readout back to empty, History intact
    /// (T0-13 against T0-12).
    case stale
    /// The live episode is furnished and at least one earlier episode exists.
    case multiEpisode
    /// The densest four rows this scenario ever shows.
    case densestTimeline
    /// Where whole-episode `lastInterval` most contradicts the windowed average (W10).
    case lastIntervalWhipsaw
    /// Just after the device clock moved.
    case afterClockJump
    /// Relaunched into a contraction that was running when the app was killed.
    case afterKillWhileRunning
    /// The most evidence this scenario ever assembles — its strongest case for a verdict
    /// it may or may not be entitled to.
    case peakEvidence

    var slug: String {
        switch self {
        case let .verdictMetPlus(minutes): "verdict-met-plus-\(minutes)m"
        case .oneShortOfFloor: "one-short-of-floor"
        case .suspectPresent: "suspect-present"
        case .runningMidContraction: "running-mid-contraction"
        case let .drainedWindow(minutes): "drained-window-\(minutes)m"
        case .stale: "stale"
        case .multiEpisode: "multi-episode"
        case .densestTimeline: "densest-timeline"
        case .lastIntervalWhipsaw: "last-interval-whipsaw"
        case .afterClockJump: "after-clock-jump"
        case .afterKillWhileRunning: "after-kill-mid-contraction"
        case .peakEvidence: "peak-evidence"
        }
    }

    var rationale: String {
        switch self {
        case .verdictMetPlus: "The banner has just arrived; the screen has reordered around it."
        case .oneShortOfFloor: "Five in the window against a floor of six — every derived figure withheld."
        case .suspectPresent: "A forgotten stop is visible in the timer's rows."
        case .runningMidContraction: "A contraction is being timed: the button reads End, the newest node reads NOW."
        case .drainedWindow: "Taps stopped after the verdict; the window is draining under her."
        case .stale: "Past the two-hour boundary: readout empty, History intact."
        case .multiEpisode: "Tonight's stretch on the timer, earlier stretches in History."
        case .densestTimeline: "The tightest four rows this body ever produces."
        case .lastIntervalWhipsaw: "The bimodal instant: whole-episode lastInterval at its furthest from the windowed mean, where the INTERVAL detail slot now prints the spread instead (decision 0024 §2)."
        case .afterClockJump: "Five minutes after the device clock moved."
        case .afterKillWhileRunning: "Relaunched into the contraction that was running when the app died."
        case .peakEvidence: "The most contractions this scenario ever holds inside the analysis window."
        }
    }

    var absenceReason: String {
        switch self {
        case .verdictMetPlus: "the app never met the rule in this scenario"
        case .oneShortOfFloor: "the window never held exactly five"
        case .suspectPresent: "no suspect record ever reached the timer's visible rows"
        case .runningMidContraction: "no contraction ran long enough on a furnished screen"
        case .drainedWindow: "no verdict to drain from, or the drain crosses the staleness boundary"
        case .stale: "no records at all"
        case .multiEpisode: "the scenario never produced a second episode"
        case .densestTimeline: "no records at all"
        case .lastIntervalWhipsaw: "the two figures were never both available"
        case .afterClockJump: "no device-clock change in this scenario"
        case .afterKillWhileRunning: "no kill landed mid-contraction"
        case .peakEvidence: "no records at all"
        }
    }
}

// MARK: - Resolving a moment to an instant

/// One walk of a scenario's probe grid, keeping only what the moment selectors ask
/// about. Built once per promoted scenario rather than once per moment: the walk
/// re-derives the pattern at every probe, and four moments would otherwise be four full
/// sweeps of the same labor.
///
/// `resolve(_:)` is two steps: `rawResolve` picks the instant a moment's own logic
/// wants, then a single boundary-clearance nudge (F-0019) checks it is not sitting
/// on top of a fact the record set itself changes at — a record aging out of the
/// window, an episode going stale, the sustained hour ticking over — before handing
/// it back.
struct MomentScan {
    struct Sample {
        var at: Int64
        var episodeCount: Int
        var inWindow: Int
        var met: Bool
        var runningElapsed: Int64?
        var suspectVisible: Bool
        var lastInterval: Double?
        var averageInterval: Double?
        var totalEpisodes: Int
        var densityTwentyMinutes: Int
    }

    let manifest: ScenarioManifest
    let rule: GuidelineRule
    let samples: [Sample]
    /// The newest record start over the whole scenario — the anchor both staleness and
    /// the drained window are measured from.
    let latestStart: Int64?

    init(manifest: ScenarioManifest) {
        self.manifest = manifest
        let rule = HarnessBridge.rule(manifest.rule)
        self.rule = rule
        let cadence = ReplayEngine.cadence(for: manifest)
        let probes = ReplayEngine.probeTimes(for: manifest, cadence: cadence)

        var cursor = ReplayEngine.Cursor(manifest.actions)
        var generation = -1
        var contractions: [Contraction] = []
        var totalEpisodes = 0
        var collected: [Sample] = []
        collected.reserveCapacity(probes.count)

        for probe in probes {
            let records = cursor.advance(to: probe)
            if cursor.generation != generation {
                generation = cursor.generation
                contractions = HarnessBridge.contractions(
                    ReplayEngine.sorted(records), t0: manifest.t0
                )
                // Depends on the record set and not on `now`, so it is re-derived when
                // the store changes rather than at every one of a few thousand probes.
                totalEpisodes = PatternAnalysis.episodes(contractions).count
            }

            let now = HarnessBridge.date(manifest.t0, probe)
            let pattern = PatternAnalysis.pattern(for: contractions, rule: rule, now: now)
            let running = pattern.episode.last(where: { $0.endedAt == nil })

            collected.append(Sample(
                at: probe,
                episodeCount: pattern.episode.count,
                // F-0029: this used to hand-roll `now - 2 * rule.sustainedWindow` —
                // a *two-hour* window where `PatternAnalysis` actually uses one, so
                // `oneShortOfFloor` and `peakEvidence` were picked from the wrong
                // instants despite a comment here claiming otherwise. `inWindowCount`
                // exists precisely so a second copy of the window rule cannot live
                // somewhere else; reading it is now the only definition this file has.
                inWindow: pattern.inWindowCount,
                // The latched verdict: these samples choose what to photograph, and
                // what the screen shows is what a reviewer is looking at.
                met: pattern.presentedMet,
                runningElapsed: running.map { Int64(now.timeIntervalSince($0.startedAt)) },
                suspectVisible: pattern.episode.suffix(4).contains(where: \.isSuspect),
                lastInterval: pattern.lastInterval.map(HarnessBridge.seconds),
                averageInterval: pattern.averageInterval.map(HarnessBridge.seconds),
                totalEpisodes: totalEpisodes,
                densityTwentyMinutes: pattern.episode.filter {
                    now.timeIntervalSince($0.startedAt) <= 20 * 60
                }.count
            ))
        }

        self.samples = collected
        self.latestStart = ReplayEngine.fold(manifest.actions).map(\.start).max()
    }

    /// The last instant this scenario has anything on screen at all. Only used when
    /// every named moment came back empty.
    var fallbackInstant: Int64? {
        samples.last { $0.episodeCount > 0 }?.at
    }

    // MARK: Resolving

    func resolve(_ moment: SnapshotMoment) -> Int64? {
        guard let raw = rawResolve(moment) else { return nil }
        return clearBoundaries(
            near: raw,
            direction: nudgeDirection(for: moment),
            holds: holds(for: moment, rawInstant: raw)
        )
    }

    /// The moment-specific searches. Unchanged in what each one computes — F-0019's
    /// fix is a step applied *after* this, not a rewrite of what "the right instant"
    /// means for any moment.
    private func rawResolve(_ moment: SnapshotMoment) -> Int64? {
        switch moment {
        case let .verdictMetPlus(minutes):
            guard let first = samples.first(where: \.met), let last = samples.last else { return nil }
            return min(first.at + Int64(minutes) * 60, last.at)

        case .oneShortOfFloor:
            let floor = PatternAnalysis.guidelineEvidenceFloor
            return samples.first { $0.inWindow == floor - 1 }?.at

        case .suspectPresent:
            return samples.first(where: \.suspectVisible)?.at

        case .runningMidContraction:
            // Thirty seconds so the elapsed figure is a reading rather than a shutter
            // caught on 0:01, and three prior contractions so the columns above it have
            // something to say.
            return samples.first { ($0.runningElapsed ?? 0) >= 30 && $0.episodeCount >= 3 }?.at

        case let .drainedWindow(minutes):
            guard samples.contains(where: \.met), let latestStart else { return nil }
            let at = latestStart + Int64(minutes) * 60
            // Past two hours is staleness, which is its own moment under its own name.
            guard at < latestStart + 7200 else { return nil }
            return at

        case .stale:
            guard let latestStart else { return nil }
            return latestStart + 7200 + 60

        case .multiEpisode:
            // The last such instant rather than the first: History accumulating is the
            // point, and it accumulates monotonically.
            return samples.last { $0.totalEpisodes >= 2 && $0.episodeCount >= 3 }?.at

        case .densestTimeline:
            return best(by: \.densityTwentyMinutes)

        case .lastIntervalWhipsaw:
            let candidates = samples.compactMap { sample -> (Int64, Double)? in
                guard sample.episodeCount >= 3,
                      let last = sample.lastInterval, let average = sample.averageInterval
                else { return nil }
                return (sample.at, abs(last - average))
            }
            return candidates.max { $0.1 < $1.1 }?.0

        case .afterClockJump:
            guard let jump = PromotedScenarios.clockJump(manifest.actions) else { return nil }
            return samples.first { $0.at >= jump + 300 }?.at ?? samples.last?.at

        case .afterKillWhileRunning:
            guard let kill = PromotedScenarios.killWhileRunning(manifest.actions) else { return nil }
            // The shot wants the app relaunched *into* the running contraction, so the
            // instant has to be one where a record is still open.
            return samples.first { $0.at >= kill && $0.runningElapsed != nil }?.at

        case .peakEvidence:
            return best(by: \.inWindow)
        }
    }

    /// The earliest instant maximising `key`, or nil if the maximum is zero. Ties break
    /// to the earlier instant so the choice is stable across runs.
    private func best(by key: KeyPath<Sample, Int>) -> Int64? {
        guard let winner = samples.max(by: { lhs, rhs in
            (lhs[keyPath: key], -lhs.at) < (rhs[keyPath: key], -rhs.at)
        }) else { return nil }
        return winner[keyPath: key] > 0 ? winner.at : nil
    }

    // MARK: - F-0019: boundary clearance

    /// How far a resolved instant must sit from every boundary the record set at
    /// that instant derives. This is exactly what `ReplayEngine.probeTimes` samples
    /// ±1 s around (`s + 3600`, `s + 7200`) for a different reason — testing both
    /// sides of a knife-edge — which is precisely how a `samples.first`/`.last`
    /// search here can land a moment on one of those probes. Widened well past that
    /// ±1 s: `DemoSeed` replays these offsets against launch `now`, and the gap
    /// between "the scan resolved this instant" and "the app rendered it" is
    /// milliseconds, not nanoseconds.
    private static let boundaryClearance: Int64 = 5

    /// How far `resolve` will search for a clearing instant before reporting the
    /// moment unresolved. Small on purpose — a resolver that needed more than this
    /// would be drifting into a different instant, not clearing a boundary of the
    /// one it found.
    private static let nudgeBudget: Int64 = 30

    private enum NudgeDirection { case earlier, later }

    /// The single nudge/validation step every moment `resolve` returns passes
    /// through — one implementation, not a special case per moment (previously only
    /// `.multiEpisode` and `.stale` were even candidates for this kind of care, and
    /// F-0019 was filed against both). Starts at the raw instant (already clear,
    /// most of the time) and steps outward in `direction`, accepting the first
    /// candidate that both clears every boundary and still satisfies `holds` — the
    /// property that made this instant the right one to begin with, so a nudge
    /// cannot buy boundary clearance by drifting the moment into meaning something
    /// else (e.g. nudging `oneShortOfFloor` off the one instant where the count
    /// actually reads floor − 1). Nil means no such candidate exists inside the
    /// budget: honestly unresolved, not a shot that contradicts its own caption.
    private func clearBoundaries(
        near instant: Int64,
        direction: NudgeDirection,
        holds: (Int64) -> Bool
    ) -> Int64? {
        var offset: Int64 = 0
        while offset <= Self.nudgeBudget {
            let candidate = direction == .later ? instant + offset : instant - offset
            if candidate >= 0, holds(candidate), clearsBoundaries(candidate) {
                return candidate
            }
            offset += 1
        }
        return nil
    }

    /// Re-derives the pattern at an arbitrary instant. The nudge step needs
    /// single-second resolution and `samples` is only as fine as
    /// `ReplayEngine.probeTimes`, so this folds and analyses fresh rather than
    /// interpolating between the nearest two samples.
    private func pattern(at instant: Int64) -> LaborPattern {
        let records = ReplayEngine.sorted(ReplayEngine.fold(manifest.actions, through: instant))
        return PatternAnalysis.pattern(
            for: HarnessBridge.contractions(records, t0: manifest.t0),
            rule: rule,
            now: HarnessBridge.date(manifest.t0, instant)
        )
    }

    /// `pattern(at:)`'s one companion figure it does not itself carry: episodes
    /// ever produced, not just the live one.
    private func totalEpisodes(at instant: Int64) -> Int {
        let records = ReplayEngine.sorted(ReplayEngine.fold(manifest.actions, through: instant))
        return PatternAnalysis.episodes(HarnessBridge.contractions(records, t0: manifest.t0)).count
    }

    /// Whether `instant` sits `boundaryClearance` seconds clear of every boundary
    /// the record set at that instant derives.
    private func clearsBoundaries(_ instant: Int64) -> Bool {
        for record in ReplayEngine.fold(manifest.actions, through: instant) {
            // Falls out of the one-hour analysis window.
            if abs(instant - (record.start + 3600)) < Self.boundaryClearance { return false }
            // Episode/staleness boundary (decision 0022's episodeGap).
            if abs(instant - (record.start + 7200)) < Self.boundaryClearance { return false }
        }

        // One shared computation for the two checks below, rather than deriving
        // the pattern at `instant` twice.
        let here = pattern(at: instant)

        // The sustained hour: the live episode's own start crossing it flips
        // `sustainedMet` independently of any single record's window exit.
        if let episodeStart = here.episodeStart {
            let episodeStartSeconds = Int64(episodeStart.timeIntervalSince1970) - manifest.t0
            if abs(instant - (episodeStartSeconds + 3600)) < Self.boundaryClearance { return false }
        }

        // The ten-minute latch release (decision 0025, moving to the pattern level
        // this wave) has no closed form the way the three above do — release
        // depends on the whole trailing raw-verdict history, not one record's
        // timestamp — so this asks the cheap version of the same question instead:
        // does `presentedMet` still read the same value on both sides of the
        // clearance window? A flip anywhere inside it means something is releasing
        // close enough to the shutter to matter, and it matters for every moment,
        // not just verdict ones — the banner leading and everything below it
        // reordering (decision 0025) changes the whole screen's layout, not just
        // the banner's own text.
        if pattern(at: instant - Self.boundaryClearance).presentedMet != here.presentedMet
            || pattern(at: instant + Self.boundaryClearance).presentedMet != here.presentedMet {
            return false
        }
        return true
    }

    /// Which way is safe to search, as **one rule** rather than per-moment tuning:
    /// an instant chosen as the *first* one where some property turns true is
    /// nudged **later** — the boundary that flipped it on sits behind, and later
    /// stays inside the span the property describes. `.stale` follows the same
    /// rule even though its formula is not a search: it is already defined as
    /// sitting past a boundary and wants to stay past it. The one documented
    /// exception is an instant chosen as the *last* one where a property holds —
    /// `.multiEpisode`, the moment F-0019 was actually filed against — where the
    /// boundary sits just ahead, so earlier is what stays inside it.
    private func nudgeDirection(for moment: SnapshotMoment) -> NudgeDirection {
        switch moment {
        case .multiEpisode: .earlier
        default: .later
        }
    }

    /// The property that selected this instant, re-checked at the nudge's
    /// candidate so the search cannot walk away from what made the moment true in
    /// the first place. Each case mirrors exactly the predicate `rawResolve`
    /// searched for; `rawInstant` supplies the target value for the two moments
    /// that maximise a count (`.densestTimeline`, `.peakEvidence`) rather than
    /// crossing a fixed threshold, so nudging cannot quietly settle for a lesser
    /// peak.
    private func holds(for moment: SnapshotMoment, rawInstant: Int64) -> (Int64) -> Bool {
        switch moment {
        case .verdictMetPlus:
            return { candidate in self.pattern(at: candidate).presentedMet }

        case .oneShortOfFloor:
            let floor = PatternAnalysis.guidelineEvidenceFloor
            return { candidate in self.pattern(at: candidate).inWindowCount == floor - 1 }

        case .suspectPresent:
            return { candidate in
                self.pattern(at: candidate).episode.suffix(4).contains(where: \.isSuspect)
            }

        case .runningMidContraction:
            return { candidate in
                let p = self.pattern(at: candidate)
                guard let running = p.running else { return false }
                let now = HarnessBridge.date(self.manifest.t0, candidate)
                return now.timeIntervalSince(running.startedAt) >= 30 && p.episode.count >= 3
            }

        case .drainedWindow:
            guard let latestStart else { return { _ in false } }
            return { candidate in
                candidate < latestStart + 7200 && !self.pattern(at: candidate).episode.isEmpty
            }

        case .stale:
            return { candidate in self.pattern(at: candidate).episode.isEmpty }

        case .multiEpisode:
            return { candidate in
                self.totalEpisodes(at: candidate) >= 2 && self.pattern(at: candidate).episode.count >= 3
            }

        case .densestTimeline:
            let target = samples.first { $0.at == rawInstant }?.densityTwentyMinutes
            return { candidate in
                guard let target else { return false }
                let now = HarnessBridge.date(self.manifest.t0, candidate)
                let count = self.pattern(at: candidate).episode.filter {
                    now.timeIntervalSince($0.startedAt) <= 20 * 60
                }.count
                return count == target
            }

        case .lastIntervalWhipsaw:
            // Relaxed on purpose: the maximised quantity is a continuous spread,
            // not a discrete count, so what has to survive the nudge is the shot's
            // qualifying evidence (three-plus in the episode, both figures
            // present) rather than the exact original divergence.
            return { candidate in
                let p = self.pattern(at: candidate)
                return p.episode.count >= 3 && p.lastInterval != nil && p.averageInterval != nil
            }

        case .afterClockJump:
            guard let jump = PromotedScenarios.clockJump(manifest.actions) else { return { _ in false } }
            return { candidate in candidate >= jump }

        case .afterKillWhileRunning:
            guard let kill = PromotedScenarios.killWhileRunning(manifest.actions) else { return { _ in false } }
            return { candidate in candidate >= kill && self.pattern(at: candidate).running != nil }

        case .peakEvidence:
            let target = samples.first { $0.at == rawInstant }?.inWindow
            return { candidate in
                guard let target else { return false }
                return self.pattern(at: candidate).inWindowCount == target
            }
        }
    }
}

// MARK: - What the reviewer should see

/// The screen's facts at one instant, as plain sentences.
///
/// Deliberately not an assertion. `HushlightUITests` asserts the rendering through
/// the accessibility tree; a second machine-checked copy of the rendering rules living
/// here would only ever drift from it. What a reviewer needs beside a screenshot is what
/// the engine says *should* be on it, in words, so a disagreement is visible without
/// opening a debugger.
enum ExpectedFacts {
    static func describe(records: [SimRecord], at now: Int64, rule: String, t0: Int64) -> [String] {
        let guidelineRule = HarnessBridge.rule(rule)
        let contractions = HarnessBridge.contractions(records, t0: t0)
        let date = HarnessBridge.date(t0, now)
        let pattern = PatternAnalysis.pattern(for: contractions, rule: guidelineRule, now: date)
        let episodes = PatternAnalysis.episodes(contractions)

        guard !pattern.episode.isEmpty else {
            // The empty state remembers whether it has been used before (decision
            // 0022 §2): first launch keeps the introduction, a stale episode over a
            // non-empty store reads as a return.
            let lastEnded = contractions.compactMap(\.endedAt).max()
            return [
                "readout is the empty state: three em-dash columns over a ghost timeline",
                lastEnded.map {
                    "prose reads \"Last contraction ended \(gap(.seconds(date.timeIntervalSince($0)))) ago.\""
                } ?? "prose reads \"No contractions yet.\"",
                "no verdict line and no banner",
                episodes.isEmpty
                    ? "History is empty (\"Nothing logged yet.\")"
                    : "History still holds \(episodes.count) episode section(s) and \(contractions.count) row(s)",
            ]
        }

        // The PATTERN slot withholds below a minute (decision 0022 §7) — "0 M" is a
        // zero wearing a unit, and it landed on the very first contraction.
        let renderedLength = pattern.patternLength.flatMap {
            $0 >= .seconds(60) ? $0 : nil
        }

        var facts: [String] = [
            column("INTERVAL", pattern.averageInterval.map(minutesSeconds)),
            column("DURATION", pattern.averageDuration.map(minutesSeconds)),
            column("PATTERN", renderedLength.map(hoursMinutes))
                + "; detail reads \"\(pattern.episode.count) TOTAL\"",
        ]

        // The INTERVAL detail slot is the in-window spread (decision 0024 §2), not
        // the newest gap: a mean beside a whole-episode `lastInterval` read as one
        // row disagreeing with itself about the same measurement.
        if let range = pattern.intervalRange {
            facts.append("""
                INTERVAL detail reads "\(minutesSeconds(range.lowerBound))–\
                \(minutesSeconds(range.upperBound))"
                """)
        }

        // The header dates the figures beside it (decision 0022 §3), and says nothing
        // while a contraction is running — the live count already dates the screen.
        if pattern.running == nil,
           let ended = pattern.episode.compactMap(\.endedAt).max() {
            let ago = Duration.seconds(max(0, date.timeIntervalSince(ended)))
            if ago >= .seconds(60) {
                facts.append("header reads \"… · LAST \(gap(ago).uppercased()) AGO\"")
            }
        }

        // The tape speaks a raw count, never a percentage (decision 0037 §7): how
        // many contractions started inside the trailing hour, the same
        // `inWindowCount` `TimerScreen` hands `EmberTape` as its accessibility value.
        facts.append("tick tape reads \(pattern.inWindowCount) — contractions in the last hour")

        // The guidance area is never blank while an episode is live (0022 §4), and
        // the banner keys on the latched verdict, which now lives on `LaborPattern`
        // itself rather than `guideline` (decision 0025's amendment) so it can keep
        // presenting through an evidence dip that withdraws `guideline` entirely —
        // that gap was F-0009's residual: a drained window used to drop the banner
        // at once instead of ten minutes later.
        if pattern.presentedMet, pattern.guideline?.met == true {
            facts.append("""
                banner present: "That meets the \(guidelineRule.label) guideline many \
                providers use." — verdict block leads, timeline recedes below it
                """)
        } else if pattern.presentedMet {
            // Held rather than live: the latch is presenting a verdict the current
            // evidence does not (raw `met` false, or no `guideline` at all below the
            // floor). Not the same banner — expect a degraded, past-tense, dated
            // form, not this instant's live wording. Left in prose because the
            // shipped copy is TimerScreen's call, not this file's to pin.
            facts.append("""
                banner present but held: the latch is presenting a verdict the live \
                evidence no longer supports right now — a degraded, past-tense, dated \
                form, not the live wording above
                """)
        } else {
            facts.append("no banner; guidance line reads \(partialLine(pattern, rule: guidelineRule, at: date))")
        }

        // The timer's rows, newest first, exactly as `EpisodeTimeline` slices them.
        let visible = Array(pattern.episode.suffix(4).reversed())
        facts.append("timeline shows \(visible.count) row(s), newest ordinal \(pattern.episode.count)")
        for (offset, contraction) in visible.enumerated() {
            let ordinal = pattern.episode.count - offset
            if contraction.endedAt == nil {
                facts.append("row \(offset + 1) (contraction \(ordinal)) is running — reads NOW")
            } else if let suspicion = contraction.suspicion {
                // Mirrors `LaborFormat.checkFlag` (decision 0032): two ways a thumb
                // misses, two different words on the row.
                let flag = suspicion == .tooLong ? "CHECK · OVER 3 MIN" : "CHECK · UNDER 20 S"
                facts.append("row \(offset + 1) (contraction \(ordinal)) reads \(flag)")
            }
        }

        facts.append("History shows \(episodes.count) episode section(s), \(contractions.count) row(s) total")
        return facts
    }

    private static func column(_ name: String, _ value: String?) -> String {
        value.map { "\(name) column reads \($0)" }
            ?? "\(name) column reads an em dash (floor unmet — never a zero)"
    }

    /// Mirrors `TimerScreen.partialLine`. Same duplication trade as the formatters
    /// below, for the same reason — and the same risk, which is why the shapes are
    /// kept short enough to compare by eye against the screen's own builder.
    private static func partialLine(
        _ pattern: LaborPattern, rule: GuidelineRule, at now: Date
    ) -> String {
        let count = pattern.inWindowCount
        if let line = missingLegLine(pattern, rule: rule) { return line }
        if let interval = pattern.averageInterval {
            if let duration = pattern.averageDuration {
                return """
                    "Not at \(rule.label) yet — averaging \(minutesSeconds(interval)) apart and \
                    \(minutesSeconds(duration)) long over \(count) timed contractions."
                    """
            }
            return """
                "Not at \(rule.label) yet — averaging \(minutesSeconds(interval)) apart over \
                \(count) timed contractions; not enough finished ones yet to average their length."
                """
        }
        if pattern.running != nil {
            return count > 0
                ? "\"Timing this contraction — \(count) in the last hour.\""
                : "\"Timing this contraction — nothing else in the last hour.\""
        }
        if let ended = pattern.episode.compactMap(\.endedAt).max() {
            let elapsed = Duration.seconds(max(0, now.timeIntervalSince(ended)))
            return "\"Last contraction \(gap(elapsed)) ago — not enough in the last hour to average.\""
        }
        return "\"Not enough in the last hour to average.\""
    }

    /// Mirrors `TimerScreen.missingLegLine` (SP-201) — the printed form only, which
    /// is what a fact string quotes. Same duplication trade as `partialLine` above.
    private static func missingLegLine(_ pattern: LaborPattern, rule: GuidelineRule) -> String? {
        guard let status = pattern.guideline else { return nil }
        let label = rule.label
        switch (status.frequencyMet, status.durationMet, status.sustainedMet) {
        case (true, true, false):
            guard pattern.sustainedEvidence < rule.sustainedWindow else { return nil }
            return """
                "Not at \(label) yet — spacing and length are there; this stretch has been \
                unbroken for \(gap(pattern.sustainedEvidence)), and the guideline asks for an hour."
                """
        case (false, true, true):
            guard let range = pattern.intervalRange else { return nil }
            return """
                "Not at \(label) yet — length and the hour are there; spacing runs \
                \(minutesSeconds(range.lowerBound))–\(minutesSeconds(range.upperBound)), and the \
                guideline asks for \(minutesSeconds(rule.intervalThreshold)) or closer."
                """
        case (true, false, true):
            guard let duration = pattern.averageDuration else { return nil }
            return """
                "Not at \(label) yet — spacing and the hour are there; contractions are averaging \
                \(minutesSeconds(duration)), and the guideline asks for about a minute."
                """
        default:
            return nil
        }
    }

    /// Mirrors `Hushlight/LaborFormat`. Duplicated rather than shared because
    /// LaborSim must not depend on the app target, and the alternative — describing a
    /// format nobody restates — is how the two would quietly diverge unnoticed.
    static func minutesSeconds(_ duration: Duration) -> String {
        let total = max(0, Int(duration.components.seconds))
        return "\(total / 60):" + String(format: "%02d", total % 60)
    }

    static func hoursMinutes(_ duration: Duration) -> String {
        let totalMinutes = max(0, Int(duration.components.seconds)) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return hours > 0 ? "\(hours) H \(minutes) M" : "\(minutes) M"
    }

    /// Mirrors `LaborFormat.gap` — elapsed-since, not duration-of.
    static func gap(_ duration: Duration) -> String {
        if duration < .seconds(60) { return "under a minute" }
        let totalMinutes = max(0, Int(duration.components.seconds)) / 60
        if totalMinutes >= 60, totalMinutes % 60 == 0 { return "\(totalMinutes / 60) H" }
        return hoursMinutes(duration)
    }
}

// MARK: - The index

/// `snapshots/index.json` — the reviewer's and the report generator's map from a PNG
/// back to the scenario, the instant, and what should be on it.
struct SnapshotIndex: Codable {
    struct Entry: Codable {
        var scenario: String
        var label: String
        var moment: String
        var file: String
        var shot: String
        var atSeconds: Int64
        var archetype: String
        var noiseProfile: String
        var rule: String
        var recordCount: Int
        var rationale: String
        var momentRationale: String
        var expectedFacts: [String]
    }

    struct Unresolved: Codable {
        var label: String
        var scenario: String
        var moment: String
        var reason: String
    }

    var version: Int
    var generatorVersion: String
    var promotedCount: Int
    var entries: [Entry]
    var unresolved: [Unresolved]
}
#endif
