#if DEBUG
import Foundation
import Testing
@testable import LaborKit

/// The wire format is the one contract between the QA harness (which encodes) and
/// `DemoSeed` (which decodes) — a round trip here is what keeps them from drifting
/// independently, since neither side imports the other.
@Suite("Labor seed snapshot")
struct SeedSnapshotTests {
    @Test func encodingAndDecodingRoundTripsExactly() throws {
        let snapshot = LaborSeedSnapshot(
            version: 1,
            records: [
                LaborSeedSnapshot.Record(startOffsetSeconds: -3600, endOffsetSeconds: -3538),
                LaborSeedSnapshot.Record(startOffsetSeconds: -300, endOffsetSeconds: -240),
                LaborSeedSnapshot.Record(startOffsetSeconds: -30, endOffsetSeconds: nil)
            ]
        )

        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(LaborSeedSnapshot.self, from: data)

        #expect(decoded.version == 1)
        #expect(decoded.records.count == 3)
        #expect(decoded.records[0].startOffsetSeconds == -3600)
        #expect(decoded.records[0].endOffsetSeconds == -3538)
        #expect(decoded.records.last?.endOffsetSeconds == nil)
        #expect(decoded.rule == nil, "a v1 payload built without a rule round-trips without one")
    }

    /// F-0020: version 2 carries the rule the snapshot's facts were computed under,
    /// and it has to survive the same round trip the offsets do.
    @Test func versionTwoRoundTripsTheRule() throws {
        let snapshot = LaborSeedSnapshot(
            version: 2,
            records: [LaborSeedSnapshot.Record(startOffsetSeconds: -300, endOffsetSeconds: -240)],
            rule: "fourOneOne"
        )

        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(LaborSeedSnapshot.self, from: data)

        #expect(decoded.version == 2)
        #expect(decoded.rule == "fourOneOne")
    }

    /// `DemoSeed` reads snapshots as plain JSON files, not through the encoder — a
    /// hand-written payload has to decode too, or the harness's file format is only
    /// ever tested against its own encoder's exact byte-for-byte output.
    @Test func decodesAHandWrittenPayload() throws {
        let json = """
        {"version":1,"records":[{"startOffsetSeconds":-300,"endOffsetSeconds":-240}]}
        """
        let decoded = try JSONDecoder().decode(LaborSeedSnapshot.self, from: Data(json.utf8))

        #expect(decoded.version == 1)
        #expect(decoded.records[0].startOffsetSeconds == -300)
        #expect(decoded.records[0].endOffsetSeconds == -240)
        #expect(decoded.rule == nil, "a hand-written v1 payload carries no `rule` key at all")
    }

    /// The hand-written half of F-0020: a v2 payload carrying a `rule` key decodes
    /// with it. The v1 compatibility case — `rule` absent altogether — is the test
    /// above.
    @Test func decodesAHandWrittenVersionTwoPayloadWithARule() throws {
        let json = """
        {"version":2,"records":[{"startOffsetSeconds":-300,"endOffsetSeconds":-240}],"rule":"threeOneOne"}
        """
        let decoded = try JSONDecoder().decode(LaborSeedSnapshot.self, from: Data(json.utf8))

        #expect(decoded.version == 2)
        #expect(decoded.rule == "threeOneOne")
    }
}
#endif
