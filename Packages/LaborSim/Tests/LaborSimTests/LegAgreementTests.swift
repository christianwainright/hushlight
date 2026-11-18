import Foundation
import LaborKit
import Testing
@testable import LaborSim

/// Every adversarial store scenario plus one row per archetype. The adversarial half
/// is where the three implementations of undo/clear/kill bookkeeping have any room to
/// differ at all; the archetype half is there so the sample is not made entirely of
/// edge cases.
///
/// Outside the suite because `@Test(arguments:)` evaluates its argument list before
/// any actor hop, and the suite below is `@MainActor`.
enum LegAgreementSample {
    static let refs: [ScenarioSeedRef] = {
        var picked = ScenarioCorpus.battery.filter { ref in
            BoundaryBattery.all[ref.paramVariant].id.hasPrefix("boundaryBattery-adv")
        }
        var seen: Set<ArchetypeID> = []
        for ref in ScenarioCorpus.base where ref.noiseProfile == .exhaustedSolo {
            guard seen.insert(ref.archetype).inserted else { continue }
            picked.append(ref)
        }
        return picked
    }()
}

/// The cross-check: one scenario, three implementations of "what did the store end up
/// holding", and no opinion about which is right.
///
/// Each leg already agrees with the pure fold inside its own suite, so three-way
/// identity follows by transitivity for the whole subsample. This suite asserts it
/// directly on a smaller sample anyway, because transitivity is only as good as the
/// two comparisons it rests on — and if either of those ever loosened (a tolerance, a
/// skipped case), the gap would open silently between store and model, which is
/// exactly the pair no other test looks at head-on.
@MainActor
@Suite("Leg agreement")
struct LegAgreementTests {

    @Test(arguments: LegAgreementSample.refs)
    func allThreeLegsEndOnTheSameTimeline(ref: ScenarioSeedRef) throws {
        let manifest = ScenarioCorpus.generate(ref)

        let pure = TimelineCompare.rows(ReplayEngine.fold(manifest.actions))
        let store = TimelineCompare.rows(
            try StoreReplay.run(manifest, leg: .agreement).final, t0: manifest.t0
        )
        let model = TimelineCompare.rows(
            try ModelReplay.run(manifest, leg: .agreement).final, t0: manifest.t0
        )

        let storeVsPure = TimelineCompare.firstDifference(store, pure)
        let modelVsPure = TimelineCompare.firstDifference(model, pure)
        let storeVsModel = TimelineCompare.firstDifference(store, model)

        // A divergence is a finding, not an accident, so it is registry-gated the same
        // way a T0 violation is: known ones are recorded and reported, new ones are red.
        var collector = ViolationCollector(scenarioId: manifest.id, leg: .agreement)
        let probe = manifest.actions.last?.at ?? 0
        if let storeVsPure { collector.record("T0-02", at: probe, "store vs pure: \(storeVsPure)") }
        if let modelVsPure { collector.record("T0-02", at: probe, "model vs pure: \(modelVsPure)") }
        if let storeVsModel { collector.record("T0-02", at: probe, "store vs model: \(storeVsModel)") }

        ResultsWriter.write(
            ScenarioResult(
                scenarioId: manifest.id,
                leg: "agreement",
                archetype: manifest.archetype,
                paramVariant: manifest.paramVariant,
                noiseProfile: manifest.noiseProfile,
                rule: manifest.rule,
                seed: ScenarioSeedRef.hex(manifest.seed),
                probeCount: 1,
                cadenceSeconds: Int(ReplayEngine.cadence(for: manifest)),
                truth: TruthSummary(manifest),
                t0: T0Result(pass: collector.passed, violations: collector.violations),
                legAgreement: LegAgreement(
                    comparedWith: "pure+store+model",
                    agrees: storeVsPure == nil && modelVsPure == nil && storeVsModel == nil,
                    detail: storeVsPure ?? modelVsPure ?? storeVsModel
                )
            ),
            scenario: manifest.id,
            leg: "agreement"
        )

        #expect(collector.passed, "\(collector.failureSummary)")
    }

    /// Three legs that all produced nothing would agree perfectly and prove nothing.
    @Test func theSampleActuallyExercisesTheStore() {
        let total = LegAgreementSample.refs.reduce(0) { sum, ref in
            sum + ReplayEngine.fold(ScenarioCorpus.generate(ref).actions).count
        }
        #expect(total > 100, "leg-agreement sample produced only \(total) records")
    }
}
