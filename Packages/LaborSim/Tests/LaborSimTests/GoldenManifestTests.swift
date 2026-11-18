import Foundation
import Testing
@testable import LaborSim

/// Six committed manifests, generated once and frozen.
///
/// The corpus digest pins *which* scenarios the harness runs; these pin *what
/// generation produces from them*. Both are needed and neither substitutes for the
/// other: a refactor of the physiology model would leave the digest untouched while
/// silently rewriting every labor in the corpus, and the first symptom would be a
/// report that no longer compares to last week's.
///
/// When one of these fails legitimately — because the generator was deliberately
/// changed — the fix is to bump `LaborSimVersion.generator`, regenerate the
/// fixtures, and bump the corpus manifest's **major** version. It is never to edit
/// a fixture until it matches.
@Suite("Golden manifests")
struct GoldenManifestTests {

    /// One per interesting shape: a textbook labor, a fast one, one that dies out,
    /// a coupled one, a multi-day one, and an exact-arithmetic probe.
    static let golden: [(name: String, ref: ScenarioSeedRef)] = [
        ("classicNullipara-typicalSolo", ScenarioSeedRef(
            archetype: .classicNullipara, paramVariant: 0,
            noiseProfile: .typicalSolo, run: 0, rule: "fiveOneOne")),
        ("precipitous-exhaustedSolo", ScenarioSeedRef(
            archetype: .precipitous, paramVariant: 1,
            noiseProfile: .exhaustedSolo, run: 0, rule: "fiveOneOne")),
        ("prodromalFizzle-clean", ScenarioSeedRef(
            archetype: .prodromalFizzle, paramVariant: 0,
            noiseProfile: .clean, run: 0, rule: "fiveOneOne")),
        ("backLaborCoupling-typicalSolo", ScenarioSeedRef(
            archetype: .backLaborCoupling, paramVariant: 2,
            noiseProfile: .typicalSolo, run: 0, rule: "fiveOneOne")),
        ("multiDayLatent-exhaustedSolo", ScenarioSeedRef(
            archetype: .multiDayLatent, paramVariant: 0,
            noiseProfile: .exhaustedSolo, run: 1, rule: "fiveOneOne")),
        ("boundaryBattery-first", ScenarioSeedRef(
            archetype: .boundaryBattery, paramVariant: 0,
            noiseProfile: .clean, run: 0, rule: "fiveOneOne", seed: 0))
    ]

    static func fixtureURL(_ name: String) throws -> URL {
        try #require(
            Bundle.module.url(
                forResource: name, withExtension: "json", subdirectory: "Fixtures"
            ),
            "fixture \(name).json is missing from the test bundle"
        )
    }

    @Test(arguments: GoldenManifestTests.golden)
    func generationMatchesItsFrozenFixture(entry: (name: String, ref: ScenarioSeedRef)) throws {
        let data = try Data(contentsOf: Self.fixtureURL(entry.name))
        let expected = try CanonicalJSON.decode(ScenarioManifest.self, from: data)
        let actual = ScenarioCorpus.generate(entry.ref)

        // Compare the decoded values rather than the bytes: a formatting change in
        // the encoder is not a change in the scenario, and conflating the two would
        // make this test fail for reasons that do not matter.
        #expect(actual == expected, "\(entry.name) drifted from its golden fixture")
    }

    /// The fixtures must round-trip through the same canonical encoder that wrote
    /// them, or the freeze is not actually reproducible.
    @Test(arguments: GoldenManifestTests.golden)
    func fixturesReEncodeToTheirOwnBytes(entry: (name: String, ref: ScenarioSeedRef)) throws {
        let data = try Data(contentsOf: Self.fixtureURL(entry.name))
        let decoded = try CanonicalJSON.decode(ScenarioManifest.self, from: data)
        let reencoded = try CanonicalJSON.data(decoded, pretty: true)
        #expect(reencoded == data, "\(entry.name) does not re-encode to its own bytes")
    }

    /// A fixture that froze an empty scenario would pass forever and guard nothing.
    @Test(arguments: GoldenManifestTests.golden)
    func fixturesContainRealScenarios(entry: (name: String, ref: ScenarioSeedRef)) throws {
        let data = try Data(contentsOf: Self.fixtureURL(entry.name))
        let manifest = try CanonicalJSON.decode(ScenarioManifest.self, from: data)
        #expect(!manifest.actions.isEmpty)
        #expect(manifest.schemaVersion == LaborSimVersion.schema)
        #expect(manifest.generatorVersion == LaborSimVersion.generator)
        // Sampled scenarios take their id from the ref; the battery keeps the
        // authored case name it is filed under, so identity is checked against what
        // generation actually produces rather than against the ref in both cases.
        #expect(manifest.id == ScenarioCorpus.generate(entry.ref).id)
        #expect(!manifest.id.isEmpty)
    }

    /// The generator version is stamped into every manifest so a report can say
    /// which generator produced it. A fixture carrying a stale one means the freeze
    /// and the code have already parted company.
    @Test func everyGoldenFixtureCarriesTheCurrentGeneratorVersion() throws {
        for entry in Self.golden {
            let data = try Data(contentsOf: Self.fixtureURL(entry.name))
            let manifest = try CanonicalJSON.decode(ScenarioManifest.self, from: data)
            #expect(manifest.generatorVersion == LaborSimVersion.generator)
        }
    }

    /// The pointer file that asks for a regeneration, alongside `ResultsWriter`'s.
    /// An exported variable cannot reach a simulator-hosted test process — that is
    /// `ResultsWriter`'s whole documented reason for existing, and writing this test
    /// against `ProcessInfo` first proved it again: the guard fell through, nothing
    /// was written, and `xcodebuild` reported TEST SUCCEEDED. A silent no-op that
    /// prints success is the exact failure mode the harness keeps re-learning.
    static let pointerFileName = ".hushlight-golden-out"

    /// Rewrites the six fixtures from the current generator. Silent no-op unless the
    /// pointer file names the source `Fixtures` directory — opt-in for the same
    /// reason `ResultsWriter` is: a test that writes to the repo on every run is a
    /// test that can launder a regression into a new baseline.
    ///
    /// This exists because the freeze has a legitimate release valve and it was
    /// tribal knowledge. The suite's own header states the procedure — bump
    /// `LaborSimVersion.generator`, regenerate, bump the corpus major — and the
    /// middle step was the one nobody could run. Making it a command is what keeps
    /// the other two honest: regenerating without the version bump now fails
    /// `everyGoldenFixtureCarriesTheCurrentGeneratorVersion` on the next run.
    ///
    ///     echo "$PWD/Packages/LaborSim/Tests/LaborSimTests/Fixtures" > ~/.hushlight-golden-out
    ///     ./scripts/test.sh LaborSim
    ///     rm ~/.hushlight-golden-out
    @Test func regenerateGoldenFixturesWhenAsked() throws {
        let environment = ProcessInfo.processInfo.environment
        guard let home = environment["SIMULATOR_HOST_HOME"] ?? environment["HOME"],
              let data = try? Data(
                  contentsOf: URL(fileURLWithPath: home)
                      .appendingPathComponent(Self.pointerFileName)
              ),
              let directory = String(data: data, encoding: .utf8)?
                  .trimmingCharacters(in: .whitespacesAndNewlines),
              !directory.isEmpty
        else { return }

        let base = URL(fileURLWithPath: directory, isDirectory: true)
        for entry in Self.golden {
            let manifest = ScenarioCorpus.generate(entry.ref)
            let data = try CanonicalJSON.data(manifest, pretty: true)
            try data.write(to: base.appendingPathComponent("\(entry.name).json"))
        }
    }
}
