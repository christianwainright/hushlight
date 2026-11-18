import XCTest

/// **A live-tree browser, built rather than borrowed (HL-019, F-0038).**
///
/// F-0038 parked ~50 `contrast` and 18 `hitRegion` findings as "reproducible and
/// unlocated": Apple's audit reports every one of them with `issue.element == nil`,
/// so there is no frame to screenshot and no `debugDescription` to diff. The entry
/// said closing it "needs a tool this session did not have (Xcode's Accessibility
/// Inspector or equivalent live-tree browser)".
///
/// This is that tool, in the one form a headless session can actually use. The audit
/// will not say *which* element it means, but `XCUIElementQuery` will happily hand
/// over every element in the tree with its frame — so instead of asking the audit to
/// name its finding, this asks the tree the audit's own question and prints
/// everything that could be an answer.
///
/// **This is a diagnostic, not a gate.** It asserts nothing and is wired into no
/// script; `scripts/labor-sim.sh` and `scripts/a11y-ax5.sh` do not know it exists.
/// Run it by hand when a `hitRegion` count needs a name:
///
///     xcodebuild test -project Hushlight.xcodeproj -scheme Hushlight \
///       -only-testing:HushlightUITests/SmallTargetDiagnostics \
///       -destination 'id=<udid>'
///
/// Read the `SMALL[state]` lines it prints. The `hitRegion` audit's bar is a 44x44 pt
/// touch target, so anything below that in either dimension is a candidate; the count
/// per state is the number to reconcile against the audit's own.
// `@MainActor` for the same reason `AccessibilityAuditTests` carries it: the audit's
// issue-handler closure is non-Sendable, and driving `XCUIApplication` off the main
// actor is a data race Swift 6 will not compile.
@MainActor
final class SmallTargetDiagnostics: XCTestCase {

    /// The audit's own threshold: Apple's HIG minimum touch target.
    private static let minimumTarget: CGFloat = 44

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    private func launch(_ arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = arguments
        app.launch()
        return app
    }

    /// Every element in the tree whose frame is under 44 pt in either dimension,
    /// with enough about it to find it in the source.
    ///
    /// Element *types* are printed as raw values because `XCUIElement.ElementType` has
    /// no useful description. The raw number is stable and greppable, which is what
    /// matters here; the full mapping is `XCUIElementTypes.h`. The ones this app's
    /// tree actually produces, read off that header rather than remembered:
    /// **1** other, **9** button, **21** navigationBar, **43** image, **48** staticText.
    private func reportSmallElements(_ state: String, _ app: XCUIApplication) {
        let all = app.descendants(matching: .any).allElementsBoundByAccessibilityElement
        var reported = 0
        for element in all {
            // `frame` on a non-existent element throws; skip rather than fail, since
            // a diagnostic that dies mid-tree tells you less than a partial one.
            guard element.exists else { continue }
            let frame = element.frame
            guard frame.width > 0, frame.height > 0 else { continue }
            let tooNarrow = frame.width < Self.minimumTarget
            let tooShort = frame.height < Self.minimumTarget
            guard tooNarrow || tooShort else { continue }
            reported += 1
            let label = element.label.isEmpty ? "(no label)" : element.label
            let axis = tooNarrow && tooShort ? "both" : (tooNarrow ? "width" : "height")
            print(String(
                format: "SMALL[%@] type=%d under=%@ frame={{%.1f, %.1f}, {%.1f, %.1f}} hittable=%@ label: '%@'",
                state, element.elementType.rawValue, axis,
                frame.origin.x, frame.origin.y, frame.width, frame.height,
                element.isHittable ? "yes" : "no", label
            ))
        }
        print("SMALL[\(state)] total=\(reported) of \(all.count) accessibility elements")
    }

    /// `met` and `history` are where every `hitRegion` finding lives — three per state,
    /// in exactly the six states that render `LegRowView`'s three rows (the verdict
    /// banner's legs and History's `PinnedLegHeader`). That coincidence is what F-0038
    /// tested and could not confirm: giving each row a 44 pt floor left the count at 3.
    func testSmallTargetsInMetVerdict() throws {
        let app = launch(["-uitesting", "-seedLabor511"])
        XCTAssertTrue(
            app.descendants(matching: .any)
                .matching(NSPredicate(format: "label CONTAINS %@", "guideline many providers use"))
                .firstMatch.waitForExistence(timeout: 10),
            "-seedLabor511 did not produce the met banner — the state being walked is not the one named"
        )
        reportSmallElements("met", app)
    }

    /// **The control, and the reason this file proves anything.** `empty` reports
    /// *zero* `hitRegion` findings while showing the same toolbar as `met`. If the
    /// toolbar's buttons are small here too, they cannot be what `met` is being flagged
    /// for — which leaves whatever `met` has and `empty` does not.
    func testSmallTargetsInEmptyState() throws {
        let app = launch(["-uitesting", "-seedLaborWipe"])
        XCTAssertTrue(
            app.buttons["Start contraction"].waitForExistence(timeout: 10),
            "-seedLaborWipe did not produce the empty timer"
        )
        reportSmallElements("empty", app)
    }

    func testSmallTargetsInHistory() throws {
        let app = launch(["-uitesting", "-seedLabor511"])
        let history = app.buttons["History"]
        XCTAssertTrue(history.waitForExistence(timeout: 10), "History button never appeared")
        history.tap()
        // Wait on `Back`, not on the leg rows. The verdict banner this screen was
        // pushed *from* renders its own `apart`/`long`/`holding` rows, so a predicate
        // matching those is satisfied before the tap lands — a failed navigation would
        // sail through and the dump would be labelled `history` while describing the
        // timer. `Back` exists only once a screen has actually been pushed.
        XCTAssertTrue(
            app.buttons["Back"].waitForExistence(timeout: 10),
            "History never pushed — no Back button, so the tree below would be the timer's"
        )
        reportSmallElements("history", app)
    }
}
