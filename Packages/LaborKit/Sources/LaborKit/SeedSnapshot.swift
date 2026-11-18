#if DEBUG
/// The wire format between the QA harness and DemoSeed: record times as offsets
/// relative to launch `now` (negative = past), matching DemoSeed's
/// relative-to-now seeding. One shared type so encoder (LaborSim) and decoder
/// (DemoSeed) cannot drift.
public struct LaborSeedSnapshot: Codable, Sendable {
    public struct Record: Codable, Sendable {
        public var startOffsetSeconds: Double
        public var endOffsetSeconds: Double?   // nil = still running

        public init(startOffsetSeconds: Double, endOffsetSeconds: Double?) {
            self.startOffsetSeconds = startOffsetSeconds
            self.endOffsetSeconds = endOffsetSeconds
        }
    }

    public var version: Int    // 1 or 2; bump again on the next shape change
    public var records: [Record]

    /// The guideline rule this snapshot was derived under — `GuidelineRule.rawValue`
    /// (F-0020). Without it `DemoSeed` never had a rule to persist, so every
    /// rule-switch shot judged against whichever rule the device already had
    /// (5-1-1 by default), no matter what the snapshot's own facts assumed.
    ///
    /// `nil` on a version-1 payload — there was nothing to carry then, and decoding
    /// one still has to succeed exactly as it always did: `Optional` properties
    /// decode a missing key as `nil` for free, so no custom `init(from:)` is needed
    /// to keep that path working.
    public var rule: String?

    public init(version: Int = 2, records: [Record], rule: String? = nil) {
        self.version = version
        self.records = records
        self.rule = rule
    }
}
#endif
