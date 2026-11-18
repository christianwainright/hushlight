import DesignKit
import LaborKit
import SwiftUI

/// The reference card (SP-190; card in the Claude Design project). Six lessons,
/// each taught by a miniature of the app's own parts — no stock art, no quiz, and
/// it never gates the timer: it appears once as a dismissible sheet on first
/// launch and lives behind the toolbar's `?` forever after. Mechanics belong
/// here; the medical "call now regardless" list stays in Guidance.
struct HowItWorksScreen: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.space5) {
                VStack(alignment: .leading, spacing: Metrics.space2) {
                    // The other of the identity's two reserved moments — the
                    // app's opening line on the screen a first launch shows.
                    Text("How it works", comment: "How It Works sheet's opening headline")
                        .font(.voice)
                        .foregroundStyle(Palette.primaryText)
                    Text("Thirty seconds — and it waits under the question mark up top whenever you want it back.", comment: "How It Works sheet's opening caption. \"Question mark\" names the toolbar's question-mark-circle icon in words, not the bare glyph, so a half-attentive first read can't mistake it for a typo or a broken token.")
                        .font(.prose)
                        .foregroundStyle(Palette.secondaryText)
                    // The three promises, first (HL-014) — before any mechanics,
                    // because they are the answers to the questions a frightened
                    // first launch actually arrives with. Airplane mode is the
                    // cheapest possible proof of the privacy claim, and the one
                    // line no identity-linked competitor can copy. Stated here as
                    // positioning; the "Yours alone" lesson below carries the
                    // mechanism.
                    Text("Free forever · no account · works in airplane mode", comment: "How It Works sheet: the three-promise claim, printed register")
                        .font(.claim)
                        .foregroundStyle(Palette.primaryText)
                        .accessibilityLabel(String(localized: "Free forever. No account. Works in airplane mode.", comment: "VoiceOver: spoken form of the three-promise claim on the How It Works sheet"))
                }

                // `lesson`'s `title`/`body` parameters are plain `String`, not
                // `LocalizedStringKey` — `lessonText` displays them via `Text(title)`/
                // `Text(body)`, the verbatim-`String` initializer, since both are
                // variables rather than literals. Every call site below wraps its
                // literal in `String(localized:)` for that reason (the same pattern
                // `SectionHeader(label:)` and `GuidanceScreen.bullet(_:)` follow).
                lesson(art: { MiniSlab() },
                       title: String(localized: "One button", comment: "How It Works lesson title: the single control"),
                       body: String(localized: "Tap the bar when a contraction begins, tap it again when it ends. That's the whole job. Mis-taps get fixed in History — swipe to delete, and Undo takes back the last touch.", comment: "How It Works lesson body: the single control"))

                lesson(art: { IntervalArc() },
                       title: String(localized: "Interval is start-to-start", comment: "How It Works lesson title: how the interval is measured"),
                       body: String(localized: "\"Every 5 minutes\" measures the gap between the beginnings of contractions — the way providers measure. Duration is how long each lasts; Pattern is how long this stretch has been going. Timing starts at the tap, so recorded lengths run a little behind the felt contraction.", comment: "How It Works lesson body: how the interval is measured, and what Duration and Pattern mean"))

                lesson(art: { MiniTimeline() },
                       title: String(localized: "The timeline reads downward", comment: "How It Works lesson title: the timeline"),
                       body: String(localized: "Newest at the top, the gap between each pair printed right where it happened. Figures stay dashes until there's enough to mean something — a dash is honest, a guess isn't.", comment: "How It Works lesson body: the timeline"))

                lesson(art: { MiniChip() },
                       title: String(localized: "Your guideline", comment: "How It Works lesson title: the guideline rule"),
                       body: String(localized: "Every 5 minutes, lasting about a minute, for an hour — the widely used rule. Providers differ; the chip on the timer sets yours. When your pattern truly meets it, the app says so and suggests the call.", comment: "How It Works lesson body: the guideline rule"))

                lesson(art: { MiniLockScreen() },
                       title: String(localized: "Lock the phone freely", comment: "How It Works lesson title: the Live Activity"),
                       body: String(localized: "Timing runs on the clock, not the screen. Once a pattern is going, the button lives on the lock screen too — start and end without unlocking.", comment: "How It Works lesson body: the Live Activity"))

                lesson(art: {
                    // Hidden like every other miniature: `lesson` combines its
                    // children for VoiceOver, and an unhidden symbol folds a stray
                    // "lock" into this row's spoken text.
                    Image(systemName: "lock")
                        .font(.claim)
                        .foregroundStyle(Palette.secondaryText)
                        .accessibilityHidden(true)
                },
                       title: String(localized: "Yours alone", comment: "How It Works lesson title: privacy"),
                       body: String(localized: "No account, no ads, no network. Everything stays on this phone, and Clear All History removes it whenever you choose.", comment: "How It Works lesson body: privacy"))
            }
            .padding(.horizontal, Metrics.screenMargin)
            .padding(.top, Metrics.space6)
            .padding(.bottom, Metrics.space6)
        }
        // **HL-044: the same two mechanisms HL-007 found on `TimerScreen`, one screen
        // over.** This sheet's last visible line read *through* the pinned "Got it"
        // bar — the reader saw a sentence dissolve into the slab rather than stop at
        // it, which looks like lost text even though the rest is one scroll away. The
        // walk below iOS 26 (HL-039) is what caught it, and it bled on **18.5 and 26.4
        // alike**, which is what proved there were two causes rather than one:
        //
        //   1. iOS 26's automatic scroll-edge fade, which `.hard` opts out of. Absent
        //      below 26 — which is precisely why the bleed survived there and why
        //      fixing only this half would have looked right on the newest simulator
        //      and wrong on every shipping phone at the floor.
        //   2. `.bar`'s own frosted translucency, which bleeds on every runtime.
        //
        // `Palette.raised` is a flat, fully opaque fill; its doc comment requires a
        // hairline or shadow to carry its boundary at the 1.09:1 / 1.06:1 step, and the
        // top hairline is that — doubling as the seam between scrolled content and the
        // pinned control, exactly as it does on `TimerScreen`.
        .hardBottomScrollEdge()
        .background(Palette.screen)
        .safeAreaInset(edge: .bottom) {
            Button("Got it") { dismiss() }
                // Esc, on a keyboard (HL-058b).
                .keyboardShortcut(.cancelAction)
                .buttonStyle(.capsuleFilled)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Metrics.screenMargin)
                .padding(.vertical, Metrics.space3)
                .background(Palette.raised)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Palette.hairline)
                        .frame(height: Metrics.hairline)
                }
        }
    }

    /// Art column fixed and scaled; prose flows beside it. At accessibility sizes
    /// the pair stacks rather than squeezing the text.
    @ViewBuilder
    private func lesson(
        @ViewBuilder art: () -> some View,
        title: String,
        body: String
    ) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: Metrics.space4) {
                art().frame(width: 64, alignment: .center)
                lessonText(title: title, body: body)
            }
            VStack(alignment: .leading, spacing: Metrics.space3) {
                art()
                lessonText(title: title, body: body)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func lessonText(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: Metrics.space2) {
            Text(title)
                .font(.claim)
                .foregroundStyle(Palette.primaryText)
            Text(body)
                .font(.prose)
                .foregroundStyle(Palette.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Miniatures

/// The control at postage-stamp scale — same gradient, same word, same shape it
/// actually has. It became a slab with the screen it teaches (HL-003 slice 1): a
/// lesson that draws a circle while the screen below shows a bar is a lesson that
/// has to be unlearned in the same session it was given.
private struct MiniSlab: View {
    /// The stamp grows with its word. A flat box around a `.label`-role `Text` is a
    /// fixed frame on a text container — the one thing CLAUDE.md's layout rule names
    /// outright — and at AX5 it clipped "Start" mid-word, which the audit reported as
    /// `textClipped` on the only element in this app that was genuinely losing a
    /// character. Scaled against `.caption2`, the style `.dataText(.label)` itself
    /// resolves to, so the slab and the word grow at the same rate rather than at two
    /// rates that happen to agree at the default size.
    @ScaledMetric(relativeTo: .caption2) private var height: CGFloat = 34
    @ScaledMetric(relativeTo: .caption2) private var width: CGFloat = 108

    var body: some View {
        Text("Start", comment: "How It Works miniature slab: the same word the real slab shows while idle")
            .dataText(.label)
            .foregroundStyle(Palette.onEmber)
            .fixedSize()
            .frame(width: width, height: height)
            .background(
                // The same two named stops and the same continuous-corner radius as
                // the real slab (decision 0034 §6, `Metrics.slabRadius`), scaled down
                // with the stamp — a miniature of the control is still a control, and
                // a runtime mix is still a colour no contrast test can reach.
                RoundedRectangle(cornerRadius: Metrics.slabRadius * 0.5, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Palette.emberSlabTop, Palette.emberSlabBottom],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Palette.tint.opacity(0.35), radius: 8, y: 2)
            )
            .accessibilityHidden(true)
    }
}

/// Two starts and the dashed measurement between them — the one lesson other
/// timers get wrong, drawn rather than described.
private struct IntervalArc: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            ArcShape()
                .stroke(
                    Palette.tint,
                    style: StrokeStyle(lineWidth: 1.6, dash: [3, 3])
                )
                .frame(width: 56, height: 24)
            HStack {
                Circle().fill(Palette.tint).frame(width: 10, height: 10)
                Spacer()
                Circle().strokeBorder(Palette.hairline, lineWidth: 1.4)
                    .frame(width: 10, height: 10)
            }
            .frame(width: 56)
        }
        .accessibilityHidden(true)
    }

    private struct ArcShape: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.minX + 4, y: rect.maxY - 4))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - 4, y: rect.maxY - 4),
                control: CGPoint(x: rect.midX, y: rect.minY - 6)
            )
            return path
        }
    }
}

/// The timeline's silhouette, three nodes tall.
private struct MiniTimeline: View {
    var body: some View {
        VStack(spacing: 2) {
            Circle().fill(Palette.tint).frame(width: 10, height: 10)
            connector
            Circle().strokeBorder(Palette.hairline, lineWidth: 1.4).frame(width: 10, height: 10)
            connector
            Circle().strokeBorder(Palette.hairline, lineWidth: 1.4).frame(width: 10, height: 10)
        }
        .accessibilityHidden(true)
    }

    private var connector: some View {
        Rectangle().fill(Palette.hairline).frame(width: 1.4, height: 9)
    }
}

/// The real chip, at rest.
///
/// HL-009: mirrors the fix on the real header chip (`TimerScreen.headerLabels`) —
/// `chevron.forward`, not a baked `›` glyph, since this illustration is a literal
/// depiction of that chip and would otherwise teach the wrong picture under RTL.
private struct MiniChip: View {
    var body: some View {
        HStack(spacing: Metrics.space1) {
            // A figure, not copy: `verbatim` so the extractor never keys "5-1-1"
            // into the catalog for nine locales to translate into itself.
            Text(verbatim: "5-1-1")
            Image(systemName: "chevron.forward")
                .imageScale(.small)
        }
        .dataText(.label)
        .foregroundStyle(Palette.primaryText)
        .padding(.horizontal, Metrics.space3)
        .padding(.vertical, Metrics.space2)
        .overlay(Capsule().strokeBorder(Palette.hairline, lineWidth: 1))
        .accessibilityHidden(true)
    }
}

/// A thumbnail of the Live Activity: the count on a locked screen.
private struct MiniLockScreen: View {
    var body: some View {
        VStack(spacing: 2) {
            Text(verbatim: "0:38")  // a figure, not copy — see MiniChip above
                .dataText(.row)
                .foregroundStyle(Palette.primaryText)
            Text("LOCK SCREEN", comment: "caption on the How It Works miniature of the Lock Screen Live Activity. Rendered in caps by the type role, so translate as words rather than in capitals")
                .dataText(.label)
                .foregroundStyle(Palette.secondaryText)
        }
        .padding(Metrics.space2)
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Palette.hairline, lineWidth: 1.4))
        .accessibilityHidden(true)
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            HowItWorksScreen()
        }
}
