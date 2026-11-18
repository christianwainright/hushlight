import Foundation
import SwiftData
import Testing
@testable import LaborKit

/// The layer the one button actually talks to.
///
/// `LaborStoreTests` proves the store never loses a tap; this proves the model never
/// misreads what the store holds. The distinction is not academic — the QA harness's
/// worst finding lived entirely here (F-0002/F-0003): the store was correct
/// throughout while the model told the button the opposite, and the cost was a live
/// contraction that could never be closed and up to half a labor's timeline.
@MainActor
@Suite("Labor model")
struct LaborModelTests {
    private let base = Date(timeIntervalSince1970: 1_800_000_000)

    /// A suite-named domain per test: `LaborModel` persists the selected rule, and a
    /// test writing into `.standard` would leave its preference on the machine.
    private func makeModel(
        _ name: String,
        context: ModelContext? = nil
    ) throws -> LaborModel {
        let suite = "net.wainright.laborkit.\(name)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        return LaborModel(
            context: try context ?? ModelContext(LaborStore.container(inMemory: true)),
            defaults: defaults
        )
    }

    // MARK: One definition of running (F-0002)

    /// The state the clock could reach and the model could not describe: an older
    /// contraction still open beneath a newer completed one. `isRunning` read
    /// `contractions.last` — newest by *start* — and said no; `runningSince` looked
    /// for an open record and said yes. Both now derive from the same search.
    @Test func anOlderRunningRecordBeneathANewerCompletedOneStillReadsAsRunning() throws {
        // Inserted directly rather than tapped: the point is a record set the store
        // can legitimately hold, whatever route it arrived by.
        let context = ModelContext(try LaborStore.container(inMemory: true))
        context.insert(ContractionRecord(startedAt: base, endedAt: base.addingTimeInterval(60)))
        context.insert(ContractionRecord(startedAt: base.addingTimeInterval(-210)))
        try context.save()

        let model = try makeModel("outOfOrderRunning", context: context)

        #expect(model.contractions.last?.endedAt != nil, "the newest record by start is the completed one")
        #expect(model.isRunning)
        #expect(model.runningSince == base.addingTimeInterval(-210))
        #expect(model.isRunning == (model.runningSince != nil))

        // And the tap that follows must close the open record rather than no-op
        // against it.
        model.tap(at: base.addingTimeInterval(120))
        #expect(!model.isRunning)
        #expect(model.contractions.count == 2)
    }

    // MARK: The stop tap that became a start tap (F-0003)

    /// The full sequence the corpus caught, replayed through the model: a clean
    /// contraction, a device clock set backwards mid-labor, a second contraction
    /// stamped *earlier* than the first, then a stop tap.
    ///
    /// The stop tap used to call `beginContraction`, which no-opped against the
    /// still-open record: the live contraction could never be closed from the UI,
    /// every later tap no-opped too, and `undoAction` sat on `.started` — one undo
    /// from deleting the contraction being timed.
    @Test func aStopTapAfterABackwardClockSetEndsTheRunningContraction() throws {
        let model = try makeModel("clockSetBack")

        model.tap(at: base)                              // A starts
        model.tap(at: base.addingTimeInterval(60))       // A ends

        // The clock moves back five minutes, so the next tap is stamped before A.
        let bStart = base.addingTimeInterval(90 - 300)
        model.tap(at: bStart)
        guard case let .started(bID)? = model.undoAction else {
            Issue.record("the second start tap did not register as undoable")
            return
        }
        #expect(model.isRunning)
        #expect(model.runningSince == bStart)

        let bEnd = bStart.addingTimeInterval(45)
        model.tap(at: bEnd)

        // The tap ended B rather than starting a third record.
        #expect(!model.isRunning)
        #expect(model.contractions.count == 2)
        #expect(model.undoAction == .ended(id: bID))

        let b = try #require(model.contractions.first { $0.id == bID })
        #expect(b.endedAt == bEnd)

        // The timeline keeps growing: the next tap opens a third record instead of
        // no-opping against a record stuck open forever.
        model.tap(at: base.addingTimeInterval(200))
        #expect(model.contractions.count == 3)
        #expect(model.isRunning)
    }

    // MARK: Dating the empty state (decision 0022 §2)

    @Test func lastEndedAtIsNilUntilSomethingHasFinished() throws {
        let model = try makeModel("lastEndedEmpty")
        #expect(model.lastEndedAt == nil)

        model.tap(at: base)
        #expect(model.lastEndedAt == nil, "a running contraction has not ended")

        model.tap(at: base.addingTimeInterval(60))
        #expect(model.lastEndedAt == base.addingTimeInterval(60))
    }

    /// The newest end, not the newest start — a forgotten stop can leave an older
    /// contraction ending after a later one.
    @Test func lastEndedAtTakesTheNewestEnd() throws {
        let context = ModelContext(try LaborStore.container(inMemory: true))
        context.insert(ContractionRecord(
            startedAt: base, endedAt: base.addingTimeInterval(900)
        ))
        context.insert(ContractionRecord(
            startedAt: base.addingTimeInterval(300), endedAt: base.addingTimeInterval(360)
        ))
        try context.save()

        let model = try makeModel("lastEndedNewest", context: context)
        #expect(model.lastEndedAt == base.addingTimeInterval(900))
    }

    // MARK: - HL-027, the flagged sweep

    @Test func theSweepRemovesOnlyFlaggedRecords() throws {
        let model = try makeModel("sweepOnlyFlagged")

        model.tap(at: base)                                 // a real 90 s contraction
        model.tap(at: base.addingTimeInterval(90))
        model.tap(at: base.addingTimeInterval(300))         // a slip: 6 s
        model.tap(at: base.addingTimeInterval(306))
        model.tap(at: base.addingTimeInterval(600))         // a forgotten stop: 4 min
        model.tap(at: base.addingTimeInterval(840))

        #expect(model.contractions.count == 3)
        #expect(model.flaggedCount == 2)

        let removed = model.deleteFlagged()

        #expect(removed == 2)
        #expect(model.contractions.count == 1)
        // The survivor is the real one, identified by its own duration.
        #expect(model.contractions.first?.duration == .seconds(90))
        #expect(model.flaggedCount == 0)
    }

    @Test func theWholeSweepIsOneUndoAndEveryRecordComesBack() throws {
        let model = try makeModel("sweepUndo")

        model.tap(at: base)
        model.tap(at: base.addingTimeInterval(90))
        model.tap(at: base.addingTimeInterval(300))
        model.tap(at: base.addingTimeInterval(306))
        model.tap(at: base.addingTimeInterval(600))
        model.tap(at: base.addingTimeInterval(840))

        let before = model.contractions.map(\.id).sorted { $0.uuidString < $1.uuidString }
        model.deleteFlagged()
        #expect(model.contractions.count == 1)

        model.undo()

        // Every record back, with its own identity — not merely the right count.
        let after = model.contractions.map(\.id).sorted { $0.uuidString < $1.uuidString }
        #expect(after == before)
        #expect(model.flaggedCount == 2)
    }

    @Test func aRunningContractionIsNeverSweptHoweverLongItReads() throws {
        let model = try makeModel("sweepSpareRunning")

        model.tap(at: base)                                 // starts, never ended
        // Well past the three-minute suspicion bound, but still being measured.
        let pattern = model.pattern(now: base.addingTimeInterval(600))
        #expect(pattern.running != nil)

        #expect(model.flaggedCount == 0)
        #expect(model.deleteFlagged() == 0)
        #expect(model.contractions.count == 1)
    }

    @Test func aSweepWithNothingFlaggedChangesNothing() throws {
        let model = try makeModel("sweepNoop")

        model.tap(at: base)
        model.tap(at: base.addingTimeInterval(90))

        let undoBefore = model.undoAction
        #expect(model.deleteFlagged() == 0)
        #expect(model.contractions.count == 1)
        // A no-op sweep must not consume the undo slot a real correction is holding.
        #expect(model.undoAction == undoBefore)
    }

    // MARK: HL-018 — healing a split contraction

    /// The merged record's span is the earlier record's start and the later
    /// record's end — "what actually happened" per the item, not the slip's own
    /// short span and not a fresh duration invented from nowhere.
    @Test func mergeSpansFromTheEarlierStartToTheLaterEnd() throws {
        let model = try makeModel("mergeSpan")

        model.tap(at: base)                              // parent starts
        model.tap(at: base.addingTimeInterval(90))        // parent ends (a real 90s contraction)
        model.tap(at: base.addingTimeInterval(200))       // slip starts
        model.tap(at: base.addingTimeInterval(211))       // slip ends (11s — a slip, decision 0032)

        let slip = try #require(model.contractions.last)
        #expect(slip.suspicion == .tooShort)

        model.mergeWithPrevious(slip)

        #expect(model.contractions.count == 1)
        let merged = try #require(model.contractions.first)
        #expect(merged.startedAt == base)
        #expect(merged.endedAt == base.addingTimeInterval(211))
    }

    /// One Undo restores both original records exactly — same identities, same
    /// spans — not a fresh pair that merely looks the same.
    @Test func mergeUndoesToBothOriginalRecordsWithIdentity() throws {
        let model = try makeModel("mergeUndo")

        model.tap(at: base)
        model.tap(at: base.addingTimeInterval(90))
        model.tap(at: base.addingTimeInterval(200))
        model.tap(at: base.addingTimeInterval(211))

        let parentBefore = try #require(model.contractions.first)
        let slipBefore = try #require(model.contractions.last)

        model.mergeWithPrevious(slipBefore)
        #expect(model.contractions.count == 1)

        model.undo()

        #expect(model.contractions.count == 2)
        let parentAfter = try #require(model.contractions.first { $0.id == parentBefore.id })
        let slipAfter = try #require(model.contractions.first { $0.id == slipBefore.id })
        #expect(parentAfter == parentBefore)
        #expect(slipAfter == slipBefore)
        #expect(model.undoAction == nil)
    }

    /// The oldest record the store holds split from nothing — merge is absent for
    /// it, and calling the model op anyway is a safe no-op rather than a crash or
    /// a corrupted store.
    @Test func mergingTheOldestRecordIsANoOp() throws {
        let model = try makeModel("mergeOldest")

        model.tap(at: base)
        model.tap(at: base.addingTimeInterval(45))

        let onlyRecord = try #require(model.contractions.first)
        #expect(!model.canMergeWithPrevious(onlyRecord))
        let undoActionBefore = model.undoAction

        model.mergeWithPrevious(onlyRecord)

        #expect(model.contractions.count == 1)
        #expect(model.contractions.first == onlyRecord)
        // No side effect at all — not even the undo slot moves for a call the
        // model refused to act on.
        #expect(model.undoAction == undoActionBefore)
    }

    /// The UI offers "Merge Up" only on a suspect-short row, but the model
    /// operation itself has no such restriction — it is safe (and correct) to call
    /// against an ordinary, believable pair too.
    @Test func mergingANonSlipPairIsSafeAtTheModelLayer() throws {
        let model = try makeModel("mergeNonSlip")

        model.tap(at: base)
        model.tap(at: base.addingTimeInterval(70))               // an ordinary 70s contraction
        model.tap(at: base.addingTimeInterval(300))
        model.tap(at: base.addingTimeInterval(365))               // another ordinary contraction, not a slip

        let second = try #require(model.contractions.last)
        #expect(second.suspicion == nil, "not a slip — the merge op must still be safe against it")

        model.mergeWithPrevious(second)

        #expect(model.contractions.count == 1)
        let merged = try #require(model.contractions.first)
        #expect(merged.startedAt == base)
        #expect(merged.endedAt == base.addingTimeInterval(365))
    }

    /// A merge changes what the store holds, and the pattern the model reads back
    /// out reflects exactly that — no special-casing anywhere in the analysis path.
    @Test func theRecomputedPatternReflectsTheMerge() throws {
        let model = try makeModel("mergePattern")

        model.tap(at: base)
        model.tap(at: base.addingTimeInterval(90))
        model.tap(at: base.addingTimeInterval(200))
        model.tap(at: base.addingTimeInterval(211))

        let before = model.pattern(now: base.addingTimeInterval(300))
        #expect(before.inWindowCount == 2, "the slip's start still counts before the merge")

        let slip = try #require(model.contractions.last)
        model.mergeWithPrevious(slip)

        let after = model.pattern(now: base.addingTimeInterval(300))
        #expect(after.inWindowCount == 1)
        #expect(after.episode.first?.duration == .seconds(211))
    }

    /// Merging is never automatic and never called against a still-running
    /// contraction by any UI path, but the model must refuse it outright rather
    /// than deleting the contraction being timed out from under her.
    @Test func mergingAStillRunningContractionIsANoOp() throws {
        let model = try makeModel("mergeRunning")

        model.tap(at: base)
        model.tap(at: base.addingTimeInterval(90))
        model.tap(at: base.addingTimeInterval(200))               // second contraction still running

        let running = try #require(model.contractions.last)
        #expect(running.endedAt == nil)

        model.mergeWithPrevious(running)

        #expect(model.contractions.count == 2, "nothing was deleted")
        #expect(model.isRunning, "the live contraction is still live")
    }

    // MARK: The persisted rule (F-0013)

    /// The lock-screen intent reads the same key this writes. One definition, so the
    /// two surfaces cannot answer different questions about the same labor.
    @Test func theSelectedRuleIsReadableThroughTheSharedKey() throws {
        let suite = "net.wainright.laborkit.persistedRule"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }

        #expect(GuidelineRule.persisted(in: defaults) == .fiveOneOne, "the taught default stands")

        let model = LaborModel(
            context: ModelContext(try LaborStore.container(inMemory: true)),
            defaults: defaults
        )
        model.rule = .threeOneOne

        #expect(GuidelineRule.persisted(in: defaults) == .threeOneOne)
        #expect(defaults.string(forKey: GuidelineRule.defaultsKey) == "threeOneOne")
    }
}
