import Foundation

// T1: how good the verdict was, not whether the arithmetic was right. T0 asks
// "does the engine agree with the referee"; this asks "did the app say the useful
// thing at the useful time", measured against what the body actually did. Nothing
// here can fail a test — RUBRIC §1 is explicit that a threshold breach is a finding
// for a human to rank, and a suite that went red on verdict *quality* would be a
// suite nobody could keep green while the product still had trade-offs in it.

/// What the screen is showing at one instant, reduced to the three states a user can
/// distinguish: no verdict at all, a partial verdict, or the rule met.
///
/// Spelled `noVerdict` rather than `none`: a bare `.none` in any inferred position is
/// also `Optional.none`, and asking the type checker to disambiguate that in every
/// tick literal across the suite costs minutes of compile time for no clarity at all.
/// The rubric's word survives as the raw value, which is what the JSON carries.
public enum VerdictState: String, Codable, Sendable, Equatable {
    /// No guideline status renders — the evidence floors are unmet.
    case noVerdict = "none"
    /// A status renders but at least one dimension is unmet.
    case partial
    /// All three dimensions met.
    case met
}

/// One grid point of the engine's answer. Deliberately tiny: the sweep builds one of
/// these per probe across four hundred scenarios, and anything richer would cost more
/// memory than the measurement is worth.
public struct ScenarioTick: Sendable, Equatable {
    public var at: Int64
    /// What the screen showed — the latched verdict (decision 0025). Every T1 metric
    /// that describes the reader's experience keys on this.
    public var state: VerdictState
    /// The unlatched verdict underneath it. Kept so `rawFlaps` can quantify how much
    /// churn the latch is absorbing; the calibration that justifies the ten minutes
    /// is worthless if the raw signal stops being recorded.
    public var rawState: VerdictState

    public init(at: Int64, state: VerdictState, rawState: VerdictState? = nil) {
        self.at = at
        self.state = state
        self.rawState = rawState ?? state
    }
}

public enum T1Metrics {

    // MARK: Thresholds (RUBRIC §1, T1 table)

    /// T1-01. Ten minutes under the impossible-ideal thumb, twenty under any real
    /// one — a noisy record earns some latitude, an engine fed perfect taps does not.
    public static let onsetLagCleanSeconds: Int64 = 10 * 60
    public static let onsetLagNoisySeconds: Int64 = 20 * 60

    /// T1-01 (F-0018). The symmetric half of onset lag: firing more than fifteen
    /// minutes before truth's first `mustFire` is an early fire worth naming. One
    /// threshold regardless of noise profile — unlike late lag, early firing is not
    /// latitude for a noisy thumb to earn, it is the app forming an opinion truth
    /// has not yet asserted, and that call is judged by where it lands (`compute`),
    /// not by how noisy the taps were.
    public static let earlyFireThresholdSeconds: Int64 = 15 * 60

    /// T1-03. A truth-met stretch shorter than this is not yet a suppression; it is
    /// the app being slow, which T1-01 already measures.
    public static let suppressionZoneSeconds: Int64 = 30 * 60

    /// T1-04. Both halves of the flap threshold.
    public static let flapWindowSeconds: Int64 = 30 * 60
    public static let flapsPerWindowLimit = 2
    public static let bannerChurnPerHourLimit: Double = 6

    /// T1-05. One suspect or one miss moving onset by more than this is the paired
    /// comparison's whole point.
    public static let noiseDeltaOnsetSeconds: Int64 = 15 * 60

    /// T1-06. The floors' tolerated cost.
    public static let floorStarvationSeconds: Int64 = 30 * 60

    /// T1-02. Decision 0025's ten-minute latch-release window, restated here (this
    /// package cannot import the app target) because a latched-only met tick landing
    /// inside it, right after a genuine `mustFire` zone closed, is the decided
    /// behaviour arriving on schedule rather than a false positive. Must move if
    /// 0025's ten minutes ever does.
    public static let latchReleaseSeconds: Int64 = 10 * 60

    // MARK: - Computation

    /// Measures one scenario's tick series against its own truth timeline.
    ///
    /// `cadence` is the periodic grid spacing, and it is needed rather than inferable:
    /// false-met *seconds* weight each offending tick by the span it stands for, and
    /// the boundary probes sit one second apart while the sweep sits sixty. Weighting
    /// by the raw gap to the next probe would let a single tick before a long quiet
    /// stretch absorb the whole stretch.
    public static func compute(
        ticks: [ScenarioTick],
        truth: TruthTimeline,
        rule: String,
        noiseProfile: String,
        cadence: Int64
    ) -> T1MetricSet {
        let zones = truth.zones.filter { $0.rule == rule }.sorted { $0.from < $1.from }
        let truthFirstMet = zones.first(where: { $0.kind == .mustFire })?.from
        let appFirstMet = ticks.first(where: { $0.state == .met })?.at
        let floorsFirstSatisfied = ticks.first(where: { $0.state != .noVerdict })?.at

        var flags: [String] = []

        // T1-01 — plain difference, sign preserved. An app that fires *before* truth
        // is not "early by -8 minutes of lag"; it is a false positive, and T1-02
        // below is the check that says so. Recording the negative keeps the two
        // events distinguishable in the report instead of collapsing them.
        var onsetLag: Int64?
        if let truthFirstMet, let appFirstMet {
            onsetLag = appFirstMet - truthFirstMet
            let limit = noiseProfile == NoiseProfileID.clean.rawValue
                ? onsetLagCleanSeconds : onsetLagNoisySeconds
            if appFirstMet - truthFirstMet > limit { flags.append("T1-01") }
        }

        // T1-01 (F-0018) — the symmetric half of onset lag, named only where it is
        // not defensible. Every app-met tick strictly before truth's first mustFire
        // that grades gray, or falls in no zone at all, is a judgement call the
        // harness has no standing to fault — truth asserts nothing there. A tick
        // inside mustNotFire is different: T1-02 below already condemns it, and
        // naming it here too is what lets a report tell "fired early into ambiguity"
        // apart from "fired early into a stretch truth condemns" instead of
        // collapsing both into the same silence. Magnitude is recorded whenever the
        // threshold is cleared; the flag fires only for the second case.
        var earlyFireSeconds: Int64?
        var earlyFireGraded: String?
        if let truthFirstMet, let appFirstMet, appFirstMet < truthFirstMet {
            let magnitude = truthFirstMet - appFirstMet
            if magnitude > earlyFireThresholdSeconds {
                earlyFireSeconds = magnitude
                let earlyMetTicks = ticks.filter { $0.state == .met && $0.at < truthFirstMet }
                let anyMustNotFire = earlyMetTicks.contains { zoneKind(zones, at: $0.at) == .mustNotFire }
                earlyFireGraded = anyMustNotFire ? "mustNotFire" : "gray"
                if anyMustNotFire { flags.append("T1-01") }
            }
        }

        // T1-02 — any met tick inside a mustNotFire zone, with one latch-aware
        // exemption: decision 0025 holds a verdict for ten minutes after the raw one
        // drops, so a latched-only met tick (`state == .met && rawState != .met`)
        // landing inside that window, right after a genuine mustFire zone for this
        // rule closed, is the decided behaviour arriving on schedule — not the app
        // getting it wrong. Grade that tick gray instead: excluded from the false-met
        // count but still tallied in `latchGracedTicks` so it stays a visible fact.
        // The exemption is narrow on purpose — it only covers the latch holding a
        // verdict truth had just endorsed. A latched-only tick with no qualifying
        // mustFire exit in the last ten minutes, and any tick where the *raw* verdict
        // itself reads met (`rawState == .met`), are condemned exactly as before:
        // there truth, not the latch, is the one saying the app is wrong.
        var falseMetTicks = 0
        var falseMetSeconds: Int64 = 0
        var latchGracedTicks = 0
        for (index, tick) in ticks.enumerated() where tick.state == .met {
            guard zoneKind(zones, at: tick.at) == .mustNotFire else { continue }
            let latchedOnly = tick.rawState != .met
            if latchedOnly, withinLatchRelease(zones, at: tick.at) {
                latchGracedTicks += 1
                continue
            }
            falseMetTicks += 1
            let next = index + 1 < ticks.count ? ticks[index + 1].at : tick.at + 1
            falseMetSeconds += min(max(0, next - tick.at), cadence)
        }
        if falseMetTicks > 0 { flags.append("T1-02") }

        // T1-03 — S4, and the reason it outranks every lag figure: the app was silent
        // through a stretch where truth was unambiguously met for half an hour.
        var suppressed = false
        var suppressedZoneSeconds: Int64?
        for zone in zones where zone.kind == .mustFire {
            let length = zone.to - zone.from + 1
            guard length >= suppressionZoneSeconds else { continue }
            let fired = ticks.contains { $0.at >= zone.from && $0.at <= zone.to && $0.state == .met }
            if !fired {
                suppressed = true
                suppressedZoneSeconds = max(suppressedZoneSeconds ?? 0, length)
            }
        }
        if suppressed { flags.append("T1-03") }

        // T1-04 — a flap is the verdict dropping while the body has not changed its
        // mind. Counted only inside mustFire, because dropping out of a gray zone is
        // the engine being honest about a borderline pattern, not churn.
        //
        // Keyed on the presented state (decision 0025 §4): a flap is a defect because
        // of what it does to the reader — the banner leaving, the screen reordering
        // under a thumb mid-contraction — so the counter measures the state the
        // reader saw. `rawFlaps` records the same count over the unlatched verdict,
        // which is what says whether the latch is doing anything.
        // Flap attribution: where the churn actually goes. `current.state` is not
        // `.met` by construction here, so it is always exactly one of `.noVerdict` or
        // `.partial` — the two counters below partition `flapTimes` completely, and
        // their sum equals `flapCount` by construction rather than by coincidence.
        // The split is what makes 0025's residual (F-0009: 54 of 69 flaps were the
        // status disappearing, only 15 a dimension wobbling) checkable per run rather
        // than re-diagnosed by hand every time the latch moves.
        var flapTimes: [Int64] = []
        var flapToNoVerdict = 0
        var flapToPartial = 0
        var rawFlaps = 0
        var churn = 0
        for index in 1..<max(1, ticks.count) {
            let previous = ticks[index - 1]
            let current = ticks[index]
            if previous.state != current.state { churn += 1 }
            if previous.state == .met, current.state != .met,
               zoneKind(zones, at: current.at) == .mustFire {
                flapTimes.append(current.at)
                switch current.state {
                case .noVerdict: flapToNoVerdict += 1
                case .partial: flapToPartial += 1
                case .met: break // unreachable: current.state != .met above
                }
            }
            if previous.rawState == .met, current.rawState != .met,
               zoneKind(zones, at: current.at) == .mustFire {
                rawFlaps += 1
            }
        }
        let worstFlaps = densest(flapTimes, window: flapWindowSeconds)
        let spanSeconds = (ticks.last?.at ?? 0) - (ticks.first?.at ?? 0)
        let churnPerHour = spanSeconds > 0 ? Double(churn) * 3600 / Double(spanSeconds) : 0
        if worstFlaps > flapsPerWindowLimit || churnPerHour > bannerChurnPerHourLimit {
            flags.append("T1-04")
        }

        // T1-06 — how much of the onset lag is the floors rather than the body. Only
        // meaningful once truth has actually fired.
        var starvation: Int64?
        if let truthFirstMet, let floorsFirstSatisfied {
            starvation = floorsFirstSatisfied - truthFirstMet
            if floorsFirstSatisfied - truthFirstMet > floorStarvationSeconds { flags.append("T1-06") }
        }

        return T1MetricSet(
            onsetLagSeconds: onsetLag,
            truthFirstMetAt: truthFirstMet,
            appFirstMetAt: appFirstMet,
            earlyFireSeconds: earlyFireSeconds,
            earlyFireGraded: earlyFireGraded,
            falseMetTicks: falseMetTicks,
            falseMetSeconds: falseMetSeconds,
            latchGracedTicks: latchGracedTicks,
            suppressed: suppressed,
            suppressedZoneSeconds: suppressedZoneSeconds,
            flapCount: flapTimes.count,
            flapToNoVerdict: flapToNoVerdict,
            flapToPartial: flapToPartial,
            rawFlaps: rawFlaps,
            worstFlapsIn30Minutes: worstFlaps,
            bannerChurnPerHour: churnPerHour,
            floorStarvationSeconds: starvation,
            flags: flags
        )
    }

    /// T1-05. Folds the paired comparison against the same-physiology clean sibling
    /// into an already-computed metric set.
    ///
    /// The pairing is what makes the number mean anything: both runs are the *same
    /// labor*, so any difference between them is the thumb, never the body.
    public static func withNoiseDelta(_ noisy: T1MetricSet, clean: T1MetricSet) -> T1MetricSet {
        var result = noisy
        var flags = noisy.flags

        if let noisyOnset = noisy.onsetLagSeconds, let cleanOnset = clean.onsetLagSeconds {
            let delta = noisyOnset - cleanOnset
            result.noiseDeltaOnsetSeconds = delta
            if abs(delta) > noiseDeltaOnsetSeconds { flags.append("T1-05") }
        }
        result.noiseDeltaFlaps = noisy.flapCount - clean.flapCount

        // "Suppressing outright" is the severe half of T1-05 and is not a delta at
        // all: the clean thumb got the verdict, this one never did.
        let newlySuppressed = noisy.suppressed && !clean.suppressed
        result.noiseSuppressedButCleanDidNot = newlySuppressed
        if newlySuppressed, !flags.contains("T1-05") { flags.append("T1-05") }

        result.flags = flags
        result.flagged = !flags.isEmpty
        return result
    }

    // MARK: - Helpers

    /// The zone covering `time`, by binary search — the sweep asks this once per met
    /// tick across four hundred scenarios, and a linear scan over a few hundred zones
    /// is the difference between a fast suite and a slow one.
    static func zoneKind(_ zones: [TruthZone], at time: Int64) -> TruthZoneKind? {
        var low = 0
        var high = zones.count - 1
        while low <= high {
            let mid = (low + high) / 2
            if time < zones[mid].from {
                high = mid - 1
            } else if time > zones[mid].to {
                low = mid + 1
            } else {
                return zones[mid].kind
            }
        }
        return nil
    }

    /// True when `time` sits within `latchReleaseSeconds` of the end of some
    /// `mustFire` zone (for this rule) that closed at or before `time` — decision
    /// 0025's window for the latch to still be holding a verdict truth itself had
    /// just endorsed. Only asked for latched-only ticks found inside `mustNotFire`,
    /// which are rare enough that a linear scan of the (already rule-filtered) zone
    /// list costs nothing measurable — `zoneKind` above earns its binary search by
    /// running on every met tick across four hundred scenarios; this does not.
    static func withinLatchRelease(_ zones: [TruthZone], at time: Int64) -> Bool {
        zones.contains { zone in
            zone.kind == .mustFire && zone.to <= time && time - zone.to <= latchReleaseSeconds
        }
    }

    /// The most events any `window`-second span contains. Sorted input, two pointers.
    static func densest(_ times: [Int64], window: Int64) -> Int {
        guard !times.isEmpty else { return 0 }
        let ordered = times.sorted()
        var best = 0
        var low = 0
        for high in ordered.indices {
            while ordered[high] - ordered[low] > window { low += 1 }
            best = max(best, high - low + 1)
        }
        return best
    }
}
