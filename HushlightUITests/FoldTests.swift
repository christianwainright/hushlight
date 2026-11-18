import XCTest

/// HL-061: the tabletop. A half-open Duo with the fold across the window puts the
/// instrument on the upright half and gives the half on the nightstand to the button.
///
/// The fold is `-simulateFold tabletop` — nothing in XCTest or `simctl` can pose a
/// simulated Duo — so this proves the layout's answer to a fold, on any device, and
/// not that the system reports one (decision 0066 says where that check lives).
/// Each state is photographed (`XCTAttachment`, kept always), as `RegimeTests` does.
final class FoldTests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    override func tearDown() async throws {
        await MainActor.run {
            let cleanup = XCUIApplication()
            cleanup.launchArguments = ["-uitesting", "-seedLaborWipe"]
            cleanup.launch()
        }
    }

    func testTabletopGivesTheLowerHalfToTheButtonAndTheCountToTheUpperHalf() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitesting", "-seedLabor511", "-seedProviderNumber", "5550100",
                               "-simulateFold", "tabletop"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15))

        let tabletop = app.descendants(matching: .any).matching(identifier: "tabletop").firstMatch
        XCTAssertTrue(tabletop.waitForExistence(timeout: 10), "a half-open fold across the window is the tabletop")
        XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "ledger").firstMatch.exists,
                       "the upright half has no room for the ledger")

        let screen = app.windows.firstMatch.frame
        let slab = app.descendants(matching: .any).matching(identifier: "timer.slab").firstMatch
        XCTAssertTrue(slab.waitForExistence(timeout: 5), "no slab")
        // The whole lower half, not a bar at the bottom of it: the slab starts at the
        // crease and runs most of the way to the edge.
        XCTAssertGreaterThanOrEqual(slab.frame.minY, screen.midY - 2, "the slab crossed above the fold")
        XCTAssertGreaterThan(slab.frame.height, screen.height * 0.25, "the slab is a bar, not the half")
        // Met leads on the upright half: the verdict is read without scrolling.
        let call = app.buttons["Call your provider"].firstMatch
        XCTAssertTrue(call.exists, "the verdict banner is missing")
        attach("tabletop-idle", app)

        slab.tap()
        let running = app.descendants(matching: .any).matching(identifier: "timer.slab").firstMatch
        XCTAssertTrue(running.waitForExistence(timeout: 5))
        XCTAssertEqual(running.label, "End contraction", "the lower half did not start the timing")
        // The live count is on the upright half, above the crease.
        let hero = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'second'")).firstMatch
        XCTAssertTrue(hero.waitForExistence(timeout: 5), "no live count")
        XCTAssertLessThan(hero.frame.maxY, screen.midY, "the count fell below the fold")
        attach("tabletop-running", app)

        running.tap()
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "timer.slab").firstMatch.label,
                       "Start contraction", "the second tap did not end it")
    }

    /// Without a fold nothing changes: the same launch minus the flag is the compact
    /// column with its pinned bar, on the outer display and on every iPhone.
    func testNoFoldIsTheColumn() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitesting", "-seedLabor511", "-seedProviderNumber", "5550100"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15))
        let slab = app.descendants(matching: .any).matching(identifier: "timer.slab").firstMatch
        XCTAssertTrue(slab.waitForExistence(timeout: 10))
        XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "tabletop").firstMatch.exists)
        XCTAssertLessThan(slab.frame.height, app.windows.firstMatch.frame.height * 0.25,
                          "without a fold the slab is the pinned bar")
    }

    private func attach(_ name: String, _ app: XCUIApplication) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
