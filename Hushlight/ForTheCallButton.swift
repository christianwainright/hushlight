import DesignKit
import LaborKit
import SwiftUI

/// The trigger for SP-206's card — one component, two call sites: a quiet capsule
/// under the verdict banner's leg rows, and another beside Guidance's provider and
/// report entries. Renders nothing at all when there is no current episode to
/// summarize, the same "an empty field is a silence, never a prompt" stance
/// `CallProviderButton` already takes — a button that opens a card with nothing on
/// it is worse than no button.
struct ForTheCallButton: View {
    /// The current episode, oldest first — the same array `LaborPattern.episode`
    /// and `PatternAnalysis.episodes(_:).last` already produce. Passed in rather
    /// than re-derived here so both call sites can hand over whatever they already
    /// have in scope without a second `episodes(_:)` walk of the whole store.
    let episode: [Contraction]

    @State private var isPresented = false
    /// HL-058b: a sheet over the timer takes Space and ⌘J/⌘G off the keyboard.
    @Environment(KeyboardIntents.self) private var keyboard

    var body: some View {
        if let summary = PatternAnalysis.callSummary(of: episode) {
            Button {
                isPresented = true
            } label: {
                Text("For the call", comment: "capsule button label that opens the one-sentence call summary card")
            }
            .buttonStyle(.capsuleTinted)
            .accessibilityLabel(String(localized: "For the call", comment: "VoiceOver label for the button that opens the one-sentence call summary card"))
            .accessibilityHint(String(localized: "Shows one sentence with the pattern, to read or share", comment: "VoiceOver hint for the For the call button"))
            .onChange(of: isPresented) { _, shown in keyboard.sheet(shown) }
            .sheet(isPresented: $isPresented) {
                ForTheCallScreen(episode: episode, summary: summary)
            }
        }
    }
}
