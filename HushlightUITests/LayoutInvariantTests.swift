import UIKit
import XCTest

/// The geometry contract at AX5, because `.textClipped` catches one of the three ways
/// this screen has failed at accessibility sizes and not the other two.
///
/// F-0005 was three symptoms in one report: numerals wrapping mid-figure ("2:5 / 8"),
/// labels clipping mid-glyph ("INTER / VAL"), and — the one that actually mattered —
/// **the met banner sitting entirely below the fold, so the met, one-short-of-floor and
/// forty-five-minutes-stale screens were indistinguishable in the first screenful.**
/// Apple's audit sees the second. Nothing in it sees the first (a reflowed figure is
/// not clipped text) and nothing in it sees the third (a view below the fold is not an
/// accessibility issue; it is a layout decision). Decision 0022 §5 and decision 0027
/// answer all three by *reflowing*: `ViewThatFits` stacks the readout's three columns
/// and the header's two labels, and at accessibility sizes the guidance renders above
/// both. Those branches are invisible to every other check in this repository — a
/// screenshot shows them but asserts nothing, and the fact assertion reads values, not
/// positions. So they are asserted here, as frames.
///
/// **This file hard-fails below an accessibility size rather than skipping.** Every
/// invariant below is about a branch that only exists at accessibility sizes; pointed
/// at the default size it would pass by describing a layout it never looked at. A
/// layout invariant that quietly passes because it was aimed at the wrong size is worse
/// than no layout invariant, and it is the exact shape of every false green this
/// harness has produced (F-0030 and its two predecessors).
@MainActor
final class LayoutInvariantTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = true
    }

    override func tearDown() async throws {
        await MainActor.run {
            let cleanup = XCUIApplication()
            cleanup.launchArguments = ["-uitesting", "-seedLaborWipe"]
            cleanup.launch()
            cleanup.terminate()
        }
        try await super.tearDown()
    }

    // MARK: - The size gate

    /// Shared with `AccessibilityAuditTests` through `RunnerContentSize` so both files
    /// answer "what size are we at" the same way, and printed on the same
    /// `A11Y SIZE:` line `scripts/labor-sim.sh` greps — the script verifies that the
    /// size the test observed is the size the script set, which is the only defence
    /// against a stale simulator quietly downgrading the whole leg.
    private func requireAccessibilitySize() throws {
        let category = RunnerContentSize.category
        print("A11Y SIZE: \(category.rawValue) (source: \(RunnerContentSize.source))")
        guard category.isAccessibilityCategory else {
            XCTFail("""
                LayoutInvariantTests requires an accessibility content size; the runner \
                observes \(category.rawValue). Set it from the host — \
                `xcrun simctl ui <sim> content_size accessibility-extra-extra-extra-large` \
                — a test process cannot set it for itself. Failing rather than skipping: \
                these invariants describe branches that do not exist at smaller sizes, \
                so a skip and a pass would be indistinguishable.
                """)
            // A plain error, deliberately not `XCTSkip`: a skip is reported as "not
            // run", which is the very outcome this guard exists to refuse.
            throw WrongContentSize(observed: category)
        }
    }

    private struct WrongContentSize: Error {
        var observed: UIContentSizeCategory
    }

    // MARK: - Launch helpers

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

    private func element(_ app: XCUIApplication, matching predicate: NSPredicate) -> XCUIElement {
        app.descendants(matching: .any).matching(predicate).firstMatch
    }

    /// Finds an element that may start below the fold, dragging the readout up until
    /// it appears. `waitForExistence` alone does not scroll, and the stacked readout at
    /// AX5 begins several hundred points under the first screenful.
    private func elementScrollingIfNeeded(
        _ app: XCUIApplication, matching predicate: NSPredicate, attempts: Int = 6
    ) -> XCUIElement {
        let target = element(app, matching: predicate)
        if target.waitForExistence(timeout: 5) { return target }
        let scroll = app.scrollViews.firstMatch
        for _ in 0..<attempts where scroll.exists {
            scroll.swipeUp()
            if target.exists { return target }
        }
        return target
    }

    private static func describe(_ rect: CGRect) -> String {
        String(
            format: "x %.1f…%.1f  y %.1f…%.1f",
            rect.minX, rect.maxX, rect.minY, rect.maxY
        )
    }

    // MARK: - 1. The verdict is on screen, not under the bar

    /// F-0005's actual defect: at AXL the met banner sat **entirely** below the fold,
    /// so the met, one-short-of-floor and forty-five-minutes-stale screens were
    /// indistinguishable in the first screenful. Decision 0022 §5 answers it by
    /// ordering: at accessibility sizes the verdict renders first, ahead of the header
    /// and the readout, whatever the state.
    ///
    /// **What is asserted is that ordering plus a readable strip, not containment of
    /// the whole banner — and the measurement is why.** At AX5 on a 402 × 874 pt
    /// device the met banner is *972 pt tall*: the sentence alone is longer than the
    /// screen. Demanding that it fit above a ~350 pt button bar would be demanding
    /// truncation, which DESIGN-SPEC §8 forbids outright and which is a worse failure
    /// than scrolling. So the contract is the one that actually distinguishes the fixed
    /// screen from the broken one:
    ///
    ///   - the banner **leads** — it starts above every other content element, so the
    ///     first thing on screen is the verdict and not a column of numerals;
    ///   - it starts **inside the strip above the bar**, with at least two tap targets'
    ///     worth of it readable before the bar begins (measured: 362 pt of 88 required);
    ///   - it is hittable, so nothing is sitting on top of it.
    ///
    /// A banner that regressed to rendering after the readout, or that began under the
    /// bar, fails every one of those — which is exactly what F-0005 looked like.
    ///
    /// The element queried is the **combined** banner (`.accessibilityElement(children:
    /// .combine)`), so `descendants(matching: .any)` rather than `staticTexts` — which
    /// of the two XCTest types a combined group surfaces as depends on the traits
    /// SwiftUI folds in, not on anything this test controls.
    func testMetVerdictLeadsAndIsReadableAboveTheButtonBarAtAX5() throws {
        try requireAccessibilitySize()
        let app = launch(["-uitesting", "-seedLabor511"])

        let banner = element(
            app, matching: NSPredicate(format: "label CONTAINS %@", "guideline many providers use")
        )
        XCTAssertTrue(banner.waitForExistence(timeout: 10), "The met banner never rendered under -seedLabor511")
        XCTAssertTrue(banner.isHittable, "The met banner exists but is not hittable — it is behind something")

        let bar = timerButton(app)
        XCTAssertTrue(bar.waitForExistence(timeout: 10), "The timer button never appeared")

        let window = app.frame
        let bannerFrame = banner.frame
        let barFrame = bar.frame
        // Printed unconditionally: when this fails, the number by which it failed is
        // the finding, and re-running to learn it costs four minutes of simulator.
        print("""
            LAYOUT[verdict] window \(Self.describe(window)) \
            banner \(Self.describe(bannerFrame)) bar \(Self.describe(barFrame))
            """)

        XCTAssertGreaterThanOrEqual(
            bannerFrame.minY, window.minY,
            "Banner starts above the window's top edge — \(Self.describe(bannerFrame))"
        )
        XCTAssertLessThan(
            bannerFrame.minY, barFrame.minY,
            "Banner begins under the pinned button bar (\(bannerFrame.minY) vs \(barFrame.minY)) — "
                + "the verdict is entirely below the fold, which is F-0005 exactly."
        )
        // Two minimum tap targets. Not a design constant so much as a floor with a
        // number behind it: less than this and what is visible above the bar is a
        // fragment of one wrapped line, which is what "below the fold" felt like.
        XCTAssertGreaterThanOrEqual(
            barFrame.minY - bannerFrame.minY, 88,
            "Only \(barFrame.minY - bannerFrame.minY) pt of the verdict is readable before the "
                + "button bar begins; the reader has to scroll to learn what the screen says."
        )
        XCTAssertGreaterThanOrEqual(bannerFrame.minX, window.minX, "Banner starts left of the window")
        XCTAssertLessThanOrEqual(bannerFrame.maxX, window.maxX, "Banner runs past the window's right edge")

        // The verdict leads: decision 0022 §5's actual claim, and the half of it a
        // "does it fit" check cannot see. Every other content element must start below
        // the banner's top edge.
        for label in ["interval", "duration", "pattern"] {
            let column = elementScrollingIfNeeded(app, matching: NSPredicate(format: "label == %@", label))
            guard column.exists else {
                XCTFail("Readout column '\(label)' never appeared")
                continue
            }
            XCTAssertGreaterThan(
                column.frame.minY, bannerFrame.minY,
                "The '\(label)' column starts above the verdict — the readout is leading at an "
                    + "accessibility size, which is the ordering decision 0022 §5 reversed."
            )
        }
    }

    // MARK: - 2. The readout stacked

    /// Three columns, one under the other, sharing a left edge. Side by side they would
    /// share a `minY` and differ in `minX` — the arrangement that wrapped "2:58" into
    /// "2:5 / 8" — so the two branches are told apart by geometry alone, with no
    /// reliance on what any of them says.
    func testReadoutTakesItsStackedBranchAtAX5() throws {
        try requireAccessibilitySize()
        let app = launch(["-uitesting", "-seedLabor511"])

        var frames: [(label: String, frame: CGRect)] = []
        for label in ["interval", "duration", "pattern"] {
            let column = elementScrollingIfNeeded(
                app, matching: NSPredicate(format: "label == %@", label)
            )
            XCTAssertTrue(column.exists, "Readout column '\(label)' never appeared, even after scrolling")
            guard column.exists else { return }
            frames.append((label, column.frame))
        }
        print("LAYOUT[readout] " + frames.map { "\($0.label) \(Self.describe($0.frame))" }.joined(separator: " | "))

        let leadingEdges = frames.map(\.frame.minX)
        let spread = (leadingEdges.max() ?? 0) - (leadingEdges.min() ?? 0)
        XCTAssertLessThanOrEqual(
            spread, 1,
            "Readout columns do not share a leading edge (spread \(spread) pt) — they are still side by side"
        )
        for index in 1..<frames.count {
            XCTAssertGreaterThanOrEqual(
                frames[index].frame.minY, frames[index - 1].frame.maxY,
                "'\(frames[index].label)' overlaps '\(frames[index - 1].label)' vertically — "
                    + "the stacked branch must place them strictly one below the other"
            )
        }
    }

    // MARK: - 3. The header stacked

    /// The header's own `ViewThatFits`: identity text and guideline chip side by side
    /// while they fit, one above the other when they do not. At AX5 the two labels
    /// overlapped each other under the toolbar in the horizontal branch, which is what
    /// the stacked one exists to prevent.
    func testHeaderTakesItsStackedBranchAtAX5() throws {
        try requireAccessibilitySize()
        let app = launch(["-uitesting", "-seedLabor511"])

        let identity = elementScrollingIfNeeded(
            app, matching: NSPredicate(format: "label BEGINSWITH %@", "Contractions")
        )
        XCTAssertTrue(identity.exists, "The header's identity label never appeared")
        let chip = elementScrollingIfNeeded(
            app, matching: NSPredicate(format: "label BEGINSWITH %@", "Guideline ")
        )
        XCTAssertTrue(chip.exists, "The guideline chip never appeared")
        guard identity.exists, chip.exists else { return }

        let identityFrame = identity.frame
        let chipFrame = chip.frame
        print("LAYOUT[header] identity \(Self.describe(identityFrame)) chip \(Self.describe(chipFrame))")

        XCTAssertGreaterThanOrEqual(
            chipFrame.minY, identityFrame.maxY,
            "Header chip sits beside the identity label rather than below it — the horizontal "
                + "branch is still being taken at AX5, where the two overlap"
        )
        XCTAssertEqual(
            chipFrame.minX, identityFrame.minX, accuracy: 1,
            "Stacked header labels must share a leading edge"
        )
    }

    // MARK: - 4. The whole bar is the target

    /// The invariant most likely to be silently regressed and the one no screenshot can
    /// prove. The circle is the *look*; the bar is the target. Shaping the hit area to
    /// the circle left dead corners either side of it, on the one surface whose promise
    /// is that nothing requires aim — mid-contraction, one-handed, in the dark. Both
    /// `.frame(maxWidth: .infinity)` and `.contentShape(Rectangle())` live inside the
    /// button's label for that reason, and a refactor that moves either outside
    /// `.buttonStyle` restores the dead corners while every screenshot stays identical.
    func testTheButtonBarsFarCornerToggles() throws {
        try requireAccessibilitySize()
        let app = launch(["-uitesting", "-seedLaborWipe"])

        let start = app.buttons["Start contraction"]
        XCTAssertTrue(start.waitForExistence(timeout: 10), "Start button never appeared on a wiped store")
        let barFrame = start.frame
        print("LAYOUT[bar] \(Self.describe(barFrame)) window \(Self.describe(app.frame))")
        XCTAssertGreaterThan(barFrame.width, 0)

        // Eight points in from the trailing edge — inside the bar, far outside the
        // disc. Expressed as a normalized offset of the button's own frame so it stays
        // correct on any device width.
        let dx = (barFrame.width - 8) / barFrame.width
        start.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: 0.5)).tap()

        XCTAssertTrue(
            app.buttons["End contraction"].waitForExistence(timeout: 10),
            "A tap 8 pt from the bar's trailing edge did not start a contraction — the hit "
                + "region has collapsed back onto the circle and the corners are dead again"
        )
    }

    // MARK: - Helpers

    /// The one button, whichever action it is currently offering.
    // MARK: - 5. The timeline's connectors have not collapsed

    /// HL-031, F-0055. `EpisodeTimeline` laid every row out as two fixed columns and
    /// then whatever had to sit after them — `leadingColumnWidth` against `.body` and
    /// `nodeDiameter` against `.caption2`. At AX5 those two came to roughly 235 pt and
    /// 90 pt of a 402 pt screen, so the connector's "5:00 apart", third in the row, was
    /// proposed a sliver and wrapped to **one character per line**: a vertical strip of
    /// letters down the right edge, with the row several hundred points tall.
    ///
    /// **Nothing in this repository could see it.** Apple's audit does not flag it —
    /// reflowed text is not clipped text, and a very tall row is not an accessibility
    /// violation. The connector is `accessibilityHidden` by design (its interval is
    /// spoken on the older node of the pair it measures), so XCUI cannot query the
    /// collapsed element directly either. And the *nodes* looked fine throughout,
    /// because they usually have nothing after their two columns at all — the CHECK
    /// flag is absent on a healthy row. It read as an oddly empty timeline.
    ///
    /// So the assertion is made on the hole the connector leaves between the two nodes
    /// it separates, which is the one thing its collapse cannot hide. The bound is the
    /// neighbouring rows rather than a constant: stacked, a connector holds one short
    /// phrase over two lines and a node holds two figures and a dot, so rough parity is
    /// the expectation and **twice** a row is already generous. The failure it exists to
    /// catch is not a near miss — one character per line turns "5:00 apart" into ten
    /// lines where two belong, four or five times a node rather than a fraction over.
    ///
    /// Measured at AX5 with `-seedLabor511`: rows 101.7 pt, gaps 96.0 pt. The first
    /// draft of this test bounded the gap at one row and passed by 5.7 pt — true, and
    /// far too tight to survive a longer word or a larger locale. An invariant that
    /// goes red on a translation rather than on the defect teaches its reader to raise
    /// the threshold, which is how a real regression gets waved through later.
    func testTimelineConnectorsDoNotCollapseAtAX5() throws {
        try requireAccessibilitySize()
        let app = launch(["-uitesting", "-seedLabor511"])

        let nodes = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", "Contraction "))
        XCTAssertTrue(
            nodes.firstMatch.waitForExistence(timeout: 10),
            "No timeline nodes rendered under -seedLabor511"
        )

        // Newest first on screen, but sort by position rather than trusting query
        // order — this needs vertical adjacency, and only geometry establishes that.
        let frames = (0..<nodes.count)
            .map { nodes.element(boundBy: $0).frame }
            .filter { $0.height > 0 }
            .sorted { $0.minY < $1.minY }
        XCTAssertGreaterThanOrEqual(
            frames.count, 2,
            "Fewer than two timeline nodes on screen; there is no connector to measure"
        )
        print("LAYOUT[timeline] " + frames.map { Self.describe($0) }.joined(separator: " | "))

        for (upper, lower) in zip(frames, frames.dropFirst()) {
            let gap = lower.minY - upper.maxY
            let budget = 2 * max(upper.height, lower.height)
            XCTAssertLessThanOrEqual(
                gap, budget,
                "The connector between two timeline nodes is \(gap) pt tall, over a budget of "
                    + "\(budget) pt (twice the taller neighbouring row). A hairline and "
                    + "\"5:00 apart\" do not need that much room — the interval has been "
                    + "squeezed into a column too narrow to hold it and is wrapping a "
                    + "character at a time. This is F-0055."
            )
        }
    }

    private func timerButton(_ app: XCUIApplication) -> XCUIElement {
        let start = app.buttons["Start contraction"]
        return start.exists ? start : app.buttons["End contraction"]
    }
}
