import Foundation
import LaborKit

/// One place for every figure the screens print, so a duration never renders two
/// ways. Data numerals are monospaced by the type roles; these only make strings.
///
/// **Every entry clamps at zero (F-0011).** A duration reaching here can be negative
/// — a device clock set backwards, a timezone correction — and the arithmetic below
/// renders that as "-1:-10" and "-1 M", which are not small measurements but
/// impossible ones. Clamping here rather than at each call site is the same
/// single-definition move the rest of this file exists for: the engine floors its own
/// figures, and this floors anything that still arrives negative from a screen doing
/// its own subtraction against `now`.
enum LaborFormat {
    /// "4:50" — intervals and durations.
    static func minutesSeconds(_ duration: Duration) -> String {
        let total = max(0, Int(duration.components.seconds))
        return "\(total / 60):" + String(format: "%02d", total % 60)
    }

    /// "5:31–20:58" — the spread between two figures of the same kind. An en dash,
    /// not a hyphen: this is a range, and the glyph that says so is the one the
    /// system's own date and number formatters use.
    static func range(_ range: ClosedRange<Duration>) -> String {
        "\(minutesSeconds(range.lowerBound))–\(minutesSeconds(range.upperBound))"
    }

    /// "1 H 12 M" under the pattern column; "48 M" under an hour.
    static func hoursMinutes(_ duration: Duration) -> String {
        let totalMinutes = max(0, Int(duration.components.seconds)) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        // HL-046: the unit letters translate like the rest of the mono-caps
        // instrument vocabulary (decision 0062) — a Japanese reader gets 時間 and
        // 分, not two Latin initials for words their language does not spell that
        // way. The type role still supplies the caps.
        return hours > 0
            ? String(localized: "\(hours) H \(minutes) M", comment: "a duration of an hour or more, printed under a data column. \"H\" and \"M\" abbreviate hours and minutes; render them in this language's own abbreviations, and keep the figures where they are")
            : String(localized: "\(minutes) M", comment: "a duration under an hour, printed under a data column. \"M\" abbreviates minutes")
    }

    /// **How long ago** something happened — "under a minute", "8 M", "2 H",
    /// "1 H 12 M". Distinct from `hoursMinutes`, which renders **how long something
    /// lasted**: a column of durations wants one stable shape, a sentence about
    /// elapsed time wants to read.
    ///
    /// Two zeros are dropped here that `hoursMinutes` cannot drop. Below sixty
    /// seconds it renders "0 M", and a zero in a sentence about elapsed time is the
    /// same zero-as-measurement the columns' em dashes exist to prevent (decision
    /// 0022 §7) — prose can say what a data slot cannot, which is that the gap is
    /// real but too short to name. And on a whole hour it renders "2 H 0 M", where
    /// the trailing zero is a component of a compound figure rather than a
    /// measurement, but prose has no column to align and reads worse for carrying it.
    static func gap(_ duration: Duration) -> String {
        if duration < .seconds(60) {
            // A bare catalog string, no arguments to position — nothing here for
            // HL-007 to restructure. Kept as prose rather than a figure (decision
            // 0022 §7): the em-dash/absence rule this file's own header describes
            // is untouched by this item, exactly as CLAUDE.md's brief requires.
            return String(localized: "under a minute", comment: "elapsed time since the last contraction ended, when under one minute — replaces the zero a data column would otherwise show")
        }
        let totalMinutes = max(0, Int(duration.components.seconds)) / 60
        if totalMinutes >= 60, totalMinutes % 60 == 0 {
            return String(localized: "\(totalMinutes / 60) H", comment: "elapsed time on a whole hour, printed — \"H\" abbreviates hours")
        }
        return hoursMinutes(duration)
    }

    // MARK: Dates

    /// "SINCE 5:13 PM" today, "SINCE YESTERDAY 5:13 PM" yesterday, "SINCE FRI
    /// 5:13 PM" anything older (decision 0022 §3, SP-214) — the header's own
    /// mono-caps register, so the day-word reads as one clause with the time
    /// rather than an interruption before it.
    ///
    /// The day word comes from `EpisodeDay`, the pure and package-tested half of
    /// this decision (LaborKitTests) — this function only spells out what that
    /// enum already decided. `now` is whatever the caller is rendering against
    /// (the header's live `TimelineView` tick), so a reader who has the episode on
    /// screen across a timezone change sees it reclassified on the next render
    /// against the device's *current* calendar — never a value frozen from when
    /// the episode began. See `EpisodeDay.describe` for why that is the honest
    /// choice rather than a bug.
    static func since(_ start: Date, now: Date) -> String {
        let time = start.formatted(date: .omitted, time: .shortened).uppercased()
        switch EpisodeDay.describe(start: start, now: now) {
        case .today:
            return String(localized: "SINCE \(time)", comment: "timer header clause: when this stretch began, same day. Rendered in caps by the type role, so translate as words rather than in capitals. The argument is a clock time")
        case .yesterday:
            return String(localized: "SINCE YESTERDAY \(time)", comment: "timer header clause: when this stretch began, yesterday. Rendered in caps by the type role. The argument is a clock time")
        case .older:
            let weekday = start.formatted(.dateTime.weekday(.abbreviated)).uppercased()
            return String(localized: "SINCE \(weekday) \(time)", comment: "timer header clause: when this stretch began, earlier than yesterday. Rendered in caps by the type role. Arguments are an abbreviated weekday and a clock time")
        }
    }

    /// The spoken form of `since` — "since 5:13 PM", "since yesterday at 5:13 PM",
    /// "since Friday at 5:13 PM" — the same day word, prose case, with "at"
    /// inserted only where the day word would otherwise run straight into the
    /// clock time.
    static func spokenSince(_ start: Date, now: Date) -> String {
        let time = start.formatted(date: .omitted, time: .shortened)
        // Three branches, but not three concatenated fragments: each `case`
        // already returns one complete, independently-translatable catalog
        // sentence (which day word it is stays engine truth, from
        // `EpisodeDay.describe`) — the shape this item's format-string rule
        // asks for, not the assembly it forbids. Named here explicitly because
        // an earlier pass over this file flagged it for restructuring on the
        // strength of having "three branches" alone; it needed none.
        switch EpisodeDay.describe(start: start, now: now) {
        case .today:
            return String(localized: "since \(time)", comment: "VoiceOver: episode started at this clock time today")
        case .yesterday:
            return String(localized: "since yesterday at \(time)", comment: "VoiceOver: episode started at this clock time yesterday")
        case .older:
            let weekday = start.formatted(.dateTime.weekday(.wide))
            return String(localized: "since \(weekday) at \(time)", comment: "VoiceOver: episode started at this clock time on an earlier named weekday")
        }
    }

    /// "MON, AUG 24" — History's midnight-crossing day marker (SP-214), printed
    /// once per calendar-day group rather than once per row. Absolute, not
    /// relative: a marker sitting deep in a scrolled list has no fixed "now" the
    /// way the live header does, so it names the day outright rather than saying
    /// "yesterday" of an unstated reference point.
    static func dayMarker(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()).uppercased()
    }

    /// The same day, spoken — "on Monday, August 24" — carried on every row that
    /// is not on its section's start day (SP-214), not only the row the visual
    /// marker sits above: VoiceOver navigates row by row, and a marker passed two
    /// swipes back is easy to lose track of.
    static func spokenDayMarker(_ date: Date) -> String {
        String(localized: "on \(date.formatted(.dateTime.weekday(.wide).month(.wide).day()))", comment: "VoiceOver: the calendar day a group of History rows falls on, spoken form of the mono-caps day marker above")
    }

    /// Spoken equivalents for accessibility labels.
    ///
    /// **HL-007's plural-machinery line, drawn here.** Every argument below is a
    /// real `Int`, interpolated directly rather than pre-stringified — which
    /// already means the string it produces keys into the catalog as `%lld`, not
    /// `%@`, and the catalog's own `variations.plural` picks the grammatical
    /// number a translator's language needs (decision-quality note: the *old*
    /// hand-authored catalog entries for these four keys were typed `%@`, which
    /// never matched this runtime key at all — they were dead entries, silently
    /// falling back to Foundation's raw-pattern rendering, which is exactly the
    /// plain-decimal text they already show; the catalog fix here makes them live
    /// for the first time, it does not change what English renders).
    ///
    /// **What did not change: the English category text.** `SnapshotFactAssertionTests`
    /// and `ContractionMechanicsTests` parse this exact shape back out of the
    /// accessibility tree ("N seconds", "N minutes", never "N second"/"N minute"),
    /// so English's own `one` category is pinned to read the same as `other` here
    /// — the catalog is wired for correct plural agreement in every language that
    /// gets one, English's included, but English's *source* copy keeps the words
    /// those two pinned test suites already parse. A future decision can move
    /// English's `one` category to genuine singular ("1 second") once those
    /// parsers are updated in the same change; this item does not touch pinned
    /// test copy to make its own diff smaller.
    static func spoken(_ duration: Duration) -> String {
        let total = max(0, Int(duration.components.seconds))
        if total < 60 {
            return String(localized: "\(total) seconds", comment: "VoiceOver: a duration under one minute, spoken as a count of seconds — catalog plural entry, English's own \"one\" category intentionally reads the same as \"other\" (see the doc comment above)")
        }
        let minutes = total / 60
        let seconds = total % 60
        if minutes < 60 {
            return seconds == 0
                ? String(localized: "\(minutes) minutes", comment: "VoiceOver: a duration of whole minutes, spoken — catalog plural entry, English's own \"one\" category intentionally reads the same as \"other\" (see the doc comment above)")
                : String(localized: "\(minutes) minutes \(seconds) seconds", comment: "VoiceOver: a duration of minutes and seconds, spoken — both counts are catalog plural entries, English's own \"one\" categories intentionally read the same as \"other\" (see the doc comment above)")
        }
        return String(localized: "\(minutes / 60) hours \(minutes % 60) minutes", comment: "VoiceOver: a duration of an hour or more, spoken as hours and minutes — both counts are catalog plural entries, English's own \"one\" categories intentionally read the same as \"other\" (see the doc comment above)")
    }

    /// The spoken form of `gap` — VoiceOver reads "under a minute" as prose rather
    /// than reading a mono-caps "0 M" as a figure.
    static func spokenGap(_ duration: Duration) -> String {
        duration < .seconds(60)
            ? String(localized: "under a minute", comment: "elapsed time since the last contraction ended, when under one minute — replaces the zero a data column would otherwise show")
            : spoken(duration)
    }

    /// The CHECK flag's words, printed (SP-203). Two ways a thumb misses and two
    /// different things to do about them, so the row says which — and it says it in
    /// one place, because History and the timeline flag the same record and must not
    /// describe it differently.
    /// The printed figures come from the constants that decide the flag, each in the
    /// unit it reads best in. Decision 0032 records a measured alternative for the
    /// short bound and the harness can move it again; a literal here would leave the
    /// row claiming "UNDER 20 S" over a record flagged at a different number, which
    /// is exactly the screen-versus-arithmetic disagreement the one-number rule
    /// exists to prevent. The spoken forms below stay prose — a number spelled out in
    /// words has no honest derivation, and it is the printed row a reader checks.
    static func checkFlag(_ suspicion: Contraction.Suspicion) -> String {
        switch suspicion {
        case .tooLong:
            String(localized: "CHECK · OVER \(Int(Contraction.suspectDuration.components.seconds) / 60) MIN", comment: "the CHECK flag on a record that ran unusually long, printed in mono caps. \"CHECK\" is the flag's own word — translate it; \"MIN\" abbreviates minutes; the · separator stays")
        case .tooShort:
            String(localized: "CHECK · UNDER \(Int(Contraction.slipDuration.components.seconds)) S", comment: "the CHECK flag on a record too short to be a contraction, printed in mono caps. \"S\" abbreviates seconds; the · separator stays")
        }
    }

    /// The live form of the over-three-minute flag, for the record still on the
    /// timer (SP-204). Present tense and a consequence rather than a verdict: the
    /// record is not suspect yet, because it has not ended yet, and what she can do
    /// about it is end it.
    static func runningLongCaption() -> String {
        // The minute count is a real `Int`, interpolated directly rather than
        // pre-stringified, so it keys into the catalog as `%lld` and is wired
        // through `variations.plural` — `Contraction.suspectDuration` is a fixed
        // 3-minute constant today, so English's own `one` category is
        // unreachable in practice (same footnote as `GuidanceScreen.explainer`),
        // but the machinery is there for both a translated language's own plural
        // rule and for the constant ever changing.
        String(localized: "Still timing — over \(Int(Contraction.suspectDuration.components.seconds) / 60) minute usually means a missed end tap. Ending it now sets it aside from the averages.", comment: "caption under a contraction still running past the suspicion floor, explaining why ending it now is the recommended action — catalog plural entry on the minute-count argument")
    }

    /// The same, spoken. VoiceOver reaches this through the button's value, which is
    /// read on demand — never announced on a one-second tick.
    static func spokenRunningLong() -> String {
        String(localized: "Over three minutes. That usually means a missed end tap. Ending it now sets it aside from the averages.", comment: "VoiceOver value for the running-long contraction button, spoken form of the on-screen caption")
    }

    /// The same flag, spoken. Mono caps read aloud letter by letter; the reason is
    /// what VoiceOver should hear.
    static func spokenCheckFlag(_ suspicion: Contraction.Suspicion) -> String {
        switch suspicion {
        case .tooLong:
            String(localized: "over three minutes — check this one", comment: "VoiceOver: spoken reason a History/timeline row is flagged CHECK for running unusually long")
        case .tooShort:
            String(localized: "under twenty seconds — likely a slip, check this one", comment: "VoiceOver: spoken reason a History/timeline row is flagged CHECK for being unusually short")
        }
    }

    // MARK: Episode summaries

    /// "AVG 4:50 APART · 1:02 LONG · OVER 1 H 8 M" — History's per-episode row.
    /// Parts absent below their evidence floor rather than printed as zeros. SP-215's
    /// `recapLine` below reads the same `EpisodeSummary` through the same
    /// `minutesSeconds`/`hoursMinutes` calls rather than a second implementation of
    /// which parts are present (F-0012), even though its sentence wears a different,
    /// quieter register than this row's mono caps.
    ///
    /// **SP-206: "OVER", not "SPAN".** "SPAN" reads as a noun on first pass — a
    /// distance, a bridge — and only resolves to "how long this ran" on a second
    /// look. "OVER" is unambiguous the first time, in the same mono-caps register
    /// the other two parts already use.
    /// **Decision 0047: the band names its own window.** These figures cover the
    /// whole stretch, and they sit directly beneath pinned legs covering only the
    /// last hour — the walkthrough caught the two printing 6:51 and 6:30 against
    /// the same word, six lines apart, with nothing on screen to tell them apart.
    /// The scope prefix is the cheapest honest fix: it costs two words in a
    /// register that already carries `OVER`, and it means neither figure has to
    /// move.
    static func episodeSummaryLine(_ summary: EpisodeSummary) -> String? {
        var parts: [String] = []
        if let interval = summary.averageInterval {
            parts.append(String(localized: "THIS STRETCH · AVG \(minutesSeconds(interval)) APART", comment: "History's episode band, spacing clause. Names its own window (\"this stretch\") because the legs pinned above it cover only the last hour; \"AVG\" abbreviates average. Mono caps come from the type role, so translate as words"))
        }
        if let duration = summary.averageDuration {
            parts.append(String(localized: "\(minutesSeconds(duration)) LONG", comment: "History's episode band, duration clause — how long the average contraction in this stretch lasted"))
        }
        // Span is absent for a lone contraction — the band disappears entirely
        // rather than printing "OVER 0 M", which would read as a measurement.
        if let span = summary.span {
            parts.append(String(localized: "OVER \(hoursMinutes(span))", comment: "History's episode band, span clause — the whole stretch's total length. \"OVER\" rather than \"SPAN\" (SP-206): it reads unambiguously the first time"))
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// **When the last stretch was** (HL-026, decision 0022 §3's rule applied to the
    /// recap). The closure card renders for any episode older than three days —
    /// including, in a later pregnancy, one from the last — and it printed count, span
    /// and averages with nothing dating any of them. Past tense is not the same as
    /// dated: "Last stretch: 14 contractions" is equally true of last Tuesday and of
    /// eleven months ago, and the reader had no way to tell without leaving the screen.
    ///
    /// The year appears only when the stretch is not from this one. Within a pregnancy
    /// that is never — printing "2026" on every recap would be noise — and across one
    /// it is the whole point, since `AUG 23` alone is exactly as ambiguous as no date.
    static func recapDate(_ date: Date, now: Date = Date(), calendar: Calendar = .current) -> String {
        let sameYear = calendar.component(.year, from: date) == calendar.component(.year, from: now)
        return sameYear
            ? date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
            : date.formatted(.dateTime.month(.abbreviated).day().year())
    }

    /// Spoken form of `recapDate` — the abbreviated month and weekday read aloud as
    /// letters otherwise, the same reason every mono-caps figure in this app carries a
    /// spoken pair (0038).
    static func spokenRecapDate(_ date: Date, now: Date = Date(), calendar: Calendar = .current) -> String {
        let sameYear = calendar.component(.year, from: date) == calendar.component(.year, from: now)
        return sameYear
            ? date.formatted(.dateTime.weekday(.wide).month(.wide).day())
            : date.formatted(.dateTime.month(.wide).day().year())
    }

    /// The spoken counterpart to `episodeSummaryLine` (HL-023, F-0042). Its printed
    /// form is mono-caps instrument vocabulary — `THIS STRETCH · AVG 6:51 APART ·
    /// 1:02 LONG · OVER 1 H 15 M` — which VoiceOver reads as letters: "A V G",
    /// "H", "M". Every sibling figure in this app has carried a spoken pair since
    /// decision 0038; this line was the one that did not, and it is the line its
    /// own render site calls "the line a provider call reads from".
    ///
    /// Same scope word as the printed form (decision 0047): these figures cover the
    /// whole stretch, and the legs pinned above them cover the last hour.
    static func spokenEpisodeSummaryLine(_ summary: EpisodeSummary) -> String? {
        var clauses: [String] = []
        if let interval = summary.averageInterval {
            clauses.append(String(localized: "averaging \(spoken(interval)) apart", comment: "VoiceOver: History band clause — the whole stretch's average interval"))
        }
        if let duration = summary.averageDuration {
            clauses.append(String(localized: "lasting \(spoken(duration))", comment: "VoiceOver: History band clause — the whole stretch's average contraction duration"))
        }
        if let span = summary.span {
            clauses.append(String(localized: "over \(spoken(span))", comment: "VoiceOver: History band clause — the whole stretch's total span"))
        }
        guard !clauses.isEmpty else { return nil }
        return String(localized: "This stretch: \(clauses.joined(separator: ", ")).", comment: "VoiceOver: the History episode band, naming that its figures cover the whole stretch rather than the last hour")
    }

    /// **A clock time with its seconds** (HL-022, decision 0048) — used wherever the
    /// app prints a *gap* beside a start time, so a reader who subtracts two displayed
    /// times gets the figure the app itself printed. Without it History showed
    /// `8:22 PM` above `8:17 PM` with `+5:30` beside them: five minutes flat by the
    /// reader's arithmetic, five thirty by the app's, and the app was right only
    /// because the display had silently dropped up to fifty-nine seconds.
    ///
    /// Standalone clock readings — the header's `SINCE`, History's `FROM` — keep the
    /// minute deliberately: nothing sits beside them to check, and seconds there would
    /// be noise bought for nothing.
    ///
    /// `Date.FormatStyle`, not a hand-built string: a 24-hour locale gets its own
    /// shape, and a clock reading is one of the few figures in this app that is
    /// *supposed* to be locale-shaped (HL-007's line).
    static func clockTimeWithSeconds(_ date: Date) -> String {
        date.formatted(.dateTime.hour().minute().second())
    }

    /// SP-215's recap sentence — "Last stretch: 14 contractions over 1 H 8 M,
    /// averaging 5:00 apart, lasting 1:02." The quiet acknowledgment the timer
    /// screen shows in place of the short "last contraction ended … ago" line once
    /// `EpisodeClosure.isConcluded` says the stretch reads as over.
    ///
    /// `count` is a raw fact, exempt from every floor below it — the same way
    /// `CallSummary`'s trailing count needs none — so this always has at least
    /// something to say. `span`, then the interval and duration clauses, are
    /// omitted together with whichever `EpisodeSummary` field backs them, never
    /// printed as a dash mid-sentence: a spoken-register line reads a stumble
    /// where a dash reads as data.
    static func recapLine(_ summary: EpisodeSummary, startedAt: Date? = nil) -> String {
        // **HL-007's line, drawn here.** `head` used to be built with Swift `+=`,
        // gluing two independently-resolved sentences together — the actual
        // concatenation this item exists to remove, since a language whose
        // "over N" clause has to move *before* the count (rather than after it)
        // had no way to say so. It is now one of two complete catalog sentences,
        // chosen by which the engine says is there — the same shape every other
        // branch in this file already used for its outer wrap, just applied one
        // level in. `clauses.joined(separator: ", ")` below is untouched: each
        // clause is already its own complete catalog phrase, and joining a
        // variable-length list of complete phrases with a plain separator (never
        // reordering or truncating any one of them) is the shape CLAUDE.md's own
        // CallSummary guidance sanctions — "each clause... become translatable
        // units with positions." (`Foundation.ListFormatStyle` was considered and
        // rejected here: every list type it offers inserts a localized
        // conjunction — "X, Y, and Z" — which is not this sentence's punctuation
        // and would silently change the shipped English text the pixel-diff pins.)
        // The date leads (HL-026): it dates every figure that follows before the
        // reader reaches one, which is decision 0022 §3's rule — nothing in the
        // present tense without something dating it — applied to a card that can be
        // showing a stretch from a previous pregnancy.
        let when = startedAt.map { recapDate($0) }
        let head: String = switch (when, summary.span) {
        case let (.some(when), .some(span)):
            String(localized: "Last stretch, \(when): \(contractionCount(summary.count)) over \(hoursMinutes(span))", comment: "opening clause of the post-episode recap line, naming when the stretch was, how many contractions were recorded, and its total span")
        case let (.some(when), .none):
            String(localized: "Last stretch, \(when): \(contractionCount(summary.count))", comment: "opening clause of the post-episode recap line, naming when the stretch was and how many contractions were recorded, when its total span is not yet known")
        case let (.none, .some(span)):
            String(localized: "Last stretch: \(contractionCount(summary.count)) over \(hoursMinutes(span))", comment: "opening clause of the quiet post-episode recap line, naming how many contractions were recorded and the episode's total span")
        case (.none, .none):
            String(localized: "Last stretch: \(contractionCount(summary.count))", comment: "opening clause of the quiet post-episode recap line, naming how many contractions were recorded, when the episode's total span is not yet known")
        }
        var clauses: [String] = []
        if let interval = summary.averageInterval {
            clauses.append(String(localized: "averaging \(minutesSeconds(interval)) apart", comment: "recap line clause naming the average interval between contractions"))
        }
        if let duration = summary.averageDuration {
            clauses.append(String(localized: "lasting \(minutesSeconds(duration))", comment: "recap line clause naming the average contraction duration"))
        }
        return clauses.isEmpty
            ? String(localized: "\(head).", comment: "recap line terminated with a period when no averaging/lasting clauses follow")
            : String(localized: "\(head), \(clauses.joined(separator: ", ")).", comment: "recap line terminated with its averaging/lasting clauses, comma-joined")
    }

    /// The spoken form of `recapLine`, through `spoken` rather than
    /// `minutesSeconds`/`hoursMinutes` — the same printed/spoken split every other
    /// figure in this file keeps.
    static func spokenRecapLine(_ summary: EpisodeSummary, startedAt: Date? = nil) -> String {
        // Same restructuring as `recapLine` above, spoken register — see its doc
        // comment for why `head` is one of two complete catalog sentences rather
        // than two Swift-glued fragments, and why the clause join stays as-is.
        let when = startedAt.map { spokenRecapDate($0) }
        let head: String = switch (when, summary.span) {
        case let (.some(when), .some(span)):
            String(localized: "Last stretch, \(when), \(contractionCount(summary.count)) over \(spoken(span))", comment: "VoiceOver: opening clause of the spoken recap, naming when the stretch was, how many contractions there were, and the total span")
        case let (.some(when), .none):
            String(localized: "Last stretch, \(when), \(contractionCount(summary.count))", comment: "VoiceOver: opening clause of the spoken recap, naming when the stretch was and how many contractions there were")
        case let (.none, .some(span)):
            String(localized: "Last stretch, \(contractionCount(summary.count)) over \(spoken(span))", comment: "VoiceOver: opening clause of the spoken post-episode recap, naming how many contractions were recorded and the episode's total span")
        case (.none, .none):
            String(localized: "Last stretch, \(contractionCount(summary.count))", comment: "VoiceOver: opening clause of the spoken post-episode recap, naming how many contractions were recorded, when the episode's total span is not yet known")
        }
        var clauses: [String] = []
        if let interval = summary.averageInterval {
            clauses.append(String(localized: "averaging \(spoken(interval)) apart", comment: "VoiceOver: recap clause naming the average interval between contractions"))
        }
        if let duration = summary.averageDuration {
            clauses.append(String(localized: "lasting \(spoken(duration))", comment: "VoiceOver: recap clause naming the average contraction duration"))
        }
        return clauses.isEmpty
            ? String(localized: "\(head).", comment: "VoiceOver: recap terminated with a period when no averaging/lasting clauses follow")
            : String(localized: "\(head), \(clauses.joined(separator: ", ")).", comment: "VoiceOver: recap terminated with its averaging/lasting clauses, comma-joined")
    }

    /// A count of contractions, correctly declined. `count` is a real `Int`
    /// interpolated directly, so this keys into the catalog as `%lld contraction`
    /// and resolves through `variations.plural` — `one`/`other` in English
    /// ("1 contraction" / "14 contractions", the same words the old ternary
    /// produced, now a translator's plural rule rather than Swift's), and
    /// whatever categories a translated language's own CLDR plural rule needs.
    private static func contractionCount(_ count: Int) -> String {
        String(localized: "\(count) contraction", comment: "a count of contractions, embedded in a recap sentence — catalog plural entry")
    }

    // MARK: Trend (decision 0043)

    /// "Averaging 5:40 apart — closer than an hour ago (was 7:10)." split into the
    /// three pieces History colours: the direction phrase in the middle carries
    /// `Palette.tintText` (closer) or `Palette.easingText` (farther) — words carry the
    /// meaning, colour only seconds it (0043 §4), so `prefix`/`suffix` stay in the
    /// row's own ink whatever the direction is.
    struct TrendCaption {
        let prefix: String
        let direction: String
        let suffix: String
        let spokenForm: String
    }

    /// Builds the three pieces above from `LaborTrend`'s engine truth — the two
    /// bound figures through the same `minutesSeconds`/`spoken` this file uses
    /// everywhere else, never a second rendering of a duration.
    static func trendCaption(_ trend: LaborTrend) -> TrendCaption {
        // **HL-007's boundary, drawn here — a deliberate exception, not an
        // oversight.** `prefix`/`direction`/`suffix` stay three separate catalog
        // phrases rather than one sentence with positional arguments, because
        // decision 0043 §4 requires the direction clause to carry its own SwiftUI
        // colour (`Palette.tintText`/`Palette.easingText`) independent of the ink around
        // it — three `Text` runs is the only way to paint one word of a sentence
        // a different colour, and a single format string collapses back to one
        // `Text` the instant it is rendered. Each piece is still its own complete,
        // independently-translatable catalog entry (never a mid-word fragment),
        // and `spokenForm` below — read by VoiceOver, which has no colour to
        // carry — composes all three into one real catalog sentence with
        // positional arguments, exactly the shape this item asks for everywhere
        // coloring does not force three pieces apart.
        let directionPhrase = trend.direction == .closer
            ? String(localized: "closer than an hour ago", comment: "History trend caption: contractions are spacing closer together than an hour ago")
            : String(localized: "farther apart than an hour ago", comment: "History trend caption: contractions are spacing farther apart than an hour ago")
        return TrendCaption(
            prefix: String(localized: "Averaging \(minutesSeconds(trend.current)) apart — ", comment: "History trend caption, opening clause naming the current average interval, printed register"),
            direction: directionPhrase,
            suffix: String(localized: " (was \(minutesSeconds(trend.previous))).", comment: "History trend caption, closing clause naming the interval an hour ago, printed register"),
            spokenForm: String(localized: "Averaging \(spoken(trend.current)) apart, \(directionPhrase) — was \(spoken(trend.previous)).", comment: "VoiceOver: full spoken form of the History trend caption, direction phrase already resolved to English prose")
        )
    }

    /// Builds the same three coloured pieces from `StretchComparison` (decision 0050) —
    /// this stretch against the one before it, where `trendCaption` above tells this
    /// hour against the last one.
    ///
    /// Two things differ from its sibling, both from the decision rather than from
    /// taste. **The scope word is carried explicitly** ("your last stretch", dated),
    /// because History now prints three differently-scoped figures and 0047's rule is
    /// that each says which one it is. And **there is a steady phrase**: inside the
    /// one-sixth band the trend caption does not render at all, while this one says
    /// *about the same* — for the reader on the third night of prodromal labor that is
    /// the answer, not the absence of one (§4).
    ///
    /// The sentence states two measurements and stops. No clause follows from them:
    /// "closer together than your last stretch, so things are moving" is prognosis, and
    /// decisions 0041 and 0049 both refuse it.
    static func stretchComparisonCaption(
        _ comparison: StretchComparison, now: Date = Date()
    ) -> TrendCaption {
        // Three catalog phrases rather than one sentence, for the reason `trendCaption`
        // records at length: the direction clause carries its own colour, and a single
        // format string collapses to one `Text` that cannot be painted in two inks.
        // Each remains an independently-translatable whole phrase.
        let directionPhrase: String = switch comparison.direction {
        case .closer:
            String(localized: "closer together than your last stretch", comment: "History stretch-comparison caption: this stretch's contractions are spacing closer together than the previous stretch's")
        case .fartherApart:
            String(localized: "farther apart than your last stretch", comment: "History stretch-comparison caption: this stretch's contractions are spacing farther apart than the previous stretch's")
        case .aboutTheSame:
            String(localized: "about the same as your last stretch", comment: "History stretch-comparison caption: this stretch is spacing much like the previous one — decision 0050's steady reading, which is an answer rather than the absence of one and must never be omitted the way the hourly trend's steady state is")
        }
        let when = recapDate(comparison.previousStartedAt, now: now)
        let spokenWhen = spokenRecapDate(comparison.previousStartedAt, now: now)
        return TrendCaption(
            prefix: String(localized: "This stretch is ", comment: "History stretch-comparison caption, opening clause naming the scope being described, printed register"),
            direction: directionPhrase,
            suffix: String(localized: " — \(minutesSeconds(comparison.current)) apart against \(minutesSeconds(comparison.previous)) on \(when).", comment: "History stretch-comparison caption, closing clause naming both whole-stretch averages and the date of the earlier one, printed register"),
            spokenForm: String(localized: "This stretch is \(directionPhrase), \(spoken(comparison.current)) apart against \(spoken(comparison.previous)) on \(spokenWhen).", comment: "VoiceOver: full spoken form of the History stretch-comparison caption, direction phrase already resolved to English prose")
        )
    }
}
