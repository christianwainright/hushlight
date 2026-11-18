import XCTest

/// HL-058b: a hardware keyboard does what a finger does. iPad only — the commands
/// exist everywhere, but the tray table holds an iPad.
///
/// **What the harness can prove, and what it cannot.** `typeKey` reaches the app for
/// unmodified keys and for the system's own edit commands (⌘Z arrives through the
/// undo responder chain), so Space and ⌘Z are asserted below. Esc and custom ⌘-letter
/// commands are another matter: across two dozen runs on an iPad simulator they fired
/// only intermittently — never for a letter Simulator.app binds itself (⌘1/⌘2/⌘L/⌘Y/⌘H),
/// and for ⌘J only in some configurations, with or without the Simulator's
/// "connect hardware keyboard" preference. The app's ⌘J/⌘G commands are declared
/// through the same `.commands` API as Space and appear in the iPad's ⌘ HUD; their
/// test is opt-in (`KEYBOARD_COMMANDS=1` in the runner environment) so a harness
/// limitation cannot read as a regression, and their real verification is a Magic
/// Keyboard on a real iPad — recorded as HL-058b's device gate.
final class KeyboardTests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    override func tearDown() async throws {
        await MainActor.run {
            let cleanup = XCUIApplication()
            cleanup.launchArguments = ["-uitesting", "-seedLaborWipe"]
            cleanup.launch()
        }
    }

    func testSpaceStartsAndEndsAndCommandZUndoes() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "keyboard commands are exercised on iPad")
        let app = launch()
        // The slab's own word is the evidence, not the ledger's RUNNING badge: the
        // badge exists only in the regular regimes, and this test is about the key.
        let slab = app.descendants(matching: .any).matching(identifier: "timer.slab").firstMatch
        let ending = NSPredicate(format: "label BEGINSWITH 'End'")
        let starting = NSPredicate(format: "label BEGINSWITH 'Start'")
        app.typeKey(" ", modifierFlags: [])
        XCTAssertTrue(wait(for: slab, until: ending), "Space did not start a contraction")
        app.typeKey(" ", modifierFlags: [])
        XCTAssertTrue(wait(for: slab, until: starting), "Space did not end the contraction")
        app.typeKey("z", modifierFlags: .command)
        XCTAssertTrue(wait(for: slab, until: ending), "⌘Z did not undo the end tap — the contraction should be running again")
    }

    func testEscClosesASheet() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "keyboard commands are exercised on iPad")
        // Esc into a presented sheet joins ⌘J/⌘G: `.cancelAction` is the documented
        // Escape binding, and the harness did not deliver it to the sheet in any run.
        try XCTSkipUnless(ProcessInfo.processInfo.environment["KEYBOARD_COMMANDS"] == "1",
                          "Esc delivery into a sheet is not reliable in this harness — see the header; set KEYBOARD_COMMANDS=1 to run")
        let app = launch()
        let howItWorks = app.buttons["How it works"]
        XCTAssertTrue(howItWorks.waitForExistence(timeout: 5))
        howItWorks.tap()
        let gotIt = app.buttons["Got it"]
        XCTAssertTrue(gotIt.waitForExistence(timeout: 5), "the How it works sheet never presented")
        // The sheet takes key focus at the end of its presentation, not the start.
        sleep(1)
        app.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
        XCTAssertTrue(waitForAbsence(gotIt, timeout: 5), "Esc did not close the sheet")
    }

    func testCommandJAndGPushTheScreens() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "keyboard commands are exercised on iPad")
        try XCTSkipUnless(ProcessInfo.processInfo.environment["KEYBOARD_COMMANDS"] == "1",
                          "custom ⌘-letter delivery is not reliable in this harness — see the header; set KEYBOARD_COMMANDS=1 to run")
        let app = launch()
        app.typeKey("j", modifierFlags: .command)
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5), "⌘J did not push History")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["Guidance"].waitForExistence(timeout: 5), "did not return to the timer")
        sleep(1)
        app.typeKey("g", modifierFlags: .command)
        XCTAssertTrue(app.navigationBars["Guidance"].waitForExistence(timeout: 5), "⌘G did not push Guidance")
    }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uitesting", "-seedLabor511", "-seedProviderNumber", "5550100"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15))
        XCTAssertTrue(app.buttons["Guidance"].waitForExistence(timeout: 10), "the timer never came up")
        // Key events land only once the window is key; the first few hundred
        // milliseconds after launch swallow them.
        sleep(1)
        return app
    }

    private func wait(for element: XCUIElement, until predicate: NSPredicate, timeout: TimeInterval = 5) -> Bool {
        XCTWaiter().wait(for: [expectation(for: predicate, evaluatedWith: element)], timeout: timeout) == .completed
    }

    private func waitForAbsence(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let gone = NSPredicate(format: "exists == false")
        return XCTWaiter().wait(for: [expectation(for: gone, evaluatedWith: element)], timeout: timeout) == .completed
    }
}
