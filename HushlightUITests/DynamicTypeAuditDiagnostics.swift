import XCTest

/// **What `.dynamicType` actually fires on, today (SP-195, F-0032).**
///
/// `AccessibilityAuditTests.baseAuditTypes` omits `.dynamicType`. The reason is real —
/// F-0032 measured a `MiniCircle` scaling 3.7x while the audit insisted its font could
/// not change size, and eliminated tracking, weight and `accessibilityShowsLargeContentViewer`
/// one build at a time — but that evidence was gathered in SP-195 phase 4, **before**
/// decision 0036 replaced the disc with a slab and before the rebrand. Half the elements
/// it names no longer exist. An exclusion resting on evidence about deleted views is an
/// exclusion nobody can re-check, which is how F-0034 and F-0036 went stale until HL-019
/// re-triaged them from scratch.
///
/// So this asks the same question against today's tree, and prints rather than judges.
/// It is the only place `.dynamicType` runs at all.
///
/// **A diagnostic, not a gate.** It asserts nothing about the findings and is skipped by
/// name in `scripts/labor-sim.sh`'s UI stage, alongside `SmallTargetDiagnostics`. Run it
/// at whichever content size you want to interrogate — the audit reads the device's
/// setting, so the host chooses:
///
///     xcrun simctl ui <udid> content_size accessibility-extra-extra-extra-large
///     xcodebuild test -project Hushlight.xcodeproj -scheme Hushlight \
///       -only-testing:HushlightUITests/DynamicTypeAuditDiagnostics \
///       -destination 'id=<udid>'
///
/// Read the `DYNTYPE[state]` lines. Each carries the element as the audit describes it
/// and its frame, so "this cannot scale" can be checked against what it measures.
// `@MainActor` for the same reason `AccessibilityAuditTests` carries it: the audit's
// issue-handler closure is non-Sendable, and driving `XCUIApplication` off the main
// actor is a data race Swift 6 will not compile.
@MainActor
final class DynamicTypeAuditDiagnostics: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    private func launch(_ arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = arguments
        app.launch()
        return app
    }

    /// Runs the one category the gate excludes and reports every finding, with the
    /// element's measured frame beside the audit's claim about it.
    ///
    /// **The handler returns `true`, and the direction is not obvious.** `true` means
    /// "suppress this issue"; `false` means "let it fail the test". `AccessibilityAuditTests`
    /// returns `false` because it *is* a gate and a finding there must go red. This file
    /// is a diagnostic, so it returns `true` — the finding is printed and the test stays
    /// green. Getting this backwards, as the first version of this file did, turns a
    /// reporting tool into three failing tests that still print the right answer.
    private func reportDynamicType(_ state: String, _ app: XCUIApplication) throws {
        var findings = 0
        try app.performAccessibilityAudit(for: .dynamicType) { issue in
            findings += 1
            let described = issue.element?.debugDescription ?? "unknown element"
            let firstLine = described.split(separator: "\n").first.map(String.init) ?? described
            // The frame is the whole argument: an element the audit says cannot change
            // font size, printed with the size it currently occupies, is either evidence
            // for the finding or against it — and either way it is checkable.
            let frame = issue.element.map { "\($0.frame)" } ?? "no frame"
            print("DYNTYPE[\(state)] \(issue.compactDescription) — \(firstLine) — frame \(frame)")
            print("DYNTYPE[\(state)]   detail: \(issue.detailedDescription.replacingOccurrences(of: "\n", with: " · "))")
            return true
        }
        print("DYNTYPE AUDITED: \(state) findings=\(findings)")
    }

    func testDynamicTypeOnTheEmptyTimer() throws {
        let app = launch(["-uitesting", "-seedLaborWipe"])
        XCTAssertTrue(
            app.buttons["Start contraction"].waitForExistence(timeout: 10),
            "-seedLaborWipe did not produce the empty timer"
        )
        try reportDynamicType("empty", app)
    }

    func testDynamicTypeOnTheMetVerdict() throws {
        let app = launch(["-uitesting", "-seedLabor511"])
        XCTAssertTrue(
            app.descendants(matching: .any)
                .matching(NSPredicate(format: "label CONTAINS %@", "guideline many providers use"))
                .firstMatch.waitForExistence(timeout: 10),
            "-seedLabor511 did not produce the met banner"
        )
        try reportDynamicType("met", app)
    }

    func testDynamicTypeOnGuidance() throws {
        let app = launch(["-uitesting", "-seedLabor511"])
        let guidance = app.buttons["Guidance"]
        XCTAssertTrue(guidance.waitForExistence(timeout: 10), "Guidance button never appeared")
        guidance.tap()
        // "YOUR GUIDELINE", not "guideline". The timer carries a `Guideline 5-1-1` chip,
        // so the looser predicate matches the screen being navigated away from and a
        // failed tap would go unnoticed — reporting the timer's findings under the name
        // `guidance`. This header exists only on Guidance.
        // **Match "Your guideline", case-insensitively, and both halves of that matter.**
        //
        // *Case:* the audit prints this element as `label: 'YOUR GUIDELINE'`, but
        // `XCUIElement.label` reports `'Your guideline'` — the caps are `.textCase`
        // styling, not the accessibility label. A predicate written from the audit's
        // output therefore matches nothing, which is exactly what the first version of
        // this guard did. Read anchors off the element tree, never off audit prose.
        //
        // *Uniqueness:* the timer carries a `Guideline 5-1-1` chip, so a looser
        // `"guideline"` matches the screen being navigated away from and a failed tap
        // goes unnoticed — reporting the timer's findings under the name `guidance`.
        // `"your guideline"` appears on Guidance and nowhere else.
        XCTAssertTrue(
            app.descendants(matching: .any)
                .matching(NSPredicate(format: "label CONTAINS[c] %@", "your guideline"))
                .firstMatch.waitForExistence(timeout: 10),
            "Guidance never opened — no 'Your guideline' header, so the audit below would be the timer's"
        )
        try reportDynamicType("guidance", app)
    }
}
