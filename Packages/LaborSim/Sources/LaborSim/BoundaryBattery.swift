import Foundation

/// The hand-authored half of the corpus (decision 0021 §5's odd one out).
///
/// Everything else in this package is *sampled* from clinical brackets through
/// `Archetypes` and `SplitMix64` — which means no sampled scenario ever lands on an
/// exact boundary value, the way a random labor essentially never produces a mean
/// interval of precisely 300.000 s. These do, by construction: every number here is
/// a literal chosen to sit exactly on, or exactly one second off, some threshold the
/// engine has to get right. No random draws, no floating point, nothing to re-derive
/// from a seed — the numbers are the scenario.
public enum BoundaryBattery {
    /// ~30 exact-value probes, one boundary each.
    public static func manifests() -> [ScenarioManifest] {
        withVariantIndex([
            intervalExactly300(), intervalExactly301(),
            intervalExactly240(), intervalExactly180(),
            durationExactly60(), durationExactly59(), durationExactly61(),
            durationExactly180(), durationExactly181(),
            oneSuspectAmongGood(),
            gapExactly7200(), gapExactly7201(),
            sixthContractionAtWindowEdge(),
            contractionAtExactlyNowMinus3600(), contractionAtExactlyNowMinus3601(),
            fiveInWindowThenSix(),
            exactlyTwoIntervals(), exactlyOneInterval(),
            exactlyThreeUsableDurations(), exactlyTwoUsableDurations(),
            patternLengthExactly3600(), patternLengthExactly3599(),
            zeroLengthContraction(), endBeforeStart(),
            equalStartTies(), singleContraction(),
            flappingNearTheShareBoundary(), couplingFaithfulShareRefuses(),
            burstLullTap(), lastIntervalContradictsTheWindow(),
            fastFromTheFirstContraction(),
            timezoneCorrectionBeforeEpisodeStart(),
        ])
    }

    /// 10 store-abuse scenarios: the arithmetic is incidental, the point is what
    /// `ReplayEngine`'s fold does when the store is prodded outside its happy path.
    public static func adversarial() -> [ScenarioManifest] {
        withVariantIndex([
            advRestoreWhileRunning(),
            advDeleteAllThenTap(),
            advClearAllMidEpisode(),
            advUndoAfterClearAll(),
            advDoubleDelete(),
            advUndoWithoutDelete(),
            advEndWhileIdleRepeated(),
            advStartWhileRunningRepeated(),
            advClockBackMidContraction(),
            advClockForwardOverlap(),
        ])
    }

    public static var all: [ScenarioManifest] { manifests() + adversarial() }

    // MARK: - Shared construction

    /// Assembles a manifest from the four things that actually vary between cases.
    /// `truth` is always `TruthCompiler.compile` over the case's own true stream,
    /// and `expectedSuspects` is always the replayed fold of the case's own
    /// actions — never hand-computed, so the corpus can never assert a suspect list
    /// that disagrees with the engine both legs are judged against.
    private static func makeManifest(
        caseName: String,
        rule: String,
        trueContractions: [TrueContraction],
        actions: [ScenarioAction],
        expectedDetection: [String] = []
    ) -> ScenarioManifest {
        var truth = TruthCompiler.compile(trueStream: trueContractions, rules: [rule])
        truth.expectedSuspects = ReplayEngine.expectedSuspects(actions)
        return ScenarioManifest(
            id: "boundaryBattery-\(caseName)",
            seed: 0,
            archetype: ArchetypeID.boundaryBattery.rawValue,
            paramVariant: 0,   // stamped to the case's array index below
            noiseProfile: NoiseProfileID.clean.rawValue,
            rule: rule,
            t0: laborSimEpoch,
            timeZone: "America/New_York",
            trueContractions: trueContractions,
            actions: actions,
            truth: truth,
            expectedDetection: expectedDetection.isEmpty ? nil : expectedDetection
        )
    }

    /// `paramVariant` is the case's position in the array its function returns —
    /// stamped here, once, rather than threaded through every case builder.
    private static func withVariantIndex(_ manifests: [ScenarioManifest]) -> [ScenarioManifest] {
        manifests.enumerated().map { index, manifest in
            var stamped = manifest
            stamped.paramVariant = index
            return stamped
        }
    }

    /// `count` contractions of `duration` seconds, `interval` seconds apart, the
    /// first starting at `firstStart`. The one shape nearly every probe below is
    /// built from — only the four numbers differ, and every one of them is a
    /// literal you can check by eye.
    private static func evenStream(
        count: Int, firstStart: Int64, interval: Int64, duration: Int64
    ) -> [TrueContraction] {
        (0..<count).map { i in
            let start = firstStart + Int64(i) * interval
            return TrueContraction(start: start, end: start + duration)
        }
    }

    /// Mirrors a true stream tap-for-tap: a `tapStart` at every start, a `tapEnd`
    /// at every end, nothing more. Built by walking contractions in start order and
    /// keeping each contraction's own pair adjacent, then a stable sort by `at` —
    /// which resolves both tie shapes correctly with zero extra logic. A
    /// contraction's own zero-length pair keeps its start before its end (pushed
    /// in that order to begin with), and two different contractions that touch
    /// keep the earlier one's end before the later one's start (pushed in that
    /// order too, since contractions are walked earliest-first). A comparator that
    /// tried to encode this by `Kind` instead would get the zero-length case
    /// backwards — closing a record that was never opened, then leaving the real
    /// one running forever.
    private static func faithfulActions(_ stream: [TrueContraction]) -> [ScenarioAction] {
        var actions: [ScenarioAction] = []
        for contraction in stream.sorted(by: { $0.start < $1.start }) {
            actions.append(.tapStart(at: contraction.start))
            actions.append(.tapEnd(at: contraction.end))
        }
        return actions.sorted { $0.at < $1.at }
    }

    /// The index in `actions` of the nth `tapStart` (0-based) — the `createdBy` a
    /// `deleteRecord`/`undoDelete` must cite. Counting positions by hand across a
    /// hand-authored array invites exactly the off-by-one this corpus exists to
    /// catch in the app under test; this counts instead.
    private static func nthTapStartIndex(_ n: Int, in actions: [ScenarioAction]) -> Int {
        var seen = 0
        for (index, action) in actions.enumerated() {
            if case .tapStart = action {
                if seen == n { return index }
                seen += 1
            }
        }
        preconditionFailure("no tapStart #\(n) among \(actions.count) actions")
    }

    /// Six clean 60 s contractions, 300 s apart — the reused "healthy baseline"
    /// body for adversarial cases where the store abuse, not the physiology, is
    /// the point under test.
    private static func sixGoodStream() -> [TrueContraction] {
        evenStream(count: 6, firstStart: 0, interval: 300, duration: 60)
    }

    // MARK: - 1-4. Interval thresholds

    /// Boundary: mean start-to-start interval under 5-1-1 (300 s threshold).
    /// Thirteen contractions exactly 300 s apart put the mean exactly on the
    /// line — `≤` is a pass, so this sits on the **met** side by construction.
    private static func intervalExactly300() -> ScenarioManifest {
        let contractions = evenStream(count: 13, firstStart: 0, interval: 300, duration: 60)
        return makeManifest(
            caseName: "intervalExactly300", rule: "fiveOneOne",
            trueContractions: contractions, actions: faithfulActions(contractions),
            expectedDetection: ["mean interval exactly at 5-1-1's 300s threshold: met side"]
        )
    }

    /// Boundary: one second past 5-1-1's 300 s interval threshold. The same shape
    /// as `intervalExactly300`, widened by a single second, must fall on the
    /// **missed** side.
    private static func intervalExactly301() -> ScenarioManifest {
        let contractions = evenStream(count: 13, firstStart: 0, interval: 301, duration: 60)
        return makeManifest(
            caseName: "intervalExactly301", rule: "fiveOneOne",
            trueContractions: contractions, actions: faithfulActions(contractions),
            expectedDetection: ["mean interval one second past 5-1-1's 300s threshold: missed side"]
        )
    }

    /// Boundary: mean interval under 4-1-1 (240 s threshold), landed exactly on
    /// it — the **met** side, the same way `intervalExactly300` sits on 5-1-1's.
    private static func intervalExactly240() -> ScenarioManifest {
        let contractions = evenStream(count: 13, firstStart: 0, interval: 240, duration: 60)
        return makeManifest(
            caseName: "intervalExactly240", rule: "fourOneOne",
            trueContractions: contractions, actions: faithfulActions(contractions),
            expectedDetection: ["mean interval exactly at 4-1-1's 240s threshold: met side"]
        )
    }

    /// Boundary: mean interval under 3-1-1 (180 s threshold), landed exactly on
    /// it — the **met** side.
    private static func intervalExactly180() -> ScenarioManifest {
        let contractions = evenStream(count: 13, firstStart: 0, interval: 180, duration: 60)
        return makeManifest(
            caseName: "intervalExactly180", rule: "threeOneOne",
            trueContractions: contractions, actions: faithfulActions(contractions),
            expectedDetection: ["mean interval exactly at 3-1-1's 180s threshold: met side"]
        )
    }

    // MARK: - 5-10. Duration thresholds

    /// Boundary: mean contraction duration at the 60 s pass line. `≥` is a pass,
    /// so a duration landing exactly on 60 s sits on the **met** side.
    private static func durationExactly60() -> ScenarioManifest {
        let contractions = evenStream(count: 13, firstStart: 0, interval: 300, duration: 60)
        return makeManifest(
            caseName: "durationExactly60", rule: "fiveOneOne",
            trueContractions: contractions, actions: faithfulActions(contractions),
            expectedDetection: ["mean duration exactly at the 60s pass line: met side"]
        )
    }

    /// Boundary: one second short of the 60 s duration threshold — the
    /// **missed** side.
    private static func durationExactly59() -> ScenarioManifest {
        let contractions = evenStream(count: 13, firstStart: 0, interval: 300, duration: 59)
        return makeManifest(
            caseName: "durationExactly59", rule: "fiveOneOne",
            trueContractions: contractions, actions: faithfulActions(contractions),
            expectedDetection: ["mean duration one second short of 60s: missed side"]
        )
    }

    /// Boundary: one second past the 60 s duration threshold — comfortably the
    /// **met** side, the neighbor that proves 59/60/61 all land where they should.
    private static func durationExactly61() -> ScenarioManifest {
        let contractions = evenStream(count: 13, firstStart: 0, interval: 300, duration: 61)
        return makeManifest(
            caseName: "durationExactly61", rule: "fiveOneOne",
            trueContractions: contractions, actions: faithfulActions(contractions),
            expectedDetection: ["mean duration one second past 60s: met side"]
        )
    }

    /// Boundary: the suspect cutoff is strictly **>180 s**, so a duration landed
    /// exactly on 180 s is legitimate and must count toward the duration mean,
    /// not get excluded as suspect.
    private static func durationExactly180() -> ScenarioManifest {
        let contractions = evenStream(count: 13, firstStart: 0, interval: 300, duration: 180)
        return makeManifest(
            caseName: "durationExactly180", rule: "fiveOneOne",
            trueContractions: contractions, actions: faithfulActions(contractions),
            expectedDetection: ["180s duration is not suspect; all thirteen count toward the mean"]
        )
    }

    /// Boundary: one second past the suspect cutoff — every contraction here is
    /// suspect and excluded from the duration mean, leaving no usable duration at
    /// all. The asymmetry: their **starts** still count toward the interval mean,
    /// since suspicion is a duration verdict, not a start-time one.
    private static func durationExactly181() -> ScenarioManifest {
        let contractions = evenStream(count: 13, firstStart: 0, interval: 300, duration: 181)
        return makeManifest(
            caseName: "durationExactly181", rule: "fiveOneOne",
            trueContractions: contractions, actions: faithfulActions(contractions),
            expectedDetection: [
                "181s duration is suspect; all thirteen excluded, no usable duration mean, starts still count",
            ]
        )
    }

    /// Boundary: exactly one contraction crosses the suspect line among otherwise
    /// clean data. Only that one record is excluded, and the surviving mean is
    /// unchanged at exactly 60 s — the suspect verdict is per-record, not
    /// contagious to its neighbors.
    private static func oneSuspectAmongGood() -> ScenarioManifest {
        var contractions = evenStream(count: 13, firstStart: 0, interval: 300, duration: 60)
        contractions[6] = TrueContraction(start: contractions[6].start, end: contractions[6].start + 300)
        return makeManifest(
            caseName: "oneSuspectAmongGood", rule: "fiveOneOne",
            trueContractions: contractions, actions: faithfulActions(contractions),
            expectedDetection: ["one 300s outlier among twelve 60s contractions; only it is excluded, mean stays 60"]
        )
    }

    // MARK: - 11-12. Episode gap

    /// Boundary: the episode-split gap is strictly **>2 h**. A start-to-start gap
    /// of exactly 7200 s does not exceed it, so both clusters remain one episode.
    private static func gapExactly7200() -> ScenarioManifest {
        let clusterA = evenStream(count: 6, firstStart: 0, interval: 300, duration: 60)
        let clusterB = evenStream(count: 6, firstStart: 1500 + 7200, interval: 300, duration: 60)
        let contractions = clusterA + clusterB
        return makeManifest(
            caseName: "gapExactly7200", rule: "fiveOneOne",
            trueContractions: contractions, actions: faithfulActions(contractions),
            expectedDetection: ["start-to-start gap exactly 7200s: one episode, not two"]
        )
    }

    /// Boundary: one second past the 7200 s episode gap — the clusters must split
    /// into two separate episodes.
    private static func gapExactly7201() -> ScenarioManifest {
        let clusterA = evenStream(count: 6, firstStart: 0, interval: 300, duration: 60)
        let clusterB = evenStream(count: 6, firstStart: 1500 + 7201, interval: 300, duration: 60)
        let contractions = clusterA + clusterB
        return makeManifest(
            caseName: "gapExactly7201", rule: "fiveOneOne",
            trueContractions: contractions, actions: faithfulActions(contractions),
            expectedDetection: ["start-to-start gap 7201s, one past the split: two episodes"]
        )
    }

    // MARK: - 13-16. Window edges and the evidence floor

    /// Boundary: the one-hour window's opening edge (`start >= now - 3600`). Six
    /// contractions span exactly one hour with the earliest sitting exactly on
    /// that edge — the evidence floor of six is met only if the edge is
    /// **inclusive**.
    private static func sixthContractionAtWindowEdge() -> ScenarioManifest {
        let contractions = evenStream(count: 6, firstStart: 96_400, interval: 720, duration: 60)
        return makeManifest(
            caseName: "sixthContractionAtWindowEdge", rule: "fiveOneOne",
            trueContractions: contractions, actions: faithfulActions(contractions),
            expectedDetection: [
                "probe:100000",
                "earliest of six starts exactly at now-3600: floor met only if the edge is inclusive",
            ]
        )
    }

    /// Boundary: a contraction starting exactly 3600 s before the probe instant
    /// is inside the one-hour window (`>=`), and its interval to the next
    /// contraction must be counted.
    private static func contractionAtExactlyNowMinus3600() -> ScenarioManifest {
        let contractions = [
            TrueContraction(start: 496_400, end: 496_460),   // exactly now - 3600
            TrueContraction(start: 500_000, end: 500_060),   // "now"
        ]
        return makeManifest(
            caseName: "contractionAtExactlyNowMinus3600", rule: "fiveOneOne",
            trueContractions: contractions, actions: faithfulActions(contractions),
            expectedDetection: [
                "probe:500000",
                "start exactly 3600s before probe is in-window; its interval to the next counts",
            ]
        )
    }

    /// Boundary: one second earlier than the window edge — now outside the
    /// window, and the interval from it to the next contraction must **not** be
    /// counted.
    private static func contractionAtExactlyNowMinus3601() -> ScenarioManifest {
        let contractions = [
            TrueContraction(start: 496_399, end: 496_459),   // exactly now - 3601
            TrueContraction(start: 500_000, end: 500_060),   // "now"
        ]
        return makeManifest(
            caseName: "contractionAtExactlyNowMinus3601", rule: "fiveOneOne",
            trueContractions: contractions, actions: faithfulActions(contractions),
            expectedDetection: [
                "probe:500000",
                "start 3601s before probe is out of window; no interval to the next",
            ]
        )
    }

    /// Boundary: the six-contraction evidence floor, probed at the two instants
    /// one contraction apart that straddle it — five present (no verdict
    /// possible) and, a moment later, six present (a verdict becomes possible).
    private static func fiveInWindowThenSix() -> ScenarioManifest {
        let contractions = evenStream(count: 6, firstStart: 0, interval: 300, duration: 60)
        return makeManifest(
            caseName: "fiveInWindowThenSix", rule: "fiveOneOne",
            trueContractions: contractions, actions: faithfulActions(contractions),
            expectedDetection: [
                "probe:1499", "probe:1500",
                "five contractions present, then a sixth, one contraction apart",
            ]
        )
    }

    // MARK: - 17-20. Average floors

    /// Boundary: the minimum count for a printed interval average. Three
    /// contractions give exactly two intervals — the floor, not one below it.
    private static func exactlyTwoIntervals() -> ScenarioManifest {
        let contractions = evenStream(count: 3, firstStart: 0, interval: 300, duration: 60)
        return makeManifest(
            caseName: "exactlyTwoIntervals", rule: "fiveOneOne",
            trueContractions: contractions, actions: faithfulActions(contractions),
            expectedDetection: ["three contractions, two intervals: the floor for a printed average"]
        )
    }

    /// Boundary: one below the interval-average floor. Two contractions give
    /// exactly one interval, which is not enough to average.
    private static func exactlyOneInterval() -> ScenarioManifest {
        let contractions = evenStream(count: 2, firstStart: 0, interval: 300, duration: 60)
        return makeManifest(
            caseName: "exactlyOneInterval", rule: "fiveOneOne",
            trueContractions: contractions, actions: faithfulActions(contractions),
            expectedDetection: ["two contractions, one interval: below the floor, no average"]
        )
    }

    /// Boundary: the minimum count for a printed duration average. Three
    /// completed, non-suspect durations — the floor, not one below it.
    private static func exactlyThreeUsableDurations() -> ScenarioManifest {
        let contractions = evenStream(count: 3, firstStart: 0, interval: 300, duration: 60)
        return makeManifest(
            caseName: "exactlyThreeUsableDurations", rule: "fiveOneOne",
            trueContractions: contractions, actions: faithfulActions(contractions),
            expectedDetection: ["three completed non-suspect durations: the floor for a printed average"]
        )
    }

    /// Boundary: one below the duration-average floor. Two completed durations
    /// is not enough to average.
    private static func exactlyTwoUsableDurations() -> ScenarioManifest {
        let contractions = evenStream(count: 2, firstStart: 0, interval: 300, duration: 60)
        return makeManifest(
            caseName: "exactlyTwoUsableDurations", rule: "fiveOneOne",
            trueContractions: contractions, actions: faithfulActions(contractions),
            expectedDetection: ["two completed durations: below the floor, no average"]
        )
    }

    // MARK: - 21-22. Sustainment

    /// Boundary: the rule's one-hour sustainment requirement, met exactly (`>=`).
    /// The episode is precisely 3600 s old at the probe instant — the **met**
    /// side.
    private static func patternLengthExactly3600() -> ScenarioManifest {
        let contractions = evenStream(count: 19, firstStart: 0, interval: 200, duration: 90)
        return makeManifest(
            caseName: "patternLengthExactly3600", rule: "fiveOneOne",
            trueContractions: contractions, actions: faithfulActions(contractions),
            expectedDetection: ["probe:3600", "episode exactly one hour old: sustained is met on >="]
        )
    }

    /// Boundary: one second short of the one-hour sustainment requirement — the
    /// episode has not yet been running long enough, the **missed** side.
    private static func patternLengthExactly3599() -> ScenarioManifest {
        let contractions = evenStream(count: 19, firstStart: 0, interval: 200, duration: 90)
        return makeManifest(
            caseName: "patternLengthExactly3599", rule: "fiveOneOne",
            trueContractions: contractions, actions: faithfulActions(contractions),
            expectedDetection: ["probe:3599", "episode one second short of an hour old: sustained not yet met"]
        )
    }

    // MARK: - 23-26. Degenerate and adversarial-arithmetic shapes

    /// Boundary: a `tapEnd` landing on the same second as its `tapStart`. Zero
    /// length is a legal recorded duration, not a suspect one — suspicion starts
    /// strictly above 180 s, and 0 is nowhere near it.
    private static func zeroLengthContraction() -> ScenarioManifest {
        let contractions = [
            TrueContraction(start: 0, end: 60),
            TrueContraction(start: 300, end: 360),
            TrueContraction(start: 600, end: 660),
            TrueContraction(start: 900, end: 900),     // zero length: legal, not suspect
            TrueContraction(start: 1200, end: 1260),
            TrueContraction(start: 1500, end: 1560),
        ]
        return makeManifest(
            caseName: "zeroLengthContraction", rule: "fiveOneOne",
            trueContractions: contractions, actions: faithfulActions(contractions),
            expectedDetection: ["tapEnd on the same second as tapStart: zero length, legal, not suspect"]
        )
    }

    /// Boundary: a recorded end earlier than its own start, reachable only
    /// through a clock set backward between the two taps. The fold must clamp to
    /// zero length — never store or propagate a negative duration.
    private static func endBeforeStart() -> ScenarioManifest {
        let actions: [ScenarioAction] = [
            .tapStart(at: 1000),
            .clockSet(at: 1010, deltaSeconds: -120),
            .tapEnd(at: 1020),   // effective 1020 - 120 = 900, before start(1000) -> clamps to 1000
        ]
        return makeManifest(
            caseName: "endBeforeStart", rule: "fiveOneOne",
            trueContractions: [TrueContraction(start: 1000, end: 1060)], actions: actions,
            expectedDetection: ["clock jump makes the end precede the start; must clamp to zero length, never negative"]
        )
    }

    /// Boundary: two records that end up sharing the same start second. Nothing
    /// in this corpus depends on which one is "first" except
    /// `ReplayEngine.sorted`'s documented tie-break — ascending `createdBy` —
    /// and this pins that answer.
    private static func equalStartTies() -> ScenarioManifest {
        let contractions = [
            TrueContraction(start: 100, end: 100),   // zero length, resolves first
            TrueContraction(start: 100, end: 160),
        ]
        return makeManifest(
            caseName: "equalStartTies", rule: "fiveOneOne",
            trueContractions: contractions, actions: faithfulActions(contractions),
            expectedDetection: ["two records share start=100: ReplayEngine.sorted's createdBy tie-break decides order"]
        )
    }

    /// Boundary: the floor beneath every other floor here. One contraction gives
    /// no interval, no duration-window span greater than itself, and no average
    /// of anything — the degenerate case a naive implementation renders as a
    /// false zero instead of an absence.
    private static func singleContraction() -> ScenarioManifest {
        let contractions = [TrueContraction(start: 0, end: 60)]
        return makeManifest(
            caseName: "singleContraction", rule: "fiveOneOne",
            trueContractions: contractions, actions: faithfulActions(contractions),
            expectedDetection: ["one contraction: no interval, no averages — must not render as a false zero"]
        )
    }

    // MARK: - 27-30. RUBRIC §4 weakness seeds (F-0024)
    //
    // W1, W2 and W4 close to specific `expectedDetection` values named by the F-0024
    // disposition itself, matching RUBRIC §4's own "Must be caught by" column filtered
    // to what a Layer-E corpus battery can reach (its T3 half needs a screenshot and an
    // agent, not a probe grid). W10's is reasoned out at its own case below, because
    // RUBRIC's table names only a Layer-J check for that row.

    /// W1: verdict flapping near the share's own two-thirds boundary. Decision 0024
    /// removed the old mean-drift mechanism outright — a straddling 270/330
    /// alternation no longer crosses anything, pinned at zero flaps by
    /// `WeaknessDetectionTests.w1FlappingIsCounted` — but the latch (0025) still has a
    /// residual to guard: a share that hovers near its own 2/3 line as records age out
    /// of the window. 290/315 sits ten seconds inside the 300 s threshold on one side
    /// and fifteen outside it on the other, tight enough to keep testing that edge for
    /// the run's whole length rather than settling comfortably to one side of it the
    /// way 270/330 does.
    private static func flappingNearTheShareBoundary() -> ScenarioManifest {
        var starts: [Int64] = [0]
        for index in 0..<59 {
            starts.append(starts[index] + (index.isMultiple(of: 2) ? 290 : 315))
        }
        let contractions = starts.map { TrueContraction(start: $0, end: $0 + 70) }
        return makeManifest(
            caseName: "flappingNearTheShareBoundary", rule: "fiveOneOne",
            trueContractions: contractions, actions: faithfulActions(contractions),
            expectedDetection: [
                "T1-04",
                "290/315s alternation held near the share's 2/3 boundary: RUBRIC W1 seed",
            ]
        )
    }

    /// W2: coupling recorded **faithfully** — no phantom tap. (That mechanism is a
    /// different one, F-0027, and it is `WeaknessDetectionTests
    /// .phantomTapsInACoupledTroughDefeatAnyIntervalStatistic` — see that test's own
    /// doc comment for why it is not this weakness.) Alternating 120 s / 480 s
    /// start-to-start gaps average to exactly 5:00, the value a plain mean would have
    /// passed on; the share of gaps at or under the threshold is exactly half, which
    /// `frequencyMet`'s two-thirds rule refuses outright, and which stays refused
    /// under a share judged with a margin too — decision 0024's own text names this
    /// exact shape as the one a margined share still catches. Twenty contractions is
    /// comfortably past the evidence floor for the whole run, not just at one probe.
    private static func couplingFaithfulShareRefuses() -> ScenarioManifest {
        var starts: [Int64] = [0]
        for index in 0..<19 {
            starts.append(starts[index] + (index.isMultiple(of: 2) ? 120 : 480))
        }
        let contractions = starts.map { TrueContraction(start: $0, end: $0 + 70) }
        return makeManifest(
            caseName: "couplingFaithfulShareRefuses", rule: "fiveOneOne",
            trueContractions: contractions, actions: faithfulActions(contractions),
            expectedDetection: [
                "T1-02",
                "faithful 120/480s coupling, mean exactly 5:00, share 50%: RUBRIC W2 seed",
            ]
        )
    }

    /// W4: burst, lull, tap. Six quick contractions clear the evidence floor, then a
    /// 2590 s silence — RUBRIC's own "50-min lull" language for this shape, and
    /// F-0010's finding text names the same 2590 s — before one more lands.
    /// `patternLength` alone still clears whatever elapsed-time claim it always did;
    /// decision 0026's continuity requirement is what has to refuse `sustainedMet`
    /// here, since the lull sits inside the window at the reconnecting tap and blows
    /// past three times the rule's own spacing many times over.
    private static func burstLullTap() -> ScenarioManifest {
        let burst = evenStream(count: 6, firstStart: 0, interval: 90, duration: 75)
        let reconnect = TrueContraction(
            start: burst[5].start + 2590, end: burst[5].start + 2590 + 75
        )
        let contractions = burst + [reconnect]
        return makeManifest(
            caseName: "burstLullTap", rule: "fiveOneOne",
            trueContractions: contractions, actions: faithfulActions(contractions),
            expectedDetection: [
                "T1-02",
                "six quick + 2590s lull + one tap: RUBRIC W4 seed (burst-lull-tap)",
            ]
        )
    }

    /// W10: whole-episode `lastInterval` contradicts the windowed `averageInterval`.
    /// Fourteen tight 60 s contractions, then a 2700 s (45-min) lull, then one more
    /// landing exactly at the probe: `lastInterval` reads the full 45 minutes while
    /// the windowed mean — diluted by the other thirteen 60 s gaps still inside the
    /// hour — reads well under four and a half.
    ///
    /// **Why this names T0-02 and not T1-02.** RUBRIC §4's own table lists only
    /// T3-Q2 for this row — a Layer-J judgment call over a screenshot, unreachable by
    /// a Layer-E corpus battery — and T1-02 is not a fallback for it: this shape
    /// cannot actually produce a false met for T1-02 to catch. Decision 0026's
    /// continuity requirement already refuses `sustainedMet` here (the 2700 s
    /// in-window gap is many times triple the rule's own spacing), so `met` reads
    /// false at the very probe where the lastInterval/average contradiction is
    /// sharpest — the same guard that closes W4 above. What a Layer-E run genuinely
    /// exercises on this scenario is oracle agreement between the two figures
    /// themselves, independently derived and made to diverge on purpose: T0-02.
    private static func lastIntervalContradictsTheWindow() -> ScenarioManifest {
        let tight = evenStream(count: 14, firstStart: 0, interval: 60, duration: 70)
        let lull = TrueContraction(
            start: tight[13].start + 2700, end: tight[13].start + 2700 + 70
        )
        let contractions = tight + [lull]
        return makeManifest(
            caseName: "lastIntervalContradictsTheWindow", rule: "fiveOneOne",
            trueContractions: contractions, actions: faithfulActions(contractions),
            expectedDetection: [
                "T0-02",
                "probe:3480",
                "14x60s + 2700s lull + one tap: lastInterval 45m beside a ~4m windowed mean (RUBRIC W10 seed)",
            ]
        )
    }

    // MARK: - 30b. SP-207's corpus half (F-0037)

    /// Fast from the first contraction — the shape decision 0040 was written for,
    /// and the shape SP-207's differential sweep proved the sampled corpus never
    /// produces: `Archetypes.precipitous` ramps down log-linearly from 8:00, so its
    /// gaps sit inside fast-met's half-threshold only in the ramp's final stretch,
    /// shorter than the windowed share can clear — by then the ordinary verdict is
    /// already serving it. A labor that is 2:00 apart from onset is a different
    /// physiology, and without this seed the fast-met state had agreement evidence
    /// everywhere (373 K probes, zero oracle disagreement) but detection evidence
    /// nowhere in the corpus. Exact arithmetic on purpose: 120 s starts, 80 s
    /// durations, 45 minutes — inside the hour `sustainedMet` needs, past the
    /// 20-minute floor 0040 sets, every gap inside 150 s, so `fastMet` must be true
    /// and `met` must not.
    private static func fastFromTheFirstContraction() -> ScenarioManifest {
        let starts: [Int64] = (0..<23).map { Int64($0) * 120 }
        let contractions = starts.map { TrueContraction(start: $0, end: $0 + 80) }
        return makeManifest(
            caseName: "fastFromTheFirstContraction", rule: "fiveOneOne",
            trueContractions: contractions, actions: faithfulActions(contractions),
            expectedDetection: [
                "23x120s/80s from onset, 44 min: fastMet true and met false (0040, F-0037)",
            ]
        )
    }

    // MARK: - 31. F-0011's corpus half

    /// A multi-hour backward `clockSet`, timezone-correction shaped, arriving after
    /// an established six-contraction episode. `clockSet` rewrites nothing already
    /// stored (see `advClockBackMidContraction`) — the six taps below keep the
    /// stamps they were made with — it only bends what `now` would read from this
    /// instant forward. Three hours back, one hour into the episode, lands the next
    /// live read of `now` a clean two hours *before* `episodeStart`
    /// (`3600 - 10800 = -7200`): the negative `patternLength` F-0011's clamp exists
    /// for, and the shape no corpus scenario exercised before it
    /// (`docs/qa/FINDINGS.md` F-0011, "Not done here").
    ///
    /// **What Layer E can actually see here, and why not more.** Every consumer of
    /// this corpus that computes a pattern — `PureSweep`, and even the pin suite's
    /// own `noProbeEverProducesANegativeFigure` — folds the record set and reads
    /// `now` from the *same* probe (`ReplayEngine.probeTimes`, itself filtered to
    /// `>= 0`). A record only folds in once its own effective time has reached that
    /// probe, so `episodeStart <= probe` holds by construction at every probe either
    /// of them ever tries — this mechanism is structurally unreachable by the
    /// coupled-probe sweep, on this scenario or any other, however the numbers are
    /// chosen. `CorpusStabilityTests` proves the clamp holds here by decoupling the
    /// two by hand, the way a live `Date()` read would after a real clock
    /// correction. T0-02 is what the standard sweep genuinely exercises on this
    /// scenario — ordinary oracle agreement over whatever the coupled grid *can*
    /// reach. T0-11 (never renders a negative figure) and T2-01 (parse-back
    /// formatting) are the presentation half, and need a `now` genuinely decoupled
    /// from the fold — a real app pass with the simulator's own clock set back,
    /// Layer A territory, not this one.
    private static func timezoneCorrectionBeforeEpisodeStart() -> ScenarioManifest {
        let established = sixGoodStream()
        var actions = faithfulActions(established)
        actions.append(.clockSet(at: 3600, deltaSeconds: -10_800))
        return makeManifest(
            caseName: "timezoneCorrectionBeforeEpisodeStart", rule: "fiveOneOne",
            trueContractions: established, actions: actions,
            expectedDetection: [
                "T0-02",
                "3h clockSet 1h into the episode: now would read episodeStart-7200s (F-0011 corpus half)",
            ]
        )
    }

    // MARK: - Adversarial 1-10. Store abuse

    /// Store abuse: undo bypasses the single-running-record guard. Deleting a
    /// running contraction and restoring it after a second one has started
    /// leaves two records open at once; the next `tapEnd` must close the
    /// **latest-started** of the two (the store's documented fetch order), not
    /// the earliest and not the most recently restored.
    private static func advRestoreWhileRunning() -> ScenarioManifest {
        var actions: [ScenarioAction] = [.tapStart(at: 0)]                 // A: createdBy 0
        let aIndex = actions.count - 1
        actions.append(.deleteRecord(at: 10, createdBy: aIndex))            // delete A mid-run
        actions.append(.tapStart(at: 20))                                   // B: createdBy 2, now running
        actions.append(.undoDelete(at: 30, createdBy: aIndex))              // A restored, still running too
        actions.append(.tapEnd(at: 40))                                     // closes B (start 20), not A (start 0)
        return makeManifest(
            caseName: "advRestoreWhileRunning", rule: "fiveOneOne",
            trueContractions: sixGoodStream(), actions: actions,
            expectedDetection: ["tapEnd after restore-while-running must close the latest-started record"]
        )
    }

    /// Store abuse: delete-all-then-tap. Six contractions are built and every
    /// one is deleted by its own `createdBy`; the following tap must start a
    /// fresh pattern at count one, not resurrect an average from records that no
    /// longer exist.
    private static func advDeleteAllThenTap() -> ScenarioManifest {
        let baseline = sixGoodStream()
        var actions = faithfulActions(baseline)
        let startIndices = (0..<6).map { nthTapStartIndex($0, in: actions) }
        for (offset, createdBy) in startIndices.enumerated() {
            actions.append(.deleteRecord(at: 2000 + Int64(offset) * 10, createdBy: createdBy))
        }
        actions.append(.tapStart(at: 3000))   // the store must be empty going into this tap
        return makeManifest(
            caseName: "advDeleteAllThenTap", rule: "fiveOneOne",
            trueContractions: baseline, actions: actions,
            expectedDetection: ["pattern must rebuild from nothing after every existing record is deleted"]
        )
    }

    /// Store abuse: `clearAll` mid-episode. A healthy, regularly-spaced run is
    /// wiped partway through, then tapping resumes; nothing from before the
    /// clear may contribute to the pattern the resumed taps build.
    private static func advClearAllMidEpisode() -> ScenarioManifest {
        let before = evenStream(count: 8, firstStart: 0, interval: 200, duration: 90)
        let after = evenStream(count: 8, firstStart: 3000, interval: 200, duration: 90)
        var actions = faithfulActions(before)
        actions.append(.clearAll(at: 2000))              // wipes the store partway through `before`
        actions.append(contentsOf: faithfulActions(after))
        return makeManifest(
            caseName: "advClearAllMidEpisode", rule: "fiveOneOne",
            trueContractions: before + after, actions: actions,
            expectedDetection: ["clearAll mid-episode must not leak pre-clear evidence into the resumed pattern"]
        )
    }

    /// Store abuse: `clearAll` is deliberately un-undoable. A delete is followed
    /// by a clear, then an attempt to undo the original delete; the clear also
    /// drops the remembered-delete table, so the undo must find nothing and do
    /// nothing.
    private static func advUndoAfterClearAll() -> ScenarioManifest {
        let baseline = sixGoodStream()
        var actions = faithfulActions(baseline)
        let target = nthTapStartIndex(0, in: actions)
        actions.append(.deleteRecord(at: 2000, createdBy: target))
        actions.append(.clearAll(at: 2010))
        actions.append(.undoDelete(at: 2020, createdBy: target))   // no-op: clearAll dropped the memory of it
        return makeManifest(
            caseName: "advUndoAfterClearAll", rule: "fiveOneOne",
            trueContractions: baseline, actions: actions,
            expectedDetection: ["undoDelete issued after clearAll must be a no-op"]
        )
    }

    /// Store abuse: the same `createdBy` deleted twice. The first delete removes
    /// the live record; the second finds nothing there and must do nothing — not
    /// touch whatever else now occupies the store.
    private static func advDoubleDelete() -> ScenarioManifest {
        let baseline = sixGoodStream()
        var actions = faithfulActions(baseline)
        let target = nthTapStartIndex(2, in: actions)
        actions.append(.deleteRecord(at: 2000, createdBy: target))
        actions.append(.deleteRecord(at: 2010, createdBy: target))   // no-op: already gone
        return makeManifest(
            caseName: "advDoubleDelete", rule: "fiveOneOne",
            trueContractions: baseline, actions: actions,
            expectedDetection: ["second deleteRecord of an already-deleted createdBy is a no-op"]
        )
    }

    /// Store abuse: `undoDelete` for a `createdBy` that was never deleted. There
    /// is nothing in the remembered-delete table for it, so the action must do
    /// nothing — the live record must not be touched or duplicated.
    private static func advUndoWithoutDelete() -> ScenarioManifest {
        let baseline = sixGoodStream()
        var actions = faithfulActions(baseline)
        let target = nthTapStartIndex(4, in: actions)
        actions.append(.undoDelete(at: 2000, createdBy: target))   // no-op: never deleted
        return makeManifest(
            caseName: "advUndoWithoutDelete", rule: "fiveOneOne",
            trueContractions: baseline, actions: actions,
            expectedDetection: ["undoDelete of a never-deleted createdBy is a no-op"]
        )
    }

    /// Store abuse: five consecutive `tapEnd`s with nothing running. Every one
    /// must be a no-op; the store must hold zero records afterward. No body
    /// activity at all, which is exactly what an idle-tapping session looks like.
    private static func advEndWhileIdleRepeated() -> ScenarioManifest {
        let actions: [ScenarioAction] = [
            .tapEnd(at: 0), .tapEnd(at: 10), .tapEnd(at: 20), .tapEnd(at: 30), .tapEnd(at: 40),
        ]
        return makeManifest(
            caseName: "advEndWhileIdleRepeated", rule: "fiveOneOne",
            trueContractions: [], actions: actions,
            expectedDetection: ["repeated tapEnd with nothing running must leave the store untouched"]
        )
    }

    /// Store abuse: six `tapStart`s in a row with no `tapEnd` between them. The
    /// store refuses to stack a running record, so only the first creates one;
    /// the other five must be no-ops against the still-open record.
    private static func advStartWhileRunningRepeated() -> ScenarioManifest {
        let actions: [ScenarioAction] = [
            .tapStart(at: 0), .tapStart(at: 10), .tapStart(at: 20),
            .tapStart(at: 30), .tapStart(at: 40), .tapStart(at: 50),
        ]
        return makeManifest(
            caseName: "advStartWhileRunningRepeated", rule: "fiveOneOne",
            trueContractions: [TrueContraction(start: 0, end: 80)], actions: actions,
            expectedDetection: ["only the first of six repeated tapStarts creates a record"]
        )
    }

    /// Store abuse: the clock set backward while a contraction is running. The
    /// closing tap's effective time lands before its own start; the fold must
    /// clamp the stored end to the start rather than record a negative duration.
    private static func advClockBackMidContraction() -> ScenarioManifest {
        let actions: [ScenarioAction] = [
            .tapStart(at: 1000),
            .clockSet(at: 1010, deltaSeconds: -600),
            .tapEnd(at: 1020),   // effective 1020 - 600 = 420, before start(1000) -> clamps to 1000
        ]
        return makeManifest(
            caseName: "advClockBackMidContraction", rule: "fiveOneOne",
            trueContractions: [TrueContraction(start: 1000, end: 1060)], actions: actions,
            expectedDetection: ["end effective-time before start must clamp to zero length, never negative"]
        )
    }

    /// Store abuse: the clock walked back between two contractions. The second
    /// contraction's effective start lands before the first's effective end —
    /// physically impossible for a body, reachable only through a clock — and
    /// `ReplayEngine.sorted`'s (start, createdBy) ordering must still produce a
    /// definite total order over the two overlapping records.
    private static func advClockForwardOverlap() -> ScenarioManifest {
        let actions: [ScenarioAction] = [
            .tapStart(at: 0), .tapEnd(at: 60),                    // record 1: effective [0, 60]
            .clockSet(at: 70, deltaSeconds: -1800),
            .tapStart(at: 1830), .tapEnd(at: 1890),               // record 2: effective [30, 90] — overlaps record 1
        ]
        return makeManifest(
            caseName: "advClockForwardOverlap", rule: "fiveOneOne",
            trueContractions: [
                TrueContraction(start: 0, end: 60), TrueContraction(start: 300, end: 360),
            ],
            actions: actions,
            expectedDetection: ["clock-induced overlap between two records must still sort to a total order"]
        )
    }
}
