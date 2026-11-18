import ActivityKit
import DesignKit
import LaborKit
import SwiftUI
import WidgetKit

@main
struct HushlightWidgets: WidgetBundle {
    var body: some Widget {
        ContractionActivityWidget()
        ContractionControl()
    }
}

/// **Control Center and the Lock Screen's controls** (HL-065). A plain button, not
/// a toggle: a toggle would have to read whether a contraction is running, and that
/// fact lives in the app's sandbox, which this extension cannot see without the App
/// Group the ratchet forbids. The Live Activity is where the state shows; this is
/// only the door. `StartStopContractionIntent` is a `LiveActivityIntent`, so the
/// tap runs in the app's process — and refuses to write if it ever does not.
struct ContractionControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "net.wainright.hushlight.contraction") {
            ControlWidgetButton(action: StartStopContractionIntent()) {
                Label {
                    Text("Contraction", comment: "Control Center control's label: the button that starts or ends a contraction")
                } icon: {
                    Image(systemName: "stopwatch")
                }
            }
        }
        .displayName(LocalizedStringResource("Start or stop a contraction", comment: "the intent's name as it appears in Shortcuts/Spotlight — the lock-screen Live Activity button that starts or ends a contraction"))
        .description(LocalizedStringResource("One tap starts the timing; the next ends it.", comment: "Control gallery description of the Control Center control that starts or ends a contraction"))
    }
}

/// The lock screen during labor. One glance, one button: the elapsed count ticks
/// via `timerInterval` — the system draws every second, no process ever wakes —
/// and the tap runs `StartStopContractionIntent` in the app's process, which is
/// what lets the store stay in the app sandbox (decision 0018, SP-186).
struct ContractionActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ContractionActivityAttributes.self) { context in
            LockScreenView(state: context.state)
                .padding(Metrics.space4)
                .activityBackgroundTint(Palette.screen.opacity(0.9))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    LockScreenView(state: context.state)
                        .padding(.vertical, Metrics.space2)
                }
            } compactLeading: {
                Text("CTX", comment: "Dynamic Island compact leading label, an abbreviation of contractions. Rendered in caps by the type role — keep it to three or four characters, it shares a very narrow slot with the timer")
                    .dataText(.label)
                    .foregroundStyle(Palette.secondaryText)
            } compactTrailing: {
                if let since = context.state.runningSince {
                    // The island's compact slot is width-capped; the system timer
                    // text stays within it.
                    //
                    // F-0060 (HL-063): on an iPhone Duo the island runs down the side,
                    // and its compact slot is narrower than this 44 pt cap — the count
                    // wrapped inside itself, "0:0" over "4". One line, always: the
                    // figure shrinks before it ever breaks, every digit kept.
                    Text(timerInterval: since...since.addingTimeInterval(8 * 3600),
                         countsDown: false, showsHours: false)
                        .dataText(.label)
                        .monospacedDigit()
                        .lineLimit(1)
                        // The timer reserves the width of its longest value and sets
                        // the digits at its trailing end; centred, the four that are
                        // actually showing sit in the middle of the slot instead of
                        // under the island's curved edge.
                        .multilineTextAlignment(.center)
                } else {
                    // A count, not copy — `verbatim`, so no `%lld` catalog key.
                    Text(verbatim: "\(context.state.contractionCount)")
                        .dataText(.label)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            } minimal: {
                Text(verbatim: "\(context.state.contractionCount)")
                    .dataText(.label)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            // F-0060: the vertical island's compact slot is about four monospaced label
            // glyphs wide once the system's own margin is taken; the count needs all
            // four. The system timer text does not honour a scale factor here, so the
            // room comes from the margin instead.
            .contentMargins(.horizontal, 2, for: .compactTrailing)
        }
    }
}

private struct LockScreenView: View {
    let state: ContractionActivityAttributes.ContentState
    /// StandBy's night mode (HL-013, decision 0042): the StandBy surface *is* this
    /// activity — a widget would need the App Group the ratchet forbids — so the
    /// night presentation lives here. Reduced luminance means a nightstand across a
    /// dark room: the figures take the distance scale and the chrome stands down.
    /// The OS's red night tint is system furniture; the palette stays red-free and
    /// the system may tint as it pleases.
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    var body: some View {
        HStack(alignment: .center, spacing: Metrics.space4) {
            // Combined here, not on the row: "CONTRACTIONS" alone and a bare
            // "1:23" alone are two context-free stops, but this pair has nothing
            // interactive to swallow. The row-level combine used to also catch
            // the button below, merging its own label into the same static
            // string and folding the continuously-updating timer text in with it.
            VStack(alignment: .leading, spacing: Metrics.space2) {
                Text("CONTRACTIONS", comment: "Lock Screen Live Activity section label above the figures. Rendered in caps by the type role, so translate as a word rather than in capitals")
                    .dataText(.label)
                    .foregroundStyle(Palette.secondaryText)

                if let since = state.runningSince {
                    Text(timerInterval: since...since.addingTimeInterval(8 * 3600),
                         countsDown: false)
                        // The hero scale at reduced luminance: the reading
                        // distance is a nightstand's, not a hand's.
                        .dataText(isLuminanceReduced ? .hero : .stat)
                        .monospacedDigit()
                        .foregroundStyle(Palette.primaryText)
                } else {
                    // Idle: the figure triage asks for first, or an em dash — the
                    // same never-print-a-zero rule as the app's readout.
                    Text(idleLine)
                        .dataText(.stat)
                        .foregroundStyle(Palette.primaryText)
                        // Mono caps are for the glance; VoiceOver would spell
                        // "AVG" out letter by letter, so the spoken form says the
                        // words — same split the app's readout columns keep.
                        .accessibilityLabel(spokenIdleLine)
                }
            }
            .accessibilityElement(children: .combine)

            Spacer(minLength: Metrics.space3)

            Button(intent: StartStopContractionIntent()) {
                Text(state.runningSince == nil ? "Start" : "End", comment: "Lock Screen Live Activity button word — Start while idle, End while a contraction is running, same words the app's own slab uses")
                    .font(.prose)
                    .fontWeight(.semibold)
                    // Idle rests on the tint fill below and needs its ink;
                    // running rests on the neutral `inputFill`, same as the
                    // app's own disc.
                    .foregroundStyle(state.runningSince == nil ? Palette.onEmber : Palette.primaryText)
                    .frame(minWidth: 88, minHeight: Metrics.minimumTapTarget)
            }
            .buttonStyle(.plain)
            .background(
                Capsule().fill(
                    state.runningSince == nil ? Palette.tint : Palette.inputFill
                )
            )
            .accessibilityLabel(state.runningSince == nil
                ? String(localized: "Start contraction", comment: "VoiceOver label for the Live Activity button while idle")
                : String(localized: "End contraction", comment: "VoiceOver label for the Live Activity button while a contraction is running"))
        }
    }

    /// SP-213: the average leads. One irregular pair used to answer "how far
    /// apart?" with an outlier on the one surface read during the drive in; the
    /// average is the figure the app's own INTERVAL column leads with, under the
    /// same evidence floor. The last gap stays as the labelled fallback for the
    /// young pattern that has intervals but no average yet, and the em dash stays
    /// for no figures at all — never a zero.
    private var idleLine: String {
        guard state.contractionCount > 0 else { return "—" }
        if let average = state.averageIntervalSeconds {
            return String(localized: "AVG \(minutesSeconds(average)) APART · \(state.contractionCount)", comment: "Lock Screen Live Activity idle line with an average: the mean interval and how many contractions it is drawn from. Rendered in caps by the type role. Arguments are a formatted mm:ss interval and a count")
        }
        if let last = state.lastIntervalSeconds {
            return String(localized: "LAST \(minutesSeconds(last)) APART · \(state.contractionCount)", comment: "Lock Screen Live Activity idle line before an average exists: the most recent interval and how many contractions are logged. Rendered in caps by the type role. Arguments are a formatted mm:ss interval and a count")
        }
        // No noun follows the count here ("3 logged", "1 logged" both already
        // read fine), so there is no plural agreement to wire — only the
        // argument's own type, a real `Int` interpolated directly rather than
        // pre-stringified, which is what lets it key into the catalog as `%lld`.
        return String(localized: "\(state.contractionCount) logged", comment: "Lock Screen Live Activity idle line, when there is no interval yet to average — a raw count of contractions logged")
    }

    private func minutesSeconds(_ seconds: Int) -> String {
        "\(seconds / 60):" + String(format: "%02d", seconds % 60)
    }

    /// The two `String(localized:)` calls below that interpolate `count` were
    /// already each one complete format string, not Swift-glued fragments; the
    /// actual violation was `count` itself, a Swift `== 1` ternary choosing
    /// between two bare nouns. It is now the same real-`Int`-through-
    /// `variations.plural` shape `LaborFormat.contractionCount` uses on the app
    /// side (this target cannot import `LaborFormat` — it lives in the app
    /// target, and the widget extension is its own target — so the shape is
    /// duplicated, not shared; decision-quality note: the two copies are kept
    /// deliberately in sync rather than promoted to a shared module here, the
    /// same tradeoff `CallSummaryFormat`'s doc comment already accepts for
    /// LaborKit's own duplicate of `minutesSeconds`).
    private var spokenIdleLine: String {
        guard state.contractionCount > 0 else {
            return String(localized: "No contractions yet", comment: "VoiceOver: Lock Screen Live Activity idle line, before any contraction has been recorded")
        }
        let count = String(localized: "\(state.contractionCount) contraction", comment: "a count of contractions, embedded in the Live Activity's spoken idle line — catalog plural entry")
        if let average = state.averageIntervalSeconds {
            return String(localized: "Averaging \(spokenGap(average)) apart, \(count)", comment: "VoiceOver: Live Activity idle line naming the average interval and the count")
        }
        if let last = state.lastIntervalSeconds {
            return String(localized: "Last gap \(spokenGap(last)), \(count)", comment: "VoiceOver: Live Activity idle line naming the last interval and the count, before an average exists")
        }
        return count
    }

    /// Same shape, and the same EN-preserving choice, as `LaborFormat.spoken` on
    /// the app side: real `Int` arguments key into the catalog's
    /// `variations.plural`, but English's own `one` category is kept reading the
    /// same as `other` ("1 seconds", "1 minutes") for consistency with that
    /// twin function rather than diverging the app's two copies of one duration
    /// grammar — nothing in this target's own test coverage pins the widget's
    /// spoken text the way `SnapshotFactAssertionTests`/`ContractionMechanicsTests`
    /// pin the app's, so a future decision is free to move this one alone.
    private func spokenGap(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let rest = seconds % 60
        if minutes == 0 {
            return String(localized: "\(rest) seconds", comment: "VoiceOver: a duration under one minute, spoken as a count of seconds — catalog plural entry, English's own \"one\" category intentionally reads the same as \"other\"")
        }
        return rest == 0
            ? String(localized: "\(minutes) minutes", comment: "VoiceOver: a duration of whole minutes, spoken — catalog plural entry, English's own \"one\" category intentionally reads the same as \"other\"")
            : String(localized: "\(minutes) minutes \(rest) seconds", comment: "VoiceOver: a duration of minutes and seconds, spoken — both counts are catalog plural entries, English's own \"one\" categories intentionally read the same as \"other\"")
    }
}
