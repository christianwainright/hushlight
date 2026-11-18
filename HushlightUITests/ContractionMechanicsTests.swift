import XCTest

/// The contraction timer's mechanics, exercised the way a labouring person would
/// actually touch the screen: one giant button, an occasional swipe in History, and
/// (SP-181's one hard requirement) surviving getting killed mid-contraction. Every
/// test runs against the real accessibility tree — the same one VoiceOver reads —
/// never pixel positions, and every test finishes in well under its wall-clock
/// budget because this is a real-time app with no compressed-clock test seam: taps
/// and seeded snapshots stand in for the hour someone would otherwise have to wait.
@MainActor
final class ContractionMechanicsTests: XCTestCase {
    override func setUp() {
        // A broken launch must fail loudly once, not cascade into ten
        // misleading downstream failures on an app that never came up.
        continueAfterFailure = false
    }

    /// DemoSeed's own stated contract, enforced from the outside: every test — pass
    /// or fail — must leave the on-device store wiped. Seeded patterns, and the real
    /// contractions some of these tests start, must never outlive the pass.
    ///
    /// `async` and hopping through `MainActor.run` rather than the plain
    /// `override func tearDown()` the audit suite uses: `XCTestCase.tearDown()` is
    /// nonisolated, so an override of it in a `@MainActor` class is nonisolated too,
    /// and reaching `launch` from there is a Swift 6 data race. The audit suite gets
    /// away with a plain override because its `setUp` only touches an inherited
    /// property; this one drives the app.
    override func tearDown() async throws {
        await MainActor.run {
            let cleanup = launch(["-uitesting", "-seedLaborWipe"])
            cleanup.terminate()
        }
        try await super.tearDown()
    }

    // MARK: - Launch helper

    /// Constructs, launches, and confirms the app actually came up — every test
    /// launches through this rather than rolling its own, so a stuck simulator
    /// fails with one clear assertion instead of ten timeouts downstream.
    private func launch(_ args: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = args
        app.launch()
        XCTAssertTrue(
            app.wait(for: .runningForeground, timeout: 15),
            "App never reached the foreground with launch arguments \(args)"
        )
        return app
    }

    // MARK: - Accessibility lookup helpers

    /// `.accessibilityElement(children: .ignore)` (the readout columns, the
    /// timeline nodes) and `.accessibilityElement(children: .combine)` (the
    /// met-verdict block) both merge their children into one element, and which
    /// XCTest element *type* that merged element surfaces as — `staticText` vs
    /// `otherElement` — depends on which traits SwiftUI folds in, not on
    /// anything this test controls. Searching `.descendants(matching: .any)`
    /// instead of picking one type sidesteps the type guess entirely and
    /// removes the race a "try staticTexts, else otherElements" fallback would
    /// have between two separate queries.
    private func firstDescendant(_ app: XCUIApplication, matching predicate: NSPredicate) -> XCUIElement {
        app.descendants(matching: .any).matching(predicate).firstMatch
    }

    private func element(_ app: XCUIApplication, exactlyLabeled label: String) -> XCUIElement {
        firstDescendant(app, matching: NSPredicate(format: "label == %@", label))
    }

    private func element(_ app: XCUIApplication, labelBeginningWith prefix: String) -> XCUIElement {
        firstDescendant(app, matching: NSPredicate(format: "label BEGINSWITH %@", prefix))
    }

    private func element(_ app: XCUIApplication, labelContaining text: String) -> XCUIElement {
        firstDescendant(app, matching: NSPredicate(format: "label CONTAINS %@", text))
    }

    // MARK: - Navigation helpers

    private func openHistory(_ app: XCUIApplication) {
        let historyLink = app.buttons["History"]
        XCTAssertTrue(historyLink.waitForExistence(timeout: 10), "History toolbar link never appeared")
        historyLink.tap()
    }

    /// Taps the leading nav-bar button regardless of its label. TimerScreen sets
    /// no `.navigationTitle`, so History's default back button's text is not
    /// something this test should have to predict — position is the stable
    /// contract, not the string on it.
    private func goBackToTimer(_ app: XCUIApplication) {
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(backButton.waitForExistence(timeout: 10), "Back button never appeared in History's navigation bar")
        backButton.tap()
    }

    // MARK: - 1. Tap flips the button and the columns fill

    /// The T2-05 invariant: the button's accessibility label is always the
    /// *action* a tap performs, never the *state* the app is in. "Start" means
    /// tapping starts something; "End" means tapping ends something. A label
    /// that said "Running" would describe the state and leave VoiceOver users
    /// guessing what the tap does next.
    func testTapFlipsButtonAndColumnsFill() throws {
        let app = launch(["-uitesting", "-seedLaborWipe"])

        let startButton = app.buttons["Start contraction"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 10), "Start button never appeared on a freshly wiped store")
        startButton.tap()

        let endButton = app.buttons["End contraction"]
        XCTAssertTrue(
            endButton.waitForExistence(timeout: 10),
            "Button label must flip to the action (End), never sit on the state (Running) — T2-05"
        )

        let runningNode = element(app, labelBeginningWith: "Contraction 1, running")
        XCTAssertTrue(runningNode.waitForExistence(timeout: 10), "Running timeline node never appeared after starting a contraction")

        endButton.tap()

        let startAgain = app.buttons["Start contraction"]
        XCTAssertTrue(startAgain.waitForExistence(timeout: 10), "Button label must flip back to Start once the contraction ends")

        // Presence only, not content: with one contraction on the books the
        // evidence floors (PatternAnalysis needs 2 intervals / 3 durations
        // before printing an average) keep every value an em dash. The columns
        // themselves — the instrument's anatomy — must exist regardless.
        for label in ["interval", "duration", "pattern"] {
            let column = element(app, exactlyLabeled: label)
            XCTAssertTrue(column.waitForExistence(timeout: 10), "Readout column '\(label)' missing after a completed contraction")
        }
    }

    // MARK: - 1b. The slip strip catches the double tap (SP-203)

    /// Start and end in one gesture — the mis-tap the walkthrough caught — must
    /// produce the offer, and the offer must actually remove the record. The old
    /// path was: notice the wrong figure, navigate to History, swipe-delete, in
    /// labor.
    func testSlipStripOffersAndDeletesTheMisTap() throws {
        let app = launch(["-uitesting", "-seedLaborWipe"])

        app.buttons["Start contraction"].tap()
        let endButton = app.buttons["End contraction"]
        XCTAssertTrue(endButton.waitForExistence(timeout: 10))
        endButton.tap()

        // The strip self-dismisses, so everything below runs against a live offer:
        // `waitForExistence` returning true is itself the first assertion.
        let strip = element(app, labelContaining: "likely a slip")
        XCTAssertTrue(
            strip.waitForExistence(timeout: 5),
            "A contraction recorded in well under twenty seconds produced no slip offer"
        )
        // The disc must stay where her thumb left it: the strip grows the bottom bar
        // *upward*, so a correction never moves the control it interrupts. Measured
        // across the strip's own appearance and removal, with no navigation in
        // between — a push and a pop would re-lay out the screen and prove nothing.
        //
        // Two points of tolerance rather than zero: the bar's height changes, and
        // SwiftUI rounds a laid-out frame to the device's scale, so the disc can land
        // a fraction of a point differently at two bar heights. The claim under test
        // is that it does not move *enough to miss*, and a 44 pt target against a
        // 216 pt disc has three orders of magnitude in hand.
        let button = app.buttons["Start contraction"]
        let withStrip = button.frame

        app.buttons["Delete"].tap()

        XCTAssertTrue(
            strip.waitForNonExistence(timeout: 5),
            "The strip stayed up after its own Delete"
        )
        XCTAssertEqual(
            button.frame.minY, withStrip.minY, accuracy: 2,
            "The button moved when the strip came and went"
        )

        openHistory(app)
        XCTAssertTrue(
            app.staticTexts["Nothing logged yet."].waitForExistence(timeout: 10),
            "The strip's Delete did not remove the slip"
        )
    }

    // MARK: - 2. Undo of a start deletes the record

    func testUndoOfStartDeletesRecord() throws {
        let app = launch(["-uitesting", "-seedLaborWipe"])

        let startButton = app.buttons["Start contraction"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 10))
        startButton.tap()
        XCTAssertTrue(app.buttons["End contraction"].waitForExistence(timeout: 10))

        openHistory(app)

        let undoButton = app.buttons["Undo"]
        XCTAssertTrue(undoButton.waitForExistence(timeout: 10), "Undo action should be offered for the contraction just started")
        undoButton.tap()

        // `.started(id)` undo deletes the record outright (LaborModel.undo) —
        // the only correct outcome is the empty state, not a row for a
        // contraction that no longer exists.
        let emptyState = app.staticTexts["Nothing logged yet."]
        XCTAssertTrue(emptyState.waitForExistence(timeout: 10), "History should show its empty state after undoing the only start")
    }

    // MARK: - 3. Undo of an end resumes the running contraction

    func testUndoOfEndResumesRunningContraction() throws {
        let app = launch(["-uitesting", "-seedLaborWipe"])

        app.buttons["Start contraction"].tap()
        let endButton = app.buttons["End contraction"]
        XCTAssertTrue(endButton.waitForExistence(timeout: 10))
        endButton.tap()
        XCTAssertTrue(app.buttons["Start contraction"].waitForExistence(timeout: 10), "Button should read Start again once the contraction ends")

        openHistory(app)

        let undoButton = app.buttons["Undo"]
        XCTAssertTrue(undoButton.waitForExistence(timeout: 10), "Undo action should be offered for the contraction just ended")
        undoButton.tap()

        goBackToTimer(app)

        // `.ended(id)` undo re-opens the record (LaborModel.undo): the end tap
        // was the mistake, not the contraction, so the button must go back to
        // reporting it as running rather than staying stopped.
        XCTAssertTrue(
            app.buttons["End contraction"].waitForExistence(timeout: 10),
            "Undoing an end must resume the contraction as running"
        )
    }

    // MARK: - 4. Delete in History plus Undo restores

    /// Polls a query's match count. A delete or undo mutates `LaborModel`
    /// synchronously, but the List's diff and its insert/remove animation land a
    /// beat later, so a synchronous read immediately after `.tap()` races the
    /// animation.
    @discardableResult
    private func waitForMatchCount(
        _ query: XCUIElementQuery,
        timeout: TimeInterval,
        satisfying condition: @escaping (Int) -> Bool
    ) -> Int {
        let predicate = NSPredicate { _, _ in condition(query.count) }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        _ = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return query.count
    }

    func testDeleteInHistoryThenUndoRestores() throws {
        let scenarioPath = try writeTempScenario(resourceName: "verdict-met")
        // `-laborScenario` wipes and reseeds unconditionally (DemoSeed.applyScenario),
        // so no separate `-seedLaborWipe` launch is needed first.
        let app = launch(["-uitesting", "-laborScenario", scenarioPath])

        openHistory(app)

        let cells = app.cells
        XCTAssertTrue(cells.firstMatch.waitForExistence(timeout: 10), "History list never populated from the seeded scenario")

        // Addressed by content, not by index. The episode's summary line is a row too
        // (it renders inside the same `Section`) and carries no swipe action — "the
        // second cell" is a guess about layout, whereas "the first row that reads as a
        // completed contraction" is what `HistoryRow`'s own accessibility label promises.
        let contractionRow = NSPredicate(format: "label CONTAINS %@", "lasted")
        let targetRow = cells.containing(contractionRow).firstMatch
        XCTAssertTrue(
            targetRow.waitForExistence(timeout: 10),
            "No History row read as a completed contraction — expected a HistoryRow label containing 'lasted'"
        )

        // The oracle is this one row's identity, not the row *count*. A `List` only
        // realises the cells near the viewport, so deleting one of fifteen simply pulls
        // the next into view and `app.cells.count` never moves — an earlier version of
        // this test asserted on that count and read 11 both before and after a delete
        // that had genuinely happened.
        //
        // The label is read off the *element inside* the cell, not off the cell. A cell
        // that merely contains a labelled descendant has no label of its own, and the
        // empty string it returns matches over a hundred elements — which is exactly
        // how the first attempt at this assertion passed its query and compared
        // nothing. Hence the emptiness guard: it is the assertion that catches this
        // test lying about what it looked at.
        let rowElement = app.descendants(matching: .any).matching(contractionRow).firstMatch
        XCTAssertTrue(rowElement.waitForExistence(timeout: 10), "No labelled contraction row inside the History list")
        let targetLabel = rowElement.label
        XCTAssertFalse(
            targetLabel.isEmpty,
            "Read an empty label for the target row — the identity oracle below would match everything"
        )
        let sameRow = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", targetLabel))

        // A deliberate press-and-drag rather than `swipeLeft()`. `swipeLeft` is a
        // fast flick, and SwiftUI's swipe actions frequently do not latch open from
        // one: the row springs back before the button is queryable. Pressing first
        // and dragging to 40% reveals the action and stops short of the full-swipe
        // threshold, which would perform the delete itself and leave no button to tap.
        let grip = targetRow.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5))
        let release = targetRow.coordinate(withNormalizedOffset: CGVector(dx: 0.40, dy: 0.5))
        grip.press(forDuration: 0.2, thenDragTo: release)

        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(
            deleteButton.waitForExistence(timeout: 5),
            "Swipe-to-delete action never materialised. SwiftUI list swipe actions are the flakiest control exercised in this "
                + "suite — if this assertion fails, it is almost certainly the gesture that didn't land, not the delete/undo logic."
        )
        deleteButton.tap()

        let matchesAfterDelete = waitForMatchCount(sameRow, timeout: 10) { $0 == 0 }
        XCTAssertEqual(matchesAfterDelete, 0, "The deleted row (\(targetLabel)) is still in History")

        let undoButton = app.buttons["Undo"]
        XCTAssertTrue(undoButton.waitForExistence(timeout: 10), "Undo action should be offered for the row just deleted")
        undoButton.tap()

        // `.deleted(contraction)` undo restores the record verbatim (LaborModel.undo →
        // ModelContext.restoreContraction) — same start, same end, same id — so the
        // row that comes back must read exactly as the one that left, not merely
        // bring the count back up.
        let matchesAfterUndo = waitForMatchCount(sameRow, timeout: 10) { $0 > 0 }
        XCTAssertGreaterThan(matchesAfterUndo, 0, "Undo did not restore the deleted row (\(targetLabel))")
    }

    // MARK: - 5. Kill and relaunch mid-contraction (SP-181)

    /// Parses the tail of a running node's accessibility label
    /// ("Contraction 1, running, 2 minutes 14 seconds") back into a second
    /// count, mirroring the four shapes `LaborFormat.spoken` actually produces
    /// (checked against `Hushlight/LaborFormat.swift` before writing this):
    /// "N seconds" under a minute, "N minutes", "N minutes M seconds", and
    /// "N hours M minutes" past the hour. Returns nil for anything else so the
    /// caller can fall back to a weaker but still meaningful assertion instead
    /// of crashing on a format this parser doesn't recognise.
    private func elapsedSeconds(fromRunningNodeLabel label: String) -> Int? {
        guard let markerRange = label.range(of: "running, ") else { return nil }
        let spoken = String(label[markerRange.upperBound...])
        let fullRange = NSRange(spoken.startIndex..<spoken.endIndex, in: spoken)

        func firstMatchGroups(_ pattern: String, count: Int) -> [Int]? {
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: spoken, range: fullRange)
            else { return nil }
            var values: [Int] = []
            for index in 1...count {
                guard let range = Range(match.range(at: index), in: spoken),
                      let value = Int(spoken[range])
                else { return nil }
                values.append(value)
            }
            return values
        }

        if let groups = firstMatchGroups(#"^(\d+) hours (\d+) minutes$"#, count: 2) {
            return groups[0] * 3600 + groups[1] * 60
        }
        if let groups = firstMatchGroups(#"^(\d+) minutes (\d+) seconds$"#, count: 2) {
            return groups[0] * 60 + groups[1]
        }
        if let groups = firstMatchGroups(#"^(\d+) minutes$"#, count: 1) {
            return groups[0] * 60
        }
        if let groups = firstMatchGroups(#"^(\d+) seconds$"#, count: 1) {
            return groups[0]
        }
        return nil
    }

    /// SP-181's actual acceptance criterion, on glass rather than in a unit
    /// test: the running contraction lives in the store the moment it starts
    /// (`LaborModel.tap`), never in an in-memory timer, so killing the process
    /// and relaunching must find it still running with more time on the clock.
    func testKillAndRelaunchMidContraction() throws {
        let app = launch(["-uitesting", "-seedLaborWipe"])

        app.buttons["Start contraction"].tap()
        XCTAssertTrue(app.buttons["End contraction"].waitForExistence(timeout: 10))

        let preKillNode = element(app, labelBeginningWith: "Contraction 1, running")
        XCTAssertTrue(preKillNode.waitForExistence(timeout: 10), "Running node missing before kill")
        let preKillLabel = preKillNode.label

        app.terminate()

        // Relaunch bare — `-uitesting` only, deliberately no `-seedLaborWipe`
        // and no `-laborScenario`. `DemoSeed.applyIfRequested` checks the wipe
        // flag first, the scenario flag second, and does nothing at all when
        // neither is present, so this is the one launch in the whole suite
        // that must leave the on-disk store exactly as the killed process left
        // it — that's the entire behaviour under test.
        let relaunched = launch(["-uitesting"])

        XCTAssertTrue(
            relaunched.buttons["End contraction"].waitForExistence(timeout: 10),
            "A bare relaunch (no seeding flag) must find the running contraction the killed process left behind"
        )

        let postKillNode = element(relaunched, labelBeginningWith: "Contraction 1, running")
        XCTAssertTrue(postKillNode.waitForExistence(timeout: 10), "Running node missing after relaunch")
        let postKillLabel = postKillNode.label

        if let preSeconds = elapsedSeconds(fromRunningNodeLabel: preKillLabel),
           let postSeconds = elapsedSeconds(fromRunningNodeLabel: postKillLabel) {
            XCTAssertGreaterThan(
                postSeconds, preSeconds,
                "Elapsed time on the surviving contraction should have grown across the kill/relaunch: "
                    + "'\(preKillLabel)' -> '\(postKillLabel)'"
            )
        } else {
            // Weaker fallback, kept only for a `LaborFormat.spoken` shape this
            // parser doesn't recognise. The label still existing at all after a
            // real process kill, and the contraction still reading as running,
            // is itself the load-bearing proof that the store survived — the
            // exact figure is a nice-to-have on top of that.
            XCTAssertNotEqual(
                preKillLabel, postKillLabel,
                "Elapsed label should differ across a real kill/relaunch even where it can't be parsed numerically: "
                    + "'\(preKillLabel)' vs '\(postKillLabel)'"
            )
        }
    }

    // MARK: - 6. Verdict banner from a seeded snapshot

    /// Writes a bundled JSON fixture out to a file the *app* process can open.
    ///
    /// The runner and the app under test are two different processes with two
    /// different containers, so the bundle URL itself is useless to the app —
    /// it names a path inside the runner's sandbox. The destination is `/tmp`
    /// rather than `NSTemporaryDirectory()` for the same reason
    /// `scripts/labor-sim.sh` hands the app repo-relative host paths and
    /// `ResultsWriter` reads a pointer file out of `SIMULATOR_HOST_HOME`: a
    /// plain shared host path is the one channel between simulator processes
    /// that is known to work, where one process reaching into another's data
    /// container is not.
    private static let scenarioDirectory = "/tmp/hushlight-labor-uitests"

    private func writeTempScenario(resourceName: String) throws -> String {
        let bundle = Bundle(for: type(of: self))
        let resourceURL = try XCTUnwrap(
            bundle.url(forResource: resourceName, withExtension: "json"),
            "Missing test bundle resource \(resourceName).json — expected under HushlightUITests/Resources"
        )
        let data = try Data(contentsOf: resourceURL)
        let directory = URL(fileURLWithPath: Self.scenarioDirectory, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let tempURL = directory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
        try data.write(to: tempURL)
        addTeardownBlock { try? FileManager.default.removeItem(at: tempURL) }
        return tempURL.path
    }

    // Both snapshots are `LaborSeedSnapshot` v1: `startOffsetSeconds` /
    // `endOffsetSeconds` are seconds relative to launch `now` (negative =
    // past). Every figure below is checked against
    // `Packages/LaborKit/Sources/LaborKit/PatternAnalysis.swift`:
    //
    //   - `episodeGap` = 2 h — both scenarios are far inside this, one episode each.
    //   - the analysis window is `now - rule.sustainedWindow` = the last hour, plus
    //     the one record immediately before it (the bridging interval, decision
    //     0023 §3), which contributes a gap but not a duration or a count.
    //   - `guidelineEvidenceFloor` = 6 — a verdict renders at all only once the
    //     window holds ≥ 6 contractions.
    //   - 5-1-1 (the default `GuidelineRule`): `intervalThreshold` = 300 s, met when
    //     ≥ 2/3 of in-window gaps are at or under it (decision 0024);
    //     `durationEvidenceThreshold` = 50 s (≥ — decision 0023; the *stated* rule is
    //     still 60 s and copy says so); `sustainedWindow` = 3600 s, met when the
    //     pattern is that old **and** no in-window gap exceeds `sustainedGapLimit`
    //     = 900 s (decision 0026).
    //
    // `verdict-met.json` — 15 contractions, 290 s apart, 62 s each, newest
    // ending 120 s ago (offsets -182/-120 down to -4242/-4180):
    //   - 12 fall inside the hour ⇒ evidence floor cleared (12 ≥ 6).
    //   - every gap is 290 s ⇒ 12 of 12 at or under 300 ⇒ frequencyMet. **290, not
    //     300**: the threshold is inclusive, so a 300 s gap would sit exactly on the
    //     boundary, and these offsets are resolved against a wall-clock `Date` whose
    //     magnitude leaves roughly 1e-7 s of float slack. A fixture that could flip on
    //     rounding tests the double, not the app — RUBRIC §1's corpus-discipline rule
    //     applied to a hand-written fixture.
    //   - average duration = 62 s ⇒ durationMet (62 ≥ 50, and ≥ 60 besides).
    //   - patternLength = now − earliest start = 4242 s ≈ 71 min, longest gap 290 s
    //     ⇒ sustainedMet.
    //   - all three true ⇒ `status.met`, and a raw-true verdict is presented
    //     immediately (decision 0025), so the screen renders the banner whose
    //     fixed copy contains "meets the 5-1-1 guideline".
    //
    // `verdict-near.json` — 7 contractions, 240 s apart, 62 s each, newest
    // ending 120 s ago (offsets -182/-120 down to -1622/-1560):
    //   - all 7 fall inside the hour ⇒ evidence floor cleared (7 ≥ 6).
    //   - every gap is 240 s ⇒ frequencyMet.
    //   - average duration = 62 s ⇒ durationMet.
    //   - patternLength = now − earliest start = 1622 s ≈ 27 min ⇒ sustainedMet is
    //     FALSE (< 3600 s) — frequency and duration both met, sustained is not. The
    //     latch cannot rescue it either: ten minutes earlier the pattern was younger
    //     still, so no sampled instant was ever met.
    //   - `status.presentedMet` is false, so the screen renders the partial line. Since
    //     decision 0022 that line states the measured figures rather than naming the
    //     unmet dimensions, and since SP-201 it also names *which* leg is missing when
    //     exactly one is — which this scenario is: "Not at 5-1-1 yet — spacing and
    //     length are there; this stretch has been unbroken for 27 M, and the guideline
    //     asks for an hour." The assertions below match the stable prefix and the
    //     missing-leg clause rather than the whole string — the figures are the
    //     engine's answer and pinning them here would duplicate `PatternAnalysisTests`
    //     badly, whereas the wording is the copy contract (T0-14).

    func testVerdictBannerRendersWhenPatternMeets511() throws {
        let scenarioPath = try writeTempScenario(resourceName: "verdict-met")
        let app = launch(["-uitesting", "-laborScenario", scenarioPath])

        let banner = element(app, labelContaining: "meets the 5-1-1 guideline")
        XCTAssertTrue(banner.waitForExistence(timeout: 10), "The 'met' snapshot should render the 5-1-1 met-guideline banner")
    }

    func testPartialLineRendersWhenPatternIsNearButNotSustained() throws {
        let scenarioPath = try writeTempScenario(resourceName: "verdict-near")
        let app = launch(["-uitesting", "-laborScenario", scenarioPath])

        let partialLine = element(app, labelBeginningWith: "Not at 5-1-1 yet")
        XCTAssertTrue(partialLine.waitForExistence(timeout: 10), "The 'near' snapshot should render the partial (not-yet-met) line")

        // SP-201: sustained is the one missing leg here, so the line must say so and
        // must credit the two that are met. The spoken form leads with the absence.
        XCTAssertTrue(
            element(app, labelContaining: "the guideline asks for an hour").exists,
            "The 'near' snapshot names no missing leg — the reader is left doing the rule arithmetic"
        )
        // "pacing", not "spacing": the printed line runs the clause on after an em
        // dash while the spoken form — the one in the tree — opens a sentence with
        // it, and `labelContaining` is case-sensitive.
        XCTAssertTrue(
            element(app, labelContaining: "pacing and length are there").exists,
            "The 'near' snapshot never credits the two dimensions that already qualify"
        )

        let banner = element(app, labelContaining: "meets the 5-1-1 guideline")
        XCTAssertFalse(banner.exists, "The 'near' snapshot must NOT render the met-guideline banner — sustained is not met")
    }
}
