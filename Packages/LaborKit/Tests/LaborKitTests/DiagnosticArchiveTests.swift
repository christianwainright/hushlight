import Foundation
import Testing
@testable import LaborKit

/// The on-device crash/hang archive (decision 0029 §3): bounded, newest first,
/// and unable to take the app down however its stored bytes rot.
@Suite("Diagnostic archive")
struct DiagnosticArchiveTests {
    private func freshDefaults(_ name: String) throws -> UserDefaults {
        let suite = "net.wainright.laborkit.\(name)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    private func summary(
        kind: DiagnosticSummary.Kind = .crash,
        detail: String = "signal 6"
    ) -> DiagnosticSummary {
        DiagnosticSummary(
            kind: kind,
            date: Date(timeIntervalSince1970: 1_724_400_000),
            appVersion: "1.0 (1)",
            osVersion: "27.0",
            detail: detail
        )
    }

    @Test func aRecordedSummaryReadsBackVerbatim() throws {
        let defaults = try freshDefaults("archiveRoundTrip")
        let recorded = summary()
        DiagnosticArchive.record(recorded, in: defaults)
        #expect(DiagnosticArchive.summaries(in: defaults) == [recorded])
    }

    @Test func newestComesFirst() throws {
        let defaults = try freshDefaults("archiveOrder")
        DiagnosticArchive.record(summary(detail: "first"), in: defaults)
        DiagnosticArchive.record(summary(detail: "second"), in: defaults)
        #expect(DiagnosticArchive.summaries(in: defaults).map(\.detail) == ["second", "first"])
    }

    @Test("The cap evicts the oldest, keeping the last few — not the first few")
    func theCapEvictsTheOldest() throws {
        let defaults = try freshDefaults("archiveCap")
        for index in ["one", "two", "three", "four", "five", "six", "seven"] {
            DiagnosticArchive.record(summary(detail: index), in: defaults)
        }
        let details = DiagnosticArchive.summaries(in: defaults).map(\.detail)
        #expect(details.count == DiagnosticArchive.maxEntries)
        #expect(details == ["seven", "six", "five", "four", "three"])
    }

    /// A diagnostics feature that could itself crash the app would be worse than
    /// none: garbage under the key reads as empty and recording over it recovers.
    @Test func garbageBytesReadAsEmptyAndRecordingRecovers() throws {
        let defaults = try freshDefaults("archiveGarbage")
        defaults.set(Data("not json at all".utf8), forKey: DiagnosticArchive.defaultsKey)
        #expect(DiagnosticArchive.summaries(in: defaults).isEmpty)

        DiagnosticArchive.record(summary(), in: defaults)
        #expect(DiagnosticArchive.summaries(in: defaults).count == 1)
    }

    @Test func countsSplitByKind() throws {
        let defaults = try freshDefaults("archiveCounts")
        DiagnosticArchive.record(summary(kind: .crash), in: defaults)
        DiagnosticArchive.record(summary(kind: .hang, detail: "hang of about 3 seconds"), in: defaults)
        DiagnosticArchive.record(summary(kind: .crash), in: defaults)
        let counts = DiagnosticArchive.counts(in: defaults)
        #expect(counts.crashes == 2)
        #expect(counts.hangs == 1)
    }
}
