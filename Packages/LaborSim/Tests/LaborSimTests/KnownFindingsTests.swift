import Foundation
import Testing
@testable import LaborSim

/// The ratchet on the registry.
///
/// `KnownFindings` is permission to be wrong about specific things, and permission
/// that outlives the defect is how a suite quietly stops testing. So every entry has
/// to keep earning its place: it must still match a scenario the harness actually
/// runs, and that scenario must still produce the violation it claims. A fix removes
/// the entry in the same commit or this goes red — which is the intended failure, not
/// a nuisance.
@MainActor
@Suite("Known findings registry")
struct KnownFindingsTests {

    /// Patterns are matched against **manifest** ids, not seed-ref ids. The boundary
    /// battery is hand-authored and names its own cases
    /// (`boundaryBattery-advDoubleDelete`) while its ref derives a positional id, and a
    /// registry that named the positional one would silently re-point at a different
    /// case the moment a probe was inserted ahead of it.
    static let corpus: [(ref: ScenarioSeedRef, id: String)] = ScenarioCorpus.standard.map {
        ($0, ScenarioCorpus.generate($0).id)
    }

    /// Candidates for one entry: the whole corpus for the pure leg, the replay
    /// subsample for the rest. An entry gating a leg is only meaningful over the
    /// scenarios that leg actually runs — and searching the other three hundred for a
    /// container-backed violation would cost minutes to prove nothing.
    static func matching(_ entry: KnownFinding) -> [ScenarioSeedRef] {
        let pool: [(ref: ScenarioSeedRef, id: String)]
        switch entry.leg {
        case .pure:
            pool = corpus
        case .store, .model, .agreement:
            let sampled = Set(ReplaySubsample.refs)
            pool = corpus.filter { sampled.contains($0.ref) }
        }
        return pool.filter { KnownFindings.matches(entry.scenarioIdPattern, $0.id) }.map(\.ref)
    }

    @Test func everyEntryNamesRealScenarios() {
        for entry in KnownFindings.registry {
            #expect(!Self.matching(entry).isEmpty, """
                stale entry \(entry.findingRef): '\(entry.scenarioIdPattern)' matches no \
                scenario the \(entry.leg.rawValue) leg runs
                """)
        }
    }

    /// Replays each entry's own scenarios and demands the violation still happens.
    /// Stops at the first match — the question is whether the defect survives, not how
    /// widespread it is, and prevalence is the report's job. Replays are memoised
    /// across entries because several findings share a leg and a scenario pool.
    @Test func everyEntryStillFires() throws {
        var cache: [String: [String: Int]] = [:]

        func totals(_ leg: KnownFinding.Leg, _ ref: ScenarioSeedRef) throws -> [String: Int] {
            let key = "\(leg.rawValue)|\(ref.id)"
            if let cached = cache[key] { return cached }
            let manifest = ScenarioCorpus.generate(ref)
            let result: [String: Int]
            switch leg {
            case .pure:
                result = PureSweep.run(manifest).collector.totals
            case .store:
                result = try StoreReplay.run(manifest).collector.totals
            case .model:
                result = try ModelReplay.run(manifest).collector.totals
            case .agreement:
                let pure = TimelineCompare.rows(ReplayEngine.fold(manifest.actions))
                let store = TimelineCompare.rows(
                    try StoreReplay.run(manifest, leg: .agreement).final, t0: manifest.t0
                )
                let model = TimelineCompare.rows(
                    try ModelReplay.run(manifest, leg: .agreement).final, t0: manifest.t0
                )
                let diverged = TimelineCompare.firstDifference(store, pure) != nil
                    || TimelineCompare.firstDifference(model, pure) != nil
                result = diverged ? ["T0-02": 1] : [:]
            }
            cache[key] = result
            return result
        }

        for entry in KnownFindings.registry {
            var fired = false
            for ref in Self.matching(entry) {
                let counts = try totals(entry.leg, ref)
                if counts[entry.checkId, default: 0] > 0 {
                    fired = true
                    break
                }
            }
            #expect(fired, """
                stale entry \(entry.findingRef): \(entry.checkId) no longer fires on \
                '\(entry.scenarioIdPattern)' [\(entry.leg.rawValue)] — remove it
                """)
        }
    }

    /// The glob is the only pattern language this file allows, and a matcher that
    /// silently matched everything would hand out blanket permission.
    @Test func theGlobMatcherIsNarrow() {
        #expect(KnownFindings.matches("exact-id", "exact-id"))
        #expect(!KnownFindings.matches("exact-id", "exact-idx"))
        #expect(KnownFindings.matches("prefix*", "prefix-and-more"))
        #expect(!KnownFindings.matches("prefix*", "not-prefix"))
        #expect(KnownFindings.matches("*suffix", "ends-with-suffix"))
        #expect(!KnownFindings.matches("*suffix", "suffix-then-more"))
        #expect(KnownFindings.matches("*middle*", "has-middle-inside"))
        #expect(!KnownFindings.matches("*middle*", "has-nothing-inside"))
        #expect(KnownFindings.matches("a*b*c", "a-x-b-y-c"))
        #expect(!KnownFindings.matches("a*b*c", "a-x-c-y-b"))
    }

    /// Every entry has to be triageable: a reference, a mechanism, and a check id the
    /// rubric has actually heard of.
    @Test func everyEntryIsWellFormed() {
        let known: Set<String> = [
            "T0-01", "T0-02", "T0-03", "T0-04", "T0-05", "T0-06", "T0-07", "T0-08",
            "T0-09", "T0-10", "T0-10a", "T0-11", "T0-12", "T0-13", "T0-14", "T0-15",
        ]
        for entry in KnownFindings.registry {
            #expect(!entry.findingRef.isEmpty)
            #expect(entry.mechanism.count > 20, "\(entry.findingRef) has no mechanism")
            #expect(known.contains(entry.checkId), "\(entry.checkId) is not a rubric check id")
        }
    }

    /// A registry that could match everything would be a blanket exemption. Nothing in
    /// it may name the whole corpus.
    @Test func noEntryMatchesTheWholeCorpus() {
        for entry in KnownFindings.registry {
            #expect(entry.scenarioIdPattern != "*", "\(entry.findingRef) exempts everything")
            #expect(Self.matching(entry).count < ScenarioCorpus.standard.count,
                    "\(entry.findingRef) exempts the entire corpus")
        }
    }
}
