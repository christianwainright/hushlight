import Foundation
import Testing
@testable import LaborKit

/// The lock screen's content is derived by one pure function; these pin it to the
/// same honesty rules as the in-app readout — the Live Activity must never print a
/// figure the app itself would refuse.
@Suite("Live Activity content")
struct ContractionActivityTests {
    private let base = Date(timeIntervalSince1970: 1_800_000_000)

    private func contraction(atMinutes minutes: Double, lastingSeconds seconds: Double? = 60) -> Contraction {
        let start = base.addingTimeInterval(minutes * 60)
        return Contraction(startedAt: start, endedAt: seconds.map { start.addingTimeInterval($0) })
    }

    @Test func aRunningContractionDrivesTheTimerState() {
        let contractions = [
            contraction(atMinutes: 0),
            contraction(atMinutes: 5, lastingSeconds: nil)
        ]
        let pattern = PatternAnalysis.pattern(
            for: contractions, rule: .fiveOneOne, now: base.addingTimeInterval(6 * 60)
        )
        let state = ContractionActivityAttributes.ContentState.from(pattern)

        #expect(state.runningSince == base.addingTimeInterval(5 * 60))
        #expect(state.contractionCount == 2)
    }

    @Test func idleStateCarriesTheLastIntervalAndCount() {
        let contractions = [contraction(atMinutes: 0), contraction(atMinutes: 5)]
        let pattern = PatternAnalysis.pattern(
            for: contractions, rule: .fiveOneOne, now: base.addingTimeInterval(7 * 60)
        )
        let state = ContractionActivityAttributes.ContentState.from(pattern)

        #expect(state.runningSince == nil)
        #expect(state.lastIntervalSeconds == 300)
        #expect(state.contractionCount == 2)
    }

    /// One contraction has no interval — the lock screen shows the count, never a
    /// zero-shaped figure. Same rule as the app's em dash.
    @Test func aSingleContractionHasNoInterval() {
        let pattern = PatternAnalysis.pattern(
            for: [contraction(atMinutes: 0)],
            rule: .fiveOneOne,
            now: base.addingTimeInterval(2 * 60)
        )
        let state = ContractionActivityAttributes.ContentState.from(pattern)

        #expect(state.lastIntervalSeconds == nil)
        #expect(state.contractionCount == 1)
    }

    /// SP-213: the average rides the same floor the app's INTERVAL column uses —
    /// present at three contractions' worth of evidence, absent below it, so the
    /// lock screen can never lead with a figure the app itself would withhold.
    @Test func theAverageArrivesWithItsFloorAndNotBefore() {
        let two = PatternAnalysis.pattern(
            for: [contraction(atMinutes: 0), contraction(atMinutes: 5)],
            rule: .fiveOneOne, now: base.addingTimeInterval(7 * 60)
        )
        let twoState = ContractionActivityAttributes.ContentState.from(two)
        #expect(twoState.averageIntervalSeconds == nil)
        #expect(twoState.lastIntervalSeconds == 300)

        let three = PatternAnalysis.pattern(
            for: [contraction(atMinutes: 0), contraction(atMinutes: 5), contraction(atMinutes: 10)],
            rule: .fiveOneOne, now: base.addingTimeInterval(12 * 60)
        )
        let threeState = ContractionActivityAttributes.ContentState.from(three)
        #expect(threeState.averageIntervalSeconds == 300)
    }

    @Test func theEmptyPatternProducesTheEmptyState() {
        let state = ContractionActivityAttributes.ContentState.from(.empty)
        #expect(state.runningSince == nil)
        #expect(state.lastIntervalSeconds == nil)
        #expect(state.contractionCount == 0)
    }
}


/// SP-205: the rearm decision, tested where it lives. Both callers — the app's
/// foreground reconciliation and the lock-screen intent — read this one predicate,
/// so these boundaries are the whole of the behavior.
@Suite("Activity rearm")
struct ActivityRearmTests {
    @Test func sixHoursIsTheLine() {
        let born = Date(timeIntervalSince1970: 1_756_000_000)
        let attributes = ContractionActivityAttributes(startedAt: born)
        // Either side of the boundary, deliberately: five-fifty-nine keeps the
        // activity, six-oh-one replaces it. Exactly six hours is not yet stale —
        // the predicate is strictly greater-than, matching the constant's meaning
        // as an age it must *exceed*.
        #expect(!attributes.needsReplacement(now: born.addingTimeInterval(6 * 3600 - 60)))
        #expect(!attributes.needsReplacement(now: born.addingTimeInterval(6 * 3600)))
        #expect(attributes.needsReplacement(now: born.addingTimeInterval(6 * 3600 + 60)))
    }

    @Test func theMarginAgainstThePlatformCeilingIsReal() {
        // ActivityKit kills at eight hours and tells nobody. The rearm age exists
        // to stay clear of that; a future edit that narrows the margin below an
        // hour deserves a failing test and a decision entry, not a quiet nudge.
        #expect(ContractionActivityAttributes.rearmAge <= 7 * 3600)
        #expect(ContractionActivityAttributes.rearmAge >= 4 * 3600)
    }
}
