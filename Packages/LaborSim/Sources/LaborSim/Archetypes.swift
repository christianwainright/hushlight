import Foundation

/// The clinical brackets behind each `ArchetypeID`, and the sampling that turns them
/// into a concrete `PhysiologyPlan`. `paramVariant` selects a seed (via
/// `ScenarioSeedRef`), not a different bracket — variants 0...2 draw from the same
/// ranges through three independent streams; only the named variants (>= 3) change
/// what gets built.
public enum Archetypes {
    public static func plan(for archetype: ArchetypeID, paramVariant: Int, rng: inout SplitMix64) -> PhysiologyPlan {
        switch archetype {
        case .classicNullipara: classicNullipara(rng: &rng)
        case .classicMultipara: classicMultipara(rng: &rng)
        case .precipitous: precipitous(rng: &rng)
        case .prodromalFizzle: prodromalFizzle(rng: &rng)
        case .prodromalNightly: prodromalNightly(paramVariant: paramVariant, rng: &rng)
        case .braxtonHicks: braxtonHicks(rng: &rng)
        case .irregularProgressing: irregularProgressing(rng: &rng)
        case .backLaborCoupling: backLaborCoupling(rng: &rng)
        case .pretermEarly: pretermEarly(paramVariant: paramVariant, rng: &rng)
        case .inductionRamp: inductionRamp(paramVariant: paramVariant, rng: &rng)
        case .multiDayLatent: multiDayLatent(paramVariant: paramVariant, rng: &rng)
        case .sromThenOnset: sromThenOnset(rng: &rng)
        // Hand-authored elsewhere: exact arithmetic the sampler must not touch.
        case .boundaryBattery: PhysiologyPlan(bouts: [])
        }
    }

    public static func pretermContext(for archetype: ArchetypeID) -> Bool {
        archetype == .pretermEarly
    }

    // MARK: - 1. classicNullipara

    private static func classicNullipara(rng: inout SplitMix64) -> PhysiologyPlan {
        let bout = Bout(segments: [
            nulliparaLatent(lengthSeconds: hours(6...14, &rng)),
            nulliparaActive(lengthSeconds: hours(3...6, &rng)),
            nulliparaTransition(lengthSeconds: hours(0.5...1.5, &rng)),
        ])
        return PhysiologyPlan(bouts: [bout])
    }

    private static func nulliparaLatent(lengthSeconds: Double) -> TrajectorySegment {
        TrajectorySegment(
            lengthSeconds: lengthSeconds,
            intervalStart: 22 * 60, intervalEnd: 8 * 60,
            durationStart: 32, durationEnd: 48,
            sigmaIntervalStart: 0.35, sigmaIntervalEnd: 0.20
        )
    }

    private static func nulliparaActive(lengthSeconds: Double) -> TrajectorySegment {
        TrajectorySegment(
            lengthSeconds: lengthSeconds,
            intervalStart: 8 * 60, intervalEnd: 3.5 * 60,
            durationStart: 48, durationEnd: 65,
            sigmaIntervalStart: 0.15, sigmaIntervalEnd: 0.15
        )
    }

    private static func nulliparaTransition(lengthSeconds: Double) -> TrajectorySegment {
        TrajectorySegment(
            lengthSeconds: lengthSeconds,
            intervalStart: 3.5 * 60, intervalEnd: 2.2 * 60,
            durationStart: 65, durationEnd: 85,
            sigmaIntervalStart: 0.12, sigmaIntervalEnd: 0.12
        )
    }

    // MARK: - 2. classicMultipara

    // Multipara latent brackets sit at roughly half nullipara's length and interval —
    // a cervix that has done this before does not need the same runway.
    private static func classicMultipara(rng: inout SplitMix64) -> PhysiologyPlan {
        let bout = Bout(segments: [
            multiparaLatent(lengthSeconds: hours(2...5, &rng)),
            multiparaActive(lengthSeconds: hours(1...2.5, &rng)),
            multiparaTransition(lengthSeconds: minutes(15...40, &rng)),
        ])
        return PhysiologyPlan(bouts: [bout])
    }

    private static func multiparaLatent(lengthSeconds: Double) -> TrajectorySegment {
        TrajectorySegment(
            lengthSeconds: lengthSeconds,
            intervalStart: 15 * 60, intervalEnd: 7 * 60,
            durationStart: 35, durationEnd: 50,
            sigmaIntervalStart: 0.30, sigmaIntervalEnd: 0.18
        )
    }

    private static func multiparaActive(lengthSeconds: Double) -> TrajectorySegment {
        TrajectorySegment(
            lengthSeconds: lengthSeconds,
            intervalStart: 7 * 60, intervalEnd: 3 * 60,
            durationStart: 50, durationEnd: 70,
            sigmaIntervalStart: 0.15, sigmaIntervalEnd: 0.15
        )
    }

    private static func multiparaTransition(lengthSeconds: Double) -> TrajectorySegment {
        TrajectorySegment(
            lengthSeconds: lengthSeconds,
            intervalStart: 3 * 60, intervalEnd: 2 * 60,
            durationStart: 70, durationEnd: 90,
            sigmaIntervalStart: 0.12, sigmaIntervalEnd: 0.12
        )
    }

    // MARK: - 3. precipitous

    private static func precipitous(rng: inout SplitMix64) -> PhysiologyPlan {
        let segment = TrajectorySegment(
            lengthSeconds: hours(1...2.5, &rng),
            intervalStart: 8 * 60, intervalEnd: 1.8 * 60,
            durationStart: 40, durationEnd: 80,
            sigmaIntervalStart: 0.15, sigmaIntervalEnd: 0.15
        )
        return PhysiologyPlan(bouts: [Bout(segments: [segment])])
    }

    // MARK: - 4/5. prodromalFizzle / prodromalNightly

    private static func prodromalFizzle(rng: inout SplitMix64) -> PhysiologyPlan {
        PhysiologyPlan(bouts: [Bout(segments: [prodromalFizzleSegment(rng: &rng)])])
    }

    /// The shared "false alarm that inflates and dies" segment, reused per-bout by
    /// `prodromalNightly` — each call draws its own fresh length/onset/tau.
    private static func prodromalFizzleSegment(rng: inout SplitMix64) -> TrajectorySegment {
        let length = hours(2...6, &rng)
        let fizzleStart = length * rng.uniform(in: 0.6...0.8)
        let tau = minutes(20...40, &rng)
        return TrajectorySegment(
            lengthSeconds: length,
            intervalStart: 8 * 60, intervalEnd: 6 * 60,
            durationStart: 40, durationEnd: 55,
            sigmaIntervalStart: 0.25, sigmaIntervalEnd: 0.25,
            fizzle: Fizzle(startSeconds: fizzleStart, tauSeconds: tau)
        )
    }

    private static func prodromalNightly(paramVariant: Int, rng: inout SplitMix64) -> PhysiologyPlan {
        let boutCount = rng.int(in: 2...4)
        var bouts: [Bout] = []
        for i in 0..<boutCount {
            let gap = i == 0 ? 0 : hours(14...22, &rng)
            var segments = [prodromalFizzleSegment(rng: &rng)]
            // resolvesIntoLabor: the nightly false alarms that finally were not —
            // only the last bout gets to turn into the real thing.
            if paramVariant >= 3, i == boutCount - 1 {
                segments.append(nulliparaActive(lengthSeconds: hours(3...6, &rng)))
            }
            bouts.append(Bout(gapFromPreviousSeconds: gap, segments: segments))
        }
        return PhysiologyPlan(bouts: bouts)
    }

    // MARK: - 6. braxtonHicks

    // No ramp anywhere, high jitter: the archetype exists to fail every onset rule,
    // never to pass one.
    private static func braxtonHicks(rng: inout SplitMix64) -> PhysiologyPlan {
        let interval = minutes(18...35, &rng)
        let duration = rng.uniform(in: 25...55)
        let segment = TrajectorySegment(
            lengthSeconds: hours(1...3, &rng),
            intervalStart: interval, intervalEnd: interval,
            durationStart: duration, durationEnd: duration,
            sigmaIntervalStart: 0.85, sigmaIntervalEnd: 0.85
        )
        return PhysiologyPlan(bouts: [Bout(segments: [segment])])
    }

    // MARK: - 7. irregularProgressing

    private static func irregularProgressing(rng: inout SplitMix64) -> PhysiologyPlan {
        let segment = TrajectorySegment(
            lengthSeconds: hours(8...16, &rng),
            intervalStart: 18 * 60, intervalEnd: 3.5 * 60,
            durationStart: 35, durationEnd: 70,
            sigmaIntervalStart: 0.40, sigmaIntervalEnd: 0.40
        )
        return PhysiologyPlan(bouts: [Bout(segments: [segment])])
    }

    // MARK: - 8. backLaborCoupling

    private static func backLaborCoupling(rng: inout SplitMix64) -> PhysiologyPlan {
        let segment = TrajectorySegment(
            lengthSeconds: hours(4...8, &rng),
            intervalStart: 9 * 60, intervalEnd: 4 * 60,
            durationStart: 45, durationEnd: 70,
            sigmaIntervalStart: 0.20, sigmaIntervalEnd: 0.20,
            coupling: Coupling(pOn: 0.15, pOff: 0.25)
        )
        return PhysiologyPlan(bouts: [Bout(segments: [segment])])
    }

    // MARK: - 9. pretermEarly

    private static func pretermEarly(paramVariant: Int, rng: inout SplitMix64) -> PhysiologyPlan {
        let intervalStart = minutes(10...14, &rng)
        let duration = rng.uniform(in: 30...45)
        let base = TrajectorySegment(
            lengthSeconds: hours(1...4, &rng),
            // "ramping only slightly" — the point of pretermEarly is that it looks
            // almost like Braxton Hicks, not like active labor.
            intervalStart: intervalStart, intervalEnd: intervalStart * 0.85,
            durationStart: duration, durationEnd: duration,
            sigmaIntervalStart: 0.30, sigmaIntervalEnd: 0.30
        )
        var segments = [base]
        if paramVariant >= 3 {
            // progressing: the spec pins only the interval ramp for the appended
            // segment. Duration/sigma aren't given a new bracket, so this reuses
            // pretermEarly's own flat-duration bracket and sigma — the same body,
            // now actually progressing rather than just teasing.
            let progressingDuration = rng.uniform(in: 30...45)
            segments.append(TrajectorySegment(
                lengthSeconds: hours(1...2, &rng),
                intervalStart: 7 * 60, intervalEnd: 4 * 60,
                durationStart: progressingDuration, durationEnd: progressingDuration,
                sigmaIntervalStart: 0.30, sigmaIntervalEnd: 0.30
            ))
        }
        return PhysiologyPlan(bouts: [Bout(segments: segments)])
    }

    // MARK: - 10. inductionRamp

    private static func inductionRamp(paramVariant: Int, rng: inout SplitMix64) -> PhysiologyPlan {
        let strayCount = rng.int(in: 0...2)
        let quietWindow = hours(0.5...2, &rng)
        let ramp = TrajectorySegment(
            lengthSeconds: minutes(30...60, &rng),
            intervalStart: 12 * 60, intervalEnd: 3 * 60,
            durationStart: 45, durationEnd: 75,
            sigmaIntervalStart: 0.12, sigmaIntervalEnd: 0.12
        )
        var segments = [ramp]
        // tachysystole: contractions stacking closer than the uterus should allow.
        // A floor on the ramp segment alone (the original shape) never actually
        // bites: its tail sits at a 180 s mean, and even a 2.5-sigma dip at
        // sigmaIntervalEnd=0.12 only reaches ~133 s — comfortably above a 95-110 s
        // floor, so the constraint was dead code (F-0025: 8 true contractions
        // total, nowhere near a dense run). What actually sustains tachysystole is
        // a second, flat segment held at the floor for the better part of an hour
        // — at ~100-110 s spacing an hour holds ~35 contractions.
        if paramVariant >= 3 {
            let floorSeconds = rng.uniform(in: 95...110)
            segments.append(TrajectorySegment(
                lengthSeconds: hours(1...1.5, &rng),
                intervalStart: floorSeconds, intervalEnd: floorSeconds,
                durationStart: 70, durationEnd: 80,
                sigmaIntervalStart: 0.10, sigmaIntervalEnd: 0.10,
                intervalFloorSeconds: floorSeconds
            ))
        }
        let bout = Bout(segments: segments, strayCount: strayCount, strayWindowSeconds: quietWindow)
        return PhysiologyPlan(bouts: [bout])
    }

    // MARK: - 11. multiDayLatent

    // Fixed inter-bout gaps (minutes) for variants 3...8, straddling the engine's 2 h
    // (7200 s) episode boundary from both sides. This sweep IS the archetype's point:
    // "how long has this been happening" either resets across the gap or it does not,
    // and both answers are only visible from ground truth, never from the recording
    // alone. Everything else about the scenario (bout count, phase lengths) still
    // draws normally — only the one gap under test is pinned.
    private static let multiDayLatentGapSweepMinutes: [Int: Double] = [
        3: 110, 4: 115, 5: 118, 6: 120, 7: 125, 8: 135,
    ]

    private static func multiDayLatent(paramVariant: Int, rng: inout SplitMix64) -> PhysiologyPlan {
        let boutCount = rng.int(in: 3...5)
        var bouts: [Bout] = []
        for i in 0..<boutCount {
            let gap: Double
            if i == 0 {
                gap = 0
            } else if let sweepMinutes = multiDayLatentGapSweepMinutes[paramVariant] {
                gap = sweepMinutes * 60
            } else {
                gap = hours(3...8, &rng)
            }

            var segments = [nulliparaLatent(lengthSeconds: hours(2...5, &rng))]
            if i == boutCount - 1 {
                // The final night resolves: latent finally hands off to active and
                // transition, using classicNullipara's own brackets for both.
                segments.append(nulliparaActive(lengthSeconds: hours(3...6, &rng)))
                segments.append(nulliparaTransition(lengthSeconds: hours(0.5...1.5, &rng)))
            }
            bouts.append(Bout(gapFromPreviousSeconds: gap, segments: segments))
        }
        return PhysiologyPlan(bouts: bouts)
    }

    // MARK: - 12. sromThenOnset

    private static func sromThenOnset(rng: inout SplitMix64) -> PhysiologyPlan {
        let strayCount = rng.int(in: 0...3)
        let window = hours(1...6, &rng)
        let active = multiparaActive(lengthSeconds: hours(1...2.5, &rng))
        let bout = Bout(segments: [active], strayCount: strayCount, strayWindowSeconds: window)
        return PhysiologyPlan(bouts: [bout])
    }

    // MARK: - Bracket sampling helpers

    private static func hours(_ range: ClosedRange<Double>, _ rng: inout SplitMix64) -> Double {
        rng.uniform(in: range) * 3600
    }

    private static func minutes(_ range: ClosedRange<Double>, _ rng: inout SplitMix64) -> Double {
        rng.uniform(in: range) * 60
    }
}
