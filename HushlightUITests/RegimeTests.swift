import UIKit
import XCTest

/// HL-058: the three layout regimes, on the device that has all of them. Portrait is
/// *Hand* and landscape is *Stand*; both show the ledger beside the instrument, and
/// the compact column never does. Skips itself on an iPhone — the regimes are chosen by
/// the window, and a phone only ever offers the compact one.
///
/// Each regime is photographed (`XCTAttachment`, kept always) so a run leaves the
/// evidence a reviewer of this item wants: the two panes, as laid out.
final class RegimeTests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    override func tearDown() async throws {
        await MainActor.run {
            XCUIDevice.shared.orientation = .portrait
            let cleanup = XCUIApplication()
            cleanup.launchArguments = ["-uitesting", "-seedLaborWipe"]
            cleanup.launch()
        }
    }

    func testHandAndStandShowTheLedgerAndCompactDoesNot() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "the regular regimes exist only on iPad")
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["-uitesting", "-seedLabor511", "-seedProviderNumber", "5550100"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15))

        let ledger = app.descendants(matching: .any).matching(identifier: "ledger").firstMatch
        XCTAssertTrue(ledger.waitForExistence(timeout: 10), "portrait on iPad is Hand — the ledger should be beside the instrument")
        // `sectionLabelText()` uppercases the header, so match the label, not the key.
        let header = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'this stretch'")).firstMatch
        XCTAssertTrue(header.exists, "the ledger's header never rendered")
        XCTAssertTrue(app.buttons["Call your provider"].firstMatch.exists, "the verdict banner is missing from the instrument")
        attach("hand-portrait", app)

        XCUIDevice.shared.orientation = .landscapeLeft
        // The rotation animates; the geometry the regime reads settles with it.
        sleep(2)
        XCTAssertTrue(ledger.waitForExistence(timeout: 10), "landscape on iPad is Stand — the ledger should still be there")
        // Rotation re-lays out but must not rebuild the screen's state: the same
        // rows are listed, nothing was reset.
        XCTAssertTrue(header.exists, "the ledger's header vanished on rotation")
        // Start a contraction so the stand's figure — the hero at `.distance` — is on
        // screen, and the ledger's newest row reads RUNNING beside it.
        let slab = app.descendants(matching: .any).matching(identifier: "timer.slab").firstMatch
        XCTAssertTrue(slab.waitForExistence(timeout: 5), "no slab")
        slab.tap()
        XCTAssertTrue(app.staticTexts["RUNNING"].firstMatch.waitForExistence(timeout: 5),
                      "the ledger did not pick up the running contraction")
        sleep(HOLD_SECONDS)
        attach("stand-landscape", app)
    }

    /// How long the landscape regime is held on screen before its capture — long
    /// enough for a person (or `simctl io screenshot`) to look at it while it runs.
    /// `REGIME_HOLD` in the test runner's environment overrides the default.
    private var HOLD_SECONDS: UInt32 {
        UInt32(ProcessInfo.processInfo.environment["REGIME_HOLD"] ?? "") ?? 2
    }

    /// The compact half of the claim: a phone is only ever the single column, and the
    /// ledger must not appear there. Skips on iPad, where the two above run.
    func testCompactHasNoLedger() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .phone, "the compact regime is asserted on iPhone")
        let app = XCUIApplication()
        app.launchArguments = ["-uitesting", "-seedLabor511", "-seedProviderNumber", "5550100"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15))
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "timer.slab").firstMatch.waitForExistence(timeout: 10))
        XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "ledger").firstMatch.exists,
                       "a phone is the compact regime — no ledger")
    }

    private func attach(_ name: String, _ app: XCUIApplication) {
        // The screen, not the app: on iPad the app's own screenshot comes back in
        // the framebuffer's pre-rotation orientation, which misreads as a layout bug.
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
