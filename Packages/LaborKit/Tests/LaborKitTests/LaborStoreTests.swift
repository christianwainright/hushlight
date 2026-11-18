import Foundation
import SwiftData
import Testing
@testable import LaborKit

/// The store's one job is to never lose a tap. Every case runs on an in-memory
/// container; the wall-clock-truth cases use two contexts over one container to
/// stand in for "before and after the app died".
@MainActor
@Suite("Labor store")
struct LaborStoreTests {
    private func makeContainer() throws -> ModelContainer {
        try LaborStore.container(inMemory: true)
    }

    @Test func beginningAndEndingRecordsOneContraction() throws {
        let context = ModelContext(try makeContainer())
        let start = Date(timeIntervalSince1970: 1_800_000_000)

        try context.beginContraction(at: start)
        try context.endContraction(at: start.addingTimeInterval(62))

        let all = try context.allContractions()
        #expect(all.count == 1)
        #expect(all[0].duration == .seconds(62))
    }

    /// The one-button flow cannot produce overlap, so the store refuses to: a
    /// second begin while one runs returns the running record untouched.
    @Test func beginningWhileRunningIsANoOp() throws {
        let context = ModelContext(try makeContainer())
        let start = Date(timeIntervalSince1970: 1_800_000_000)

        let first = try context.beginContraction(at: start)
        let second = try context.beginContraction(at: start.addingTimeInterval(30))

        #expect(second.id == first.id)
        #expect(try context.allContractions().count == 1)
    }

    @Test func endingWithNothingRunningRecordsNothing() throws {
        let context = ModelContext(try makeContainer())
        #expect(try context.endContraction() == nil)
        #expect(try context.allContractions().isEmpty)
    }

    /// A running contraction must survive the app dying: a fresh context over the
    /// same container — nothing carried in memory — still sees it running and can
    /// end it with the true duration.
    @Test func aRunningContractionSurvivesAFreshContext() throws {
        let container = try makeContainer()
        let start = Date(timeIntervalSince1970: 1_800_000_000)

        try ModelContext(container).beginContraction(at: start)

        let relaunched = ModelContext(container)
        let running = try #require(try relaunched.runningContraction())
        #expect(running.startedAt == start)

        try relaunched.endContraction(at: start.addingTimeInterval(75))
        let all = try relaunched.allContractions()
        #expect(all[0].duration == .seconds(75))
    }

    /// Clock weirdness (manual clock change, timezone jump) must not store a
    /// negative contraction.
    @Test func anEndBeforeItsStartClampsToZero() throws {
        let context = ModelContext(try makeContainer())
        let start = Date(timeIntervalSince1970: 1_800_000_000)

        try context.beginContraction(at: start)
        try context.endContraction(at: start.addingTimeInterval(-30))

        #expect(try context.allContractions()[0].duration == .zero)
    }

    @Test func deleteAndRestoreRoundTripsTheSameContraction() throws {
        let context = ModelContext(try makeContainer())
        let start = Date(timeIntervalSince1970: 1_800_000_000)

        try context.beginContraction(at: start)
        try context.endContraction(at: start.addingTimeInterval(60))
        let snapshot = try #require(try context.allContractions().first)

        try context.deleteContraction(id: snapshot.id)
        #expect(try context.allContractions().isEmpty)

        try context.restoreContraction(snapshot)
        let restored = try #require(try context.allContractions().first)
        // Same identity, not a lookalike — undo means it never happened.
        #expect(restored == snapshot)
    }

    /// F-0001, the direction the harness caught: a contraction deleted mid-run, a
    /// different one started in the space the delete made, then undo. The restored
    /// record must not become a second runner — the older one is what every later
    /// stop tap would miss, leaving the live contraction unclosable.
    @Test func restoringARunningRecordWhileAnotherRunsKeepsOneRunner() throws {
        let context = ModelContext(try makeContainer())
        let start = Date(timeIntervalSince1970: 1_800_000_000)

        try context.beginContraction(at: start)
        let deleted = try #require(try context.allContractions().first)
        #expect(deleted.endedAt == nil)
        try context.deleteContraction(id: deleted.id)

        try context.beginContraction(at: start.addingTimeInterval(20))
        try context.restoreContraction(deleted)

        let all = try context.allContractions()
        #expect(all.count == 2)
        #expect(all.filter { $0.endedAt == nil }.count == 1)

        // The row survives — "undo restores it" has to stay true — closed at its own
        // start rather than at a clock reading nobody marked.
        let restored = try #require(all.first { $0.id == deleted.id })
        #expect(restored.startedAt == deleted.startedAt)
        #expect(restored.endedAt == deleted.startedAt)

        // And the runner is still the one the user is actually timing, so the next
        // stop tap closes it.
        let running = try #require(try context.runningContraction())
        #expect(running.startedAt == start.addingTimeInterval(20))
        try context.endContraction(at: start.addingTimeInterval(80))
        #expect(try context.runningContraction() == nil)
    }

    /// The other direction: with nothing running, a restore is verbatim. The guard
    /// must not close records it was never asked to close.
    @Test func restoringARunningRecordWithNothingElseRunningIsVerbatim() throws {
        let context = ModelContext(try makeContainer())
        let start = Date(timeIntervalSince1970: 1_800_000_000)

        try context.beginContraction(at: start)
        let deleted = try #require(try context.allContractions().first)
        try context.deleteContraction(id: deleted.id)
        try context.restoreContraction(deleted)

        let restored = try #require(try context.allContractions().first)
        #expect(restored == deleted)
        #expect(restored.endedAt == nil)
        #expect(try context.runningContraction()?.id == deleted.id)
    }

    /// The earlier half of a merge (HL-018): identity and start untouched, only
    /// `endedAt` moves.
    @Test func extendContractionMovesOnlyTheEnd() throws {
        let context = ModelContext(try makeContainer())
        let start = Date(timeIntervalSince1970: 1_800_000_000)

        try context.beginContraction(at: start)
        try context.endContraction(at: start.addingTimeInterval(60))
        let original = try #require(try context.allContractions().first)

        try context.extendContraction(id: original.id, endedAt: start.addingTimeInterval(600))

        let extended = try #require(try context.allContractions().first)
        #expect(extended.id == original.id)
        #expect(extended.startedAt == original.startedAt)
        #expect(extended.endedAt == start.addingTimeInterval(600))
    }

    /// A vanished id (a race with a concurrent delete) degrades quietly rather than
    /// throwing mid-labor — the same tolerant shape `deleteContraction` takes.
    @Test func extendingAMissingIDIsANoOp() throws {
        let context = ModelContext(try makeContainer())
        try context.extendContraction(id: UUID(), endedAt: Date())
        #expect(try context.allContractions().isEmpty)
    }

    @Test func contractionsComeBackOldestFirst() throws {
        let context = ModelContext(try makeContainer())
        let base = Date(timeIntervalSince1970: 1_800_000_000)

        for offset in [300.0, 0.0, 600.0] {
            let start = base.addingTimeInterval(offset)
            context.insert(ContractionRecord(startedAt: start, endedAt: start.addingTimeInterval(60)))
        }
        try context.save()

        let starts = try context.allContractions().map(\.startedAt)
        #expect(starts == starts.sorted())
    }
}
