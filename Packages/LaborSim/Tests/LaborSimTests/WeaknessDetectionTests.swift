import Foundation
import LaborKit
import LaborOracle
import Testing
@testable import LaborSim

/// **Rubric validation: does the instrument register the things it was built to see?**
///
/// RUBRIC §4 pre-registers ten weaknesses. A check that no seeded weakness and no
/// engine mutation can trip is dead weight, so each weakness gets a scenario built to
/// provoke it and an assertion that the named measurement moves.
///
/// **These tests are green while the weakness exists.** They go red if the *rubric*
/// goes blind, not if the app gets worse. When a Phase 7 fix removes a weakness, its
/// test flips to asserting non-detection — one line at each says so.
///
/// One structural note that shaped most of what follows, and that Phase 6 should
/// treat as a finding in its own right. `TruthCompiler` judges the noise-free stream
/// with the *same* window, the same start-to-start mean, and the same floors the
/// engine uses — only with margins around them. So under a faithful recording the two
/// compute identical figures and truth can never condemn the app: the verdict lands
/// in truth's gray band by construction. Every false-met and every suppression the
/// harness can detect therefore requires the recorded stream to differ from the true
/// one. That is realistic (it is what thumbs do) but it means "the mean is the wrong
/// statistic for this pattern" — the pure form of W2 and W4 — is invisible to T1 and
/// is asserted structurally below instead.
@Suite("Weakness detection")
struct WeaknessDetectionTests {

    // MARK: - Scenario construction

    /// A tap at every start and a tap at every end, nothing else.
    static func faithful(_ stream: [TrueContraction]) -> [ScenarioAction] {
        var actions: [ScenarioAction] = []
        for contraction in stream.sorted(by: { $0.start < $1.start }) {
            actions.append(.tapStart(at: contraction.start))
            actions.append(.tapEnd(at: contraction.end))
        }
        return actions.sorted { $0.at < $1.at }
    }

    static func evenStream(count: Int, from: Int64, interval: Int64, duration: Int64) -> [TrueContraction] {
        (0..<count).map { index in
            let start = from + Int64(index) * interval
            return TrueContraction(start: start, end: start + duration)
        }
    }

    /// Hand-authored rather than drawn from the corpus. The corpus is pinned by a
    /// digest and its size is asserted elsewhere, so adding nine scenarios to it to
    /// validate the rubric would make every future corpus diff unreadable — see the
    /// deviation note in this phase's report.
    static func manifest(
        _ name: String,
        rule: String = "fiveOneOne",
        stream: [TrueContraction],
        actions: [ScenarioAction]
    ) -> ScenarioManifest {
        var truth = TruthCompiler.compile(trueStream: stream, rules: [rule])
        truth.expectedSuspects = ReplayEngine.expectedSuspects(actions)
        return ScenarioManifest(
            id: "weakness-\(name)",
            seed: 0,
            archetype: ArchetypeID.boundaryBattery.rawValue,
            paramVariant: 0,
            noiseProfile: NoiseProfileID.clean.rawValue,
            rule: rule,
            trueContractions: stream,
            actions: actions,
            truth: truth
        )
    }

    static func pattern(_ manifest: ScenarioManifest, at probe: Int64) -> LaborPattern {
        let records = ReplayEngine.sorted(ReplayEngine.fold(manifest.actions, through: probe))
        return PatternAnalysis.pattern(
            for: HarnessBridge.contractions(records, t0: manifest.t0),
            rule: HarnessBridge.rule(manifest.rule),
            now: HarnessBridge.date(manifest.t0, probe)
        )
    }

    static func oracle(_ manifest: ScenarioManifest, at probe: Int64) -> OraclePattern {
        let records = ReplayEngine.sorted(ReplayEngine.fold(manifest.actions, through: probe))
        return OracleMath.pattern(
            records: HarnessBridge.oracleRecords(records),
            rule: HarnessBridge.oracleRule(manifest.rule),
            now: probe
        )
    }

    static func metrics(_ manifest: ScenarioManifest) -> (T1MetricSet, SweepOutcome) {
        let outcome = PureSweep.run(manifest)
        let metrics = T1Metrics.compute(
            ticks: outcome.ticks, truth: manifest.truth, rule: manifest.rule,
            noiseProfile: manifest.noiseProfile, cadence: outcome.cadence
        )
        return (metrics, outcome)
    }

    /// `met -> not met` transitions in the tick series, regardless of what truth was
    /// doing. T1-04's first half restricts this to truth-met stretches; W1's straddling
    /// probe sits inside truth's gray band by design, so the churn half of T1-04 is
    /// the half that sees it. Keyed on the **presented** state — the latch (0025) is
    /// what a reader actually sees flap.
    static func metFlips(_ ticks: [ScenarioTick]) -> Int {
        var flips = 0
        for index in 1..<max(1, ticks.count)
        where ticks[index - 1].state == .met && ticks[index].state != .met {
            flips += 1
        }
        return flips
    }

    /// The same reduction over the **raw**, unlatched state — kept only so this file
    /// can report how much the latch has left to absorb, not to make a claim about it.
    static func rawMetFlips(_ ticks: [ScenarioTick]) -> Int {
        var flips = 0
        for index in 1..<max(1, ticks.count)
        where ticks[index - 1].rawState == .met && ticks[index].rawState != .met {
            flips += 1
        }
        return flips
    }

    // MARK: - W1 · Verdict flapping — closed by 0024 (T1-04)

    /// Alternating 270 s / 330 s spacing averages to exactly the 300 s line, so under
    /// the old mean-based test which side the windowed mean landed on depended only on
    /// which interval the hour happened to start with — information about nothing —
    /// and the verdict followed it exactly.
    ///
    /// Decision 0024 removed the mechanism outright for this probe, rather than
    /// damping it: a straddling 270/330 alternation puts roughly half of in-window
    /// intervals within the rule's threshold, under the two-thirds share `frequencyMet`
    /// now requires, so it reads false throughout instead of oscillating across a
    /// line. There is no threshold-crossing left here for the verdict to flap across.
    /// The latch (0025) is what remains to guard the residual flapping a share can
    /// still produce near its own 2/3 boundary — its onset-immediacy and ten-minute
    /// release are pinned in LaborKitTests, not here.
    @Test func w1FlappingIsCounted() {
        var starts: [Int64] = [0]
        for index in 0..<39 {
            starts.append(starts[index] + (index.isMultiple(of: 2) ? 270 : 330))
        }
        let stream = starts.map { TrueContraction(start: $0, end: $0 + 70) }
        let manifest = Self.manifest("w1-flapping", stream: stream, actions: Self.faithful(stream))
        let (metrics, outcome) = Self.metrics(manifest)

        let flips = Self.metFlips(outcome.ticks)
        let raw = Self.rawMetFlips(outcome.ticks)
        #expect(flips == 0,
                "W1 closed by 0024: \(flips) latched met-flips, \(raw) raw met-flips, churn \(metrics.bannerChurnPerHour)/h")
        // Measured empirically: the share never crosses 2/3 on this stream, so the raw
        // series never reaches .met either and there is nothing for the latch to hold.
        #expect(raw == 0, "raw verdict flipped \(raw) times on a stream frequencyMet should never pass")
    }

    // MARK: - Phantom taps in a coupled trough — F-0027, a W7-family mechanism, not W2

    /// **Reclassified by F-0027.** This scenario carried the name
    /// `w2CouplingProducesAFalseMet` through the wave-C report, and that was a
    /// mis-attribution from the first triage pass, not a description of what it
    /// models. The **genuine** W2 — coupling *recorded faithfully*, gaps alternating
    /// 120 s / 480 s with no extra tap — is what decision 0024's share actually
    /// closes (its own text names that exact shape), and it now lives as
    /// `BoundaryBattery.couplingFaithfulShareRefuses()` (added for F-0024, in the
    /// standard corpus) and as the frozen `F-0008.json` pin
    /// (`PinTests.f0008_aCoupledMeanAtThresholdNoLongerMeetsFrequency`). Anyone
    /// chasing "does the app still fail W2" wants one of those two, not this test.
    ///
    /// **What this one actually models: a thumb tapping the phantom tightening a
    /// coupled trough produces** — which is what back-labor coupling *feels like*
    /// from the inside, not a recording error a careful thumb would avoid. Back
    /// labor couples: a hard contraction, a short breath, then a long trough. The
    /// body's true mean start-to-start is 330 s — truth condemns it, and a faithful
    /// recording would too, mean or share alike. But the phantom tap does not shift
    /// a statistic toward the threshold the way a mistap or a rounding error would;
    /// it **eliminates the long interval from the recorded stream entirely**,
    /// splitting every ~510 s trough into two ~255 s halves. No statistic computed
    /// over the recorded gaps can see a gap that is no longer in them — a share is
    /// exactly as blind as a mean to it. Measured at a probe deep into the scenario:
    /// `intervalRange` is (150 s, 255 s) over 17 in-window intervals, every single
    /// one under the 300 s threshold, so the share reads 100 %, nowhere near
    /// two-thirds' refusal line.
    ///
    /// This is a recording-fidelity failure of the **W7 family** (missed or phantom
    /// taps corrupting the stream `TruthCompiler` judges against), not a
    /// statistic-choice gap — decision 0024 has nothing to reach here, whichever
    /// statistic it had chosen. F-0027 is decision-needed (duration-aware interval
    /// weighting, or an explicit correction affordance for the tap the user did not
    /// mean — both verdict math, neither free), so the assertions below
    /// **characterise the limitation as it stands**, not a bug still awaiting a fix:
    /// they are pinned to go red if the mechanism ever *stops* reproducing, the same
    /// way `w7MissedTapsSuppressARealVerdict` pins its own accepted gap.
    @Test func phantomTapsInACoupledTroughDefeatAnyIntervalStatistic() {
        var starts: [Int64] = []
        var cursor: Int64 = 0
        for index in 0..<40 {
            starts.append(cursor)
            cursor += index.isMultiple(of: 2) ? 150 : 510
        }
        let stream = starts.map { TrueContraction(start: $0, end: $0 + 80) }

        var actions = Self.faithful(stream)
        // One extra tap in the middle of every long trough.
        for index in stride(from: 1, to: starts.count - 1, by: 2) {
            let midpoint = starts[index] + 255
            actions.append(.tapStart(at: midpoint))
            actions.append(.tapEnd(at: midpoint + 70))
        }
        actions.sort { $0.at < $1.at }

        let manifest = Self.manifest("phantom-tap-coupling", stream: stream, actions: actions)
        let (metrics, _) = Self.metrics(manifest)

        // Direct probe deep into the scenario, well past the evidence floor: the share
        // sees exactly what the phantom tap left it to see — nothing above threshold.
        let deep = Self.pattern(manifest, at: starts[30])
        #expect(deep.guideline?.frequencyMet == true,
                "F-0027 mechanism changed: frequencyMet now \(String(describing: deep.guideline?.frequencyMet)), intervalRange \(String(describing: deep.intervalRange))")

        #expect(metrics.falseMetTicks > 0,
                "F-0027 mechanism changed: no met tick inside a mustNotFire zone")
        #expect(metrics.flags.contains("T1-02"))
    }

    // MARK: - W3 · Dropped interval at the window edge — first half closed by 0023 (T1-01/T1-06)

    /// This weakness had two parts. The first: the interval between the last
    /// out-of-window contraction and the first in-window one was never counted —
    /// intervals lived strictly inside the hour — so a windowed average rested on one
    /// fewer interval than the records in front of it implied. Decision 0023 §3 gives
    /// the window a bridging interval: the gap whose *later* endpoint starts in-window
    /// is last-hour evidence, so `n` in-window records now yield `n` intervals
    /// whenever a record precedes the window, and `n-1` only at the very start of an
    /// episode, where there is nothing to bridge from.
    ///
    /// The second part stands: the verdict can still vanish on a second where nothing
    /// happened at all, once the in-window count itself falls under the evidence
    /// floor (6 -> 5). That cliff is the evidence-count floor, not the interval-basis
    /// question 0023 §3 fixed, and this wave did not touch it.
    @Test func w3TheWindowEdgeDropsAnIntervalAndThenTheVerdict() {
        let stream = Self.evenStream(count: 7, from: 0, interval: 300, duration: 70)
        let manifest = Self.manifest("w3-window-edge", stream: stream, actions: Self.faithful(stream))

        // The bridging interval closes the first half: with a pre-window record to
        // bridge from, n records in the window now yield n intervals, not n-1.
        let inside = Self.oracle(manifest, at: 3601)
        let intervalCount: Int = inside.averageInterval?.count ?? -1
        #expect(intervalCount == inside.inWindowCount,
                "W3 (bridging) undetected: \(intervalCount) intervals for \(inside.inWindowCount) records with a pre-window record present")

        // At the very start of an episode there is no pre-window record to bridge
        // from, so the floor case is still n-1 — pinned rather than dropped.
        let atStart = Self.oracle(manifest, at: 1800)
        let startIntervalCount: Int = atStart.averageInterval?.count ?? -1
        #expect(startIntervalCount == atStart.inWindowCount - 1,
                "episode-start floor changed: \(startIntervalCount) intervals for \(atStart.inWindowCount) records with nothing to bridge from")

        // The cliff itself, unchanged by 0023. Nothing is tapped after 1800, so every
        // difference between these two instants is a record ageing out of the window.
        let before = Self.pattern(manifest, at: 3900)
        let after = Self.pattern(manifest, at: 3901)
        #expect(before.episode.count == after.episode.count, "the record set must not change")
        #expect(before.guideline?.met == true, "W3 setup: the verdict should be met at 3900")
        #expect(after.guideline == nil, "W3 undetected: the verdict survived the window edge")
    }

    // MARK: - W4 · Lull-ripened sustainedMet — closed by 0026 (T1-02 / T3-Q2)

    /// `patternLength` is `now − episodeStart`, so a lull inside the episode used to
    /// ripen it regardless: thirty quick contractions, a forty-three-minute silence,
    /// one more tap, and the app reported a pattern sustained for well over the hour.
    /// The hour was real; the *pattern* had spent the last three quarters of it not
    /// happening.
    ///
    /// Decision 0026 makes `sustainedMet` require continuity: no in-window
    /// start-to-start gap may exceed triple the rule's interval threshold (900 s at
    /// 5-1-1). This scenario's 2590 s silence blows well past that, so `sustainedMet`
    /// — and with it `met` — now reads false even though `patternLength` alone still
    /// clears the hour. `sustainedEvidence`, the tick tape's own figure, is measured
    /// from the later of episode start and the newest such break, capped at the hour:
    /// at the instant the reconnecting tap lands, that break *is* now, so the tape
    /// reads zero rather than showing elapsed episode time.
    @Test func w4ALullRipensSustainment() {
        var stream = Self.evenStream(count: 30, from: 0, interval: 90, duration: 75)
        stream.append(TrueContraction(start: 5200, end: 5275))
        let manifest = Self.manifest("w4-lull", stream: stream, actions: Self.faithful(stream))

        let pattern = Self.pattern(manifest, at: 5200)
        #expect(pattern.guideline?.sustainedMet == false,
                "W4 undetected: the 43-minute silence did not break sustainedMet")
        #expect(pattern.guideline?.met == false,
                "W4 undetected: the verdict survived the lull")
        // Measured empirically: the reconnecting tap is itself the newest continuity
        // break, so sustainedEvidence has had zero time to reaccumulate at this probe.
        #expect(pattern.sustainedEvidence == .zero,
                "sustainedEvidence read \(HarnessBridge.seconds(pattern.sustainedEvidence))s, not zero, at the reconnecting tap")

        // The measurement that made this a weakness is still true of the episode —
        // patternLength alone still does not see the gap. It is sustainedMet and
        // sustainedEvidence, not patternLength, that now carry the continuity story.
        let starts = pattern.episode.map { Int64($0.startedAt.timeIntervalSince1970) - manifest.t0 }
        var largestGap: Int64 = 0
        for index in 1..<starts.count {
            largestGap = max(largestGap, starts[index] - starts[index - 1])
        }
        #expect(largestGap > 2400,
                "the gap this scenario relies on should still be present: \(largestGap)s")
    }

    // MARK: - W5 · The drive-gap cliff (T3 standing; T1 transition trace)

    /// Taps stop when the car does. The window drains, the verdict drops at
    /// `inWindow < 6`, the figures dash out, and at exactly two hours past the last
    /// start the whole readout goes empty — which reads as the app having lost her
    /// labor somewhere on the interstate.
    ///
    /// Flip to asserting a retained "last known" state if the design ever adds one.
    @Test func w5TheVerdictDrainsAndThenVanishes() {
        let stream = Self.evenStream(count: 30, from: 0, interval: 240, duration: 80)
        let manifest = Self.manifest("w5-drive-gap", stream: stream, actions: Self.faithful(stream))
        let lastStart = stream[stream.count - 1].start

        #expect(Self.pattern(manifest, at: lastStart).guideline?.met == true,
                "W5 setup: the verdict should be met when the taps stop")

        // Verdict withdrawn once the window drains below the evidence floor, while the
        // episode is still very much on screen.
        let drained = Self.pattern(manifest, at: lastStart + 3600)
        #expect(drained.guideline == nil, "W5 undetected: a verdict survived an empty window")
        #expect(!drained.episode.isEmpty)

        // T0-13, the cliff: live at exactly two hours, empty one second later.
        #expect(!Self.pattern(manifest, at: lastStart + 7200).episode.isEmpty)
        #expect(Self.pattern(manifest, at: lastStart + 7201).episode.isEmpty,
                "W5 undetected: a stale episode kept reporting")
    }

    // MARK: - W6 · One suspect no longer nulls the verdict — closed by 0023 §2 (T1-05)

    /// Six contractions in the window and exactly three usable durations: the floor,
    /// met precisely. One forgotten stop-tap used to turn a fourth into a suspect, the
    /// duration mean fell below its old floor of three, and the *whole verdict*
    /// disappeared — including the two dimensions that had nothing to do with
    /// duration. S4: the app went quiet on a body that had not changed.
    ///
    /// Decision 0023 §2 relieves the usable-duration floor to two whenever the window
    /// holds >=6 records and at least one is suspect: a forgotten stop-tap is itself
    /// evidence a contraction happened and ran long, and it must not be able to null
    /// the reading it belongs to. This scenario still has two usable durations after
    /// the suspect, which now clears the relieved floor, so the verdict survives.
    @Test func w6OneSuspectNoLongerSuppressesTheVerdict() {
        var stream = Self.evenStream(count: 6, from: 0, interval: 300, duration: 70)
        // Three genuinely long ones: already suspect, already excluded, in both runs.
        for index in 3..<6 {
            stream[index] = TrueContraction(start: stream[index].start, end: stream[index].start + 200)
        }
        let control = Self.manifest("w6-control", stream: stream, actions: Self.faithful(stream))
        #expect(Self.pattern(control, at: 3600).guideline?.met == true,
                "W6 setup: three usable durations is the floor, and the floor should pass")

        // One forgotten stop on a fourth contraction. Nothing about the body changed.
        var actions = Self.faithful(stream)
        actions = actions.map { action in
            if case let .tapEnd(at) = action, at == stream[2].end {
                return .tapEnd(at: stream[2].start + 200)
            }
            return action
        }
        let forgotten = Self.manifest("w6-one-suspect", stream: stream, actions: actions)
        let after = Self.pattern(forgotten, at: 3600)

        #expect(after.averageDuration != nil,
                "W6 undetected: two usable durations no longer cleared the relieved floor")
        #expect(after.guideline?.met == true,
                "W6 undetected: the verdict did not survive losing a duration to suspicion")
        #expect(after.episode.count == 6, "the records themselves must be untouched")
    }

    // MARK: - W7 · Missed contractions inflate the mean (T1-03/T1-05)

    /// Every third contraction goes untapped — an entirely ordinary rate for someone
    /// four hours in. The recorded gaps stretch from 240 s to an average of 360 s, the
    /// frequency test fails, and the app stays silent through hours of a pattern that
    /// genuinely met the rule. This is the suppression case, S4 and outranking
    /// everything.
    ///
    /// Flip to asserting a fired verdict if the engine ever models missed taps.
    @Test func w7MissedTapsSuppressARealVerdict() {
        let stream = Self.evenStream(count: 60, from: 0, interval: 240, duration: 80)
        var recorded: [TrueContraction] = []
        for (index, contraction) in stream.enumerated() where !index.isMultiple(of: 3) {
            recorded.append(contraction)
        }
        let manifest = Self.manifest("w7-missed", stream: stream, actions: Self.faithful(recorded))
        let (metrics, _) = Self.metrics(manifest)

        #expect(metrics.truthFirstMetAt != nil, "W7 setup: truth must actually fire")
        let appFirst = metrics.appFirstMetAt.map(String.init) ?? "never"
        let truthFirst = metrics.truthFirstMetAt.map(String.init) ?? "never"
        #expect(metrics.suppressed,
                "W7 undetected: app first met \(appFirst), truth first met \(truthFirst)")
        #expect(metrics.flags.contains("T1-03"))
    }

    // MARK: - W8 · Clock skew renders impossible figures (T0-02 / T3 DST)

    /// The store clamps `end >= start` and nothing clamps anything against the clock.
    /// A backward clock set between two contractions stores the later-tapped one
    /// *earlier*, so the timeline the screen renders is not the order the taps
    /// happened in — and the engine and the oracle agree about it exactly, which is
    /// the point: this is a design gap, not an arithmetic bug.
    ///
    /// Flip to asserting tap-order preservation if the schema ever records one.
    @Test func w8AClockSetReordersTheTimeline() {
        let stream = Self.evenStream(count: 6, from: 0, interval: 300, duration: 70)
        let actions: [ScenarioAction] = [
            .tapStart(at: 0), .tapEnd(at: 70),
            .tapStart(at: 300), .tapEnd(at: 370),
            .clockSet(at: 400, deltaSeconds: -1800),
            .tapStart(at: 2400), .tapEnd(at: 2470),   // effective 600/670
            .tapStart(at: 2000), .tapEnd(at: 2070),   // effective 200/270 — before its predecessor
        ]
        let manifest = Self.manifest("w8-clock-skew", stream: stream, actions: actions)

        let records = ReplayEngine.sorted(ReplayEngine.fold(manifest.actions))
        let tapOrder = records.map(\.createdBy)
        #expect(tapOrder != tapOrder.sorted(),
                "W8 undetected: the clock set did not reorder the stored timeline")

        // And the engine reports it as ordinary history: the pattern's own last
        // interval is measured between two records the user tapped in the other order.
        let pattern = Self.pattern(manifest, at: 3000)
        #expect(pattern.episode.count == 4)
        #expect(pattern.lastInterval != nil)
    }

    /// F-0037 / SP-207's detection evidence: the fast-from-onset shape actually
    /// *fires* fast-met — in the engine and the oracle both — and never reaches
    /// `met` inside its 44 minutes. The differential sweep gave the state agreement
    /// evidence everywhere and detection evidence nowhere; this is the nowhere,
    /// closed. Probed at 40 minutes: past 0040's twenty-minute floor with margin,
    /// inside the hour `sustainedMet` needs.
    @Test func fastFromOnsetFiresFastMetAndNeverMet() {
        let stream = (0..<23).map { TrueContraction(start: Int64($0) * 120, end: Int64($0) * 120 + 80) }
        let manifest = Self.manifest("fast-from-onset", stream: stream, actions: Self.faithful(stream))

        let probe: Int64 = 40 * 60
        let engine = Self.pattern(manifest, at: probe)
        #expect(engine.guideline?.fastMet == true, "engine fastMet should hold at 40 min")
        #expect(engine.guideline?.met != true, "met must not fire inside the hour")
        #expect(engine.presentedFastMet, "the latched form is what the banner keys on")

        let oracle = Self.oracle(manifest, at: probe)
        #expect(oracle.fastMet == true, "the referee reaches the same call independently")
        #expect(oracle.guidelineMet != true)
    }

    // MARK: - W10 · lastInterval contradicts the windowed story (T3-Q2)

    /// `lastInterval` is a whole-episode figure and `averageInterval` is a windowed
    /// one, so they can be read side by side and disagree completely: forty-five
    /// minutes since the last contraction, printed next to a five-minute average.
    ///
    /// Flip to asserting agreement once the two figures share a window.
    @Test func w10LastIntervalDisagreesWithTheAverageBesideIt() {
        var stream = Self.evenStream(count: 11, from: 0, interval: 60, duration: 50)
        stream.append(TrueContraction(start: 3300, end: 3350))
        let manifest = Self.manifest("w10-last-interval", stream: stream, actions: Self.faithful(stream))

        let pattern = Self.pattern(manifest, at: 3300)
        let last: Double = pattern.lastInterval.map(HarnessBridge.seconds) ?? -1
        let average: Double = pattern.averageInterval.map(HarnessBridge.seconds) ?? -1
        #expect(last >= 2700, "W10 setup: lastInterval was \(last)s, not the 45-minute gap")
        #expect(average <= 300 && average > 0,
                "W10 undetected: the windowed average was \(average)s")
    }
}
