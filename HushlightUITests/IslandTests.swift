import XCTest

/// HL-063: the Live Activity outside the app. On an iPhone Duo the Dynamic Island
/// runs vertically down the side of both displays; this starts a contraction, leaves
/// for the Home Screen, and photographs the island carrying it — the compact
/// presentation's count in a slot the old horizontal island never had to fit.
///
/// Evidence, not an assertion about pixels: the island is SpringBoard's, outside
/// this app's accessibility tree, so what the test can prove is that the timing
/// survives the app going to the background; the picture is left for a person.
final class IslandTests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    override func tearDown() async throws {
        await MainActor.run {
            let cleanup = XCUIApplication()
            cleanup.launchArguments = ["-uitesting", "-seedLaborWipe"]
            cleanup.launch()
        }
    }

    func testTheIslandCarriesARunningContraction() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitesting", "-seedLabor511", "-seedProviderNumber", "5550100"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15))
        let slab = app.descendants(matching: .any).matching(identifier: "timer.slab").firstMatch
        XCTAssertTrue(slab.waitForExistence(timeout: 10))
        slab.tap()
        XCTAssertEqual(slab.label, "End contraction")

        // SpringBoard, not `press(.home)`: a Duo has no Home button, and the press is
        // a silent no-op there — the first run of this test photographed the app.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        springboard.activate()
        XCTAssertTrue(springboard.wait(for: .runningForeground, timeout: 10))
        XCTAssertTrue(app.wait(for: .runningBackground, timeout: 10), "the app never left the screen")
        // The island settles after the app's exit animation.
        sleep(3)
        attach("island-home", XCUIScreen.main.screenshot())

        // Back in: still running — the activity and the record are the same state.
        app.activate()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "timer.slab").firstMatch.label,
                       "End contraction", "the contraction did not survive the trip to the Home Screen")
        app.descendants(matching: .any).matching(identifier: "timer.slab").firstMatch.tap()
    }

    private func attach(_ name: String, _ shot: XCUIScreenshot) {
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
