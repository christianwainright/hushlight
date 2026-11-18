import XCTest

/// HL-057: the two hand-off buttons explain themselves when the OS refuses them.
///
/// The simulator has neither a mail app nor telephony, so both refusals are
/// deterministic here — which is the point. `AccessibilityAuditTests` proves the Call
/// button is *accessible* wherever it appears; nothing before this tapped one and
/// asked what happened next, so a regression that restored the silent button would
/// have passed every suite. Three instances are exercised: the verdict banner's
/// (its own state), and Guidance's `ViewThatFits` pair (state hoisted to the screen,
/// because the fallback widens the row and the branch can switch under it).
final class HandoffFallbackTests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    override func tearDown() async throws {
        await MainActor.run {
            let cleanup = XCUIApplication()
            cleanup.launchArguments = ["-uitesting", "-seedLaborWipe"]
            cleanup.launch()
        }
    }

    func testRefusedCallShowsTheNumberAndCopies() throws {
        let app = launch()
        let call = app.buttons["Call your provider"].firstMatch
        XCTAssertTrue(call.waitForExistence(timeout: 10), "no Call button in the verdict banner")
        call.tap()
        XCTAssertTrue(
            app.staticTexts["This device cannot place calls. The number:"].waitForExistence(timeout: 5),
            "the refused call showed no fallback"
        )
        XCTAssertTrue(app.staticTexts["5550100"].exists, "the fallback does not show the number as typed")
        let copy = app.buttons["Copy number"]
        XCTAssertTrue(copy.exists)
        copy.tap()
        XCTAssertTrue(app.buttons["Copied"].waitForExistence(timeout: 3), "Copy number gave no confirmation")
        // `hasStrings` asks nothing of the user; reading the string from another
        // process would raise the paste prompt and stall the run.
        XCTAssertTrue(UIPasteboard.general.hasStrings, "nothing reached the pasteboard")
    }

    func testGuidanceCallPairKeepsItsFallbackAndMailShowsTheAddress() throws {
        let app = launch()
        let guidance = app.buttons["Guidance"]
        XCTAssertTrue(guidance.waitForExistence(timeout: 10))
        guidance.tap()
        XCTAssertTrue(app.navigationBars.buttons.element(boundBy: 0).waitForExistence(timeout: 10),
                      "Guidance never pushed")

        // The first Call on Guidance is the `ViewThatFits` pair beside "For the call".
        let pairCall = app.buttons.matching(identifier: "Call your provider").element(boundBy: 0)
        scroll(app, until: pairCall)
        pairCall.tap()
        let fallback = app.staticTexts["This device cannot place calls. The number:"].firstMatch
        XCTAssertTrue(fallback.waitForExistence(timeout: 5), "the pair's refused call showed no fallback")
        // Widening the row is what can flip the pair from HStack to VStack; the flag
        // is owned by the screen, so the fallback must still be there a beat later.
        sleep(1)
        XCTAssertTrue(fallback.exists, "the fallback vanished — the refusal state was lost to a layout switch")

        let report = app.buttons["Report a problem"]
        scroll(app, until: report)
        report.tap()
        XCTAssertTrue(
            app.staticTexts["No mail app on this device. Write to:"].waitForExistence(timeout: 5),
            "the refused mail draft showed no fallback"
        )
        XCTAssertTrue(app.staticTexts["christian@wainright.net"].exists, "the fallback does not show the address")
        XCTAssertTrue(app.buttons["Copy address"].exists)
    }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uitesting", "-seedLabor511", "-seedProviderNumber", "5550100"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15))
        return app
    }

    private func scroll(_ app: XCUIApplication, until element: XCUIElement) {
        for _ in 0..<8 where !(element.exists && element.isHittable) {
            app.swipeUp()
        }
        XCTAssertTrue(element.exists && element.isHittable, "could not scroll \(element) into view")
    }
}
