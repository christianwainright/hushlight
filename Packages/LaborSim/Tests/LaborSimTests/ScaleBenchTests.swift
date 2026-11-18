import Foundation
import Testing
import LaborKit
import LaborSim

/// Rubric T2-07 (engine half): `pattern()` runs on every tap and every timer
/// re-render, so its cost has to stay invisible even on the worst episode a real
/// labor produces — hundreds of contractions logged over many hours. This is a
/// microbenchmark, not a correctness test: parity and boundary behavior are
/// ReplayParityTests' job, this file only asks "is it still fast at scale."
@Suite("Scale bench")
struct ScaleBenchTests {

    /// 500 contractions, 300 s start-to-start (well under `episodeGap`'s 2 h), so
    /// the whole run folds into a single episode. Whole-second, epoch-anchored
    /// timestamps rather than `Date()` — this only has to be a shape `pattern()`
    /// can chew on, and a fixed clock keeps the benchmark reproducible instead of
    /// depending on when the suite happens to run.
    private static func syntheticEpisode(count: Int) -> [Contraction] {
        (0..<count).map { index in
            let start = Date(
                timeIntervalSince1970: TimeInterval(laborSimEpoch + Int64(index * 300))
            )
            return Contraction(startedAt: start, endedAt: start.addingTimeInterval(60))
        }
    }

    /// `Duration` has no public millisecond accessor, so this reads the components
    /// directly rather than reaching for a private extension elsewhere in the tree.
    private static func milliseconds(_ duration: Duration) -> Double {
        let c = duration.components
        return Double(c.seconds) * 1000 + Double(c.attoseconds) / 1e15
    }

    @Test func patternP99StaysUnderFiftyMillisecondsAt500Records() {
        let records = Self.syntheticEpisode(count: 500)
        let now = Date(
            timeIntervalSince1970: TimeInterval(laborSimEpoch + Int64(500 * 300) + 60)
        )
        let clock = ContinuousClock()

        // Warmup, discarded: the first handful of calls pay for one-time costs
        // (allocator growth, whatever the optimizer defers to first use) that a
        // steady-state caller never sees. Timing them would bias the measurement
        // toward a cost real usage doesn't pay.
        for _ in 0..<20 {
            _ = PatternAnalysis.pattern(for: records, rule: .fiveOneOne, now: now)
        }

        // Up to three rounds, keeping the best p99 (F-0054). A loaded machine can push
        // one round of 200 calls past the line and pass idle; a real regression is
        // slow in every round, so only that still fails.
        var p99Milliseconds = Double.infinity
        var lastPattern = LaborPattern.empty
        for _ in 0..<3 where p99Milliseconds >= 50 {
            var samples: [Duration] = []
            samples.reserveCapacity(200)
            for _ in 0..<200 {
                let start = clock.now
                lastPattern = PatternAnalysis.pattern(for: records, rule: .fiveOneOne, now: now)
                samples.append(clock.now - start)
            }

            samples.sort()
            // p99 index: floor(0.99 * count) rather than round, so the index can never
            // land past the last sample. For count == 200 that's index 198 — the 199th
            // of 200 sorted calls, i.e. "99% of calls are at least this fast."
            let p99Index = Int((0.99 * Double(samples.count)).rounded(.down))
            p99Milliseconds = min(p99Milliseconds, Self.milliseconds(samples[p99Index]))
        }

        // 50 ms is deliberately loose against the real cost of one pattern() call
        // over 500 records — comfortably sub-millisecond on real hardware — so a
        // noisy CI runner (shared host, thermal throttle, a neighbor process)
        // cannot flap this test. The threshold is a tripwire for a real regression,
        // not a performance target; the actual number is what a failure needs, and
        // it's in the message below, not in the 50 ms line.
        #expect(
            p99Milliseconds < 50,
            "best p99 of three rounds of 200 calls on 500 records was \(p99Milliseconds) ms"
        )

        // A benchmark that silently measured a 1-record episode because the
        // synthetic gaps drifted past episodeGap would still pass — fast, and
        // meaningless. Pin the shape the timing number is actually describing.
        #expect(
            lastPattern.episode.count == 500,
            "expected all 500 synthetic records in one episode, got \(lastPattern.episode.count)"
        )
    }
}
