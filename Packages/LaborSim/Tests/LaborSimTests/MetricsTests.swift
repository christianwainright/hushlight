import Foundation
import Testing
@testable import LaborSim

/// The T1 arithmetic, pinned on hand-built tick series.
///
/// These metrics are the only figures Phase 5's report ranks findings by, which makes
/// them an authoritative path in the DoD's sense: a suppression counter that quietly
/// stopped counting would make the harness report "nothing to see" forever, and no
/// other test in the package would notice.
@Suite("T1 metrics")
struct MetricsTests {

    private func zone(_ kind: TruthZoneKind, _ from: Int64, _ to: Int64) -> TruthZone {
        TruthZone(rule: "fiveOneOne", kind: kind, from: from, to: to)
    }

    private func timeline(_ zones: [TruthZone]) -> TruthTimeline {
        TruthTimeline(episodesTrue: [], zones: zones, events: [], expectedSuspects: [])
    }

    private func ticks(_ entries: [(Int64, VerdictState)]) -> [ScenarioTick] {
        entries.map { ScenarioTick(at: $0.0, state: $0.1) }
    }

    /// The three-column form, for series where the presented (latched) state and
    /// the raw (unlatched) state diverge — `rawFlaps` exists to see exactly that gap
    /// (decision 0025 §4).
    private func ticks(_ entries: [(Int64, VerdictState, VerdictState)]) -> [ScenarioTick] {
        entries.map { ScenarioTick(at: $0.0, state: $0.1, rawState: $0.2) }
    }

    private func compute(
        _ series: [ScenarioTick], _ truth: TruthTimeline,
        profile: String = NoiseProfileID.clean.rawValue, cadence: Int64 = 60
    ) -> T1MetricSet {
        T1Metrics.compute(
            ticks: series, truth: truth, rule: "fiveOneOne",
            noiseProfile: profile, cadence: cadence
        )
    }

    // MARK: T1-01

    @Test func onsetLagIsTheSignedDifferenceAndFlagsOnlyWhenLate() {
        let truth = timeline([zone(.mustNotFire, 0, 999), zone(.mustFire, 1000, 20_000)])
        let late = compute(ticks([(0, .noVerdict), (1000, .partial), (1500, .met)]), truth)
        #expect(late.onsetLagSeconds == 500)
        #expect(!late.flags.contains("T1-01"))

        let tooLate = compute(ticks([(0, .noVerdict), (1000, .partial), (2000, .met)]), truth)
        #expect(tooLate.onsetLagSeconds == 1000)
        #expect(tooLate.flags.contains("T1-01"), "10 min is the clean threshold")

        // A noisy thumb earns twice the latitude for the same lag.
        let noisy = compute(ticks([(0, .noVerdict), (1000, .partial), (2000, .met)]), truth,
                            profile: NoiseProfileID.typicalSolo.rawValue)
        #expect(!noisy.flags.contains("T1-01"))

        // Firing early is a negative lag, not a small one — it is a different defect
        // and T1-02 is the check that names it.
        let early = compute(ticks([(0, .met), (1000, .met)]), truth)
        #expect(early.onsetLagSeconds == -1000)
    }

    // MARK: T1-02

    @Test func falseMetCountsTicksAndCappedSeconds() {
        let truth = timeline([zone(.mustNotFire, 0, 5000)])
        let metrics = compute(ticks([(0, .met), (60, .met), (120, .partial), (3000, .met)]), truth)
        #expect(metrics.falseMetTicks == 3)
        // 60 + 60 (capped from the 2880 s jump) + 1 for the final tick.
        #expect(metrics.falseMetSeconds == 121)
        #expect(metrics.flags.contains("T1-02"))
    }

    @Test func aMetTickInsideGrayIsNotAFalseMet() {
        let truth = timeline([zone(.gray, 0, 5000)])
        #expect(compute(ticks([(0, .met), (60, .met)]), truth).falseMetTicks == 0)
    }

    /// Decision 0025: a latched-only met tick (`state == .met`, `rawState != .met`)
    /// landing inside the ten-minute release window of a genuine `mustFire` exit is
    /// the latch doing exactly what it was built to do, not a false positive.
    @Test func aLatchedOnlyMetTickWithinTenMinutesOfAMustFireExitIsGracedNotFalse() {
        let truth = timeline([zone(.mustFire, 0, 1000), zone(.mustNotFire, 1001, 5000)])
        let series: [(Int64, VerdictState, VerdictState)] = [
            (0, .met, .met),
            (1000, .met, .met),
            // Ten minutes (600 s) past the mustFire exit at 1000: still inside the
            // release window — latched-only, so graced.
            (1600, .met, .partial),
        ]
        let graced = compute(ticks(series), truth)
        #expect(graced.falseMetTicks == 0)
        #expect(graced.falseMetSeconds == 0)
        #expect(graced.latchGracedTicks == 1)
        #expect(!graced.flags.contains("T1-02"))

        // The same tick eleven minutes (660 s) out has left the window: counted.
        let tooLate: [(Int64, VerdictState, VerdictState)] = [
            (0, .met, .met),
            (1000, .met, .met),
            (1660, .met, .partial),
        ]
        let counted = compute(ticks(tooLate), truth)
        #expect(counted.falseMetTicks == 1)
        #expect(counted.latchGracedTicks == 0)
        #expect(counted.flags.contains("T1-02"))
    }

    /// A raw-met tick inside `mustNotFire` is condemned regardless of the latch —
    /// there truth itself, not the latch, is the one saying the app is wrong, even
    /// if the tick happens to sit right after a `mustFire` zone closed.
    @Test func aRawMetTickInsideMustNotFireIsCountedRegardlessOfTheLatch() {
        let truth = timeline([zone(.mustFire, 0, 1000), zone(.mustNotFire, 1001, 5000)])
        let series: [(Int64, VerdictState, VerdictState)] = [
            (0, .met, .met),
            (1000, .met, .met),
            (1200, .met, .met), // raw still met — not latched-only.
        ]
        let metrics = compute(ticks(series), truth)
        #expect(metrics.falseMetTicks == 1)
        #expect(metrics.latchGracedTicks == 0)
        #expect(metrics.flags.contains("T1-02"))
    }

    // MARK: T1-01 (F-0018) — early fire

    /// Every early met tick lands in gray: the app noticing early is a judgement
    /// call truth has no standing to fault, so the magnitude is recorded but the
    /// scenario is not flagged.
    @Test func anEarlyFireWhollyInGrayIsRecordedButNotFlagged() {
        let truth = timeline([zone(.gray, 0, 1199), zone(.mustFire, 1200, 20_000)])
        // App fires at t=0, truth's first mustFire is 1200 (20 min) later.
        let metrics = compute(ticks([(0, .met), (1200, .met)]), truth)
        #expect(metrics.earlyFireSeconds == 1200)
        #expect(metrics.earlyFireGraded == "gray")
        #expect(!metrics.flags.contains("T1-01"))
    }

    /// The same early onset, but at least one of the early met ticks sits inside a
    /// `mustNotFire` zone — truth actively forbids it there, so T1-01 names it too
    /// (T1-02 already does, separately).
    @Test func anEarlyFireTouchingMustNotFireIsFlagged() {
        let truth = timeline([
            zone(.mustNotFire, 0, 599), zone(.gray, 600, 1199), zone(.mustFire, 1200, 20_000),
        ])
        let metrics = compute(ticks([(0, .met), (600, .met), (1200, .met)]), truth)
        #expect(metrics.earlyFireSeconds == 1200)
        #expect(metrics.earlyFireGraded == "mustNotFire")
        #expect(metrics.flags.contains("T1-01"))
    }

    /// Ten minutes early sits under the fifteen-minute threshold: no early fire
    /// recorded at all, defensible or not.
    @Test func anOnsetTenMinutesEarlyRecordsNoEarlyFire() {
        let truth = timeline([zone(.gray, 0, 599), zone(.mustFire, 600, 20_000)])
        let metrics = compute(ticks([(0, .met), (600, .met)]), truth)
        #expect(metrics.earlyFireSeconds == nil)
        #expect(metrics.earlyFireGraded == nil)
        #expect(!metrics.flags.contains("T1-01"))
    }

    // MARK: T1-03

    @Test func suppressionNeedsAHalfHourOfUnambiguousTruth() {
        let short = timeline([zone(.mustFire, 0, 1500)])
        #expect(!compute(ticks([(0, .noVerdict), (600, .partial)]), short).suppressed)

        let long = timeline([zone(.mustFire, 0, 3600)])
        let metrics = compute(ticks([(0, .noVerdict), (600, .partial), (3000, .partial)]), long)
        #expect(metrics.suppressed)
        #expect(metrics.suppressedZoneSeconds == 3601)
        #expect(metrics.flags.contains("T1-03"))

        // One met tick anywhere inside the zone is enough to clear it.
        #expect(!compute(ticks([(0, .noVerdict), (600, .met), (3000, .partial)]), long).suppressed)
    }

    // MARK: T1-04

    @Test func flapsCountOnlyWhereTruthHeldSteady() {
        let truth = timeline([zone(.mustFire, 0, 10_000)])
        let metrics = compute(
            ticks([(0, .met), (60, .partial), (120, .met), (180, .partial), (240, .met), (300, .noVerdict)]),
            truth
        )
        #expect(metrics.flapCount == 3)
        #expect(metrics.worstFlapsIn30Minutes == 3)
        #expect(metrics.flags.contains("T1-04"))

        // The same churn where truth is gray is not a flap: dropping a borderline
        // verdict is the engine being honest, not the screen thrashing.
        let gray = timeline([zone(.gray, 0, 10_000)])
        #expect(compute(ticks([(0, .met), (60, .partial), (120, .met), (180, .partial)]), gray)
            .flapCount == 0)
    }

    /// Flap attribution (F-0009's residual): the destination state of every flap is
    /// exactly one of `.noVerdict` or `.partial`, so the two counters partition
    /// `flapCount` completely — this is the number a report uses to prove the
    /// pattern-level latch collapsed the status-disappearing majority.
    @Test func flapDestinationsPartitionFlapCountExactly() {
        let truth = timeline([zone(.mustFire, 0, 10_000)])
        let metrics = compute(
            ticks([
                (0, .met), (60, .noVerdict), // met -> noVerdict
                (120, .met), (180, .partial), // met -> partial
                (240, .met), (300, .noVerdict), // met -> noVerdict
            ]),
            truth
        )
        #expect(metrics.flapCount == 3)
        #expect(metrics.flapToNoVerdict == 2)
        #expect(metrics.flapToPartial == 1)
        #expect(metrics.flapToNoVerdict + metrics.flapToPartial == metrics.flapCount)
    }

    /// `rawFlaps` (decision 0025 §4) counts the same met -> not-met transitions the
    /// latch is built to absorb, but over the unlatched series. Here the raw signal
    /// wobbles twice inside a mustFire zone while the latch holds the presented
    /// series steady at `.met` throughout: `flapCount` sees none of it, `rawFlaps`
    /// sees both — the number that says how much churn the latch is doing its job on.
    @Test func rawFlapsCountsTheUnlatchedSeriesSeparatelyFromTheLatchedOne() {
        let truth = timeline([zone(.mustFire, 0, 10_000)])
        let series: [(Int64, VerdictState, VerdictState)] = [
            (0, .met, .met),
            (60, .met, .partial),
            (120, .met, .met),
            (180, .met, .partial),
            (240, .met, .met),
        ]
        let metrics = compute(ticks(series), truth)

        #expect(metrics.flapCount == 0, "the latch should have absorbed every raw wobble")
        #expect(metrics.rawFlaps == 2, "the raw series should still show both underlying flips")
        #expect(!metrics.flags.contains("T1-04"), "the presented series never churned")
    }

    @Test func bannerChurnIsPerHourOfSweptTime() {
        let truth = timeline([zone(.gray, 0, 10_000)])
        // Four transitions across an hour: under the 6/h limit.
        let metrics = compute(
            ticks([(0, .noVerdict), (900, .partial), (1800, .met), (2700, .partial), (3600, .noVerdict)]),
            truth
        )
        #expect(abs(metrics.bannerChurnPerHour - 4) < 0.001)
        #expect(!metrics.flags.contains("T1-04"))
    }

    // MARK: T1-06

    @Test func floorStarvationMeasuresTheGapToTheFirstRenderedFigure() {
        let truth = timeline([zone(.mustFire, 1000, 20_000)])
        let metrics = compute(ticks([(0, .noVerdict), (2000, .partial), (2500, .met)]), truth)
        #expect(metrics.floorStarvationSeconds == 1000)
        #expect(!metrics.flags.contains("T1-06"))

        let starved = compute(ticks([(0, .noVerdict), (4000, .partial), (4500, .met)]), truth)
        #expect(starved.floorStarvationSeconds == 3000)
        #expect(starved.flags.contains("T1-06"))
    }

    // MARK: T1-05

    @Test func theNoiseDeltaIsAgainstTheSameBodyUnderACleanThumb() {
        let clean = T1MetricSet(onsetLagSeconds: 100, flapCount: 1)
        let shifted = T1Metrics.withNoiseDelta(
            T1MetricSet(onsetLagSeconds: 1200, flapCount: 4), clean: clean
        )
        #expect(shifted.noiseDeltaOnsetSeconds == 1100)
        #expect(shifted.noiseDeltaFlaps == 3)
        #expect(shifted.flags.contains("T1-05"))

        let tolerable = T1Metrics.withNoiseDelta(
            T1MetricSet(onsetLagSeconds: 400, flapCount: 1), clean: clean
        )
        #expect(!tolerable.flags.contains("T1-05"))

        // Suppression is the severe half and is not a delta: the clean thumb got the
        // verdict and this one never did.
        let suppressed = T1Metrics.withNoiseDelta(
            T1MetricSet(onsetLagSeconds: nil, suppressed: true), clean: clean
        )
        #expect(suppressed.noiseSuppressedButCleanDidNot == true)
        #expect(suppressed.flags.contains("T1-05"))
        #expect(suppressed.flagged)
    }

    // MARK: Helpers

    @Test func zoneLookupIsExactAtBothEdgesAndNilOutside() {
        let zones = [zone(.mustNotFire, 0, 99), zone(.gray, 100, 199), zone(.mustFire, 200, 299)]
        #expect(T1Metrics.zoneKind(zones, at: 0) == .mustNotFire)
        #expect(T1Metrics.zoneKind(zones, at: 99) == .mustNotFire)
        #expect(T1Metrics.zoneKind(zones, at: 100) == .gray)
        #expect(T1Metrics.zoneKind(zones, at: 299) == .mustFire)
        #expect(T1Metrics.zoneKind(zones, at: 300) == nil)
        #expect(T1Metrics.zoneKind([], at: 0) == nil)
    }

    @Test func densestCountsTheFullestWindowInclusiveOfItsEdges() {
        #expect(T1Metrics.densest([], window: 1800) == 0)
        #expect(T1Metrics.densest([0, 1800], window: 1800) == 2)
        #expect(T1Metrics.densest([0, 1801], window: 1800) == 1)
        #expect(T1Metrics.densest([0, 600, 1200, 5000], window: 1800) == 3)
    }

    /// `flagged` is stored, not computed, so that the JSON carries it. A constructor
    /// that let the two disagree would ship a results file whose summary line
    /// contradicted its own flag list.
    @Test func flaggedTracksTheFlagList() {
        #expect(!T1MetricSet().flagged)
        #expect(T1MetricSet(flags: ["T1-02"]).flagged)
    }
}
