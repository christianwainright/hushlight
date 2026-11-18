import Foundation
import Testing
@testable import LaborKit

/// SP-216's whole point is that the eligibility decision is a pure function, so the
/// guards are proven here instead of asserted in a comment. The base case is the calm
/// the prompt is for; every other test flips exactly one guard and expects the door
/// to close.
@Suite("Review prompt eligibility")
struct ReviewPromptTests {
    private let now = Date(timeIntervalSince1970: 1_756_000_000)

    private func eligible(
        firstLaunch: TimeInterval? = -30 * 24 * 3600,
        newestRecordEnd: TimeInterval? = -10 * 24 * 3600,
        isRunning: Bool = false,
        lastClearAll: TimeInterval? = nil,
        alreadyAttempted: Bool = false
    ) -> Bool {
        ReviewPrompt.isEligible(
            now: now,
            firstLaunch: firstLaunch.map { now.addingTimeInterval($0) },
            newestRecordEnd: newestRecordEnd.map { now.addingTimeInterval($0) },
            isRunning: isRunning,
            lastClearAll: lastClearAll.map { now.addingTimeInterval($0) },
            alreadyAttempted: alreadyAttempted
        )
    }

    @Test func theCalmBaseCaseIsEligible() {
        #expect(eligible())
    }

    @Test func oneAttemptPerInstall() {
        #expect(!eligible(alreadyAttempted: true))
    }

    @Test func neverWhileAContractionRuns() {
        #expect(!eligible(isRunning: true))
    }

    @Test func aRecentEpisodeClosesTheDoor() {
        // Either side of the seven-day guard, deliberately: six days out is too
        // soon, eight is past it.
        #expect(!eligible(newestRecordEnd: -6 * 24 * 3600))
        #expect(eligible(newestRecordEnd: -8 * 24 * 3600))
    }

    @Test func anEmptyStoreIsNoBar() {
        // Never recorded anything: nothing implies a labor in progress.
        #expect(eligible(newestRecordEnd: nil))
    }

    @Test func aRecentClearAllReadsAsClosure() {
        // She just ended the record of her night; the app does not follow that
        // with "rate us." Same guard width as the episode's.
        #expect(!eligible(lastClearAll: -6 * 24 * 3600))
        #expect(eligible(lastClearAll: -8 * 24 * 3600))
    }

    @Test func theFirstDayIsTooSoon() {
        #expect(!eligible(firstLaunch: -12 * 3600))
        #expect(eligible(firstLaunch: -25 * 3600))
    }

    @Test func unknownAgeReadsAsFirstLaunch() {
        // An absent first-launch stamp proves nothing about age, and an unproven
        // age is treated as zero — the conservative direction.
        #expect(!eligible(firstLaunch: nil))
    }
}
