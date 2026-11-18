import Foundation
import LaborKit
import LaborOracle
import SwiftData
import Testing
@testable import LaborSim

/// **Layer E, leg two: the real store.**
///
/// The pure sweep proves the arithmetic. This proves the bookkeeping: a real
/// `ModelContainer`, real `ModelContext` operations, real saves, and a fresh context
/// wherever the scenario says the process died. `ReplayEngine.fold` is only a *model*
/// of these calls, and the interesting failures are exactly where the model and the
/// store disagree.
///
/// Sampled rather than exhaustive — a container-backed replay costs two orders of
/// magnitude more than the fold — but sampled with intent: every archetype, every
/// thumb, and every hand-authored store-abuse scenario in full.
@MainActor
@Suite("Store replay")
struct StoreReplayTests {

    /// Five instants spread across the scenario, used to check that the two legs
    /// agree on the *pattern* and not merely on the final record list — a leg can end
    /// up in the right place having passed through the wrong ones.
    static func spotProbes(_ manifest: ScenarioManifest) -> [Int64] {
        let probes = ReplayEngine.probeTimes(for: manifest, cadence: ReplayEngine.cadence(for: manifest))
        guard probes.count >= 5 else { return probes }
        return (1...5).map { probes[probes.count * $0 / 6] }
    }

    @Test(arguments: ReplaySubsample.refs)
    func theStoreEndsWhereTheFoldSaysItShould(ref: ScenarioSeedRef) throws {
        let manifest = ScenarioCorpus.generate(ref)
        let probes = Self.spotProbes(manifest)
        var outcome = try StoreReplay.run(manifest, spotProbes: probes)

        // Pattern parity at the spot probes. Same rule, same instant, same records:
        // any difference here is the store having taken a different route.
        let rule = HarnessBridge.rule(manifest.rule)
        for snapshot in outcome.snapshots {
            let foldRecords = ReplayEngine.sorted(ReplayEngine.fold(manifest.actions, through: snapshot.probe))
            let foldPattern = PatternAnalysis.pattern(
                for: HarnessBridge.contractions(foldRecords, t0: manifest.t0),
                rule: rule, now: HarnessBridge.date(manifest.t0, snapshot.probe)
            )
            let storePattern = PatternAnalysis.pattern(
                for: snapshot.contractions, rule: rule,
                now: HarnessBridge.date(manifest.t0, snapshot.probe)
            )
            if HarnessBridge.verdictState(foldPattern) != HarnessBridge.verdictState(storePattern)
                || foldPattern.episode.count != storePattern.episode.count {
                outcome.collector.record("T0-02", at: snapshot.probe,
                                         "store and fold patterns differ mid-scenario")
            }
        }

        ResultsWriter.write(
            ScenarioResult(
                scenarioId: manifest.id,
                leg: "store",
                archetype: manifest.archetype,
                paramVariant: manifest.paramVariant,
                noiseProfile: manifest.noiseProfile,
                rule: manifest.rule,
                seed: ScenarioSeedRef.hex(manifest.seed),
                probeCount: outcome.snapshots.count,
                cadenceSeconds: Int(ReplayEngine.cadence(for: manifest)),
                truth: TruthSummary(manifest),
                t0: T0Result(pass: outcome.collector.passed, violations: outcome.collector.violations),
                legAgreement: outcome.agreement
            ),
            scenario: manifest.id,
            leg: "store"
        )

        #expect(outcome.collector.passed, "\(outcome.collector.failureSummary)")
    }

    /// T0-09's other half. The per-kill identity check inside the driver proves the
    /// running record survived; this proves the *whole pattern* did, by replaying the
    /// same scenario with the process never dying and demanding an identical timeline.
    @Test(arguments: ReplaySubsample.refs.filter { ref in
        ScenarioCorpus.generate(ref).actions.contains { if case .killApp = $0 { true } else { false } }
    })
    func killingTheAppChangesNothing(ref: ScenarioSeedRef) throws {
        var manifest = ScenarioCorpus.generate(ref)
        let withKills = try StoreReplay.run(manifest)

        // Neutralised, not removed. `deleteRecord`/`undoDelete` address records by the
        // *index* of the action that created them, so dropping two actions renumbers
        // every later one and the control would delete different records than the
        // scenario did — a difference the comparison would then blame on the kill.
        // `launchApp` is a no-op in both the fold and the store, so swapping each kill
        // for one leaves the indices and everything else untouched.
        manifest.actions = manifest.actions.map {
            if case let .killApp(at) = $0 { return ScenarioAction.launchApp(at: at) }
            return $0
        }
        let control = try StoreReplay.run(manifest)

        let difference = TimelineCompare.firstDifference(
            TimelineCompare.rows(withKills.final, t0: manifest.t0),
            TimelineCompare.rows(control.final, t0: manifest.t0)
        )
        #expect(difference == nil, "T0-09 \(ref.label): kill/relaunch changed the record — \(difference ?? "")")
    }

    /// T0-10 stated directly, on hand-built sequences rather than sampled ones. The
    /// sweep above catches these where a scenario happens to produce them; this
    /// catches them because they are the rule.
    @Test func correctionsRoundTrip() throws {
        let context = ModelContext(try LaborStore.container(inMemory: true))
        let t0 = Date(timeIntervalSince1970: TimeInterval(laborSimEpoch))

        // begin-while-running is a no-op returning the running record.
        let first = try context.beginContraction(at: t0)
        let second = try context.beginContraction(at: t0.addingTimeInterval(30))
        #expect(first.id == second.id)
        #expect(try context.allContractions().count == 1)

        // end-while-none records nothing.
        try context.endContraction(at: t0.addingTimeInterval(60))
        #expect(try context.endContraction(at: t0.addingTimeInterval(90)) == nil)
        #expect(try context.allContractions().count == 1)

        // delete -> restore is id-identical and pattern-identical.
        let before = try context.allContractions()
        let beforePattern = PatternAnalysis.pattern(for: before, rule: .fiveOneOne, now: t0.addingTimeInterval(120))
        try context.deleteContraction(id: first.id)
        #expect(try context.allContractions().isEmpty)
        try context.restoreContraction(before[0])
        let after = try context.allContractions()
        #expect(after == before)
        #expect(PatternAnalysis.pattern(for: after, rule: .fiveOneOne, now: t0.addingTimeInterval(120))
            == beforePattern)

        // An end stamped before its own start clamps rather than storing a negative
        // duration — T0-08, reachable only through a clock moving backwards.
        try context.beginContraction(at: t0.addingTimeInterval(600))
        let clamped = try context.endContraction(at: t0.addingTimeInterval(300))
        #expect(clamped?.endedAt == clamped?.startedAt)
    }

    /// A subsample that quietly stopped covering something would still pass every
    /// assertion above. This is what stops it drifting.
    @Test func theSubsampleCoversWhatItClaimsTo() {
        let refs = ReplaySubsample.refs
        #expect(refs.count >= 50 && refs.count <= 80, "subsample is \(refs.count) scenarios")
        for archetype in ArchetypeID.sampled {
            #expect(refs.contains { $0.archetype == archetype }, "\(archetype.rawValue) missing")
        }
        for profile in NoiseProfileID.allCases {
            #expect(refs.contains { $0.noiseProfile == profile }, "\(profile.rawValue) missing")
        }
        let adversarial = refs.filter { $0.archetype == .boundaryBattery }
        #expect(adversarial.count == BoundaryBattery.adversarial().count)
    }
}
