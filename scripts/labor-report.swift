#!/usr/bin/env swift
// Labor QA report generator (decision 0021, RUBRIC.md §3, SP-193 Phase 5).
//
// Reads a completed harness run directory and writes `report.md` beside it.
// Foundation-only and standalone on purpose: it must never `import LaborSim` or
// `LaborKit`, because the report has to stay readable from a plain checkout without
// building the app, and because a report generator that shares types with the thing
// it is grading could silently agree with a schema bug instead of catching it. Every
// struct below is a hand-copied mirror of LaborSim/Sources/LaborSim/QAResults.swift
// and ManifestSchema.swift, not an import of them.
//
// Every field is Optional. That is not caution for its own sake: a run directory
// from an older or newer generator version must decode here without throwing —
// missing fields become nil, and a schema addition upstream is just an unread key.
// Every section below degrades to a one-line "not present" note rather than a
// crash when its inputs are partial or absent, because Phase 5 runs against
// real, in-progress harness output, not fixtures.
//
// Usage: swift scripts/labor-report.swift <runDir>

import Foundation

// MARK: - JSON mirrors: results/<scenario>.<leg>.json (LaborSim.ScenarioResult)

struct T0Violation: Decodable {
    var check: String?
    var probe: Int64?
    var detail: String?
    var knownRef: String?
}

struct T0Result: Decodable {
    var pass: Bool?
    var violations: [T0Violation]?
}

struct T1MetricSet: Decodable {
    var onsetLagSeconds: Int64?
    var truthFirstMetAt: Int64?
    var appFirstMetAt: Int64?
    var falseMetTicks: Int?
    var falseMetSeconds: Int64?
    var suppressed: Bool?
    var suppressedZoneSeconds: Int64?
    var flapCount: Int?
    var rawFlaps: Int?
    var worstFlapsIn30Minutes: Int?
    var bannerChurnPerHour: Double?
    var floorStarvationSeconds: Int64?
    var noiseDeltaOnsetSeconds: Int64?
    var noiseDeltaFlaps: Int?
    var noiseSuppressedButCleanDidNot: Bool?
    var flags: [String]?
    var flagged: Bool?

    // MARK: Fix wave D additions (SP-194)

    /// T1-01 (F-0018), the early-fire half: positive seconds when the app's first met
    /// tick beat truth's first `mustFire` by more than the threshold.
    var earlyFireSeconds: Int64?
    /// `"gray"` (a judgement call) or `"mustNotFire"` (also earns the T1-01 flag).
    var earlyFireGraded: String?
    /// Latched-only met ticks inside a `mustNotFire` zone landing within decision
    /// 0025's ten-minute release window of a genuine `mustFire` zone's end — exempted
    /// from `falseMetTicks`, recorded here so the exemption is an auditable fact.
    var latchGracedTicks: Int?
    /// `flapCount` split by destination state: `.noVerdict` is the status
    /// disappearing (F-0009's residual), `.partial` is a dimension wobbling (what the
    /// original latch was built to hold). Sum equals `flapCount` in the source.
    var flapToNoVerdict: Int?
    var flapToPartial: Int?

    /// **Not yet emitted by `QAResults.ScenarioResult` as of this wave.** The clause
    /// (`"count"`, `"sustained"`, `"frequency"`, `"duration"`) of the `mustNotFire`
    /// `TruthZone` that condemned this scenario-leg's *first* false-met tick.
    /// `buildFalseMetClauseSection` below states this same requirement again at the
    /// point it degrades — decoding it here costs nothing while the key is absent and
    /// starts rendering the moment a result row carries it.
    var falseMetClause: String?
}

// Decoded for fidelity with ScenarioResult's shape; this report does not currently
// surface truth-level figures, only the pass/fail and metric verdicts judged against
// them.
struct TruthSummary: Decodable {
    var trueContractionCount: Int?
    var trueEpisodeCount: Int?
    var mustFireSeconds: Int64?
    var mustNotFireSeconds: Int64?
    var graySeconds: Int64?
    var firstMustFireAt: Int64?
    var neverQualifies: Bool?
    var expectedSuspectCount: Int?
}

struct LegAgreement: Decodable {
    var comparedWith: String?
    var agrees: Bool?
    var detail: String?
}

struct ScenarioResult: Decodable {
    var schemaVersion: Int?
    var scenarioId: String?
    var leg: String?
    var archetype: String?
    var paramVariant: Int?
    var noiseProfile: String?
    var rule: String?
    var seed: String?
    var probeCount: Int?
    var cadenceSeconds: Int?
    var truth: TruthSummary?
    var t0: T0Result?
    var t1: T1MetricSet?
    var legAgreement: LegAgreement?
    var undoOutOfReach: Int?

    /// **Not yet emitted by `QAResults.ScenarioResult` as of this wave.** Mirrors
    /// `ScenarioManifest.expectedDetection` — RUBRIC §4's pre-registered-weakness
    /// annotation. `buildExpectedDetectionSection` states the exact field/type needed
    /// and where to thread it from when this decodes to nil across every row.
    var expectedDetection: [String]?
}

// MARK: - JSON mirror: run.json (LaborSim.RunMetadata, engine-written)

struct RunMetadata: Decodable {
    var schemaVersion: Int?
    var generatorVersion: String?
    var corpusDigest: String?
    var corpusSize: Int?
    var gitRef: String?
    var startedAt: String?
    var legs: [String]?
    var cadenceSeconds: Int?
    var coarseCadenceSeconds: Int?
    var coarseCadenceAboveSeconds: Int64?
}

// MARK: - JSON mirror: run-meta.json (host-stamped, not defined by any Swift source)
//
// No package in this repo owns this file's shape, unlike run.json/ScenarioResult —
// it is written by whatever drove the run, on the host, before or after the engine
// pass. Each field decodes independently (rather than via one synthesized
// Decodable) so a single unexpected type — `stages` turning out to be objects
// instead of strings, say — costs that one field, not the whole file.
struct RunMeta: Decodable {
    var gitRef: String?
    var startedAt: String?
    var corpusDigest: String?
    var corpusSize: Int?
    var deep: Bool?
    var stages: [String]?

    private enum CodingKeys: String, CodingKey {
        case gitRef, startedAt, corpusDigest, corpusSize, deep, stages
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        gitRef = try? container.decode(String.self, forKey: .gitRef)
        startedAt = try? container.decode(String.self, forKey: .startedAt)
        corpusDigest = try? container.decode(String.self, forKey: .corpusDigest)
        corpusSize = try? container.decode(Int.self, forKey: .corpusSize)
        deep = try? container.decode(Bool.self, forKey: .deep)
        stages = try? container.decode([String].self, forKey: .stages)
    }
}

// MARK: - JSON mirror: docs/qa/corpus/manifest.json
//
// Read from the repo checkout, not from the run directory -- no LaborSim source
// writes this file into a run, and the harness's own digest handover already runs
// host-side through CorpusStabilityTests.pinnedDigest (see labor-sim.sh). This mirror
// exists for one line in the header: whether the corpus manifest's *version* means
// this run's rows are comparable to a 1.0.0 run's.

struct CorpusManifest: Decodable {
    var corpusVersion: String?
    var contentHash: String?
}

func loadCorpusManifest(repoRoot: URL) -> CorpusManifest? {
    let url = repoRoot.appendingPathComponent("docs/qa/corpus/manifest.json")
    guard let data = try? Data(contentsOf: url) else { return nil }
    return try? JSONDecoder().decode(CorpusManifest.self, from: data)
}

// MARK: - Galleries

/// The sweep the gallery links point at, named once.
///
/// `shots/` now holds three sweeps — `dark-axl` (the primary, DESIGN-SPEC §8), plus the
/// sampled `dark-ax5` and `light-m`. This constant used to be a string literal repeated
/// at two call sites in the Worst-12 section, and `light-m` was written by
/// `labor-sim.sh` and read by nothing at all: a gallery nobody could reach from the
/// report. A third hard-coded directory would have made that two.
let primaryShotsDirectory = "shots/dark-axl"

/// Every `shots/<sweep>/` directory that actually has PNGs in it, with its count.
/// Enumerated rather than listed, so a sweep added to `labor-sim.sh` appears here
/// without anyone remembering to come back and add it.
func discoveredGalleries(runDirURL: URL) -> [(name: String, count: Int)] {
    let shotsRoot = runDirURL.appendingPathComponent("shots", isDirectory: true)
    let fm = FileManager.default
    guard let names = try? fm.contentsOfDirectory(atPath: shotsRoot.path) else { return [] }
    return names.sorted().compactMap { name in
        let directory = shotsRoot.appendingPathComponent(name, isDirectory: true)
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: directory.path, isDirectory: &isDir), isDir.boolValue else { return nil }
        let pngs = ((try? fm.contentsOfDirectory(atPath: directory.path)) ?? [])
            .filter { $0.hasSuffix(".png") }
        return pngs.isEmpty ? nil : (name, pngs.count)
    }
}

// MARK: - JSON mirror: snapshots/index.json

struct SnapshotIndexEntry: Decodable {
    var scenario: String?
    /// The short file stem the exporter names its artefacts with. `shot` is the PNG
    /// basename the screenshot stage writes under shots/<appearance>/, stated by the
    /// exporter rather than reconstructed here — the two would drift the first time
    /// either side changed its naming.
    var label: String?
    var moment: String?
    var file: String?
    var shot: String?
    var expectedFacts: [String]?
    var note: String?
}

struct SnapshotIndex: Decodable {
    var version: String?
    var entries: [SnapshotIndexEntry]?

    private enum CodingKeys: String, CodingKey {
        case version, entries
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // `version` isn't pinned to a type by any source in this repo either --
        // tolerate a bare number as readily as a string.
        if let stringVersion = try? container.decode(String.self, forKey: .version) {
            version = stringVersion
        } else if let intVersion = try? container.decode(Int.self, forKey: .version) {
            version = String(intVersion)
        } else {
            version = nil
        }
        entries = try? container.decode([SnapshotIndexEntry].self, forKey: .entries)
    }
}

// MARK: - Corpus identifiers (ManifestSchema.ArchetypeID / NoiseProfileID rawValues)
//
// Copied rather than imported -- see the file header. Order matters: it fixes the
// T0 grid's row/column order, and CaseIterable's order is declaration order, so
// these lists must track ManifestSchema.swift by hand if a case is ever added.

let archetypeOrder: [String] = [
    "classicNullipara", "classicMultipara", "precipitous", "prodromalFizzle",
    "prodromalNightly", "braxtonHicks", "irregularProgressing", "backLaborCoupling",
    "pretermEarly", "inductionRamp", "multiDayLatent", "sromThenOnset", "boundaryBattery",
]

let noiseProfileOrder: [String] = [
    "clean", "partnerDiligent", "typicalSolo", "exhaustedSolo", "chaotic", "clockHostile",
]

// MARK: - Small formatting utilities

func writeStderr(_ message: String) {
    FileHandle.standardError.write(Data(message.utf8))
}

// Nearest-rank percentile on a sorted ascending array (rank = ceil(p/100 * n),
// clamped into [1, n]). Chosen over linear interpolation so report numbers only
// move when the underlying sample set changes -- never because of an
// interpolation-method edit -- which matters for a report meant to be diffed
// run over run.
func nearestRankInt64(_ sorted: [Int64], _ percentile: Double) -> Int64? {
    guard !sorted.isEmpty else { return nil }
    let rank = Int((percentile / 100.0 * Double(sorted.count)).rounded(.up))
    let clamped = max(1, min(sorted.count, rank))
    return sorted[clamped - 1]
}

func nearestRankDouble(_ sorted: [Double], _ percentile: Double) -> Double? {
    guard !sorted.isEmpty else { return nil }
    let rank = Int((percentile / 100.0 * Double(sorted.count)).rounded(.up))
    let clamped = max(1, min(sorted.count, rank))
    return sorted[clamped - 1]
}

func nearestRankInt(_ sorted: [Int], _ percentile: Double) -> Int? {
    guard !sorted.isEmpty else { return nil }
    let rank = Int((percentile / 100.0 * Double(sorted.count)).rounded(.up))
    let clamped = max(1, min(sorted.count, rank))
    return sorted[clamped - 1]
}

func formatMinutes(_ seconds: Int64) -> String {
    String(format: "%.1f", Double(seconds) / 60.0)
}

// Joins a list for display, capping it so one bad archetype/noise cell or one
// noisy check id can't blow up the report's length; the overflow count still says
// how much was hidden.
func capped(_ items: [String], limit: Int = 10) -> String {
    guard items.count > limit else { return items.joined(separator: ", ") }
    let shown = items.prefix(limit).joined(separator: ", ")
    return "\(shown), +\(items.count - limit) more"
}

func markdownTable(headers: [String], rows: [[String]]) -> String {
    guard !rows.isEmpty else { return "_(no rows)_\n" }
    var lines: [String] = []
    lines.append("| " + headers.joined(separator: " | ") + " |")
    lines.append("|" + headers.map { _ in "---" }.joined(separator: "|") + "|")
    for row in rows {
        lines.append("| " + row.joined(separator: " | ") + " |")
    }
    return lines.joined(separator: "\n") + "\n"
}

// MARK: - T0 grouping
//
// RUBRIC §2's T0 preamble reads "any failure on any scenario is a red run" -- so a
// scenario's pass/fail for the grid is the AND across whichever legs (pure/store/
// model) this run produced for it, not a per-leg row. A failure on the store leg
// still makes the scenario a failure even if the pure leg was clean.

struct ScenarioT0Status {
    var archetype: String
    var noiseProfile: String
    var allPass: Bool
    var failingLegs: [String]
}

func groupScenariosForT0(_ results: [ScenarioResult]) -> [String: ScenarioT0Status] {
    var byId: [String: ScenarioT0Status] = [:]
    for row in results {
        guard let id = row.scenarioId else { continue }
        let archetype = row.archetype ?? "unknown"
        let noise = row.noiseProfile ?? "unknown"
        let leg = row.leg ?? "unknown"
        let passed = row.t0?.pass == true
        if var existing = byId[id] {
            if !passed {
                existing.allPass = false
                existing.failingLegs.append(leg)
            }
            byId[id] = existing
        } else {
            byId[id] = ScenarioT0Status(
                archetype: archetype, noiseProfile: noise,
                allPass: passed, failingLegs: passed ? [] : [leg]
            )
        }
    }
    return byId
}

// MARK: - Worst-12 classification
//
// The ranking law (decision 0021 §2, RUBRIC §3): a verdict that fires late is worse
// than one that fires early. Suppression outranks lag, lag outranks false-met,
// false-met outranks flap, and anything else flagged trails all four. A row is
// filed under the HIGHEST tier it qualifies for and no other, so one scenario never
// occupies two gallery slots.

enum WorstTier: Int {
    case suppression = 1
    case lagBreach = 2
    case falseMet = 3
    case flap = 4
    case other = 5

    var severityLabel: String {
        switch self {
        case .suppression: return "S4"
        case .lagBreach: return "S3"
        case .falseMet: return "S2"
        case .flap: return "S2"
        case .other: return "S1"
        }
    }
}

struct WorstCandidate {
    var tier: WorstTier
    var magnitude: Double
    var scenarioId: String
    var leg: String
    var archetype: String
    var noiseProfile: String
    var metric: String
    var flags: [String]
}

func classify(_ row: ScenarioResult) -> WorstCandidate? {
    guard let t1 = row.t1 else { return nil }
    let scenarioId = row.scenarioId ?? "unknown"
    let leg = row.leg ?? "unknown"
    let archetype = row.archetype ?? "unknown"
    let noise = row.noiseProfile ?? "unknown"
    let flags = t1.flags ?? []

    if t1.suppressed == true {
        let zoneSeconds = t1.suppressedZoneSeconds ?? 0
        let metric = "suppressed \(formatMinutes(zoneSeconds)) min zone"
        return WorstCandidate(
            tier: .suppression, magnitude: Double(zoneSeconds), scenarioId: scenarioId,
            leg: leg, archetype: archetype, noiseProfile: noise, metric: metric, flags: flags
        )
    }

    if let lag = t1.onsetLagSeconds {
        // T1-01: > 10 min under clean, > 20 min under any single-noise profile.
        let thresholdSeconds: Int64 = noise == "clean" ? 600 : 1200
        if lag > thresholdSeconds {
            let metric = "onset lag \(formatMinutes(lag)) min"
            return WorstCandidate(
                tier: .lagBreach, magnitude: Double(lag), scenarioId: scenarioId,
                leg: leg, archetype: archetype, noiseProfile: noise, metric: metric, flags: flags
            )
        }
    }

    if (t1.falseMetTicks ?? 0) > 0 {
        let seconds = t1.falseMetSeconds ?? 0
        let metric = "false-met \(seconds)s / \(t1.falseMetTicks ?? 0) ticks"
        return WorstCandidate(
            tier: .falseMet, magnitude: Double(seconds), scenarioId: scenarioId,
            leg: leg, archetype: archetype, noiseProfile: noise, metric: metric, flags: flags
        )
    }

    let worstFlaps = t1.worstFlapsIn30Minutes ?? 0
    let churn = t1.bannerChurnPerHour ?? 0
    if worstFlaps > 2 || churn > 6 {
        let metric = "\(worstFlaps) flaps/30min, \(String(format: "%.1f", churn)) churn/h"
        // Flap count dominates the tie-break; churn only separates equal flap counts.
        let magnitude = Double(worstFlaps) * 1000.0 + churn
        return WorstCandidate(
            tier: .flap, magnitude: magnitude, scenarioId: scenarioId,
            leg: leg, archetype: archetype, noiseProfile: noise, metric: metric, flags: flags
        )
    }

    if !flags.isEmpty {
        let metric = flags.joined(separator: ", ")
        return WorstCandidate(
            tier: .other, magnitude: Double(flags.count), scenarioId: scenarioId,
            leg: leg, archetype: archetype, noiseProfile: noise, metric: metric, flags: flags
        )
    }

    return nil
}

func rankedCandidates(_ results: [ScenarioResult]) -> [WorstCandidate] {
    var candidates: [WorstCandidate] = []
    for row in results {
        if let candidate = classify(row) {
            candidates.append(candidate)
        }
    }
    candidates.sort { a, b in
        if a.tier.rawValue != b.tier.rawValue { return a.tier.rawValue < b.tier.rawValue }
        if a.magnitude != b.magnitude { return a.magnitude > b.magnitude }
        return a.scenarioId < b.scenarioId
    }
    return candidates
}

// MARK: - FINDINGS.md status-table parsing

struct FindingRow {
    var f: String
    var severity: String
    var status: String
    var summary: String
}

// Reads the `## Status table` markdown table in docs/qa/FINDINGS.md. Returns nil
// when the file itself can't be read (not present); returns an empty array when the
// file is readable but the table is empty or missing its heading -- those are
// different kinds of "nothing to report" and the caller says so distinctly.
func parseFindingsTable(at url: URL) -> [FindingRow]? {
    guard let content = try? String(contentsOf: url, encoding: .utf8) else { return nil }
    let lines = content.components(separatedBy: .newlines)
    guard let headingIndex = lines.firstIndex(where: { $0.contains("## Status table") }) else {
        return []
    }

    var rows: [FindingRow] = []
    var index = headingIndex + 1
    var sawHeaderRow = false
    while index < lines.count {
        let line = lines[index].trimmingCharacters(in: .whitespaces)
        index += 1

        if line.isEmpty {
            if sawHeaderRow { break }
            continue
        }
        guard line.hasPrefix("|") else {
            if sawHeaderRow { break }
            continue
        }

        var parts = line.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
        if parts.first == "" { parts.removeFirst() }
        if parts.last == "" { parts.removeLast() }
        guard parts.count >= 4 else { continue }

        if !sawHeaderRow {
            // The `| F | Sev | Status | Summary |` label row itself.
            sawHeaderRow = true
            continue
        }

        let isSeparator = parts.allSatisfy { part in part.allSatisfy { char in char == "-" } }
        if isSeparator { continue }

        rows.append(FindingRow(f: parts[0], severity: parts[1], status: parts[2], summary: parts[3]))
    }
    return rows
}

// MARK: - Kill-matrix log parsing (scripts/labor-mutate.sh output format)
//
// Lines look like `  KILLED   gapWiden             everyScenarioAgrees...(ref:)` or
// `  SURVIVED windowTwoHours`. Everything else in these logs -- the header row, the
// dashed separator, the closing "MUTATION MATRIX CLEAN"/"MUTANTS SURVIVED" line --
// is noise this pattern simply never matches, so no explicit exclusion list is
// needed.

struct MutantRow {
    var source: String
    var mutant: String
    var verdict: String
    var killedBy: String
}

func parseKillLog(at path: String, source: String) -> [MutantRow] {
    guard let content = try? String(contentsOf: URL(fileURLWithPath: path), encoding: .utf8) else {
        return []
    }
    guard let regex = try? NSRegularExpression(
        pattern: #"^\s*(KILLED|SURVIVED|TIMEOUT|ERROR)\s+(\S+)\s*(.*)$"#
    ) else {
        return []
    }

    var rows: [MutantRow] = []
    for line in content.components(separatedBy: .newlines) {
        let fullRange = NSRange(line.startIndex..<line.endIndex, in: line)
        guard let match = regex.firstMatch(in: line, range: fullRange) else { continue }
        guard let verdictRange = Range(match.range(at: 1), in: line),
              let nameRange = Range(match.range(at: 2), in: line) else { continue }

        let verdict = String(line[verdictRange])
        let name = String(line[nameRange])
        var detail = ""
        if let detailRange = Range(match.range(at: 3), in: line) {
            detail = String(line[detailRange]).trimmingCharacters(in: .whitespaces)
        }
        rows.append(MutantRow(source: source, mutant: name, verdict: verdict, killedBy: detail.isEmpty ? "—" : detail))
    }
    return rows
}

// MARK: - Wall-clock duration

// Best-effort: startedAt (from run.json or run-meta.json) to the newest file
// modification time under the run dir, as a proxy for "finished at". Nil whenever
// startedAt is absent or unparseable, or nothing in the tree postdates it -- "if
// derivable" in the spec means this is allowed to come up empty.
func deriveWallClockDuration(runDirURL: URL, startedAt: String) -> String? {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    var startDate = formatter.date(from: startedAt)
    if startDate == nil {
        formatter.formatOptions = [.withInternetDateTime]
        startDate = formatter.date(from: startedAt)
    }
    guard let start = startDate else { return nil }

    let fm = FileManager.default
    guard let enumerator = fm.enumerator(
        at: runDirURL, includingPropertiesForKeys: [.contentModificationDateKey]
    ) else {
        return nil
    }

    var latest: Date?
    for case let fileURL as URL in enumerator {
        guard let values = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]),
              let modified = values.contentModificationDate else { continue }
        if latest == nil || modified > latest! {
            latest = modified
        }
    }
    guard let end = latest, end > start else { return nil }

    let intervalSeconds = Int(end.timeIntervalSince(start))
    let hours = intervalSeconds / 3600
    let minutes = (intervalSeconds % 3600) / 60
    return "\(hours)h \(minutes)m (started \(startedAt), latest artifact \(formatter.string(from: end)))"
}

// MARK: - Section 1: header / run summary

func buildHeaderSection(
    runDirURL: URL, results: [ScenarioResult], runMetadata: RunMetadata?,
    runMeta: RunMeta?, parseFailures: Int, corpusManifest: CorpusManifest?
) -> String {
    var out = "# Labor QA report — \(runDirURL.lastPathComponent)\n\n"
    out += "## Run summary\n\n"

    let gitRef = runMetadata?.gitRef ?? runMeta?.gitRef ?? "unknown"
    let startedAt = runMetadata?.startedAt ?? runMeta?.startedAt ?? "unknown"
    let generatorVersion = runMetadata?.generatorVersion ?? "unknown"
    let corpusDigest = runMetadata?.corpusDigest ?? runMeta?.corpusDigest ?? "unknown"
    let corpusSize = runMetadata?.corpusSize ?? runMeta?.corpusSize
    let deepMode = runMeta?.deep

    let scenarioIds = Set(results.compactMap { $0.scenarioId })
    var legCounts: [String: Int] = [:]
    var totalProbes = 0
    for row in results {
        let leg = row.leg ?? "unknown"
        legCounts[leg, default: 0] += 1
        totalProbes += row.probeCount ?? 0
    }

    out += "- Run dir: `\(runDirURL.lastPathComponent)`\n"
    out += "- Git ref: `\(gitRef)`\n"
    out += "- Started at: \(startedAt)\n"
    out += "- Corpus: generator `\(generatorVersion)`, digest `\(corpusDigest)`"
    if let size = corpusSize {
        out += ", size \(size)"
    }
    out += "\n"

    // Corpus comparability (item 7 / this wave's Job 3): the manifest is read from
    // the checkout, not the run, so a run executed before the manifest last moved
    // shows up as a digest mismatch below rather than a false "comparable" claim.
    if let manifest = corpusManifest, let manifestVersion = manifest.corpusVersion {
        let digestMatches = manifest.contentHash != nil && manifest.contentHash == corpusDigest
        out += "- Corpus manifest: `docs/qa/corpus/manifest.json` states version `\(manifestVersion)`"
        out += digestMatches
            ? " (digest matches this run).\n"
            : " (digest does **not** match this run's `\(corpusDigest)` — the manifest "
                + "has moved since this run; treat the version above as unconfirmed for it).\n"
        if digestMatches, !manifestVersion.hasPrefix("1.") {
            out += "- **Not comparable to corpus 1.0.0 runs** — this run's rows are corpus "
                + "`\(manifestVersion)`; do not diff them against a 1.0.0-digest report "
                + "(decision-record convention, RUBRIC's semver note in the manifest itself).\n"
        }
    } else {
        out += "- Corpus manifest: not present or unreadable at `docs/qa/corpus/manifest.json`.\n"
    }

    out += "- Scenarios: \(scenarioIds.count) distinct ids, \(results.count) scenario × leg rows\n"
    if legCounts.isEmpty {
        out += "- Legs: none\n"
    } else {
        let legSummary = legCounts.keys.sorted().map { "\($0): \(legCounts[$0]!)" }.joined(separator: ", ")
        out += "- Legs: \(legSummary)\n"
    }
    out += "- Total probes evaluated (sum of probeCount across all rows): \(totalProbes)\n"

    if let duration = deriveWallClockDuration(runDirURL: runDirURL, startedAt: startedAt) {
        out += "- Wall-clock duration: \(duration)\n"
    } else {
        out += "- Wall-clock duration: not derivable\n"
    }

    if let deep = deepMode {
        out += "- Deep mode: \(deep)\n"
    } else {
        out += "- Deep mode: unknown\n"
    }

    if let stages = runMeta?.stages, !stages.isEmpty {
        out += "- Stages recorded: \(stages.count)\n"
    }

    if parseFailures > 0 {
        out += "- \(parseFailures) results file(s) failed to decode and were skipped.\n"
    }

    out += "\n"
    return out
}

// MARK: - Section 2: T0 grid

func buildT0Section(_ results: [ScenarioResult]) -> String {
    var out = "## T0 — invariant grid\n\n"
    let byId = groupScenariosForT0(results)
    if byId.isEmpty {
        out += "not run / not present — no results/*.json rows decoded.\n\n"
        return out
    }

    var header = ["Archetype"]
    header.append(contentsOf: noiseProfileOrder)
    var rows: [[String]] = []
    var failingByCell: [String: [String]] = [:]

    for archetype in archetypeOrder {
        var row: [String] = [archetype]
        for noise in noiseProfileOrder {
            let scenarios = byId.filter { $0.value.archetype == archetype && $0.value.noiseProfile == noise }
            let total = scenarios.count
            if total == 0 {
                row.append("–")
                continue
            }
            let passing = scenarios.filter { $0.value.allPass }.count
            row.append("\(passing)/\(total)")
            if passing < total {
                let failingEntries = scenarios.filter { !$0.value.allPass }
                let failingIds = failingEntries.map { entry -> String in
                    let legs = entry.value.failingLegs.joined(separator: ",")
                    return "\(entry.key) (\(legs))"
                }.sorted()
                failingByCell["\(archetype)|\(noise)"] = failingIds
            }
        }
        rows.append(row)
    }
    out += markdownTable(headers: header, rows: rows)
    out += "\n"

    if !failingByCell.isEmpty {
        out += "### T0 failures by cell\n\n"
        for archetype in archetypeOrder {
            for noise in noiseProfileOrder {
                let key = "\(archetype)|\(noise)"
                guard let ids = failingByCell[key], !ids.isEmpty else { continue }
                out += "- **\(archetype) / \(noise)**: \(capped(ids))\n"
            }
        }
        out += "\n"
    }

    struct CheckStats {
        var unregistered = 0
        var registered = 0
        var scenarios = Set<String>()
        var registeredRefs = Set<String>()
    }
    var checkStats: [String: CheckStats] = [:]
    for row in results {
        guard let id = row.scenarioId, let violations = row.t0?.violations else { continue }
        for violation in violations {
            let check = violation.check ?? "unknown"
            var stats = checkStats[check] ?? CheckStats()
            stats.scenarios.insert(id)
            if let ref = violation.knownRef, !ref.isEmpty {
                stats.registered += 1
                stats.registeredRefs.insert(ref)
            } else {
                stats.unregistered += 1
            }
            checkStats[check] = stats
        }
    }

    out += "### T0 check breakdown\n\n"
    if checkStats.isEmpty {
        out += "no T0 violations recorded in this run.\n\n"
    } else {
        var checkRows: [[String]] = []
        for check in checkStats.keys.sorted() {
            let stats = checkStats[check]!
            checkRows.append([check, "\(stats.unregistered)", "\(stats.registered)", "\(stats.scenarios.count)"])
        }
        out += markdownTable(
            headers: ["Check", "Unregistered", "Registered", "Distinct scenarios"], rows: checkRows
        )
        out += "\n"

        out += "### Registered violations by check\n\n"
        var registeredRows: [[String]] = []
        for check in checkStats.keys.sorted() {
            let stats = checkStats[check]!
            guard stats.registered > 0 else { continue }
            let refs = capped(Array(stats.registeredRefs).sorted())
            registeredRows.append([check, "\(stats.registered)", refs])
        }
        if registeredRows.isEmpty {
            out += "no registered (known-ref) violations in this run.\n\n"
        } else {
            out += markdownTable(headers: ["Check", "Registered count", "Known refs"], rows: registeredRows)
            out += "\n"
        }
    }

    return out
}

// MARK: - Section 3: T1 tables

func buildOnsetLagSection(_ results: [ScenarioResult]) -> String {
    var out = "### Onset lag by archetype\n\n"
    var byArchetype: [String: [Int64]] = [:]
    for row in results {
        guard let lag = row.t1?.onsetLagSeconds else { continue }
        let archetype = row.archetype ?? "unknown"
        byArchetype[archetype, default: []].append(lag)
    }
    if byArchetype.isEmpty {
        out += "no scenario recorded a non-nil onset lag (truth never fired, or the app never did).\n\n"
        return out
    }

    var rows: [[String]] = []
    for archetype in archetypeOrder {
        guard let values = byArchetype[archetype], !values.isEmpty else { continue }
        let sorted = values.sorted()
        let p50 = nearestRankInt64(sorted, 50) ?? 0
        let p90 = nearestRankInt64(sorted, 90) ?? 0
        let p99 = nearestRankInt64(sorted, 99) ?? 0
        let maxValue = sorted.last ?? 0
        rows.append([
            archetype, "\(sorted.count)",
            formatMinutes(p50), formatMinutes(p90), formatMinutes(p99), formatMinutes(maxValue),
        ])
    }
    out += markdownTable(
        headers: ["Archetype", "n", "p50 (min)", "p90 (min)", "p99 (min)", "max (min)"], rows: rows
    )
    out += "\n"
    return out
}

func buildFalseMetSection(_ results: [ScenarioResult]) -> String {
    var out = "### False-met scenarios\n\n"
    let flagged = results.filter { ($0.t1?.falseMetTicks ?? 0) > 0 }
    if flagged.isEmpty {
        out += "no scenario recorded a false-met tick.\n\n"
        return out
    }

    let sortedRows = flagged.sorted { a, b in
        (a.t1?.falseMetSeconds ?? 0) > (b.t1?.falseMetSeconds ?? 0)
    }
    var rows: [[String]] = []
    for row in sortedRows.prefix(20) {
        rows.append([
            row.scenarioId ?? "unknown", row.leg ?? "unknown",
            row.archetype ?? "unknown", row.noiseProfile ?? "unknown",
            "\(row.t1?.falseMetTicks ?? 0)", "\(row.t1?.falseMetSeconds ?? 0)",
        ])
    }
    out += markdownTable(headers: ["Scenario", "Leg", "Archetype", "Noise", "Ticks", "Seconds"], rows: rows)
    if sortedRows.count > 20 {
        out += "\n_+\(sortedRows.count - 20) more not shown._\n"
    }
    out += "\n"

    // Decision 0025's exemption, stated as a fact rather than folded silently into
    // the count above: a latch-graced tick already isn't in `falseMetTicks`, so this
    // is what lets a reader see how much the release window is doing, not a
    // correction to the table.
    let gracedTotal = flagged.reduce(0) { $0 + ($1.t1?.latchGracedTicks ?? 0) }
    out += "Latch-graced ticks (raw-false, latched-met inside a `mustNotFire` zone, "
    out += "exempted from the count above): \(gracedTotal).\n\n"
    return out
}

func buildFalseMetClauseSection(_ results: [ScenarioResult]) -> String {
    var out = "### False-met clause attribution (F-0028)\n\n"
    let flagged = results.filter { ($0.t1?.falseMetTicks ?? 0) > 0 }
    if flagged.isEmpty {
        out += "no scenario recorded a false-met tick.\n\n"
        return out
    }

    let withClause = flagged.filter { $0.t1?.falseMetClause != nil }
    guard !withClause.isEmpty else {
        out += "not present in this run — `T1MetricSet` needs a `falseMetClause: String?` "
        out += "field (the `reason` of the `mustNotFire` `TruthZone` — `\"count\"`, "
        out += "`\"sustained\"`, `\"frequency\"` or `\"duration\"` — that condemns this "
        out += "scenario-leg's *first* false-met tick) for this table to attribute the "
        out += "\(flagged.count) false-met scenario(s) above to a clause. F-0028 is "
        out += "explicit that the raw count is otherwise uninterpretable.\n\n"
        return out
    }

    var counts: [String: Int] = [:]
    for row in withClause {
        counts[row.t1!.falseMetClause!, default: 0] += 1
    }
    var rows: [[String]] = []
    for clause in counts.keys.sorted() {
        rows.append([clause, "\(counts[clause]!)"])
    }
    out += markdownTable(headers: ["Clause", "Scenarios"], rows: rows)
    out += "\n"
    if withClause.count < flagged.count {
        out += "_\(flagged.count - withClause.count) false-met scenario(s) carry no clause "
        out += "(an older result row, or a leg the field doesn't reach)._\n\n"
    }
    return out
}

func buildEarlyFireSection(_ results: [ScenarioResult]) -> String {
    var out = "### Early fire (T1-01's symmetric half, F-0018)\n\n"
    let rows = results.filter { $0.t1?.earlyFireSeconds != nil }
    if rows.isEmpty {
        out += "no scenario recorded an early fire in this run.\n\n"
        return out
    }

    let sortedRows = rows.sorted { ($0.t1?.earlyFireSeconds ?? 0) > ($1.t1?.earlyFireSeconds ?? 0) }
    var table: [[String]] = []
    for row in sortedRows {
        table.append([
            row.scenarioId ?? "unknown", row.leg ?? "unknown",
            row.archetype ?? "unknown", row.noiseProfile ?? "unknown",
            row.t1?.earlyFireSeconds.map(formatMinutes) ?? "—",
            row.t1?.earlyFireGraded ?? "—",
        ])
    }
    out += markdownTable(
        headers: ["Scenario", "Leg", "Archetype", "Noise", "Early by (min)", "Graded"], rows: table
    )
    out += "\n"

    let mustNotFireCount = rows.filter { $0.t1?.earlyFireGraded == "mustNotFire" }.count
    out += "\(rows.count) scenario(s) fired early; \(mustNotFireCount) landed in a `mustNotFire` "
    out += "zone (T1-01's early-fire flag) rather than gray.\n\n"
    return out
}

func buildFlapSection(_ results: [ScenarioResult]) -> String {
    var out = "### Flap histogram\n\n"
    var buckets: [String: Int] = ["0": 0, "1": 0, "2": 0, "3-5": 0, "6+": 0]
    var churnValues: [Double] = []
    var latchedTotal = 0
    var rawTotal = 0
    var noVerdictTotal = 0
    var partialTotal = 0
    var scenariosWithRawFlaps = 0
    var scenariosWithDestination = 0
    var any = false
    for row in results {
        guard let t1 = row.t1 else { continue }
        any = true
        latchedTotal += t1.flapCount ?? 0
        rawTotal += t1.rawFlaps ?? 0
        if (t1.rawFlaps ?? 0) > 0 { scenariosWithRawFlaps += 1 }
        if t1.flapToNoVerdict != nil || t1.flapToPartial != nil { scenariosWithDestination += 1 }
        noVerdictTotal += t1.flapToNoVerdict ?? 0
        partialTotal += t1.flapToPartial ?? 0
        let worst = t1.worstFlapsIn30Minutes ?? 0
        switch worst {
        case 0: buckets["0"]! += 1
        case 1: buckets["1"]! += 1
        case 2: buckets["2"]! += 1
        case 3...5: buckets["3-5"]! += 1
        default: buckets["6+"]! += 1
        }
        churnValues.append(t1.bannerChurnPerHour ?? 0)
    }
    guard any else {
        out += "not run / not present.\n\n"
        return out
    }

    var rows: [[String]] = []
    for key in ["0", "1", "2", "3-5", "6+"] {
        rows.append([key, "\(buckets[key]!)"])
    }
    out += markdownTable(headers: ["Worst flaps in 30 min", "Count"], rows: rows)
    out += "\n"

    let sortedChurn = churnValues.sorted()
    let p90 = nearestRankDouble(sortedChurn, 90) ?? 0
    let maxChurn = sortedChurn.last ?? 0
    out += "Banner churn per hour — p90: \(String(format: "%.1f", p90)), "
    out += "max: \(String(format: "%.1f", maxChurn)) (n=\(sortedChurn.count)).\n\n"

    // The latch's own account of itself (decision 0025): the histogram above is the
    // presented verdict, and without the raw count beside it nobody can tell a latch
    // that is working from a mechanism that never fired.
    out += "Flaps in mustFire zones — latched: \(latchedTotal), raw: \(rawTotal), "
    out += "across \(scenariosWithRawFlaps) scenario(s) with any raw flap. "
    // Latched can exceed raw: holding the verdict moves a transition later, and a
    // drop that used to land in a gray zone can land inside a mustFire one, where
    // T1-04 counts it. The two numbers are a comparison, not a subtraction.
    out += latchedTotal <= rawTotal
        ? "The latch absorbed \(rawTotal - latchedTotal).\n\n"
        : "The latch shifted \(latchedTotal - rawTotal) transition(s) later into a mustFire zone rather than absorbing them.\n\n"

    // The split this wave exists to show (F-0009's residual): met→noVerdict is the
    // status disappearing under the evidence floor, met→partial is a dimension
    // wobbling — the latch was built for the second and was absorbing the first
    // instead. Rendered whether the fields are present or not, so an older run's
    // absence reads as "not present" rather than as a silent 0/0.
    if scenariosWithDestination > 0 {
        out += "Flap destination split — met→noVerdict: \(noVerdictTotal), met→partial: \(partialTotal) "
        out += "(sum \(noVerdictTotal + partialTotal) against a latched total of \(latchedTotal)).\n\n"
    } else {
        out += "Flap destination split: not present in this run — needs "
        out += "`T1MetricSet.flapToNoVerdict`/`flapToPartial: Int?`.\n\n"
    }
    return out
}

func buildNoiseDeltaSection(_ results: [ScenarioResult]) -> String {
    var out = "### Paired noise-delta\n\n"

    struct Bucket {
        var deltas: [Int64] = []
        var suppressedButCleanDidNotCount = 0
        var flapDeltas: [Int] = []
    }
    var byNoise: [String: Bucket] = [:]
    for row in results {
        guard let t1 = row.t1, let delta = t1.noiseDeltaOnsetSeconds else { continue }
        let noise = row.noiseProfile ?? "unknown"
        var bucket = byNoise[noise] ?? Bucket()
        bucket.deltas.append(delta)
        if t1.noiseSuppressedButCleanDidNot == true {
            bucket.suppressedButCleanDidNotCount += 1
        }
        if let flapDelta = t1.noiseDeltaFlaps {
            bucket.flapDeltas.append(flapDelta)
        }
        byNoise[noise] = bucket
    }
    if byNoise.isEmpty {
        out += "no scenario carries a paired noise-delta (needs a same-seed clean sibling).\n\n"
        return out
    }

    var rows: [[String]] = []
    for noise in noiseProfileOrder {
        guard let bucket = byNoise[noise], !bucket.deltas.isEmpty else { continue }
        let sortedDeltas = bucket.deltas.sorted()
        let median = nearestRankInt64(sortedDeltas, 50) ?? 0
        let maxDelta = sortedDeltas.last ?? 0
        let sortedFlaps = bucket.flapDeltas.sorted()
        let medianFlapsString: String
        if let medianFlaps = nearestRankInt(sortedFlaps, 50) {
            medianFlapsString = "\(medianFlaps)"
        } else {
            medianFlapsString = "—"
        }
        rows.append([
            noise, "\(bucket.deltas.count)", formatMinutes(median), formatMinutes(maxDelta),
            "\(bucket.suppressedButCleanDidNotCount)", medianFlapsString,
        ])
    }
    out += markdownTable(
        headers: [
            "Noise profile", "n", "median Δ onset (min)", "max Δ onset (min)",
            "suppressed-but-clean-didn't", "median Δ flaps",
        ], rows: rows
    )
    out += "\n"
    return out
}

func buildSuppressionSection(_ results: [ScenarioResult]) -> String {
    var out = "### Suppression by noise profile\n\n"
    var counts: [String: Int] = [:]
    var total = 0
    for row in results {
        guard row.t1?.suppressed == true else { continue }
        total += 1
        let noise = row.noiseProfile ?? "unknown"
        counts[noise, default: 0] += 1
    }
    out += "**Total suppressions in this run: \(total)** — S4, the top of the ranking law (decision 0021 §2).\n\n"
    if total == 0 {
        out += "no scenario suppressed a legitimate verdict in this run.\n\n"
        return out
    }

    var rows: [[String]] = []
    for noise in noiseProfileOrder {
        let count = counts[noise] ?? 0
        guard count > 0 else { continue }
        rows.append([noise, "\(count)"])
    }
    out += markdownTable(headers: ["Noise profile", "Suppressions"], rows: rows)
    out += "\n"
    return out
}

func buildFloorStarvationSection(_ results: [ScenarioResult]) -> String {
    var out = "### Floor starvation\n\n"
    let values = results.compactMap { $0.t1?.floorStarvationSeconds }
    if values.isEmpty {
        out += "no scenario recorded floor starvation.\n\n"
        return out
    }

    let sorted = values.sorted()
    let p50 = nearestRankInt64(sorted, 50) ?? 0
    let p90 = nearestRankInt64(sorted, 90) ?? 0
    let maxValue = sorted.last ?? 0
    // T1-06's threshold is 30 minutes, i.e. 1800 seconds.
    let overThreshold = values.filter { $0 > 1800 }.count
    out += "p50: \(formatMinutes(p50)) min, p90: \(formatMinutes(p90)) min, "
    out += "max: \(formatMinutes(maxValue)) min (n=\(sorted.count)).\n\n"
    out += "Over the 30 min T1-06 threshold: \(overThreshold) of \(values.count).\n\n"
    return out
}

func buildT1Section(_ results: [ScenarioResult]) -> String {
    var out = "## T1 — verdict quality\n\n"
    let withT1 = results.filter { $0.t1 != nil }
    if withT1.isEmpty {
        out += "not run / not present — no scenario carries a t1 metric set.\n\n"
        return out
    }

    out += buildOnsetLagSection(withT1)
    out += buildEarlyFireSection(withT1)
    out += buildFalseMetSection(withT1)
    out += buildFalseMetClauseSection(withT1)
    out += buildFlapSection(withT1)
    out += buildNoiseDeltaSection(withT1)
    out += buildSuppressionSection(withT1)
    out += buildFloorStarvationSection(withT1)
    return out
}

// MARK: - Section 3b: expected-detection validation (RUBRIC §4, F-0024)
//
// RUBRIC §4: "Each ships as a seeded corpus scenario annotated `expected_detection:
// [check ids]`; the validation mode fails if any expected detection stays silent."
// The field the code actually carries (`ScenarioManifest.expectedDetection`, see
// Corpus.swift/BoundaryBattery.swift) is looser than that promise today — free-text
// tags ("archetype:precipitous", "onsetExpected") and hand-written prose, not always
// a rubric check id — so this section renders whatever a scenario carries, extracts
// any check-id-shaped token it can find inside each annotation, and scores only
// those: a T0-/T1-shaped id is checked against this row's own violations/flags (the
// only per-row facts a result carries to check it against); a T2-/T3-shaped id is
// listed for reference but not scored, because T2 is bench/layer-A and T3 is
// judgment-only (RUBRIC §2: "Never pass/fail") — neither fires from a result row.

func buildExpectedDetectionSection(_ results: [ScenarioResult]) -> String {
    var out = "## Expected-detection validation (RUBRIC §4)\n\n"
    let annotated = results.filter { !($0.expectedDetection ?? []).isEmpty }
    guard !annotated.isEmpty else {
        out += "no scenario in this run carries `expectedDetection` — `ScenarioResult` "
        out += "needs an `expectedDetection: [String]?` field (mirroring "
        out += "`ScenarioManifest.expectedDetection`), threaded from `manifest.expectedDetection` "
        out += "at each `ScenarioResult(...)` construction site (`PureSweepTests.swift`, "
        out += "`ModelReplayTests.swift`, `StoreReplayTests.swift`, `LegAgreementTests.swift`) "
        out += "for this section to render anything.\n\n"
        return out
    }

    func checkIds(in tag: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: #"T[0-3]-(?:Q?\d+)"#) else { return [] }
        let range = NSRange(tag.startIndex..<tag.endIndex, in: tag)
        return regex.matches(in: tag, range: range).compactMap { match in
            Range(match.range, in: tag).map { String(tag[$0]) }
        }
    }

    var rows: [[String]] = []
    var anyScored = false
    var anySilent = false
    for row in annotated {
        let scenarioId = row.scenarioId ?? "unknown"
        let leg = row.leg ?? "unknown"
        let firedFlags = Set(row.t1?.flags ?? [])
        let firedT0 = Set((row.t0?.violations ?? []).compactMap { $0.check })

        for tag in row.expectedDetection ?? [] {
            let ids = checkIds(in: tag)
            guard !ids.isEmpty else {
                rows.append([scenarioId, leg, capped([tag], limit: 1), "—", "not a check id; reference only"])
                continue
            }
            for id in ids {
                guard id.hasPrefix("T0-") || id.hasPrefix("T1-") else {
                    rows.append([scenarioId, leg, tag, id, "layer A/J — not scored from a result row"])
                    continue
                }
                anyScored = true
                let fired = firedFlags.contains(id) || firedT0.contains(id)
                if !fired { anySilent = true }
                rows.append([scenarioId, leg, tag, id, fired ? "fired" : "**SILENT**"])
            }
        }
    }

    out += markdownTable(headers: ["Scenario", "Leg", "Annotation", "Check id", "Result"], rows: rows)
    out += "\n"

    if !anyScored {
        out += "**Verdict: not evaluated** — no annotation in this run resolved to a T0-/T1-shaped "
        out += "check id, so RUBRIC §4's \"fails if any expected detection stays silent\" rule has "
        out += "nothing to check against yet.\n\n"
    } else if anySilent {
        out += "**Verdict: NOT ALL GREEN** — at least one expected detection stayed silent.\n\n"
    } else {
        out += "**Verdict: all green** — every scorable expected detection fired.\n\n"
    }
    return out
}

// MARK: - Section 4: T2

func buildT2Section(runDirURL: URL, results: [ScenarioResult], t2FieldScenarioIds: [String]) -> String {
    var out = "## T2 — presentation and scale\n\n"

    // The galleries, whatever they turned out to be. Every sweep the shots stage
    // wrote gets a line whether or not this script knows its name — the alternative
    // is what `light-m` was: written every run, referenced nowhere, invisible to
    // anyone reading the report instead of the directory.
    let galleries = discoveredGalleries(runDirURL: runDirURL)
    if galleries.isEmpty {
        out += "no screenshot sweeps in this run (`shots/` is empty or absent).\n\n"
    } else {
        out += "Screenshot sweeps under `shots/`:\n\n"
        for gallery in galleries {
            let primary = "shots/\(gallery.name)" == primaryShotsDirectory ? " — primary (DESIGN-SPEC §8)" : ""
            out += "- [`\(gallery.name)`](shots/\(gallery.name)) — \(gallery.count) shot(s)\(primary)\n"
        }
        out += "\n"
    }

    let benchDir = runDirURL.appendingPathComponent("bench", isDirectory: true)
    let fm = FileManager.default
    var isDir: ObjCBool = false
    let benchDirExists = fm.fileExists(atPath: benchDir.path, isDirectory: &isDir) && isDir.boolValue
    let benchFiles: [URL] = benchDirExists
        ? ((try? fm.contentsOfDirectory(at: benchDir, includingPropertiesForKeys: nil))?
            .filter { $0.pathExtension == "json" } ?? [])
        : []

    if !benchFiles.isEmpty {
        out += "Bench files found under `bench/`:\n\n"
        for file in benchFiles.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            out += "- `\(file.lastPathComponent)`\n"
            if let data = try? Data(contentsOf: file) {
                if let raw = try? JSONSerialization.jsonObject(with: data) {
                    if let json = raw as? [String: Any] {
                        for key in json.keys.sorted() {
                            if let value = json[key] {
                                out += "  - \(key): \(String(describing: value))\n"
                            }
                        }
                    }
                }
            }
        }
        out += "\n"
        return out
    }

    if !t2FieldScenarioIds.isEmpty {
        out += "no `bench/` directory, but \(t2FieldScenarioIds.count) result row(s) carry a top-level "
        out += "`t2` field not modeled by this script's decoder: \(capped(t2FieldScenarioIds)).\n\n"
        return out
    }

    out += "no bench output in this run; T2-07 microbench lives in LaborSimTests/ScaleBenchTests.swift.\n\n"
    return out
}

// MARK: - Section 5: Worst-12 gallery

func buildWorst12Section(_ results: [ScenarioResult], runDirURL: URL, snapshotIndex: SnapshotIndex?) -> String {
    var out = "## Worst 12\n\n"
    let candidates = rankedCandidates(results)
    if candidates.isEmpty {
        out += "no scenario tripped a T1 flag in this run.\n\n"
        return out
    }

    let worst = Array(candidates.prefix(12))

    // Scenario id -> the PNGs the index says this scenario's moments produced. The
    // exporter states the shot basename itself; reconstructing it from the scenario id
    // would not work anyway, because the stem is the promoted scenario's short label
    // and the moment, not the corpus id.
    var shotsByScenario: [String: [String]] = [:]
    for entry in snapshotIndex?.entries ?? [] {
        guard let scenario = entry.scenario else { continue }
        let shot = entry.shot ?? entry.file.map { ($0 as NSString).deletingPathExtension + ".png" }
        guard let shot else { continue }
        shotsByScenario[scenario, default: []].append(shot)
    }

    let shotsDir = runDirURL.appendingPathComponent(primaryShotsDirectory, isDirectory: true)
    let fm = FileManager.default
    var isDir: ObjCBool = false
    let shotsDirExists = fm.fileExists(atPath: shotsDir.path, isDirectory: &isDir) && isDir.boolValue
    // Only link shots that actually landed: a run whose shots stage was skipped or
    // blocked should say nothing rather than offer twelve dead links.
    let shotFiles: Set<String> = shotsDirExists
        ? Set((try? fm.contentsOfDirectory(atPath: shotsDir.path)) ?? [])
        : []

    var rows: [[String]] = []
    for (index, candidate) in worst.enumerated() {
        var cell = "\(candidate.scenarioId).\(candidate.leg)"
        let links = (shotsByScenario[candidate.scenarioId] ?? [])
            .filter { shotFiles.contains($0) }
            .sorted()
            .map { "[\(($0 as NSString).deletingPathExtension)](\(primaryShotsDirectory)/\($0))" }
        if !links.isEmpty {
            cell += " — " + links.joined(separator: ", ")
        }
        rows.append([
            "\(index + 1)", candidate.tier.severityLabel, cell,
            candidate.archetype, candidate.noiseProfile, candidate.metric,
            candidate.flags.joined(separator: ", "),
        ])
    }
    out += markdownTable(
        headers: ["Rank", "Sev", "Scenario", "Archetype", "Noise", "Metric", "Flags"], rows: rows
    )
    if candidates.count < 12 {
        out += "\n_only \(candidates.count) scenario(s) tripped a T1 flag; fewer than 12 available._\n"
    }
    out += "\n"
    return out
}

// MARK: - Section 6: Findings delta

func buildFindingsDeltaSection(_ results: [ScenarioResult], repoRoot: URL) -> String {
    var out = "## Findings delta\n\n"

    let overridePath = ProcessInfo.processInfo.environment["HUSHLIGHT_FINDINGS"]
    let findingsURL: URL
    if let overridePath = overridePath, !overridePath.isEmpty {
        findingsURL = URL(fileURLWithPath: overridePath)
    } else {
        findingsURL = repoRoot.appendingPathComponent("docs/qa/FINDINGS.md")
    }

    guard let findingRows = parseFindingsTable(at: findingsURL) else {
        out += "not present — could not read \(findingsURL.path).\n\n"
        return out
    }

    out += "### Status counts\n\n"
    if findingRows.isEmpty {
        out += "no findings registered yet in \(findingsURL.lastPathComponent).\n\n"
    } else {
        var bySeverity: [String: Int] = [:]
        var byStatus: [String: Int] = [:]
        for row in findingRows {
            bySeverity[row.severity, default: 0] += 1
            // "filed(SP-192)" -> "filed" so the family, not every distinct ref, groups.
            let statusFamily = row.status.components(separatedBy: "(").first?
                .trimmingCharacters(in: .whitespaces) ?? row.status
            byStatus[statusFamily, default: 0] += 1
        }

        var severityRows: [[String]] = []
        for key in bySeverity.keys.sorted() {
            severityRows.append([key, "\(bySeverity[key]!)"])
        }
        out += markdownTable(headers: ["Severity", "Count"], rows: severityRows)
        out += "\n"

        var statusRows: [[String]] = []
        for key in byStatus.keys.sorted() {
            statusRows.append([key, "\(byStatus[key]!)"])
        }
        out += markdownTable(headers: ["Status", "Count"], rows: statusRows)
        out += "\n"
    }

    out += "### Registered vs. FINDINGS.md\n\n"
    var registeredRefsInRun = Set<String>()
    for row in results {
        for violation in row.t0?.violations ?? [] {
            if let ref = violation.knownRef, !ref.isEmpty {
                registeredRefsInRun.insert(ref)
            }
        }
    }
    let findingsIds = Set(findingRows.map { $0.f })

    let seenNotFiled = registeredRefsInRun.subtracting(findingsIds).sorted()
    let filedNotSeen = findingsIds.subtracting(registeredRefsInRun).sorted()

    out += "- Registered `knownRef`s in this run with no row in FINDINGS.md: "
    out += seenNotFiled.isEmpty ? "none.\n" : "\(capped(seenNotFiled)).\n"
    out += "- FINDINGS.md rows with no matching `knownRef` in this run: "
    out += filedNotSeen.isEmpty ? "none.\n" : "\(capped(filedNotSeen)).\n"
    out += "\n"

    return out
}

// MARK: - Section 7: Appendix — kill matrix

func buildKillMatrixSection() -> String {
    var out = "## Appendix: kill matrix\n\n"
    let env = ProcessInfo.processInfo.environment
    let mutantLogPath = env["HUSHLIGHT_MUTANT_LOG"] ?? "/tmp/mutant-retry.log"
    let inplaceLogPath = env["HUSHLIGHT_INPLACE_LOG"] ?? "/tmp/inplace-matrix.log"

    let mutantRows = parseKillLog(at: mutantLogPath, source: "mutant-retry")
    let inplaceRows = parseKillLog(at: inplaceLogPath, source: "inplace-matrix")
    let allRows = mutantRows + inplaceRows

    if allRows.isEmpty {
        out += "run scripts/labor-mutate.sh\n\n"
        return out
    }

    var rows: [[String]] = []
    for row in allRows {
        rows.append([row.source, row.mutant, row.verdict, row.killedBy])
    }
    out += markdownTable(headers: ["Source", "Mutant", "Verdict", "Killed by"], rows: rows)
    out += "\n"
    return out
}

// MARK: - Driver

let arguments = CommandLine.arguments
guard arguments.count >= 2 else {
    writeStderr("usage: swift labor-report.swift <runDir>\n")
    exit(1)
}

let runDirPath = arguments[1]
let fileManager = FileManager.default

var runDirIsDirectory: ObjCBool = false
guard fileManager.fileExists(atPath: runDirPath, isDirectory: &runDirIsDirectory),
      runDirIsDirectory.boolValue else {
    writeStderr("labor-report: run dir not found: \(runDirPath)\n")
    exit(1)
}

let runDirURL = URL(fileURLWithPath: runDirPath, isDirectory: true).standardizedFileURL
let resultsDirURL = runDirURL.appendingPathComponent("results", isDirectory: true)

let resultFiles: [URL] = (try? fileManager.contentsOfDirectory(
    at: resultsDirURL, includingPropertiesForKeys: nil
))?.filter { $0.pathExtension == "json" } ?? []

guard !resultFiles.isEmpty else {
    writeStderr("labor-report: no results/*.json found under \(runDirPath)\n")
    exit(1)
}

var scenarioResults: [ScenarioResult] = []
var parseFailures = 0
var t2FieldScenarioIds: [String] = []
let decoder = JSONDecoder()

for fileURL in resultFiles {
    guard let data = try? Data(contentsOf: fileURL) else {
        parseFailures += 1
        continue
    }

    // Cheap, best-effort scan for a schema addition the decoder above doesn't know
    // about yet, so the T2 section can still say something rather than silently
    // dropping it. Independent of the typed decode below.
    if let raw = try? JSONSerialization.jsonObject(with: data) {
        if let dict = raw as? [String: Any], dict["t2"] != nil {
            if let id = dict["scenarioId"] as? String {
                t2FieldScenarioIds.append(id)
            }
        }
    }

    guard let result = try? decoder.decode(ScenarioResult.self, from: data) else {
        parseFailures += 1
        continue
    }
    scenarioResults.append(result)
}

let runMetadata: RunMetadata? = {
    let url = runDirURL.appendingPathComponent("run.json")
    guard let data = try? Data(contentsOf: url) else { return nil }
    return try? decoder.decode(RunMetadata.self, from: data)
}()

let runMeta: RunMeta? = {
    let url = runDirURL.appendingPathComponent("run-meta.json")
    guard let data = try? Data(contentsOf: url) else { return nil }
    return try? decoder.decode(RunMeta.self, from: data)
}()

let snapshotIndex: SnapshotIndex? = {
    let url = runDirURL.appendingPathComponent("snapshots/index.json")
    guard let data = try? Data(contentsOf: url) else { return nil }
    return try? decoder.decode(SnapshotIndex.self, from: data)
}()

// Repo root = this script file's own directory, one level up (scripts/ -> repo
// root). #filePath is a compile-time literal, not argv[0], so it survives however
// `swift` chooses to invoke the compiled script.
let scriptPath = #filePath
let scriptURL: URL = scriptPath.hasPrefix("/")
    ? URL(fileURLWithPath: scriptPath)
    : URL(fileURLWithPath: scriptPath, relativeTo: URL(fileURLWithPath: fileManager.currentDirectoryPath)).standardizedFileURL
let repoRoot = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
let corpusManifest = loadCorpusManifest(repoRoot: repoRoot)

var report = ""
report += buildHeaderSection(
    runDirURL: runDirURL, results: scenarioResults, runMetadata: runMetadata,
    runMeta: runMeta, parseFailures: parseFailures, corpusManifest: corpusManifest
)
report += buildT0Section(scenarioResults)
report += buildT1Section(scenarioResults)
report += buildExpectedDetectionSection(scenarioResults)
report += buildT2Section(runDirURL: runDirURL, results: scenarioResults, t2FieldScenarioIds: t2FieldScenarioIds)
report += buildWorst12Section(scenarioResults, runDirURL: runDirURL, snapshotIndex: snapshotIndex)
report += buildFindingsDeltaSection(scenarioResults, repoRoot: repoRoot)
report += buildKillMatrixSection()

let reportURL = runDirURL.appendingPathComponent("report.md")
do {
    try report.write(to: reportURL, atomically: true, encoding: .utf8)
} catch {
    writeStderr("labor-report: failed to write \(reportURL.path): \(error)\n")
    exit(1)
}

// MARK: - Caller-facing summary

let scenarioIdCount = Set(scenarioResults.compactMap { $0.scenarioId }).count
let t0Groups = groupScenariosForT0(scenarioResults)
let t0Total = t0Groups.count
let t0Passing = t0Groups.values.filter { $0.allPass }.count
let t0PassRateString = t0Total > 0 ? "\(t0Passing)/\(t0Total)" : "n/a"

let suppressionCount = scenarioResults.filter { $0.t1?.suppressed == true }.count

let worstFinding: String
if let top = rankedCandidates(scenarioResults).first {
    worstFinding = "\(top.tier.severityLabel) \(top.scenarioId).\(top.leg) — \(top.metric)"
} else {
    worstFinding = "none"
}

print("Scenarios: \(scenarioIdCount) distinct ids, \(scenarioResults.count) scenario × leg rows.")
print("T0 pass rate: \(t0PassRateString) scenarios fully clean across their legs.")
print("Suppressions (S4): \(suppressionCount).")
print("Worst finding: \(worstFinding).")
print("Report written to: \(reportURL.path)")
