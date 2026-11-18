import XCTest

/// HL-007's AC, the app-side half: format tests run under at least three
/// locales — en, one RTL (`ar`), one non-Latin-digit locale (`hi`, Devanagari)
/// — against the *real* compiled app, the one thing a `LaborKitTests` process
/// cannot exercise (`LaborFormat` lives in the app target; `-AppleLanguages`
/// is a launch-time, process-level switch no package test can reach — see
/// `LocaleFormatTests`' own doc comment in `Packages/LaborKit/Tests/LaborKitTests`
/// for the mechanism this file relies on and that one cannot).
///
/// **What this file checks, and why not more.** It was written while every
/// localization table in this repo was `en` only, so the note here used to say
/// nothing was translated yet. HL-008 changed that — nine locales ship now —
/// but not what this suite tests: `ar` and `hi` are *not* among them, so under
/// `-AppleLanguages (ar)` the words on screen are still English and the seam
/// below is unchanged. What genuinely varies is the OS chrome (status bar,
/// system alerts) and, for a locale whose numbering system asks for it, digit
/// glyphs in locale-formatted content. That is exactly the seam this suite guards
/// guard: the mono-caps mm:ss/H M instrument figures (decisions 0022–0026,
/// CLAUDE.md's instrument-vocabulary line) must render the identical ASCII
/// figure regardless — proven here by literally comparing the seeded 511
/// scenario's readout under three different launch locales rather than
/// asserting it as an architectural claim.
///
/// **SP-042a is closed.** This target's UI-test legs run locally now — the aborts
/// that note described were a beta-runtime/SDK mismatch, gone with the Xcode-beta
/// pin (HL-038). CI's macOS tier is a second opinion rather than the only place
/// they execute.
@MainActor
final class LocaleFormatUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = true
    }

    override func tearDown() async throws {
        await MainActor.run {
            let cleanup = XCUIApplication()
            cleanup.launchArguments = ["-uitesting", "-seedLaborWipe"]
            cleanup.launch()
            cleanup.terminate()
        }
        try await super.tearDown()
    }

    private func launch(locale: String?, language: String?) -> XCUIApplication {
        let app = XCUIApplication()
        var args = ["-uitesting", "-seedLabor511"]
        if let language { args += ["-AppleLanguages", "(\(language))"] }
        if let locale { args += ["-AppleLocale", locale] }
        app.launchArguments = args
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15), "App never reached the foreground under locale \(locale ?? "(default)")")
        return app
    }

    /// HL-009's forced-RTL launch: `-AppleTextDirection YES
    /// -NSForceRightToLeftWritingDirection YES`, the standard Apple pair for testing
    /// layout mirroring in isolation from translation — no `-AppleLanguages` change,
    /// so the strings stay the same known-English figures `assertInstrumentFiguresUnchanged`
    /// already reads, and the only variable is layout direction. Distinct from
    /// `testInstrumentFiguresAreLocaleInvariantInArabic` above, which changes the
    /// *language* (Arabic being itself RTL mirrors as a side effect of that, not as
    /// something this file isolates and asserts on).
    ///
    /// Launch arguments only, per CLAUDE.md's simulator hygiene: nothing here calls
    /// `defaults write` or otherwise touches persistent simulator state, so RTL never
    /// outlives this one process.
    private func launchForcedRTL() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-uitesting", "-seedLabor511",
            "-AppleTextDirection", "YES",
            "-NSForceRightToLeftWritingDirection", "YES",
        ]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15), "App never reached the foreground under forced RTL")
        return app
    }

    /// The seeded 511 scenario's own known figures (the same fixture
    /// `scripts/pseudo-check.sh` and `CallSummaryTests`' textbook shape both
    /// use) — asserted as literal `staticTexts` queries, which read the real
    /// `Text` content directly rather than a possibly-truncated accessibility
    /// value (`SnapshotFactAssertionTests`' own F-0030 lesson).
    private func assertInstrumentFiguresUnchanged(_ app: XCUIApplication, locale: String) {
        for figure in ["5:00", "1:02", "1 H 8 M"] {
            XCTAssertTrue(
                app.staticTexts[figure].waitForExistence(timeout: 10),
                "locale \(locale): instrument figure '\(figure)' missing or changed"
            )
        }
        // No Eastern Arabic (٠-٩) or Devanagari (०-९) digit glyph anywhere in
        // the tree — a trip-wire for the day a translated build exists and
        // some future call site accidentally drops a data numeral through
        // locale-aware number formatting instead of this file's own ASCII
        // builders (LaborFormat/CallSummaryFormat's ban on exactly that).
        let dump = app.debugDescription
        let foreignDigits = CharacterSet(charactersIn: "٠١٢٣٤٥٦٧٨٩०१२३४५६७८९")
        XCTAssertNil(
            dump.unicodeScalars.first(where: { foreignDigits.contains($0) }),
            "locale \(locale): a non-ASCII digit glyph appeared in the accessibility tree — instrument vocabulary must stay locale-invariant"
        )
    }

    func testInstrumentFiguresAreLocaleInvariantInEnglish() {
        let app = launch(locale: "en_US", language: "en")
        assertInstrumentFiguresUnchanged(app, locale: "en_US")
        app.terminate()
    }

    /// RTL.
    func testInstrumentFiguresAreLocaleInvariantInArabic() {
        let app = launch(locale: "ar_SA", language: "ar")
        assertInstrumentFiguresUnchanged(app, locale: "ar_SA")
        app.terminate()
    }

    /// Non-Latin-digit locale (Devanagari).
    func testInstrumentFiguresAreLocaleInvariantInHindi() {
        let app = launch(locale: "hi_IN", language: "hi")
        assertInstrumentFiguresUnchanged(app, locale: "hi_IN")
        app.terminate()
    }

    /// HL-009 item 4: the digit-shape guard, extended to the forced-RTL case — mm:ss
    /// on screen renders Western digits regardless of layout direction, the same
    /// invariant `assertInstrumentFiguresUnchanged` already proves per-locale.
    func testInstrumentFiguresStayASCIIUnderForcedRTL() {
        let app = launchForcedRTL()
        assertInstrumentFiguresUnchanged(app, locale: "forced-RTL")
        app.terminate()
    }

    /// HL-009 item 1/TESTS: decision 0045's ruling made concrete — the ember tape's
    /// end caps ("1 H AGO" / "NOW") keep their screen positions under forced RTL
    /// rather than swapping sides the way the rest of the mirrored screen does.
    /// `EmberTape`'s own `.environment(\.layoutDirection, .leftToRight)` (see its
    /// doc comment) is what this proves held: without it, the end-cap `HStack`
    /// would reverse its child order under RTL and "NOW" would drift to the left
    /// edge — silently disagreeing with the tocograph strip the tape imitates.
    /// Position, not accessibility-tree order, because XCUITest cannot observe
    /// VoiceOver traversal order directly — `LayoutInvariantTests`' own house
    /// convention for geometry-shaped claims a fact-string cannot express.
    func testTapeEndCapsHoldTheirAxisUnderForcedRTL() {
        let app = launchForcedRTL()

        let leadingCap = app.staticTexts["1 H AGO"]
        let trailingCap = app.staticTexts["NOW"]
        XCTAssertTrue(leadingCap.waitForExistence(timeout: 10), "tape's leading end cap '1 H AGO' never appeared under forced RTL")
        XCTAssertTrue(trailingCap.waitForExistence(timeout: 10), "tape's trailing end cap 'NOW' never appeared under forced RTL")

        // The axis is fixed (decision 0045): past on the left, NOW on the right, in
        // every locale and every layout direction — so the leading caption's frame
        // must sit to the left of the trailing caption's, exactly as it does under
        // ordinary LTR. A mirrored tape would report these in the opposite order.
        XCTAssertLessThan(
            leadingCap.frame.minX, trailingCap.frame.minX,
            "'1 H AGO' (\(leadingCap.frame)) is not left of 'NOW' (\(trailingCap.frame)) under forced RTL — "
                + "the tape's axis mirrored with the screen, which decision 0045 forbids"
        )

        app.terminate()
    }
}
