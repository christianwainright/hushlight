import Foundation
import Testing
@testable import LaborKit

/// `PatternAnalysis.tape(for:window:now:)` is presentation math on the authoritative
/// path — the ember tape's bars are what a reader checks the app's continuity claim
/// against (decision 0037's rationale), so a wrong fraction here is a wrong picture,
/// not just a wrong number. Tolerances below use `abs(... ) < 0.0001`: Double division
/// over a one-hour window in seconds has no exact stopping point worth demanding.
@Suite("Tape geometry")
struct TapeGeometryTests {
    private let base = Date(timeIntervalSince1970: 1_800_000_000)
    private let hour: Duration = .seconds(60 * 60)

    private func contraction(
        startMinutesAgo: Double,
        lastingSeconds seconds: Double?,
        now: Date
    ) -> Contraction {
        let start = now.addingTimeInterval(-startMinutesAgo * 60)
        return Contraction(
            startedAt: start,
            endedAt: seconds.map { start.addingTimeInterval($0) }
        )
    }

    private func close(_ a: Double, _ b: Double) -> Bool { abs(a - b) < 0.0001 }

    // MARK: Right-alignment

    /// A contraction still running pins its bar's *end* to `now` — fraction 1 — no
    /// matter how far its start sits inside the window.
    @Test func aLiveContractionsBarEndsAtNow() {
        let now = base
        let running = contraction(startMinutesAgo: 2, lastingSeconds: nil, now: now)
        let geometry = PatternAnalysis.tape(for: [running], window: hour, now: now)

        #expect(geometry.bars.count == 1)
        let bar = geometry.bars[0]
        #expect(close(bar.start, 58.0 / 60.0))
        #expect(close(bar.start + bar.width, 1.0))
        #expect(bar.isLive)
    }

    /// A contraction that ended exactly at `now` lands its bar's end exactly at the
    /// right edge too — the live case is not the only way to reach fraction 1.
    @Test func aContractionEndingAtNowReachesTheRightEdge() {
        let now = base
        let ended = contraction(startMinutesAgo: 1, lastingSeconds: 60, now: now)
        let geometry = PatternAnalysis.tape(for: [ended], window: hour, now: now)

        #expect(geometry.bars.count == 1)
        #expect(close(geometry.bars[0].start + geometry.bars[0].width, 1.0))
        #expect(!geometry.bars[0].isLive)
    }

    // MARK: Clipping at the left edge

    /// A contraction that started before the window but ended inside it is clipped,
    /// not dropped: the bar starts at 0 and keeps its true end position, so what is
    /// missing from it is exactly the part that fell outside the hour (decision 0037
    /// §4).
    @Test func aBarBeginningBeforeTheWindowIsClippedNotDropped() {
        let now = base
        let straddling = contraction(startMinutesAgo: 70, lastingSeconds: 15 * 60, now: now)
        // Started 70 min ago, 15 min long -> ended 55 min ago, 5 min inside the hour.
        let geometry = PatternAnalysis.tape(for: [straddling], window: hour, now: now)

        #expect(geometry.bars.count == 1)
        let bar = geometry.bars[0]
        #expect(bar.start == 0)
        #expect(close(bar.width, 5.0 / 60.0))
    }

    // MARK: One bar, no gap artifact

    /// A single contraction with nothing else in the window produces exactly one bar
    /// at its true position — no phantom second bar, no gap-filling artifact.
    @Test func oneContractionProducesOneBarAtItsTruePosition() {
        let now = base
        let solo = contraction(startMinutesAgo: 30, lastingSeconds: 60, now: now)
        let geometry = PatternAnalysis.tape(for: [solo], window: hour, now: now)

        #expect(geometry.bars.count == 1)
        let bar = geometry.bars[0]
        // 30 minutes ago sits at the window's midpoint: 30 of the 60 minutes since
        // the left edge have passed.
        #expect(close(bar.start, 0.5))
        #expect(close(bar.width, 1.0 / 60.0))
        #expect(bar.suspicion == nil)
    }

    // MARK: Suspects at true scale

    /// A three-minute-plus record is drawn to true scale, not floored or clipped to
    /// something smaller — the tape is a raw-record surface (decision 0032 §1, 0037
    /// §5: "a three-minute bar dominates its neighbours because it dominated the
    /// hour").
    @Test func aTooLongSuspectDrawsAtTrueScale() {
        let now = base
        let over = contraction(startMinutesAgo: 10, lastingSeconds: 200, now: now)
        let geometry = PatternAnalysis.tape(for: [over], window: hour, now: now)

        #expect(geometry.bars.count == 1)
        let bar = geometry.bars[0]
        #expect(close(bar.width, 200.0 / 3600.0))
        #expect(bar.suspicion == .tooLong)
    }

    // MARK: The slip floor

    /// A slip well under the floor is raised to it, so it exists at all — a floor of
    /// visibility, not a lie of magnitude (decision 0037 §5).
    @Test func aSlipBelowTheFloorIsRaisedToIt() {
        let now = base
        let slip = contraction(startMinutesAgo: 20, lastingSeconds: 5, now: now)
        let trueWidth = 5.0 / 3600.0
        #expect(trueWidth < PatternAnalysis.tapeSlipWidthFloor) // the case actually exercises the floor

        let geometry = PatternAnalysis.tape(for: [slip], window: hour, now: now)

        #expect(geometry.bars.count == 1)
        let bar = geometry.bars[0]
        #expect(close(bar.width, PatternAnalysis.tapeSlipWidthFloor))
        #expect(bar.suspicion == .tooShort)
    }

    /// A slip whose true width already clears the floor is left alone — only a bar
    /// already under it is raised.
    @Test func aSlipAtOrAboveTheFloorIsNotAltered() {
        let now = base
        // 19 s is still a slip (< Contraction.slipDuration, 20 s) and its true
        // fraction (19/3600 ≈ 0.00528) already clears the floor (1/370 ≈ 0.0027).
        let slip = contraction(startMinutesAgo: 20, lastingSeconds: 19, now: now)
        let trueWidth = 19.0 / 3600.0
        #expect(trueWidth > PatternAnalysis.tapeSlipWidthFloor)

        let geometry = PatternAnalysis.tape(for: [slip], window: hour, now: now)
        #expect(close(geometry.bars[0].width, trueWidth))
    }

    // MARK: Empty and fully aged-out windows

    /// No contractions at all produces no bars — the resting tape's grid and baseline
    /// still have something to draw against an empty geometry, but that is
    /// DesignKit's concern, not this one's.
    @Test func anEmptyRecordSetProducesNoBars() {
        let geometry = PatternAnalysis.tape(for: [], window: hour, now: base)
        #expect(geometry.bars.isEmpty)
    }

    /// A record set that exists but has entirely aged out of the trailing window
    /// (every contraction ended long before the window started) also produces no
    /// bars — the same empty geometry as a genuinely empty store, which is what makes
    /// a lull read as honest emptiness rather than a stuck instrument.
    @Test func aWindowInWhichEveryBarHasAgedOutProducesNoBars() {
        let now = base
        let old = [
            contraction(startMinutesAgo: 200, lastingSeconds: 60, now: now),
            contraction(startMinutesAgo: 190, lastingSeconds: 60, now: now),
            contraction(startMinutesAgo: 180, lastingSeconds: 60, now: now)
        ]
        let geometry = PatternAnalysis.tape(for: old, window: hour, now: now)
        #expect(geometry.bars.isEmpty)
    }
}
