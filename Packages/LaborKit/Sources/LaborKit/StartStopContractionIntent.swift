#if os(iOS)
import ActivityKit
import AppIntents
import Foundation
import SwiftData

/// The lock-screen button. `LiveActivityIntent` is the load-bearing conformance:
/// it executes **in the app's process**, which is what lets this write to a store
/// that lives in the app's own sandbox — no App Group, decision 0018 intact. A
/// plain `AppIntent` would run in the extension's process and find nothing there.
///
/// HL-065 gave it three more doors — Siri and the Action button (`HushlightShortcuts`)
/// and a Control Center control (`ContractionControl`) — and with them a way to be
/// heard: a doorway with no Live Activity on screen has nothing else to show that
/// the tap landed, so the result speaks the same words Magic Tap does.
public struct StartStopContractionIntent: LiveActivityIntent {
    // `bundle:` stays the default (`.main`) rather than `.module`, deliberately:
    // AppIntents' build-time metadata extraction requires a `LocalizedStringResource`
    // it can resolve statically to the *app's* bundle, and fails the build otherwise
    // ("AppIntents requires 'LocalizedStringResource' to use the main bundle"). The
    // key still auto-keys and resolves correctly in `en` without a catalog entry;
    // HL-008 can add one to the app's own catalog if this ever needs translating.
    public static var title: LocalizedStringResource {
        LocalizedStringResource(
            "Start or stop a contraction",
            comment: "the intent's name as it appears in Shortcuts/Spotlight — the lock-screen Live Activity button that starts or ends a contraction"
        )
    }
    /// One tap must never present UI — the whole point is not unlocking the phone.
    public static let openAppWhenRun: Bool = false

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        // Bracketing breadcrumbs (0029 §3): the lock-screen tap is the path with
        // the least visible failure mode in the whole app — nothing on screen
        // changes when it dies — so its execution is the one most worth a trace.
        Breadcrumb.log(.intentBegan)
        do {
            let result = try await run()
            Breadcrumb.log(.intentCompleted)
            return result
        } catch {
            Breadcrumb.log(.intentFailed, error: error)
            throw error
        }
    }

    @MainActor
    private func run() async throws -> some IntentResult & ProvidesDialog {
        // **The second lock on decision 0018** (HL-065). Every door this intent has
        // is meant to run it here, in the app — that is what `LiveActivityIntent`
        // promises. If some surface ever ran it in the widget extension instead, the
        // store it opened would be the extension's own empty sandbox: the tap would
        // be written where nothing will ever read it, and the lock screen would say
        // it worked. Refusing is the honest failure, and it is the only one that
        // cannot lose a contraction she believes she timed.
        guard Bundle.main.bundleURL.pathExtension != "appex" else {
            Breadcrumb.log(.intentRefusedOutsideApp)
            return .result(dialog: IntentDialog(LocalizedStringResource(
                "Open Hushlight to time this one.",
                comment: "Siri/Shortcuts reply, only if the start/stop intent ever runs outside the app and so cannot record — the user should open the app and tap there"
            )))
        }

        let container = try LaborStore.container()
        let context = ModelContext(container)

        let dialog: IntentDialog
        if let running = try context.runningContraction() {
            let length = Duration.seconds(max(0, Date().timeIntervalSince(running.startedAt)))
            try context.endContraction()
            // The Magic Tap announcement's words (SP-210): the result, not the press.
            let spoken = length.formatted(.units(allowed: [.minutes, .seconds], width: .wide))
            dialog = IntentDialog(LocalizedStringResource(
                "Recorded \(spoken)",
                comment: "VoiceOver announcement after a Magic Tap ends a contraction, naming the recorded duration"
            ))
        } else {
            try context.beginContraction()
            dialog = IntentDialog(LocalizedStringResource(
                "Timing",
                comment: "VoiceOver announcement after a Magic Tap starts a contraction"
            ))
        }

        // The tap is also the update: recompute the pattern and push it to the
        // activity so the lock screen flips between Start and the live count.
        //
        // The rule comes from the same persisted key `LaborModel` writes (F-0013).
        // It hard-coded 5-1-1 while the in-app rule is selectable — latent only
        // because nothing in `ContentState` is rule-dependent today, and a lock
        // screen quietly answering a different question than the app is not a
        // divergence to leave lying around for the next refactor to trip over.
        let pattern = PatternAnalysis.pattern(
            for: try context.allContractions(),
            rule: GuidelineRule.persisted()
        )
        let state = ContractionActivityAttributes.ContentState.from(pattern)
        let content = ActivityContent(
            state: state,
            staleDate: Date().addingTimeInterval(PatternAnalysis.episodeGap.timeInterval)
        )
        // Only Bools cross out of this region: an `Activity` cannot be sent across
        // an await under strict concurrency, so the list is re-read below inside the
        // loop's own region rather than held across the suspension.
        let hasLiveActivity = Activity<ContractionActivityAttributes>.activities.contains {
            $0.activityState.countsAsPresent
        }
        // **The rearm check the intent never had** (SP-205, completing decision
        // 0028). The app-foreground path has replaced an aging activity since
        // SP-186; this path updated whatever was present and called it done — so a
        // woman timing entirely from the lock screen, the promised workflow, rode
        // an activity straight into ActivityKit's eight-hour kill and lost the
        // button. Every lock-screen tap is the same opportunity a foreground is,
        // and the same shared predicate now answers for both callers.
        let needsReplacing = Activity<ContractionActivityAttributes>.activities.contains {
            $0.activityState.countsAsPresent && $0.attributes.needsReplacement()
        }
        // A create path, not only an update one (decision 0028). Updating a list that
        // happens to be empty is a silent no-op, and this intent runs in the app's
        // process precisely so it can do real work — any entry point that can reach it
        // without a live activity on screen (an App Shortcut, the Action button)
        // should start the timing, not fail quietly.
        if !hasLiveActivity || needsReplacing {
            guard !pattern.episode.isEmpty,
                  ActivityAuthorizationInfo().areActivitiesEnabled
            else { return .result(dialog: dialog) }
            if needsReplacing {
                // End-then-request, exactly as the app's own reconciliation does:
                // a fresh activity restarts the eight-hour clock, which is how an
                // app with no network covers a labor longer than the platform's
                // limit — now from the lock screen too.
                for activity in Activity<ContractionActivityAttributes>.activities {
                    await activity.end(nil, dismissalPolicy: .immediate)
                }
                Breadcrumb.log(.activityReplaced)
            }
            do {
                _ = try Activity.request(
                    attributes: ContractionActivityAttributes(),
                    content: content
                )
                Breadcrumb.log(.activityRequested)
            } catch {
                // Quietly acceptable, as in the app: the tap's write already
                // happened, and the activity is a convenience surface.
                Breadcrumb.log(.activityRequestFailed, error: error)
            }
            return .result(dialog: dialog)
        }
        for activity in Activity<ContractionActivityAttributes>.activities
        where activity.activityState.countsAsPresent {
            await activity.update(content)
        }
        Breadcrumb.log(.activityUpdated)
        return .result(dialog: dialog)
    }
}
#endif
