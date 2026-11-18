import Foundation
import LaborKit
import SwiftData
import Testing
@testable import LaborSim

/// **Layer E, leg three: the view model.**
///
/// Same scenarios, same container, one layer higher — `LaborModel` is what the screens
/// actually talk to, and it adds three things the store does not have: a cached
/// snapshot, a one-step undo, and a persisted rule. Each of those is a place the app
/// can be right about the store and wrong about itself.
@MainActor
@Suite("Model replay")
struct ModelReplayTests {

    @Test(arguments: ReplaySubsample.refs)
    func theModelSnapshotTracksTheFold(ref: ScenarioSeedRef) throws {
        let manifest = ScenarioCorpus.generate(ref)
        let probes = StoreReplayTests.spotProbes(manifest)
        var outcome = try ModelReplay.run(manifest, spotProbes: probes)

        // Mid-scenario parity. `LaborModel.contractions` is a cache that every
        // mutation is supposed to refresh; a snapshot that only agreed at the end
        // would be a cache that happens to converge, which is not the same promise.
        for snapshot in outcome.snapshots {
            let foldRows = TimelineCompare.rows(
                ReplayEngine.fold(manifest.actions, through: snapshot.probe)
            )
            let modelRows = TimelineCompare.rows(snapshot.contractions, t0: manifest.t0)
            if let difference = TimelineCompare.firstDifference(modelRows, foldRows) {
                outcome.collector.record("T0-02", at: snapshot.probe,
                                         "model snapshot stale mid-scenario: \(difference)")
            }
        }

        ResultsWriter.write(
            ScenarioResult(
                scenarioId: manifest.id,
                leg: "model",
                archetype: manifest.archetype,
                paramVariant: manifest.paramVariant,
                noiseProfile: manifest.noiseProfile,
                rule: manifest.rule,
                seed: ScenarioSeedRef.hex(manifest.seed),
                probeCount: outcome.snapshots.count,
                cadenceSeconds: Int(ReplayEngine.cadence(for: manifest)),
                truth: TruthSummary(manifest),
                t0: T0Result(pass: outcome.collector.passed, violations: outcome.collector.violations),
                legAgreement: outcome.agreement,
                undoOutOfReach: outcome.undoOutOfReach
            ),
            scenario: manifest.id,
            leg: "model"
        )

        #expect(outcome.collector.passed, "\(outcome.collector.failureSummary)")
    }

    /// The three undo cases, stated rather than sampled. Mis-taps are the expected
    /// mid-labor event (decision 0018), so "one tap takes the last action back" has to
    /// hold for all three shapes of last action, not just the common one.
    @Test func undoTakesBackEachKindOfLastAction() throws {
        let suite = "net.wainright.laborsim.undo-cases"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }

        let context = ModelContext(try LaborStore.container(inMemory: true))
        let model = LaborModel(context: context, defaults: defaults)
        let t0 = Date(timeIntervalSince1970: TimeInterval(laborSimEpoch))

        // 1. Undo a start: the contraction never happened.
        model.tap(at: t0)
        guard case .started = model.undoAction else {
            Issue.record("a start tap did not produce .started")
            return
        }
        model.undo()
        #expect(model.contractions.isEmpty)
        #expect(model.undoAction == nil)

        // 2. Undo an end: the end tap was the mistake, the contraction was not.
        model.tap(at: t0)
        model.tap(at: t0.addingTimeInterval(60))
        guard case .ended = model.undoAction else {
            Issue.record("an end tap did not produce .ended")
            return
        }
        model.undo()
        #expect(model.contractions.count == 1)
        #expect(model.runningSince == t0)
        #expect(model.isRunning)

        // 3. Undo a delete: restored verbatim, same identity.
        model.tap(at: t0.addingTimeInterval(60))
        let target = try #require(model.contractions.first)
        model.delete(target)
        #expect(model.contractions.isEmpty)
        guard case .deleted = model.undoAction else {
            Issue.record("a delete did not produce .deleted")
            return
        }
        model.undo()
        #expect(model.contractions == [target])
    }

    /// The rule is persisted per device, so a suite that wrote it into `.standard`
    /// would leave the real app's preference behind on whichever machine ran the
    /// tests. This pins the injection point that stops that.
    @Test func theRulePersistsIntoTheInjectedDomainOnly() throws {
        let suite = "net.wainright.laborsim.rule-domain"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }

        let container = try LaborStore.container(inMemory: true)
        let model = LaborModel(context: ModelContext(container), defaults: defaults)
        #expect(model.rule == .fiveOneOne)
        model.rule = .threeOneOne

        let reopened = LaborModel(context: ModelContext(container), defaults: defaults)
        #expect(reopened.rule == .threeOneOne)
        #expect(UserDefaults.standard.string(forKey: "guidelineRule") == nil)
    }
}
