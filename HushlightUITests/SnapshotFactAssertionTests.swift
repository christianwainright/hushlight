import XCTest

/// F-0023: the shots stage asserts nothing today — it seeds a snapshot, sleeps, and
/// photographs it, and `snapshots/index.json`'s `expectedFacts` never touch the
/// accessibility tree. F-0019, F-0020 and F-0025 all went unnoticed by the machine
/// and were caught only by a human reviewing the gallery; T2 produced zero machine
/// rows in the run those findings came from.
///
/// **Mechanism, and why this shape.** `xcrun simctl` has no first-class
/// accessibility-tree dump, so the only client that can read the same tree VoiceOver
/// reads is XCUITest — which is why `scripts/labor-sim.sh` already carries a
/// `HushlightUITests` target rather than driving the simulator by `simctl` alone.
/// The alternative to what follows would be one `xcodebuild test -only-testing:`
/// invocation *per snapshot*, but `xcodebuild test` performs its own install/attach
/// handshake on every invocation — paying that per snapshot (dozens of them) would
/// cost tens of minutes on top of the screenshot loop it is meant to double-check.
/// So this file is **one test, one xcodebuild invocation**, which itself loops over
/// every dark/AXL snapshot in-process: each iteration terminates the previous
/// instance and relaunches with a new `-laborScenario` argument against the *same*
/// already-installed binary `shots_pass` built — exactly the "install once, vary the
/// launch argument" discipline `shoot_snapshot` already uses for the screenshots
/// themselves. `scripts/labor-sim.sh` invokes this test right after the dark/AXL
/// screenshot loop and before switching the simulator to the light/medium sweep, so
/// the accessibility-size-driven layout (`TimerScreen`'s `dynamicTypeSize.isAccessibilitySize`
/// reordering) is exactly what gets checked — light/medium is a spot check
/// (RUBRIC §1's Layer A), not the primary pass, and is not asserted here.
///
/// **F-0030, and why this file no longer reads values out of the dump.** The first
/// version of this checker scraped everything out of one `XCUIApplication.debugDescription`
/// capture, labels and values alike. Labels survive that: the dump prints them quoted
/// and in full (`label: 'interval'`, and a 230-character banner label verbatim). **Values
/// do not.** The dump prints them *unquoted* and *truncated to twenty characters*:
///
///     Other, 0x10808f5c0, {{20.0, 903.3}, …}, label: 'interval', value: average 4 minutes ...
///
/// so `value: '([^']*)'` never matched anything, `columnValue` returned nil for every
/// column on every snapshot, and every fact that quotes a figure reported a miss —
/// under the message "no accessibility element labelled 'interval' found in the tree",
/// which is what made 24 checker faults look like 24 product regressions. Truncation
/// makes this unfixable by regex: even correctly parsed, `average 4 minutes ...` cannot
/// be compared against "4 minutes 36 seconds". So **every figure now comes from a real
/// `XCUIElement` query** (`ScreenCapture` below), which returns the untruncated
/// accessibility value; the dump is kept only for label containment, which it renders
/// faithfully, and a sentinel fails loudly if that ever stops being true.
///
/// **What is asserted, precisely.** `ExpectedFacts.describe` (`SnapshotExportTests.swift`)
/// writes prose sentences for a human reviewer, not literal accessibility labels — so
/// a naive "is this exact string in the tree" check fails on almost everything. This
/// file instead recognises the small, fixed catalogue of sentence shapes
/// `ExpectedFacts.describe` actually emits (enumerated by reading the function, not
/// guessed at), extracts the **quoted figure or named state** each shape carries, and
/// checks that fragment against the tree:
///   - Column figures (INTERVAL/DURATION/PATTERN): the printed figure ("4:50", "1 H
///     12 M") is converted to the words `TimerScreen`'s `spokenColumnValue` actually
///     renders ("4 minutes", "36 seconds") — the accessibility *value* is spoken, not
///     the printed numeral, because the column view group is
///     `.accessibilityElement(children: .ignore)` with a custom `.accessibilityValue`.
///     The em-dash state checks for the exact literal `spokenColumnValue` returns
///     below the floor: "not enough contractions yet".
///   - The interval range detail and the tape's count (`EmberTape`'s own
///     `.accessibilityValue`) come from the same captured element values.
///   - The header's "LAST … AGO" gap is a *label*, so it is checked against the dump.
///   - The banner ("meets the RULE guideline…") is checked as a **literal substring**:
///     `.accessibilityElement(children: .combine)` merges its children's own,
///     un-transformed text, so the printed and accessible strings agree there.
///   - The partial line is checked by **stable prefix** ("Not at RULE yet"), the
///     "N timed contractions" tail, and — where SP-201's missing-leg wording applies
///     — the one fragment the printed and spoken forms share ("the guideline asks
///     for") — the same convention
///     `ContractionMechanicsTests.testPartialLineRendersWhenPatternIsNearButNotSustained`
///     already uses, because `TimerScreen.partialLine`'s printed and spoken forms
///     diverge in duration formatting but agree on those two fragments.
///   - Timeline row count, and the running/"CHECK · …" per-row states (both the
///     over-three-minute and the under-twenty-second flag), are
///     checked against `EpisodeTimeline.nodeAccessibilityText`'s actual wording
///     ("Contraction N, running…", "…check this one") — not the printed row text,
///     which again differs from what VoiceOver reads.
///
/// **What is deliberately not asserted**, and why:
///   - **History facts** ("History is empty", "History still holds N episode
///     section(s)…") describe a *different screen* — `HistoryScreen`, reached by a
///     `NavigationLink` — that the photographed screen never shows. Asserting them
///     would mean navigating away from the state the PNG actually captures, which is
///     not what this check is for; they are marked skipped, not silently ignored.
///   - Fractional-second duration figures beyond what a fact quotes: this file checks
///     that the derived minute/hour words are **present as a substring** of the
///     accessible value, not that the value equals them exactly, because some spoken
///     forms (whole-hour durations, in particular) drop a seconds component the
///     printed figure never carried in the first place. A substring check cannot
///     miss a genuinely wrong figure; it can only be more permissive about trailing
///     content it was never asked to police.
///   - Anything `ExpectedFacts.describe` might emit in a shape this file does not
///     recognise reports as **skipped**, not passed — see `FactCheck.evaluate`'s
///     final `return .skipped`. A snapshot whose facts are *entirely* unrecognised
///     shapes fails loudly (`NO ASSERTABLE FACTS`) rather than silently reporting
///     zero misses as a pass — a check that can assert nothing and still say
///     "PASSED" is worse than no check at all, which is F-0023's whole complaint.
///
/// **Invoking standalone**, outside `scripts/labor-sim.sh`: this test reads the
/// harness run directory from `~/.hushlight-labor-qa-out` (see `runDirectory` below),
/// the same pointer file `LaborSim.ResultsWriter` reads — plain `export`ed
/// environment variables never reach a simulator-hosted test process (see that
/// type's own doc comment for why), so write the run directory there first:
///
///     echo "$RUN" > ~/.hushlight-labor-qa-out
///     xcrun simctl ui <SIM> appearance dark
///     xcrun simctl ui <SIM> content_size accessibility-extra-large
///     xcodebuild test -project Hushlight.xcodeproj -scheme Hushlight \
///         -only-testing:HushlightUITests/SnapshotFactAssertionTests/testDarkAXLSnapshotsMatchExpectedFacts \
///         -destination "platform=iOS Simulator,id=<SIM>"
///     rm ~/.hushlight-labor-qa-out
///
/// `$RUN` must already hold `snapshots/index.json` and the seed snapshots it names —
/// i.e. a prior `--engine-only` (or full) `labor-sim.sh` pass. Appearance/content-size
/// are simulator-wide settings this test does not set itself, matching
/// `scripts/labor-sim.sh`'s own division of labour (bash owns the simulator's UI
/// state; the test owns what it reads once launched).
@MainActor
final class SnapshotFactAssertionTests: XCTestCase {
    override func setUp() {
        // Every snapshot is checked even after an earlier one misses, so one run
        // reports every failing fact instead of stopping at the first — a partial
        // report here is exactly the blind spot this file exists to close.
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

    // MARK: - Entry point

    func testDarkAXLSnapshotsMatchExpectedFacts() throws {
        guard let runDirectory else {
            throw XCTSkip(
                "no run directory at ~/.hushlight-labor-qa-out — run via scripts/labor-sim.sh, "
                    + "or see this file's header for standalone invocation."
            )
        }
        let index: SnapshotIndexFile
        do {
            index = try loadIndex(runDirectory: runDirectory)
        } catch {
            XCTFail("could not read snapshots/index.json under \(runDirectory.path): \(error)")
            return
        }
        guard !index.entries.isEmpty else {
            XCTFail("snapshots/index.json has no entries — did the engine pass run first?")
            return
        }

        let app = XCUIApplication()
        var factsAsserted = 0
        var factsSkipped = 0
        var snapshotsWithMiss = 0

        for entry in index.entries {
            let snapshotPath = runDirectory
                .appendingPathComponent("snapshots")
                .appendingPathComponent(entry.file).path

            app.terminate()
            // **Wait for the old process to actually be gone.** `terminate()` is
            // asynchronous, and a `launch()` issued while the previous process is
            // still dying attaches to it instead of starting a new one — which means
            // `DemoSeed` never runs and the loop asserts the *previous* scenario's
            // screen, aged by however long has passed. That is not hypothetical: a
            // full-harness run read `rule-switch-four-one-one`'s labor while checking
            // `classic-nullipara-typical`'s facts, because the shots stage had left
            // that scenario on screen a minute earlier. It is intermittent — the same
            // 24 snapshots passed cleanly in a standalone run — which is exactly the
            // kind of flake that gets re-run instead of fixed.
            XCTAssertTrue(
                app.wait(for: .notRunning, timeout: 15),
                "previous instance never terminated before \(entry.shot) — the next launch "
                    + "would attach to it and assert the wrong labor"
            )
            app.launchArguments = ["-uitesting", "-laborScenario", snapshotPath]
            app.launch()
            XCTAssertTrue(
                app.wait(for: .runningForeground, timeout: 15),
                "app never reached the foreground for \(entry.shot)"
            )
            _ = app.buttons["Start contraction"].waitForExistence(timeout: 10)
                || app.buttons["End contraction"].waitForExistence(timeout: 10)

            let capture = ScreenCapture(app: app)
            guard capture.tree.count > 200 else {
                // A dump this short means the accessibility hierarchy didn't come up
                // the way this file expects, not that every fact genuinely missed —
                // an environment fault (SP-042a-class), reported as one rather than
                // cascading into dozens of spurious FACT MISS lines.
                XCTFail(
                    "accessibility dump for \(entry.shot) is \(capture.tree.count) chars — "
                        + "looks truncated/BLOCKED, not a genuine fact miss"
                )
                snapshotsWithMiss += 1
                continue
            }
            // The dump-format sentinel, and the direct lesson of F-0030: label
            // containment is the one thing still read out of `debugDescription`, and
            // it is read on the strength of an *observed* format Apple does not
            // document. If that format ever changes, this must fail as one loud
            // environment/format fault rather than as a hundred silent fact misses.
            guard capture.tree.contains("label: '") else {
                XCTFail(
                    "accessibility dump for \(entry.shot) contains no \"label: '\" marker — "
                        + "the debugDescription format changed; label checks below cannot be trusted"
                )
                snapshotsWithMiss += 1
                continue
            }

            var snapshotChecked = 0
            var snapshotMissed = 0
            for fact in entry.expectedFacts {
                switch FactCheck.evaluate(fact, against: capture) {
                case .passed:
                    factsAsserted += 1
                    snapshotChecked += 1
                case .skipped:
                    factsSkipped += 1
                case let .failed(reason):
                    factsAsserted += 1
                    snapshotChecked += 1
                    snapshotMissed += 1
                    XCTFail("""
                        FACT MISS [\(entry.shot)] \(fact)
                          reason: \(reason)
                          values: \(capture.describedValues)
                          tree:
                        \(relevantTreeSlice(capture.tree))
                        """)
                }
            }
            if snapshotChecked == 0 {
                XCTFail(
                    "NO ASSERTABLE FACTS for \(entry.shot) — \(entry.expectedFacts.count) fact(s), "
                        + "none checkable; an assertion pass that verifies nothing is worse than none"
                )
                snapshotsWithMiss += 1
            } else if snapshotMissed > 0 {
                snapshotsWithMiss += 1
            }
        }
        app.terminate()

        // Grepped by scripts/labor-sim.sh's assert_pass — the loud, parseable line
        // that lets bash tell "the pointer file silently failed and nothing ran" (no
        // line at all) apart from "it ran and found N misses" (this line, N > 0).
        print(
            "SNAPSHOT ASSERTIONS: \(index.entries.count) snapshot(s), "
                + "\(factsAsserted) fact(s) asserted, \(factsSkipped) skipped (not assertable), "
                + "\(snapshotsWithMiss) snapshot(s) with a miss."
        )
    }

    // MARK: - Run-directory handover
    //
    // Mirrors `LaborSim.ResultsWriter.outputRoot`'s pointer-file fallback, which this
    // target cannot import (`HushlightUITests` depends on the app target only, and
    // LaborSim is a harness-authoring package with no business being linked into a
    // glass-driving test bundle). The restriction it works around is the same one:
    // a simulator-hosted test process is handed a fixed environment of its own, and
    // nothing a host shell `export`s before `xcodebuild test` reaches it.

    private var runDirectory: URL? {
        let env = ProcessInfo.processInfo.environment
        guard let home = env["SIMULATOR_HOST_HOME"] ?? env["HOME"] else { return nil }
        let pointer = URL(fileURLWithPath: home).appendingPathComponent(".hushlight-labor-qa-out")
        guard let data = try? Data(contentsOf: pointer),
              let path = String(data: data, encoding: .utf8)?
                  .trimmingCharacters(in: .whitespacesAndNewlines),
              !path.isEmpty
        else { return nil }
        return URL(fileURLWithPath: path, isDirectory: true)
    }

    private struct SnapshotEntry: Decodable {
        var file: String
        var shot: String
        var expectedFacts: [String]
    }

    private struct SnapshotIndexFile: Decodable {
        var entries: [SnapshotEntry]
    }

    private func loadIndex(runDirectory: URL) throws -> SnapshotIndexFile {
        let url = runDirectory.appendingPathComponent("snapshots/index.json")
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(SnapshotIndexFile.self, from: data)
    }

    /// The lines of a tree dump worth quoting beside a failure: the readout columns,
    /// the banner/partial line, the timeline nodes, the tick tape, the header — the
    /// same surfaces `ExpectedFacts.describe` speaks about. Falls back to a raw
    /// prefix if none of these markers are present, which would itself be a sign the
    /// dump's shape isn't what this file expects.
    private func relevantTreeSlice(_ tree: String) -> String {
        // HL-003 slice 2 (decision 0037): `TickTapeGauge`'s spoken percentage
        // retired with the gauge itself, and its anchor here moves with it —
        // "unbroken pattern toward one hour" becomes `EmberTape`'s stable label,
        // "contractions in the last hour" (see `ScreenCapture.tapeLabel` below,
        // which is where this file's other half of the same anchor lives; decision
        // 0036's boundary rule is what requires both to move together in this
        // commit).
        let keywords = [
            "label: 'interval'", "label: 'duration'", "label: 'pattern'",
            "guideline", "Not at ", "Contraction ", "contractions in the last hour",
            "Last contraction", "No contractions yet",
        ]
        let lines = tree.split(separator: "\n", omittingEmptySubsequences: true)
            .filter { line in keywords.contains { line.contains($0) } }
            .prefix(20)
        return lines.isEmpty ? String(tree.prefix(800)) : lines.joined(separator: "\n")
    }
}

// MARK: - One snapshot's readable surface

/// Everything one launched scenario offers a fact checker, captured once.
///
/// The split is F-0030's lesson made structural. **Labels** come from the dump: it
/// renders them quoted and complete, and one string search beats a predicate query per
/// fact (roughly ten per snapshot, twenty-four snapshots). **Values** come from real
/// element queries, because the dump truncates them at twenty characters and does not
/// quote them — reading a figure out of `value: average 4 minutes ...` is not a parsing
/// problem, it is missing data.
///
/// Four queries per snapshot, resolved eagerly at capture time rather than lazily per
/// fact: the readout's three columns and the tick tape are the only elements whose
/// *value* any fact asks about, and fetching them once keeps the per-snapshot query
/// count fixed no matter how many facts the index grows.
@MainActor
private struct ScreenCapture {
    /// `TimerScreen.tapeAccessibilityLabel` — named once there so the resting and
    /// live instruments cannot say different things, which is what makes it a stable
    /// anchor here. HL-003 slice 2 (decision 0037) re-cuts this anchor along with the
    /// gauge it described: `TickTapeGauge` spoke "unbroken pattern toward one hour"
    /// paired with a percent `accessibilityValue`; `EmberTape` speaks this label
    /// paired with a raw count (decision 0037 §7 — never a percentage). Nothing else
    /// in this file changes; `relevantTreeSlice`'s keyword list carries the same
    /// fragment for the same reason.
    static let tapeLabel = "contractions in the last hour"

    let tree: String
    /// Spoken accessibility values, keyed by the column's own lowercased label. A
    /// missing key means no element carried that label — a real miss, distinct from
    /// an element whose value is empty.
    let columnValues: [String: String]
    let tapeValue: String?

    init(app: XCUIApplication) {
        tree = app.debugDescription
        var columns: [String: String] = [:]
        for label in ["interval", "duration", "pattern"] {
            if let value = Self.value(of: label, in: app) { columns[label] = value }
        }
        columnValues = columns
        tapeValue = Self.value(of: Self.tapeLabel, in: app)
    }

    /// `.descendants(matching: .any)` rather than a typed query for the same reason
    /// `ContractionMechanicsTests.firstDescendant` gives: `.accessibilityElement(children:)`
    /// merges a group into one element whose XCTest *type* depends on which traits
    /// SwiftUI folded in, not on anything this file controls.
    private static func value(of label: String, in app: XCUIApplication) -> String? {
        let element = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", label))
            .firstMatch
        guard element.exists else { return nil }
        return element.value as? String
    }

    /// The captured values, for a failure message — so a miss says what was actually
    /// on screen rather than only what was expected.
    var describedValues: String {
        let columns = columnValues
            .sorted { $0.key < $1.key }
            .map { "\($0.key)='\($0.value)'" }
            .joined(separator: " ")
        return columns + " tape=" + (tapeValue.map { "'\($0)'" } ?? "<absent>")
    }
}

// MARK: - Fact checking

/// What one `expectedFacts` string resolved to against a captured tree dump.
private enum FactOutcome {
    case passed
    /// A shape `ExpectedFacts.describe` can emit that this file does not (and, for
    /// the History shapes, deliberately does not) check — see the file header.
    case skipped
    case failed(String)
}

/// Recognises the fixed catalogue of sentence shapes `ExpectedFacts.describe`
/// (`Packages/LaborSim/Tests/LaborSimTests/SnapshotExportTests.swift`) emits, and
/// checks the figure or state each shape carries against one `ScreenCapture` — labels
/// out of the dump, figures out of the element values that capture already fetched. No
/// further XCUITest querying happens per fact: a predicate query per fact (roughly ten
/// per snapshot, twenty-four snapshots) is measurably slower than in-process string
/// search over what was captured once, and "keep runtime sane" is an explicit
/// constraint here.
@MainActor
private enum FactCheck {
    static func evaluate(_ fact: String, against capture: ScreenCapture) -> FactOutcome {
        let tree = capture.tree
        if let content = quoted(after: "prose reads ", in: fact) {
            return evaluateProse(content, tree: tree)
        }
        if fact == "no verdict line and no banner" {
            return tree.contains("guideline many providers use")
                ? .failed("banner text present despite an empty pattern")
                : .passed
        }
        if fact.hasPrefix("History is empty") || fact.hasPrefix("History still holds")
            || fact.hasPrefix("History shows") {
            return .skipped // a different screen than the one this snapshot photographs
        }
        if fact == "readout is the empty state: three em-dash columns over a ghost timeline" {
            for label in ["interval", "duration", "pattern"] {
                guard columnReadsEmDash(label, in: capture) else {
                    return .failed("column '\(label)' does not read the em-dash state")
                }
            }
            return .passed
        }
        if let (column, rest) = columnFact(fact) {
            return evaluateColumn(column, rest, capture: capture)
        }
        if let range = quoted(after: "INTERVAL detail reads ", in: fact) {
            return evaluateRange(range, capture: capture)
        }
        if let headerTail = quoted(after: "header reads ", in: fact) {
            return evaluateHeader(headerTail, tree: tree)
        }
        if fact.hasPrefix("tick tape reads ") {
            return evaluateTickTape(fact, capture: capture)
        }
        if let banner = quoted(after: "banner present: ", in: fact) {
            return tree.contains(banner) ? .passed : .failed("banner text \"\(banner)\" not found")
        }
        if fact.hasPrefix("banner present but held") {
            return evaluateHeldBanner(tree: tree)
        }
        if fact.hasPrefix("no banner; guidance line reads ") {
            return evaluatePartialLine(fact, tree: tree)
        }
        if fact.hasPrefix("timeline shows ") {
            return evaluateTimelineCount(fact, tree: tree)
        }
        if fact.hasPrefix("row ") {
            return evaluateRow(fact, tree: tree)
        }
        return .skipped
    }

    // MARK: Empty-state prose

    /// `ExpectedFacts` quotes the **printed** sentence; `TimerScreen.emptyStateCopy`
    /// overrides that Text's accessibility label with the spoken gap
    /// (`LaborFormat.spokenGap`), so "Last contraction ended 2 H ago." never appears in
    /// the tree — "…ended 2 hours 0 minutes ago" does. The other shape
    /// ("No contractions yet.") carries no figure and needs no conversion.
    private static func evaluateProse(_ content: String, tree: String) -> FactOutcome {
        guard let match = firstMatch(#"^Last contraction ended (.+) ago\.$"#, in: content) else {
            return tree.contains(content) ? .passed : .failed("expected literal prose \"\(content)\" in the tree")
        }
        guard tree.contains("Last contraction ended") else {
            return .failed("no element reads 'Last contraction ended … ago'")
        }
        guard let parsed = parseGapDuration(match[0]) else {
            return .failed("could not parse the prose gap figure '\(match[0])'")
        }
        if let missing = firstUnsatisfied(elapsedCandidates(hours: parsed.hours, minutes: parsed.minutes), in: tree) {
            return .failed("empty-state prose is missing '\(missing)' (from \"\(content)\")")
        }
        return .passed
    }

    // MARK: The held banner

    /// The latched shape (decision 0025). `ExpectedFacts` leaves the wording to
    /// `TimerScreen` deliberately, so what is assertable is the *tense*: the held
    /// banner says "That met the …", never "That meets the …", and confusing the two
    /// is precisely the failure the fact describes.
    private static func evaluateHeldBanner(tree: String) -> FactOutcome {
        guard tree.contains("That met the ") else {
            return .failed("no element reads the held, past-tense banner ('That met the …')")
        }
        guard !tree.contains("That meets the ") else {
            return .failed("the live present-tense banner is on screen where a held one was expected")
        }
        return .passed
    }

    // MARK: Column figures (INTERVAL / DURATION / PATTERN)

    private static func columnFact(_ fact: String) -> (column: String, rest: String)? {
        guard let m = firstMatch(#"^(INTERVAL|DURATION|PATTERN) column reads (.+)$"#, in: fact) else { return nil }
        return (m[0], m[1])
    }

    private static func evaluateColumn(_ column: String, _ rest: String, capture: ScreenCapture) -> FactOutcome {
        let label = column.lowercased()
        if rest.hasPrefix("an em dash") {
            return columnReadsEmDash(label, in: capture)
                ? .passed
                : .failed("'\(label)' column does not read 'not enough contractions yet'")
        }
        guard let value = capture.columnValues[label] else {
            return .failed("no accessibility element labelled '\(label)' found in the tree")
        }

        let token = (rest.components(separatedBy: "; detail reads").first ?? rest)
            .trimmingCharacters(in: .whitespaces)
        let candidates: [[String]]
        if column == "PATTERN" {
            guard let parsed = parseHoursMinutes(token) else {
                return .failed("PATTERN figure '\(token)' did not parse as an H/M token")
            }
            // PATTERN is `now − episodeStart`, so it is the one column that keeps
            // running after the snapshot was described. See `elapsedCandidates`.
            candidates = elapsedCandidates(hours: parsed.hours, minutes: parsed.minutes)
        } else {
            guard let parsed = parseMinutesSeconds(token) else {
                return .failed("'\(label)' figure '\(token)' did not parse as an M:SS token")
            }
            // INTERVAL and DURATION are means over fixed offsets: seeding replays the
            // same gaps whenever it runs, so these do not drift and get no tolerance.
            candidates = [spokenFragments(minutes: parsed.minutes, seconds: parsed.seconds)]
        }
        if let missing = firstUnsatisfied(candidates, in: value) {
            return .failed("'\(label)' column value '\(value)' is missing '\(missing)'")
        }

        if column == "PATTERN", let detailMatch = firstMatch(#"detail reads "([^"]*)""#, in: rest),
           let countMatch = firstMatch(#"^(\d+) TOTAL$"#, in: detailMatch[0]) {
            let expectedSubstring = "\(countMatch[0]) contractions"
            guard value.contains(expectedSubstring) else {
                return .failed("PATTERN detail '\(detailMatch[0])' present but '\(expectedSubstring)' missing from '\(value)'")
            }
        }
        return .passed
    }

    private static func columnReadsEmDash(_ label: String, in capture: ScreenCapture) -> Bool {
        capture.columnValues[label]?.contains("not enough contractions yet") == true
    }

    // MARK: Interval range detail

    private static func evaluateRange(_ range: String, capture: ScreenCapture) -> FactOutcome {
        let sides = range.components(separatedBy: "–") // en dash — LaborFormat.range's glyph
        guard sides.count == 2,
              let lower = parseMinutesSeconds(sides[0]),
              let upper = parseMinutesSeconds(sides[1])
        else { return .failed("could not parse range '\(range)'") }
        guard let value = capture.columnValues["interval"] else {
            return .failed("no accessibility element labelled 'interval'")
        }
        let fragments = spokenFragments(minutes: lower.minutes, seconds: lower.seconds)
            + spokenFragments(minutes: upper.minutes, seconds: upper.seconds)
        for fragment in fragments {
            guard value.contains(fragment) else {
                return .failed("interval column value '\(value)' is missing '\(fragment)' from range \(range)")
            }
        }
        return .passed
    }

    // MARK: Header "LAST … AGO"

    private static func evaluateHeader(_ tail: String, tree: String) -> FactOutcome {
        guard let match = firstMatch(#"LAST (.+) AGO$"#, in: tail) else {
            // A header fact without a LAST clause (no `lastEndedAgo`) carries nothing
            // beyond presence, which other facts already cover.
            return .skipped
        }
        guard let parsed = parseGapDuration(match[0]) else {
            return .failed("could not parse header gap figure '\(match[0])'")
        }
        guard tree.contains("last one ended") else {
            return .failed("no element speaks 'last one ended ... ago' (spokenHeader)")
        }
        // "how long ago", so it keeps growing after the fact was written — same
        // tolerance and the same direction as PATTERN's.
        if let missing = firstUnsatisfied(elapsedCandidates(hours: parsed.hours, minutes: parsed.minutes), in: tree) {
            return .failed("header gap figure missing '\(missing)' in the tree")
        }
        return .passed
    }

    // MARK: Tick tape

    private static func evaluateTickTape(_ fact: String, capture: ScreenCapture) -> FactOutcome {
        guard let match = firstMatch(#"tick tape reads (\d+) "#, in: fact), let expected = Int(match[0]) else {
            return .failed("could not parse expected count out of '\(fact)'")
        }
        guard let value = capture.tapeValue else {
            return .failed("no element labelled '\(ScreenCapture.tapeLabel)' (the tick tape)")
        }
        // A raw count on both sides (decision 0037 §7), so no tolerance: the tape
        // either speaks the number of contractions the engine counted or it does not.
        guard let actual = Int(value) else {
            return .failed("tick tape value '\(value)' is not a count")
        }
        guard actual == expected else {
            return .failed("tick tape reads \(actual), expected \(expected)")
        }
        return .passed
    }

    // MARK: Partial line

    private static func evaluatePartialLine(_ fact: String, tree: String) -> FactOutcome {
        guard let content = quoted(after: "no banner; guidance line reads ", in: fact) else {
            return .failed("could not extract the partial-line text from '\(fact)'")
        }
        // `TimerScreen.partialLine` builds a printed `text` and a spoken form
        // together; they diverge in duration formatting but share these fragments,
        // which is why a fragment check survives the divergence and a full-string
        // check would not (same convention as the hand-written
        // `testPartialLineRendersWhenPatternIsNearButNotSustained`).
        if let match = firstMatch(#"^Not at (.+?) yet"#, in: content) {
            let prefix = "Not at \(match[0]) yet"
            guard tree.contains(prefix) else {
                return .failed("no element reads the partial-line prefix '\(prefix)'")
            }
            if let countMatch = firstMatch(#"over (\d+) timed contractions"#, in: content) {
                let suffix = "over \(countMatch[0]) timed contractions"
                guard tree.contains(suffix) else {
                    return .failed("partial-line prefix present but missing '\(suffix)'")
                }
            }
            // SP-201's missing-leg wording. "the guideline asks for" is the one
            // fragment the printed and spoken forms share verbatim — the figures
            // around it differ by design ("4:20" vs "4 minutes 20 seconds"), and only
            // the spoken form reaches the tree.
            //
            // **Which** legs are named is deliberately not pinned here. The facts are
            // derived at the harness's instant and the tree is captured `SETTLE_SECONDS`
            // later, and a scenario near a boundary can legitimately lose a second leg
            // in that gap — an old interval ages out of the window, the share drops,
            // and the screen correctly falls back to the figures-only line for the
            // instant it was photographed. So a fallback to that line passes, and only
            // a screen naming *neither* fails: that is the regression this exists to
            // catch — the view no longer reading `GuidelineStatus` at all. The exact
            // wording is pinned where the instant is fixed and far from any boundary,
            // in `ContractionMechanicsTests`.
            if content.contains("the guideline asks for") {
                guard tree.contains("the guideline asks for")
                        || tree.contains("timed contractions")
                else {
                    return .failed(
                        "the partial line names a missing leg and no element names one, "
                            + "nor did the screen fall back to the figures-only line"
                    )
                }
            }
            return .passed
        }
        if content.hasPrefix("Timing this contraction") {
            // Identical wording in both the printed and spoken forms for this
            // branch — an exact match is safe here, unlike the branches above.
            return tree.contains(content) ? .passed : .failed("expected literal '\(content)'")
        }
        if content.hasPrefix("Last contraction") {
            // Case-insensitive on the tail, and that is not cosmetic: the printed line
            // runs the clause on after an em dash ("… ago — not enough in the last
            // hour to average.") while the spoken form starts a new sentence ("…
            // Not enough in the last hour to average."). Only the spoken form is in
            // the tree, so a case-sensitive match here could never succeed.
            guard tree.contains("Last contraction"),
                  tree.localizedCaseInsensitiveContains("not enough in the last hour to average")
            else {
                return .failed("no element reads 'Last contraction ... not enough in the last hour to average'")
            }
            return .passed
        }
        return .skipped
    }

    // MARK: Timeline rows

    private static func evaluateTimelineCount(_ fact: String, tree: String) -> FactOutcome {
        guard let match = firstMatch(#"timeline shows (\d+) row"#, in: fact), let expected = Int(match[0]) else {
            return .failed("could not parse row count out of '\(fact)'")
        }
        let actual = countMatches(#"label: 'Contraction \d+,"#, in: tree)
        guard actual == expected else {
            return .failed("tree shows \(actual) 'Contraction N,' node(s), expected \(expected)")
        }
        return .passed
    }

    private static func evaluateRow(_ fact: String, tree: String) -> FactOutcome {
        guard let ordinalMatch = firstMatch(#"\(contraction (\d+)\)"#, in: fact), let ordinal = Int(ordinalMatch[0]) else {
            return .skipped
        }
        if fact.contains("is running") {
            let needle = "label: 'Contraction \(ordinal), running,"
            return tree.contains(needle) ? .passed : .failed("expected '\(needle)' in the tree")
        }
        if fact.contains("CHECK · OVER 3 MIN") || fact.contains("CHECK · UNDER 20 S") {
            let prefix = "label: 'Contraction \(ordinal), lasted"
            guard let line = tree.split(separator: "\n").first(where: { $0.contains(prefix) }) else {
                return .failed("no '\(prefix)' node in the tree")
            }
            guard line.contains("check this one") else {
                return .failed("contraction \(ordinal) node exists but is not marked suspect ('check this one')")
            }
            return .passed
        }
        return .skipped
    }

    // MARK: - Small parsers, mirroring LaborFormat/ExpectedFacts's grammar
    //
    // A third copy of this grammar, after `LaborFormat` (Contractions) and
    // `ExpectedFacts` (LaborSim) — the same trade both of those already make, for the
    // same reason: this target cannot call either in-process (`ExpectedFacts` runs in
    // a different process entirely; `LaborFormat` is app-target code an XCUITest
    // bundle cannot link against), so verifying its output means restating enough of
    // its grammar to recognise that output. Kept to exactly the shapes `ExpectedFacts`
    // is proven (by `theFormatGrammarClampsAndNeverPrintsAZeroInProse`) to emit.

    /// "4:50" -> (4, 50).
    private static func parseMinutesSeconds(_ token: String) -> (minutes: Int, seconds: Int)? {
        let parts = token.split(separator: ":")
        guard parts.count == 2, let m = Int(parts[0]), let s = Int(parts[1]) else { return nil }
        return (m, s)
    }

    /// "1 H 12 M" or "47 M" -> (hours, minutes). `LaborFormat.hoursMinutes`'s grammar.
    private static func parseHoursMinutes(_ token: String) -> (hours: Int, minutes: Int)? {
        if let m = firstMatch(#"^(\d+) H (\d+) M$"#, in: token) { return (Int(m[0])!, Int(m[1])!) }
        if let m = firstMatch(#"^(\d+) M$"#, in: token) { return (0, Int(m[0])!) }
        return nil
    }

    /// "2 H", "2 H 1 M" or "47 M" -> (hours, minutes). `LaborFormat.gap`'s grammar,
    /// which — unlike `hoursMinutes` — can print bare hours with no minutes term.
    private static func parseGapDuration(_ token: String) -> (hours: Int, minutes: Int)? {
        if let parsed = parseHoursMinutes(token) { return parsed }
        if let m = firstMatch(#"^(\d+) H$"#, in: token) { return (Int(m[0])!, 0) }
        return nil
    }

    /// `LaborFormat.spoken`, restated over a second count — all three of its branches,
    /// in its order, because two of them are only reachable from figures this file
    /// routinely sees and getting either wrong condemns a correct screen:
    ///
    ///   - **under a minute → "N seconds" alone.** It never says "0 minutes", and a
    ///     sub-minute DURATION average ("0:50") is the common case here, not the edge.
    ///   - **an hour or more → "H hours M minutes", with the seconds dropped.** An
    ///     `M:SS` figure can exceed sixty minutes — `intervalRange`'s upper bound reads
    ///     "76:21" on a stalled pattern — and the spoken form of that is "1 hours 16
    ///     minutes", which shares no fragment at all with "76 minutes".
    ///
    /// Both wrong readings were live in this checker's first version, hidden behind
    /// F-0030: nothing could reach them while every value lookup was already returning
    /// nil.
    private static func spokenForm(totalSeconds: Int) -> [String] {
        let total = max(0, totalSeconds)
        if total < 60 { return ["\(total) seconds"] }
        let minutes = total / 60
        let seconds = total % 60
        if minutes < 60 {
            return seconds == 0 ? ["\(minutes) minutes"] : ["\(minutes) minutes", "\(seconds) seconds"]
        }
        return ["\(minutes / 60) hours", "\(minutes % 60) minutes"]
    }

    /// An `M:SS` token's spoken fragments.
    private static func spokenFragments(minutes: Int, seconds: Int) -> [String] {
        spokenForm(totalSeconds: minutes * 60 + seconds)
    }

    /// The two readings an **elapsed** figure may legitimately have: the one the fact
    /// records, and one minute more.
    ///
    /// `ExpectedFacts` computes its figures at the snapshot's exact instant. The app
    /// computes them at *its* instant: `DemoSeed` resolves every offset against `Date()`
    /// in `HushlightApp.init`, and the screen renders a second or three later, after
    /// the store has been written and the test has waited for the button. Fixed-offset
    /// figures are immune — an interval or duration mean is the same however long
    /// afterwards you ask — but anything of the form `now − something` (PATTERN's
    /// `patternLength`, the header's "LAST … AGO", the empty state's prose gap) grows by
    /// that gap, and `LaborFormat.hoursMinutes` **floors** to the minute. So a figure
    /// sitting within a few seconds of a minute boundary renders one minute higher than
    /// the fact says. Two of twenty-four snapshots did exactly that.
    ///
    /// The tolerance is **one minute and only upward**, because launch time only ever
    /// moves forward between the seed and the render. A figure that reads *low*, or two
    /// minutes high, is still a miss — which is what keeps this from being the kind of
    /// slack that swallows a real defect. (Distinct from F-0019, which is about moments
    /// landing on *derived* boundaries; this is display formatting, and no moment picker
    /// can avoid it.)
    private static func elapsedCandidates(hours: Int, minutes: Int) -> [[String]] {
        let seconds = hours * 3600 + minutes * 60
        return [spokenForm(totalSeconds: seconds), spokenForm(totalSeconds: seconds + 60)]
    }

    /// nil if any one candidate set is entirely present in `value`; otherwise the first
    /// fragment the *first* candidate was missing — the closest thing to "what went
    /// wrong" a multi-candidate check can report.
    private static func firstUnsatisfied(_ candidates: [[String]], in value: String) -> String? {
        for fragments in candidates where fragments.allSatisfy({ value.contains($0) }) {
            return nil
        }
        return candidates.first?.first { !value.contains($0) } ?? "<no candidate fragments>"
    }

    /// The substring after `prefix` between its first and last `"` — every quoted
    /// `ExpectedFacts` shape carries exactly one quoted span, so "first to last"
    /// and "first to next" agree; written as "to last" because it costs nothing and
    /// tolerates a fact whose content happens to embed an escaped quote.
    private static func quoted(after prefix: String, in fact: String) -> String? {
        guard fact.hasPrefix(prefix) else { return nil }
        let rest = fact.dropFirst(prefix.count)
        guard rest.hasPrefix("\"") else { return nil }
        let inner = rest.dropFirst()
        guard let end = inner.lastIndex(of: "\"") else { return nil }
        return String(inner[..<end])
    }

    private static func firstMatch(_ pattern: String, in s: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(s.startIndex..<s.endIndex, in: s)
        guard let m = regex.firstMatch(in: s, range: range), m.numberOfRanges > 1 else { return nil }
        var groups: [String] = []
        for i in 1..<m.numberOfRanges {
            guard let r = Range(m.range(at: i), in: s) else { return nil }
            groups.append(String(s[r]))
        }
        return groups
    }

    private static func countMatches(_ pattern: String, in s: String) -> Int {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return 0 }
        let range = NSRange(s.startIndex..<s.endIndex, in: s)
        return regex.numberOfMatches(in: s, range: range)
    }
}
