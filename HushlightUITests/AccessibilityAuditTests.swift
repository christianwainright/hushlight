import UIKit
import XCTest

/// The contraction timer's accessibility audit — Apple's own, run by the system on
/// the real element tree, over the seven states this app actually has.
///
/// Same instrument as the Setpoint suite once used, deliberately stricter
/// in three ways, because this is the app that ships first and the one someone uses at
/// 3am with one thumb:
///
/// 1. **Zero suppressions.** The issue handler returns `false` for everything. The
///    suite app carries one accepted category (Dynamic Type, decision 0015) against a
///    design gallery of display roles that have no matching text style; this app has
///    no such role and therefore no such excuse. If something fires here it is fixed,
///    or it is written up as a finding — it is not excused inside the test that was
///    supposed to catch it.
/// 2. **Categories named explicitly, never `.all`.** `.all` is `~0` — every bit set,
///    including bits Apple has not defined yet. A toolchain bump would silently change
///    what this gate means, in whichever direction the new audit happens to point, and
///    nobody would review the change because nothing in the repository would have
///    moved. The seven names below were checked against `XCUIAccessibilityAuditTypes.h`
///    in the pinned SDK before being relied on.
/// 3. **The content size is asserted, not assumed.** A test process cannot set the
///    simulator's content size — `xcrun simctl ui … content_size` does, from the host —
///    so a UI stage that merely *believes* it is running at AX5 is one stale simulator
///    away from a false green. Every audit prints `A11Y SIZE:` with the category the
///    runner actually observes, and `scripts/labor-sim.sh` fails the leg unless that
///    line names the size it set. Three UI stages in this harness have now produced a
///    false green (F-0030 and its two predecessors); an affirmative line is the only
///    thing that has ever caught one.
///
/// **Scrolled as well as at rest.** `TimerScreen` mounts its button bar with
/// `.safeAreaInset(edge: .bottom)`, which by design lets the readout scroll *underneath*
/// it. The suite app answers the resulting contrast findings with a positional
/// suppression (any static text inside the bottom 180 pt is presumed occluded). That
/// trade is not made here: the timer's states are audited at rest and again scrolled to
/// the end, so content that would have been under the bar is genuinely clear of it when
/// it is judged. Removing the occlusion beats removing the finding — and unlike a
/// positional filter, it cannot hide a control that really does fail down there.
@MainActor
final class AccessibilityAuditTests: XCTestCase {
    override func setUp() {
        // Every state reports every issue it has; stopping at the first would turn a
        // seven-state gate into a one-state one on the first bad day.
        continueAfterFailure = true
    }

    /// Same shape as `ContractionMechanicsTests.tearDown`, and for the same Swift 6
    /// reason: `XCTestCase.tearDown()` is nonisolated, so a plain override in a
    /// `@MainActor` class is nonisolated too and touching `XCUIApplication` from it is
    /// a data race. The suite app's audit gets away with a plain override only because
    /// its teardown drives nothing.
    override func tearDown() async throws {
        await MainActor.run {
            let cleanup = XCUIApplication()
            cleanup.launchArguments = ["-uitesting", "-seedLaborWipe"]
            cleanup.launch()
            cleanup.terminate()
        }
        try await super.tearDown()
    }

    // MARK: - The audit

    /// The categories this gate covers, named one by one.
    ///
    /// Verified against `XCUIAccessibilityAuditTypes.h` in the pinned SDK
    /// (`XCUIAccessibilityAuditTypeContrast` … `XCUIAccessibilityAuditTypeTrait`); the
    /// last three are iOS-family only, which is fine — this bundle has no other
    /// destination.
    /// `.dynamicType` is **not** among them, and this is the one place in this gate
    /// where something is left out. It is not a suppression in the sense the rest of
    /// this file argues against — a suppression hides a finding the tool got right.
    /// This category is measurably wrong on this toolchain, and the exclusion is
    /// printed in the log line every run rather than buried in an `accepted` set.
    ///
    /// The evidence, three eliminations and one proof (decision 0027, F-0032):
    /// removing `.kerning`, dropping `.weight()` from a text-style font, and adding
    /// `.accessibilityShowsLargeContentViewer()` each changed nothing. Then the
    /// decisive case — it flags `"Tap when it begins"`, which is `.font(.prose)`,
    /// plain `Font.body`, measured at 226 × 126 pt at AX5. A stock system text style
    /// cannot be a non-scaling font, so a finding that says it is has told us
    /// something about the audit rather than about the app.
    ///
    /// It goes back in the moment a toolchain stops reporting that, and the gate has
    /// `.textClipped` — which catches the failure `.dynamicType` is supposed to
    /// predict — plus `LayoutInvariantTests`, which asserts the reflow directly.
    /// **`.dynamicType` is absent, and the reason belongs here rather than only in a
    /// findings file** (F-0032, SP-195). It reports elements as unable to change font
    /// size that measurably do: re-measured 2026-09-05 against current code,
    /// `SectionHeader`'s "YOUR GUIDELINE" is flagged while growing **25.8 pt → 60.5 pt**
    /// between the default size and AX5 — a 2.34x scale the audit says is impossible.
    ///
    /// Both element classes it still fires on are composed or UIKit-hosted nodes: a
    /// `.accessibilityElement(children: .combine)`d `SectionHeader`, and the toolbar's
    /// `History` item. The timer's own plain-`Text` section label is never flagged in
    /// any state, which is the control. Decision 0058 accepts the exclusion; the
    /// category is re-run on demand by `DynamicTypeAuditDiagnostics` rather than
    /// suppressed inside this gate, so the evidence stays reproducible instead of
    /// becoming a comment nobody can check.
    private static let baseAuditTypes: XCUIAccessibilityAuditType = [
        .elementDetection,
        .hitRegion,
        .sufficientElementDescription,
        .textClipped,
        .trait,
    ]

    /// `.contrast` is added **only below an accessibility size**, and the decision is
    /// taken from the size the runner observes rather than handed in by the script.
    ///
    /// Contrast is a small-text problem: WCAG's 4.5:1 bar applies under 18 pt and
    /// relaxes to 3:1 above it, so an accessibility-size run can only ever re-judge a
    /// subset of the default-size run's elements against the easier bar. Running it at
    /// AX5 would add minutes and no coverage. Deriving it here rather than from a flag
    /// means the two legs cannot desync: there is no channel between the script and
    /// this decision to go stale, which is the same failure mode the `A11Y SIZE:`
    /// assertion exists to catch on the other side.
    private static var auditTypes: XCUIAccessibilityAuditType {
        RunnerContentSize.category.isAccessibilityCategory
            ? baseAuditTypes
            : baseAuditTypes.union(.contrast)
    }

    /// Every audit in this file runs at whatever content size the *host* left on the
    /// device, so every audit says which one that was — and which categories that size
    /// selected.
    private func announceContentSize() {
        print("""
            A11Y SIZE: \(RunnerContentSize.category.rawValue) \
            (source: \(RunnerContentSize.source), categories: \(Self.categoryName(Self.auditTypes)))
            """)
    }

    private func audit(
        _ state: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        var findings = 0
        try app.performAccessibilityAudit(for: Self.auditTypes) { issue in
            findings += 1
            let element = issue.element?.debugDescription ?? "unknown element"
            let firstLine = element.split(separator: "\n").first.map(String.init) ?? element
            // The category comes off `issue.auditType`, not out of
            // `compactDescription`. Substring-matching Apple's prose is how the suite
            // app's suppression set came to be keyed on sentences ("Contrast nearly
            // passed") that only ever held by convention — a reworded string would
            // have changed which findings were suppressed with nothing in the diff.
            print("A11Y[\(state)] \(Self.categoryName(issue.auditType)) — \(issue.compactDescription) — \(firstLine)")
            // The detail is what makes a finding actionable — `compactDescription` says
            // "Dynamic Type font sizes are partially unsupported" for a dozen different
            // causes, and the triage cost of not printing this is one full simulator
            // run per question asked. One line, flattened, so grep still works.
            print("A11Y[\(state)]   detail: \(issue.detailedDescription.replacingOccurrences(of: "\n", with: " · "))")
            return false
        }
        // Machine-readable, per state: `Executed N tests` proves the bundle ran, this
        // proves each state was actually walked.
        print("A11Y AUDITED: \(state) findings=\(findings)")
    }

    /// `XCUIAccessibilityAuditType` is an option set; one issue carries exactly one
    /// bit. Anything unrecognised prints its raw value rather than "unknown", so a
    /// category added by a future SDK is identifiable from the log alone.
    private static func categoryName(_ type: XCUIAccessibilityAuditType) -> String {
        let known: [(XCUIAccessibilityAuditType, String)] = [
            (.contrast, "contrast"),
            (.elementDetection, "elementDetection"),
            (.hitRegion, "hitRegion"),
            (.sufficientElementDescription, "sufficientElementDescription"),
            (.dynamicType, "dynamicType"),
            (.textClipped, "textClipped"),
            (.trait, "trait"),
        ]
        let names = known.filter { type.contains($0.0) }.map(\.1)
        return names.isEmpty ? "auditType(\(type.rawValue))" : names.joined(separator: "+")
    }

    // MARK: - Launching and scrolling

    private func launch(_ args: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = args
        app.launch()
        XCTAssertTrue(
            app.wait(for: .runningForeground, timeout: 15),
            "App never reached the foreground with launch arguments \(args)"
        )
        // The timer is up once its one button is; every state below is reached from
        // there, so this is the single readiness gate.
        XCTAssertTrue(
            app.buttons["Start contraction"].waitForExistence(timeout: 10)
                || app.buttons["End contraction"].waitForExistence(timeout: 10),
            "Timer button never appeared with launch arguments \(args)"
        )
        return app
    }

    /// Drags the readout clear of the pinned bottom bar. Fixed count rather than a
    /// "until it stops moving" loop: a scroll view already at its end absorbs a swipe
    /// harmlessly, so over-swiping costs a second and under-swiping costs the whole
    /// point of the second audit.
    private func scrollToEnd(_ app: XCUIApplication) {
        let scroll = app.scrollViews.firstMatch
        guard scroll.exists else { return }
        for _ in 0..<6 { scroll.swipeUp() }
    }

    /// The two-position audit the timer states get: as the screen arrives, and again
    /// with the content dragged out from under the bar.
    private func auditAtRestAndScrolled(_ state: String, _ app: XCUIApplication) throws {
        try audit(state, in: app)
        scrollToEnd(app)
        try audit("\(state)/scrolled", in: app)
    }

    // MARK: - The seven states

    /// The instrument at rest — em-dash columns, ghost timeline, onboarding prose.
    func testEmptyStateIsAccessible() throws {
        announceContentSize()
        try auditAtRestAndScrolled("empty", launch(["-uitesting", "-seedLaborWipe"]))
    }

    /// Mid-contraction: the disc reads elapsed, the newest timeline node is live, and
    /// the button's label has flipped to the action it now performs.
    func testRunningContractionIsAccessible() throws {
        announceContentSize()
        let app = launch(["-uitesting", "-seedLaborWipe"])
        app.buttons["Start contraction"].tap()
        XCTAssertTrue(
            app.buttons["End contraction"].waitForExistence(timeout: 10),
            "Button never flipped to End — the running state was never reached"
        )
        try auditAtRestAndScrolled("running", app)
    }

    /// The met verdict: the banner leads, the timeline recedes below it.
    func testMetVerdictIsAccessible() throws {
        announceContentSize()
        let app = launch(["-uitesting", "-seedLabor511"])
        XCTAssertTrue(
            app.descendants(matching: .any)
                .matching(NSPredicate(format: "label CONTAINS %@", "guideline many providers use"))
                .firstMatch.waitForExistence(timeout: 10),
            "-seedLabor511 did not produce the met banner — the state under audit is not the one named"
        )
        try auditAtRestAndScrolled("met", app)
    }

    /// A strong but young pattern: frequency and duration met, sustained not, so the
    /// partial line renders and the banner must not.
    func testPartialPatternIsAccessible() throws {
        announceContentSize()
        let app = launch(["-uitesting", "-seedLaborYoung"])
        XCTAssertTrue(
            app.descendants(matching: .any)
                .matching(NSPredicate(format: "label BEGINSWITH %@", "Not at 5-1-1 yet"))
                .firstMatch.waitForExistence(timeout: 10),
            "-seedLaborYoung did not produce the partial line — the state under audit is not the one named"
        )
        try auditAtRestAndScrolled("partial", app)
    }

    /// The forgotten timer (SP-204), at the size where its sentence is longest.
    /// A record still running past three minutes moves that sentence out of the
    /// pinned bar and into the scroll content, and the audit is the reason it moved:
    /// left in the bar it truncated at "from the avera…".
    func testForgottenTimerIsAccessible() throws {
        announceContentSize()
        let app = launch(["-uitesting", "-laborScenario", try Self.scenarioPath("forgotten-timer")])
        XCTAssertTrue(
            app.descendants(matching: .any)
                .matching(NSPredicate(format: "label CONTAINS %@", "missed end tap"))
                .firstMatch.waitForExistence(timeout: 10),
            "the seeded 25-minute record produced no missed-end-tap notice"
        )
        try auditAtRestAndScrolled("forgottenTimer", app)
    }

    /// Copies a bundled snapshot somewhere the app can read it, the same way
    /// `ContractionMechanicsTests` does — a test bundle resource lives inside the
    /// runner, and `-laborScenario` hands the app a plain path.
    static func scenarioPath(_ resource: String) throws -> String {
        let bundle = Bundle(for: AccessibilityAuditTests.self)
        let url = try XCTUnwrap(
            bundle.url(forResource: resource, withExtension: "json"),
            "Missing test bundle resource \(resource).json — expected under HushlightUITests/Resources"
        )
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(resource)-\(UUID().uuidString).json")
        try FileManager.default.copyItem(at: url, to: destination)
        return destination.path
    }

    /// The slip strip (SP-203): start and immediately end, which is the double tap
    /// the walkthrough caught. The strip is the only transient element on this
    /// screen and it appears directly above the one control that matters, so a
    /// contrast or hit-target finding on it lands in the worst possible place.
    func testSlipStripIsAccessible() throws {
        announceContentSize()
        let app = launch(["-uitesting", "-seedLaborWipe"])
        app.buttons["Start contraction"].tap()
        XCTAssertTrue(
            app.buttons["End contraction"].waitForExistence(timeout: 10),
            "Button never flipped to End — the slip could not be recorded"
        )
        app.buttons["End contraction"].tap()

        XCTAssertTrue(
            app.descendants(matching: .any)
                .matching(NSPredicate(format: "label CONTAINS %@", "likely a slip"))
                .firstMatch.waitForExistence(timeout: 10),
            "A contraction recorded in under a second produced no slip strip"
        )
        try audit("slip", in: app)
        XCTAssertTrue(app.buttons["Delete"].isHittable, "The strip's Delete is not reachable")
    }

    /// The met verdict with a provider number stored — the one state where the
    /// screen offers a Call button (SP-200), on both surfaces that carry it. The
    /// button is the only control on the timer besides the disc itself, and a
    /// contrast or label finding on it would land on the one tap this app exists
    /// to make possible.
    func testCallButtonIsAccessibleWhereverItAppears() throws {
        announceContentSize()
        let app = launch(["-uitesting", "-seedLabor511", "-seedProviderNumber", "5551234567"])
        let call = app.buttons["Call your provider"]
        XCTAssertTrue(
            call.waitForExistence(timeout: 10),
            "-seedProviderNumber did not put a Call button in the verdict banner"
        )
        try auditAtRestAndScrolled("met/call", app)

        let guidance = app.buttons["Guidance"]
        XCTAssertTrue(guidance.waitForExistence(timeout: 10), "Guidance toolbar link never appeared")
        guidance.tap()
        XCTAssertTrue(
            app.navigationBars.buttons.element(boundBy: 0).waitForExistence(timeout: 10),
            "Guidance never pushed"
        )
        scrollToEnd(app)
        XCTAssertTrue(
            app.buttons["Call your provider"].waitForExistence(timeout: 10),
            "The call-right-away card never offered its Call button"
        )
        try audit("guidance/call", in: app)
    }

    // The three pushed screens are reached by *navigating*, not by a launch argument
    // that would deep-link straight to them. Navigating audits the navigation bar and
    // the back button that carry the reader between screens — which is exactly the
    // furniture a launch-arg shortcut would skip, and it is furniture this app relies
    // on (`TimerScreen` sets no navigation title, so History's back button takes its
    // default text).

    func testHistoryIsAccessible() throws {
        announceContentSize()
        let app = launch(["-uitesting", "-seedLabor511"])
        let history = app.buttons["History"]
        XCTAssertTrue(history.waitForExistence(timeout: 10), "History toolbar link never appeared")
        history.tap()
        XCTAssertTrue(app.cells.firstMatch.waitForExistence(timeout: 10), "History never populated")
        try audit("history", in: app)
        scrollToEnd(app)
        try audit("history/scrolled", in: app)
    }

    func testGuidanceIsAccessible() throws {
        announceContentSize()
        let app = launch(["-uitesting", "-seedLabor511"])
        let guidance = app.buttons["Guidance"]
        XCTAssertTrue(guidance.waitForExistence(timeout: 10), "Guidance toolbar link never appeared")
        guidance.tap()
        // The back button is the arrival signal: the pushed screen owns the navigation
        // bar only once the push has landed.
        XCTAssertTrue(
            app.navigationBars.buttons.element(boundBy: 0).waitForExistence(timeout: 10),
            "Guidance never pushed"
        )
        try audit("guidance", in: app)
        scrollToEnd(app)
        try audit("guidance/scrolled", in: app)
    }

    func testHowItWorksIsAccessible() throws {
        announceContentSize()
        let app = launch(["-uitesting", "-seedLabor511"])
        let howItWorks = app.buttons["How it works"]
        XCTAssertTrue(howItWorks.waitForExistence(timeout: 10), "How it works toolbar button never appeared")
        howItWorks.tap()
        // The sheet's own dismiss button, not `app.sheets` — a SwiftUI `.sheet` with
        // `.presentationDetents([.large])` does not reliably surface as an XCTest
        // `sheet` element, and querying for one reported "never presented" over a
        // screen the audit then walked perfectly well.
        XCTAssertTrue(
            app.buttons["Got it"].waitForExistence(timeout: 10),
            "How it works sheet never presented"
        )
        try audit("howItWorks", in: app)
        scrollToEnd(app)
        try audit("howItWorks/scrolled", in: app)
    }
}

/// What content size the runner is actually living at.
///
/// Shared with `LayoutInvariantTests` on purpose: the whole value of this probe is that
/// one definition of "what size are we at" governs every stage, and a second copy would
/// be a second chance to be wrong about the one thing these tests cannot set for
/// themselves.
///
/// `UIApplication.shared` first — the runner is a real app on the simulator, so it sees
/// the device-wide setting `xcrun simctl ui … content_size` writes. `UITraitCollection.current`
/// is the fallback for the case where the application object reports `.unspecified`
/// (it can, before the runner's first window is up).
@MainActor
enum RunnerContentSize {
    static var category: UIContentSizeCategory {
        let fromApplication = UIApplication.shared.preferredContentSizeCategory
        return fromApplication == .unspecified
            ? UITraitCollection.current.preferredContentSizeCategory
            : fromApplication
    }

    static var source: String {
        UIApplication.shared.preferredContentSizeCategory == .unspecified
            ? "UITraitCollection.current"
            : "UIApplication"
    }
}
