import CryptoKit
import Foundation
import LaborKit
import LaborOracle
import Testing
@testable import LaborSim

/// **Layer E, leg one: the whole corpus against the referee.**
///
/// Every scenario, every probe instant on the rubric's grid, `PatternAnalysis` on one
/// side and `LaborOracle` on the other. The two share no code and were written from
/// the same prose twice, which is the only reason their agreement means anything.
///
/// What fails a run is narrow on purpose: an **unregistered** T0 violation. A
/// violation already triaged into `KnownFindings` is recorded into the results file
/// with its finding reference and does not go red — see that file for why a harness
/// that failed the build on every known trade-off would be a harness nobody left
/// switched on. T1 never fails anything at all; it is measured, flagged, and reported.
@Suite("Pure sweep")
struct PureSweepTests {

    @Test(arguments: ScenarioCorpus.standard)
    func everyScenarioAgreesWithTheOracleAtEveryProbe(ref: ScenarioSeedRef) {
        let manifest = ScenarioCorpus.generate(ref)
        let outcome = PureSweep.run(manifest)
        let metrics = PureSweep.metrics(manifest, outcome: outcome)

        ResultsWriter.write(
            ScenarioResult(
                scenarioId: manifest.id,
                leg: "pure",
                archetype: manifest.archetype,
                paramVariant: manifest.paramVariant,
                noiseProfile: manifest.noiseProfile,
                rule: manifest.rule,
                seed: ScenarioSeedRef.hex(manifest.seed),
                probeCount: outcome.probeCount,
                cadenceSeconds: Int(outcome.cadence),
                truth: TruthSummary(manifest),
                t0: T0Result(pass: outcome.collector.passed,
                             violations: outcome.collector.violations),
                t1: metrics
            ),
            scenario: manifest.id,
            leg: "pure"
        )

        #expect(outcome.collector.passed, "\(outcome.collector.failureSummary)")
    }

    /// The grid has to actually be a grid. A probe list that silently collapsed to
    /// the action times would agree with the oracle perfectly and prove nothing about
    /// the minutes in between.
    @Test func theProbeGridCoversTheCorpusDensely() {
        var total = 0
        for ref in ScenarioCorpus.standard {
            let manifest = ScenarioCorpus.generate(ref)
            let cadence = ReplayEngine.cadence(for: manifest)
            let probes = ReplayEngine.probeTimes(for: manifest, cadence: cadence)
            total += probes.count
            #expect(probes == probes.sorted(), "\(ref.label) probe grid is unsorted")
        }
        #expect(total > 200_000, "corpus probe grid collapsed to \(total) points")
    }

    /// Coarsening is allowed only where the rubric's minute grid would be asking the
    /// same question of a three-day store four thousand times. Every action probe,
    /// zone boundary and knife-edge survives it — this pins that.
    @Test func coarseningKeepsEveryTargetedProbe() {
        let ref = ScenarioCorpus.standard.first {
            $0.archetype == .multiDayLatent
        }
        guard let ref else { return }
        let manifest = ScenarioCorpus.generate(ref)
        let fine = Set(ReplayEngine.probeTimes(for: manifest, cadence: 60))
        let coarse = Set(ReplayEngine.probeTimes(for: manifest, cadence: 300))

        // `probeTimes` drops negative instants, so an action at second zero has no
        // left neighbour to keep — the only reason this is not a blanket assertion.
        for action in manifest.actions {
            #expect(coarse.contains(action.at))
            #expect(action.at <= 0 || coarse.contains(action.at - 1))
            #expect(coarse.contains(action.at + 1))
        }
        for zone in manifest.truth.zones {
            #expect(coarse.contains(zone.from))
            #expect(coarse.contains(zone.to))
        }
        #expect(coarse.count < fine.count)
    }

    /// `run.json`: the header without which a results directory is a pile of numbers
    /// nobody can say the provenance of. Written unconditionally so the file exists
    /// even on a run where every scenario passed.
    @Test func theRunHeaderIsWritten() throws {
        let digest = try SHA256.hash(data: ScenarioCorpus.digestInput())
            .map { String(format: "%02x", $0) }.joined()
        let metadata = RunMetadata(
            corpusDigest: digest,
            corpusSize: ScenarioCorpus.standard.count,
            gitRef: ResultsWriter.gitRef,
            startedAt: ISO8601DateFormatter().string(from: Date()),
            legs: ["pure", "store", "model"],
            cadenceSeconds: Int(ReplayEngine.defaultCadenceSeconds),
            coarseCadenceSeconds: Int(ReplayEngine.coarseCadenceSeconds),
            coarseCadenceAboveSeconds: ReplayEngine.coarseCadenceAboveSeconds
        )
        let wrote = ResultsWriter.writeRun(metadata)
        // Inert without LABOR_QA_OUT, which is the ordinary edit-test case.
        #expect(wrote == (ResultsWriter.outputDirectory != nil))
    }
}
