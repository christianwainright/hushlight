import Foundation

/// SP-206: the triage nurse asks in a known order — how far apart, how long, since
/// when, how many — and the answers used to be scattered across the readout, a
/// header that scrolls away, and History's jargon line. `CallSummary` composes them
/// into one sentence meant to be **read aloud**, not read as data: "Contractions
/// every 5:00 on average (ranging 4:20–5:40), lasting about 1:02, since 6:17 PM —
/// 14 so far."
public struct CallSummary: Equatable, Sendable {
    /// The whole sentence, printed and spoken alike — plain prose, no mono-caps
    /// abbreviation, so VoiceOver reads it the way a person would say it over the
    /// phone.
    public let text: String
}

extension PatternAnalysis {
    /// Composes `CallSummary` from one episode (as `episodes(_:)` groups them —
    /// completed and running records both). Pure and window-free, the same stance
    /// `summary(of:)` takes: a call script judges the whole stretch, not the last
    /// hour.
    ///
    /// **Where this lives, and why.** `LaborFormat` — the app's one place every
    /// figure is rendered — lives in the app target, not here: LaborKit is
    /// deliberately dependency-free (decision 0018) and cannot import it, and a
    /// script sentence has to be asserted against literal text in package tests,
    /// which only a LaborKit test target can do without pulling SwiftUI in to
    /// inspect a string. So the sentence is composed *and* rendered here, with its
    /// own minimal formatting (`CallSummaryFormat`, below) rather than in the app
    /// from LaborKit-provided figures.
    ///
    /// That is a second, tiny *implementation* of "seconds as mm:ss" — not a second
    /// *derivation* of any figure the sentence quotes. Every quantity this function
    /// prints (`EpisodeSummary`'s own average, range, and duration; `episode.first`'s
    /// start; `episode.count`) is read exactly once, from the same functions the
    /// live readout and History already call — `summary(of:)`, which in turn rests
    /// on `startToStartIntervals` and `interval(from:to:)`, the one definition of a
    /// start-to-start gap this whole engine agrees on. Two mm:ss formatters
    /// producing "4:50" for the same `Duration` cannot disagree the way two
    /// *derivations* of an average could (F-0012's actual lesson); promoting
    /// `LaborFormat`'s handful of one-line formatters into a shared, dependency-free
    /// module is a real option, but a wider refactor than this item — it touches
    /// every screen `LaborFormat` already serves — so it stays a noted tradeoff
    /// rather than done here.
    ///
    /// **The floors.** Every clause reads through `EpisodeSummary`'s own evidence
    /// floors, so a figure this sentence has no business claiming is *omitted*, not
    /// dashed mid-sentence and never zeroed — a spoken script with a dash in it
    /// reads as a stumble, and omission is how a person actually talks. `since` and
    /// the trailing count are raw facts, exempt from the floors above them the same
    /// way the timer header's own `SINCE` is (decision 0022 §3): a card that cannot
    /// yet say how far apart or how long can still always say since when and how
    /// many.
    /// `locale` defaults to the device's own — every real call site wants that,
    /// and none has ever had to say so. It exists as a parameter at all for
    /// HL-007's own AC: `LaborKitTests`' locale-format suite passes `ar`/`hi`
    /// explicitly to prove the figures below never change *value* under a
    /// locale that spells them differently, without switching this whole test
    /// process's locale (which `xcodebuild test` has no per-test way to do) or
    /// touching a single call site outside that suite.
    public static func callSummary(of episode: [Contraction], locale: Locale = .autoupdatingCurrent) -> CallSummary? {
        let ordered = episode.sorted { $0.startedAt < $1.startedAt }
        guard let first = ordered.first, let summary = summary(of: ordered) else {
            return nil
        }

        var clauses: [String] = []

        // The interval clause carries the range beside the mean (decision 0024):
        // frequency is a share, not a mean, and the range is what keeps a printed
        // average honest about a bimodal pattern the mean alone would hide.
        // `averageInterval` and `intervalRange` share one floor and are nil
        // together below it, so this clause is whole or absent — never half of it
        // standing in for the other.
        //
        // **HL-007's line, drawn here.** Which clauses appear stays engine truth,
        // decided in Swift by the `if let`s below (decision-quality reason:
        // `EpisodeSummary`'s own evidence floors are what gate each one, and no
        // catalog can second-guess a floor). Each clause is its own complete,
        // independently-translatable catalog phrase — never a fragment a Swift
        // `+` has to complete — and `clauses.joined(separator: ", ")` only ever
        // combines whole phrases in the fixed order a nurse's own script asks
        // them in (how far apart, how long, since when), never reorders or
        // truncates one. The sentence *frame* around that joined list is one
        // catalog format string with the joined clauses and the trailing count as
        // its two positional arguments (below, after every clause is collected) —
        // not, as it was, three independently-localized pieces (an opener, the
        // joined clauses, a closer) glued together with Swift `+`.
        if let interval = summary.averageInterval, let range = summary.intervalRange {
            // A flat range says nothing the mean did not — "every 5:00 (ranging
            // 5:00–5:00)" reads as a stumble in a sentence meant to be spoken.
            // The parenthesis earns its place only when the spread is real, which
            // is exactly when 0024 needs it there keeping the mean honest.
            if range.lowerBound == range.upperBound {
                clauses.append(String(
                    localized: "every \(CallSummaryFormat.minutesSeconds(interval)) on average",
                    bundle: .module,
                    locale: locale,
                    comment: "call-summary clause: the average interval between contractions, spoken aloud over the phone"
                ))
            } else {
                clauses.append(String(
                    localized: "every \(CallSummaryFormat.minutesSeconds(interval)) on average (ranging \(CallSummaryFormat.minutesSeconds(range.lowerBound))–\(CallSummaryFormat.minutesSeconds(range.upperBound)))",
                    bundle: .module,
                    locale: locale,
                    comment: "call-summary clause: the average interval plus its range, spoken aloud over the phone, when the spread is real (not a flat range)"
                ))
            }
        }

        if let duration = summary.averageDuration {
            clauses.append(String(
                localized: "lasting about \(CallSummaryFormat.minutesSeconds(duration))",
                bundle: .module,
                locale: locale,
                comment: "call-summary clause: the average contraction duration, spoken aloud over the phone"
            ))
        }

        // A raw fact — always sayable, evidence floor or none.
        clauses.append(String(
            localized: "since \(CallSummaryFormat.timeOfDay(first.startedAt, locale: locale))",
            bundle: .module,
            locale: locale,
            comment: "call-summary clause: the clock time the episode began, spoken aloud over the phone"
        ))

        // One frame, two positional arguments: the comma-joined clauses (still in
        // the fixed order they were collected above — how far apart, how long,
        // since when, all raw material a translator can move relative to *each
        // other* only by moving whole clauses, which nothing here forbids them
        // from wanting the freedom to do; that freedom is the one this specific
        // join does not buy, and is the documented limit noted at the top of this
        // function) and the trailing count, a raw fact exempt from every
        // evidence floor above it — `summary.count` is a real `Int`, interpolated
        // directly, so it keys as `%lld` rather than the dead `%@` the old
        // hand-authored `closer` entry carried (that entry never matched the
        // runtime key it was hand-typed against; this fixes it as a side effect).
        return CallSummary(text: String(
            localized: "Contractions \(clauses.joined(separator: ", ")) — \(summary.count) so far.",
            bundle: .module,
            locale: locale,
            comment: "call-summary sentence frame: the comma-joined clauses (spacing/duration/since, whichever cleared their own evidence floor), followed by a raw count of contractions in the episode"
        ))
    }
}

/// The minimal renderings `callSummary(of:)` needs, kept private to this file. Not
/// `LaborFormat` — see that function's doc comment for why a package with zero
/// dependencies cannot reach the app target's copy.
private enum CallSummaryFormat {
    /// "4:50" — the exact shape `LaborFormat.minutesSeconds` prints, floored at
    /// zero for the same reason: a duration reaching here has already cleared an
    /// evidence floor, but the floor-at-zero guard costs nothing to repeat and a
    /// negative figure is never an honest one to print in a sentence read aloud.
    ///
    /// **HL-007's instrument-vocabulary line, drawn here.** No `locale` parameter,
    /// deliberately: `m:ss` built from `"\(...)"` and `String(format: "%02d", …)`
    /// is this app's own notation — the mm:ss numerals decisions 0022–0026 pin —
    /// not prose, and CLAUDE.md's line for this item is explicit that instrument
    /// vocabulary stays as-is regardless of locale (bidi/script questions are
    /// HL-009's). `LocaleFormatTests` asserts this renders identically under
    /// en/ar/hi: the whole point of a hand-built ASCII format is that no locale
    /// can touch it.
    static func minutesSeconds(_ duration: Duration) -> String {
        let total = max(0, Int(duration.components.seconds))
        return "\(total / 60):" + String(format: "%02d", total % 60)
    }

    /// "6:17 PM" — the device's own short time format, unmodified: this sentence
    /// is prose, not a mono-caps header, so it takes the same casing a person
    /// would write by hand rather than History's row uppercasing. `locale`
    /// threads through from `callSummary(of:locale:)` so a test can ask for
    /// Eastern Arabic digits (`ar`) or Devanagari ones (`hi`) here specifically —
    /// this is the one figure in the sentence that is *supposed* to take the
    /// locale's own digits, unlike `minutesSeconds` below, which is this
    /// sentence's own instrument vocabulary and stays ASCII on purpose (see its
    /// own doc comment).
    static func timeOfDay(_ date: Date, locale: Locale) -> String {
        date.formatted(Date.FormatStyle(date: .omitted, time: .shortened, locale: locale))
    }
}
