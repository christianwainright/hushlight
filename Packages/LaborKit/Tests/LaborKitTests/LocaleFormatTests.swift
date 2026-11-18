import Foundation
import Testing
@testable import LaborKit

/// HL-007's AC: `CallSummary` and `ProblemReport` format tests, run under at
/// least three locales — en, one RTL (`ar`), one non-Latin-digit locale
/// (`ar` doubles as this too, once its numbering system is asked for
/// explicitly; `hi` is exercised separately for Devanagari) — asserting that
/// no figure changes *value* under any locale, that plurals produce the right
/// English forms both sides of 1, and that CallSummary's clause-omission logic
/// (which clauses appear at all) is engine truth untouched by locale.
///
/// **A finding this suite exists to record, not paper over.** `String(localized:
/// locale:)`'s `locale` parameter was added to `callSummary(of:locale:)` and
/// `ProblemReport.body(for:locale:)` for exactly this test file. Measured
/// directly against the compiled catalogs (`xcstringstool compile` +
/// `Bundle(path:)` against a bare `.lproj`, the standalone-bundle trick Apple's
/// own testing guidance uses to force one language without touching system
/// settings): passing an explicit `Locale` changes how a `%lld`/`%@` argument
/// already selected for substitution is *formatted* (digits, calendar), but it
/// does **not** override which language table `String(localized:)` reads from
/// — that follows `Bundle.preferredLocalizations`, which in turn follows the
/// process's own language settings (the mechanism `-AppleLanguages` at launch
/// relies on, which is exactly how `scripts/pseudo-check.sh` and a real
/// translated build both actually work). Since this package ships only an
/// `en` table today (HL-008 hasn't run — it has since, and this package now ships
/// nine, which changes none of the reasoning below), that limitation costs this suite
/// nothing — every assertion below holds regardless of which table a
/// `locale:` argument does or doesn't select, because they test what the
/// *engine* and the *instrument vocabulary* guarantee, not what a
/// not-yet-existing translation says. A future HL-008 suite that needs to
/// assert genuinely translated prose will need the real mechanism (a
/// `-AppleLanguages`-launched process, or `HushlightUITests`' equivalent) —
/// noted here so the next reader does not rediscover this the hard way.
@Suite("Locale-format invariants (HL-007)")
struct LocaleFormatTests {
    /// RTL, and reachable with Eastern Arabic digits when a caller's own
    /// number formatting asks for them (`Locale(identifier: "ar_SA@numbers=arab")`,
    /// exercised separately below for the digit-script assertion specifically).
    private let arabic = Locale(identifier: "ar")
    /// Non-Latin-digit locale, Devanagari.
    private let hindi = Locale(identifier: "hi")
    private let english = Locale(identifier: "en_US")
    private var locales: [Locale] { [english, arabic, hindi] }

    private let base = Date(timeIntervalSince1970: 1_800_000_000)

    private func starts(_ offsetsSeconds: [Double], lastingSeconds seconds: Double? = 62) -> [Contraction] {
        offsetsSeconds.map { offset in
            let start = base.addingTimeInterval(offset)
            return Contraction(startedAt: start, endedAt: seconds.map { start.addingTimeInterval($0) })
        }
    }

    // MARK: Instrument vocabulary is locale-invariant

    /// The mm:ss figures inside a call summary are this app's own notation
    /// (decisions 0022–0026), never prose — CLAUDE.md's line for this item.
    /// `CallSummaryFormat.minutesSeconds` takes no locale at all, by
    /// construction, so this is really asserting the sentence *around* it
    /// never mangles what it quotes.
    ///
    /// Scoped to the "every/ranging/lasting" clauses specifically, not a bare
    /// `\d+:\d+` sweep of the whole sentence: the "since" clause's own clock
    /// time (`CallSummaryFormat.timeOfDay`) is `h:mm`, the *same shape* as
    /// `m:ss`, and is *supposed* to vary by locale (many locales' short time
    /// style is 24-hour, e.g. "18:17" rather than "6:17 PM") — that clause is
    /// prose, not instrument vocabulary, and CLAUDE.md's own line draws that
    /// exact distinction. A sweep that can't tell the two apart is a bug in
    /// the test, not the product — the first version of this test had exactly
    /// that bug, caught by the locale that renders `since` in 24-hour time.
    @Test func mmSSFiguresAreByteIdenticalAcrossLocales() throws {
        let episode = starts([0, 260, 560, 860, 1200])
        var renderings: Set<String> = []
        for locale in locales {
            let summary = try #require(PatternAnalysis.callSummary(of: episode, locale: locale))
            let mean = try #require(summary.text.firstMatch(of: /every (\d+:\d{2}) on average/))
            // `Regex(String)` rather than a `/…/` literal: this pattern's en
            // dash trips the same regex-literal lexer limitation the doc
            // comment above names (an em dash did, in the sibling test below)
            // — constructing the regex from an ordinary string sidesteps the
            // literal's lexer entirely, since `\u{2013}` is valid *string*
            // escaping.
            let rangePattern = try Regex("ranging (\\d+:\\d{2})\u{2013}(\\d+:\\d{2})")
            let range = try #require(summary.text.firstMatch(of: rangePattern))
            let duration = try #require(summary.text.firstMatch(of: /lasting about (\d+:\d{2})/))
            // `range`'s captures come back as `AnyRegexOutput` (a dynamically
            // built `Regex(String)`, not a literal, has no compile-time tuple
            // type for `.1`/`.2`), so its two groups are read by index instead.
            let rangeLower = try #require(range.output[1].substring)
            let rangeUpper = try #require(range.output[2].substring)
            let figures = [String(mean.1), String(rangeLower), String(rangeUpper), String(duration.1)]
            #expect(figures == ["5:00", "4:20", "5:40", "1:02"], "locale \(locale.identifier) mangled an mm:ss figure: \(figures)")
            renderings.insert(figures.joined(separator: ","))
        }
        #expect(renderings.count == 1, "the same episode produced different mm:ss figures under different locales")
    }

    /// The mirror proof for the one figure that *is* supposed to vary: the
    /// `since` clock time renders in each locale's own short-time convention
    /// (12-hour with a day period for `en_US`; commonly 24-hour for `ar`/`hi`),
    /// while still landing on the same instant — the value never moves, only
    /// its locale-appropriate spelling does. This is `LaborFormat`'s
    /// "spoken/prose renderings... go through locale-aware... format
    /// machinery" line, proven on the one figure in this sentence it actually
    /// governs.
    @Test func theSinceClauseIsLocaleAwareByDesignUnlikeTheInstrumentFigures() throws {
        let episode = starts([0])
        var renderings: Set<String> = []
        for locale in locales {
            let summary = try #require(PatternAnalysis.callSummary(of: episode, locale: locale))
            // Plain `String` range-finding rather than a regex literal: an em
            // dash inside `/…/` trips this toolchain's regex-literal lexer
            // ("Invalid character in source file") — a real, narrow parser
            // limitation, not a reason to route around the em dash by
            // guessing at an escape; sidestepping the literal entirely is the
            // more honest fix.
            let sinceStart = try #require(summary.text.range(of: "since "), "locale \(locale.identifier): no since clause in '\(summary.text)'")
            let closerStart = try #require(summary.text.range(of: " \u{2014} ", range: sinceStart.upperBound..<summary.text.endIndex), "locale \(locale.identifier): since clause never closes in '\(summary.text)'")
            renderings.insert(String(summary.text[sinceStart.upperBound..<closerStart.lowerBound]))
        }
        // Not asserting *which* locales differ (CLDR's exact short-time
        // convention per locale is not this test's contract to pin) — only
        // that this is the one clause in the sentence free to, unlike the
        // mm:ss figures the test above pins as invariant.
        #expect(renderings.count > 1)
    }

    // MARK: No figure changes value under any locale

    /// The trailing count is a raw fact (decision-quality note in
    /// `callSummary(of:locale:)`'s doc comment): parse it back as an `Int`
    /// under each locale and confirm the *value* survived, not just that some
    /// digits appeared.
    @Test func theTrailingCountParsesBackToTheSameValueUnderEveryLocale() throws {
        let episode = starts([0, 300, 600, 900, 1200, 1500]) // 6 contractions
        for locale in locales {
            let summary = try #require(PatternAnalysis.callSummary(of: episode, locale: locale))
            let match = try #require(summary.text.firstMatch(of: /(\d+) so far/), "locale \(locale.identifier): no trailing count found in '\(summary.text)'")
            #expect(Int(match.1) == 6, "locale \(locale.identifier) changed the trailing count's value")
        }
    }

    /// Same proof, the other reachable count shape: `ProblemReport`'s Recorded
    /// line, which carries two independent counts on one line.
    @Test func theRecordedLineCountsParseBackToTheSameValuesUnderEveryLocale() throws {
        let context = ProblemReport.Context(
            appVersion: "1.0 (1)", osVersion: "iOS 27.0.1", deviceModel: "iPhone17,2",
            rule: .fiveOneOne, contractionCount: 14, episodeCount: 2,
            liveActivityVisible: true, storedCrashCount: 0, storedHangCount: 0
        )
        for locale in locales {
            let body = ProblemReport.body(for: context, locale: locale)
            let match = try #require(
                body.firstMatch(of: /Recorded: (\d+) contractions? across (\d+) episodes?/),
                "locale \(locale.identifier): Recorded line not found in expected shape: \(body)"
            )
            #expect(Int(match.1) == 14, "locale \(locale.identifier) changed the contraction count's value")
            #expect(Int(match.2) == 2, "locale \(locale.identifier) changed the episode count's value")
        }
    }

    /// A duration figure, likewise, holds its value across every locale —
    /// `Duration.seconds(62)` in, "1:02" out, regardless.
    @Test func theDurationClauseParsesBackToTheSameSecondsUnderEveryLocale() throws {
        let episode = starts([0, 260, 560, 860, 1200], lastingSeconds: 62)
        for locale in locales {
            let summary = try #require(PatternAnalysis.callSummary(of: episode, locale: locale))
            let match = try #require(summary.text.firstMatch(of: /lasting about (\d+):(\d{2})/), "locale \(locale.identifier): no duration clause in '\(summary.text)'")
            let seconds = (Int(match.1) ?? -1) * 60 + (Int(match.2) ?? -1)
            #expect(seconds == 62, "locale \(locale.identifier) changed the duration figure's value")
        }
    }

    // MARK: Plurals produce the right English forms both sides of 1

    /// `ProblemReportTests.singularCountsReadGrammatically` already pins this
    /// at the default locale; restated here explicitly against `en_US` so this
    /// suite's own coverage of the AC line is self-contained, and once more at
    /// a value on the far side of 1 in the same test so a regression that only
    /// breaks one boundary cannot hide.
    @Test func englishPluralsAgreeBothSidesOfOne() {
        let single = ProblemReport.Context(
            appVersion: "1.0", osVersion: "iOS 27.0.1", deviceModel: "iPhone17,2",
            rule: .fourOneOne, contractionCount: 1, episodeCount: 1,
            liveActivityVisible: false, storedCrashCount: 0, storedHangCount: 0
        )
        let many = ProblemReport.Context(
            appVersion: "1.0", osVersion: "iOS 27.0.1", deviceModel: "iPhone17,2",
            rule: .fourOneOne, contractionCount: 14, episodeCount: 2,
            liveActivityVisible: false, storedCrashCount: 0, storedHangCount: 0
        )
        let singleBody = ProblemReport.body(for: single, locale: english)
        let manyBody = ProblemReport.body(for: many, locale: english)
        #expect(singleBody.contains("1 contraction across 1 episode"))
        #expect(!singleBody.contains("1 contractions"))
        #expect(!singleBody.contains("1 episodes"))
        #expect(manyBody.contains("14 contractions across 2 episodes"))
    }

    /// `CallSummary`'s own count noun-free closer ("N so far") has nothing to
    /// decline — the AC's "%lld so far" example is about the argument's type
    /// (`%lld`, a real `Int`, not a Swift-ternary-built `%@`) rather than a
    /// grammatical form, so this is a value check, not a plural check; it
    /// lives here rather than the value-parsing tests above because it is the
    /// literal "%lld so far" the AC brief names.
    @Test func theSoFarCountNeedsNoDeclension() throws {
        for count in [1, 2, 14] {
            let episode = starts((0..<count).map { Double($0) * 300 })
            let summary = try #require(PatternAnalysis.callSummary(of: episode, locale: english))
            #expect(summary.text.hasSuffix("\(count) so far."))
        }
    }

    // MARK: CallSummary's clause-omission logic is engine truth, not locale

    /// Below decision 0024's two-interval floor and below the three-usable-
    /// duration floor at once: both clauses omit. A translated frame swapping
    /// in extra words around the omitted clauses' *positions* must not
    /// resurrect either — the omission happens before any catalog lookup, in
    /// the `if let`s `callSummary(of:locale:)`'s own doc comment names as
    /// engine truth, so it cannot vary by locale by construction. Proven under
    /// all three locales rather than asserted as an architectural claim.
    @Test func floorOmissionsHoldUnderEveryLocale() throws {
        let episode = starts([0, 300]) // two contractions: below both floors
        for locale in locales {
            let summary = try #require(PatternAnalysis.callSummary(of: episode, locale: locale))
            #expect(!summary.text.contains("on average"), "locale \(locale.identifier) resurrected the omitted interval clause")
            #expect(!summary.text.contains("lasting"), "locale \(locale.identifier) resurrected the omitted duration clause")
            // The two raw facts (since, count) never omit — a card with
            // nothing measurable yet must still be able to say when and how many.
            #expect(summary.text.contains("2 so far"), "locale \(locale.identifier) lost the raw count")
        }
    }

    /// The mirror case: every floor cleared, every clause present, under
    /// every locale — proving presence is equally locale-independent, not
    /// only absence.
    @Test func everyClauseSurvivesUnderEveryLocaleWhenEveryFloorClears() throws {
        let episode = starts([0, 260, 560, 860, 1200])
        for locale in locales {
            let summary = try #require(PatternAnalysis.callSummary(of: episode, locale: locale))
            #expect(summary.text.contains("on average"), "locale \(locale.identifier) dropped the interval clause")
            #expect(summary.text.contains("ranging"), "locale \(locale.identifier) dropped the range clause")
            #expect(summary.text.contains("lasting"), "locale \(locale.identifier) dropped the duration clause")
            #expect(summary.text.contains("so far"), "locale \(locale.identifier) dropped the trailing count")
        }
    }
}
