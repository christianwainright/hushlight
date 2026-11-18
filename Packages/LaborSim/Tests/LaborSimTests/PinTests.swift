import Foundation
import LaborKit
import LaborOracle
import Testing
@testable import LaborSim

/// Every pin, by finding. Adding a fixture without adding it here would freeze a
/// scenario nothing replays. File-scope rather than a static on the suite: `@Test`'s
/// argument lists are evaluated outside the suite's actor.
private let pinnedFindings = [
    "F-0001", "F-0002", "F-0003", "F-0004",
    "F-0007", "F-0008", "F-0009", "F-0010",
    "F-0035",
]

/// **The regression pins** (decision 0021 §5: "every fixed finding pins its catching
/// scenario").
///
/// `KnownFindings` is the register of what is still wrong; this is the register of
/// what stopped being wrong, and it is the more important of the two. A fix removes
/// its registry entry — which is the only thing that was keeping the harness pointed
/// at that defect — so without a pin the very next refactor could reintroduce it and
/// the suite would applaud.
///
/// Each fixture is the manifest that caught the finding, **frozen**: decoded from
/// JSON, never regenerated from its seed. That is the whole point. A pin re-derived
/// from `ScenarioCorpus` would move with the corpus, and a regression test that moves
/// with the thing it is testing is a regression test that eventually agrees with the
/// bug. `docs/qa/corpus/pins/README.md` is the human index over these files.
@MainActor
@Suite("Regression pins")
struct PinTests {

    static func manifest(_ finding: String) throws -> ScenarioManifest {
        let url = try #require(
            Bundle.module.url(
                forResource: finding, withExtension: "json", subdirectory: "Fixtures/Pins"
            ),
            "pin fixture \(finding).json is missing from the test bundle"
        )
        return try CanonicalJSON.decode(ScenarioManifest.self, from: Data(contentsOf: url))
    }

    /// The fixtures have to stay fixtures. A pin that had quietly become a pointer
    /// back into the generator would drift with it and prove nothing.
    @Test(arguments: pinnedFindings)
    func everyPinIsAFrozenScenarioWithRealContent(finding: String) throws {
        let manifest = try Self.manifest(finding)
        #expect(!manifest.actions.isEmpty)
        #expect(manifest.schemaVersion == LaborSimVersion.schema)
        #expect(!manifest.id.isEmpty)
        #expect(manifest.t0 == laborSimEpoch)
    }

    // MARK: The invariants the fixes established

    /// **F-0001, everywhere.** At most one record is ever open — asserted over the
    /// whole probe grid rather than at the end, because the collision the finding
    /// describes lasts exactly as long as it takes the next stop tap to miss it.
    @Test(arguments: pinnedFindings)
    func theFoldNeverHoldsTwoRunningRecords(finding: String) throws {
        let manifest = try Self.manifest(finding)
        var cursor = ReplayEngine.Cursor(manifest.actions)
        for probe in ReplayEngine.probeTimes(for: manifest, cadence: ReplayEngine.cadence(for: manifest)) {
            let open = cursor.advance(to: probe).count { $0.end == nil }
            #expect(open <= 1, "\(finding): \(open) records open at probe \(probe)")
        }
    }

    /// The same claim asked of the real container, and of the snapshot the screens
    /// read. `StoreReplay`/`ModelReplay` record T0-10 for a second runner, T0-10a for
    /// an `isRunning`/`runningSince` split (**F-0002**), and T0-02 for a timeline that
    /// stops tracking the fold — which is how **F-0003** cost up to half a labor.
    ///
    /// With the registry empty, `passed` means no violation of any kind fired.
    @Test(arguments: pinnedFindings)
    func bothContainerLegsReplayClean(finding: String) throws {
        let manifest = try Self.manifest(finding)

        let store = try StoreReplay.run(manifest)
        #expect(store.collector.passed, "\(finding) [store] \(store.collector.failureSummary)")
        #expect(store.agreement.agrees, "\(finding) [store] diverged from the fold")

        let model = try ModelReplay.run(manifest)
        #expect(model.collector.passed, "\(finding) [model] \(model.collector.failureSummary)")
        #expect(model.agreement.agrees, "\(finding) [model] diverged from the fold")
        #expect(model.collector.totals["T0-10a", default: 0] == 0,
                "\(finding): isRunning and runningSince disagreed")
    }

    /// The differential test over the pinned scenarios. The engine and the referee
    /// changed together for the staleness guard, the `patternLength` floor and the
    /// restore rule; if only one side moved, this is where it shows.
    @Test(arguments: pinnedFindings)
    func theEngineAndTheOracleStillAgree(finding: String) throws {
        let manifest = try Self.manifest(finding)
        let outcome = PureSweep.run(manifest)
        #expect(outcome.collector.passed, "\(finding) [pure] \(outcome.collector.failureSummary)")
    }

    /// Nothing the engine renders may be negative (**F-0011**). `patternLength` is the
    /// one figure measured against `now` rather than between two stored stamps, so it
    /// is the one a backward clock set can invert.
    @Test(arguments: pinnedFindings)
    func noProbeEverProducesANegativeFigure(finding: String) throws {
        let manifest = try Self.manifest(finding)
        let rule = HarnessBridge.rule(manifest.rule)
        var cursor = ReplayEngine.Cursor(manifest.actions)

        for probe in ReplayEngine.probeTimes(for: manifest, cadence: ReplayEngine.cadence(for: manifest)) {
            let contractions = HarnessBridge.contractions(
                ReplayEngine.sorted(cursor.advance(to: probe)), t0: manifest.t0
            )
            let pattern = PatternAnalysis.pattern(
                for: contractions, rule: rule, now: HarnessBridge.date(manifest.t0, probe)
            )
            if let length = pattern.patternLength {
                #expect(length >= .zero, "\(finding): patternLength \(length) at probe \(probe)")
            }
            if let last = pattern.lastInterval {
                #expect(last >= .zero, "\(finding): lastInterval \(last) at probe \(probe)")
            }
        }
    }

    // MARK: The findings, one at a time

    /// **F-0001.** The exact sequence: start A, delete A mid-run, start B, undo the
    /// delete. A comes back — mis-taps are expected and "undo restores it" has to stay
    /// true — but closed at its own start, so B is still the record the next stop tap
    /// finds.
    @Test func f0001_restoreWhileRunningLeavesTheLiveContractionClosable() throws {
        let manifest = try Self.manifest("F-0001")
        let final = ReplayEngine.sorted(ReplayEngine.fold(manifest.actions))

        #expect(final.count == 2, "both records survive the correction")
        let restored = try #require(final.first { $0.createdBy == 0 })
        #expect(restored.end == restored.start, "the restored record is closed at its own start")

        let live = try #require(final.first { $0.createdBy != 0 })
        #expect(live.end != nil, "the stop tap closed the contraction that was actually running")
        #expect(live.end! >= live.start)

        // And the referee reached the same record set from its own arithmetic.
        let oracle = OracleMath.sorted(OracleMath.fold(manifest.actions.map(HarnessBridge.asOracle)))
        #expect(oracle.map(\.start) == final.map(\.start))
        #expect(oracle.map(\.end) == final.map(\.end))
    }

    /// **F-0002 / F-0003.** One definition of running, asked of `LaborModel` itself at
    /// every action of the scenario that carried the backward clock set. The button
    /// follows `isRunning`; when that disagreed with `runningSince` the stop tap
    /// became a start tap, the live contraction became unclosable, and every later tap
    /// no-opped against it.
    @Test(arguments: ["F-0002", "F-0003"])
    func theModelKeepsOneAnswerAboutWhatIsRunning(finding: String) throws {
        let manifest = try Self.manifest(finding)
        let outcome = try ModelReplay.run(manifest)

        #expect(outcome.collector.totals["T0-10a", default: 0] == 0)
        #expect(outcome.collector.totals["T0-10", default: 0] == 0)

        // The timeline is the cost F-0003 charged: with a record stuck open the model
        // stopped growing and drifted from the fold for the rest of the labor.
        let expected = TimelineCompare.rows(ReplayEngine.fold(manifest.actions))
        let actual = TimelineCompare.rows(outcome.final, t0: manifest.t0)
        #expect(TimelineCompare.firstDifference(actual, expected) == nil)
        #expect(actual.count == expected.count)
        #expect(actual.count { $0.end == nil } <= 1)
    }

    /// **F-0004.** Two hours and a minute past the newest start — the instant that
    /// emptied the readout under a live 121-minute count and offered first-launch
    /// onboarding copy over it.
    ///
    /// Both halves of decision 0022 are pinned here, and which one applies is decided
    /// by the fixture rather than asserted by hope: with a record open the episode is
    /// live however old it is; with everything closed it is genuinely stale, and the
    /// screen must then have a *last ended* time to date its returning copy from —
    /// never the introduction it shows a first-time reader.
    @Test func f0004_theStaleBoundaryRespectsARunningContraction() throws {
        let manifest = try Self.manifest("F-0004")
        let rule = HarnessBridge.rule(manifest.rule)

        let latestStart = try #require(ReplayEngine.fold(manifest.actions).map(\.start).max())
        let staleInstant = latestStart + 7200 + 60

        let records = ReplayEngine.sorted(ReplayEngine.fold(manifest.actions, through: staleInstant))
        let contractions = HarnessBridge.contractions(records, t0: manifest.t0)
        let pattern = PatternAnalysis.pattern(
            for: contractions, rule: rule, now: HarnessBridge.date(manifest.t0, staleInstant)
        )

        if records.contains(where: { $0.end == nil }) {
            #expect(pattern != .empty, "an open record cannot have gone stale")
            #expect(pattern.running != nil)
            #expect(pattern.patternLength ?? .zero > .seconds(7200))
        } else {
            #expect(pattern == .empty, "a finished episode past the boundary is history")
            #expect(contractions.compactMap(\.endedAt).max() != nil,
                    "the returning empty state needs a last-ended time to date itself from")
        }

        // The referee agrees about which of the two it is.
        let oracle = OracleMath.pattern(
            records: HarnessBridge.oracleRecords(records),
            rule: HarnessBridge.oracleRule(manifest.rule),
            now: staleInstant
        )
        #expect(oracle.hasPattern == (pattern != .empty))
    }

    // MARK: Fix wave C — the verdict mathematics

    /// The pattern at one instant of a pin, both engines.
    static func both(_ manifest: ScenarioManifest, at probe: Int64) throws -> (LaborPattern, OraclePattern) {
        let records = ReplayEngine.sorted(ReplayEngine.fold(manifest.actions, through: probe))
        return (
            PatternAnalysis.pattern(
                for: HarnessBridge.contractions(records, t0: manifest.t0),
                rule: HarnessBridge.rule(manifest.rule),
                now: HarnessBridge.date(manifest.t0, probe)
            ),
            OracleMath.pattern(
                records: HarnessBridge.oracleRecords(records),
                rule: HarnessBridge.oracleRule(manifest.rule),
                now: probe
            )
        )
    }

    static func lastStart(_ manifest: ScenarioManifest) throws -> Int64 {
        try #require(ReplayEngine.fold(manifest.actions).map(\.start).max())
    }

    /// **F-0007 (decision 0023 §2).** Six in the window, three usable durations —
    /// the floor met exactly — and then one forgotten stop-tap turns a fourth
    /// suspect. The verdict used to vanish whole, including the two dimensions that
    /// had nothing to do with duration, on a body that had not changed. The relieved
    /// floor keeps the reading its own record belongs to.
    @Test func f0007_oneForgottenStopDoesNotNullTheVerdict() throws {
        let manifest = try Self.manifest("F-0007")
        let (pattern, oracle) = try Self.both(manifest, at: 3600)

        // Hoisted rather than inlined: `#expect` decomposes a `contains(where:)` call
        // into its receiver and predicate, and the rethrows analysis of that
        // decomposition does not survive a key-path argument.
        let hasSuspect = pattern.episode.contains(where: \.isSuspect)
        #expect(pattern.inWindowCount == 6)
        #expect(hasSuspect, "the forgotten stop must still be a suspect")
        #expect(pattern.averageDuration != nil, "two usable durations clear the relieved floor")
        #expect(pattern.guideline?.met == true)
        #expect(oracle.guidelineMet == true, "and the referee reaches it independently")
    }

    /// **F-0035 (decision 0032).** The mirror image of F-0007, and the reason the
    /// two pins sit next to each other: a forgotten stop-tap must not null a verdict,
    /// and neither must a double tap.
    ///
    /// Twelve believable 52-second contractions in the window, five minutes apart,
    /// an hour and eleven minutes in — every dimension of 5-1-1 met — plus one
    /// eleven-second slip dropped in the dead time between two of them. Averaged in,
    /// it takes the recorded duration mean to 48.8 s, under the 50 s evidence
    /// threshold decision 0023 calibrated, and the whole verdict goes with it. The
    /// body had not changed; the app would have gone quiet because a thumb bounced.
    @Test func f0035_aSlipDoesNotNullTheVerdict() throws {
        let manifest = try Self.manifest("F-0035")
        let (pattern, oracle) = try Self.both(manifest, at: 4260)

        let slips = pattern.episode.filter { $0.suspicion == .tooShort }
        #expect(slips.count == 1, "the fixture's one double tap must read as a slip")
        #expect(pattern.inWindowCount == 13, "twelve contractions and the slip, all inside the hour")

        // The figure the guideline reads, with the slip out of it. Averaged in it
        // would be 635 / 13 = 48 s (integer division), and `durationMet` would fail.
        #expect(pattern.averageDuration == .seconds(52))
        #expect(pattern.guideline?.durationMet == true)
        #expect(pattern.guideline?.met == true)
        #expect(oracle.guidelineMet == true, "and the referee reaches it independently")

        // The slip's start is still a tap at a real time: it splits one five-minute
        // gap into two shorter ones, and both are still inside the rule.
        #expect(pattern.averageInterval != nil)
        #expect(pattern.guideline?.frequencyMet == true)
    }

    /// **F-0008 (decision 0024).** Coupled back labor recorded faithfully: gaps
    /// alternate two and eight minutes, and the windowed *mean* still sits at or under
    /// the rule's threshold — which is exactly how a bimodal pattern used to pass a
    /// five-minute check on a spacing that is never five minutes. The share sees it.
    ///
    /// The assertion is on the engine rather than on a T1 false-met count on purpose:
    /// `TruthCompiler` judges the true stream with the same mean (F-0014), so truth
    /// cannot condemn this scenario until that changes. A pin does not need truth's
    /// permission to say what the engine must answer.
    @Test func f0008_aCoupledMeanAtThresholdNoLongerMeetsFrequency() throws {
        let manifest = try Self.manifest("F-0008")
        let probe = try Self.lastStart(manifest)
        let (pattern, oracle) = try Self.both(manifest, at: probe)

        let mean = try #require(pattern.averageInterval)
        #expect(mean <= HarnessBridge.rule(manifest.rule).intervalThreshold,
                "setup: the mean is what would have passed")
        #expect(oracle.averageInterval?.isAtMost(300) == true)
        #expect(pattern.guideline?.frequencyMet == false)
        #expect(oracle.frequencyMet == false)

        // And the spread the readout now prints is the thing the mean was hiding.
        let range = try #require(pattern.intervalRange)
        #expect(range.lowerBound == .seconds(120))
        #expect(range.upperBound == .seconds(480))
    }

    /// **F-0009 (decisions 0024 and 0025).** Alternating 270/330 spacing: the mean
    /// drifted across the 300 s line as old intervals aged out, and the verdict —
    /// and with it the whole screen's running order — followed it. The presented
    /// verdict never retracts across this pin's entire probe grid.
    @Test func f0009_thePresentedVerdictNeverRetracts() throws {
        let manifest = try Self.manifest("F-0009")
        let outcome = PureSweep.run(manifest)

        var flips: [Int64] = []
        for index in 1..<max(1, outcome.ticks.count)
        where outcome.ticks[index - 1].state == .met && outcome.ticks[index].state != .met {
            flips.append(outcome.ticks[index].at)
        }
        #expect(flips.isEmpty, "presented verdict retracted at \(flips)")
    }

    /// **F-0010 (decision 0026).** Thirty contractions ninety seconds apart, a
    /// forty-three-minute silence, one more tap — and "sustained for an hour" used to
    /// be true, with the tick tape rendering a full bar as its proof. The hour was
    /// real; the pattern spent three quarters of it not happening.
    @Test func f0010_aLullBreaksSustainmentAndEmptiesTheTape() throws {
        let manifest = try Self.manifest("F-0010")
        let probe = try Self.lastStart(manifest)
        let (pattern, oracle) = try Self.both(manifest, at: probe)

        #expect(pattern.patternLength ?? .zero >= HarnessBridge.rule(manifest.rule).sustainedWindow,
                "setup: elapsed time alone still clears the hour")
        #expect(pattern.guideline?.sustainedMet == false)
        #expect(oracle.sustainedMet == false)
        #expect(pattern.sustainedEvidence == .zero,
                "the reconnecting tap is itself the newest break; the tape starts over")
        #expect(oracle.sustainedEvidenceSeconds == 0)
    }
}
