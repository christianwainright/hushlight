import DesignKit
import LaborKit
import SwiftUI

/// The story of the current episode, newest at the top, capped at four rows so it
/// never fights the button for the screen (SP-187; anatomy card in the Claude
/// Design project). Each contraction is a node with its duration and start time;
/// the start-to-start interval sits on the connector between the pair it measures.
///
/// This renders raw record, not derived figures, so no evidence floor applies —
/// one contraction is one node. Averages and verdicts keep their floors elsewhere.
struct EpisodeTimeline: View {
    /// The current episode, oldest first, as `LaborPattern.episode` provides it.
    let episode: [Contraction]
    /// The clock, from the screen's `TimelineView` — drives the live node's count.
    let now: Date

    private static let maximumRows = 4

    /// One width for the duration column in nodes *and* connectors, scaled with
    /// type — if they measured independently, the connector line would drift off
    /// the dots the moment Dynamic Type grew the figures.
    ///
    /// **Ordinary sizes only** (HL-031). This is the column the accessibility branch
    /// exists to stop using: scaled to AX5 it is ~235 pt of a 402 pt screen, and with
    /// `nodeDiameter`'s ~90 pt beside it there is nothing left for the figure that has
    /// to sit third. See `body` for the whole account.
    @ScaledMetric(relativeTo: .body) private var leadingColumnWidth: CGFloat = 76

    /// Which arrangement the rows take. The same split `LegRowView` makes, for the
    /// same reason and with the same words: side by side while it fits, stacked at
    /// accessibility sizes.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// The node's resting diameter, scaled to the same role its ordinal is set in.
    /// Contraction 10 arrives in every real labor, so the shape has to grow with
    /// two digits and with Dynamic Type instead of clipping them.
    @ScaledMetric(relativeTo: .caption2) private var nodeDiameter: CGFloat = 26

    /// SP-195: the live node's roll shares one clock with the hero numeral above it
    /// (the circle it used to share it with became a slab in HL-003 slice 1, and the
    /// count moved out of the control) — so it has to share that numeral's Reduce
    /// Motion gate too, or the claim stops being true for exactly the reader who
    /// asked for stillness.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Newest first for display; the slice keeps the newest end of the episode.
    private var rows: [Contraction] {
        episode.suffix(Self.maximumRows).reversed()
    }

    /// **Two fixed columns and a figure that has to fit after them** (HL-031, F-0055).
    ///
    /// A row is `[figures][dot][flag]` and a connector is `[gap][rule][interval]`, and
    /// the first two slots of each are fixed widths that scale with type:
    /// `leadingColumnWidth` against `.body`, `nodeDiameter` against `.caption2`. That
    /// is the whole point of them — one width shared by nodes and connectors is what
    /// keeps the thread running true down the column instead of drifting off the dots
    /// as Dynamic Type grows the figures.
    ///
    /// It stops working entirely at accessibility sizes. Scaled to AX5 the two come to
    /// roughly 235 pt and 90 pt of a 402 pt screen, so whatever sits third is proposed
    /// a sliver: "5:00 apart" wrapped to **one character per line**, a vertical strip
    /// of letters down the right edge with the row several hundred points tall. The
    /// nodes hid it — they usually have nothing after their two columns, since the
    /// CHECK flag is absent on a healthy row — so it read as an empty timeline with
    /// something strange at the margin rather than as a layout that had collapsed.
    ///
    /// Note the direction of the failure: nothing was widened. Decision 0048
    /// §Boundaries records that widening `leadingColumnWidth` to 98 pushed this screen
    /// into horizontal overflow at AX5, and declined to. This is the other half of
    /// that finding — at AX5 the *shipped* 76 pt is already too wide for what has to
    /// sit beside it.
    ///
    /// So at accessibility sizes the fixed columns go and the row stacks: the dot
    /// leads, the figures follow it in a leading-aligned stack, and the connector
    /// keeps only its rule — which lands under the dot, because the dot now leads the
    /// row too, so the thread still runs true without a fixed gap holding it there.
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, contraction in
                // Episode ordinal, not lifetime count — "how many this stretch" is
                // the question a nurse actually asks. Arithmetic, not a search:
                // rows run newest-first off the end of the episode, so the row at
                // `index` is the episode's `count - index`th contraction.
                node(
                    contraction,
                    ordinal: episode.count - index,
                    // The connector row is hidden from VoiceOver, so the interval
                    // it would have spoken has to live somewhere reachable — on
                    // the older of the pair it measures, since `rows` runs
                    // newest-first and index 0 (the newest) has nothing after it
                    // yet to report an interval to.
                    intervalToNext: index > 0
                        ? PatternAnalysis.interval(from: contraction, to: rows[index - 1])
                        : nil
                )
                if index < rows.count - 1 {
                    connector(to: rows[index + 1], from: contraction)
                }
            }
        }
    }

    // MARK: Rows

    private func node(
        _ contraction: Contraction, ordinal: Int, intervalToNext: Duration?
    ) -> some View {
        let isAccessibility = dynamicTypeSize.isAccessibilitySize
        let dot = nodeDot(ordinal: ordinal, isLive: contraction.endedAt == nil)
        // Trailing while the figures sit in their own fixed column to the left of the
        // thread; leading once they follow the dot instead, so both lines start on the
        // same edge rather than ragging against a column that is no longer there.
        let figures = VStack(alignment: isAccessibility ? .leading : .trailing, spacing: 1) {
            if let duration = contraction.duration {
                Text(LaborFormat.minutesSeconds(duration))
                    .dataText(.row)
                    .foregroundStyle(Palette.primaryText)
                // Minute precision here, deliberately — decision 0048 §Boundaries.
                // This column is 76 pt and holds two stacked values; a clock time
                // carrying its seconds wraps mid-token into "8:34:57 P / M", and
                // widening the column to 98 was measured pushing the whole screen
                // into horizontal overflow at AX5 (content spanning the full 402 pt
                // instead of stopping at the margin). History's rows and the export
                // — where a reader actually checks a gap against two times — carry
                // the seconds instead.
                Text(contraction.startedAt.formatted(date: .omitted, time: .shortened).uppercased())
                    .dataText(.label)
                    .foregroundStyle(Palette.secondaryText)
            } else {
                Text(LaborFormat.minutesSeconds(.seconds(max(0, now.timeIntervalSince(contraction.startedAt)))))
                    .dataText(.row)
                    .foregroundStyle(Palette.emberLive)
                    // Rolls in step with the hero numeral above — one clock, one
                    // motion, both stilled under Reduce Motion.
                    .contentTransition(.numericText(countsDown: false))
                    .animation(reduceMotion ? nil : .linear(duration: 0.2), value: now)
                Text("NOW", comment: "timeline present-moment marker. Rendered in caps by the type role, so translate as a word rather than in capitals")
                    .dataText(.label)
                    .foregroundStyle(Palette.secondaryText)
            }
        }

        // The same words for the same fact, whether the record has ended or is
        // still running (SP-204): `suspicion` needs `endedAt`, so before this the
        // flag structurally could not fire on the one row actually on screen —
        // a timer left running past twenty-five minutes read as routine.
        let flag = Group {
            if let suspicion = contraction.suspicion {
                // Words, not color — orange stays reserved for the suite's semantic
                // roles. The row keeps its place; the averages already exclude it.
                Text(LaborFormat.checkFlag(suspicion))
            } else if contraction.isRunningLong(at: now) {
                Text(LaborFormat.checkFlag(.tooLong))
            }
        }
        .dataText(.label)
        .foregroundStyle(Palette.secondaryText)

        return Group {
            if isAccessibility {
                // `.top` rather than `.center`: the dot is one line tall and the stack
                // beside it is two or three, and a dot floating level with the middle
                // of a three-line block has visibly come off the thread.
                HStack(alignment: .top, spacing: Metrics.space3) {
                    dot
                    VStack(alignment: .leading, spacing: 1) {
                        figures
                        flag
                    }
                    Spacer(minLength: 0)
                }
            } else {
                HStack(alignment: .center, spacing: Metrics.space3) {
                    figures.frame(width: leadingColumnWidth, alignment: .trailing)
                    dot
                    flag
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(minHeight: Metrics.minimumTapTarget * 0.75)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            nodeAccessibilityText(contraction, ordinal: ordinal, intervalToNext: intervalToNext)
        )
    }

    /// A capsule rather than a circle: round at one digit, a stadium at two, so the
    /// ordinal is never clipped. The outer fixed-width frame keeps every node
    /// centered on the same axis as the connectors — content wider than the frame
    /// overflows it symmetrically, so the line stays true down the column.
    private func nodeDot(ordinal: Int, isLive: Bool) -> some View {
        // The node's own number: a figure, never a translatable key.
        Text(verbatim: "\(ordinal)")
            .dataText(.label)
            .foregroundStyle(isLive ? Palette.onEmber : Palette.secondaryText)
            // Refuses the outer frame's width proposal, so "14" stays on one line
            // and widens the capsule instead of wrapping to two rows inside it.
            .fixedSize()
            .padding(.horizontal, Metrics.space2)
            .frame(minWidth: nodeDiameter, minHeight: nodeDiameter)
            .background(
                Capsule().fill(isLive ? Palette.emberLive : Color.clear)
            )
            .overlay(
                Capsule().strokeBorder(
                    isLive ? Palette.emberLive : Palette.hairline,
                    lineWidth: 1.5
                )
            )
            .shadow(
                color: isLive ? Palette.emberLive.opacity(0.35) : .clear,
                radius: isLive ? 6 : 0
            )
            .frame(width: nodeDiameter)
    }

    /// The connector between two nodes carries the start-to-start interval of
    /// exactly that pair — drawn where the gap it measures is.
    private func connector(to older: Contraction, from newer: Contraction) -> some View {
        let interval = PatternAnalysis.interval(from: older, to: newer)
        return HStack(alignment: .center, spacing: Metrics.space3) {
            // The gap that holds the rule under the dots — and only while the dots are
            // in the second slot. At accessibility sizes the node's dot leads its own
            // row, so the rule leads too and the thread stays true with no gap at all;
            // keeping one here would push this row's interval into exactly the sliver
            // HL-031 is about, on the one row that has always had something after the
            // two fixed columns.
            if !dynamicTypeSize.isAccessibilitySize {
                Color.clear.frame(width: leadingColumnWidth, height: 1)
            }
            Rectangle()
                .fill(Palette.hairline)
                .frame(width: Metrics.hairline)
                .frame(width: nodeDiameter)
                // A stub between rows while the columns hold the interval out to the
                // right of the thread, where nothing else sits and it cannot be read
                // as anything but a gap. Stacked, it has to work harder: the interval
                // lands at the same indent and the same `.label` weight as the node's
                // own clock time directly above it, so "5:00 apart" and "9:57 PM" are
                // told apart by the word `apart` alone. Letting the rule span the row
                // gives the eye the cue the columns used to: an unbroken thread beside
                // a figure means the figure is about the space between two
                // contractions, not about either one of them.
                .frame(
                    minHeight: 22,
                    maxHeight: dynamicTypeSize.isAccessibilitySize ? .infinity : 22
                )
            Text("\(LaborFormat.minutesSeconds(interval)) apart", comment: "timeline connector: the start-to-start interval between the two adjoining nodes")
                .dataText(.label)
                .foregroundStyle(Palette.secondaryText)
                // The figure the whole row exists to print. Without this it is the
                // element that yields when the row runs short — which is how it came
                // to be rendered one character per line rather than simply wrapping.
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .accessibilityHidden(true)
    }

    /// The connector's interval is decorative-hidden (below), so this is the only
    /// place a VoiceOver reader can hear the start-to-start gap decision 0018 calls
    /// the clinically standard measure — appended to the older of the pair it
    /// describes, in the direction time actually runs.
    private func nodeAccessibilityText(
        _ contraction: Contraction, ordinal: Int, intervalToNext: Duration?
    ) -> String {
        // Same shape as `CallSummary`'s clause list (see its doc comment): which
        // clauses appear is row truth, each one is already a complete
        // independent catalog phrase, and a variable-length list of them joins
        // with a plain separator. Restructured from `text +=` — which, on the
        // CHECK-flag clauses, was gluing on a *bare* Swift interpolation with no
        // `String(localized:)` wrapper at all (harmless in English today only
        // because `spokenCheckFlag`'s own return value was already fully
        // resolved; still not a catalog-backed join) — into the same
        // parts-array-and-join every other multi-clause accessibility string in
        // this app now uses.
        var parts: [String] = []
        if let duration = contraction.duration {
            parts.append(String(localized: "Contraction \(ordinal), lasted \(LaborFormat.spoken(duration)), at \(contraction.startedAt.formatted(date: .omitted, time: .shortened))", comment: "VoiceOver: timeline node — ordinal, duration, and start time of a finished contraction"))
            if let intervalToNext {
                parts.append(String(localized: "\(LaborFormat.spoken(intervalToNext)) before the next one", comment: "VoiceOver: timeline node clause naming the interval to the next contraction"))
            }
            if let suspicion = contraction.suspicion {
                parts.append(LaborFormat.spokenCheckFlag(suspicion))
            }
        } else {
            // Always the newest row, so `intervalToNext` is always nil here —
            // nothing has happened after it yet.
            parts.append(String(localized: "Contraction \(ordinal), running, \(LaborFormat.spoken(.seconds(now.timeIntervalSince(contraction.startedAt))))", comment: "VoiceOver: timeline node — ordinal and elapsed time of the contraction still running"))
            if contraction.isRunningLong(at: now) {
                parts.append(LaborFormat.spokenCheckFlag(.tooLong))
            }
        }
        return parts.joined(separator: ", ")
    }
}
