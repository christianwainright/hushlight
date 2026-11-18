import Foundation

/// Markov on/off state for back-labor-style paired contractions. See
/// `TrajectorySegment.coupling` and the alternation rule in `Physiology.runSegment`.
public struct Coupling: Sendable, Equatable {
    public var pOn: Double
    public var pOff: Double

    public init(pOn: Double, pOff: Double) {
        self.pOn = pOn
        self.pOff = pOff
    }
}

/// A prodromal bout inflating its own intervals until it dies out. `startSeconds` is
/// segment-relative, not absolute — a segment built once and reused at different
/// lengths (see `multiDayLatent`) must not have its fizzle onset silently drift.
public struct Fizzle: Sendable, Equatable {
    public var startSeconds: Double
    public var tauSeconds: Double

    public init(startSeconds: Double, tauSeconds: Double) {
        self.startSeconds = startSeconds
        self.tauSeconds = tauSeconds
    }
}

/// One log-linear phase of a labor. `sigmaDuration` defaults to 0.18 because every
/// archetype in this package uses that value — a bracket that ever needs to deviate
/// says so explicitly at the call site.
public struct TrajectorySegment: Sendable, Equatable {
    public var lengthSeconds: Double
    public var intervalStart: Double
    public var intervalEnd: Double
    public var durationStart: Double
    public var durationEnd: Double
    public var sigmaIntervalStart: Double
    public var sigmaIntervalEnd: Double
    public var sigmaDuration: Double
    public var coupling: Coupling?
    public var fizzle: Fizzle?
    public var intervalFloorSeconds: Double?

    public init(
        lengthSeconds: Double,
        intervalStart: Double,
        intervalEnd: Double,
        durationStart: Double,
        durationEnd: Double,
        sigmaIntervalStart: Double,
        sigmaIntervalEnd: Double,
        sigmaDuration: Double = 0.18,
        coupling: Coupling? = nil,
        fizzle: Fizzle? = nil,
        intervalFloorSeconds: Double? = nil
    ) {
        self.lengthSeconds = lengthSeconds
        self.intervalStart = intervalStart
        self.intervalEnd = intervalEnd
        self.durationStart = durationStart
        self.durationEnd = durationEnd
        self.sigmaIntervalStart = sigmaIntervalStart
        self.sigmaIntervalEnd = sigmaIntervalEnd
        self.sigmaDuration = sigmaDuration
        self.coupling = coupling
        self.fizzle = fizzle
        self.intervalFloorSeconds = intervalFloorSeconds
    }
}

/// A run of segments, optionally preceded by scattered stray contractions.
public struct Bout: Sendable, Equatable {
    /// Gap in seconds from the END of the previous bout's last contraction to this
    /// bout's first contraction. Ignored for the first bout.
    public var gapFromPreviousSeconds: Double
    public var segments: [TrajectorySegment]
    /// Isolated one-off contractions scattered uniformly across the bout's span
    /// *before* its segments run — the "0–3 sporadic" and "0–2 stray" cases.
    public var strayCount: Int
    public var strayWindowSeconds: Double

    public init(
        gapFromPreviousSeconds: Double = 0,
        segments: [TrajectorySegment],
        strayCount: Int = 0,
        strayWindowSeconds: Double = 0
    ) {
        self.gapFromPreviousSeconds = gapFromPreviousSeconds
        self.segments = segments
        self.strayCount = strayCount
        self.strayWindowSeconds = strayWindowSeconds
    }
}

public struct PhysiologyPlan: Sendable, Equatable {
    public var bouts: [Bout]

    public init(bouts: [Bout]) {
        self.bouts = bouts
    }
}

/// Samples a `TrueContraction` stream from a `PhysiologyPlan`. Every random draw
/// flows through the caller's `SplitMix64`, so a plan plus a seed is the entire
/// specification of a scenario's body — nothing here reads the clock.
public enum Physiology {
    /// The stream plus the absolute times at which any bout began to die out.
    ///
    /// Whether a bout *fizzled* is a fact about the model that produced it, not
    /// something recoverable from the emitted contractions — inflating intervals
    /// look identical to a labor that simply slowed. The truth compiler therefore
    /// takes fizzle times as input rather than inferring them, and this is where
    /// they come from.
    public static func generateDetailed(
        plan: PhysiologyPlan, rng: inout SplitMix64
    ) -> (stream: [TrueContraction], fizzleTimes: [Int64]) {
        var result: [TrueContraction] = []
        var fizzleTimes: [Int64] = []
        var cursor: Int64 = 0

        for (index, bout) in plan.bouts.enumerated() {
            let start = index == 0 ? 0 : cursor + Int64(bout.gapFromPreviousSeconds.rounded())
            cursor = run(
                bout: bout, startAbsolute: start, rng: &rng,
                into: &result, fizzleTimes: &fizzleTimes
            )
        }

        return (result, fizzleTimes)
    }

    // MARK: - Bout

    /// Runs one bout starting at `startAbsolute` and returns the end of its last
    /// emitted contraction — the anchor the *next* bout's gap is measured from.
    private static func run(
        bout: Bout,
        startAbsolute: Int64,
        rng: inout SplitMix64,
        into result: inout [TrueContraction],
        fizzleTimes: inout [Int64]
    ) -> Int64 {
        let lastStrayEnd = emitStrays(
            count: bout.strayCount,
            windowSeconds: bout.strayWindowSeconds,
            boutStart: startAbsolute,
            rng: &rng,
            into: &result
        )

        // Segments begin at a fixed offset from bout start — the stray window's
        // nominal length, not wherever the last (possibly dropped) stray actually
        // landed. A dropped stray must not perturb when "quiet time" ends.
        var cursor = startAbsolute + Int64(bout.strayWindowSeconds.rounded())
        for segment in bout.segments {
            if let fizzle = segment.fizzle {
                fizzleTimes.append(cursor + Int64(fizzle.startSeconds.rounded()))
            }
            cursor = runSegment(segment, startAbsolute: cursor, rng: &rng, into: &result)
        }

        return bout.segments.isEmpty ? (lastStrayEnd ?? startAbsolute) : cursor
    }

    // MARK: - Strays

    /// Scatters `count` one-off contractions uniformly across `[0, windowSeconds)`
    /// relative to `boutStart`, dropping any that would land within 90 s of an
    /// already-accepted one. Returns the end of the last accepted stray, or `nil` if
    /// none were accepted (including the trivial `count == 0` case).
    @discardableResult
    private static func emitStrays(
        count: Int,
        windowSeconds: Double,
        boutStart: Int64,
        rng: inout SplitMix64,
        into result: inout [TrueContraction]
    ) -> Int64? {
        guard count > 0, windowSeconds > 0 else { return nil }

        var candidates: [(start: Double, duration: Double)] = []
        candidates.reserveCapacity(count)
        for _ in 0..<count {
            candidates.append((rng.uniform(in: 0...windowSeconds), rng.uniform(in: 25...55)))
        }
        candidates.sort { $0.start < $1.start }

        var lastEndRelative: Double?
        var lastEmittedEnd: Int64?
        for candidate in candidates {
            if let lastEndRelative, candidate.start - lastEndRelative < 90 { continue }
            let span = roundedSpan(rawStart: Double(boutStart) + candidate.start, duration: candidate.duration)
            result.append(TrueContraction(start: span.start, end: span.end))
            lastEndRelative = candidate.start + candidate.duration
            lastEmittedEnd = span.end
        }
        return lastEmittedEnd
    }

    // MARK: - Segment

    /// Samples one segment's contractions starting at `startAbsolute` (the segment's
    /// own t=0) and returns the end of its last contraction — the anchor the *next*
    /// segment chains from directly, with no gap of its own (segments are contiguous
    /// phases of one continuous labor; only bouts get an explicit gap).
    private static func runSegment(
        _ segment: TrajectorySegment,
        startAbsolute: Int64,
        rng: inout SplitMix64,
        into result: inout [TrueContraction]
    ) -> Int64 {
        var t: Double = 0
        var lastEnd = startAbsolute

        // Coupling state. `pairIsShort` tracks alternation independent of on/off
        // transitions — re-entering "coupled" resumes wherever the pairing left off
        // rather than forcing a fresh short-first pair, since nothing in the model
        // distinguishes a fresh entry from a continuing one.
        var coupled = false
        var pairIsShort = true
        var lastShortGap: Double = 0

        while t <= segment.lengthSeconds {
            let f = min(1, t / segment.lengthSeconds)
            let muI = logLinear(segment.intervalStart, segment.intervalEnd, f)
            let muD = logLinear(segment.durationStart, segment.durationEnd, f)
            let sigI = segment.sigmaIntervalStart + (segment.sigmaIntervalEnd - segment.sigmaIntervalStart) * f

            let z = rng.normal(truncatedTo: 2.5)
            var gap = muI * exp(sigI * z)

            if let fizzle = segment.fizzle, t > fizzle.startSeconds {
                gap *= exp((t - fizzle.startSeconds) / fizzle.tauSeconds)
            }
            if let floorSeconds = segment.intervalFloorSeconds {
                gap = max(gap, floorSeconds)
            }

            // One bernoulli draw per step regardless of state, so the stream
            // position never depends on whether coupling happened to be active.
            if let coupling = segment.coupling {
                if coupled {
                    if rng.bernoulli(coupling.pOff) { coupled = false }
                } else {
                    if rng.bernoulli(coupling.pOn) { coupled = true }
                }
                if coupled {
                    if pairIsShort {
                        let short = rng.uniform(in: 75...135)
                        lastShortGap = short
                        gap = short
                    } else {
                        // Preserves the pair's local mean: short + long == 2 * muI.
                        gap = max(2 * muI - lastShortGap, muD + 45)
                    }
                    pairIsShort.toggle()
                }
            }

            let zDuration = rng.normal(truncatedTo: 2.5)
            // The 150 s cap is load-bearing: true physiology must never produce a
            // suspect record (the engine's suspect threshold is >180 s), so every
            // suspect in the corpus is provably the work of the noise model or the
            // hand-authored battery, never of the body.
            let duration = min(max(muD * exp(segment.sigmaDuration * zDuration), 15), 150)

            let span = roundedSpan(rawStart: Double(startAbsolute) + t, duration: duration)
            result.append(TrueContraction(start: span.start, end: span.end))
            lastEnd = span.end

            // The *rounded* start is what the next gap is measured from, so the
            // manifest's arithmetic and the generator's arithmetic can never drift
            // apart across a long stream of accumulated fractional seconds.
            let roundedRelativeStart = Double(span.start - startAbsolute)
            t = roundedRelativeStart + max(gap, muD + 30)
        }

        return lastEnd
    }

    // MARK: - Shared math

    /// Log-linear interpolation: a 22→8 min ramp halves at a constant proportional
    /// rate rather than a constant absolute one, which is how labor actually
    /// accelerates.
    private static func logLinear(_ start: Double, _ end: Double, _ f: Double) -> Double {
        start * pow(end / start, f)
    }

    /// Rounds a raw start/duration pair to whole seconds at the moment it becomes a
    /// `TrueContraction`, bumping the end forward if rounding collapsed it onto the
    /// start.
    private static func roundedSpan(rawStart: Double, duration: Double) -> (start: Int64, end: Int64) {
        let start = Int64(rawStart.rounded())
        var end = Int64((rawStart + duration).rounded())
        if end <= start { end = start + 1 }
        return (start, end)
    }
}
