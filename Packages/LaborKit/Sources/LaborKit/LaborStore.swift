import Foundation
import SwiftData

/// Builds the contraction timer's `ModelContainer`.
///
/// **This store is local to the app on purpose** — the default sandbox location,
/// no App Group of any kind. Labor data is unreachable by
/// the fitness apps rather than filtered out of them, the same make-the-wrong-
/// thing-impossible move the sensitive-data fences use (decision 0018).
public enum LaborStore {
    public static let schema = Schema(versionedSchema: LaborSchemaV1.self)

    public static func container(inMemory: Bool = false) throws -> ModelContainer {
        try ModelContainer(
            for: schema,
            migrationPlan: LaborMigrationPlan.self,
            // Both exclusions stated rather than inherited. `.automatic` resolves to
            // no CloudKit and no group container today only because this target has
            // no entitlements file — which makes the guarantee live in a checkbox
            // nobody reads, one Signing & Capabilities click from flipping. Saying it
            // here is the same make-the-wrong-thing-impossible move the doc comment
            // above claims for the store's location.
            configurations: ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: inMemory,
                groupContainer: .none,
                cloudKitDatabase: .none
            )
        )
    }
}

// MARK: - Operations

extension ModelContext {
    /// The contraction currently running, if any. There can only be one: the UI is
    /// a single start/stop button, and `beginContraction` refuses to stack.
    public func runningContraction() throws -> ContractionRecord? {
        let descriptor = FetchDescriptor<ContractionRecord>(
            predicate: #Predicate { $0.endedAt == nil },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        return try fetch(descriptor).first
    }

    /// Starts a contraction now (or at `date`). If one is already running this is
    /// a no-op returning it — inventing an end time for the running one would be
    /// recording a moment nobody marked.
    @discardableResult
    public func beginContraction(at date: Date = Date()) throws -> ContractionRecord {
        if let running = try runningContraction() { return running }
        let record = ContractionRecord(startedAt: date)
        insert(record)
        try save()
        return record
    }

    /// Ends the running contraction. Nil when none is running — a stray end tap
    /// (double-tap, pocket) records nothing rather than something.
    @discardableResult
    public func endContraction(at date: Date = Date()) throws -> ContractionRecord? {
        guard let running = try runningContraction() else { return nil }
        // An end before its own start can only come from clock weirdness; clamp to
        // a zero-length contraction rather than storing a negative one.
        running.endedAt = max(date, running.startedAt)
        try save()
        return running
    }

    /// Every contraction, oldest first — the order the analysis wants.
    public func allContractions() throws -> [Contraction] {
        let descriptor = FetchDescriptor<ContractionRecord>(
            sortBy: [SortDescriptor(\.startedAt, order: .forward)]
        )
        return try fetch(descriptor).map(\.asContraction)
    }

    /// Mis-taps happen mid-labor; deletion is the correction model (decision 0018).
    public func deleteContraction(id: UUID) throws {
        let descriptor = FetchDescriptor<ContractionRecord>(
            predicate: #Predicate { $0.id == id }
        )
        guard let record = try fetch(descriptor).first else { return }
        delete(record)
        try save()
    }

    /// Restores a deleted contraction — the undo half of the correction model. Takes
    /// the value snapshot so the caller never holds a deleted record.
    ///
    /// **Verbatim, with one exception (F-0001).** A record deleted mid-contraction is
    /// still open, and by the time undo arrives a *different* contraction may have
    /// been started in the space the delete made. Reinserting the open record then
    /// leaves two running at once, which `beginContraction` exists to make
    /// impossible — and the damage is not cosmetic: the older runner is the one every
    /// later stop tap misses, so the live contraction can never be closed and every
    /// subsequent start no-ops against it.
    ///
    /// The fix closes the restored record at its own start rather than refusing the
    /// restore. Mis-taps are expected mid-labor and "undo restores it" has to stay
    /// true, so the row survives — as a zero-length contraction its owner can see and
    /// delete — while the single-running invariant holds. Inventing an end time from
    /// the clock would be recording a moment nobody marked; the start is the only
    /// instant this record can honestly claim.
    public func restoreContraction(_ contraction: Contraction) throws {
        var restored = contraction
        if contraction.endedAt == nil, try runningContraction() != nil {
            restored = Contraction(
                id: contraction.id,
                startedAt: contraction.startedAt,
                endedAt: contraction.startedAt
            )
        }
        insert(ContractionRecord(restoring: restored))
        try save()
    }

    /// Moves an already-ended record's `endedAt` forward in place, identity and
    /// `startedAt` untouched — the earlier half of a merge (HL-018, decision 0032's
    /// slip handling extended). `deleteContraction` removes the later record a merge
    /// absorbs; this is the counterpart that lets the earlier one claim the later
    /// record's end as its own, "what actually happened" per the item. A no-op, not
    /// an error, when the id is gone — the same tolerant shape `deleteContraction`
    /// already takes, so a caller that raced a concurrent delete degrades quietly
    /// rather than throwing mid-labor.
    public func extendContraction(id: UUID, endedAt: Date) throws {
        let descriptor = FetchDescriptor<ContractionRecord>(
            predicate: #Predicate { $0.id == id }
        )
        guard let record = try fetch(descriptor).first else { return }
        record.endedAt = endedAt
        try save()
    }

    /// Deletes every contraction. The full-clear a finished pregnancy deserves —
    /// deliberate and confirmed at the UI, and deliberately without an undo: a
    /// clear someone can casually reverse is a clear they were allowed to make
    /// casually. Same deletion stance as the suite's decision 0014.
    public func clearAllContractions() throws {
        try delete(model: ContractionRecord.self)
        try save()
    }
}
