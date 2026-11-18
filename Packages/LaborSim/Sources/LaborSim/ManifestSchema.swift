import Foundation

/// The generator's identity, stamped into every manifest.
///
/// Bump it whenever a change would alter generated scenarios. Reports are only
/// row-comparable within one generator version (decision 0021 §5), and a manifest
/// that cannot say which generator produced it is a manifest nobody can re-derive.
public enum LaborSimVersion {
    /// 3.0.0 — SP-203, decision 0032. `truth.expectedSuspects` now carries the short
    /// side too: a recorded length under twenty seconds is a tap artifact, and the
    /// referee expects the app to flag it exactly as it expects the over-three-minute
    /// side to be flagged. The taps themselves are byte-identical — no archetype, no
    /// noise draw, no zone moved — but generated manifests differ for existing
    /// scenarios, which is a generator change by this file's own rule, and the
    /// findings a run produces differ with it (suppressions 46 → 41 on the same
    /// corpus). So: goldens regenerated, corpus major bumped alongside.
    ///
    /// 2.0.0 — SP-194 wave D. Truth is now compiled against the decided semantics
    /// rather than the engine's old ones (share-based frequency, margins bracketing
    /// the 50 s duration threshold, continuity in the sustained clause), and every
    /// zone carries the clause that condemned it. Both change what generation
    /// produces from an unchanged seed, so the goldens were regenerated and the
    /// corpus took its major bump alongside.
    public static let generator = "3.0.0"
    public static let schema = 1
}

/// The one epoch every scenario is written against — the same fixed instant
/// `LaborKitTests` uses. Nothing in this package reads the wall clock: a QA harness
/// whose corpus changes with the date is a harness whose failures nobody can
/// reproduce.
public let laborSimEpoch: Int64 = 1_800_000_000

// MARK: - Identifiers

/// The thirteen labor shapes the corpus covers. `boundaryBattery` is the odd one
/// out — it is hand-authored exact arithmetic rather than sampled physiology, and
/// the generator branches on it explicitly.
public enum ArchetypeID: String, Codable, Sendable, CaseIterable {
    case classicNullipara
    case classicMultipara
    case precipitous
    case prodromalFizzle
    case prodromalNightly
    case braxtonHicks
    case irregularProgressing
    case backLaborCoupling
    case pretermEarly
    case inductionRamp
    case multiDayLatent
    case sromThenOnset
    case boundaryBattery

    /// Everything the physiology model samples. The battery is authored, not drawn.
    public static var sampled: [ArchetypeID] {
        allCases.filter { $0 != .boundaryBattery }
    }
}

/// The six thumbs. Ordered loosely by how much they cost the record — `clean` is the
/// impossible ideal that isolates engine bugs from user-behaviour bugs.
public enum NoiseProfileID: String, Codable, Sendable, CaseIterable {
    case clean
    case partnerDiligent
    case typicalSolo
    case exhaustedSolo
    case chaotic
    case clockHostile
}

// MARK: - Scenario identity

/// The committed half of the corpus: enough to re-derive a whole scenario, and
/// nothing else. Decision 0021 §5 keeps ~400 manifests *out* of the tree — seeds
/// plus a digest pin plus golden fixtures reproduce them without the drift.
public struct ScenarioSeedRef: Codable, Sendable, Equatable, Hashable {
    public var archetype: ArchetypeID
    public var paramVariant: Int
    public var noiseProfile: NoiseProfileID

    /// Which run of this profile. The same archetype/variant has exactly one
    /// physiology seed by construction, so two `typicalSolo` runs of one labor are
    /// distinguished here and nowhere else — without it the second run would be a
    /// byte-identical copy of the first.
    public var run: Int

    public var rule: String
    public var seed: UInt64

    public init(
        archetype: ArchetypeID,
        paramVariant: Int,
        noiseProfile: NoiseProfileID,
        run: Int = 0,
        rule: String,
        seed: UInt64
    ) {
        self.archetype = archetype
        self.paramVariant = paramVariant
        self.noiseProfile = noiseProfile
        self.run = run
        self.rule = rule
        self.seed = seed
    }

    /// Derives the ref from its own parts, so a corpus row can never carry a seed
    /// that disagrees with the archetype it names.
    public init(
        archetype: ArchetypeID,
        paramVariant: Int,
        noiseProfile: NoiseProfileID,
        run: Int = 0,
        rule: String
    ) {
        self.init(
            archetype: archetype,
            paramVariant: paramVariant,
            noiseProfile: noiseProfile,
            run: run,
            rule: rule,
            seed: SeedDerivation.scenarioSeed(
                archetype: archetype.rawValue, paramVariant: paramVariant
            )
        )
    }

    /// Stable, filesystem-safe, and unique across the corpus — it names the results
    /// JSON and the golden fixture, so it must survive being a filename.
    public var id: String {
        "\(archetype.rawValue)-v\(paramVariant)-\(noiseProfile.rawValue)-r\(run)-\(rule)-\(Self.hex(seed))"
    }

    /// The failure label. Seeds render at full width rather than the eye-friendly
    /// four digits: across ~400 scenarios a 16-bit tag collides by birthday more
    /// often than not, and a label that cannot identify its scenario is decoration.
    public var label: String {
        let ruleLabel = GuidelineRuleLabels.label(forRawValue: rule)
        return "\(archetype.rawValue)/v\(paramVariant)/\(noiseProfile.rawValue)/r\(run)"
            + "#\(ruleLabel)#0x\(Self.hex(seed))"
    }

    static func hex(_ value: UInt64) -> String {
        let digits = String(value, radix: 16, uppercase: true)
        return String(repeating: "0", count: max(0, 16 - digits.count)) + digits
    }
}

extension ScenarioSeedRef: CustomStringConvertible {
    public var description: String { label }
}

/// Rule rawValue → the taught label, without importing LaborKit into anything that
/// only needs a string. Kept beside the ref it serves.
public enum GuidelineRuleLabels {
    public static func label(forRawValue raw: String) -> String {
        switch raw {
        case "fiveOneOne": "5-1-1"
        case "fourOneOne": "4-1-1"
        case "threeOneOne": "3-1-1"
        default: raw
        }
    }
}

// MARK: - Manifest

/// One contraction as the body produced it, before any thumb touched a button.
/// Whole seconds relative to `t0`; the noise-free stream the clinical-intent oracle
/// judges against.
public struct TrueContraction: Codable, Sendable, Equatable {
    public var start: Int64
    public var end: Int64

    public init(start: Int64, end: Int64) {
        self.start = start
        self.end = end
    }

    public var durationSeconds: Int64 { end - start }
}

/// A half-open-in-spirit span in scenario seconds. Both bounds inclusive; spans are
/// only ever compared against whole seconds, so there is no half-second to lose.
public struct TruthSpan: Codable, Sendable, Equatable {
    public var start: Int64
    public var end: Int64

    public init(start: Int64, end: Int64) {
        self.start = start
        self.end = end
    }

    public func contains(_ time: Int64) -> Bool { time >= start && time <= end }
}

/// A rule change partway through a scenario — someone re-reads the discharge sheet
/// at 2am and switches from 5-1-1 to 4-1-1.
public struct RuleChange: Codable, Sendable, Equatable {
    public var at: Int64
    public var rule: String

    public init(at: Int64, rule: String) {
        self.at = at
        self.rule = rule
    }
}

/// What the app must do over a span, judged from the true stream alone.
///
/// The three-way split is the whole point: a knife-edge instant where the true mean
/// sits at 300.4 s cannot be allowed to define a pass or a fail, because a single
/// second of sampling luck would flip it. Only the margined zones assert.
public enum TruthZoneKind: String, Codable, Sendable {
    /// The body genuinely met the rule with margin to spare. Silence here is S4.
    case mustFire
    /// Inside the margin. The harness asserts nothing; either answer is defensible.
    case gray
    /// The body clearly did not meet the rule. A verdict here is a false positive.
    case mustNotFire
}

/// Which `mustNotFire` clause condemned a zone (F-0028's per-clause
/// attribution) — `nil` on `mustFire`/`gray` zones, where truth is not
/// condemning anything. When more than one clause holds at the same instant,
/// `TruthCompiler.classify` picks by a fixed precedence — count → sustained →
/// frequency → duration, evidence before statistics — documented there, so the
/// attribution is deterministic rather than a pick of whichever clause was
/// evaluated last.
public enum TruthZoneReason: String, Codable, Sendable, Equatable {
    case count
    case sustained
    case frequency
    case duration
}

public struct TruthZone: Codable, Sendable, Equatable {
    public var rule: String
    public var kind: TruthZoneKind
    public var from: Int64
    public var to: Int64

    /// Optional with a default: every existing decode path — golden fixtures
    /// included — keeps working, reading an older manifest's zones as simply
    /// having no opinion about which clause condemned them.
    public var reason: TruthZoneReason?

    public init(
        rule: String, kind: TruthZoneKind, from: Int64, to: Int64, reason: TruthZoneReason? = nil
    ) {
        self.rule = rule
        self.kind = kind
        self.from = from
        self.to = to
        self.reason = reason
    }
}

public enum TruthEventType: String, Codable, Sendable {
    /// The first instant the rule was genuinely, durably met.
    case onsetTrue
    /// The rule stopped being met (a pattern that backed off).
    case offsetTrue
    /// A prodromal bout that inflated its own intervals and died out.
    case fizzle
    /// A true >2 h gap — the point where "how long has this been happening" resets.
    case episodeBoundaryTrue
    /// This scenario never qualifies under this rule at any instant. The
    /// false-positive probe: any verdict at all is a finding.
    case neverQualifies
}

public struct TruthEvent: Codable, Sendable, Equatable {
    public var type: TruthEventType
    public var rule: String?
    public var at: Int64?

    public init(type: TruthEventType, rule: String? = nil, at: Int64? = nil) {
        self.type = type
        self.rule = rule
        self.at = at
    }
}

/// Ground truth: what the body did, independent of what got recorded.
public struct TruthTimeline: Codable, Sendable, Equatable {
    public var episodesTrue: [TruthSpan]
    public var zones: [TruthZone]
    public var events: [TruthEvent]

    /// Records the app *should* flag as suspect, addressed by the index of the
    /// action that created them. Store position is not an address: a delete two
    /// hours earlier renumbers every position and nothing else.
    public var expectedSuspects: [Int]

    public init(
        episodesTrue: [TruthSpan] = [],
        zones: [TruthZone] = [],
        events: [TruthEvent] = [],
        expectedSuspects: [Int] = []
    ) {
        self.episodesTrue = episodesTrue
        self.zones = zones
        self.events = events
        self.expectedSuspects = expectedSuspects
    }
}

/// Where a simulator pass should pick the scenario up: seed the store through
/// `seedThroughAction`, then drive the last `liveTailSeconds` in real time.
///
/// Decision 0021 rejected compressed-time UI replay — the design's running state
/// derives from stored timestamps, so a fast clock tests a different app. A seeded
/// snapshot plus a short real-time tail tests this one.
public struct SimCheckpoint: Codable, Sendable, Equatable {
    public var seedThroughAction: Int
    public var liveTailSeconds: Int

    public init(seedThroughAction: Int, liveTailSeconds: Int) {
        self.seedThroughAction = seedThroughAction
        self.liveTailSeconds = liveTailSeconds
    }
}

/// One fully-specified simulated labor: the body, the thumb, and the truth.
public struct ScenarioManifest: Codable, Sendable, Equatable {
    public var schemaVersion: Int
    public var id: String
    public var generatorVersion: String
    public var seed: UInt64
    public var archetype: String
    public var paramVariant: Int
    public var noiseProfile: String
    public var rule: String
    public var ruleChanges: [RuleChange]?
    public var pretermContext: Bool

    /// Absolute epoch anchor. Every other time in this manifest is seconds relative
    /// to it, so the arithmetic stays in Int64 and never touches a calendar.
    public var t0: Int64

    /// Display-only. The engine is wall-clock; a timezone change must not move a
    /// single stored second, and asserting that is the point of carrying it.
    public var timeZone: String

    public var trueContractions: [TrueContraction]
    public var actions: [ScenarioAction]
    public var truth: TruthTimeline
    public var expectedDetection: [String]?
    public var simulatorCheckpoint: SimCheckpoint?

    public init(
        schemaVersion: Int = LaborSimVersion.schema,
        id: String,
        generatorVersion: String = LaborSimVersion.generator,
        seed: UInt64,
        archetype: String,
        paramVariant: Int,
        noiseProfile: String,
        rule: String,
        ruleChanges: [RuleChange]? = nil,
        pretermContext: Bool = false,
        t0: Int64 = laborSimEpoch,
        timeZone: String = "America/New_York",
        trueContractions: [TrueContraction],
        actions: [ScenarioAction],
        truth: TruthTimeline,
        expectedDetection: [String]? = nil,
        simulatorCheckpoint: SimCheckpoint? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.id = id
        self.generatorVersion = generatorVersion
        self.seed = seed
        self.archetype = archetype
        self.paramVariant = paramVariant
        self.noiseProfile = noiseProfile
        self.rule = rule
        self.ruleChanges = ruleChanges
        self.pretermContext = pretermContext
        self.t0 = t0
        self.timeZone = timeZone
        self.trueContractions = trueContractions
        self.actions = actions
        self.truth = truth
        self.expectedDetection = expectedDetection
        self.simulatorCheckpoint = simulatorCheckpoint
    }
}

// MARK: - Actions

/// Everything a thumb (or a phone) can do to the record.
///
/// Records are addressed by **the index of the action that created them**, never by
/// position in the store: a delete renumbers every later position, and an oracle
/// that disagrees with the engine about *which* record was meant would report
/// disagreements that are really its own bookkeeping.
public enum ScenarioAction: Sendable, Equatable {
    case tapStart(at: Int64)
    case tapEnd(at: Int64)
    case deleteRecord(at: Int64, createdBy: Int)
    case undoDelete(at: Int64, createdBy: Int)
    case killApp(at: Int64)
    case launchApp(at: Int64)
    case clockSet(at: Int64, deltaSeconds: Int64)
    case timezoneChange(at: Int64, identifier: String)
    case setRule(at: Int64, rule: String)
    case clearAll(at: Int64)

    /// Scenario seconds. Every case has one, which is what lets the action list be
    /// sorted and probed uniformly.
    public var at: Int64 {
        switch self {
        case let .tapStart(at), let .tapEnd(at), let .killApp(at),
             let .launchApp(at), let .clearAll(at):
            at
        case let .deleteRecord(at, _), let .undoDelete(at, _):
            at
        case let .clockSet(at, _):
            at
        case let .timezoneChange(at, _):
            at
        case let .setRule(at, _):
            at
        }
    }

    public var kind: Kind {
        switch self {
        case .tapStart: .tapStart
        case .tapEnd: .tapEnd
        case .deleteRecord: .deleteRecord
        case .undoDelete: .undoDelete
        case .killApp: .killApp
        case .launchApp: .launchApp
        case .clockSet: .clockSet
        case .timezoneChange: .timezoneChange
        case .setRule: .setRule
        case .clearAll: .clearAll
        }
    }

    public enum Kind: String, Codable, Sendable, CaseIterable {
        case tapStart, tapEnd, deleteRecord, undoDelete, killApp
        case launchApp, clockSet, timezoneChange, setRule, clearAll
    }
}

/// Hand-rolled `Codable` over a `kind` discriminator. Swift's synthesised enum
/// coding nests each case under its own key, which makes the JSON unreadable in a
/// diff and unstable to reorder — and these manifests are read by humans triaging
/// findings.
extension ScenarioAction: Codable {
    private enum CodingKeys: String, CodingKey {
        case kind, at, createdBy, deltaSeconds, identifier, rule
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        let at = try container.decode(Int64.self, forKey: .at)

        switch kind {
        case .tapStart: self = .tapStart(at: at)
        case .tapEnd: self = .tapEnd(at: at)
        case .killApp: self = .killApp(at: at)
        case .launchApp: self = .launchApp(at: at)
        case .clearAll: self = .clearAll(at: at)
        case .deleteRecord:
            self = .deleteRecord(at: at, createdBy: try container.decode(Int.self, forKey: .createdBy))
        case .undoDelete:
            self = .undoDelete(at: at, createdBy: try container.decode(Int.self, forKey: .createdBy))
        case .clockSet:
            self = .clockSet(at: at, deltaSeconds: try container.decode(Int64.self, forKey: .deltaSeconds))
        case .timezoneChange:
            self = .timezoneChange(at: at, identifier: try container.decode(String.self, forKey: .identifier))
        case .setRule:
            self = .setRule(at: at, rule: try container.decode(String.self, forKey: .rule))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(kind, forKey: .kind)
        try container.encode(at, forKey: .at)

        switch self {
        case let .deleteRecord(_, createdBy), let .undoDelete(_, createdBy):
            try container.encode(createdBy, forKey: .createdBy)
        case let .clockSet(_, deltaSeconds):
            try container.encode(deltaSeconds, forKey: .deltaSeconds)
        case let .timezoneChange(_, identifier):
            try container.encode(identifier, forKey: .identifier)
        case let .setRule(_, rule):
            try container.encode(rule, forKey: .rule)
        case .tapStart, .tapEnd, .killApp, .launchApp, .clearAll:
            break
        }
    }
}

// MARK: - Canonical encoding

/// Byte-stable JSON: sorted keys, no escaped slashes, no pretty-printing decisions
/// left to a default that could change under a toolchain bump.
///
/// The corpus digest hashes these bytes, so "canonical" here means *the same bytes
/// on every machine and every Swift release*, not merely valid JSON.
public enum CanonicalJSON {
    public static func encoder(pretty: Bool = false) -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = pretty
            ? [.sortedKeys, .withoutEscapingSlashes, .prettyPrinted]
            : [.sortedKeys, .withoutEscapingSlashes]
        return encoder
    }

    public static func data<T: Encodable>(_ value: T, pretty: Bool = false) throws -> Data {
        try encoder(pretty: pretty).encode(value)
    }

    public static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try JSONDecoder().decode(type, from: data)
    }
}
