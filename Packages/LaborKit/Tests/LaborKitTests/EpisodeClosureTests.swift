import Foundation
import Testing
@testable import LaborKit

/// SP-215's whole point is that "does this stretch read as concluded" is a pure
/// function, so the guards are proven here instead of asserted in a comment. The
/// base case is comfortably past the threshold; every other test flips exactly one
/// guard and expects the recap to stay off.
@Suite("Episode closure")
struct EpisodeClosureTests {
    private let now = Date(timeIntervalSince1970: 1_756_000_000)

    private func concluded(
        lastEndedAt: TimeInterval? = -4 * 24 * 3600,
        isRunning: Bool = false
    ) -> Bool {
        EpisodeClosure.isConcluded(
            lastEndedAt: lastEndedAt.map { now.addingTimeInterval($0) },
            isRunning: isRunning,
            now: now
        )
    }

    @Test func fourDaysClearOfTheThresholdIsConcluded() {
        #expect(concluded())
    }

    @Test func bothSidesOfTheThreeDayThreshold() {
        let threshold = EpisodeClosure.recapThreshold.timeInterval
        // A second short of three days: not yet. Exactly three days, and a
        // second past it: concluded — the predicate is inclusive at the line.
        #expect(!concluded(lastEndedAt: -(threshold - 1)))
        #expect(concluded(lastEndedAt: -threshold))
        #expect(concluded(lastEndedAt: -(threshold + 1)))
    }

    @Test func aRecentRecordIsNotConcluded() {
        // A few hours old — well past `episodeGap`'s own 2 h staleness line, but
        // nowhere near "days".
        #expect(!concluded(lastEndedAt: -6 * 3600))
    }

    @Test func aRunningEpisodeIsNeverConcluded() {
        // Even with an old finished record sitting in the same episode, a
        // contraction being timed right now must block the recap outright.
        #expect(!concluded(lastEndedAt: -4 * 24 * 3600, isRunning: true))
    }

    @Test func anEmptyStoreIsNeverConcluded() {
        // No `lastEndedAt` at all — nothing has ever been recorded, so there is
        // no stretch to acknowledge.
        #expect(!concluded(lastEndedAt: nil))
    }

    @Test func aRunningFirstContractionWithNoPriorRecordIsNotConcluded() {
        // The very first contraction of an install, still open: `lastEndedAt` is
        // nil AND `isRunning` is true. Neither guard alone should be trusted to
        // carry the other's job.
        #expect(!concluded(lastEndedAt: nil, isRunning: true))
    }
}
