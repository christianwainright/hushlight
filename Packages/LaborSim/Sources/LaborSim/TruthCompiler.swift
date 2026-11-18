import Foundation

/// The clinical-intent oracle (decision 0021, oracle #2).
///
/// It reads the **noise-free true stream** — what the body did, before any thumb
/// touched a button — and answers a different question from the mathematical
/// oracle. `LaborOracle` asks "given these taps, is the arithmetic right?".
/// This asks "given this labor, *should* the app have said something?". The gap
/// between the two is the product metric: onset lag, false-met minutes,
/// suppression.
///
/// ## Why three zones and not a boolean
///
/// At any instant the true frequency share, mean duration, and sustainment are
/// some real numbers. If truth were a boolean, an instant where the frequency
/// share sits at exactly 4-of-6 would make a verdict either mandatory or
/// forbidden on the strength of one interval's sampling luck — and the harness
/// would file findings that are really rounding. So truth asserts only where it
/// has margin on every dimension (below). The band between `mustFire` and
/// `mustNotFire` is `gray`, where the harness asserts nothing and either answer
/// is defensible.
///
/// ## Why hysteresis
///
/// A five-minute blip that touches the threshold and retreats is not a labor
/// meeting the rule; it is noise in the body. A `mustFire` zone therefore opens
/// only after the raw condition has held continuously for ten minutes, and a run
/// shorter than that is demoted to `gray` rather than to `mustNotFire` — it was
/// close, and truth should not claim the app was wrong to notice.
///
/// ## Decision alignment, not engine import (F-0014, F-0028)
///
/// Every margin below is truth's own constant, restated here rather than taken
/// from `PatternAnalysis` or `OracleMath` — but the *kind* of statistic each
/// margin brackets has to track whatever the product decided, because judging a
/// share against a mean-shaped margin does not measure a regression, it measures
/// the distance between two statistics (F-0028: 12 of 18 false-mets in the wave-C
/// run were truth still holding the mean decision 0024 replaced). Decision 0024
/// made frequency a share; decision 0023 moved the duration boolean's threshold
/// and defined the bridging interval basis; decision 0026 added sustained
/// continuity. Truth follows each, on its own terms:
///
/// **Frequency is a share margined on both sides**, not a mean margined on one.
/// `mustFire` needs at least two-thirds of the in-window start-to-start
/// intervals at or under `threshold − 15 s`; `mustNotFire` needs at most
/// one-half at or under `threshold + 15 s` — both compared as integer counts
/// (`within × 3 ≥ total × 2`, `within × 2 ≤ total`) rather than by forming a
/// quotient, the same discipline the engine uses to decide the exact 4-of-6
/// case without a `Double`'s rounding of 0.666…. The two shapes are not mirror
/// images on purpose: the engine's own boolean is "≥ 2/3 at exactly the
/// threshold," so silence is a defect only when a comfortable supermajority of
/// gaps beat the threshold with 15 s to spare, and a verdict is a defect only
/// when even a generous reading of the threshold cannot get half the gaps under
/// it. Everything between is gray — which is where a share sitting near its own
/// 2/3 boundary belongs. 15 s is retained from the old mean-based margin: it is
/// roughly the swing one contraction landing early or late produces in a
/// six-contraction hour. The in-window intervals use the **bridging basis**
/// decision 0023 §3 defines — an interval whose *later* endpoint starts
/// in-window belongs to the window, so `n` in-window contractions yield `n`
/// intervals whenever anything precedes the window, and `n−1` only at the very
/// start of an episode. This is restated here, not imported: truth must
/// partition the same hour the decision defines, or the two disagree about the
/// window rather than about the labor.
///
/// **Duration margins bracket the threshold the boolean actually reads.** The
/// evidence threshold `PatternAnalysis` compares against is 50 s
/// (`durationEvidenceThreshold`, decision 0023 §1), not the 60 s the rule's copy
/// quotes. The old margins (65 s / 55 s) straddled 60 s, which left the
/// `mustNotFire` ceiling *above* the boolean's own threshold — a faithful thumb
/// recording a true 50–55 s pattern read as a false met by construction, because
/// truth was still condemning what the engine now allows (F-0028's second
/// cluster, four scenarios). Margins are now symmetric around 50 s: `mustFire`
/// at ≥ 55 s, `mustNotFire` at ≤ 45 s — decision 0023's amendment ratifies this
/// exact pairing.
///
/// **Sustained gains continuity on one side only.** `mustFire` now also requires
/// that no in-window start-to-start gap exceed 3× the rule's interval threshold
/// (decision 0026) — a true hour with a hole in it is not a sustained pattern,
/// so truth will not call the app's silence a defect there. `mustNotFire` does
/// **not** gain the mirror clause: truth demands margin before it condemns, and
/// a broken pattern is a reason to stop demanding a verdict, not an automatic
/// reason to forbid one. A broken hour therefore lands in `gray`, never
/// `mustNotFire` — evidence for silence is not evidence against a verdict.
public enum TruthCompiler {

    // MARK: Margins

    /// The margin either side of the rule's threshold that decides which
    /// in-window intervals count toward the frequency share — see the header
    /// for why the two clauses use it asymmetrically, and why 15 s.
    public static let intervalMarginSeconds: Double = 15

    /// Duration margins bracket the 50 s evidence threshold the boolean
    /// actually reads (decision 0023 §1), not the stated 60 s rule — see the
    /// header for why the old 65/55 pair was wrong once the boolean moved.
    public static let mustFireDurationSeconds: Double = 55
    public static let mustNotFireDurationSeconds: Double = 45

    /// Decision 0026: a sustained `mustFire` pattern must not contain an
    /// in-window gap wider than this multiple of the rule's own interval
    /// threshold — 900 s at 5-1-1, 720 at 4-1-1, 540 at 3-1-1. `mustNotFire`
    /// does not read this constant; see the header for the asymmetry.
    public static let sustainedContinuityMultiplier: Double = 3

    /// The rule's hour, plus and minus five minutes.
    public static let mustFireSustainedSeconds: Int64 = 65 * 60
    public static let mustNotFireSustainedSeconds: Int64 = 55 * 60

    /// The engine's own evidence floor is 6; truth demands the same before it will
    /// call silence a defect, and calls fewer than 5 clearly insufficient.
    public static let mustFireCountFloor = 6
    public static let mustNotFireCountFloor = 5

    /// How long the raw condition must persist before a `mustFire` zone opens.
    public static let hysteresisSeconds: Int64 = 600

    /// The engine's constants, restated here rather than imported. This oracle is
    /// judging LaborKit; taking its numbers from LaborKit would make a changed
    /// constant self-approving.
    public static let windowSeconds: Int64 = 3600
    public static let episodeGapSeconds: Int64 = 7200

    static func intervalThreshold(forRule raw: String) -> Double {
        switch raw {
        case "fiveOneOne": 300
        case "fourOneOne": 240
        case "threeOneOne": 180
        default: 300
        }
    }

    // MARK: - True episodes

    /// The true stream's own episode split, on the same >2 h start-to-start gap the
    /// engine uses. Exactly 7200 s stays one episode.
    public static func trueEpisodes(_ stream: [TrueContraction]) -> [TruthSpan] {
        let ordered = stream.sorted { $0.start < $1.start }
        guard let first = ordered.first else { return [] }

        var spans: [TruthSpan] = []
        var episodeStart = first.start
        var previousStart = first.start
        var episodeEnd = first.end

        for contraction in ordered.dropFirst() {
            if contraction.start - previousStart > episodeGapSeconds {
                spans.append(TruthSpan(start: episodeStart, end: episodeEnd))
                episodeStart = contraction.start
            }
            previousStart = contraction.start
            episodeEnd = max(episodeEnd, contraction.end)
        }
        spans.append(TruthSpan(start: episodeStart, end: episodeEnd))
        return spans
    }

    // MARK: - Instantaneous classification

    /// What the true stream looked like at one instant, as the app would have been
    /// able to see it: contractions that have *started* count toward the window and
    /// its intervals; only contractions that have *ended* contribute a duration.
    /// (True durations cap at 150 s by construction, so none is ever suspect — every
    /// suspect in the corpus is provably the noise model's work.)
    struct Snapshot {
        var count: Int
        /// In-window start-to-start intervals, bridging basis (see header). May
        /// be shorter than `count` at the very start of an episode, where there
        /// is nothing before the window to bridge from.
        var intervals: [Double]
        var meanDuration: Double?
        var sustainedSeconds: Int64
        var stale: Bool
    }

    static func snapshot(_ ordered: [TrueContraction], rule: String, at now: Int64) -> Snapshot {
        let started = ordered.prefix { $0.start <= now }
        guard let last = started.last else {
            return Snapshot(count: 0, intervals: [], meanDuration: nil,
                            sustainedSeconds: 0, stale: true)
        }

        // Stale by the engine's own rule: an episode whose last start is more than
        // the gap ago is history, not a pattern.
        if now - last.start > episodeGapSeconds {
            return Snapshot(count: 0, intervals: [], meanDuration: nil,
                            sustainedSeconds: 0, stale: true)
        }

        // The live episode only.
        var episodeStartIndex = 0
        for index in 1..<max(1, started.count)
        where started[index].start - started[index - 1].start > episodeGapSeconds {
            episodeStartIndex = index
        }
        let episode = Array(started[episodeStartIndex...])
        let episodeStart = episode[0].start

        let windowStartIndex = episode.firstIndex { $0.start >= now - windowSeconds } ?? episode.count
        let window = Array(episode[windowStartIndex...])

        // Bridging basis (decision 0023 §3, restated rather than imported — see
        // header): the record immediately before the window contributes the
        // interval that reaches into it, so `n` in-window records yield `n`
        // intervals whenever a predecessor exists, and `n−1` only at the very
        // start of an episode, where there is nothing to bridge from. The same
        // set feeds the frequency share and 0026's continuity check below, so
        // "in-window interval" has one definition here too.
        var intervals: [Double] = []
        if windowStartIndex > 0, let firstWindow = window.first {
            intervals.append(Double(firstWindow.start - episode[windowStartIndex - 1].start))
        }
        if window.count >= 2 {
            for index in 1..<window.count {
                intervals.append(Double(window[index].start - window[index - 1].start))
            }
        }

        let durations = window.filter { $0.end <= now }.map { Double($0.end - $0.start) }

        return Snapshot(
            count: window.count,
            intervals: intervals,
            meanDuration: durations.count >= 3
                ? durations.reduce(0, +) / Double(durations.count) : nil,
            sustainedSeconds: now - episodeStart,
            stale: false
        )
    }

    /// The raw, pre-hysteresis verdict at one instant.
    public static func classify(
        trueStream: [TrueContraction], rule: String, at now: Int64
    ) -> TruthZoneKind {
        let ordered = trueStream.sorted { $0.start < $1.start }
        return classify(ordered: ordered, rule: rule, at: now).kind
    }

    /// Classification plus, for a `mustNotFire` instant, which clause is doing
    /// the condemning. The two are computed together because attribution needs
    /// the same clause evaluations classification does — recomputing them
    /// separately would risk the two silently disagreeing.
    struct Classification {
        var kind: TruthZoneKind
        var reason: TruthZoneReason?
    }

    static func classify(ordered: [TrueContraction], rule: String, at now: Int64) -> Classification {
        let threshold = intervalThreshold(forRule: rule)
        let snap = snapshot(ordered, rule: rule, at: now)
        let intervals = snap.intervals

        // The existing floor: a lone interval (or none) cannot support a share
        // in either direction, so neither frequency clause may assert below two.
        let hasIntervalEvidence = intervals.count >= 2

        let fireWithin = intervals.filter { $0 <= threshold - intervalMarginSeconds }.count
        let mustFireFrequency = hasIntervalEvidence && fireWithin * 3 >= intervals.count * 2

        let notFireWithin = intervals.filter { $0 <= threshold + intervalMarginSeconds }.count
        let mustNotFireFrequency = hasIntervalEvidence && notFireWithin * 2 <= intervals.count

        // Decision 0026, mustFire only (see header for the asymmetry). Vacuously
        // true when there is no interval to break, which is harmless because
        // `mustFireFrequency` is already false whenever `intervals` is that short.
        let maxGap = intervals.max() ?? 0
        let continuityHolds = maxGap <= sustainedContinuityMultiplier * threshold

        if snap.count >= mustFireCountFloor,
           mustFireFrequency,
           let meanDuration = snap.meanDuration, meanDuration >= mustFireDurationSeconds,
           snap.sustainedSeconds >= mustFireSustainedSeconds,
           continuityHolds {
            return Classification(kind: .mustFire, reason: nil)
        }

        // Precedence when several mustNotFire clauses hold at once: evidence
        // before statistics. Count and sustainment are floors on whether truth
        // has enough to speak at all; frequency and duration are what it says
        // once it does. First match wins, so attribution is deterministic.
        if snap.count < mustNotFireCountFloor {
            return Classification(kind: .mustNotFire, reason: .count)
        }
        if snap.sustainedSeconds < mustNotFireSustainedSeconds {
            return Classification(kind: .mustNotFire, reason: .sustained)
        }
        if mustNotFireFrequency {
            return Classification(kind: .mustNotFire, reason: .frequency)
        }
        if let meanDuration = snap.meanDuration, meanDuration <= mustNotFireDurationSeconds {
            return Classification(kind: .mustNotFire, reason: .duration)
        }

        return Classification(kind: .gray, reason: nil)
    }

    // MARK: - Compilation

    /// Every instant at which the classification can possibly change.
    ///
    /// Ticking a 16-hour labor second by second is ~57 000 evaluations per rule for
    /// no information: between two of these breakpoints the window's membership is
    /// fixed and every statistic with it, and the only continuously-varying term —
    /// sustainment — crosses its two thresholds at points listed here explicitly.
    /// So the classification is constant on each open interval, and evaluating one
    /// instant per interval is exact rather than approximate.
    ///
    /// The frequency share, the duration mean, and 0026's continuity clause are
    /// all functions of one finite set — which contractions are in the window,
    /// and which of those have ended — so none of them needs a breakpoint of its
    /// own: each one's value can only step at a contraction entering the window,
    /// leaving it, or finishing, and all three are already listed below.
    static func breakpoints(_ ordered: [TrueContraction], horizon: Int64) -> [Int64] {
        var points = Set<Int64>()
        for contraction in ordered {
            points.insert(contraction.start)          // enters the window
            points.insert(contraction.end)            // its duration becomes known
            points.insert(contraction.start + windowSeconds + 1)   // leaves the window
            points.insert(contraction.start + episodeGapSeconds + 1) // goes stale
        }
        for span in trueEpisodes(ordered) {
            points.insert(span.start + mustNotFireSustainedSeconds)
            points.insert(span.start + mustFireSustainedSeconds)
        }
        if let first = ordered.first { points.insert(first.start) }
        points.insert(horizon)
        return points.filter { $0 >= 0 && $0 <= horizon }.sorted()
    }

    /// Compiles ground truth for one true stream against one or more rules.
    ///
    /// `fizzleTimes` is supplied by the caller from the physiology plan rather than
    /// inferred here: whether a bout *died out* is a fact about the model that
    /// produced it, and re-deriving it from the emitted stream would be guesswork
    /// dressed as measurement.
    public static func compile(
        trueStream: [TrueContraction],
        rules: [String],
        fizzleTimes: [Int64] = [],
        horizon: Int64? = nil
    ) -> TruthTimeline {
        let ordered = trueStream.sorted { $0.start < $1.start }
        let episodes = trueEpisodes(ordered)
        guard let last = ordered.last else {
            return TruthTimeline(events: rules.map {
                TruthEvent(type: .neverQualifies, rule: $0)
            })
        }
        let end = horizon ?? (last.end + episodeGapSeconds)

        var zones: [TruthZone] = []
        var events: [TruthEvent] = []

        for rule in rules {
            let (ruleZones, ruleEvents) = compileOne(ordered: ordered, rule: rule, horizon: end)
            zones.append(contentsOf: ruleZones)
            events.append(contentsOf: ruleEvents)
        }

        // Episode boundaries are rule-independent: they are where "how long has this
        // been happening" resets, whatever anyone is timing against.
        for span in episodes.dropFirst() {
            events.append(TruthEvent(type: .episodeBoundaryTrue, at: span.start))
        }
        for time in fizzleTimes {
            events.append(TruthEvent(type: .fizzle, at: time))
        }

        return TruthTimeline(
            episodesTrue: episodes,
            zones: zones,
            events: events,
            expectedSuspects: []   // filled by the caller from the replayed fold
        )
    }

    static func compileOne(
        ordered: [TrueContraction], rule: String, horizon: Int64
    ) -> ([TruthZone], [TruthEvent]) {
        let points = breakpoints(ordered, horizon: horizon)
        guard points.count >= 2 else { return ([], [TruthEvent(type: .neverQualifies, rule: rule)]) }

        // Raw segments: [from, to] inclusive, constant classification — and, for
        // mustNotFire runs, constant attribution, since two adjacent instants
        // condemned by different clauses are not the same finding and must not
        // silently merge into one.
        var raw: [(kind: TruthZoneKind, reason: TruthZoneReason?, from: Int64, to: Int64)] = []
        for index in 0..<(points.count - 1) {
            let from = points[index]
            let to = points[index + 1] - 1
            guard to >= from else { continue }
            let classification = classify(ordered: ordered, rule: rule, at: from)
            if var lastSegment = raw.last,
               lastSegment.kind == classification.kind, lastSegment.reason == classification.reason {
                lastSegment.to = to
                raw[raw.count - 1] = lastSegment
            } else {
                raw.append((classification.kind, classification.reason, from, to))
            }
        }

        // Hysteresis: a mustFire run shorter than the dwell never opens a zone, and
        // one that survives it opens `hysteresisSeconds` late. Demoted runs become
        // gray, not mustNotFire — they were close, and truth will not call the app
        // wrong for noticing.
        var zones: [TruthZone] = []
        for segment in raw {
            guard segment.kind == .mustFire else {
                zones.append(TruthZone(rule: rule, kind: segment.kind,
                                       from: segment.from, to: segment.to, reason: segment.reason))
                continue
            }
            let opensAt = segment.from + hysteresisSeconds
            if opensAt > segment.to {
                zones.append(TruthZone(rule: rule, kind: .gray, from: segment.from, to: segment.to))
            } else {
                zones.append(TruthZone(rule: rule, kind: .gray,
                                       from: segment.from, to: opensAt - 1))
                zones.append(TruthZone(rule: rule, kind: .mustFire,
                                       from: opensAt, to: segment.to))
            }
        }
        zones = merge(zones)

        var events: [TruthEvent] = []
        let fires = zones.filter { $0.kind == .mustFire }
        if fires.isEmpty {
            events.append(TruthEvent(type: .neverQualifies, rule: rule))
        } else {
            for (index, zone) in fires.enumerated() {
                events.append(TruthEvent(type: .onsetTrue, rule: rule, at: zone.from))
                // An offset only means something if the pattern actually backed off,
                // not if the scenario simply ran out of horizon.
                let isLast = index == fires.count - 1
                if !isLast || zone.to < horizon - 1 {
                    events.append(TruthEvent(type: .offsetTrue, rule: rule, at: zone.to + 1))
                }
            }
        }
        return (zones, events)
    }

    /// Adjacent zones merge only when kind, rule, *and* reason agree — two
    /// touching `mustNotFire` runs condemned by different clauses stay separate
    /// zones rather than collapsing into one whose reason would have to pick a
    /// winner it never earned.
    static func merge(_ zones: [TruthZone]) -> [TruthZone] {
        var merged: [TruthZone] = []
        for zone in zones {
            if var last = merged.last, last.kind == zone.kind, last.rule == zone.rule,
               last.reason == zone.reason, last.to + 1 == zone.from {
                last.to = zone.to
                merged[merged.count - 1] = last
            } else {
                merged.append(zone)
            }
        }
        return merged
    }
}
