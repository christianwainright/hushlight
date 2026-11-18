import Foundation
import LaborKit
import LaborOracle
import SwiftData
import Testing
@testable import LaborSim

// The two container-backed legs. `ReplayEngine.fold` is a documented *model* of what
// the store does; these are the store itself, and the leg that matters is the one
// where they disagree.
//
// A note on what a scenario action means here. `tapStart`/`tapEnd` are the taps a
// thumb made, and the corpus is authored against the store's semantics: a start while
// something runs is a real tap that the store declines to act on (see `Noise.swift`'s
// forgotten-stop cascade). `LaborModel` exposes one toggling button instead, so the
// model leg below asks the *store* whether something is running before deciding which
// half of the toggle this tap is. Asking `LaborModel.isRunning` instead would be
// asking one of the two implementations under test to define the input.

// MARK: - Store leg

@MainActor
enum StoreReplay {
    struct Outcome {
        var final: [Contraction]
        var snapshots: [(probe: Int64, contractions: [Contraction])]
        var collector: ViolationCollector
        var agreement: LegAgreement
    }

    static func run(
        _ manifest: ScenarioManifest,
        leg: KnownFinding.Leg = .store,
        spotProbes: [Int64] = []
    ) throws -> Outcome {
        let container = try LaborStore.container(inMemory: true)
        var context = ModelContext(container)
        var collector = ViolationCollector(scenarioId: manifest.id, leg: leg)

        var idByCreator: [Int: UUID] = [:]
        var remembered: [Int: Contraction] = [:]
        var snapshots: [(probe: Int64, contractions: [Contraction])] = []
        var pending = spotProbes.sorted()
        var offset: Int64 = 0

        func date(_ seconds: Int64) -> Date { HarnessBridge.date(manifest.t0, seconds) }

        for (index, action) in manifest.actions.enumerated() {
            let effective = action.at + offset

            // Snapshots have to be taken on the fold's own boundary — every action at
            // or before the probe, nothing after it — or the two legs would be
            // compared at different instants and the disagreement would be the
            // harness's.
            while let next = pending.first, next < effective {
                snapshots.append((next, try context.allContractions()))
                pending.removeFirst()
            }

            switch action {
            case .tapStart:
                let runningBefore = try context.runningContraction()?.id
                let record = try context.beginContraction(at: date(effective))
                if let runningBefore {
                    // T0-10 — begin-while-running is a no-op returning the running
                    // record. Anything else means a second record just appeared.
                    if record.id != runningBefore {
                        collector.record("T0-10", at: effective, "begin-while-running created a record")
                    }
                } else {
                    idByCreator[index] = record.id
                }

            case .tapEnd:
                let runningBefore = try context.runningContraction()?.id
                let ended = try context.endContraction(at: date(effective))
                if runningBefore == nil, ended != nil {
                    // T0-10 — a stray end tap records nothing rather than something.
                    collector.record("T0-10", at: effective, "end-while-none returned a record")
                }

            case let .deleteRecord(_, createdBy):
                guard let id = idByCreator[createdBy],
                      let live = try contraction(id: id, in: context) else { break }
                remembered[createdBy] = live
                try context.deleteContraction(id: id)

            case let .undoDelete(_, createdBy):
                // Nothing remembered means nothing was deleted under this provenance;
                // the fold treats that as a no-op too, so this is not a divergence.
                guard let snapshot = remembered.removeValue(forKey: createdBy) else { break }
                // A restore that would stack a second open record closes the restored
                // one at its own start instead (F-0001), so what "round-tripped" means
                // is stated here rather than assumed — the collision is expected
                // behaviour now, and a driver that still demanded a verbatim record
                // would report the fix as the defect.
                let collides = try snapshot.endedAt == nil
                    && context.runningContraction() != nil
                try context.restoreContraction(snapshot)
                // T0-10 — a restore is the same contraction, not a lookalike.
                guard let restored = try contraction(id: snapshot.id, in: context) else {
                    collector.record("T0-10", at: effective, "restore did not round-trip the record")
                    break
                }
                let expected = collides
                    ? Contraction(
                        id: snapshot.id,
                        startedAt: snapshot.startedAt,
                        endedAt: snapshot.startedAt
                    )
                    : snapshot
                if restored != expected {
                    collector.record("T0-10", at: effective, "restored record differs from the deleted one")
                }

            case .killApp:
                // T0-09 — the process dies and a fresh context opens the same store.
                // Running state lives in the store or it does not survive at all.
                let before = try context.runningContraction()
                let beforeIdentity = before.map { ($0.id, $0.startedAt) }
                context = ModelContext(container)
                let after = try context.runningContraction()
                switch (beforeIdentity, after) {
                case (nil, nil):
                    break
                case let (identity?, record?):
                    if identity.0 != record.id || identity.1 != record.startedAt {
                        collector.record("T0-09", at: effective, "running record changed across a kill")
                    }
                default:
                    collector.record("T0-09", at: effective, "running record lost or invented across a kill")
                }

            case .launchApp, .timezoneChange, .setRule:
                break

            case let .clockSet(_, deltaSeconds):
                offset += deltaSeconds

            case .clearAll:
                try context.clearAllContractions()
                remembered.removeAll()
            }

            // T0-08 and the running-record invariant, after every single operation:
            // both are claims about what the store can ever hold, not about where it
            // ends up.
            let running = try runningRecords(in: context)
            if running.count > 1 {
                collector.record("T0-10", at: effective, "\(running.count) contractions running at once")
            }
            for record in running where record.endedAt != nil {
                collector.record("T0-08", at: effective, "running record carries an end")
            }
        }

        let final = try context.allContractions()
        for contraction in final {
            if let endedAt = contraction.endedAt, endedAt < contraction.startedAt {
                collector.record("T0-08", at: manifest.actions.last?.at ?? 0, "endedAt precedes startedAt")
                break
            }
        }
        while let next = pending.first {
            snapshots.append((next, final))
            pending.removeFirst()
        }

        // The fold comparison lives here rather than in the test so that one run of a
        // scenario produces one complete verdict. The registry's staleness check
        // replays a scenario and reads the collector; a divergence recorded outside the
        // driver would be invisible to it, and the entry covering it would read as stale.
        let agreement = agree(final, with: manifest, into: &collector)
        return Outcome(final: final, snapshots: snapshots, collector: collector, agreement: agreement)
    }

    static func agree(
        _ final: [Contraction], with manifest: ScenarioManifest, into collector: inout ViolationCollector
    ) -> LegAgreement {
        let expected = TimelineCompare.rows(ReplayEngine.fold(manifest.actions))
        let actual = TimelineCompare.rows(final, t0: manifest.t0)
        guard let difference = TimelineCompare.firstDifference(actual, expected) else {
            return LegAgreement(comparedWith: "pure", agrees: true)
        }
        // Hoisted: reading `collector` inside its own mutating call is an overlapping
        // access under exclusivity.
        let legName = collector.leg.rawValue
        collector.record("T0-02", at: manifest.actions.last?.at ?? 0,
                         "\(legName) timeline diverges from the fold: \(difference)")
        return LegAgreement(comparedWith: "pure", agrees: false, detail: difference)
    }

    static func contraction(id: UUID, in context: ModelContext) throws -> Contraction? {
        try context.fetch(
            FetchDescriptor<ContractionRecord>(predicate: #Predicate { $0.id == id })
        ).first?.asContraction
    }

    static func runningRecords(in context: ModelContext) throws -> [Contraction] {
        try context.fetch(
            FetchDescriptor<ContractionRecord>(predicate: #Predicate { $0.endedAt == nil })
        ).map(\.asContraction)
    }
}

// MARK: - Model leg

@MainActor
enum ModelReplay {
    struct Outcome {
        var final: [Contraction]
        var snapshots: [(probe: Int64, contractions: [Contraction])]
        var collector: ViolationCollector
        var agreement: LegAgreement
        /// Undos the app could not have performed, because `undoAction` had already
        /// moved on to a later edit. Applied through the store instead so the record
        /// set stays comparable; counted so the report can say how often the app's
        /// one-step undo is narrower than the scenario assumed.
        var undoOutOfReach: Int
    }

    /// A suite-named domain per scenario, torn down by the caller. `LaborModel`
    /// persists the selected rule, and a test that wrote it into `.standard` would
    /// leave the real app's preference behind on the machine that ran it.
    static func defaultsSuite(for manifest: ScenarioManifest) -> String {
        "net.wainright.laborsim.\(manifest.id)"
    }

    static func run(
        _ manifest: ScenarioManifest,
        leg: KnownFinding.Leg = .model,
        spotProbes: [Int64] = []
    ) throws -> Outcome {
        let suiteName = defaultsSuite(for: manifest)
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("could not open a suite-named UserDefaults for \(manifest.id)")
            return Outcome(
                final: [], snapshots: [],
                collector: ViolationCollector(scenarioId: manifest.id, leg: leg),
                agreement: LegAgreement(comparedWith: "pure", agrees: false, detail: "not run"),
                undoOutOfReach: 0
            )
        }
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let container = try LaborStore.container(inMemory: true)
        var context = ModelContext(container)
        var model = LaborModel(context: context, defaults: defaults)
        var collector = ViolationCollector(scenarioId: manifest.id, leg: leg)

        var idByCreator: [Int: UUID] = [:]
        var remembered: [Int: Contraction] = [:]
        var snapshots: [(probe: Int64, contractions: [Contraction])] = []
        var pending = spotProbes.sorted()
        var offset: Int64 = 0
        var undoOutOfReach = 0

        func date(_ seconds: Int64) -> Date { HarnessBridge.date(manifest.t0, seconds) }

        for (index, action) in manifest.actions.enumerated() {
            let effective = action.at + offset

            while let next = pending.first, next < effective {
                snapshots.append((next, model.contractions))
                pending.removeFirst()
            }

            switch action {
            case .tapStart:
                // The store's answer, not the model's — see this file's header.
                let running = try StoreReplay.runningRecords(in: context)
                guard running.isEmpty else { break }
                model.tap(at: date(effective))
                guard case let .started(id)? = model.undoAction else {
                    collector.record("T0-10", at: effective, "a start tap did not register as undoable")
                    break
                }
                idByCreator[index] = id

            case .tapEnd:
                let running = try StoreReplay.runningRecords(in: context)
                guard !running.isEmpty else { break }
                model.tap(at: date(effective))
                if case .ended = model.undoAction {} else {
                    collector.record("T0-10", at: effective, "an end tap did not register as undoable")
                }

            case let .deleteRecord(_, createdBy):
                guard let id = idByCreator[createdBy],
                      let live = model.contractions.first(where: { $0.id == id }) else { break }
                remembered[createdBy] = live
                model.delete(live)

            case let .undoDelete(_, createdBy):
                guard let snapshot = remembered.removeValue(forKey: createdBy) else { break }
                if case let .deleted(pendingContraction)? = model.undoAction,
                   pendingContraction.id == snapshot.id {
                    model.undo()
                } else {
                    // The app's undo is one step deep and this delete is no longer the
                    // last edit, so no sequence of taps could reach it. Restored
                    // through the store so the leg stays comparable with the fold,
                    // which models the correction rather than the button.
                    undoOutOfReach += 1
                    try context.restoreContraction(snapshot)
                    model.refresh()
                }

            case .killApp:
                context = ModelContext(container)
                model = LaborModel(context: context, defaults: defaults)

            case .launchApp, .timezoneChange:
                break

            case let .setRule(_, rule):
                if let parsed = GuidelineRule(rawValue: rule) { model.rule = parsed }

            case let .clockSet(_, deltaSeconds):
                offset += deltaSeconds

            case .clearAll:
                model.clearAll()
                remembered.removeAll()
            }

            // T0-10 — the same at-most-one-running claim the store leg makes, asked of
            // the snapshot the screens read rather than of the container.
            let running = model.contractions.filter { $0.endedAt == nil }
            if running.count > 1 {
                collector.record("T0-10", at: effective, "\(running.count) contractions running at once")
            }

            // T0-10a — a sentinel now rather than a probe. `isRunning` once read
            // `contractions.last` (newest by start) while `runningSince` found the
            // newest *open* record, and the two came apart whenever something older
            // was still open beneath something newer; the button follows `isRunning`,
            // so that gap cost a user her live contraction (F-0002/F-0003). Both
            // derive from one search since SP-194, which makes this structurally
            // unfirable — and that is the point: it goes red the moment anyone gives
            // "running" a second definition. Recorded rather than asserted inline so
            // a scenario reports it with the instant attached.
            if model.isRunning != (model.runningSince != nil) {
                collector.record("T0-10a", at: effective,
                                 "isRunning \(model.isRunning) but runningSince \(model.runningSince != nil)")
            }
        }

        while let next = pending.first {
            snapshots.append((next, model.contractions))
            pending.removeFirst()
        }

        let agreement = StoreReplay.agree(model.contractions, with: manifest, into: &collector)
        return Outcome(
            final: model.contractions, snapshots: snapshots,
            collector: collector, agreement: agreement, undoOutOfReach: undoOutOfReach
        )
    }
}

// MARK: - Timeline comparison

enum TimelineCompare {
    /// Ids aside. The store mints its own UUIDs and the fold derives them from
    /// provenance, so the only comparable identity is *which contraction this is* —
    /// its place in the ordered timeline, its start, its end, and whether it runs.
    struct Row: Equatable, CustomStringConvertible {
        var start: Int64
        var end: Int64?

        var description: String { "\(start)-\(end.map(String.init) ?? "running")" }
    }

    static func rows(_ contractions: [Contraction], t0: Int64) -> [Row] {
        contractions
            .map { Row(
                start: Int64($0.startedAt.timeIntervalSince1970) - t0,
                end: $0.endedAt.map { Int64($0.timeIntervalSince1970) - t0 }
            ) }
            .sorted { lhs, rhs in
                lhs.start != rhs.start ? lhs.start < rhs.start : (lhs.end ?? .max) < (rhs.end ?? .max)
            }
    }

    static func rows(_ records: [SimRecord]) -> [Row] {
        records
            .map { Row(start: $0.start, end: $0.end) }
            .sorted { lhs, rhs in
                lhs.start != rhs.start ? lhs.start < rhs.start : (lhs.end ?? .max) < (rhs.end ?? .max)
            }
    }

    /// The first disagreement, or nil. One row rather than a diff: a leg that has
    /// drifted has usually drifted everywhere after the first divergence, and the
    /// first one is the one that explains it.
    static func firstDifference(_ lhs: [Row], _ rhs: [Row]) -> String? {
        if lhs.count != rhs.count {
            return "row count \(lhs.count) vs \(rhs.count)"
        }
        for (index, pair) in zip(lhs, rhs).enumerated() where pair.0 != pair.1 {
            return "row \(index): \(pair.0) vs \(pair.1)"
        }
        return nil
    }
}
