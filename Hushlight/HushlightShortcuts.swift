import AppIntents
import LaborKit

/// **Siri and the Action button** (HL-065). The one intent the app has — the
/// lock-screen button's — offered as an App Shortcut, which is what puts it on the
/// Action button's list and in Siri's vocabulary without the user building a
/// shortcut first. It lives in the app target because App Shortcuts are read from
/// the app's own bundle; the intent itself stays in LaborKit beside the store it
/// writes.
///
/// One intent, toggling, so every phrase names the act rather than a direction: a
/// "start" phrase said while one is running would end it, and a phrase that does
/// the opposite of its words is worse than one that says less.
struct HushlightShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartStopContractionIntent(),
            // lint-localizable:ignore-start — App Shortcut phrases are `AppShortcutPhrase`s, translated in AppShortcuts.xcstrings (×9), not the String Catalog
            phrases: [
                "Time a contraction with \(.applicationName)",
                "\(.applicationName) contraction",
            ],
            // lint-localizable:ignore-end
            shortTitle: "Contraction",
            systemImageName: "stopwatch"
        )
    }
}
