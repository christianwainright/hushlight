import Foundation

/// A fixed-arithmetic SplitMix64 generator (Vigna, https://prng.di.unimi.it/splitmix64.c).
/// Every simulated labor in this package must be bit-reproducible from its seed alone —
/// no `Date()`, no `SystemRandomNumberGenerator`, no platform-dependent Double rounding —
/// so the algorithm here is pinned to the published reference bit-for-bit, verified by
/// known-answer tests. Anything less and two runs of the "same" scenario could silently
/// disagree, which defeats the entire point of a QA simulation harness.
public struct SplitMix64: RandomNumberGenerator, Sendable {
    public private(set) var state: UInt64

    public init(seed: UInt64) {
        self.state = seed
    }

    /// The SplitMix64 step: advance state by the golden-ratio increment, then run the
    /// output through two xor-shift/multiply rounds (Murmur-style finalizer) to scramble
    /// the low-entropy counter into a well-distributed 64-bit word. Every operator here
    /// wraps on purpose — overflow is the generator's normal operating mode, not a bug.
    public mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// Half-open [0, 1) from the top 53 bits of a 64-bit draw — the usual construction
    /// for a double with no bias toward either endpoint and no wasted entropy.
    public mutating func uniform() -> Double {
        Double(next() >> 11) * 0x1.0p-53
    }

    public mutating func uniform(in range: ClosedRange<Double>) -> Double {
        range.lowerBound + uniform() * (range.upperBound - range.lowerBound)
    }

    // MARK: - Standard normal via Acklam's inverse-CDF approximation
    //
    // Acklam's rational approximation to the inverse standard-normal CDF, split into
    // three branches (lower tail / central / upper tail) around the tails' crossover
    // points pLow/pHigh. Coefficients are the published constants, reproduced exactly.
    // This method exists — instead of Box-Muller or Marsaglia's polar method — because
    // both of those consume a *variable* number of uniform draws per deviate (Marsaglia
    // rejects and redraws when the point falls outside the unit disk). A variable draw
    // count would make every downstream random value in a scenario depend on how many
    // rejections happened to occur, which breaks the guarantee that two scenarios
    // sharing a seed prefix produce identical streams up to the point they diverge.
    // Acklam's approximation, by contrast, is a pure function of exactly one uniform.

    private static let acklamA: [Double] = [
        -3.969683028665376e+01, 2.209460984245205e+02, -2.759285104469687e+02,
        1.383577518672690e+02, -3.066479806614716e+01, 2.506628277459239e+00,
    ]
    private static let acklamB: [Double] = [
        -5.447609879822406e+01, 1.615858368580409e+02, -1.556989798598866e+02,
        6.680131188771972e+01, -1.328068155288572e+01,
    ]
    private static let acklamC: [Double] = [
        -7.784894002430293e-03, -3.223964580411365e-01, -2.400758277161838e+00,
        -2.549732539343734e+00, 4.374664141464968e+00, 2.938163982698783e+00,
    ]
    private static let acklamD: [Double] = [
        7.784695709041462e-03, 3.224671290700398e-01, 2.445134137142996e+00,
        3.754408661907416e+00,
    ]
    private static let acklamPLow: Double = 0.02425
    private static let acklamPHigh: Double = 1 - acklamPLow

    /// Exposed (internal, reachable via `@testable`) so tests can pin the approximation
    /// itself against known standard-normal quantiles, independent of the RNG stream.
    static func inverseNormalCDF(_ p: Double) -> Double {
        let a = acklamA, b = acklamB, c = acklamC, d = acklamD

        if p < acklamPLow {
            let q = sqrt(-2 * log(p))
            return (((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) * q + c[5])
                / ((((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1)
        } else if p <= acklamPHigh {
            let q = p - 0.5
            let r = q * q
            return (((((a[0] * r + a[1]) * r + a[2]) * r + a[3]) * r + a[4]) * r + a[5]) * q
                / (((((b[0] * r + b[1]) * r + b[2]) * r + b[3]) * r + b[4]) * r + 1)
        } else {
            let q = sqrt(-2 * log(1 - p))
            return -((((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) * q + c[5])
                / ((((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1))
        }
    }

    /// One uniform draw, always — `p == 0` is nudged to the smallest positive double
    /// rather than resampled, because resampling on a boundary condition is exactly the
    /// kind of variable-draw-count behavior this method exists to avoid (see above).
    public mutating func normal() -> Double {
        let u = uniform()
        let p = u == 0 ? 0x1.0p-53 : u
        return Self.inverseNormalCDF(p)
    }

    /// Clamps, never resamples — a resample-on-reject loop would make the number of
    /// underlying draws depend on how often the tail got hit, and that variability
    /// would desynchronize every draw downstream of it across otherwise-identical runs.
    public mutating func normal(truncatedTo limit: Double) -> Double {
        min(max(normal(), -limit), limit)
    }

    /// Uniform integer in `range`, derived from a single `uniform()` draw so the
    /// generator's stream position never depends on how many candidates get rejected.
    public mutating func int(in range: ClosedRange<Int>) -> Int {
        let count = range.upperBound - range.lowerBound + 1
        let candidate = range.lowerBound + Int(uniform() * Double(count))
        return min(candidate, range.upperBound)
    }

    public mutating func bernoulli(_ p: Double) -> Bool {
        uniform() < p
    }

    /// Number of Bernoulli(p) trials until the first success (>= 1), derived from one
    /// uniform draw via the geometric distribution's closed-form inverse-CDF rather
    /// than by looping `bernoulli(p)` until true — looping would again make the draw
    /// count variable and desynchronize the stream.
    public mutating func geometricTrials(p: Double) -> Int {
        if p <= 0 { return Int.max }
        if p >= 1 { return 1 }
        let u = uniform()
        return Int((log(1 - u) / log(1 - p)).rounded(.down)) + 1
    }
}

/// Deterministic seed derivation for simulated scenarios. `fnv1a64`/`mix` turn free-form
/// strings and integers into well-mixed 64-bit seeds without touching any hashing API
/// that Swift doesn't guarantee is stable across OS versions or runs (`String.hashValue`
/// is explicitly randomized per-process and unusable here).
public enum SeedDerivation {
    /// FNV-1a over UTF-8 bytes — simple, dependency-free, and stable across platforms,
    /// which is all a seed-derivation hash needs to be.
    public static func fnv1a64(_ string: String) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0001_0000_01b3
        }
        return hash
    }

    /// SplitMix64's own finalizer, reused standalone as a general-purpose 64-bit mixer
    /// for combining seed material before it ever becomes a generator's initial state.
    public static func mix(_ value: UInt64) -> UInt64 {
        var z = value
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    public static func scenarioSeed(archetype: String, paramVariant: Int) -> UInt64 {
        mix(fnv1a64(archetype) ^ UInt64(bitPattern: Int64(paramVariant)))
    }

    /// ASCII "PHYSIOLO" / "NOISESTR" — arbitrary but fixed domain-separation tags so the
    /// two sub-streams below can never collide with each other or with a bare scenario seed.
    public static let physiologyTag: UInt64 = 0x5048_5953_494F_4C4F
    public static let noiseTag: UInt64 = 0x4E4F_4953_4553_5452

    // Physiology and noise are drawn from independent sub-streams keyed off the same
    // scenario seed so that choosing a different noise profile can never perturb the
    // underlying "true" contraction stream. The whole point of comparing sensor-noise
    // profiles against each other is that they are measurements of the *same* labor —
    // if changing the profile string nudged the physiology stream even one draw, the
    // six profiles would silently stop being comparable runs of one ground truth.

    public static func physiologyStream(_ scenarioSeed: UInt64) -> SplitMix64 {
        SplitMix64(seed: mix(scenarioSeed ^ physiologyTag))
    }

    public static func noiseStream(_ scenarioSeed: UInt64, profile: String, run: Int) -> SplitMix64 {
        SplitMix64(
            seed: mix(mix(scenarioSeed ^ noiseTag) ^ fnv1a64(profile) ^ UInt64(bitPattern: Int64(run)))
        )
    }
}
