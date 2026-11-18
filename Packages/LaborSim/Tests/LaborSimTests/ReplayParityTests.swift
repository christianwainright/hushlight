import Foundation
import Testing
@testable import LaborSim
import LaborOracle

/// Differential testing, leg one: two independently-written folds of the same tap
/// sequence must produce byte-identical records.
///
/// `ReplayEngine` and `OracleMath.fold` share no code and no types — they were
/// written from the same prose against the same store documentation, deliberately
/// twice. That duplication is the only reason an agreement between them means
/// anything: a shared helper would make both wrong in the same direction and
/// neither would notice. Any disagreement here is a bug in one of them, and which
/// one is a question for triage, not for the assertion.
@Suite("Replay parity")
struct ReplayParityTests {

    /// The bridge across the dependency wall. Deliberately total and boring — if it
    /// grew a rule of its own it would become a third implementation, and a bug in
    /// it would masquerade as agreement.
    private func asOracle(_ action: ScenarioAction) -> OracleAction {
        switch action {
        case let .tapStart(at): .tapStart(at: at)
        case let .tapEnd(at): .tapEnd(at: at)
        case let .deleteRecord(at, createdBy): .deleteRecord(at: at, createdBy: createdBy)
        case let .undoDelete(at, createdBy): .undoDelete(at: at, createdBy: createdBy)
        case let .killApp(at): .killApp(at: at)
        case let .launchApp(at): .launchApp(at: at)
        case let .clockSet(at, delta): .clockSet(at: at, deltaSeconds: delta)
        case let .timezoneChange(at, identifier): .timezoneChange(at: at, identifier: identifier)
        case let .setRule(at, rule): .setRule(at: at, rule: rule)
        case let .clearAll(at): .clearAll(at: at)
        }
    }

    private func compare(
        _ manifest: ScenarioManifest, at probe: Int64? = nil
    ) -> (sim: [(Int, Int64, Int64?)], oracle: [(Int, Int64, Int64?)]) {
        let oracleActions = manifest.actions.map(asOracle)
        let simRecords: [SimRecord]
        let oracleRecords: [OracleRecord]

        if let probe {
            simRecords = ReplayEngine.sorted(ReplayEngine.fold(manifest.actions, through: probe))
            // The oracle has no notion of a partial fold, so the prefix is taken on
            // the action list instead — the same definition, applied one level up.
            var offset: Int64 = 0
            var prefix: [OracleAction] = []
            for action in manifest.actions {
                if action.at + offset > probe { break }
                if case let .clockSet(_, delta) = action { offset += delta }
                prefix.append(asOracle(action))
            }
            oracleRecords = OracleMath.sorted(OracleMath.fold(prefix))
        } else {
            simRecords = ReplayEngine.sorted(ReplayEngine.fold(manifest.actions))
            oracleRecords = OracleMath.sorted(OracleMath.fold(oracleActions))
        }

        return (
            simRecords.map { ($0.createdBy, $0.start, $0.end) },
            oracleRecords.map { ($0.createdBy, $0.start, $0.end) }
        )
    }

    private func assertParity(_ manifest: ScenarioManifest, at probe: Int64? = nil) {
        let (sim, oracle) = compare(manifest, at: probe)
        #expect(sim.count == oracle.count, "record count differs for \(manifest.id)")
        for (index, pair) in zip(sim, oracle).enumerated() {
            #expect(pair.0.0 == pair.1.0, "createdBy differs at \(index) in \(manifest.id)")
            #expect(pair.0.1 == pair.1.1, "start differs at \(index) in \(manifest.id)")
            #expect(pair.0.2 == pair.1.2, "end differs at \(index) in \(manifest.id)")
        }
    }

    /// A spread across the corpus rather than the whole of it: this suite is the
    /// fast smoke test that the two folds agree at all. Phase 3's mass suite runs
    /// every scenario at every probe time.
    static let sample: [ScenarioSeedRef] = {
        let standard = ScenarioCorpus.standard
        guard standard.count > 20 else { return standard }
        let stride = standard.count / 20
        return (0..<20).map { standard[$0 * stride] }
    }()

    @Test(arguments: ReplayParityTests.sample)
    func foldsAgreeRecordForRecord(ref: ScenarioSeedRef) {
        assertParity(ScenarioCorpus.generate(ref))
    }

    /// Partial folds are where a clock jump can desynchronize the two — the sim
    /// stops on effective time inside its own walk, the oracle on a prefix computed
    /// outside it, and the two definitions must coincide.
    @Test(arguments: ReplayParityTests.sample.prefix(8))
    func foldsAgreeAtIntermediateProbes(ref: ScenarioSeedRef) {
        let manifest = ScenarioCorpus.generate(ref)
        let probes = ReplayEngine.probeTimes(for: manifest)
        guard !probes.isEmpty else { return }
        for fraction in [4, 3, 2] {
            assertParity(manifest, at: probes[probes.count / fraction])
        }
    }

    /// The hand-authored battery is where the exact boundaries live, so it gets
    /// every scenario rather than a sample.
    @Test func theBoundaryBatteryAgreesEverywhere() {
        for manifest in BoundaryBattery.all {
            assertParity(manifest)
        }
    }

    /// Store abuse is the fold's hard case: deletes, undos, clears and collisions
    /// are where two implementations most easily drift apart on bookkeeping.
    @Test func adversarialStoreScenariosAgree() {
        for manifest in BoundaryBattery.adversarial() {
            assertParity(manifest)
            let probes = ReplayEngine.probeTimes(for: manifest)
            for probe in probes.prefix(60) {
                assertParity(manifest, at: probe)
            }
        }
    }

    /// Parity is worthless if both folds produce nothing — a corpus of empty
    /// scenarios would agree perfectly and prove nothing at all.
    @Test func theSampleActuallyProducesRecords() {
        let total = Self.sample.reduce(0) { sum, ref in
            sum + ReplayEngine.fold(ScenarioCorpus.generate(ref).actions).count
        }
        #expect(total > 200, "sampled scenarios produced only \(total) records")
    }
}
