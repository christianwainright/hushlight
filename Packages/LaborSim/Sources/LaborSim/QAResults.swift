import Foundation

// The shape of what a harness run leaves behind. Phase 5's report generator reads
// these files and nothing else, so every figure a report can quote has to be a field
// here — a metric that only exists inside a test assertion is a metric no report can
// rank, and decision 0021's whole routing law is a ranking over findings.

/// One T0 breach at one probe instant.
///
/// `knownRef` is what keeps the suite green while findings still flow: a violation
/// already triaged into the finding register carries its F-number here and does not
/// fail the test. An untriaged one has no ref and is a red run.
public struct T0Violation: Codable, Sendable, Equatable {
    public var check: String
    public var probe: Int64
    public var detail: String
    public var knownRef: String?

    public init(check: String, probe: Int64, detail: String, knownRef: String? = nil) {
        self.check = check
        self.probe = probe
        self.detail = detail
        self.knownRef = knownRef
    }
}

public struct T0Result: Codable, Sendable, Equatable {
    /// True when nothing untriaged breached. Registered violations are recorded
    /// below and still leave this true — that is the point of registering them.
    public var pass: Bool
    public var violations: [T0Violation]

    public init(pass: Bool, violations: [T0Violation]) {
        self.pass = pass
        self.violations = violations
    }
}

/// The T1 measurements for one scenario. Nothing here ever fails a test: these are
/// verdict *quality* figures, and a threshold breach is a finding for a human to
/// rank, not a defect the build can decide on its own (RUBRIC §1, T1 preamble).
public struct T1MetricSet: Codable, Sendable, Equatable {
    /// `t(first app met) − t(first truth met)`, in seconds. Negative means the app
    /// fired before truth did — informative, and not the same event as a false met.
    /// Nil when truth never fires, or when the app never did (see `suppressed`).
    public var onsetLagSeconds: Int64?
    public var truthFirstMetAt: Int64?
    public var appFirstMetAt: Int64?

    /// T1-01 (F-0018). Magnitude of an early fire — positive seconds, set whenever
    /// the app's first met tick beats truth's first `mustFire` by more than
    /// `earlyFireThresholdSeconds`, regardless of whether that early fire is
    /// defensible. Nil when the app did not fire early enough to name.
    public var earlyFireSeconds: Int64?
    /// Which kind of stretch the early fire (if any) landed in: `"gray"` when every
    /// early met tick sits in a gray zone or no zone at all — a judgement call, not
    /// a defect — or `"mustNotFire"` when at least one sits somewhere truth actively
    /// forbids, which is also what earns the "T1-01" flag. Nil/absent exactly when
    /// `earlyFireSeconds` is nil. A string, not an enum, so the report can render it
    /// without decoding one more type.
    public var earlyFireGraded: String?

    /// T1-02. Ticks are the raw count; seconds are those ticks weighted by the grid
    /// spacing they stand for, capped at one cadence step so an unprobed quiet
    /// stretch cannot be attributed to the single tick that opened it.
    public var falseMetTicks: Int
    public var falseMetSeconds: Int64
    /// Latched-only met ticks (`state == .met`, `rawState != .met`) inside a
    /// `mustNotFire` zone that landed within decision 0025's ten-minute release
    /// window of a genuine `mustFire` zone's end, and so were graded gray rather
    /// than counted in `falseMetTicks`/`falseMetSeconds`. Recorded so the exemption
    /// stays an auditable fact instead of a silent subtraction.
    public var latchGracedTicks: Int

    /// T1-03. True when some `mustFire` zone lasting >= 30 min contains no met tick.
    public var suppressed: Bool
    public var suppressedZoneSeconds: Int64?

    /// T1-04. `flapCount` is met -> not-met transitions while truth stays `mustFire`;
    /// `worstFlapsIn30Minutes` is the densest such half hour, which is what the
    /// threshold is actually written against. Both key on the **presented** verdict
    /// (decision 0025) — the state the reader actually saw.
    public var flapCount: Int
    /// `flapCount` split by destination state: flaps that landed on `.noVerdict`
    /// (the status disappearing — F-0009's residual, decision 0025's amendment) versus
    /// `.partial` (a dimension wobbling, what the original latch was built to hold).
    /// `flapToNoVerdict + flapToPartial == flapCount` always, by construction — this
    /// is what lets a report prove the pattern-level latch actually collapsed the 54.
    public var flapToNoVerdict: Int
    public var flapToPartial: Int
    /// The same count over the unlatched verdict. Not a threshold, a calibration:
    /// `rawFlaps - flapCount` is how much churn the ten-minute latch absorbed, and a
    /// wave that moved the verdict mathematics needs that number to stay visible.
    public var rawFlaps: Int
    public var worstFlapsIn30Minutes: Int
    public var bannerChurnPerHour: Double

    /// T1-06. `t(floors first satisfied) − t(truth met)` — how much of the delay is
    /// the evidence floors rather than the body.
    public var floorStarvationSeconds: Int64?

    /// T1-05, filled only for scenarios that have a same-physiology clean sibling.
    public var noiseDeltaOnsetSeconds: Int64?
    public var noiseDeltaFlaps: Int?
    public var noiseSuppressedButCleanDidNot: Bool?

    /// Which T1 thresholds this scenario breached, by check id.
    public var flags: [String]

    /// Stored rather than computed so the JSON carries it: a report that had to
    /// re-derive "is this flagged" from the thresholds would be a second copy of the
    /// thresholds, free to drift from this one.
    public var flagged: Bool

    public init(
        onsetLagSeconds: Int64? = nil,
        truthFirstMetAt: Int64? = nil,
        appFirstMetAt: Int64? = nil,
        earlyFireSeconds: Int64? = nil,
        earlyFireGraded: String? = nil,
        falseMetTicks: Int = 0,
        falseMetSeconds: Int64 = 0,
        latchGracedTicks: Int = 0,
        suppressed: Bool = false,
        suppressedZoneSeconds: Int64? = nil,
        flapCount: Int = 0,
        flapToNoVerdict: Int = 0,
        flapToPartial: Int = 0,
        rawFlaps: Int = 0,
        worstFlapsIn30Minutes: Int = 0,
        bannerChurnPerHour: Double = 0,
        floorStarvationSeconds: Int64? = nil,
        noiseDeltaOnsetSeconds: Int64? = nil,
        noiseDeltaFlaps: Int? = nil,
        noiseSuppressedButCleanDidNot: Bool? = nil,
        flags: [String] = []
    ) {
        self.onsetLagSeconds = onsetLagSeconds
        self.truthFirstMetAt = truthFirstMetAt
        self.appFirstMetAt = appFirstMetAt
        self.earlyFireSeconds = earlyFireSeconds
        self.earlyFireGraded = earlyFireGraded
        self.falseMetTicks = falseMetTicks
        self.falseMetSeconds = falseMetSeconds
        self.latchGracedTicks = latchGracedTicks
        self.suppressed = suppressed
        self.suppressedZoneSeconds = suppressedZoneSeconds
        self.flapCount = flapCount
        self.flapToNoVerdict = flapToNoVerdict
        self.flapToPartial = flapToPartial
        self.rawFlaps = rawFlaps
        self.worstFlapsIn30Minutes = worstFlapsIn30Minutes
        self.bannerChurnPerHour = bannerChurnPerHour
        self.floorStarvationSeconds = floorStarvationSeconds
        self.noiseDeltaOnsetSeconds = noiseDeltaOnsetSeconds
        self.noiseDeltaFlaps = noiseDeltaFlaps
        self.noiseSuppressedButCleanDidNot = noiseSuppressedButCleanDidNot
        self.flags = flags
        self.flagged = !flags.isEmpty
    }
}

/// What the body did, condensed. The report needs enough of the truth timeline to
/// say *why* a lag or a false met matters without re-deriving the scenario.
public struct TruthSummary: Codable, Sendable, Equatable {
    public var trueContractionCount: Int
    public var trueEpisodeCount: Int
    public var mustFireSeconds: Int64
    public var mustNotFireSeconds: Int64
    public var graySeconds: Int64
    public var firstMustFireAt: Int64?
    public var neverQualifies: Bool
    public var expectedSuspectCount: Int

    public init(
        trueContractionCount: Int,
        trueEpisodeCount: Int,
        mustFireSeconds: Int64,
        mustNotFireSeconds: Int64,
        graySeconds: Int64,
        firstMustFireAt: Int64?,
        neverQualifies: Bool,
        expectedSuspectCount: Int
    ) {
        self.trueContractionCount = trueContractionCount
        self.trueEpisodeCount = trueEpisodeCount
        self.mustFireSeconds = mustFireSeconds
        self.mustNotFireSeconds = mustNotFireSeconds
        self.graySeconds = graySeconds
        self.firstMustFireAt = firstMustFireAt
        self.neverQualifies = neverQualifies
        self.expectedSuspectCount = expectedSuspectCount
    }

    public init(_ manifest: ScenarioManifest) {
        let zones = manifest.truth.zones.filter { $0.rule == manifest.rule }
        func seconds(_ kind: TruthZoneKind) -> Int64 {
            zones.filter { $0.kind == kind }.reduce(0) { $0 + ($1.to - $1.from + 1) }
        }
        self.init(
            trueContractionCount: manifest.trueContractions.count,
            trueEpisodeCount: manifest.truth.episodesTrue.count,
            mustFireSeconds: seconds(.mustFire),
            mustNotFireSeconds: seconds(.mustNotFire),
            graySeconds: seconds(.gray),
            firstMustFireAt: zones.first(where: { $0.kind == .mustFire })?.from,
            neverQualifies: manifest.truth.events.contains {
                $0.type == .neverQualifies && ($0.rule == nil || $0.rule == manifest.rule)
            },
            expectedSuspectCount: manifest.truth.expectedSuspects.count
        )
    }
}

/// Whether this leg's final timeline matched the pure leg's. Only the store and model
/// legs carry it — the pure leg is the thing being agreed with.
public struct LegAgreement: Codable, Sendable, Equatable {
    public var comparedWith: String
    public var agrees: Bool
    public var detail: String?

    public init(comparedWith: String, agrees: Bool, detail: String? = nil) {
        self.comparedWith = comparedWith
        self.agrees = agrees
        self.detail = detail
    }
}

/// One scenario, one leg. Named `<scenario id>.<leg>.json` by `ResultsWriter`.
public struct ScenarioResult: Codable, Sendable, Equatable {
    public var schemaVersion: Int
    public var scenarioId: String
    public var leg: String
    public var archetype: String
    public var paramVariant: Int
    public var noiseProfile: String
    public var rule: String
    public var seed: String
    public var probeCount: Int
    public var cadenceSeconds: Int
    public var truth: TruthSummary
    public var t0: T0Result
    public var t1: T1MetricSet?
    public var legAgreement: LegAgreement?

    /// Model leg only. How many of this scenario's `undoDelete` corrections the app's
    /// one-step undo could not have performed, because a later edit had already
    /// replaced `undoAction`. The harness routes those through the store so the leg
    /// stays comparable; the count is what says how often the correction model the
    /// corpus assumes is wider than the one the app offers.
    public var undoOutOfReach: Int?

    public init(
        schemaVersion: Int = LaborSimVersion.schema,
        scenarioId: String,
        leg: String,
        archetype: String,
        paramVariant: Int,
        noiseProfile: String,
        rule: String,
        seed: String,
        probeCount: Int,
        cadenceSeconds: Int,
        truth: TruthSummary,
        t0: T0Result,
        t1: T1MetricSet? = nil,
        legAgreement: LegAgreement? = nil,
        undoOutOfReach: Int? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.scenarioId = scenarioId
        self.leg = leg
        self.archetype = archetype
        self.paramVariant = paramVariant
        self.noiseProfile = noiseProfile
        self.rule = rule
        self.seed = seed
        self.probeCount = probeCount
        self.cadenceSeconds = cadenceSeconds
        self.truth = truth
        self.t0 = t0
        self.t1 = t1
        self.legAgreement = legAgreement
        self.undoOutOfReach = undoOutOfReach
    }
}

/// `run.json`: the header every results directory needs to be interpretable later.
///
/// Reports are only row-comparable within one generator version and one corpus
/// digest (decision 0021 §5), so a results directory that cannot state both is a
/// directory nobody can compare against anything.
public struct RunMetadata: Codable, Sendable, Equatable {
    public var schemaVersion: Int
    public var generatorVersion: String
    public var corpusDigest: String
    public var corpusSize: Int
    /// From `GIT_REF` when the caller sets it. Omitted rather than guessed: this
    /// package never shells out, and a wrong ref is worse than an absent one.
    ///
    /// In practice it is always absent under `xcodebuild test`, because the simulator
    /// hands the test process its own environment (see `ResultsWriter.pointerFileName`).
    /// The report generator runs on the host, where the ref is one `git rev-parse`
    /// away, so it stamps this field rather than the harness guessing at it.
    public var gitRef: String?
    /// The one place a wall clock is allowed. The *library* never reads it — a
    /// corpus that changed with the date would be unreproducible — but a run has to
    /// be able to say when it happened.
    public var startedAt: String?
    public var legs: [String]
    public var cadenceSeconds: Int
    public var coarseCadenceSeconds: Int
    public var coarseCadenceAboveSeconds: Int64

    public init(
        schemaVersion: Int = LaborSimVersion.schema,
        generatorVersion: String = LaborSimVersion.generator,
        corpusDigest: String,
        corpusSize: Int,
        gitRef: String? = nil,
        startedAt: String? = nil,
        legs: [String],
        cadenceSeconds: Int,
        coarseCadenceSeconds: Int,
        coarseCadenceAboveSeconds: Int64
    ) {
        self.schemaVersion = schemaVersion
        self.generatorVersion = generatorVersion
        self.corpusDigest = corpusDigest
        self.corpusSize = corpusSize
        self.gitRef = gitRef
        self.startedAt = startedAt
        self.legs = legs
        self.cadenceSeconds = cadenceSeconds
        self.coarseCadenceSeconds = coarseCadenceSeconds
        self.coarseCadenceAboveSeconds = coarseCadenceAboveSeconds
    }
}

extension ResultsWriter {
    /// `GIT_REF` if the caller exported one. Optional on purpose — see `RunMetadata`.
    public static var gitRef: String? {
        ProcessInfo.processInfo.environment["GIT_REF"].flatMap { $0.isEmpty ? nil : $0 }
    }

    /// The run header, written beside `results/` rather than inside it, so a report
    /// generator can glob `results/*.json` without having to exclude one file by name.
    @discardableResult
    public static func writeRun(_ metadata: RunMetadata) -> Bool {
        guard let root = outputRoot else { return false }
        do {
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            let data = try CanonicalJSON.data(metadata, pretty: true)
            try data.write(to: root.appendingPathComponent("run.json"))
            return true
        } catch {
            return false
        }
    }
}
