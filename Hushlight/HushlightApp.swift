import DesignKit
import LaborKit
import StoreKit
import SwiftData
import SwiftUI

/// The contraction timer. Free forever, fully local, deliberately outside the
/// fitness suite's shared store (decision 0018) — its container is this app's own
/// sandbox, and there is no App Group entitlement to reach anything else's.
///
/// No version gate either: one app owns this schema, so the multi-app drift the
/// suite guards against cannot happen here.
@main
struct HushlightApp: App {
    private let container: ModelContainer
    @State private var model: LaborModel
    @Environment(\.scenePhase) private var scenePhase

    /// Registers itself with MetricKit on creation and lives as long as the app
    /// (decision 0029 §3). Nothing reads it directly; it writes summaries the
    /// problem-report email counts.
    private let diagnostics = CrashDiagnostics()

    init() {
        // A failed container here means the app cannot do its one job; crashing at
        // launch is more honest than a timer that silently drops taps. The
        // breadcrumb goes first, so the OS log says why (0029 §3).
        let container: ModelContainer
        do {
            container = try LaborStore.container()
            Breadcrumb.log(.storeOpened)
        } catch {
            Breadcrumb.log(.storeOpenFailed, error: error)
            fatalError("The labor store could not be opened: \(error)")
        }
        self.container = container
        #if DEBUG
        // SP-184's simulated-labor pass; a no-op without its launch arguments.
        DemoSeed.applyIfRequested(context: container.mainContext)
        #endif
        _model = State(wrappedValue: LaborModel(context: container.mainContext))
        // The first-launch stamp exists only so SP-216's age guard has a fact to
        // read. Set once, never touched again; absence downstream reads as
        // "first launch", the conservative direction.
        if UserDefaults.standard.object(forKey: ReviewPrompt.firstLaunchKey) == nil {
            UserDefaults.standard.set(Date(), forKey: ReviewPrompt.firstLaunchKey)
        }
    }

    /// **The rating ask, at the calm and only once** (SP-216, decision 0029 §2).
    ///
    /// `requestReview` and nothing else — no custom UI, no "enjoying Hushlight?"
    /// pre-prompt, and the OS decides whether a sheet actually appears. Our side of
    /// the bargain is `ReviewPrompt.isEligible`, the pure predicate the tests own:
    /// past the first day, nothing recorded or cleared for a week, no contraction
    /// running, once per install. Evaluated when the app comes to the foreground —
    /// the one entry point that is never the lock screen — and skipped under UI
    /// testing so no harness screenshot can meet a system sheet.
    ///
    /// The attempt is counted when we *ask*, not when the OS shows: "we asked" is
    /// the fact this app owns, and asking twice because the system declined once is
    /// exactly the pestering 0029 §2 forbids.
    private struct ReviewPromptGate: ViewModifier {
        let model: LaborModel
        @Environment(\.requestReview) private var requestReview
        @Environment(\.scenePhase) private var scenePhase

        func body(content: Content) -> some View {
            content.onChange(of: scenePhase) { _, phase in
                guard phase == .active, !RuntimeFlags.isUITesting else { return }
                let defaults = UserDefaults.standard
                let eligible = ReviewPrompt.isEligible(
                    now: Date(),
                    firstLaunch: defaults.object(forKey: ReviewPrompt.firstLaunchKey) as? Date,
                    // `contractions` is oldest-first (`running`'s own comment says
                    // so), and a still-open record counts from its start — either
                    // way the fact wanted here is "when did anything last happen".
                    newestRecordEnd: model.contractions.last.map { $0.endedAt ?? $0.startedAt },
                    isRunning: model.isRunning,
                    lastClearAll: defaults.object(forKey: ReviewPrompt.lastClearAllKey) as? Date,
                    alreadyAttempted: defaults.bool(forKey: ReviewPrompt.attemptedKey)
                )
                guard eligible else { return }
                defaults.set(true, forKey: ReviewPrompt.attemptedKey)
                requestReview()
            }
        }
    }

    /// **The screen stays awake while a contraction is being timed** (HL-011), and
    /// only then.
    ///
    /// A phone that locks mid-contraction costs a stop tap: she has to wake it, and
    /// the end time she records is the time she got back in, not the time it ended.
    /// That is the one measurement error this app cannot detect afterwards — a
    /// forgotten stop-tap at least announces itself past three minutes (decision
    /// 0032); a *late* one just quietly inflates a duration.
    ///
    /// Scoped to a running contraction rather than to the app being open, which is
    /// the version that would matter more if battery were free. It is not: this app
    /// is used across a twelve-hour night, often on a phone nobody thought to charge,
    /// and holding the display on for the fifty-five minutes of every hour when
    /// nothing is being timed would spend the battery she needs for the drive.
    /// Between contractions the phone sleeps like any other; the moment she taps, it
    /// stays with her.
    @MainActor
    private func holdTheScreenAwake(_ shouldHold: Bool) {
        UIApplication.shared.isIdleTimerDisabled = shouldHold
    }

    /// HL-058b — see `KeyboardIntents`.
    @State private var keyboard = KeyboardIntents()

    var body: some Scene {
        WindowGroup {
            TimerScreen()
                .environment(model)
                .environment(keyboard)
                // The lock-screen intent (SP-186) writes while the app is
                // backgrounded; foregrounding must show what the lock screen
                // already knows.
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { model.refresh() }
                    holdTheScreenAwake(model.isRunning && phase == .active)
                }
                // Tied to the *record*, not to any screen. History and Guidance push
                // over the timer mid-contraction, and a woman who opens the guidance
                // card to re-read the call-now list has not stopped timing.
                .onChange(of: model.isRunning, initial: true) { _, isRunning in
                    holdTheScreenAwake(isRunning && scenePhase == .active)
                }
                .modifier(ReviewPromptGate(model: model))
        }
        // **The keyboard on the tray table** (HL-058b). Space is the one button on the
        // biggest key; ⌘Z is the system's own undo slot; ⌘J and ⌘G open what the
        // toolbar opens. Each command only signals; `TimerScreen` performs the action
        // the tap would. ⌘1/⌘2/⌘L/⌘Y/⌘H are Simulator.app's own shortcuts and the
        // harness cannot deliver them, which is why History and Guidance are not on
        // them (see `KeyboardTests` for what the harness can and cannot prove).
        .commands {
            CommandMenu(Text("Timer", comment: "menu title on iPad with a hardware keyboard: the timer's commands")) {
                Button {
                    keyboard.tapSlab += 1
                } label: {
                    Text(model.isRunning ? "End" : "Start", comment: "the slab's action word — End while a contraction is running, Start while idle")
                }
                .keyboardShortcut(.space, modifiers: [])
                .disabled(!keyboard.timerIsFrontmost)
            }
            CommandGroup(replacing: .undoRedo) {
                Button("Undo") { keyboard.undo += 1 }
                    .keyboardShortcut("z", modifiers: .command)
                    .disabled(model.undoAction == nil)
            }
            CommandMenu(Text("Go", comment: "menu title on iPad with a hardware keyboard: the screens the toolbar opens")) {
                Button {
                    keyboard.openHistory += 1
                } label: {
                    Text("History")
                }
                .keyboardShortcut("j", modifiers: .command)
                .disabled(!keyboard.canNavigate)
                Button {
                    keyboard.openGuidance += 1
                } label: {
                    Text("Guidance")
                }
                .keyboardShortcut("g", modifiers: .command)
                .disabled(!keyboard.canNavigate)
            }
        }
        .modelContainer(container)
    }
}
