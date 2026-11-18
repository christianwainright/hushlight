import Foundation
import Testing
@testable import LaborKit

/// Decision 0043: this hour's windowed average against the hour before it. The
/// fixtures below are two contiguous, hand-solved spacing changes rather than
/// noisy data — a contiguous "old rate, then a different rate" shape is exactly
/// what the demo seed builds too, and solving it by hand here is what lets the
/// boundary and steady-state cases land on exact whole seconds.
@Suite("Trend")
struct TrendTests {
    /// Fixed clock; every fixture below is built against this as `now`.
    private let base = Date(timeIntervalSince1970: 1_800_000_000)

    private func contraction(atSeconds seconds: Double) -> Contraction {
        let start = base.addingTimeInterval(seconds)
        return Contraction(startedAt: start, endedAt: start.addingTimeInterval(60))
    }

    /// Seven points `r` seconds apart (newest 180 s before `now`), continuing
    /// backward into five points a fixed 510 s apart.
    ///
    /// Solved by hand: the reference window (asOf one hour back) only ever sees
    /// the 510 s-spaced tail, so its mean is exactly **510 s** whatever `r` is.
    /// The current window sees all seven `r`-spaced points plus two of the 510 s
    /// points bridging in (one more as the window's own entry interval), so its
    /// mean works out to exactly **170 + (2/3)r** seconds. `r` stays inside
    /// (315, 400) so the point count on each side of the boundary never changes.
    private func closerFixture(tightSpacing r: Double) -> [Contraction] {
        let tightOffsets = (0..<7).map { -180.0 - Double($0) * r }
        let t6 = tightOffsets.last!
        let looseOffsets = (1...5).map { t6 - Double($0) * 510.0 }
        return (tightOffsets + looseOffsets).map(contraction(atSeconds:))
    }

    /// The mirror shape: seven points 510 s apart (newest 180 s before `now`),
    /// continuing backward into five points 330 s apart.
    ///
    /// Solved the same way: the reference window sees only the 330 s-spaced tail
    /// (mean exactly **330 s**), and the current window's mean works out to
    /// exactly **465 s** — well past the one-sixth floor in the *farther* direction.
    private func fartherFixture() -> [Contraction] {
        let recentOffsets = (0..<7).map { -180.0 - Double($0) * 510.0 }
        let t6 = recentOffsets.last!
        let olderOffsets = (1...5).map { t6 - Double($0) * 330.0 }
        return (recentOffsets + olderOffsets).map(contraction(atSeconds:))
    }

    @Test func firesWhenTighterThanAnHourAgo() {
        let trend = PatternAnalysis.trend(
            for: closerFixture(tightSpacing: 330), rule: .fiveOneOne, now: base
        )
        #expect(trend?.direction == .closer)
        #expect(trend?.current == .seconds(390))
        #expect(trend?.previous == .seconds(510))
    }

    @Test func firesWhenFartherApartThanAnHourAgo() {
        let trend = PatternAnalysis.trend(for: fartherFixture(), rule: .fiveOneOne, now: base)
        #expect(trend?.direction == .fartherApart)
        #expect(trend?.current == .seconds(465))
        #expect(trend?.previous == .seconds(330))
    }

    /// Delta 84 s against a 510 s reference: 84 × 6 = 504 < 510 — just shy of the
    /// one-sixth floor, and printing "closer" over eighty-odd seconds of noise is
    /// exactly what §3 exists to refuse.
    @Test func steadyUnderOneSixthStaysSilent() {
        let trend = PatternAnalysis.trend(
            for: closerFixture(tightSpacing: 384), rule: .fiveOneOne, now: base
        )
        #expect(trend == nil)
    }

    /// Delta 85 s against a 510 s reference: 85 × 6 = 510 — exactly one-sixth, and
    /// the boundary fires on `≥`, the same closed-on-the-reporting-side convention
    /// every other boundary in this engine takes.
    @Test func boundaryAtExactlyOneSixthFires() {
        let trend = PatternAnalysis.trend(
            for: closerFixture(tightSpacing: 382.5), rule: .fiveOneOne, now: base
        )
        #expect(trend?.direction == .closer)
        #expect(trend?.current == .seconds(425))
        #expect(trend?.previous == .seconds(510))
    }

    /// The current window clears its own floor (three intervals inside the last
    /// hour), but nothing exists before it — the reference window is empty, not
    /// merely thin, and a comparison against nothing is exactly what §2 forbids.
    @Test func silentWhenTheReferenceWindowHasNoAverage() {
        let recent = [-300.0, -900.0, -1500.0, -2100.0].map(contraction(atSeconds:))
        #expect(PatternAnalysis.trend(for: recent, rule: .fiveOneOne, now: base) == nil)
    }

    /// The reference window clears its own floor comfortably, but nothing in the
    /// episode has started within the last hour — the current window is empty.
    @Test func silentWhenTheCurrentWindowHasNoAverage() {
        let old = [-4200.0, -4800.0, -5400.0, -6000.0].map(contraction(atSeconds:))
        #expect(PatternAnalysis.trend(for: old, rule: .fiveOneOne, now: base) == nil)
    }

    /// A wholly empty store clears neither floor.
    @Test func silentWithNoRecordsAtAll() {
        #expect(PatternAnalysis.trend(for: [], rule: .fiveOneOne, now: base) == nil)
    }
}
