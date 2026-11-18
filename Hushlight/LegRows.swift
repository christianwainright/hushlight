import DesignKit
import LaborKit
import SwiftUI

/// HL-015: the rule's three legs — APART, LONG, HOLDING — as one shared component so
/// TimerScreen's verdict banner and History's pinned header cannot drift (F-0012).
/// Lives in the app target rather than DesignKit: DesignKit is tokens and components
/// with no knowledge of LaborKit's types, and this reads `Duration` and
/// `LaborPattern.GuidelineStatus` directly.

/// One leg of the rule, as an evidence row states it. `text`/`spokenValue` are
/// pre-rendered by the caller's own bound quantity — never a second derivation of the
/// figure (F-0012: a second derivation WILL disagree). `met` drives filled vs. open;
/// see `legRows`.
struct LegRow: Identifiable {
    var id: String { label }
    let label: String
    let text: String?
    let spokenValue: String?
    let met: Bool
}

/// The three legs in rule order — APART, LONG, HOLDING — reading the same
/// `averageInterval`/`averageDuration`/`patternLength` quantities every caller's own
/// sentence or readout already bound, never a recomputation of them.
///
/// All three inputs are optional: TimerScreen's banners bind `interval`/`length` from
/// an `if let` over a live/held/fast-met pattern (so they arrive non-nil there), but
/// History's pinned header (HL-015) reads a live pattern with no such prior floor
/// gating a whole banner into existence, so `averageInterval` in particular can be
/// genuinely absent (one contraction logged, nothing to average yet). A row prints
/// the same em dash a readout column prints below its own floor, rather than a leg
/// with nothing behind it.
///
/// `guideline` can be nil outright — the held shape's evidence floor can drain
/// entirely while `averageInterval` and `patternLength` still stand on their own,
/// lower floors — and a leg with no `GuidelineStatus` to ask draws **open**, never
/// guessed filled: `met` defaults to `false`, the same honest-unknown the marker is
/// for.
func legRows(
    interval: Duration?, duration: Duration?, length: Duration?,
    guideline: LaborPattern.GuidelineStatus?
) -> [LegRow] {
    // Decision 0022 §7's zero-as-measurement guard, restated for HOLDING: withheld
    // below a minute so a header shown the instant the very first contraction opens
    // (HL-015 has no other floor gating it into existence first) cannot print "0 M" —
    // the exact figure-that-reads-as-a-measurement the em dash exists to replace.
    // TimerScreen's own banners never exercised this edge (by the time one renders,
    // `patternLength` is already well past a minute), so folding the guard in here
    // costs those callers nothing while closing the gap for this one.
    let flooredLength = length.flatMap { $0 >= .seconds(60) ? $0 : nil }

    return [
        LegRow(
            label: String(localized: "APART", comment: "the APART leg row's label — the spacing leg of the guideline. Rendered in caps by the type role, so translate as a word, not in capitals"),
            text: interval.map(LaborFormat.minutesSeconds),
            spokenValue: interval.map(LaborFormat.spoken),
            met: guideline?.frequencyMet ?? false
        ),
        LegRow(
            label: String(localized: "LONG", comment: "the LONG leg row's label — the duration leg of the guideline. Rendered in caps by the type role, so translate as a word, not in capitals"),
            text: duration.map(LaborFormat.minutesSeconds),
            spokenValue: duration.map(LaborFormat.spoken),
            met: guideline?.durationMet ?? false
        ),
        LegRow(
            label: String(localized: "HOLDING", comment: "the HOLDING leg row's label — the sustained leg of the guideline. Rendered in caps by the type role, so translate as a word, not in capitals"),
            text: flooredLength.map(LaborFormat.hoursMinutes),
            spokenValue: flooredLength.map(LaborFormat.spoken),
            met: guideline?.sustainedMet ?? false
        ),
    ]
}

/// One evidence row. The marker is `Palette.goTime` filled when the leg currently
/// holds and a hollow `Palette.hairline` ring when it is dipping — the same
/// happened/not-yet split `HowItWorksScreen`'s mini-timeline already draws
/// (`Circle().fill(tint)` vs. `Circle().strokeBorder(hairline, …)`), so a reader who
/// has seen that legend already knows this one. Decorative on its own; the row
/// carries the accessibility label and value.
///
/// Side by side while it fits, stacked at accessibility sizes — the same
/// `ViewThatFits`-style branch the slip strip already takes, for the same reason: a
/// leg name and its figure sharing one line at AX5 is the layout that clips.
struct LegRowView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let leg: LegRow

    var body: some View {
        let marker = Group {
            if leg.met {
                Circle().fill(Palette.goTime)
            } else {
                Circle().strokeBorder(Palette.hairline, lineWidth: 1.4)
            }
        }
        .frame(width: 8, height: 8)

        let label = Text(leg.label)
            .dataText(.label)
            .foregroundStyle(Palette.secondaryText)

        // Same em-dash convention `column(_:)` renders below its own floor — never
        // a zero, and dimmed the same way a missing readout figure is.
        let value = Text(leg.text ?? "—")
            .dataText(.row)
            .foregroundStyle(leg.text == nil ? Palette.secondaryText : Palette.primaryText)

        return Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: Metrics.space1) {
                    HStack(spacing: Metrics.space2) { marker; label }
                    value
                }
            } else {
                HStack(spacing: Metrics.space2) {
                    marker
                    label
                    Spacer(minLength: Metrics.space2)
                    value
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(leg.label.lowercased())
        // **The marker speaks too** (HL-023, F-0045). Filled or hollow is a real
        // non-colour signal — shape, not tint — and a sighted reader takes the whole
        // rule's state off three dots at a glance. Spoken, the figure arrived alone
        // and the state did not, which on History's pinned header is the only place
        // that state is carried at all: there is no verdict sentence beside it there
        // to compensate the way the timer's banner does.
        .accessibilityValue(legSpokenValue)
    }

    private var legSpokenValue: String {
        guard let spoken = leg.spokenValue else {
            return String(localized: "not enough evidence yet", comment: "VoiceOver: value of a rule-leg row below its evidence floor, in place of a measurement")
        }
        return leg.met
            ? String(localized: "\(spoken), met", comment: "VoiceOver: a rule-leg's value followed by the fact that this leg of the guideline is currently satisfied")
            : String(localized: "\(spoken), not yet", comment: "VoiceOver: a rule-leg's value followed by the fact that this leg of the guideline is not yet satisfied — same 'not yet' register the verdict copy uses")
    }
}
