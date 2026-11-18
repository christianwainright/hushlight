import Foundation
import SwiftData
import Testing
@testable import LaborKit

/// SP-189: the history screen's episode bands and the full clear.
@Suite("Episode summaries and clear-all")
struct EpisodeSummaryTests {
    private let base = Date(timeIntervalSince1970: 1_800_000_000)

    private func series(count: Int, spacingMinutes: Double, durationSeconds: Double = 62) -> [Contraction] {
        (0..<count).map {
            let start = base.addingTimeInterval(Double($0) * spacingMinutes * 60)
            return Contraction(startedAt: start, endedAt: start.addingTimeInterval(durationSeconds))
        }
    }

    @Test func aSummaryCarriesTheProviderConversationFigures() throws {
        let summary = try #require(PatternAnalysis.summary(of: series(count: 14, spacingMinutes: 5)))
        #expect(summary.count == 14)
        #expect(summary.span == .seconds(13 * 5 * 60))
        #expect(summary.averageInterval == .seconds(300))
        #expect(summary.averageDuration == .seconds(62))
    }

    /// History honors the same floors as the live readout — two contractions have
    /// a span and a count, never an average.
    @Test func summariesKeepTheEvidenceFloors() throws {
        let summary = try #require(PatternAnalysis.summary(of: series(count: 2, spacingMinutes: 5)))
        #expect(summary.count == 2)
        #expect(summary.averageInterval == nil)
        #expect(summary.averageDuration == nil)
        // Two contractions do have a real span between them.
        #expect(summary.span == .seconds(300))
    }

    /// A lone contraction is its own episode when the neighbours are hours away. It
    /// has a count and nothing else — a span of zero is not a measurement, and
    /// History must print no span at all rather than "0 M".
    @Test func aLoneContractionHasNoSpan() throws {
        let summary = try #require(PatternAnalysis.summary(of: series(count: 1, spacingMinutes: 5)))
        #expect(summary.count == 1)
        #expect(summary.span == nil)
        #expect(summary.averageInterval == nil)
        #expect(summary.averageDuration == nil)
    }

    /// The shared start-to-start definition every surface reads from.
    @Test func startToStartIntervalsComeFromOneDefinition() {
        let episode = series(count: 4, spacingMinutes: 5)
        #expect(PatternAnalysis.startToStartIntervals(episode) == [.seconds(300), .seconds(300), .seconds(300)])
        #expect(PatternAnalysis.interval(from: episode[0], to: episode[3]) == .seconds(900))
        // One contraction has no gap.
        #expect(PatternAnalysis.startToStartIntervals([episode[0]]).isEmpty)
    }

    @Test func suspectDurationsStayOutOfSummaryAverages() throws {
        var episode = series(count: 4, spacingMinutes: 5)
        let victim = episode[1]
        episode[1] = Contraction(
            id: victim.id,
            startedAt: victim.startedAt,
            endedAt: victim.startedAt.addingTimeInterval(20 * 60)
        )
        let summary = try #require(PatternAnalysis.summary(of: episode))
        // Three clean 62 s durations; the forgotten-tap monster excluded.
        #expect(summary.averageDuration == .seconds(62))
        #expect(summary.count == 4)
    }

    @Test func anEmptyEpisodeHasNoSummary() {
        #expect(PatternAnalysis.summary(of: []) == nil)
    }

    // MARK: Clear-all

    @MainActor
    @Test func clearAllDeletesEveryContraction() throws {
        let context = ModelContext(try LaborStore.container(inMemory: true))
        for offset in [0.0, 300, 600] {
            let start = base.addingTimeInterval(offset)
            context.insert(ContractionRecord(startedAt: start, endedAt: start.addingTimeInterval(60)))
        }
        try context.save()
        #expect(try context.allContractions().count == 3)

        try context.clearAllContractions()
        #expect(try context.allContractions().isEmpty)
        // And the store still works afterwards — a clear is a reset, not a wound.
        try context.beginContraction(at: base.addingTimeInterval(9_000))
        #expect(try context.allContractions().count == 1)
    }
}
