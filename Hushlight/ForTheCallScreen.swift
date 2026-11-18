import DesignKit
import LaborKit
import SwiftUI
import UIKit

/// SP-206's card: the triage-nurse script, large enough to read aloud at 3am, with
/// a Copy button for dictating it over the phone and a plain-text `ShareLink`
/// export of the whole episode. Both are user-initiated — the system share sheet
/// and the pasteboard are the sanctioned exceptions to "nothing leaves the device
/// on its own" (CLAUDE.md's privacy ratchet): this app never sends anything, it
/// only ever hands her something to send herself.
struct ForTheCallScreen: View {
    @Environment(\.dismiss) private var dismiss

    /// Chronological (oldest first) — the order the export reads in, and the order
    /// `summary` was itself composed from.
    let episode: [Contraction]
    let summary: CallSummary

    /// **What this card is called where it was opened from** (HL-024, F-0047). One
    /// screen, two honest names: during a stretch it is the script for the call, and
    /// after one has ended it is a copy worth keeping. The walkthrough's partner lens
    /// read the second name as the feature disappearing; it is the opposite — the
    /// offer genuinely changes when the call it was for is over, and a card titled
    /// "For the call" above a stretch that ended days ago would be the drift, not
    /// this. The button that opened it and the title it lands on now agree either way.
    var title: LocalizedStringResource = LocalizedStringResource("For the call", comment: "navigation title of the call summary card, when opened during a stretch")

    @State private var didCopy = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Metrics.space5) {
                    // Large and legible on purpose — this is the one sentence on
                    // this card, and it is meant to be read aloud rather than
                    // scanned. `.claim` is the role reserved for exactly that: "a
                    // claim the app makes on a card" (Typography.swift).
                    Text(summary.text)
                        .font(.claim)
                        .foregroundStyle(Palette.primaryText)

                    // **Decision 0047.** This card's averages cover the whole
                    // stretch; the timer's own readout covers the last hour, which
                    // is the window the guideline is defined over. Both are right
                    // and they differ whenever the pattern is tightening — and the
                    // person reading this aloud was looking at the other figure
                    // seconds ago. This is the only surface where one reader holds
                    // both at once, so it is the only one that names the difference
                    // instead of implying it. Quiet register: it is a footnote to
                    // the script, not part of what she reads to the nurse.
                    Text(
                        "These averages cover the whole stretch. The timer's own figures cover the last hour, so they can differ while contractions are getting closer together.",
                        comment: "Footnote under the call script naming which window its averages cover, and why the timer screen may show a different figure (decision 0047)"
                    )
                    .font(.prose)
                    .foregroundStyle(Palette.secondaryText)

                    // Side by side while it fits; stacked at accessibility sizes,
                    // where two capsules sharing a row squeeze "Copy" and "Share"
                    // into a column each — three lines wrapped inside a shape that
                    // reads as broken rather than reflowed (§8's reflow-not-
                    // truncate rule, the same `ViewThatFits` pattern the header
                    // and the verdict banner's leg rows already take).
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: Metrics.space3) {
                            copyButton
                            shareButton
                        }
                        VStack(alignment: .leading, spacing: Metrics.space3) {
                            copyButton
                            shareButton
                        }
                    }
                }
                .padding(.horizontal, Metrics.screenMargin)
                .padding(.top, Metrics.space6)
                .padding(.bottom, Metrics.space6)
            }
            .background(Palette.screen)
            .navigationTitle(Text(title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var copyButton: some View {
        Button {
            UIPasteboard.general.string = summary.text
            didCopy = true
            Task {
                try? await Task.sleep(for: .seconds(Self.copyConfirmationLifetime))
                didCopy = false
            }
        } label: {
            Label(didCopy ? "Copied" : "Copy", systemImage: didCopy ? "checkmark" : "doc.on.doc")
        }
        .buttonStyle(.capsuleTinted)
        .accessibilityLabel(didCopy
            ? String(localized: "Copied", comment: "VoiceOver label for the Copy button on the For the call card, after the tap that copied the sentence")
            : String(localized: "Copy", comment: "VoiceOver label for the Copy button on the For the call card"))
        .accessibilityHint(String(localized: "Copies this sentence", comment: "VoiceOver hint for the Copy button on the For the call card"))
        // The system's own confirmation texture — the same weight a toggle-on
        // state gets elsewhere in the suite, not the timer/stop pair reserved for
        // the button that actually starts and ends a contraction.
        .sensoryFeedback(trigger: didCopy) { _, copied in copied ? .success : nil }
    }

    private var shareButton: some View {
        ShareLink(item: exportText) {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        .buttonStyle(.capsuleTinted)
        .accessibilityLabel(String(localized: "Share", comment: "VoiceOver label for the Share button on the For the call card"))
        .accessibilityHint(String(localized: "Opens the share sheet with this sentence and every contraction in this stretch", comment: "VoiceOver hint for the Share button on the For the call card"))
    }

    /// Long enough to register as a confirmation, short enough that a second tap
    /// before it reverts still reads as "copy again" rather than "already copied."
    private static let copyConfirmationLifetime = 2.0

    /// The sentence, then one line per contraction — started, lasted, apart —
    /// through the exact renderings History's own rows use (F-0012: a second
    /// derivation of the same figure will disagree). Chronological, oldest first:
    /// this is a document read start to finish, not a list scrolled from the top,
    /// and "since 6:17 PM" reads naturally into a line that then starts at 6:17 PM.
    private var exportText: String {
        var lines = [summary.text, ""]
        var previous: Contraction?
        for contraction in episode {
            lines.append(exportLine(for: contraction, previous: previous))
            previous = contraction
        }
        return lines.joined(separator: "\n")
    }

    // Same shape as `CallSummary`'s clause list and `HistoryScreen`'s row
    // accessibility text: which clauses appear is row truth (a duration or
    // "RUNNING", a CHECK flag or an interval, never both of the latter pair),
    // each one is already a complete independent catalog phrase, and joining a
    // variable-length list of them with a plain separator is the sanctioned
    // shape — see `CallSummary.callSummary(of:)`'s doc comment for the reasoning
    // "RUNNING" is translated like every other instrument word (decision 0062).
    // This comment used to say it stayed bare "on purpose", citing an
    // instrument-vocabulary line in CLAUDE.md — which does not exist, and never
    // did. The invariance that *is* real is typographic and directional (the
    // monospaced face, ASCII digits, the tape running left-to-right), and none of
    // it is touched by translating the word.
    private func exportLine(for contraction: Contraction, previous: Contraction?) -> String {
        var parts = [String(localized: "Started \(LaborFormat.clockTimeWithSeconds(contraction.startedAt))", comment: "plain-text export line clause: the clock time a contraction started")]

        if let duration = contraction.duration {
            parts.append(String(localized: "lasted \(LaborFormat.minutesSeconds(duration))", comment: "plain-text export line clause: how long the contraction lasted"))
        } else {
            parts.append(String(localized: "RUNNING", comment: "plain-text export line clause, row badge on the contraction still being timed. Rendered in caps by the type role, so translate as a word rather than in capitals"))
        }

        // The CHECK flag takes the slot an interval would otherwise hold — the
        // same substitution `HistoryRow` draws, so a flagged record never reports
        // a spacing figure beside the reason it is flagged in the first place.
        if let suspicion = contraction.suspicion {
            parts.append(LaborFormat.checkFlag(suspicion))
        } else if let previous {
            let interval = PatternAnalysis.interval(from: previous, to: contraction)
            parts.append(String(localized: "\(LaborFormat.minutesSeconds(interval)) apart", comment: "plain-text export line clause: interval since the previous contraction"))
        }

        return parts.joined(separator: " — ")
    }
}

#Preview {
    let episode = (0..<14).map { index -> Contraction in
        let start = Date().addingTimeInterval(Double(index - 14) * 5 * 60)
        return Contraction(startedAt: start, endedAt: start.addingTimeInterval(62))
    }
    return Color.clear
        .sheet(isPresented: .constant(true)) {
            // Built the same way the button does — through the one composition,
            // never a literal sentence typed here to go stale beside it.
            ForTheCallScreen(episode: episode, summary: PatternAnalysis.callSummary(of: episode)!)
        }
}
