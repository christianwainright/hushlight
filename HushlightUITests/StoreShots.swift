import XCTest

/// HL-048: the App Store screenshot sweep, driven from the app rather than from
/// coordinates.
///
/// `shoot-store.sh` takes the three shots that need no interaction. The other four —
/// a contraction mid-run, the Lock Screen Live Activity, History and Guidance — need
/// taps, and until this file the script printed a point for a person to tap. **Those
/// were English points.** `History` is 履歴 in Japanese and a narrower button; the
/// toolbar's trailing group is a different width in German. A sweep that exists to
/// prove the app is not English cannot navigate by assuming it is, which is why the
/// three targets carry accessibility *identifiers* — stable in every language, and
/// invisible to VoiceOver, which goes on reading the translated label beside them.
///
/// Screenshots leave here as attachments and are lifted out of the result bundle by
/// `shoot-store.sh sweep`, because a test process on the simulator cannot write to a
/// path on the host.
///
/// **No `-uitesting`.** Every other suite in this target passes it to freeze
/// `TimelineView` for a settled tree; this one must not, because shot 02 is a
/// contraction *running* and a frozen schedule would photograph it at 0:00. That is
/// also why this file waits in real seconds rather than polling for a value.
@MainActor
final class StoreShots: XCTestCase {
    /// The language under test, handed in by `shoot-store.sh`. Empty is English.
    private var language: String { ProcessInfo.processInfo.environment["STORE_LANG"] ?? "" }

    /// Long enough that the elapsed figure reads as a contraction rather than a
    /// mis-tap: the app flags anything under twenty seconds as a likely slip, and a
    /// screenshot of its own slip warning is not the picture.
    private let runningSeconds: TimeInterval = 42

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

    private var languageArguments: [String] { StoreShotSupport.languageArguments(language) }

    /// **`.firstMatch`, and it is not incidental.** `accessibilityIdentifier` on a
    /// SwiftUI view propagates to the elements it contains, so a bare subscript query
    /// resolves to several and `tap()` fails with "Multiple matching elements found" —
    /// which is how this suite failed on its first run. The outermost match is the one
    /// that takes the tap.
    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement { storeElement(identifier, in: app) }

    private func launch(_ seed: String...) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = seed + languageArguments
        app.launch()
        return app
    }

    /// Named for the file `shoot-store.sh` will write, so the export needs no mapping
    /// table: the attachment name *is* the raw filename.
    private func capture(_ name: String) { captureScreen(name) }

    /// 02 — a contraction in progress. The one shot that needs the clock to be real.
    func testTimingShot() throws {
        let app = launch("-seedLaborYoung")
        let slab = element("timer.slab", in: app)
        XCTAssertTrue(slab.waitForExistence(timeout: 20), "the timer's slab button never appeared")
        slab.tap()
        Thread.sleep(forTimeInterval: runningSeconds)
        capture("02-timing-dark")
    }

    /// 06 — History, reached through the toolbar rather than a point on the screen.
    func testHistoryShot() throws {
        let app = launch("-seedLabor511")
        let history = element("nav.history", in: app)
        XCTAssertTrue(history.waitForExistence(timeout: 20), "the History link never appeared")
        history.tap()
        // The pinned rule-leg header is the last thing to settle on this screen; wait
        // for the list itself rather than for a fixed interval.
        XCTAssertTrue(app.cells.firstMatch.waitForExistence(timeout: 10)
                      || app.staticTexts.count > 0)
        Thread.sleep(forTimeInterval: 2)
        capture("06-history-light")
    }

    /// 07 — Guidance. Its toolbar button is an SF Symbol precisely so its width cannot
    /// vary by language (see `TimerScreen`), which is what makes it findable here.
    func testGuidanceShot() throws {
        let app = launch("-seedLaborWipe")
        let guidance = element("nav.guidance", in: app)
        XCTAssertTrue(guidance.waitForExistence(timeout: 20), "the Guidance button never appeared")
        guidance.tap()
        Thread.sleep(forTimeInterval: 2)
        capture("07-guidance-dark")
    }
}
