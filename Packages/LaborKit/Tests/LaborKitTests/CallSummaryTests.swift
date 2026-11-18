import Foundation
import Testing
@testable import LaborKit

/// SP-206's script: "how far apart, how long, since when, how many," composed
/// into one sentence a person reads aloud over the phone. The evidence-floor
/// tests are the point — a clause below its floor must vanish outright, never
/// print a dash or a zero mid-sentence (a spoken script with a dash in it reads
/// as a stumble).
@Suite("Call summary")
struct CallSummaryTests {
    /// Fixed clock; every test builds its own timeline against this. The `since`
    /// clause is asserted against `base.formatted(...)` rather than a literal
    /// clock string, so the test passes under whatever timezone and locale the
    /// runner happens to have — the composition under test, not the formatter's
    /// environment, is what these tests exist to pin down.
    private let base = Date(timeIntervalSince1970: 1_800_000_000)

    private func starts(_ offsetsSeconds: [Double], lastingSeconds seconds: Double? = 62) -> [Contraction] {
        offsetsSeconds.map { offset in
            let start = base.addingTimeInterval(offset)
            return Contraction(startedAt: start, endedAt: seconds.map { start.addingTimeInterval($0) })
        }
    }

    private var since: String { base.formatted(date: .omitted, time: .shortened) }

    // MARK: Every clause present

    /// The shape SP-206's own backlog example uses: intervals of 4:20, 5:00, 5:00,
    /// 5:40 average to a clean 5:00 with a visible spread, and five 62 s
    /// contractions give "1:02" for the duration clause.
    @Test func everyClauseRendersWhenEveryFloorIsCleared() throws {
        let episode = starts([0, 260, 560, 860, 1200])

        let summary = try #require(PatternAnalysis.callSummary(of: episode))

        #expect(
            summary.text
                == "Contractions every 5:00 on average (ranging 4:20–5:40), "
                + "lasting about 1:02, since \(since) — 5 so far."
        )
    }

    // MARK: Floor omissions

    /// Below two intervals (decision 0024's floor for the mean and its range) and
    /// below three usable durations at once — a two-contraction episode clears
    /// neither. Both clauses vanish; the sentence still says since when and how
    /// many, the two raw facts no floor gates.
    @Test func intervalAndDurationClausesOmitBelowTwoContractions() throws {
        let episode = starts([0, 300])

        let summary = try #require(PatternAnalysis.callSummary(of: episode))

        #expect(summary.text == "Contractions since \(since) — 2 so far.")
    }

    /// Three contractions clear the two-interval floor (interval clause renders)
    /// while a contraction still running holds usable durations to two — one
    /// short of the three-duration floor — so the duration clause alone omits.
    /// The comma the interval clause would otherwise hand off to must not survive
    /// on its own.
    @Test func durationClauseOmitsBelowItsThreeUsableFloorWhileIntervalSurvives() throws {
        var episode = starts([0, 300], lastingSeconds: 62)
        episode.append(Contraction(startedAt: base.addingTimeInterval(600))) // still running

        let summary = try #require(PatternAnalysis.callSummary(of: episode))

        #expect(
            summary.text
                == "Contractions every 5:00 on average, since \(since) — 3 so far."
        )
    }

    /// A lone contraction has no gap and no floor-clearing average of anything —
    /// only the two raw facts a nurse still gets an answer to.
    @Test func theOneContractionEpisodeSaysOneSoFarWithNoAverages() throws {
        let episode = starts([0])

        let summary = try #require(PatternAnalysis.callSummary(of: episode))

        #expect(summary.text == "Contractions since \(since) — 1 so far.")
    }

    // MARK: Suspects

    /// A forgotten stop-tap (too long) and a slip (too short) sit inside an
    /// otherwise-textbook six-contraction stretch. Both are excluded from the
    /// duration clause exactly as `EpisodeSummary.averageDuration` already
    /// excludes them — the four believable durations average to 62 s regardless
    /// of the two outliers — while their *starts* still count toward the
    /// interval clause and the trailing count, the same "a tap is a tap" rule
    /// `PatternAnalysis` states for a running record.
    @Test func suspectDurationsAreExcludedExactlyAsEpisodeSummaryExcludesThem() throws {
        let spacing = 300.0
        let offsets = (0..<6).map { Double($0) * spacing }
        var episode = starts(offsets, lastingSeconds: 62)
        episode[2] = Contraction(
            id: episode[2].id,
            startedAt: episode[2].startedAt,
            endedAt: episode[2].startedAt.addingTimeInterval(4) // too short — a slip
        )
        episode[4] = Contraction(
            id: episode[4].id,
            startedAt: episode[4].startedAt,
            endedAt: episode[4].startedAt.addingTimeInterval(200) // too long — a forgotten stop
        )

        let summary = try #require(PatternAnalysis.callSummary(of: episode))

        #expect(
            summary.text
                == "Contractions every 5:00 on average, "
                + "lasting about 1:02, since \(since) — 6 so far.",
            "the suspects stay in the count and the spacing, only out of the duration mean"
        )
    }

    // MARK: Empty input

    /// A flat range — every gap identical — drops the parenthesis: "ranging
    /// 5:00–5:00" says nothing the mean did not, and this sentence is meant to be
    /// spoken. The clause returns the moment the spread is real, which is when
    /// decision 0024 needs it keeping the mean honest.
    @Test func aFlatRangeDropsTheRangingParenthesis() {
        let base = Date(timeIntervalSince1970: 1_800_000_000)
        let episode = (0..<6).map { i in
            Contraction(
                startedAt: base.addingTimeInterval(Double(i) * 300),
                endedAt: base.addingTimeInterval(Double(i) * 300 + 62)
            )
        }
        let summary = PatternAnalysis.callSummary(of: episode)
        #expect(summary?.text.contains("every 5:00 on average,") == true)
        #expect(summary?.text.contains("ranging") == false)
    }

    @Test func theEmptyEpisodeProducesNoSummary() {
        #expect(PatternAnalysis.callSummary(of: []) == nil)
    }
}
