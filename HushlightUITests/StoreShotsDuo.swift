import XCTest

/// HL-064: the iPhone Duo store shots, one per pose. *Tabletop* (half open on the
/// nightstand: the count above the crease, the lower half the button), *Open* (laid
/// flat: History beside the timer), *Cover* (closed: the column on the outer display).
/// Driven by `scripts/shoot-store-duo.sh`.
///
/// **The pose is a precondition, not something a test can set.** Nothing in XCTest or
/// `simctl` folds a simulated Duo; Device Hub's hinge control does. So each shot
/// asserts the layout its pose produces and fails, naming the pose, when the device is
/// in another — and never passes `-simulateFold`, so a fold the system did not report
/// cannot reach the store (decision 0066).
@MainActor
final class StoreShotsDuo: XCTestCase {
    private var language: String { ProcessInfo.processInfo.environment["STORE_LANG"] ?? "" }
    private var languageArguments: [String] { StoreShotSupport.languageArguments(language) }

    override func setUp() { continueAfterFailure = false }

    override func tearDown() async throws {
        await MainActor.run {
            let cleanup = XCUIApplication()
            cleanup.launchArguments = ["-uitesting", "-seedLaborWipe"] + languageArguments
            cleanup.launch()
            cleanup.terminate()
        }
        try await super.tearDown()
    }

    /// No `-uitesting`: the store wants the app behaving normally, as the other sets do.
    /// Except the first-launch sheet, which a fresh simulator has never dismissed — the
    /// argument domain marks it seen without touching the device's defaults.
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-seedLabor511", "-seedProviderNumber", "5550100",
                               "-hasSeenHowItWorks", "YES"] + languageArguments
        app.launch()
        return app
    }

    func testTabletopShot() throws {
        let app = launch()
        XCTAssertTrue(storeElement("tabletop", in: app).waitForExistence(timeout: 20),
                      "not the tabletop — pose the Duo half open, fold across, in Device Hub first")
        storeElement("timer.slab", in: app).tap()
        // The count reads as a count, well under the three-minute CHECK flag.
        Thread.sleep(forTimeInterval: 38)
        captureScreen("duo-tabletop")
    }

    func testOpenShot() throws {
        let app = launch()
        XCTAssertTrue(storeElement("ledger", in: app).waitForExistence(timeout: 20),
                      "no ledger — open the Duo flat in Device Hub first")
        Thread.sleep(forTimeInterval: 3)
        captureScreen("duo-open")
    }

    func testCoverShot() throws {
        let app = launch()
        XCTAssertTrue(storeElement("timer.slab", in: app).waitForExistence(timeout: 20), "no slab")
        XCTAssertFalse(storeElement("ledger", in: app).exists, "a ledger — close the Duo in Device Hub first")
        XCTAssertFalse(storeElement("tabletop", in: app).exists, "the tabletop — close the Duo in Device Hub first")
        Thread.sleep(forTimeInterval: 3)
        captureScreen("duo-cover")
    }
}
