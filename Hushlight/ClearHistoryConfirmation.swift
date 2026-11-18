import DesignKit
import LaborKit
import SwiftUI

/// SP-212's confirmation, now behind two doors (SP-215): History's toolbar menu and
/// the timer screen's closure recap. One dialog, one deletion path, one message —
/// each call site owns only the presentation `Bool` and which episode "Save a copy
/// first…" would export, never a second copy of the buttons or the consequence
/// text. F-0012's lesson applies to dialogs as much as to figures: two definitions
/// of "what Clear Everything does" WILL disagree eventually.
struct ClearHistoryConfirmation: ViewModifier {
    @Environment(LaborModel.self) private var model
    @Binding var isPresented: Bool

    /// The newest episode, chronological (oldest first) — what "Save a copy
    /// first…" hands to `ForTheCallScreen`. Passed in rather than re-derived here
    /// so both call sites read it through the one definition they already have in
    /// scope (`PatternAnalysis.episodes(_:).last`), never a second walk of the
    /// store that could disagree about which episode is newest.
    let episodeToSave: [Contraction]

    /// The keepsake sheet this dialog's own save button opens. A `confirmationDialog`
    /// dismisses itself the instant any of its buttons is tapped, so "Save a copy
    /// first…" cannot present `ForTheCallScreen` from inside the dialog's own
    /// action closure — it flips this instead, and the sheet opens on the settled
    /// screen behind it, exactly the same choreography `slip`'s delete-then-offer
    /// pattern already uses elsewhere in this app.
    @State private var isShowingKeepsake = false

    func body(content: Content) -> some View {
        content
            // The full clear (SP-189). Confirmed and deliberate, with no undo — the
            // dialog is the guard, and the copy says exactly what happens. Same
            // deletion stance as the suite's decision 0014: a real affordance, no
            // ceremony beyond one honest question.
            .confirmationDialog(
                Text("Clear all history?", comment: "title of the irreversible Clear All History confirmation dialog"),
                isPresented: $isPresented,
                titleVisibility: .visible
            ) {
                // **Save-copy, Clear Everything, Cancel — in that order** (SP-215).
                // The non-destructive way out sits first, ahead of the destructive
                // action it exists to be read before, not after. Absent entirely
                // when there is nothing to export — a button that opens an empty
                // card is worse than no button, the same stance `ForTheCallButton`
                // already takes.
                if PatternAnalysis.callSummary(of: episodeToSave) != nil {
                    Button("Save a copy first…") {
                        isShowingKeepsake = true
                    }
                }
                Button("Clear Everything", role: .destructive) {
                    model.clearAll()
                    // Ending the record of her night is the closest thing to closure
                    // the app can observe, and SP-216's guard reads this stamp so a
                    // rating sheet can never follow it inside a week.
                    UserDefaults.standard.set(Date(), forKey: ReviewPrompt.lastClearAllKey)
                }
                // **A labelled way out, beside the way in** (SP-212). The dialog
                // shipped with one button, so backing out meant tapping the dimmed
                // area outside it — a precision gesture, offered as the alternative
                // to an irreversible one, on the record a triage nurse is about to
                // ask her to read out. iOS adds an implicit cancel to a confirmation
                // dialog on some presentations and not others; "some" is not a
                // guard. Stated, it is always there and always says what it does.
                Button("Cancel", role: .cancel) {}
            } message: {
                // A contraction still being timed is about to be deleted too, and
                // the elapsed time goes with it. Say so — the dialog is the only
                // guard, and a guard that omits the consequence is not one.
                Text(
                    model.isRunning
                        ? "A contraction is still being timed. This deletes it along with every other contraction on this phone. There is no undo."
                        : "This deletes every contraction on this phone. There is no undo.",
                    comment: "body of the Clear All History confirmation dialog, naming the consequence — with or without a contraction currently running"
                )
            }
            .sheet(isPresented: $isShowingKeepsake) {
                if let summary = PatternAnalysis.callSummary(of: episodeToSave) {
                    ForTheCallScreen(
                        episode: episodeToSave,
                        summary: summary,
                        // Reached from "Save a copy first…" — a keepsake, not a
                        // script, so it lands on the same name that offer used.
                        title: LocalizedStringResource("Keep a copy", comment: "navigation title of the summary card when opened from the clear-history confirmation's save-first offer")
                    )
                }
            }
    }
}

extension View {
    /// Attaches SP-212/SP-215's one Clear All confirmation. `episodeToSave` is
    /// whatever the call site's own newest-episode definition already produces —
    /// see `ClearHistoryConfirmation`'s doc comment for why that has to be passed
    /// in rather than recomputed here.
    func clearHistoryConfirmation(
        isPresented: Binding<Bool>,
        episodeToSave: [Contraction]
    ) -> some View {
        modifier(ClearHistoryConfirmation(isPresented: isPresented, episodeToSave: episodeToSave))
    }
}
