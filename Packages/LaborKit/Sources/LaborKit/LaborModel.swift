import ActivityKit
import Foundation
import Observation
import SwiftData

/// The contraction timer's one store: taps in, pattern out.
///
/// Unlike the fitness suite's stores there is no cross-process anything here — one
/// app, its own container (decision 0018) — so this is deliberately the simplest
/// shape in the ecosystem: every mutation reloads the snapshot, and the pattern is
/// recomputed on demand because it changes with the clock even when no one taps.
///
/// Lives in LaborKit (not the app target) so the QA harness (Phase 1) and package
/// tests can drive it directly against an in-memory container, the same way
/// `LaborStoreTests` already does.
@MainActor
@Observable
public final class LaborModel {
    private let context: ModelContext

    /// Every contraction ever logged, oldest first — the snapshot the screens and
    /// the analysis read. Small in practice: even a long labor is a few hundred rows.
    public private(set) var contractions: [Contraction] = []

    /// What one tap of the undo button would take back.
    public enum UndoAction: Equatable {
        /// The last tap started this contraction; undo deletes it.
        case started(id: UUID)
        /// The last tap ended this contraction; undo sets it running again.
        case ended(id: UUID)
        /// A row was deleted; undo restores it verbatim.
        case deleted(Contraction)
        /// HL-018: a suspect-short row was merged into the record before it. `earlier`
        /// is that record's own pre-merge snapshot (same id, its original `endedAt`);
        /// `absorbed` is the later, now-deleted record verbatim. Undo restores both —
        /// the earlier record's original end, and a fresh insert of the one merge
        /// removed — so one Undo reverses a two-record edit exactly, the same
        /// verbatim guarantee `.deleted` makes for one.
        case merged(earlier: Contraction, absorbed: Contraction)
        /// **A whole sweep of flagged records, undone as one** (HL-027). Carries every
        /// record the sweep removed, in full, so a single Undo puts all of them back
        /// with their identities — the same contract `deleted` keeps for one record.
        /// A bulk delete a woman cannot take back in one gesture is a bulk delete she
        /// should not be offered.
        case deletedMany([Contraction])
    }

    public private(set) var undoAction: UndoAction?

    /// The provider's rule. Persisted per device; 5-1-1 is the widely taught
    /// default for a first baby.
    public var rule: GuidelineRule {
        didSet { defaults.set(rule.rawValue, forKey: GuidelineRule.defaultsKey) }
    }

    /// The provider or labor-and-delivery number, if she chose to keep one here.
    /// Empty is the default and stays the default — nothing asks twice (SP-200).
    public var providerNumber: String {
        didSet { defaults.set(providerNumber, forKey: ProviderContact.defaultsKey) }
    }

    /// The number to dial, or nil when the field is empty or holds nothing
    /// dialable. The screens key their Call buttons off this rather than off
    /// `providerNumber.isEmpty`, so a field holding "(" can never offer a call.
    public var providerCallURL: URL? {
        ProviderContact.telURL(for: providerNumber)
    }

    /// Injected rather than always `.standard` so tests can pass a suite-named
    /// instance — rule persistence must never leak into (or read stale state from)
    /// the real domain while a test suite runs.
    private let defaults: UserDefaults

    public init(context: ModelContext, defaults: UserDefaults = .standard) {
        self.context = context
        self.defaults = defaults
        self.rule = GuidelineRule.persisted(in: defaults)
        self.providerNumber = ProviderContact.persisted(in: defaults)
        reload()
    }

    /// In-memory convenience for previews. Never the app path.
    public convenience init() {
        // swiftlint:disable:next force_try
        self.init(context: ModelContext(try! LaborStore.container(inMemory: true)))
    }

    /// **One definition of "running" (F-0002).** Both of these derive from the same
    /// search, so they cannot disagree. They used to: `isRunning` read
    /// `contractions.last` — newest by *start* — while `runningSince` found the newest
    /// record that was actually open. A backward clock set stamps a new start earlier
    /// than an already-completed one, and the two answers came apart: the button drew
    /// itself idle from `isRunning` while showing a live count from `runningSince`, so
    /// a stop tap called `beginContraction` and no-opped against the record it was
    /// meant to close (F-0003).
    public var running: Contraction? {
        contractions.last(where: { $0.endedAt == nil })
    }

    public var isRunning: Bool { running != nil }

    public var runningSince: Date? { running?.startedAt }

    /// When the most recently *finished* contraction ended, if there is one. The
    /// screen dates its figures from this (decision 0022): a returning reader needs
    /// "last contraction ended 3 h ago" where a first-time reader needs the
    /// introduction, and only the store knows which of the two she is.
    public var lastEndedAt: Date? {
        contractions.compactMap(\.endedAt).max()
    }

    /// The one interaction: tap to start, tap again to end. Everything else on the
    /// timer screen is read-only.
    public func tap(at date: Date = Date()) {
        do {
            if isRunning {
                if let ended = try context.endContraction(at: date) {
                    undoAction = .ended(id: ended.id)
                }
            } else {
                let started = try context.beginContraction(at: date)
                undoAction = .started(id: started.id)
            }
            reload()
        } catch {
            // A failed save must never take the timer down mid-labor; the previous
            // snapshot stands and the tap can be retried. The breadcrumb is what
            // makes a release build's silence diagnosable afterwards (0029 §3).
            Breadcrumb.log(.tapSaveFailed, error: error)
            assertionFailure("Contraction tap failed to persist: \(error)")
        }
    }

    /// Re-reads the store and reconciles the Live Activity. Called on foreground —
    /// the app skipped this hook while it was the only writer; the lock-screen
    /// intent (SP-186) made a second writer, so returning to the app must show
    /// what the lock screen already knows.
    public func refresh() {
        reload()
    }

    /// The live figures as of `now`. Computed per call — the pattern moves with the
    /// clock even between taps, so the screen drives this from a `TimelineView`.
    public func pattern(now: Date = Date()) -> LaborPattern {
        PatternAnalysis.pattern(for: contractions, rule: rule, now: now)
    }

    /// Contractions grouped for the history list, newest episode first, newest
    /// contraction first within each.
    public var episodesNewestFirst: [[Contraction]] {
        PatternAnalysis.episodes(contractions)
            .map { $0.reversed() }
            .reversed()
    }

    public func delete(_ contraction: Contraction) {
        do {
            try context.deleteContraction(id: contraction.id)
            undoAction = .deleted(contraction)
            reload()
        } catch {
            Breadcrumb.log(.deleteFailed, error: error)
            assertionFailure("Delete failed: \(error)")
        }
    }

    /// Mis-taps are expected mid-labor; one tap takes the last action back.
    public func undo() {
        guard let action = undoAction else { return }
        do {
            switch action {
            case .started(let id):
                try context.deleteContraction(id: id)
            case .ended(let id):
                // Re-open it: the end tap was the mistake, the contraction wasn't.
                if let record = try fetchRecord(id: id) {
                    record.endedAt = nil
                    try context.save()
                }
            case .deleted(let contraction):
                try context.restoreContraction(contraction)
            case .deletedMany(let contractions):
                for contraction in contractions {
                    try context.restoreContraction(contraction)
                }
            case .merged(let earlier, let absorbed):
                // Both halves, in either order — the earlier record's original span
                // back first, then the later record's own row restored verbatim, the
                // same identity-preserving insert `.deleted` already relies on.
                try context.extendContraction(
                    id: earlier.id,
                    endedAt: earlier.endedAt ?? earlier.startedAt
                )
                try context.restoreContraction(absorbed)
            }
            undoAction = nil
            reload()
        } catch {
            Breadcrumb.log(.undoFailed, error: error)
            assertionFailure("Undo failed: \(error)")
        }
    }

    /// Whether `contraction` has a predecessor to merge into. False only for the
    /// single oldest record the store holds — the one contraction that, by
    /// definition, split from nothing (HL-018).
    public func canMergeWithPrevious(_ contraction: Contraction) -> Bool {
        guard let index = contractions.firstIndex(where: { $0.id == contraction.id }) else { return false }
        return index > 0
    }

    /// **HL-018: heals a double-tap split.** A double tap that cuts one contraction
    /// into two leaves a slip beside its parent; this joins `contraction` with the
    /// record immediately before it in time — the contraction it was split from —
    /// into one record spanning the earlier start to the later end, which is what
    /// actually happened. The earlier record keeps its own identity and start; the
    /// later one is deleted, its span absorbed rather than duplicated.
    ///
    /// A no-op when there is no previous record (`canMergeWithPrevious` says so in
    /// advance for the UI; this re-checks rather than trusting the caller, so a stray
    /// call against the oldest record — never offered by any swipe action — cannot
    /// corrupt anything). Also a no-op against a still-running `contraction`: a
    /// suspect-short row is always an ended record (`suspicion` requires a duration),
    /// so the UI never reaches this with one running, but merging a live timer into
    /// its predecessor would delete the contraction being timed out from under her,
    /// and that must not be reachable by any path, called correctly or not.
    public func mergeWithPrevious(_ contraction: Contraction) {
        guard let endedAt = contraction.endedAt,
              let index = contractions.firstIndex(where: { $0.id == contraction.id }),
              index > 0
        else { return }
        let earlier = contractions[index - 1]
        do {
            // Extend before delete, deliberately: if the second write ever failed
            // mid-operation, this order leaves both records on disk (an odd-looking
            // overlap, fully recoverable) rather than the later record's data gone
            // with no undo action recorded to bring it back.
            try context.extendContraction(id: earlier.id, endedAt: endedAt)
            try context.deleteContraction(id: contraction.id)
            undoAction = .merged(earlier: earlier, absorbed: contraction)
            reload()
        } catch {
            Breadcrumb.log(.mergeFailed, error: error)
            assertionFailure("Merge failed: \(error)")
        }
    }

    /// **Delete every flagged record in one gesture** (HL-027).
    ///
    /// Three days of prodromal timing leaves a scattering of mis-taps, and the only
    /// tools were one swipe per row or destroying the whole record. This is the middle
    /// path the walkthrough asked for, and it is deliberately the *targeted* one: it
    /// removes only what the engine already flags as suspect (decision 0032's two
    /// sides — a forgotten stop-tap over three minutes, a slip under twenty seconds),
    /// records that are already excluded from the duration mean and already marked
    /// `CHECK` on every surface. Real contractions are never touched.
    ///
    /// A running contraction is never swept, whatever its elapsed time reads: it has
    /// not finished being a measurement yet, and deleting the timer out from under a
    /// woman mid-contraction is not a cleanup.
    ///
    /// Returns the number removed so the caller can say so; the whole sweep is one
    /// undo.
    @discardableResult
    public func deleteFlagged() -> Int {
        let flagged = flaggedContractions
        guard !flagged.isEmpty else { return 0 }
        do {
            for contraction in flagged {
                try context.deleteContraction(id: contraction.id)
            }
            undoAction = .deletedMany(flagged)
            reload()
            return flagged.count
        } catch {
            Breadcrumb.log(.deleteFailed, error: error)
            assertionFailure("Flagged sweep failed: \(error)")
            return 0
        }
    }

    /// How many records a sweep would remove — the count the confirmation names, read
    /// from the same predicate the sweep itself uses so the dialog can never promise a
    /// different number than it deletes.
    public var flaggedCount: Int {
        flaggedContractions.count
    }

    private var flaggedContractions: [Contraction] {
        contractions.filter { $0.suspicion != nil && $0.endedAt != nil }
    }

    /// The full clear, behind History's confirmation dialog. Deliberately without
    /// an undo — a clear someone can casually reverse is a clear they were allowed
    /// to make casually. Ending any Live Activity falls out of `reload()`'s
    /// reconciliation: an empty pattern ends whatever exists.
    public func clearAll() {
        do {
            try context.clearAllContractions()
            undoAction = nil
            reload()
        } catch {
            Breadcrumb.log(.clearAllFailed, error: error)
            assertionFailure("Clear-all failed: \(error)")
        }
    }

    private func fetchRecord(id: UUID) throws -> ContractionRecord? {
        try context.fetch(
            FetchDescriptor<ContractionRecord>(predicate: #Predicate { $0.id == id })
        ).first
    }

    private func reload() {
        do {
            contractions = try context.allContractions()
        } catch {
            // The screens must still render, and an empty snapshot beats a crash
            // mid-labor — but this is the one swallow most worth a trace: a store
            // that stops reading looks exactly like a user who never tapped.
            Breadcrumb.log(.storeReloadFailed, error: error)
            contractions = []
        }
        syncLiveActivity()
    }

    // MARK: - Live Activity

    /// One reconciliation point (SP-186): a live pattern keeps exactly one activity
    /// alive and current; an empty or stale pattern ends whatever exists. Runs on
    /// every reload, so taps in-app and taps on the lock screen converge on the
    /// same state without either surface owning it.
    private func syncLiveActivity() {
        let pattern = pattern()
        // `Activity` values cannot cross into a Task under strict concurrency, so
        // each Task re-reads the static list inside its own region; only Sendable
        // values (the content, a Bool) are captured.
        //
        // "Present" is `countsAsPresent`'s one definition (decision 0028): counting
        // ended-but-undismissed activities once took the update branch below onto a
        // dead activity, and the lock-screen button stayed gone until the dismissal
        // window closed — through the one action guaranteed to be able to fix it:
        // opening the app.
        let live = Activity<ContractionActivityAttributes>.activities.filter {
            $0.activityState.countsAsPresent
        }
        let hasLiveActivity = !live.isEmpty

        guard !pattern.episode.isEmpty else {
            guard !Activity<ContractionActivityAttributes>.activities.isEmpty else { return }
            Task {
                for activity in Activity<ContractionActivityAttributes>.activities {
                    await activity.end(nil, dismissalPolicy: .immediate)
                }
                Breadcrumb.log(.activityEnded)
            }
            return
        }

        // Past this age the activity is close enough to ActivityKit's eight-hour
        // ceiling to be worth replacing while we have the chance. Every foreground is
        // an opportunity the app is otherwise guaranteed not to get again — someone in
        // labor opens this screen to read the pattern, and each time she does the
        // clock starts over. It is how an app with no network covers a labor longer
        // than the platform's own limit.
        let needsReplacing = live.contains { $0.attributes.needsReplacement() }

        let content = ActivityContent(
            state: ContractionActivityAttributes.ContentState.from(pattern),
            // Stale rather than confidently wrong: if updates ever stop arriving, the
            // lock screen should say its figures have aged, the same honesty decision
            // 0022 gives the in-app readout.
            staleDate: Date().addingTimeInterval(PatternAnalysis.episodeGap.timeInterval)
        )

        if hasLiveActivity && !needsReplacing {
            Task {
                for activity in Activity<ContractionActivityAttributes>.activities
                where activity.activityState.countsAsPresent {
                    await activity.update(content)
                }
                Breadcrumb.log(.activityUpdated)
            }
            return
        }

        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        // Named before the request, because the replacement joins `activities` the
        // moment it exists and an unfiltered sweep would end the activity it was
        // making room for.
        let replaced = Set(Activity<ContractionActivityAttributes>.activities.map(\.id))
        do {
            // A failed request is quietly acceptable: the activity is a convenience
            // surface, and the app remains the source of truth. The breadcrumb is
            // the only witness a release build keeps (0029 §3).
            _ = try Activity.request(
                attributes: ContractionActivityAttributes(),
                content: content
            )
            Breadcrumb.log(.activityRequested)
            // Only once the replacement exists: an ageing activity is still a lock
            // screen button, and a failed request must not take it away.
            if needsReplacing {
                Task {
                    for activity in Activity<ContractionActivityAttributes>.activities
                    where replaced.contains(activity.id) {
                        await activity.end(nil, dismissalPolicy: .immediate)
                    }
                    Breadcrumb.log(.activityReplaced)
                }
            }
        } catch {
            Breadcrumb.log(.activityRequestFailed, error: error)
        }
    }

}
