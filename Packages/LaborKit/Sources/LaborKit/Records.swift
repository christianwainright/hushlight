import Foundation
import SwiftData

/// Versioned from day one, mirroring the fitness suite's `SchemaV1` convention —
/// adding V2 should be a mechanical edit, not a retrofit.
public enum LaborSchemaV1: VersionedSchema {
    public static let versionIdentifier = Schema.Version(1, 0, 0)
    public static var models: [any PersistentModel.Type] {
        [ContractionRecord.self]
    }
}

public enum LaborMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] { [LaborSchemaV1.self] }
    public static var stages: [MigrationStage] { [] }
}

/// One contraction: when it started, and when it ended if it has.
///
/// The schema is two timestamps on purpose. Duration, intervals, episode grouping
/// and the guideline verdict are all *derived* — storing any of them would be a
/// second copy of the truth that a deleted or corrected record could silently
/// orphan. There is no intensity field in v1: the brief asks for time measurements,
/// and a subjective 1–5 under duress is noise wearing a number.
@Model
public final class ContractionRecord {
    #Unique<ContractionRecord>([\.id])

    public private(set) var id: UUID
    public var startedAt: Date

    /// Nil while the contraction is running. Running state lives here, in the
    /// store, never in a timer — the phone locking or the app dying mid-labor
    /// must lose nothing.
    public var endedAt: Date?

    public init(startedAt: Date, endedAt: Date? = nil) {
        self.id = UUID()
        self.startedAt = startedAt
        self.endedAt = endedAt
    }

    /// Restore-with-identity, so an undone deletion is the same contraction and not
    /// a lookalike. `#Unique` makes a colliding restore an upsert, not a duplicate.
    public init(restoring contraction: Contraction) {
        self.id = contraction.id
        self.startedAt = contraction.startedAt
        self.endedAt = contraction.endedAt
    }
}

// MARK: - Value snapshot

/// The value-type view the analysis and the screens work from — same records ≠
/// contracts split as the fitness suite (decision 0009), for the same reason:
/// pure functions over values are testable without a container.
public struct Contraction: Equatable, Sendable, Identifiable {
    public let id: UUID
    public let startedAt: Date
    public let endedAt: Date?

    public init(id: UUID = UUID(), startedAt: Date, endedAt: Date? = nil) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
    }

    /// Nil while running.
    public var duration: Duration? {
        endedAt.map { .seconds($0.timeIntervalSince(startedAt)) }
    }

    /// Why a recorded length is not believable as a contraction — or nil when it is.
    /// Two ways a thumb misses, and they are not the same event to a reader, so the
    /// flag carries which one it is rather than making every surface re-derive it
    /// from the duration (decision 0032).
    public enum Suspicion: Equatable, Sendable {
        /// Longer than physiology — almost certainly a forgotten stop-tap.
        case tooLong
        /// Shorter than physiology — a double tap, or a pocket touch. The slip the
        /// walkthrough caught recorded eleven seconds.
        case tooShort
    }

    /// Nil for a running contraction (nothing to judge yet) and for any believable
    /// recorded length.
    public var suspicion: Suspicion? {
        guard let duration else { return nil }
        if duration > Self.suspectDuration { return .tooLong }
        if duration < Self.slipDuration { return .tooShort }
        return nil
    }

    /// Flagged in the history and excluded from duration averages rather than
    /// silently trusted; the *start* remains a real tap and still counts for
    /// intervals, whichever way the record is wrong.
    public var isSuspect: Bool { suspicion != nil }

    /// Over two minutes is already unusual; three is a forgotten stop-tap.
    public static let suspectDuration: Duration = .seconds(180)

    /// **A timer that is still running past the point a contraction would have
    /// ended** (SP-204). `suspicion` cannot answer this: it needs `endedAt`, so the
    /// CHECK flag structurally could not fire on the one record actually on screen —
    /// a timer left running ticked past twenty-five minutes looking entirely routine.
    ///
    /// The same three-minute bound as `.tooLong`, deliberately: this is the *live*
    /// form of exactly that judgement, and the app must not name one number while it
    /// is happening and a different one afterwards. Nothing is capped or auto-ended
    /// on the strength of it — a running record is still hers, and the app says what
    /// it sees rather than acting on it.
    public func isRunningLong(at now: Date) -> Bool {
        guard endedAt == nil else { return false }
        return Duration.seconds(now.timeIntervalSince(startedAt)) > Self.suspectDuration
    }

    /// **The slip floor** (decision 0032). Under this, a record is a tap artifact —
    /// a double tap, a pocket touch — rather than a short contraction: the QA
    /// corpus's own phantom pairs run 2–10 s and the mis-tap the walkthrough caught
    /// recorded eleven seconds.
    ///
    /// Twenty seconds is the measured choice, not a guess. Against corpus 2.0.0 it
    /// takes suppressions from 46 to 41 while false-met scenarios move 40 → 42 —
    /// four fewer labors whose true verdict never showed, for two more alarms, which
    /// is the trade decision 0021 §2's ranking law asks for (S4 above S2). Fifteen
    /// seconds measured 42/42: one suppression worse for the same alarm cost.
    ///
    /// **One number, three surfaces.** The timer's slip strip offers to delete at
    /// exactly this bound, History flags at it, and the duration mean excludes at
    /// it — so no record can be called a likely slip on one screen and averaged in
    /// on another.
    public static let slipDuration: Duration = .seconds(20)
}

extension ContractionRecord {
    public var asContraction: Contraction {
        Contraction(id: id, startedAt: startedAt, endedAt: endedAt)
    }
}
