import Testing

@testable import LaborSim

/// Known-answer vectors pin this module's SplitMix64 to the published reference
/// implementation (Vigna, https://prng.di.unimi.it/splitmix64.c) — re-derived
/// independently for this test rather than copied from the source. A PRNG with no
/// known-answer test is a PRNG nobody can port: without it, a refactor that "still
/// looks random" could silently reseed every recorded simulation run.
@Suite("Seeded random")
struct RandomVectorTests {

    // MARK: - SplitMix64 known-answer vectors

    @Test("SplitMix64 seed 0 matches published reference vectors")
    func splitMix64Seed0KnownAnswer() {
        var rng = SplitMix64(seed: 0)
        let expected: [UInt64] = [
            0xE220_A839_7B1D_CDAF, 0x6E78_9E6A_A1B9_65F4, 0x06C4_5D18_8009_454F,
            0xF88B_B8A8_724C_81EC, 0x1B39_896A_51A8_749B, 0x53CB_9F0C_747E_A2EA,
        ]
        for value in expected {
            #expect(rng.next() == value)
        }
    }

    @Test("SplitMix64 seed 0xDEADBEEF matches known outputs")
    func splitMix64SeedDeadbeefKnownAnswer() {
        var rng = SplitMix64(seed: 0xDEAD_BEEF)
        let expected: [UInt64] = [
            0x4ADF_B90F_68C9_EB9B, 0xDE58_6A31_41A1_0922, 0x021F_BC2F_8E1C_FC1D,
        ]
        for value in expected {
            #expect(rng.next() == value)
        }
    }

    // MARK: - uniform()

    @Test("uniform() from seed 0 matches known values")
    func uniformSeed0KnownAnswer() {
        var rng = SplitMix64(seed: 0)
        let expected: [Double] = [
            0.8833108082136426, 0.43152799704850997, 0.026433771592597743,
        ]
        for value in expected {
            let draw = rng.uniform()
            #expect(abs(draw - value) < 1e-15)
        }
    }

    @Test("uniform() stays within [0, 1) across seeds and draws")
    func uniformStaysInHalfOpenUnitRange() {
        let seeds: [UInt64] = [0, 1, 42, 0xDEAD_BEEF, UInt64.max]
        for seed in seeds {
            var rng = SplitMix64(seed: seed)
            for _ in 0..<10_000 {
                let draw = rng.uniform()
                #expect(draw >= 0.0)
                #expect(draw < 1.0)
            }
        }
    }

    // MARK: - normal() / inverse-CDF

    @Test("inverseNormalCDF matches known standard-normal quantiles")
    func inverseNormalCDFKnownQuantiles() {
        // Acklam's approximation carries ~1.15e-9 relative error in the central branch
        // and is looser by construction in the extreme tail; the tolerances below
        // describe the published accuracy of the approximation, not laxity in the test.
        #expect(abs(SplitMix64.inverseNormalCDF(0.5) - 0.0) < 1e-12)
        #expect(abs(SplitMix64.inverseNormalCDF(0.975) - 1.959964) < 5e-5)
        #expect(abs(SplitMix64.inverseNormalCDF(0.025) - (-1.959964)) < 5e-5)
        #expect(abs(SplitMix64.inverseNormalCDF(0.99) - 2.326348) < 5e-5)
        #expect(abs(SplitMix64.inverseNormalCDF(0.001) - (-3.090232)) < 1e-3)
    }

    // MARK: - Determinism

    @Test("identical seeds produce identical uniform sequences")
    func identicalSeedsProduceIdenticalSequences() {
        var a = SplitMix64(seed: 123_456)
        var b = SplitMix64(seed: 123_456)
        for _ in 0..<1000 {
            #expect(a.uniform() == b.uniform())
        }
    }

    @Test("different seeds diverge on the first draw")
    func differentSeedsDivergeImmediately() {
        var a = SplitMix64(seed: 1)
        var b = SplitMix64(seed: 2)
        #expect(a.next() != b.next())
    }

    // MARK: - normal(truncatedTo:)

    @Test("normal(truncatedTo:) never exceeds the clamp bound")
    func truncatedNormalStaysWithinBound() {
        var rng = SplitMix64(seed: 99)
        let limit = 2.5
        for _ in 0..<10_000 {
            let draw = rng.normal(truncatedTo: limit)
            #expect(draw >= -limit)
            #expect(draw <= limit)
        }
    }

    @Test("normal(truncatedTo:) clamps rather than resamples, consuming exactly one uniform per call")
    func truncatedNormalConsumesExactlyOneDrawPerCall() {
        // Clamping (not resampling) is what keeps stream position independent of how
        // often a deviate lands outside the clamp — resampling would make the number of
        // underlying draws depend on rejection luck, desynchronizing every later draw
        // in the scenario relative to a run that happened not to hit the tail.
        var truncated = SplitMix64(seed: 777)
        var raw = SplitMix64(seed: 777)
        let callCount = 500
        for _ in 0..<callCount {
            _ = truncated.normal(truncatedTo: 2.5)
            _ = raw.next()
        }
        #expect(truncated.state == raw.state)
    }

    // MARK: - Seed derivation

    @Test("scenarioSeed is stable and distinct across archetype/variant pairs")
    func scenarioSeedStableAndDistinct() {
        let s1 = SeedDerivation.scenarioSeed(archetype: "nullipara-fast", paramVariant: 0)
        let s1Repeat = SeedDerivation.scenarioSeed(archetype: "nullipara-fast", paramVariant: 0)
        let s2 = SeedDerivation.scenarioSeed(archetype: "nullipara-fast", paramVariant: 1)
        let s3 = SeedDerivation.scenarioSeed(archetype: "multipara-slow", paramVariant: 0)

        #expect(s1 == s1Repeat)
        #expect(s1 != s2)
        #expect(s1 != s3)
        #expect(s2 != s3)
    }

    @Test("physiology and noise streams for the same scenario diverge on their first output")
    func physiologyAndNoiseStreamsDiverge() {
        let scenario = SeedDerivation.scenarioSeed(archetype: "nullipara-fast", paramVariant: 0)
        var physiology = SeedDerivation.physiologyStream(scenario)
        var noise = SeedDerivation.noiseStream(scenario, profile: "wearable-typical", run: 0)
        #expect(physiology.next() != noise.next())
    }

    @Test("changing only the noise profile leaves the physiology stream untouched")
    func noiseProfileChangeDoesNotPerturbPhysiology() {
        // The whole basis of comparing sensor-noise profiles is that they measure the
        // same true labor — physiology and noise draw from independent sub-streams
        // precisely so a profile swap can never leak into the "ground truth" contraction
        // sequence being measured against.
        let scenario = SeedDerivation.scenarioSeed(archetype: "multipara-fast", paramVariant: 3)
        var physiologyA = SeedDerivation.physiologyStream(scenario)
        var physiologyB = SeedDerivation.physiologyStream(scenario)
        var noiseProfileOne = SeedDerivation.noiseStream(scenario, profile: "wearable-typical", run: 0)
        var noiseProfileTwo = SeedDerivation.noiseStream(scenario, profile: "manual-noisy", run: 0)

        for _ in 0..<100 { _ = noiseProfileOne.next() }
        for _ in 0..<100 { _ = noiseProfileTwo.next() }

        for _ in 0..<100 {
            #expect(physiologyA.next() == physiologyB.next())
        }
    }

    // MARK: - geometricTrials(p:)

    @Test("geometricTrials returns at least one trial always")
    func geometricTrialsAlwaysAtLeastOne() {
        var rng = SplitMix64(seed: 55)
        for _ in 0..<5000 {
            #expect(rng.geometricTrials(p: 0.25) >= 1)
        }
    }

    @Test("geometricTrials returns 1 when success is certain")
    func geometricTrialsReturnsOneWhenCertain() {
        var rng = SplitMix64(seed: 55)
        #expect(rng.geometricTrials(p: 1.0) == 1)
        #expect(rng.geometricTrials(p: 1.5) == 1)
    }

    @Test("geometricTrials at p=0.25 has mean near the theoretical 1/p")
    func geometricTrialsMeanNearTheoretical() {
        var rng = SplitMix64(seed: 2024)
        let draws = 5000
        var total = 0
        for _ in 0..<draws {
            total += rng.geometricTrials(p: 0.25)
        }
        let mean = Double(total) / Double(draws)
        #expect(abs(mean - 4.0) < 0.3)
    }
}
