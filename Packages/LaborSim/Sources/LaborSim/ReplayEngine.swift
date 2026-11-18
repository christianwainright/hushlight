import Foundation
import LaborKit

// The pure fold: [ScenarioAction] -> the record state the store would hold, at any
// probe time. It mirrors the documented semantics of `ModelContext`'s contraction
// operations without touching SwiftData, so the engine leg (this file) and the store
// leg (the real app driving real `ModelContext` calls) can be compared against a
// common expectation. Neither leg is the oracle; agreement between them is the test.

/// One record as the store would hold it. `createdBy` is the index of the action
/// that created it — records are addressed by provenance, never by store position,
/// because a delete renumbers every later position and nothing else.
public struct SimRecord: Sendable, Equatable, Identifiable {
    public var createdBy: Int
    public var id: UUID
    public var start: Int64
    public var end: Int64?     // nil while running

    public init(createdBy: Int, id: UUID, start: Int64, end: Int64? = nil) {
        self.createdBy = createdBy
        self.id = id
        self.start = start
        self.end = end
    }
}

public enum ReplayEngine {
    // MARK: - Fold

    /// The fold, as a resumable walk.
    ///
    /// `fold(_:through:)` is one `advance(to:)` on a fresh cursor, and every rule
    /// lives here so the two can never disagree. The cursor exists because the mass
    /// sweep asks for the same scenario at a thousand ascending probe times, and
    /// re-folding the whole action list at each one is quadratic in a package whose
    /// whole job is to run four hundred scenarios inside a test loop.
    ///
    /// Resuming is exact rather than approximate: the fold is a *prefix* walk that
    /// stops at the first action past the probe, so stopping and continuing lands on
    /// precisely the state a from-scratch fold would have reached. Probes must
    /// therefore be non-decreasing, and the cursor traps rather than quietly
    /// returning a wrong answer if they are not.
    public struct Cursor {
        private let actions: [ScenarioAction]
        private var index = 0
        private var offset: Int64 = 0
        private var records: [SimRecord] = []
        private var remembered: [Int: SimRecord] = [:]
        private var lastProbe: Int64?

        /// Bumped on every change to the record set, and *only* then. Callers use it
        /// to skip work that depends on the records but not on `now` — the episode
        /// partition, the suspect predicate — which between two taps is a constant
        /// being recomputed a few hundred times.
        public private(set) var generation = 0

        public init(_ actions: [ScenarioAction]) {
            self.actions = actions
        }

        @discardableResult
        public mutating func advance(to probe: Int64) -> [SimRecord] {
            if let lastProbe {
                precondition(probe >= lastProbe, "ReplayEngine.Cursor probes must not go backwards")
            }
            lastProbe = probe

            while index < actions.count {
                let action = actions[index]
                // Computed with the offset as it stood *before* this action, so a
                // clockSet's own effective time is unaffected by the jump it causes.
                let effectiveTime = action.at + offset
                if effectiveTime > probe { break }
                apply(action, createdBy: index, at: effectiveTime)
                index += 1
            }
            return records
        }

        /// Which record a stop-tap closes.
        ///
        /// Since F-0001 the answer is always "the only open one" — `undoDelete` now
        /// closes a restored record rather than stacking a second runner. The search
        /// is kept rather than collapsed to `firstIndex(where:)` because the *store*
        /// states its fetch order as contract: `endedAt == nil` sorted by `startedAt`
        /// descending, first match, so the **latest-started** record wins. Modelling
        /// that order is what lets the fold notice if the store ever holds two again;
        /// a model that assumed uniqueness would agree with the bug.
        private func latestRunningIndex() -> Int? {
            records.indices
                .filter { records[$0].end == nil }
                .max { lhs, rhs in
                    (records[lhs].start, records[lhs].createdBy)
                        < (records[rhs].start, records[rhs].createdBy)
                }
        }

        private mutating func apply(_ action: ScenarioAction, createdBy: Int, at effectiveTime: Int64) {
            switch action {
            case .tapStart:
                // Single start/stop button; the store refuses to stack. Inventing an
                // end for the running record would record a moment nobody marked.
                if records.contains(where: { $0.end == nil }) { return }
                records.append(
                    SimRecord(
                        createdBy: createdBy,
                        id: deterministicUUID(createdBy: createdBy),
                        start: effectiveTime,
                        end: nil
                    )
                )
                generation += 1

            case .tapEnd:
                // A stray tap with nothing running records nothing.
                guard let runningIndex = latestRunningIndex() else { return }
                // An end before its own start clamps to zero-length rather than
                // storing a negative duration.
                records[runningIndex].end = max(effectiveTime, records[runningIndex].start)
                generation += 1

            case let .deleteRecord(_, target):
                guard let i = records.firstIndex(where: { $0.createdBy == target }) else { return }
                remembered[target] = records.remove(at: i)
                generation += 1

            case let .undoDelete(_, target):
                // Reinsert with identity intact (same createdBy, same UUID, same
                // start) so the restored contraction is the same one, not a lookalike.
                // A record that was still running when it was deleted comes back
                // closed at its own start *if* something else is running by now —
                // the store refuses to hold two open records, and reinserting one
                // anyway is F-0001.
                guard var record = remembered.removeValue(forKey: target) else { return }
                if record.end == nil, records.contains(where: { $0.end == nil }) {
                    record.end = record.start
                }
                records.append(record)
                generation += 1

            case .killApp, .launchApp, .timezoneChange, .setRule:
                // Process and display events, and a rule swap the caller interprets
                // — none of them touch a stored record.
                break

            case let .clockSet(_, deltaSeconds):
                // Shifts how every SUBSEQUENT action maps to epoch time. Rewrites
                // nothing already stored — a device clock change does not edit
                // history.
                offset += deltaSeconds

            case .clearAll:
                // Deliberately un-undoable: also drops `remembered`, so a clear
                // someone can casually reverse is a clear they were allowed to make
                // casually. There is no `undoDelete` target left for it to hit.
                records.removeAll()
                remembered.removeAll()
                generation += 1
            }
        }
    }

    /// Folds every action whose *effective* time is <= `probe`.
    ///
    /// Effective time is `action.at + offset`, where `offset` is the running sum of
    /// every `clockSet` delta seen so far in array order. Because `clockSet` can move
    /// later actions *backwards* in epoch time, the walk cannot be reordered by
    /// sorting on effective time without changing which actions land before the
    /// probe — the fold is defined by action order, full stop, exactly as the phone
    /// processes taps in the order the thumb made them, whatever the clock says.
    public static func fold(_ actions: [ScenarioAction], through probe: Int64) -> [SimRecord] {
        var cursor = Cursor(actions)
        return cursor.advance(to: probe)
    }

    public static func fold(_ actions: [ScenarioAction]) -> [SimRecord] {
        fold(actions, through: .max)
    }

    /// Orders by `start` ascending, ties broken by `createdBy` ascending. Two
    /// records can genuinely share a start second — a restore-while-running
    /// collision, a clock jump — and an order that depended on iteration or
    /// insertion position would be nondeterministic across runs.
    public static func sorted(_ records: [SimRecord]) -> [SimRecord] {
        records.sorted { lhs, rhs in
            lhs.start != rhs.start ? lhs.start < rhs.start : lhs.createdBy < rhs.createdBy
        }
    }

    // MARK: - LaborKit projection

    /// LaborKit values for the analysis leg. `t0` is the manifest's epoch anchor;
    /// every stored second is relative to it.
    public static func contractions(_ actions: [ScenarioAction], at probe: Int64, t0: Int64) -> [Contraction] {
        sorted(fold(actions, through: probe)).map { record in
            Contraction(
                id: record.id,
                startedAt: Date(timeIntervalSince1970: TimeInterval(t0 + record.start)),
                endedAt: record.end.map { Date(timeIntervalSince1970: TimeInterval(t0 + $0)) }
            )
        }
    }

    // MARK: - Identity

    /// Arbitrary-but-fixed marker: the ASCII bytes of "LaborSimFold" (12 bytes),
    /// chosen only to be recognisable in a debugger dump, not for any semantic
    /// reason. `createdBy` fills the last 4 bytes as a big-endian `UInt32`, so the
    /// same createdBy always yields the same UUID — across runs and machines, which
    /// a golden fixture depends on: one that embedded a random UUID would fail on
    /// every run.
    private static let uuidPrefix: [UInt8] = Array("LaborSimFold".utf8)

    public static func deterministicUUID(createdBy: Int) -> UUID {
        let value = UInt32(truncatingIfNeeded: createdBy)
        let suffix: [UInt8] = [
            UInt8((value >> 24) & 0xFF),
            UInt8((value >> 16) & 0xFF),
            UInt8((value >> 8) & 0xFF),
            UInt8(value & 0xFF),
        ]
        let bytes = uuidPrefix + suffix
        return UUID(
            uuid: (
                bytes[0], bytes[1], bytes[2], bytes[3],
                bytes[4], bytes[5], bytes[6], bytes[7],
                bytes[8], bytes[9], bytes[10], bytes[11],
                bytes[12], bytes[13], bytes[14], bytes[15]
            )
        )
    }

    // MARK: - Probe instants

    /// Every instant worth asking the engine about.
    ///
    /// The ±1 probes are the entire point — a boundary tested only *at* its value
    /// proves nothing about which side it falls on. A rule that fires "at 300.0
    /// seconds of mean interval" needs a probe at 299 and 301, not just 300, or an
    /// off-by-one in either engine would sail through untested.
    public static func probeTimes(for manifest: ScenarioManifest) -> [Int64] {
        probeTimes(for: manifest, cadence: defaultCadenceSeconds)
    }

    /// The rubric's grid cadence: one probe a minute between the targeted boundary
    /// points.
    public static let defaultCadenceSeconds: Int64 = 60

    /// The coarser cadence, and the span above which it applies.
    ///
    /// A three-day prodromal scenario at 60 s is 4 300 periodic probes asking the
    /// same question of a store that changed twice an hour, and forty of those
    /// scenarios is most of the suite's runtime. Only the *periodic sweep* coarsens:
    /// every action probe, truth-zone boundary and derived knife-edge is kept at full
    /// precision, because those are the instants that decide anything. The threshold
    /// sits above the longest single-day archetype so no ordinary labor is coarsened.
    public static let coarseCadenceSeconds: Int64 = 300
    public static let coarseCadenceAboveSeconds: Int64 = 16 * 3600

    /// The cadence this scenario's periodic sweep should use.
    public static func cadence(for manifest: ScenarioManifest) -> Int64 {
        guard let first = manifest.actions.first?.at, let last = manifest.actions.last?.at,
              last - first > coarseCadenceAboveSeconds else { return defaultCadenceSeconds }
        return coarseCadenceSeconds
    }

    public static func probeTimes(for manifest: ScenarioManifest, cadence: Int64) -> [Int64] {
        var probes: Set<Int64> = []

        func addWithNeighbors(_ t: Int64) {
            probes.insert(t)
            probes.insert(t - 1)
            probes.insert(t + 1)
        }

        for action in manifest.actions {
            addWithNeighbors(action.at)
        }

        for zone in manifest.truth.zones {
            addWithNeighbors(zone.from)
            addWithNeighbors(zone.to)
        }

        // Window knife-edges, derived from the full fold's actual record starts —
        // not from `trueContractions` — because noise, deletes, and undos can shift
        // where a record starts relative to the body's true timeline, and it is the
        // *stored* start the one-hour/two-hour windows measure from.
        for record in fold(manifest.actions) {
            let s = record.start
            addWithNeighbors(s + 3600)  // falls out of the rule's one-hour analysis window
            addWithNeighbors(s + 7200)  // episode/staleness boundary
        }

        // Coarse sweep so no multi-minute stretch between the targeted boundary
        // points above goes unprobed. Array-positional first/last, not min/max —
        // this engine never assumes actions are sorted by effective time (a
        // clockSet can reorder that), only that they were authored in walk order,
        // and the sweep's job is to bracket that authored range.
        if let first = manifest.actions.first?.at, let last = manifest.actions.last?.at {
            var t = first
            while t <= last + 7200 {
                probes.insert(t)
                t += cadence
            }
        }

        return probes.filter { $0 >= 0 }.sorted()
    }

    // MARK: - Suspects

    /// Records the app should flag as suspect — recorded length strictly over 180 s,
    /// or strictly under 20 s (decision 0032) — as creating-action indices. Derived
    /// from the fold rather than from the noise model, so the two can never drift
    /// apart: whatever the fold actually produces is what gets judged, not what the
    /// generator intended to produce.
    public static func expectedSuspects(_ actions: [ScenarioAction]) -> [Int] {
        fold(actions)
            .filter { record in
                guard let end = record.end else { return false }
                let duration = end - record.start
                return duration > 180 || duration < 20
            }
            .map(\.createdBy)
            .sorted()
    }
}
