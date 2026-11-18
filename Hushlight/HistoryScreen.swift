import DesignKit
import LaborKit
import SwiftUI

/// Every contraction, grouped by episode, newest first. This is the screen a nurse
/// gets shown — start times, durations, intervals — and the place mis-taps get
/// cleaned up: swipe to delete, one Undo in the toolbar for the last action.
struct HistoryScreen: View {
    @Environment(LaborModel.self) private var model
    @State private var isConfirmingClear = false
    @State private var isConfirmingFlaggedSweep = false

    /// **A correction is felt, not only seen** (SP-202). Bumped by undo and by a
    /// swipe delete so a fix made one-handed, mid-contraction, lands as a texture
    /// distinct from the timer's own `.start`/`.stop` pair — three feelings, three
    /// meanings. A counter rather than the model's `undoAction`, which changes on
    /// every ordinary tap and would buzz for the timing itself.
    ///
    /// One overlap is deliberate: undoing a tap that opened or closed a contraction
    /// changes `isRunning` too, so the timer's texture plays alongside this one.
    /// Both things did happen, and saying so twice beats saying one of them.
    @State private var corrections = 0

    var body: some View {
        Group {
            if model.contractions.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .background(Palette.screen)
        // HL-015: the rule's three legs, pinned above the newest episode regardless
        // of scroll position. `safeAreaInset`, not a `List` section header: a native
        // section header only stays pinned while its own section's rows are on
        // screen, then yields to the next section's header as the reader scrolls
        // into older nights — exactly wrong here, because these figures describe
        // *tonight* continuously, not "whichever section happens to be in view."
        // `safeAreaInset` sits above the list's content permanently, adjusting the
        // list's own inset so scrolling never covers it, which is what "pinned" and
        // "furniture" both mean in the item's own language.
        .safeAreaInset(edge: .top) {
            if let legs = pinnedLegs {
                PinnedLegHeader(legs: legs)
            }
        }
        .navigationTitle("History")
        // The sweep's own confirmation. System-presented, so its destructive button
        // keeps the platform's red (decision 0046) — and its message names what
        // survives, because "delete flagged" is only safe if the reader knows that
        // flagged means the app's own CHECK marks and nothing else.
        .confirmationDialog(
            Text("Delete flagged records?", comment: "title of the confirmation for sweeping every CHECK-flagged record at once"),
            isPresented: $isConfirmingFlaggedSweep,
            titleVisibility: .visible
        ) {
            Button("Delete \(model.flaggedCount) Flagged", role: .destructive) {
                model.deleteFlagged()
                corrections += 1
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("These are the records already marked CHECK — a stop-tap missed by more than three minutes, or a tap under twenty seconds. Timed contractions are not touched, and Undo puts them all back.", comment: "message of the flagged-sweep confirmation, naming what is removed, what survives, and that the whole sweep is one undo")
        }
        .sensoryFeedback(.levelChange, trigger: corrections)
        .toolbar {
            if model.undoAction != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Undo") {
                        model.undo()
                        corrections += 1
                    }
                }
            }
            // **Out of the scroll flow** (SP-212). "Clear All History…" used to be the
            // last row of the list, which put an irreversible control directly under a
            // momentum scroll through the record of her night — the one gesture on this
            // screen that ends with a thumb landing somewhere nobody aimed. A menu
            // cannot be reached by inertia: it takes a deliberate tap, and then a
            // second one. The ellipsis stays, because it still opens a question rather
            // than doing the thing.
            if !model.contractions.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        // **No role here, and that is the ratchet, not a slip.**
                        // `role: .destructive` draws the item in system red, and red
                        // is not in this app's palette under any rationale
                        // (CLAUDE.md). It would also be describing the wrong thing:
                        // this item opens a question — the ellipsis says so — and the
                        // dialog behind it is what actually destroys anything. The
                        // weight belongs on the confirmation, in words, where the
                        // consequence is named; a red menu item spends the alarm
                        // register on a tap that deletes nothing.
                        // **The middle path** (HL-027). Offered only when there is
                        // something flagged to sweep, so the menu never advertises a
                        // cleanup with nothing to clean — and named with its count, so
                        // the offer states its scope before it is taken. No destructive
                        // role here either, for the reason spelled out just above.
                        if model.flaggedCount > 0 {
                            Button("Delete \(model.flaggedCount) Flagged…") {
                                isConfirmingFlaggedSweep = true
                            }
                        }
                        Button("Clear All History…") {
                            isConfirmingClear = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel(String(localized: "More", comment: "VoiceOver label for the History screen's overflow menu button"))
                }
            }
        }
        // SP-215: one dialog now shared with the timer screen's closure recap —
        // see `ClearHistoryConfirmation`. The newest episode, chronological, is
        // what "Save a copy first…" would export; `PatternAnalysis.episodes(_:)`
        // is the one definition of "newest episode" both call sites read.
        .clearHistoryConfirmation(
            isPresented: $isConfirmingClear,
            episodeToSave: PatternAnalysis.episodes(model.contractions).last ?? []
        )
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: Metrics.space2) {
            Text("Nothing logged yet.", comment: "History screen empty-state headline, before any contraction has been recorded")
                .font(.claim)
                .foregroundStyle(Palette.primaryText)
            Text("Every contraction you time appears here with its duration and the interval since the one before.", comment: "History screen empty-state caption")
                .font(.prose)
                .foregroundStyle(Palette.secondaryText)
        }
        .padding(.horizontal, Metrics.screenMargin)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.top, Metrics.space6)
    }

    /// **Decision 0043's trend** — this hour against the hour before it, computed
    /// once so it never disagrees with itself between the presence check below and
    /// the render. Nil for free whenever there is nothing to compare: a too-young
    /// episode (either window still below its own floor), a steady one (the delta
    /// sits under the one-sixth noise floor), or a concluded stretch — the engine's
    /// own staleness gate already empties `averageInterval` past the episode-gap
    /// liveness the timer screen reads the same way, so nothing here re-checks it.
    private var currentTrend: LaborTrend? {
        PatternAnalysis.trend(for: model.contractions, rule: model.rule, now: Date())
    }

    /// Decision 0050 — this stretch against the one before it. Rule-free, unlike
    /// `currentTrend`: the comparison is two whole-episode means against each other and
    /// never asks whether either met anything, so the selected guideline has no say in
    /// it. Computed fresh on every render for the same reason `currentTrend` is.
    private var stretchComparison: StretchComparison? {
        PatternAnalysis.stretchComparison(for: model.contractions, now: Date())
    }

    /// **HL-015.** The rule's three legs — measured quantities with the rule as
    /// annotation, never a progress bar toward a verdict — read off the same live
    /// pattern the timer screen's own banners read, so the two surfaces cannot
    /// disagree about tonight (F-0012). `legRows` and `LegRowView` are the shared
    /// component `Hushlight/LegRows.swift` extracts from TimerScreen for exactly this
    /// reuse.
    ///
    /// Computed fresh on every render, the same as `currentTrend` just above rather
    /// than a `TimelineView` of its own: History is a screen she glances at and
    /// leaves, not one she watches tick for minutes the way the timer's own hero
    /// numeral is built to be, and every store mutation (a tap elsewhere, an undo, a
    /// merge) already forces a re-render through `@Observable`.
    ///
    /// Nil — no header — whenever `pattern.episode` is empty: nothing running and the
    /// newest start more than `PatternAnalysis.episodeGap` (2 h) ago. That single
    /// check also covers SP-215's `EpisodeClosure` (a 3-day "reads as concluded"
    /// threshold): 3 days is far past 2 h, so any episode `EpisodeClosure` would call
    /// concluded has already made `pattern.episode` empty on its own, well before —
    /// the item's "stale/concluded: no header" is one guard, not two, because the
    /// stronger one always fires first.
    private var pinnedLegs: [LegRow]? {
        let pattern = model.pattern()
        guard !pattern.episode.isEmpty else { return nil }
        return legRows(
            interval: pattern.averageInterval,
            duration: pattern.averageDuration,
            length: pattern.patternLength,
            guideline: pattern.guideline
        )
    }

    private var list: some View {
        List {
            ForEach(Array(model.episodesNewestFirst.enumerated()), id: \.offset) { offset, episode in
                Section {
                    // The episode's figures first — the line a provider call reads
                    // from — then the rows. Same evidence floors as everywhere.
                    if let summary = PatternAnalysis.summary(of: Array(episode)) {
                        StretchSummaryLine(summary: summary)
                            .listRowBackground(Palette.inputFill)
                            .listRowSeparator(.hidden)
                    }
                    // The trend caption rides the same band, and only under the
                    // *current* episode (`offset == 0`, the newest) — `currentTrend`
                    // is always this-episode's own figures or nil, so printing it
                    // under an older section would be attaching tonight's comparison
                    // to a stretch it never described.
                    if offset == 0, let trend = currentTrend {
                        TrendCaptionText(trend: trend)
                            .listRowBackground(Palette.inputFill)
                            .listRowSeparator(.hidden)
                    }
                    // Decision 0050's comparison rides the same band under the same
                    // `offset == 0` guard, and needs it for a second reason the trend
                    // does not: `stretchComparison` names *two* stretches, so printed
                    // under an older section it would be claiming that section is
                    // "this stretch" while quoting figures from two entirely different
                    // ones. Last of the three, and deliberately: the band states this
                    // stretch's own figures, the trend narrows to its last hour, and
                    // only then does the screen look outside tonight at all.
                    if offset == 0, let comparison = stretchComparison {
                        StretchComparisonText(comparison: comparison)
                            .listRowBackground(Palette.inputFill)
                            .listRowSeparator(.hidden)
                    }
                    // Rows carry their interval to the *previous* contraction, so the
                    // pairing is computed against the episode's chronological order.
                    ForEach(Self.rows(for: episode)) { row in
                        // An episode legally spans days (the 2 h gap rule), and the
                        // section header above only carries the *start* date — the
                        // oldest group in the section, at the bottom. Every other
                        // calendar day among the rows gets its own inline marker,
                        // right above the first (newest) row of that day, naming it
                        // outright (SP-214). Quieter than `SectionHeader`: same
                        // `sectionLabelText()` register, but no ruled hairline and no
                        // raised `inputFill` band — this is a wayfinding aid inside
                        // the section, not another section.
                        if let marker = row.dayMarker {
                            Text(marker)
                                .sectionLabelText()
                                .listRowBackground(Palette.screen)
                                .listRowSeparator(.hidden)
                                .accessibilityAddTraits(.isHeader)
                        }
                        HistoryRow(row: row)
                            .swipeActions {
                                Button("Delete", role: .destructive) {
                                    model.delete(row.contraction)
                                    corrections += 1
                                }
                                // HL-018: heals a double-tap split instead of only
                                // discarding it. Offered only on a suspect-*short*
                                // row (never `.tooLong` — a forgotten stop-tap has no
                                // "record before it" it was cut from) with a previous
                                // record to join; the model op re-checks both
                                // conditions itself, so this gate is UI convenience,
                                // not the only thing keeping it safe.
                                if row.contraction.suspicion == .tooShort,
                                   model.canMergeWithPrevious(row.contraction) {
                                    Button("Merge Up") {
                                        model.mergeWithPrevious(row.contraction)
                                        corrections += 1
                                    }
                                    .tint(Palette.tint)
                                }
                            }
                    }
                } header: {
                    if let first = episode.last {
                        Text(episodeLabel(startingAt: first.startedAt, count: episode.count))
                            .sectionLabelText()
                    }
                }
                .listRowBackground(Palette.screen)
            }

        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    /// "SUN, AUG 10 · FROM 7:42 PM · 14" — when the episode began and how many it
    /// holds. The day clause is `LaborFormat.dayMarker`, the same one-liner the
    /// inline midnight markers below use — one vocabulary for "what day is this",
    /// whether it is stated once here or repeated deeper in the section (SP-214).
    private func episodeLabel(startingAt start: Date, count: Int) -> String {
        let time = start.formatted(date: .omitted, time: .shortened).uppercased()
        return String(localized: "\(LaborFormat.dayMarker(start)) · FROM \(time) · \(count)", comment: "History's section header: the day the stretch began, the clock time it started at, and how many contractions it holds. \"FROM\" is the only word here — the rest is a date, a time and a count; the · separators stay")
    }

    struct Row: Identifiable {
        let contraction: Contraction
        let interval: Duration?
        /// Non-nil only on the newest row of a calendar-day group that isn't the
        /// section's start day — the row an inline day marker renders above.
        let dayMarker: String?
        /// Non-nil on every row not on the section's start day, marker or not —
        /// VoiceOver reads rows one at a time and a marker passed earlier is easy to
        /// lose track of, so each such row states its own day (SP-214).
        let spokenDay: String?
        var id: UUID { contraction.id }
    }

    /// Rows carry the start-to-start gap to the contraction before them. The
    /// position is arithmetic, not a search: row `offset` in a newest-first list of
    /// `n` is chronological index `n - 1 - offset`, and its predecessor is the next
    /// row down. Intervals come from `PatternAnalysis`, the one definition.
    ///
    /// Day markers ride the same walk. `episodeNewestFirst` runs newest to oldest,
    /// so the *last* element is the section's start — already named by the section
    /// header — and every other calendar day represented among the rows is "new"
    /// relative to it. A row opens a marker when its day differs from the row above
    /// it (or it's the very first row) and its day isn't the start day; every row
    /// off the start day also carries the spoken form, marker or not.
    static func rows(for episodeNewestFirst: [Contraction]) -> [Row] {
        let calendar = Calendar.current
        let startDay = episodeNewestFirst.last?.startedAt
        return episodeNewestFirst.enumerated().map { offset, contraction in
            let older = episodeNewestFirst.indices.contains(offset + 1)
                ? episodeNewestFirst[offset + 1]
                : nil
            let onStartDay = startDay.map { calendar.isDate(contraction.startedAt, inSameDayAs: $0) } ?? true
            let opensNewDayGroup = offset == 0
                || !calendar.isDate(contraction.startedAt, inSameDayAs: episodeNewestFirst[offset - 1].startedAt)
            return Row(
                contraction: contraction,
                interval: older.map { PatternAnalysis.interval(from: $0, to: contraction) },
                dayMarker: (opensNewDayGroup && !onStartDay) ? LaborFormat.dayMarker(contraction.startedAt) : nil,
                spokenDay: onStartDay ? nil : LaborFormat.spokenDayMarker(contraction.startedAt)
            )
        }
    }
}

/// **HL-015.** The pinned legs themselves — quiet on purpose: no wash, no card, no
/// headline, no call-to-action. TimerScreen's banner earns all of that because it
/// *is* the verdict; this is furniture that sits above it, describing tonight
/// whether or not a verdict is anywhere near firing. The guardrail is the item's
/// whole identity: measured quantities with the rule as annotation, never a
/// progress bar toward a verdict.
private struct PinnedLegHeader: View {
    let legs: [LegRow]

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.space2) {
            ForEach(legs) { leg in
                LegRowView(leg: leg)
            }
        }
        .padding(.horizontal, Metrics.screenMargin)
        .padding(.vertical, Metrics.space3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.screen)
        // One element naming the group before VoiceOver reaches the individual
        // legs, the same orienting role the verdict's two sentences play ahead of
        // `LegRowView` on the timer screen — there, prose already sets up what
        // "apart" and "long" refer to; here there is no sentence to do it, so the
        // header names itself instead.
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "The guideline's three legs, over the last hour", comment: "VoiceOver label grouping History's pinned rule-leg header — names the window these figures cover (decision 0047); the previous label said \"tonight so far\", which is untrue of hour-windowed figures"))
    }
}

/// Decision 0043 §4: "Averaging 5:40 apart — closer than an hour ago (was 7:10)."
/// Words carry the direction; colour only seconds it — the direction phrase alone
/// takes `Palette.tintText` (closer) or `Palette.easingText` (farther), never the
/// whole sentence, so the two shapes are never told apart by colour alone. Quiet
/// register throughout: `.prose`, the same face `recapLine` prints its sentence
/// in on the timer screen, not the mono-caps band it rides beside here.
///
/// Every ink here is the `inputFill` variant, not the room's — this whole caption
/// rides `.listRowBackground(Palette.inputFill)` (see the call site above), where
/// `tint`, `easing` and `secondaryText` all measure under AA in light appearance
/// (HL-019).
private struct TrendCaptionText: View {
    let trend: LaborTrend

    private var caption: LaborFormat.TrendCaption { LaborFormat.trendCaption(trend) }
    private var directionColor: Color {
        trend.direction == .closer ? Palette.tintText : Palette.easingText
    }

    var body: some View {
        // String interpolation, not `+` (deprecated iOS 26): the middle run's
        // own `foregroundStyle` survives being interpolated into the sentence,
        // the same as it would concatenated — this is the row's own ink for the
        // prefix and suffix, seconded by colour only on the direction phrase.
        Text("\(caption.prefix)\(Text(caption.direction).foregroundStyle(directionColor))\(caption.suffix)")
            .font(.prose)
            .foregroundStyle(Palette.secondaryTextOnFill)
            .accessibilityLabel(caption.spokenForm)
    }
}

/// Decision 0050's caption — this stretch against the one before it — drawn exactly
/// like its hourly sibling above, and for the same reasons: words carry the direction,
/// colour only seconds it, and every ink is the `inputFill` variant because the row it
/// rides is `inputFill` (HL-019).
///
/// The one addition is the steady case, which its sibling has no equivalent of. It
/// takes the row's own `secondaryTextOnFill` — no tint, no easing, no third hue. A
/// stretch spacing much like the last one is not a direction, and colouring it would
/// invent a fourth semantic role for the palette to mean "unchanged" when the plain
/// ink already means exactly that.
private struct StretchComparisonText: View {
    let comparison: StretchComparison

    private var caption: LaborFormat.TrendCaption {
        LaborFormat.stretchComparisonCaption(comparison)
    }
    private var directionColor: Color {
        switch comparison.direction {
        case .closer: Palette.tintText
        case .fartherApart: Palette.easingText
        case .aboutTheSame: Palette.secondaryTextOnFill
        }
    }

    var body: some View {
        Text("\(caption.prefix)\(Text(caption.direction).foregroundStyle(directionColor))\(caption.suffix)")
            .font(.prose)
            .foregroundStyle(Palette.secondaryTextOnFill)
            .accessibilityLabel(caption.spokenForm)
    }
}

/// **The stretch's figures in one line** — the line a provider call reads from — as
/// History's band prints it and, since HL-058, as the iPad ledger prints it beside the
/// timer. One view, so the two cannot drift; the caller supplies the row background.
/// Nothing when the summary has no line to give (below its evidence floors).
struct StretchSummaryLine: View {
    let summary: EpisodeSummary

    var body: some View {
        if let line = LaborFormat.episodeSummaryLine(summary) {
            Text(line)
                .dataText(.label)
                // HL-023: the mono-caps band reads as "A V G … H … M" without this.
                // Decision 0038's rule, applied to the one line in the app that had
                // been missed.
                .accessibilityLabel(LaborFormat.spokenEpisodeSummaryLine(summary) ?? line)
                // On `inputFill` (the caller's `listRowBackground`), not the room —
                // undarkened `secondaryText` measures 4.42:1 there in light
                // appearance, under AA (HL-019).
                .foregroundStyle(Palette.secondaryTextOnFill)
        }
    }
}

/// **Three figures on one line, and one of them is a clock time** (HL-032, F-0056).
///
/// Side by side while it fits, stacked at accessibility sizes — the third view in this
/// app to need that sentence, after `LegRowView` and `EpisodeTimeline`, and the one
/// where getting it wrong cost the most. At AX5 the row's three `.row` figures shredded
/// mid-token: `10:39:29 PM · 1:02 · +5:00` rendered as `10:31:0 / 9:29 2 PM` beside
/// `+5:0 / 0`. Not a near miss and not a wrap — the figures broke *inside* themselves,
/// so the digits on screen were no longer the time the record holds.
///
/// It matters more here than it did in the timeline. F-0055 mangled a decorative
/// connector whose interval is spoken elsewhere; these are the record rows, the ones a
/// woman reads back to a nurse over the phone. Decision 0048 widened them on purpose —
/// seconds on the start time exist so that a printed gap can be checked against two
/// printed times — and at AX5 that check was impossible, which is the whole of what 0048
/// bought being spent again.
///
/// Shared with the iPad ledger (HL-058), which prints the same rows beside the timer.
struct HistoryRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let row: HistoryScreen.Row

    var body: some View {
        // Seconds, because a gap is printed on this same row (decision 0048).
        let started = Text(LaborFormat.clockTimeWithSeconds(row.contraction.startedAt))
            .dataText(.row)
            .foregroundStyle(Palette.primaryText)

        let duration = Group {
            if let duration = row.contraction.duration {
                Text(LaborFormat.minutesSeconds(duration))
                    .dataText(.row)
                    .foregroundStyle(Palette.primaryText)
            } else {
                Text("RUNNING", comment: "History row badge on the contraction still being timed. Rendered in caps by the type role, so translate as a word rather than in capitals")
                    .dataText(.label)
                    .foregroundStyle(Palette.secondaryText)
            }
        }

        let trailing = Group {
            if let suspicion = row.contraction.suspicion {
                // A forgotten stop-tap or a slip. Either way: flagged, excluded from
                // the averages, and left for the owner to delete — never auto-deleted.
                Text(LaborFormat.checkFlag(suspicion))
                    .dataText(.label)
                    .foregroundStyle(Palette.secondaryText)
            } else if let interval = row.interval {
                // A signed figure, not copy — `verbatim`, so no `+%@` key.
                Text(verbatim: "+\(LaborFormat.minutesSeconds(interval))")
                    .dataText(.row)
                    .foregroundStyle(Palette.secondaryText)
            }
        }

        return Group {
            if dynamicTypeSize.isAccessibilitySize {
                // Reading order preserved exactly: when it happened, how long it ran,
                // how long since the one before. Stacking is the only change; a row
                // that reordered itself at one type size and not another would make
                // two readers describing the same screen disagree about it.
                VStack(alignment: .leading, spacing: Metrics.space1) {
                    started
                    duration
                    trailing
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: Metrics.space3) {
                    started
                    duration
                    Spacer(minLength: Metrics.space3)
                    trailing
                }
            }
        }
        .frame(minHeight: Metrics.minimumTapTarget)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var parts = [LaborFormat.clockTimeWithSeconds(row.contraction.startedAt)]
        // Off the section's start day, every row says which day it's on (SP-214) —
        // VoiceOver reads one row at a time, and the visual marker above the first
        // row of a group is easy to lose track of a few swipes later.
        if let spokenDay = row.spokenDay {
            parts.append(spokenDay)
        }
        // Each `parts` entry is already a complete, independent catalog phrase
        // (never a mid-sentence fragment); which ones are present is engine/row
        // truth (a duration, an interval, and a suspicion flag are each their
        // own optional fact about this one record). Joining a variable-length
        // list of complete phrases with a plain separator is the shape
        // CLAUDE.md's own CallSummary guidance sanctions ("each clause...
        // become translatable units with positions") — full enumeration of
        // every presence combination here (day × duration-or-running × interval
        // × suspicion is dozens of shapes) would trade one join operation for a
        // combinatorial catalog no translator benefits from.
        if let duration = row.contraction.duration {
            parts.append(String(localized: "lasted \(LaborFormat.spoken(duration))", comment: "VoiceOver: History row clause naming the contraction's duration"))
        } else {
            parts.append(String(localized: "still running", comment: "VoiceOver: History row clause for a contraction with no end tap yet"))
        }
        if let interval = row.interval {
            parts.append(String(localized: "\(LaborFormat.spoken(interval)) after the previous one", comment: "VoiceOver: History row clause naming the interval since the previous contraction"))
        }
        if let suspicion = row.contraction.suspicion {
            parts.append(LaborFormat.spokenCheckFlag(suspicion))
        }
        return parts.joined(separator: ", ")
    }
}

#Preview {
    NavigationStack {
        HistoryScreen()
            .environment(LaborModel())
    }
}
