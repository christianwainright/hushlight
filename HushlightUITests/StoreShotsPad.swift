import XCTest

/// HL-058c: the two iPad store shots — *Hand* (portrait, the verdict beside the ledger)
/// and *Stand* (landscape, the count at `.distance` with the ledger's newest row
/// reading RUNNING). Driven by `scripts/shoot-store-ipad.sh`, which sets appearance,
/// status bar and language around each run and exports the attachments into
/// `docs/design/hushlight/store/raw-ipad/`. iPad only.
@MainActor
final class StoreShotsPad: XCTestCase {
    private var language: String { ProcessInfo.processInfo.environment["STORE_LANG"] ?? "" }

    override func setUp() { continueAfterFailure = false }

    override func tearDown() async throws {
        await MainActor.run {
            XCUIDevice.shared.orientation = .portrait
            let cleanup = XCUIApplication()
            cleanup.launchArguments = ["-uitesting", "-seedLaborWipe"] + languageArguments
            cleanup.launch()
            cleanup.terminate()
        }
        try await super.tearDown()
    }

    private var languageArguments: [String] { StoreShotSupport.languageArguments(language) }

    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement { storeElement(identifier, in: app) }

    /// No `-uitesting`: the store wants the app behaving normally — the count ticking,
    /// the ember breathing — exactly as `shoot-store.sh` shoots the iPhone set.
    private func launch(_ seed: String...) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = seed + languageArguments
        app.launch()
        return app
    }

    private func capture(_ name: String) { captureScreen(name) }

    func testHandShot() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad)
        XCUIDevice.shared.orientation = .portrait
        let app = launch("-seedLabor511", "-seedProviderNumber", "5550100")
        XCTAssertTrue(element("ledger", in: app).waitForExistence(timeout: 20), "no ledger — not the Hand regime")
        Thread.sleep(forTimeInterval: 3)
        capture("pad-hand")
    }

    func testStandShot() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad)
        let app = launch("-seedLabor511", "-seedProviderNumber", "5550100")
        XCTAssertTrue(element("timer.slab", in: app).waitForExistence(timeout: 20), "no slab")
        XCUIDevice.shared.orientation = .landscapeLeft
        Thread.sleep(forTimeInterval: 2)
        element("timer.slab", in: app).tap()
        // Long enough that the count reads as a count, short enough to stay under the
        // three-minute CHECK flag by a wide margin.
        Thread.sleep(forTimeInterval: 38)
        capture("pad-stand")
    }
}
