import Foundation
import Testing
@testable import LaborSim

/// The manifest is the harness's only durable artifact: golden fixtures are
/// manifests, the corpus digest hashes manifests, and a finding is reproduced by
/// re-decoding one. A case that survives encoding but not decoding would surface as
/// a mysterious engine disagreement months later, so every case round-trips here.
@Suite("Manifest schema")
struct SchemaRoundTripTests {

    private func roundTrip<T: Codable & Equatable>(_ value: T) throws -> T {
        let data = try CanonicalJSON.data(value)
        return try CanonicalJSON.decode(T.self, from: data)
    }

    /// Every action, including the ones whose payloads differ — the discriminator
    /// carries the case and the extra keys carry the rest, and a case that forgot to
    /// encode its payload would decode as a plausible-looking sibling.
    private static let everyAction: [ScenarioAction] = [
        .tapStart(at: 0),
        .tapEnd(at: 61),
        .deleteRecord(at: 900, createdBy: 3),
        .undoDelete(at: 930, createdBy: 3),
        .killApp(at: 1200),
        .launchApp(at: 1260),
        .clockSet(at: 1800, deltaSeconds: -600),
        .timezoneChange(at: 2400, identifier: "Europe/London"),
        .setRule(at: 3000, rule: "fourOneOne"),
        .clearAll(at: 3600)
    ]

    @Test(arguments: SchemaRoundTripTests.everyAction)
    func everyActionCaseRoundTrips(action: ScenarioAction) throws {
        #expect(try roundTrip(action) == action)
    }

    /// Case coverage is asserted structurally: adding a case to `ScenarioAction`
    /// without adding it here turns this red rather than silently shipping an
    /// untested case.
    @Test func theSampleCoversEveryActionKind() {
        let covered = Set(Self.everyAction.map(\.kind))
        #expect(covered == Set(ScenarioAction.Kind.allCases))
    }

    /// Negative deltas are the interesting clock case (a phone set *backwards* mid
    /// labor), and an unsigned encoding would lose the sign silently.
    @Test func negativeClockDeltaSurvives() throws {
        let action = ScenarioAction.clockSet(at: 500, deltaSeconds: -37)
        #expect(try roundTrip(action) == action)
    }

    @Test func actionTimesAreReadableUniformly() {
        #expect(Self.everyAction.map(\.at) == [0, 61, 900, 930, 1200, 1260, 1800, 2400, 3000, 3600])
    }

    // MARK: Whole manifest

    private func sampleManifest() -> ScenarioManifest {
        let ref = ScenarioSeedRef(
            archetype: .classicNullipara, paramVariant: 1,
            noiseProfile: .typicalSolo, run: 2, rule: "fiveOneOne"
        )
        return ScenarioManifest(
            id: ref.id,
            seed: ref.seed,
            archetype: ref.archetype.rawValue,
            paramVariant: ref.paramVariant,
            noiseProfile: ref.noiseProfile.rawValue,
            rule: ref.rule,
            ruleChanges: [RuleChange(at: 4200, rule: "fourOneOne")],
            pretermContext: true,
            trueContractions: [
                TrueContraction(start: 0, end: 45),
                TrueContraction(start: 300, end: 361)
            ],
            actions: Self.everyAction,
            truth: TruthTimeline(
                episodesTrue: [TruthSpan(start: 0, end: 3600)],
                zones: [
                    TruthZone(rule: "fiveOneOne", kind: .mustNotFire, from: 0, to: 3299),
                    TruthZone(rule: "fiveOneOne", kind: .gray, from: 3300, to: 3899),
                    TruthZone(rule: "fiveOneOne", kind: .mustFire, from: 3900, to: 7200)
                ],
                events: [
                    TruthEvent(type: .onsetTrue, rule: "fiveOneOne", at: 3900),
                    TruthEvent(type: .neverQualifies, rule: "threeOneOne")
                ],
                expectedSuspects: [4, 9]
            ),
            expectedDetection: ["forgottenStop"],
            simulatorCheckpoint: SimCheckpoint(seedThroughAction: 6, liveTailSeconds: 240)
        )
    }

    @Test func aFullManifestRoundTripsToIdentity() throws {
        let manifest = sampleManifest()
        #expect(try roundTrip(manifest) == manifest)
    }

    /// Optionals are the usual round-trip casualty: absent must decode as absent,
    /// not as an empty array that later reads as "compiled, found nothing".
    @Test func absentOptionalsStayAbsent() throws {
        var manifest = sampleManifest()
        manifest.ruleChanges = nil
        manifest.expectedDetection = nil
        manifest.simulatorCheckpoint = nil
        let decoded = try roundTrip(manifest)
        #expect(decoded.ruleChanges == nil)
        #expect(decoded.expectedDetection == nil)
        #expect(decoded.simulatorCheckpoint == nil)
        #expect(decoded == manifest)
    }

    /// The digest test hashes these bytes, so identical values must produce
    /// identical bytes on every run — key order included.
    @Test func canonicalEncodingIsByteStable() throws {
        let manifest = sampleManifest()
        let first = try CanonicalJSON.data(manifest)
        let second = try CanonicalJSON.data(manifest)
        #expect(first == second)

        let text = String(decoding: first, as: UTF8.self)
        // Sorted keys put `actions` before `archetype` before `id`; a change to the
        // encoder's formatting options would break this and the digest pin together.
        #expect(text.hasPrefix("{\"actions\""))
        #expect(!text.contains("\\/"))
    }

    /// Seeds are UInt64 and routinely exceed 2^53. JSON's number type is where that
    /// quietly becomes a Double and loses the low bits.
    @Test func largeSeedsSurviveJSON() throws {
        var manifest = sampleManifest()
        manifest.seed = 0xFFFF_FFFF_FFFF_FFF5
        #expect(try roundTrip(manifest).seed == 0xFFFF_FFFF_FFFF_FFF5)
    }

    // MARK: Seed refs

    @Test func refsDeriveTheirOwnSeedFromTheirOwnParts() {
        let ref = ScenarioSeedRef(
            archetype: .precipitous, paramVariant: 2, noiseProfile: .chaotic, rule: "fiveOneOne"
        )
        #expect(ref.seed == SeedDerivation.scenarioSeed(archetype: "precipitous", paramVariant: 2))
    }

    /// The physiology seed depends on the archetype and variant *only*, which is
    /// what makes the same true labor replayable under every noise profile.
    @Test func noiseProfileDoesNotChangeTheScenarioSeed() {
        let quiet = ScenarioSeedRef(
            archetype: .precipitous, paramVariant: 0, noiseProfile: .clean, rule: "fiveOneOne"
        )
        let loud = ScenarioSeedRef(
            archetype: .precipitous, paramVariant: 0, noiseProfile: .chaotic, rule: "fiveOneOne"
        )
        #expect(quiet.seed == loud.seed)
        #expect(quiet.id != loud.id)
    }

    @Test func labelsCarryEnoughToIdentifyTheScenario() {
        let ref = ScenarioSeedRef(
            archetype: .classicNullipara, paramVariant: 1,
            noiseProfile: .typicalSolo, run: 0, rule: "fiveOneOne"
        )
        #expect(ref.label.hasPrefix("classicNullipara/v1/typicalSolo/r0#5-1-1#0x"))
        #expect(ref.id.contains("classicNullipara-v1-typicalSolo-r0-fiveOneOne-"))
    }

    /// Filenames: the id becomes a path component, so it must not contain anything
    /// a filesystem would object to.
    @Test func idsAreFilesystemSafe() {
        for archetype in ArchetypeID.allCases {
            let ref = ScenarioSeedRef(
                archetype: archetype, paramVariant: 0, noiseProfile: .clean, rule: "fiveOneOne"
            )
            #expect(!ref.id.contains("/"))
            #expect(!ref.id.contains(" "))
            #expect(!ref.id.contains("#"))
        }
    }
}
