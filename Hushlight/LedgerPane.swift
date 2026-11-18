import DesignKit
import LaborKit
import SwiftUI

/// **The ledger** (HL-058): History's timeline for the current stretch, live beside
/// the instrument in the *Hand* and *Stand* regimes. For the partner holding the iPad
/// the question is never the count alone — it is what the last hour has looked like —
/// so History is not a screen they navigate to; it sits here.
///
/// Not a second instrument. The rows are `HistoryRow`, the figures are the same
/// `EpisodeSummary` History prints, the controls are History's own — Undo, swipe to
/// delete — and nothing else. With no stretch it says so in the timer's own words and
/// fills nothing.
struct LedgerPane: View {
    @Environment(LaborModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Chronological, as `LaborPattern.episode` hands it over; reversed here once.
    /// Nothing here reads the clock: the pane's inputs are the records and the
    /// correction count, so a tick of the timer's `TimelineView` leaves it alone.
    let episode: [Contraction]
    /// Owned by the screen, shared with the bar: deletions and undos count as
    /// corrections wherever they happen (`sensoryFeedback` reads it).
    @Binding var corrections: Int

    var body: some View {
        let newestFirst = Array(episode.reversed())
        // No header of its own: the summary band that opens the list already says
        // "THIS STRETCH" (`episodeSummaryLine`), and the instrument's readout already
        // counts the total. The empty state is the one case that needs a title.
        // Deleting the only row empties the episode while `undoAction` still holds the
        // deletion; History keeps its list (and its Undo) in that state, and so does
        // this — the empty words appear only when there is nothing to take back.
        Group {
            if episode.isEmpty && model.undoAction == nil {
                emptyState
            } else {
                list(newestFirst)
            }
        }
        .background(Palette.raised)
        // `raised`'s own rule: its 1.09:1 step against the room needs an edge to
        // carry it. The instrument's trailing hairline is that edge (TimerScreen).
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "This stretch", comment: "Ledger pane header (iPad): the current stretch's rows, beside the timer"))
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: Metrics.space2) {
            Text("This stretch", comment: "Ledger pane header (iPad): the current stretch's rows, beside the timer")
                .sectionLabelText(onFill: true)
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, Metrics.space3)
            Text("No contractions yet.", comment: "empty-state headline on a fresh install, before any contraction has been recorded")
                .font(.claim)
                .foregroundStyle(Palette.primaryText)
            Text("Each one you time appears here as it happens, with the gap since the one before.", comment: "Ledger pane (iPad) empty state, under the headline: what will appear here once a contraction is timed")
                .font(.prose)
                .foregroundStyle(Palette.secondaryTextOnFill)
        }
        .padding(.horizontal, Metrics.screenMargin)
        .padding(.top, Metrics.space5)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func list(_ newestFirst: [Contraction]) -> some View {
        List {
            // The stretch's figures first — the line a provider call reads from — with
            // the same evidence floors as everywhere.
            if let summary = PatternAnalysis.summary(of: episode) {
                StretchSummaryLine(summary: summary)
                    .listRowBackground(Palette.inputFill)
                    .listRowSeparator(.hidden)
            }
            // The summary band doubles as the pane's title; the list's top inset
            // is the band's own.
            ForEach(HistoryScreen.rows(for: newestFirst)) { row in
                HistoryRow(row: row)
                    .listRowBackground(Palette.raised)
                    .swipeActions {
                        Button("Delete", role: .destructive) {
                            model.delete(row.contraction)
                            corrections += 1
                        }
                    }
            }
            if model.undoAction != nil {
                Button("Undo") {
                    model.undo()
                    corrections += 1
                }
                .font(.claim)
                .foregroundStyle(Palette.tint)
                .listRowBackground(Palette.raised)
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .animation(reduceMotion ? nil : .spring(duration: 0.35), value: episode.count)
    }
}

#Preview("Ledger") {
    LedgerPane(episode: [], corrections: .constant(0))
        .environment(LaborModel())
}
