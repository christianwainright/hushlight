import Foundation
import LaborKit
import LaborOracle
import Testing
@testable import LaborSim

// Everything the three replay legs share: the bridge across the oracle's dependency
// wall, the per-probe comparison that turns a disagreement into a check id, and the
// bookkeeping that keeps four hundred scenarios' worth of it inside a test loop.
//
// The comparison lives here rather than in `Sources/` on purpose. `LaborSim` depends
// on LaborKit; `LaborOracle` depends on nothing. Only the test target sees both, and
// that is exactly the property decision 0021's independence rule is protecting — a
// referee that shared a module with a player would referee nothing.

/// Failure labels name the scenario the way a human triaging it would: archetype,
/// variant, thumb, rule, seed. Without this, `@Test(arguments:)` over four hundred
/// scenarios reports a struct dump nobody can act on.
extension ScenarioSeedRef: CustomTestStringConvertible {
    public var testDescription: String { label }
}

// MARK: - Violation collection

/// Caps what one scenario can record, per check.
///
/// A systematic divergence fires at every one of a scenario's probes; keeping all of
/// them would turn one bug into ten thousand JSON rows and an unreadable failure
/// message. Five per check is enough to see the shape (first occurrence, and whether
/// it recurs), and `totals` keeps the true count so the report can still rank by
/// prevalence.
struct ViolationCollector {
    static let perCheckLimit = 5

    private(set) var violations: [T0Violation] = []
    private(set) var totals: [String: Int] = [:]
    private(set) var unregistered = 0

    let scenarioId: String
    let leg: KnownFinding.Leg

    init(scenarioId: String, leg: KnownFinding.Leg) {
        self.scenarioId = scenarioId
        self.leg = leg
    }

    /// `detail` is autoclosed so the interpolation cost is paid only by violations
    /// that actually get recorded — the sweep evaluates this call site tens of
    /// millions of times across the corpus.
    mutating func record(_ check: String, at probe: Int64, _ detail: @autoclosure () -> String) {
        let seen = totals[check, default: 0]
        totals[check] = seen + 1

        let known = KnownFindings.match(scenarioId: scenarioId, checkId: check, leg: leg)
        if known == nil { unregistered += 1 }
        guard seen < Self.perCheckLimit else { return }
        violations.append(
            T0Violation(check: check, probe: probe, detail: detail(), knownRef: known?.findingRef)
        )
    }

    var passed: Bool { unregistered == 0 }

    /// The failure message. Registered violations are omitted — they are recorded in
    /// the results file and reported by Phase 5, and repeating them here would bury
    /// the one line that says what is newly wrong.
    var failureSummary: String {
        let news = violations.filter { $0.knownRef == nil }
        let lines = news.map { "\($0.check)@\($0.probe): \($0.detail)" }
        let joined = lines.prefix(5).joined(separator: " | ")
        return "\(scenarioId) [\(leg.rawValue)] \(unregistered) unregistered T0 violation(s): \(joined)"
    }
}

// MARK: - The oracle bridge

enum HarnessBridge {
    /// Deliberately total and boring — a bridge that grew a rule of its own would be
    /// a third implementation, and a bug in it would masquerade as agreement.
    static func asOracle(_ action: ScenarioAction) -> OracleAction {
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

    static func rule(_ raw: String) -> GuidelineRule { GuidelineRule(rawValue: raw) ?? .fiveOneOne }
    static func oracleRule(_ raw: String) -> OracleRule { OracleRule(rawValue: raw) ?? .fiveOneOne }

    static func date(_ t0: Int64, _ offset: Int64) -> Date {
        Date(timeIntervalSince1970: TimeInterval(t0 + offset))
    }

    static func contractions(_ records: [SimRecord], t0: Int64) -> [Contraction] {
        records.map {
            Contraction(
                id: $0.id,
                startedAt: date(t0, $0.start),
                endedAt: $0.end.map { end in date(t0, end) }
            )
        }
    }

    static func oracleRecords(_ records: [SimRecord]) -> [OracleRecord] {
        records.map { OracleRecord(createdBy: $0.createdBy, start: $0.start, end: $0.end) }
    }

    static func seconds(_ duration: Duration) -> Double {
        Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
    }

    /// What the screen shows: the **latched** verdict (decision 0025, amended),
    /// because that is the state a reader can distinguish and the banner churn
    /// T1-04 measures. `presentedMet` is checked first and alone — a pattern-level
    /// field now, so a held verdict reads `.met` even where the evidence floor has
    /// drained the `GuidelineStatus` out from under it entirely. Only once that
    /// check says no does a rendered-but-failing status earn `.partial`; neither
    /// existing at all is `.noVerdict`.
    static func verdictState(_ pattern: LaborPattern) -> VerdictState {
        guard pattern.presentedMet else {
            return pattern.guideline == nil ? .noVerdict : .partial
        }
        return .met
    }

    /// The same reduction over the **raw** verdict, kept so `rawFlaps` can say how
    /// much churn the latch is absorbing. Calibration data, not a user-visible state.
    static func rawVerdictState(_ pattern: LaborPattern) -> VerdictState {
        guard let guideline = pattern.guideline else { return .noVerdict }
        return guideline.met ? .met : .partial
    }
}

// MARK: - Per-probe comparison

enum HarnessCompare {
    /// Sampled means are plain-float averages of noisy draws; the referee keeps a
    /// rational. RUBRIC §1 allows half a second of that drift and demands exactness
    /// wherever the referee's mean is integral — which is every boundary-battery
    /// case, by construction. `exactEpsilon` is not a tolerance so much as an
    /// admission that `Duration.seconds(Double)` round-trips an integer through a
    /// binary float, and 1 ns is far below any figure this product renders.
    static let driftToleranceSeconds = 0.5
    static let exactEpsilonSeconds = 1e-9

    static func tolerance(forExactMean exact: Bool) -> Double {
        exact ? exactEpsilonSeconds : driftToleranceSeconds
    }

    /// Compares one probe instant. Returns nothing; records into the collector so a
    /// scenario's whole sweep produces one verdict rather than one per figure.
    ///
    /// `contractions`/`oracleRecords` and both rules are the sweep's own full record
    /// set and chosen rule — the trend check below needs them to look back a second
    /// window past `now`/`probe`, which `app`/`oracle` alone (already narrowed to the
    /// live episode) cannot answer.
    static func probe(
        app: LaborPattern,
        oracle: OraclePattern,
        contractions: [Contraction],
        oracleRecords: [OracleRecord],
        rule: GuidelineRule,
        oracleRule: OracleRule,
        now: Date,
        at probe: Int64,
        t0: Int64,
        into collector: inout ViolationCollector
    ) {
        // The empty state first: every other figure is meaningless if the two
        // disagree about whether there is a live episode at all.
        let appHasPattern = !app.episode.isEmpty
        guard appHasPattern == oracle.hasPattern else {
            collector.record("T0-02", at: probe,
                             "live-episode presence: app \(appHasPattern), oracle \(oracle.hasPattern)")
            return
        }
        guard oracle.hasPattern else { return }

        // T0-02 — episode partition, member for member.
        if app.episode.count != oracle.episode.count {
            collector.record("T0-02", at: probe,
                             "episode size: app \(app.episode.count), oracle \(oracle.episode.count)")
        } else {
            for (index, pair) in zip(app.episode, oracle.episode).enumerated() {
                let appStart = Int64(pair.0.startedAt.timeIntervalSince1970) - t0
                let appEnd = pair.0.endedAt.map { Int64($0.timeIntervalSince1970) - t0 }
                if appStart != pair.1.start || appEnd != pair.1.end {
                    let appEndText = appEnd.map(String.init) ?? "nil"
                    let oracleEndText = pair.1.end.map(String.init) ?? "nil"
                    collector.record("T0-02", at: probe, """
                        episode[\(index)]: app \(appStart)/\(appEndText) \
                        oracle \(pair.1.start)/\(oracleEndText)
                        """)
                    break
                }
            }
        }

        // T0-02 — the whole-second figures. Integral by construction on both sides,
        // so any difference at all is a real disagreement.
        let appEpisodeStart = app.episodeStart.map { Int64($0.timeIntervalSince1970) - t0 }
        if appEpisodeStart != oracle.episodeStart {
            let appText = appEpisodeStart.map(String.init) ?? "nil"
            let oracleText = oracle.episodeStart.map(String.init) ?? "nil"
            collector.record("T0-02", at: probe,
                             "episodeStart: app \(appText), oracle \(oracleText)")
        }
        compareInteger(app.patternLength, oracle.patternLengthSeconds,
                       "patternLength", at: probe, into: &collector)
        compareInteger(app.lastInterval, oracle.lastIntervalSeconds,
                       "lastInterval", at: probe, into: &collector)
        // Decision 0026's quantity — the tape's fill, and the only figure on the
        // screen that a lull is supposed to empty.
        compareInteger(app.sustainedEvidence, oracle.sustainedEvidenceSeconds,
                       "sustainedEvidence", at: probe, into: &collector)
        // Decision 0024's detail slot. Both ends, separately, so a disagreement says
        // which one moved.
        compareInteger(app.intervalRange?.lowerBound, oracle.intervalMinSeconds,
                       "intervalRange.min", at: probe, into: &collector)
        compareInteger(app.intervalRange?.upperBound, oracle.intervalMaxSeconds,
                       "intervalRange.max", at: probe, into: &collector)

        // T0-03 — nil-ness is a floor claim, and it is checked in both directions:
        // a figure appearing below its floor and a figure withheld above it are
        // different defects with different severities, and neither is a value bug.
        compareMean(app.averageInterval, oracle.averageInterval,
                    "averageInterval", at: probe, into: &collector)
        compareMean(app.averageDuration, oracle.averageDuration,
                    "averageDuration", at: probe, into: &collector)

        // T0-03 — the guideline itself is a floor-gated figure.
        if (app.guideline == nil) != (oracle.guidelineMet == nil) {
            let appHas = app.guideline != nil
            let oracleHas = oracle.guidelineMet != nil
            collector.record("T0-03", at: probe,
                             "guideline presence: app \(appHas), oracle \(oracleHas)")
        }
        if let guideline = app.guideline {
            if let frequency = oracle.frequencyMet, guideline.frequencyMet != frequency {
                collector.record("T0-02", at: probe,
                                 "frequencyMet: app \(guideline.frequencyMet), oracle \(frequency)")
            }
            if let duration = oracle.durationMet, guideline.durationMet != duration {
                collector.record("T0-02", at: probe,
                                 "durationMet: app \(guideline.durationMet), oracle \(duration)")
            }
            if let sustained = oracle.sustainedMet, guideline.sustainedMet != sustained {
                collector.record("T0-02", at: probe,
                                 "sustainedMet: app \(guideline.sustainedMet), oracle \(sustained)")
            }
            if let met = oracle.guidelineMet, guideline.met != met {
                collector.record("T0-02", at: probe, "met: app \(guideline.met), oracle \(met)")
            }
            // Onset is never delayed (decision 0025 §1): raw true implies presented
            // true, always. The reverse is the latch and is expected. `presentedMet`
            // reads from the pattern now, not the status (the amendment) — the check
            // still lives here because `guideline.met` is per-dimension and only
            // exists on the status.
            if guideline.met, !app.presentedMet {
                collector.record("T0-04", at: probe, "raw met but not presented — the latch delayed onset")
            }

            // T0-04 — the verdict may never outrun its evidence. Checked against the
            // referee's own window count, not the app's, so an engine that miscounted
            // the window cannot also grade its own homework.
            if guideline.met {
                if oracle.inWindowCount < 6 {
                    collector.record("T0-04", at: probe,
                                     "met with only \(oracle.inWindowCount) in window")
                }
                if app.averageInterval == nil || app.averageDuration == nil {
                    collector.record("T0-04", at: probe, "met with a nil average")
                }
            }

            // Decision 0040's early line, checked the same way `met` is above:
            // exact agreement with the referee's own independent judgement, onset
            // never delayed past the latch, and never outrunning its evidence.
            if let fastMet = oracle.fastMet, guideline.fastMet != fastMet {
                collector.record("T0-02", at: probe,
                                 "fastMet: app \(guideline.fastMet), oracle \(fastMet)")
            }
            if guideline.fastMet, !app.presentedFastMet {
                collector.record("T0-04", at: probe,
                                 "raw fast-met but not presented — the latch delayed onset")
            }
            if guideline.fastMet {
                if oracle.inWindowCount < 6 {
                    collector.record("T0-04", at: probe,
                                     "fast-met with only \(oracle.inWindowCount) in window")
                }
                if app.averageInterval == nil || app.averageDuration == nil {
                    collector.record("T0-04", at: probe, "fast-met with a nil average")
                }
                // 0040 §1's last clause: the full verdict outranks and retires the
                // fast line, so the two must never both be raw-true at once.
                if guideline.met {
                    collector.record("T0-04", at: probe, "fast-met and met both raw-true")
                }
            }
        }

        // The latched verdict is derived, not stored, so the referee derives it
        // too — a latch that agreed with nothing would be a second definition of
        // "what the screen says". Compared at every probe, outside the `guideline`
        // block above (decision 0025, amended): `presentedMet` is a pattern-level
        // field now and can read true from a held verdict even where the evidence
        // floor has withdrawn `GuidelineStatus` entirely — exactly the case this
        // amendment exists to cover, so the referee has to be watching it there too.
        if app.presentedMet != oracle.presentedMet {
            collector.record("T0-02", at: probe,
                             "presentedMet: app \(app.presentedMet), oracle \(oracle.presentedMet)")
        }
        // Decision 0040 §2: the fast-met latch, checked the same way and for the
        // same reason — it is a pattern-level field that can outlive `guideline`
        // draining below the floor, so it is compared here, not inside the
        // `guideline` block above.
        if app.presentedFastMet != oracle.presentedFastMet {
            collector.record("T0-02", at: probe,
                             "presentedFastMet: app \(app.presentedFastMet), oracle \(oracle.presentedFastMet)")
        }

        // T0-04 — the no-figures guard: a presented verdict must always have at
        // least the interval figure to render beside it. A banner with three em
        // dashes under it would be an assertion with no evidence on screen, and
        // the amendment's guard exists precisely to forbid that shape.
        if app.presentedMet, app.averageInterval == nil {
            collector.record("T0-04", at: probe,
                             "presented with no averageInterval — the no-figures guard failed")
        }
        if app.presentedFastMet, app.averageInterval == nil {
            collector.record("T0-04", at: probe,
                             "fast-met presented with no averageInterval — the no-figures guard failed")
        }

        // T0-02 — the history digest over the same episode. `summary` is the figure
        // History renders, and it applies the same floors from a different code path.
        compareSummary(
            PatternAnalysis.summary(of: app.episode),
            OracleMath.summary(of: oracle.episode),
            at: probe, into: &collector
        )

        // Decision 0043's trend — this hour against the hour before it — checked
        // for exact agreement the same way `met`/`fastMet` are above: fired or not
        // (T0-03, a floor claim in both directions), then direction and both
        // figures (T0-02) once both sides agree it fired at all.
        let appTrend = PatternAnalysis.trend(for: contractions, rule: rule, now: now)
        let oracleTrend = OracleMath.trend(records: oracleRecords, rule: oracleRule, now: probe)
        if (appTrend == nil) != (oracleTrend == nil) {
            collector.record("T0-03", at: probe,
                             "trend presence: app \(appTrend != nil), oracle \(oracleTrend != nil)")
        }
        if let appTrend, let oracleTrend {
            let appDirection: OracleTrend.Direction = appTrend.direction == .closer ? .closer : .fartherApart
            if appDirection != oracleTrend.direction {
                collector.record("T0-02", at: probe,
                                 "trend direction: app \(appDirection), oracle \(oracleTrend.direction)")
            }
            let appCurrentSeconds = appTrend.current.components.seconds
            let appPreviousSeconds = appTrend.previous.components.seconds
            if appCurrentSeconds != oracleTrend.currentSeconds {
                collector.record("T0-02", at: probe,
                                 "trend.current: app \(appCurrentSeconds), oracle \(oracleTrend.currentSeconds)")
            }
            if appPreviousSeconds != oracleTrend.previousSeconds {
                collector.record("T0-02", at: probe,
                                 "trend.previous: app \(appPreviousSeconds), oracle \(oracleTrend.previousSeconds)")
            }
        }

        // Decision 0050's stretch comparison — this stretch against the one before it —
        // held to the same standard, and it needs the presence check *more* than the
        // trend does. `.aboutTheSame` means the two sides can now disagree in a way the
        // trend never could: one saying "no comparison" while the other says "a
        // comparison that reads steady". Those are different sentences on screen, so
        // direction is compared as a three-way value rather than a boolean.
        let appStretch = PatternAnalysis.stretchComparison(for: contractions, now: now)
        let oracleStretch = OracleMath.stretchComparison(records: oracleRecords, now: probe)
        if (appStretch == nil) != (oracleStretch == nil) {
            collector.record("T0-03", at: probe,
                             "stretch comparison presence: app \(appStretch != nil), "
                                + "oracle \(oracleStretch != nil)")
        }
        if let appStretch, let oracleStretch {
            let appDirection: OracleStretchComparison.Direction = switch appStretch.direction {
            case .closer: .closer
            case .fartherApart: .fartherApart
            case .aboutTheSame: .aboutTheSame
            }
            if appDirection != oracleStretch.direction {
                collector.record("T0-02", at: probe,
                                 "stretch direction: app \(appDirection), oracle \(oracleStretch.direction)")
            }
            if appStretch.current.components.seconds != oracleStretch.currentSeconds {
                collector.record("T0-02", at: probe,
                                 "stretch.current: app \(appStretch.current.components.seconds), "
                                    + "oracle \(oracleStretch.currentSeconds)")
            }
            if appStretch.previous.components.seconds != oracleStretch.previousSeconds {
                collector.record("T0-02", at: probe,
                                 "stretch.previous: app \(appStretch.previous.components.seconds), "
                                    + "oracle \(oracleStretch.previousSeconds)")
            }
            // **Rebased to `t0` before comparing, and this is the one comparison in
            // this file that needs it.** Every other figure either side reports is a
            // *duration* — a mean, a span, a delta — and durations are the same number
            // in both clocks. `previousStart` is the first **instant** the two are ever
            // asked to agree on: the engine works in absolute `Date`s while the oracle
            // works in seconds since the scenario's own `t0`, so the raw values differ
            // by 1_800_000_000 on every scenario that has two stretches at all. The
            // first run of this check reported `app 1800000382, oracle 382` across
            // fifteen scenarios — a units disagreement wearing a correctness
            // disagreement's clothes.
            let appPreviousStart = Int64(appStretch.previousStartedAt.timeIntervalSince1970) - t0
            if appPreviousStart != oracleStretch.previousStart {
                collector.record("T0-02", at: probe,
                                 "stretch.previousStart: app \(appPreviousStart), "
                                    + "oracle \(oracleStretch.previousStart)")
            }
        }

        // T0-13 — staleness, asserted directly rather than left to fall out of the
        // empty-state comparison, so a run's results say which check caught it. The
        // running exception is decision 0022's: an episode with an open record cannot
        // be stale, so the check only speaks about episodes that have stopped.
        if oracle.running == nil, let latest = oracle.episode.last, probe - latest.start > 7200 {
            collector.record("T0-13", at: probe,
                             "episode \(probe - latest.start)s stale but still reporting")
        }
    }

    /// Checks that depend on the record set but not on `now`. Run once per change to
    /// the store rather than once per probe: between two taps these are a constant
    /// being recomputed a few hundred times.
    static func recordSet(
        contractions: [Contraction],
        oracle: [OracleRecord],
        at probe: Int64,
        into collector: inout ViolationCollector
    ) {
        // T0-06 — episode split exactness. Compared as a partition rather than as a
        // boundary rule so the check cannot pass by implementing the same off-by-one
        // as the thing it is checking.
        let appEpisodes = PatternAnalysis.episodes(contractions).map(\.count)
        let oracleEpisodes = OracleMath.episodes(oracle).map(\.count)
        if appEpisodes != oracleEpisodes {
            collector.record("T0-06", at: probe,
                             "episode partition: app \(appEpisodes), oracle \(oracleEpisodes)")
        }

        // T0-07 — suspect iff strictly over 180 s or strictly under 20 s (decision
        // 0032). Both bounds belong to the believable contraction: 180 s exactly and
        // 20 s exactly are real recordings, and the package tests probe both sides of
        // each. The literals are restated rather than read from
        // `Contraction.suspectDuration` and `.slipDuration` on purpose — this is the
        // referee leg, and a check that imports the number it is checking proves
        // nothing. They move only with a decision entry.
        for contraction in contractions {
            guard let endedAt = contraction.endedAt else { continue }
            let seconds = Int64(endedAt.timeIntervalSince(contraction.startedAt))
            if contraction.isSuspect != (seconds > 180 || seconds < 20) {
                collector.record("T0-07", at: probe,
                                 "suspect \(contraction.isSuspect) at \(seconds)s")
                break
            }
        }

        // T0-08 — end never precedes start, whatever the clock did.
        for contraction in contractions where contraction.endedAt.map({ $0 < contraction.startedAt }) == true {
            collector.record("T0-08", at: probe, "endedAt precedes startedAt")
            break
        }
    }

    // MARK: Field comparisons

    private static func compareInteger(
        _ app: Duration?, _ oracle: Int64?, _ name: String,
        at probe: Int64, into collector: inout ViolationCollector
    ) {
        switch (app, oracle) {
        case (nil, nil):
            return
        case let (value?, expected?):
            if abs(HarnessBridge.seconds(value) - Double(expected)) > exactEpsilonSeconds {
                collector.record("T0-02", at: probe,
                                 "\(name): app \(HarnessBridge.seconds(value)), oracle \(expected)")
            }
        default:
            collector.record("T0-03", at: probe,
                             "\(name) nil-ness: app \(app != nil), oracle \(oracle != nil)")
        }
    }

    private static func compareMean(
        _ app: Duration?, _ oracle: OracleMean?, _ name: String,
        at probe: Int64, into collector: inout ViolationCollector
    ) {
        switch (app, oracle) {
        case (nil, nil):
            return
        case let (value?, expected?):
            let exact = expected.count > 0
                && expected.sumSeconds % Int64(expected.count) == 0
            let limit = tolerance(forExactMean: exact)
            if abs(HarnessBridge.seconds(value) - expected.value) > limit {
                let actual = HarnessBridge.seconds(value)
                collector.record("T0-02", at: probe,
                                 "\(name): app \(actual), oracle mean \(expected.value)")
            }
        default:
            collector.record("T0-03", at: probe,
                             "\(name) nil-ness: app \(app != nil), oracle \(oracle != nil)")
        }
    }

    private static func compareSummary(
        _ app: EpisodeSummary?, _ oracle: OracleEpisodeSummary?,
        at probe: Int64, into collector: inout ViolationCollector
    ) {
        guard let app, let oracle else {
            if (app == nil) != (oracle == nil) {
                collector.record("T0-02", at: probe, "summary presence disagreement")
            }
            return
        }
        if app.count != oracle.count {
            collector.record("T0-02", at: probe,
                             "summary.count: app \(app.count), oracle \(oracle.count)")
        }
        compareInteger(app.span, oracle.spanSeconds, "summary.span", at: probe, into: &collector)
        compareMean(app.averageInterval, oracle.averageInterval,
                    "summary.averageInterval", at: probe, into: &collector)
        compareMean(app.averageDuration, oracle.averageDuration,
                    "summary.averageDuration", at: probe, into: &collector)
    }
}

// MARK: - The pure sweep

struct SweepOutcome {
    var collector: ViolationCollector
    var ticks: [ScenarioTick]
    var cadence: Int64
    var probeCount: Int
}

enum PureSweep {
    /// Walks one scenario's whole probe grid, comparing LaborKit against the oracle at
    /// every instant and recording the verdict tick series T1 is measured from.
    static func run(_ manifest: ScenarioManifest) -> SweepOutcome {
        let cadence = ReplayEngine.cadence(for: manifest)
        let probes = ReplayEngine.probeTimes(for: manifest, cadence: cadence)
        let rule = HarnessBridge.rule(manifest.rule)
        let oracleRule = HarnessBridge.oracleRule(manifest.rule)

        var collector = ViolationCollector(scenarioId: manifest.id, leg: .pure)
        var ticks: [ScenarioTick] = []
        ticks.reserveCapacity(probes.count)

        var cursor = ReplayEngine.Cursor(manifest.actions)
        var generation = -1
        var contractions: [Contraction] = []
        var oracleRecords: [OracleRecord] = []

        for probe in probes {
            let records = cursor.advance(to: probe)
            if cursor.generation != generation {
                generation = cursor.generation
                let ordered = ReplayEngine.sorted(records)
                contractions = HarnessBridge.contractions(ordered, t0: manifest.t0)
                oracleRecords = HarnessBridge.oracleRecords(ordered)
                HarnessCompare.recordSet(
                    contractions: contractions, oracle: oracleRecords,
                    at: probe, into: &collector
                )
            }

            let now = HarnessBridge.date(manifest.t0, probe)
            let app = PatternAnalysis.pattern(for: contractions, rule: rule, now: now)
            let oracle = OracleMath.pattern(records: oracleRecords, rule: oracleRule, now: probe)
            HarnessCompare.probe(
                app: app, oracle: oracle,
                contractions: contractions, oracleRecords: oracleRecords,
                rule: rule, oracleRule: oracleRule, now: now,
                at: probe, t0: manifest.t0, into: &collector
            )
            ticks.append(ScenarioTick(
                at: probe,
                state: HarnessBridge.verdictState(app),
                rawState: HarnessBridge.rawVerdictState(app)
            ))
        }

        // T0-05 — one spot-check per scenario rather than one per probe. Re-derivation
        // stability is a property of the function, not of the instant: if a shuffle
        // changes the answer anywhere it will change it at a probe with a full store,
        // and that is what this picks.
        if let probe = probes.last, !contractions.isEmpty {
            let now = HarnessBridge.date(manifest.t0, probe)
            let first = PatternAnalysis.pattern(for: contractions, rule: rule, now: now)
            let repeated = PatternAnalysis.pattern(for: contractions, rule: rule, now: now)
            if first != repeated {
                collector.record("T0-05", at: probe, "repeated call differs")
            }
            // A fixed reversal rather than a random shuffle: the sweep must be
            // reproducible, and a seeded shuffle here would be one more stream to keep
            // stable for no extra coverage — reversal already breaks any dependence on
            // input order.
            let reversed = PatternAnalysis.pattern(for: contractions.reversed(), rule: rule, now: now)
            if first != reversed {
                collector.record("T0-05", at: probe, "reversed input order differs")
            }
        }

        return SweepOutcome(
            collector: collector, ticks: ticks, cadence: cadence, probeCount: probes.count
        )
    }

    /// The pure leg's metrics, with the paired clean-sibling delta folded in where
    /// the scenario has one.
    static func metrics(_ manifest: ScenarioManifest, outcome: SweepOutcome) -> T1MetricSet {
        let base = T1Metrics.compute(
            ticks: outcome.ticks, truth: manifest.truth, rule: manifest.rule,
            noiseProfile: manifest.noiseProfile, cadence: outcome.cadence
        )
        guard let clean = CleanSiblings.metrics(for: manifest) else { return base }
        return T1Metrics.withNoiseDelta(base, clean: clean)
    }
}

// MARK: - Paired clean siblings

/// T1-05's other half. `ScenarioSeedRef` derives its seed from archetype and variant
/// alone, so the clean sibling of any scenario is the same ref with the thumb swapped
/// — same seed, same physiology stream, byte-identical `trueContractions`. Any
/// difference between the two runs is therefore the thumb and nothing else.
enum CleanSiblings {
    struct Key: Hashable {
        var archetype: ArchetypeID
        var paramVariant: Int
    }

    /// Computed once for the whole suite. Only the default rule is paired: the
    /// rule-coverage rows exist to exercise 4-1-1 and 3-1-1 thresholds, and pairing
    /// them would double the sweep to answer a question nobody asked of them.
    static let table: [Key: T1MetricSet] = {
        var keys: Set<Key> = []
        for ref in ScenarioCorpus.standard
        where ref.rule == ScenarioCorpus.defaultRule
            && ref.archetype != .boundaryBattery
            && ref.noiseProfile != .clean {
            keys.insert(Key(archetype: ref.archetype, paramVariant: ref.paramVariant))
        }

        var table: [Key: T1MetricSet] = [:]
        for key in keys {
            let manifest = ScenarioCorpus.generate(ScenarioSeedRef(
                archetype: key.archetype, paramVariant: key.paramVariant,
                noiseProfile: .clean, run: 0, rule: ScenarioCorpus.defaultRule
            ))
            let outcome = PureSweep.run(manifest)
            table[key] = T1Metrics.compute(
                ticks: outcome.ticks, truth: manifest.truth, rule: manifest.rule,
                noiseProfile: NoiseProfileID.clean.rawValue, cadence: outcome.cadence
            )
        }
        return table
    }()

    static func metrics(for manifest: ScenarioManifest) -> T1MetricSet? {
        guard manifest.rule == ScenarioCorpus.defaultRule,
              manifest.noiseProfile != NoiseProfileID.clean.rawValue,
              let archetype = ArchetypeID(rawValue: manifest.archetype)
        else { return nil }
        return table[Key(archetype: archetype, paramVariant: manifest.paramVariant)]
    }
}

// MARK: - The store/model subsample

/// The ~60 scenarios the two SwiftData legs run.
///
/// A container-backed replay is two orders of magnitude slower than the pure fold, so
/// the sample is chosen rather than sliced: every archetype at least once, every noise
/// profile at least once, and every adversarial store scenario in full — those are
/// where the store's bookkeeping is actually under test, and sampling them would be
/// sampling the point.
enum ReplaySubsample {
    static let refs: [ScenarioSeedRef] = {
        var picked: [ScenarioSeedRef] = []
        var seenArchetypes: Set<ArchetypeID> = []
        var seenProfiles: Set<NoiseProfileID> = []

        // One row per (archetype, profile) pair walking the base corpus in order, so
        // the sample is deterministic and re-derivable from the corpus alone.
        for ref in ScenarioCorpus.base {
            let newArchetype = !seenArchetypes.contains(ref.archetype)
            let newProfile = !seenProfiles.contains(ref.noiseProfile)
            guard newArchetype || newProfile else { continue }
            seenArchetypes.insert(ref.archetype)
            seenProfiles.insert(ref.noiseProfile)
            picked.append(ref)
        }

        // Every archetype under the two hardest thumbs. One draw of a probabilistic
        // noise model is an anecdote, and these two are where the undo, kill and
        // clock-set collisions the store leg exists to test actually occur.
        for ref in ScenarioCorpus.base
        where (ref.noiseProfile == .chaotic && ref.paramVariant == 1)
            || (ref.noiseProfile == .clockHostile && ref.paramVariant == 2) {
            picked.append(ref)
        }

        // The stricter rules, so the store leg is not only ever exercised at 300 s.
        picked.append(contentsOf: ScenarioCorpus.ruleCoverage.prefix(4))

        // Everything hand-authored to abuse the store.
        picked.append(contentsOf: ScenarioCorpus.battery.filter { ref in
            BoundaryBattery.all[ref.paramVariant].id.hasPrefix("boundaryBattery-adv")
        })

        var seenIds: Set<String> = []
        return picked.filter { seenIds.insert($0.id).inserted }
    }()
}
