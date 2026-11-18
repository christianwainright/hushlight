import Foundation
import Testing
@testable import LaborKit

/// Decision 0050: this stretch's whole-episode average interval against the previous
/// stretch's. Unlike `TrendTests`, no window arithmetic is involved — `summary(of:)`
/// takes the plain mean over a whole episode — so every fixture below is built from
/// evenly-spaced starts whose mean is the spacing itself, and each case names the one
/// gate it is aimed at.
@Suite("Stretch comparison")
struct StretchComparisonTests {
    /// Fixed clock; the fixtures place stretches at stated ages behind it.
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    /// `count` contractions spaced `spacing` apart, the newest `endingAgo` before
    /// `now`. Evenly spaced, so the episode's mean start-to-start interval is exactly
    /// `spacing` and every expectation below is an exact whole second.
    private func stretch(
        count: Int, spacing: TimeInterval, endingAgo: TimeInterval
    ) -> [Contraction] {
        (0..<count).map { index in
            let start = now.addingTimeInterval(-endingAgo - Double(index) * spacing)
            return Contraction(startedAt: start, endedAt: start.addingTimeInterval(60))
        }
    }

    /// Two stretches separated by well over `episodeGap`, so `episodes(_:)` splits them.
    private func twoStretches(
        current: (count: Int, spacing: TimeInterval),
        previous: (count: Int, spacing: TimeInterval),
        previousEndingAgo: TimeInterval = 24 * 60 * 60
    ) -> [Contraction] {
        stretch(count: current.count, spacing: current.spacing, endingAgo: 300)
            + stretch(count: previous.count, spacing: previous.spacing, endingAgo: previousEndingAgo)
    }

    // MARK: - The three readings

    @Test("A tighter stretch than the last one reads closer, carrying both figures")
    func closer() throws {
        let records = twoStretches(current: (6, 300), previous: (6, 510))
        let comparison = try #require(PatternAnalysis.stretchComparison(for: records, now: now))

        #expect(comparison.direction == .closer)
        #expect(comparison.current == .seconds(300))
        #expect(comparison.previous == .seconds(510))
    }

    @Test("A looser stretch than the last one reads farther apart")
    func fartherApart() throws {
        let records = twoStretches(current: (6, 600), previous: (6, 300))
        let comparison = try #require(PatternAnalysis.stretchComparison(for: records, now: now))

        #expect(comparison.direction == .fartherApart)
        #expect(comparison.current == .seconds(600))
        #expect(comparison.previous == .seconds(300))
    }

    /// **The reading the decision turns on** (0050 §4). `LaborTrend` returns nil inside
    /// this band; here it is an answer, and for the third night of prodromal labor it is
    /// the answer that matters most.
    @Test("A stretch inside the one-sixth band reads about the same, and still speaks")
    func aboutTheSame() throws {
        // 510 vs 490: delta 20, and 20 × 6 = 120 < 510. Inside the band.
        let records = twoStretches(current: (6, 490), previous: (6, 510))
        let comparison = try #require(PatternAnalysis.stretchComparison(for: records, now: now))

        #expect(comparison.direction == .aboutTheSame)
        #expect(comparison.current == .seconds(490))
        #expect(comparison.previous == .seconds(510))
    }

    // MARK: - The band's boundary, both sides

    /// Closed on the firing side, the convention every other boundary in this engine
    /// takes: exactly one-sixth is a named direction, a hair under it is steady.
    @Test("Exactly one-sixth of the reference names a direction")
    func boundaryFires() throws {
        // 600 reference, 500 current: delta 100, and 100 × 6 = 600 ≥ 600.
        let records = twoStretches(current: (6, 500), previous: (6, 600))
        let comparison = try #require(PatternAnalysis.stretchComparison(for: records, now: now))

        #expect(comparison.direction == .closer)
    }

    @Test("A hair under one-sixth reads about the same")
    func boundaryHolds() throws {
        // 600 reference, 501 current: delta 99, and 99 × 6 = 594 < 600.
        let records = twoStretches(current: (6, 501), previous: (6, 600))
        let comparison = try #require(PatternAnalysis.stretchComparison(for: records, now: now))

        #expect(comparison.direction == .aboutTheSame)
    }

    // MARK: - The gates that withhold it entirely

    @Test("One stretch has nothing to answer to")
    func singleStretch() {
        let records = stretch(count: 6, spacing: 300, endingAgo: 300)
        #expect(PatternAnalysis.stretchComparison(for: records, now: now) == nil)
    }

    @Test("No records, no comparison")
    func empty() {
        #expect(PatternAnalysis.stretchComparison(for: [], now: now) == nil)
    }

    /// §3: below `averageInterval`'s own two-interval floor there is no figure to
    /// compare, and no em dash for it either — an absent comparison is not a
    /// measurement slot.
    @Test("A previous stretch below the average's floor withholds the line")
    func previousBelowFloor() {
        // Two contractions is one interval; the average needs two.
        let records = stretch(count: 6, spacing: 300, endingAgo: 300)
            + stretch(count: 2, spacing: 510, endingAgo: 24 * 60 * 60)
        #expect(PatternAnalysis.stretchComparison(for: records, now: now) == nil)
    }

    @Test("A current stretch below the average's floor withholds the line")
    func currentBelowFloor() {
        let records = stretch(count: 2, spacing: 300, endingAgo: 300)
            + stretch(count: 6, spacing: 510, endingAgo: 24 * 60 * 60)
        #expect(PatternAnalysis.stretchComparison(for: records, now: now) == nil)
    }

    /// The newest episode having gone stale is the case where "this stretch" would be
    /// naming one that ended — the timer has already returned to its empty state.
    @Test("A concluded newest stretch is not 'this stretch'")
    func newestStretchStale() {
        let records = twoStretches(current: (6, 300), previous: (6, 510))
        let laterStill = now.addingTimeInterval(PatternAnalysis.episodeGap.timeInterval + 60)
        #expect(PatternAnalysis.stretchComparison(for: records, now: laterStill) == nil)
    }

    @Test("Exactly episodeGap since the last start is still live")
    func newestStretchAtGapBoundary() throws {
        let records = twoStretches(current: (6, 300), previous: (6, 510))
        // The newest start is 300 s back at `now`; move `now` forward so the gap is exact.
        let atBoundary = now.addingTimeInterval(PatternAnalysis.episodeGap.timeInterval - 300)
        let comparison = try #require(
            PatternAnalysis.stretchComparison(for: records, now: atBoundary)
        )
        #expect(comparison.direction == .closer)
    }

    // MARK: - The age bound (§6)

    /// A stretch from a previous pregnancy is a record she kept; treating it as a
    /// yardstick for tonight is a claim the app has no business making.
    @Test("A previous stretch older than the age bound is not a reference")
    func previousTooOld() {
        let eightDays: TimeInterval = 8 * 24 * 60 * 60
        let records = twoStretches(
            current: (6, 300), previous: (6, 510), previousEndingAgo: eightDays
        )
        #expect(PatternAnalysis.stretchComparison(for: records, now: now) == nil)
    }

    @Test("The age bound is measured from the previous stretch's own start, and is closed")
    func previousAtAgeBound() throws {
        // Place the previous stretch so its *first* start lands exactly on the bound.
        let spacing: TimeInterval = 510
        let firstStartAgo = PatternAnalysis.stretchComparisonMaxAge.timeInterval
        let newestAgo = firstStartAgo - 5 * spacing
        let records = twoStretches(
            current: (6, 300), previous: (6, spacing), previousEndingAgo: newestAgo
        )
        let comparison = try #require(PatternAnalysis.stretchComparison(for: records, now: now))
        #expect(comparison.previousStartedAt == now.addingTimeInterval(-firstStartAgo))
    }

    // MARK: - What it carries

    @Test("The previous stretch's start is its first contraction, not its last")
    func datesFromTheStart() throws {
        let records = twoStretches(current: (6, 300), previous: (6, 510))
        let comparison = try #require(PatternAnalysis.stretchComparison(for: records, now: now))

        // Previous stretch: newest 24 h back, five further intervals of 510 s behind it.
        let expected = now.addingTimeInterval(-(24 * 60 * 60) - 5 * 510)
        #expect(comparison.previousStartedAt == expected)
    }

    /// Only ever the two most recent stretches: a third, older one is not the reference
    /// even when it is the one that would make a better story.
    @Test("Only the immediately preceding stretch is the reference")
    func onlyTheImmediatelyPreceding() throws {
        let records = twoStretches(current: (6, 300), previous: (6, 510))
            + stretch(count: 6, spacing: 900, endingAgo: 3 * 24 * 60 * 60)
        let comparison = try #require(PatternAnalysis.stretchComparison(for: records, now: now))

        #expect(comparison.previous == .seconds(510))
    }

    /// Order is not an input: the engine sorts, and a store handing back records in any
    /// order must reach the same reading.
    @Test("Record order does not change the reading")
    func orderIndependent() throws {
        let records = twoStretches(current: (6, 300), previous: (6, 510))
        let forward = try #require(PatternAnalysis.stretchComparison(for: records, now: now))
        let shuffled = try #require(
            PatternAnalysis.stretchComparison(for: records.reversed(), now: now)
        )
        #expect(forward == shuffled)
    }
}
