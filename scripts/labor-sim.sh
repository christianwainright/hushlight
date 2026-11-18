#!/bin/bash
# The labor QA harness's one entry point (decision 0021, SP-193 phase 5).
#
#   ./scripts/labor-sim.sh                  # engine + snapshots + shots
#   ./scripts/labor-sim.sh --engine-only    # layer E only, then the report
#   ./scripts/labor-sim.sh --shots-only     # re-shoot an existing run's snapshots
#   ./scripts/labor-sim.sh --ui             # also drive HushlightUITests
#   ./scripts/labor-sim.sh --no-a11y        # skip the accessibility gate (on by default)
#   ./scripts/labor-sim.sh --deep           # request the wide corpus (see below)
#
# LOCAL-ONLY, like scripts/labor-mutate.sh: it drives a real
# simulator for minutes at a time and owns the device while it runs. Never wired into
# scripts/test.sh or CI.
#
# Everything lands under build/labor-qa/<UTC timestamp>/ — results JSON from the
# engine legs, the seed snapshots those legs derived, the screenshots taken from
# them, and report.md over all of it.
set -euo pipefail

cd "$(dirname "$0")/.."
REPO_ROOT=$(pwd)

# HUSHLIGHT_SIM overrides; otherwise take the newest available iPhone simulator
# (HL-038; before that it demanded the iOS 27 runtime, and before that it was a UDID
# from one machine's device set).
if [ -z "${HUSHLIGHT_SIM:-}" ]; then
    HUSHLIGHT_SIM=$(./scripts/newest-sim.sh "iPhone")
fi
if [ -z "${HUSHLIGHT_SIM:-}" ]; then
    echo "labor-sim: no iPhone simulator available; set HUSHLIGHT_SIM" >&2
    exit 1
fi
SIM=$HUSHLIGHT_SIM
BUNDLE_ID=net.wainright.hushlight
DESTINATION="platform=iOS Simulator,id=$SIM"

# The engine pass's handover channel. Not an environment variable: the simulator
# hands a Swift-package test process its own environment and forwards nothing, so
# LaborSim's ResultsWriter falls back to reading this one-line file out of
# SIMULATOR_HOST_HOME. See ResultsWriter.pointerFileName for the full story.
POINTER_FILE="$HOME/.hushlight-labor-qa-out"

# How long the app gets to launch, seed, and settle before the shutter. The seeded
# store is small (a few hundred rows at most) and TimelineView is frozen under
# -uitesting, so this is generous rather than tuned.
SETTLE_SECONDS=4

# The light/default-type secondary sweep is a spot check, not a second full pass —
# DESIGN-SPEC §8 makes dark + XL the primary and light + default the sweep.
LIGHT_SWEEP_COUNT=5

# Sampled dark/AX5 sweep. Same count and the same stride arithmetic as the light one,
# so all three galleries are comparable slices of one snapshot list rather than three
# different notions of "a sample".
DARK_AX5_COUNT=5

# The simulator's content-size tokens, named once. `large` is the **system default**;
# `medium` — which this script asked for until SP-195 phase 4 — is one notch *below*
# it, so every "default type" claim this harness has ever made was off by one. The
# shots under `shots/light-m` from earlier runs are at that lower size; the directory
# name is kept so old runs keep meaning what they meant.
SIZE_DEFAULT=large
SIZE_AXL=accessibility-extra-large
SIZE_AX5=accessibility-extra-extra-extra-large

# What the runner must report back for a leg to count. `A11Y SIZE:` carries the
# `UIContentSizeCategory` raw value the test process actually observes; a test cannot
# set the device's content size, so the only way to know a leg ran at the size it
# claims is to have it say so. See AccessibilityAuditTests's header.
category_for_size() {
    case "$1" in
        "$SIZE_DEFAULT") echo "UICTContentSizeCategoryL" ;;
        "$SIZE_AXL")     echo "UICTContentSizeCategoryAccessibilityL" ;;
        "$SIZE_AX5")     echo "UICTContentSizeCategoryAccessibilityXXXL" ;;
        *) echo "" ;;
    esac
}

DO_ENGINE=true
DO_SHOTS=true
DO_UI=false
DO_A11Y=true
DEEP=false

usage() {
    sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
    exit "${1:-0}"
}

while [ $# -gt 0 ]; do
    case "$1" in
        --engine-only) DO_SHOTS=false; DO_A11Y=false; shift ;;
        --shots-only)  DO_ENGINE=false; shift ;;
        --ui)          DO_UI=true; shift ;;
        --no-a11y)     DO_A11Y=false; shift ;;
        --deep)        DEEP=true; shift ;;
        -h|--help)     usage 0 ;;
        *) echo "labor-sim: unknown flag $1" >&2; usage 1 ;;
    esac
done

if ! $DO_ENGINE && ! $DO_SHOTS; then
    echo "labor-sim: --engine-only and --shots-only are mutually exclusive" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# The run directory
# ---------------------------------------------------------------------------

# --shots-only re-uses an existing run rather than starting an empty one: the
# snapshots it shoots are *derived by the engine pass*, so a fresh directory would
# have nothing to photograph. Point it explicitly with LABOR_QA_RUN, or let it take
# the newest run that actually carries snapshots.
if $DO_ENGINE; then
    RUN="$REPO_ROOT/build/labor-qa/$(date -u +%Y%m%dT%H%M%SZ)"
    mkdir -p "$RUN"
else
    if [ -n "${LABOR_QA_RUN:-}" ]; then
        RUN="$LABOR_QA_RUN"
    else
        RUN=$(find "$REPO_ROOT/build/labor-qa" -maxdepth 3 -name index.json -path '*/snapshots/*' 2>/dev/null \
            | sort | tail -1 | xargs -I{} dirname {} | xargs -I{} dirname {})
    fi
    if [ -z "${RUN:-}" ] || [ ! -d "$RUN" ]; then
        echo "labor-sim: --shots-only needs an existing run with snapshots; set LABOR_QA_RUN" >&2
        exit 1
    fi
    echo "labor-sim: re-shooting $RUN"
fi

GIT_REV=$(git rev-parse --short HEAD 2>/dev/null || echo unknown)
GIT_DIRTY=false
if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
    GIT_DIRTY=true
fi

# The corpus digest, host-side. Read from the pin rather than from the harness so a
# run can state which corpus it *asked for* even when the engine stage is skipped;
# the engine's own run.json carries the digest it actually computed, and a report
# that shows the two disagreeing is a report showing an unbumped pin.
CORPUS_DIGEST=$(sed -n 's/.*pinnedDigest = "\([0-9a-f]*\)".*/\1/p' \
    Packages/LaborSim/Tests/LaborSimTests/CorpusStabilityTests.swift | head -1)

STAGES=""
add_stage() { STAGES="${STAGES:+$STAGES, }\"$1\""; }
if $DO_ENGINE; then add_stage engine; fi
if $DO_SHOTS; then add_stage shots; fi
if $DO_UI; then add_stage ui; fi
if $DO_A11Y; then add_stage a11y; fi
add_stage report

cat > "$RUN/run-meta.json" <<JSON
{
  "gitRef": "$GIT_REV",
  "gitDirty": $GIT_DIRTY,
  "startedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "corpusDigest": "$CORPUS_DIGEST",
  "corpusDigestSource": "CorpusStabilityTests.pinnedDigest",
  "deep": $DEEP,
  "simulator": "$SIM",
  "stages": [$STAGES]
}
JSON

echo "labor-sim: run $RUN (git $GIT_REV, sim $SIM)"

# ---------------------------------------------------------------------------
# Stage 1 — the engine pass (layer E)
# ---------------------------------------------------------------------------

cleanup_pointer() { rm -f "$POINTER_FILE" "$HOME/.hushlight-labor-qa-deep"; }

# Appearance and content size are **device-wide** settings, so an interrupted run that
# left AX5 on would silently re-size every later screenshot, gate and manual look at
# this simulator. Restored on every exit path, not just the happy one.
restore_simulator() {
    cleanup_pointer
    sim_ui light "$SIZE_DEFAULT"
}
trap restore_simulator EXIT

engine_pass() {
    echo
    echo "== engine =="
    printf '%s\n' "$RUN" > "$POINTER_FILE"
    # `--deep` is stamped and exported, but nothing widens the corpus on it yet:
    # ScenarioCorpus.deep is deliberately caller-gated (Corpus.swift) and
    # PureSweepTests still asks for `.standard`. Left wired so the flag means one
    # thing when a test finally reads it, rather than two things now.
    if $DEEP; then
        export LABOR_QA_DEEP=1
        printf '1\n' > "$HOME/.hushlight-labor-qa-deep"
    fi

    set +e
    ./scripts/test.sh LaborSim 2>&1 | tee "$RUN/engine.log"
    local status=${PIPESTATUS[0]}
    set -e
    cleanup_pointer

    # The silent-no-op trap, and the reason this check is not optional. The pointer
    # file is the only channel into the simulator's test process; if it is missed the
    # suite still passes, writes nothing, and a green run produces an empty report
    # that looks like a clean corpus.
    local count
    count=$(find "$RUN/results" -name '*.json' 2>/dev/null | wc -l | tr -d ' ')
    if [ "$count" -eq 0 ]; then
        echo "labor-sim: engine wrote no results — the pointer-file handover failed" >&2
        echo "           (expected $RUN/results/*.json; see ResultsWriter.pointerFileName)" >&2
        exit 1
    fi
    echo "labor-sim: $count result files"

    local snaps
    snaps=$(find "$RUN/snapshots" -name '*.json' ! -name index.json 2>/dev/null | wc -l | tr -d ' ')
    echo "labor-sim: $snaps seed snapshots"
    if [ "$status" -ne 0 ]; then
        ENGINE_OK=false
        echo "labor-sim: engine tests reported failures (see engine.log) — continuing to the report"
    fi
}

# ---------------------------------------------------------------------------
# Stage 2 — the app pass (layer A): seed a snapshot, photograph the result
# ---------------------------------------------------------------------------

sim_ui() {
    xcrun simctl ui "$SIM" appearance "$1" >/dev/null 2>&1 || true
    xcrun simctl ui "$SIM" content_size "$2" >/dev/null 2>&1 || true
}

# One snapshot -> one PNG. Terminate first: DemoSeed runs in `init`, so a running app
# would keep the previous scenario on screen and photograph the wrong labor.
shoot_snapshot() {
    local snapshot=$1 out=$2
    xcrun simctl terminate "$SIM" "$BUNDLE_ID" >/dev/null 2>&1 || true
    xcrun simctl launch "$SIM" "$BUNDLE_ID" \
        -laborScenario "$snapshot" -uitesting >/dev/null 2>&1 || {
        echo "labor-sim: launch failed for $(basename "$snapshot")" >&2
        return 1
    }
    sleep "$SETTLE_SECONDS"
    xcrun simctl io "$SIM" screenshot "$out" >/dev/null 2>&1
}

# One sampled gallery: <appearance> <content size> <directory> <count> <snapshot…>.
#
# The sample is strided across the snapshot list rather than taken off the front — the
# first five alphabetically are all one archetype. Named once because there are now two
# sampled sweeps and a third hard-coded copy of this arithmetic is how the two would
# come to disagree about what "a sample" means.
#
# Snapshots arrive as trailing arguments, not as an array name: `/bin/bash` on macOS is
# 3.2, which has no namerefs, and this script is run through that interpreter.
sampled_sweep() {
    local appearance=$1 size=$2 dir=$3 want=$4
    shift 4
    local snapshots=("$@")
    mkdir -p "$RUN/shots/$dir"
    sim_ui "$appearance" "$size"
    local total=${#snapshots[@]}
    local step=$(( total / want ))
    [ "$step" -lt 1 ] && step=1
    local taken=0 i=0
    while [ "$i" -lt "$total" ] && [ "$taken" -lt "$want" ]; do
        local name
        name=$(basename "${snapshots[$i]}" .json)
        if shoot_snapshot "${snapshots[$i]}" "$RUN/shots/$dir/$name.png"; then
            taken=$((taken + 1))
        fi
        i=$(( i + step ))
    done
    echo "labor-sim: $taken $appearance/$size shots -> shots/$dir"
    # A failed shot is skipped, not retried, so any shortfall is a lost picture.
    local expected=$(( total < want ? total : want ))
    if [ "$taken" -lt "$expected" ]; then
        echo "labor-sim: $appearance/$size took $taken of $expected shots" >&2
        return 1
    fi
}

shots_pass() {
    echo
    echo "== shots =="
    local snapshots=()
    while IFS= read -r file; do snapshots+=("$file"); done < <(
        find "$RUN/snapshots" -name '*.json' ! -name index.json 2>/dev/null | sort
    )
    if [ "${#snapshots[@]}" -eq 0 ]; then
        echo "labor-sim: no snapshots to shoot (did SnapshotExportTests run?)" >&2
        return 1
    fi

    # Every step to the first screenshot is checked explicitly. This function is
    # called from an `if`, where `set -e` is suspended for the whole body — so an
    # unchecked failure here would not abort, it would photograph a stale binary.
    if ! ./scripts/build.sh Hushlight >/dev/null; then
        echo "labor-sim: Hushlight failed to build" >&2
        return 1
    fi

    local app
    app=$(find ~/Library/Developer/Xcode/DerivedData/Hushlight-*/Build/Products/Debug-iphonesimulator \
        -maxdepth 1 -name "Hushlight.app" 2>/dev/null | head -1)
    if [ -z "$app" ]; then
        echo "labor-sim: Hushlight.app not found in DerivedData" >&2
        return 1
    fi

    xcrun simctl bootstatus "$SIM" -b >/dev/null 2>&1 || xcrun simctl boot "$SIM"

    # Installed once for the whole sweep, not per shot. shoot.sh reinstalls each time
    # because it rebuilds each time; here the binary is fixed and only the launch
    # argument changes, and forty reinstalls would be forty minutes of nothing.
    xcrun simctl terminate "$SIM" "$BUNDLE_ID" >/dev/null 2>&1 || true
    xcrun simctl uninstall "$SIM" "$BUNDLE_ID" >/dev/null 2>&1 || true
    if ! xcrun simctl install "$SIM" "$app" >/dev/null; then
        echo "labor-sim: could not install $app on $SIM" >&2
        return 1
    fi

    # Dark + XL is the primary pass (DESIGN-SPEC §8): the appearance and type size
    # where truncation, header/banner collision and reorder churn actually show up.
    mkdir -p "$RUN/shots/dark-axl"
    sim_ui dark "$SIZE_AXL"
    local shot_count=0
    for snapshot in "${snapshots[@]}"; do
        local name
        name=$(basename "$snapshot" .json)
        if shoot_snapshot "$snapshot" "$RUN/shots/dark-axl/$name.png"; then
            shot_count=$((shot_count + 1))
        fi
    done
    echo "labor-sim: $shot_count dark/AXL shots"
    # Every snapshot gets a shot, so any shortfall fails the stage below. `simctl io
    # screenshot` fails on a two-display device (the iPhone Duo, which newest-sim.sh
    # picks once it is the newest runtime's only iPhone) unless told which display,
    # and that failure is silent per shot. When nothing could be shot at all, the
    # assertion and the sampled sweeps are skipped: they would photograph nothing too.
    local shots_taken=true assert_ok=true sweeps_ok=true
    if [ "$shot_count" -lt "${#snapshots[@]}" ]; then
        shots_taken=false
        echo "labor-sim: $shot_count of ${#snapshots[@]} dark/AXL shots taken on $SIM" >&2
    fi
    if [ "$shot_count" -eq 0 ]; then
        echo "labor-sim: no screenshot could be taken — if $SIM has two displays, set HUSHLIGHT_SIM to a single-display iPhone" >&2
    else

        # F-0023: verify expectedFacts against the accessibility tree while still on the
        # dark/AXL sweep (RUBRIC's primary pass) — see assert_pass below for why this is
        # one xcodebuild invocation rather than one per snapshot. Failure is captured
        # rather than returned immediately: an early `return 1` here would skip the
        # light/medium sweep *and* the exit-path wipe below, leaving the simulator mid
        # labor. The failure still reaches the caller, once cleanup has actually run.
        if ! assert_pass; then
            assert_ok=false
        fi

        # The AX5 sweep, sampled. AXL is where the reflow *starts*; AX5 is where the
        # header, the readout and the verdict have all taken their stacked branches at
        # once, and it is the size `LayoutInvariantTests` asserts against — a gallery for
        # it means a human can see what those assertions are describing.
        sampled_sweep dark "$SIZE_AX5" dark-ax5 "$DARK_AX5_COUNT" "${snapshots[@]}" || sweeps_ok=false

        # The secondary sweep. **`large`, not `medium`** — `medium` is one notch below the
        # system default, so until SP-195 phase 4 every "light + default type" claim in
        # this harness was made one size small. The directory name stays `light-m` so
        # earlier runs keep meaning what they meant.
        echo "labor-sim: light sweep at '$SIZE_DEFAULT' (the system default; earlier runs used 'medium', one notch below it)"
        sampled_sweep light "$SIZE_DEFAULT" light-m "$LIGHT_SWEEP_COUNT" "${snapshots[@]}" || sweeps_ok=false
    fi

    # The exit path, straight out of DemoSeed's own contract: a seeded pattern must
    # never outlive the pass. The simulator is left in the neutral state a human
    # would expect to find it in, not in whatever the last sweep set.
    xcrun simctl terminate "$SIM" "$BUNDLE_ID" >/dev/null 2>&1 || true
    xcrun simctl launch "$SIM" "$BUNDLE_ID" -seedLaborWipe -uitesting >/dev/null 2>&1 || true
    sleep 2
    xcrun simctl terminate "$SIM" "$BUNDLE_ID" >/dev/null 2>&1 || true
    sim_ui light "$SIZE_DEFAULT"

    if ! $assert_ok; then
        echo "labor-sim: NOTE — dark/AXL expectedFacts assertion failed; see $RUN/shots/fact-assertion.log" >&2
        return 1
    fi
    if ! $shots_taken || ! $sweeps_ok; then
        return 1
    fi
}

# ---------------------------------------------------------------------------
# Stage 2b — the shots-stage assertion (F-0023): expectedFacts against the
# accessibility tree, dark/AXL only
# ---------------------------------------------------------------------------

# One xcodebuild invocation drives HushlightUITests/SnapshotFactAssertionTests,
# which itself loops over every dark/AXL snapshot *in-process* against the binary
# `shots_pass` already installed above — the same "install once, vary the launch
# argument" discipline the screenshot loop uses, so this adds one xcodebuild
# startup to the stage rather than one per snapshot. `xcodebuild test` performs its
# own install/attach handshake on every invocation; paying that per snapshot (the
# shots loop covers dozens) is exactly the "tens of minutes" cost this design
# avoids. See SnapshotFactAssertionTests.swift's header for what is and is not
# asserted, and for how to invoke that test outside this script.
#
# The run directory reaches the simulator-hosted test process the same way the
# engine pass's ResultsWriter does (see ResultsWriter.pointerFileName): plain
# `export` never arrives there, so POINTER_FILE is the channel, reused as-is.
assert_pass() {
    echo
    echo "== shots: expectedFacts assertion (dark/AXL) =="
    printf '%s\n' "$RUN" > "$POINTER_FILE"
    set +e
    xcodebuild test -project Hushlight.xcodeproj -scheme Hushlight \
        -only-testing:HushlightUITests/SnapshotFactAssertionTests/testDarkAXLSnapshotsMatchExpectedFacts \
        -destination "$DESTINATION" \
        > "$RUN/shots/fact-assertion.log" 2>&1
    local status=$?
    set -e
    cleanup_pointer

    # Same BLOCKED convention as ui_pass: a runner that could not install or launch
    # is an environment fault, reported loudly, and does not fail the whole run —
    # the screenshots already taken above still stand as evidence.
    if grep -qE "EntityQueryP22displayRepresentations|Symbol not found|Failed to install|Unable to install|The test runner (never began|exited)|Lost connection to the test session|Early unexpected exit|failed to launch" \
        "$RUN/shots/fact-assertion.log"; then
        echo "labor-sim: fact assertion BLOCKED (SP-042a-class) — the runner could not install/launch the app."
        echo "  This is an environment fault, not a product failure; the screenshots above still stand."
        echo "  Evidence: $RUN/shots/fact-assertion.log"
        return 0
    fi

    # The silent-no-op trap, same reasoning as engine_pass's results-file count: if
    # the summary line never printed, the assertion process didn't run to completion
    # (pointer-file handover failure, crash mid-loop) and a bare exit code would read
    # as a clean pass having verified nothing.
    local summary
    summary=$(grep "SNAPSHOT ASSERTIONS:" "$RUN/shots/fact-assertion.log" | tail -1)
    if [ -z "$summary" ]; then
        echo "labor-sim: fact assertion produced no summary line — it did not run to completion" >&2
        echo "  Evidence: $RUN/shots/fact-assertion.log" >&2
        return 1
    fi
    echo "  $summary"

    if [ "$status" -eq 0 ]; then
        echo "labor-sim: fact assertion PASSED"
        return 0
    fi

    echo "labor-sim: fact assertion FAILED — expectedFacts did not match the accessibility tree" >&2
    grep -E "FACT MISS|NO ASSERTABLE FACTS|error:" "$RUN/shots/fact-assertion.log" | head -60 | sed 's/^/    /' >&2 || true
    return 1
}

# ---------------------------------------------------------------------------
# Stage 2c — the accessibility regression gate (SP-195 phase 4)
# ---------------------------------------------------------------------------

# Two legs, because the two questions want different sizes.
#
#   light + `large`  — the system default, and the leg that owns **contrast**. Small
#                      text is where contrast fails; this is the only size at which
#                      any of this screen's text is small.
#   dark  + AX5      — where the header, readout and verdict have all taken their
#                      stacked branches, and where `LayoutInvariantTests` has anything
#                      to assert. Contrast is dropped there (by the test itself, from
#                      the size it observes — see AccessibilityAuditTests.auditTypes):
#                      at AX5 nothing on this screen is under 18 pt, so a contrast run
#                      can only re-report a subset of what the default leg already
#                      judged, against the easier large-text bar.
#
# Each leg verifies the test's own `A11Y SIZE:` line names the size this script set —
# the same silent-no-op trap `engine_pass` and `assert_pass` carry, applied to the one
# thing a test process genuinely cannot control. `xcodebuild` has printed TEST SUCCEEDED
# over `Executed 0 tests` in every UI stage of this harness it has touched (F-0030), so
# the executed-count is checked too.
a11y_leg() {
    local appearance=$1 size=$2 name=$3
    shift 3
    local log="$RUN/a11y/$name.log"
    local expected
    expected=$(category_for_size "$size")
    if [ -z "$expected" ]; then
        echo "labor-sim: no UIContentSizeCategory mapping for '$size' — add one to category_for_size" >&2
        return 1
    fi

    echo
    echo "== a11y: $appearance / $size =="
    sim_ui "$appearance" "$size"

    local only=()
    local target
    for target in "$@"; do only+=("-only-testing:$target"); done

    set +e
    xcodebuild test -project Hushlight.xcodeproj -scheme Hushlight \
        "${only[@]}" -destination "$DESTINATION" > "$log" 2>&1
    local status=$?
    set -e

    # Same BLOCKED convention as ui_pass and assert_pass: a runner that could not
    # install or launch is an environment fault, reported loudly, and does not fail the
    # run on its own.
    if grep -qE "EntityQueryP22displayRepresentations|Symbol not found|Failed to install|Unable to install|The test runner (never began|exited)|Lost connection to the test session|Early unexpected exit|failed to launch" \
        "$log"; then
        echo "labor-sim: a11y leg '$name' BLOCKED (SP-042a-class) — the runner could not install/launch the app."
        echo "  Evidence: $log"
        return 0
    fi

    local executed
    executed=$(grep -oE "Executed [0-9]+ test" "$log" | tail -1 | grep -oE "[0-9]+" || true)
    if [ -z "${executed:-}" ] || [ "$executed" -eq 0 ]; then
        echo "labor-sim: a11y leg '$name' executed no tests — the bundle is not in the generated project." >&2
        echo "           Run 'xcodegen generate'. This is F-0030, exactly." >&2
        return 1
    fi

    local observed
    observed=$(grep -o "A11Y SIZE: [A-Za-z]*" "$log" | tail -1 | awk '{print $3}')
    if [ -z "${observed:-}" ]; then
        echo "labor-sim: a11y leg '$name' printed no 'A11Y SIZE:' line — it did not run to completion" >&2
        echo "  Evidence: $log" >&2
        return 1
    fi
    if [ "$observed" != "$expected" ]; then
        echo "labor-sim: a11y leg '$name' ran at '$observed' but this script set '$size' ($expected)." >&2
        echo "           The leg proved nothing about the size it claims. Evidence: $log" >&2
        return 1
    fi
    echo "  size confirmed by the runner: $observed ($executed test(s) executed)"

    grep -E "^A11Y\[|^A11Y AUDITED:|^LAYOUT\[" "$log" | sed 's/^/  /' || true

    if [ "$status" -eq 0 ]; then
        echo "labor-sim: a11y leg '$name' PASSED (zero findings, zero suppressions)"
        return 0
    fi
    echo "labor-sim: a11y leg '$name' FAILED" >&2
    grep -E "error:|XCTAssert" "$log" | head -30 | sed 's/^/    /' >&2 || true
    return 1
}

a11y_pass() {
    mkdir -p "$RUN/a11y"
    local ok=true
    if ! a11y_leg light "$SIZE_DEFAULT" default HushlightUITests/AccessibilityAuditTests; then
        ok=false
    fi
    if ! a11y_leg dark "$SIZE_AX5" ax5 \
        HushlightUITests/AccessibilityAuditTests \
        HushlightUITests/LayoutInvariantTests; then
        ok=false
    fi
    sim_ui light "$SIZE_DEFAULT"
    $ok
}

# ---------------------------------------------------------------------------
# Stage 3 — the interaction script (XCUITest)
# ---------------------------------------------------------------------------

# Same reporting stance as scripts/test.sh's app-target block: a runner that cannot
# install or launch is BLOCKED, loudly, and does not fail the whole run. A suite that
# quietly stops covering the app is worse than one that says it cannot.
ui_pass() {
    echo
    echo "== ui =="
    mkdir -p "$RUN/ui"
    set +e
    # The two diagnostics are skipped by name, not by accident (HL-019, SP-195). Both
    # assert nothing and exist to be read by a person chasing a parked audit finding:
    # `SmallTargetDiagnostics` browses the live tree, `DynamicTypeAuditDiagnostics` runs
    # the one audit category the gate excludes. Letting either ride the harness would
    # spend minutes per run printing a wall nobody asked for and — worse — make files
    # that deliberately cannot fail look like part of a gate that can.
    xcodebuild test -project Hushlight.xcodeproj -scheme Hushlight \
        -only-testing:HushlightUITests \
        -skip-testing:HushlightUITests/SmallTargetDiagnostics \
        -skip-testing:HushlightUITests/DynamicTypeAuditDiagnostics \
        -destination "$DESTINATION" \
        > "$RUN/ui/ui-test.log" 2>&1
    local status=$?
    set -e

    grep -E "Test Case .*(passed|failed)" "$RUN/ui/ui-test.log" \
        | sed -E 's/.*ContractionMechanicsTests (test[A-Za-z0-9_]+)\]. (passed|failed).*/  \2  \1/' || true

    if [ "$status" -eq 0 ]; then
        echo "UI PASSED"
        return 0
    fi

    if grep -qE "EntityQueryP22displayRepresentations|Symbol not found|Failed to install|Unable to install|The test runner (never began|exited)|Lost connection to the test session|Early unexpected exit|failed to launch" \
        "$RUN/ui/ui-test.log"; then
        echo "BLOCKED (SP-042a-class) — the runner could not install/launch the app."
        echo "  This is an environment fault, not a product failure; the engine and shots"
        echo "  stages above still stand. Evidence: $RUN/ui/ui-test.log"
        grep -E "error:|Symbol not found|Failed to install|Unable to install" \
            "$RUN/ui/ui-test.log" | head -5 | sed 's/^/    /' || true
        return 0
    fi

    echo "UI FAILED"
    grep -E "error:|XCTAssert" "$RUN/ui/ui-test.log" | head -15 | sed 's/^/    /' || true
    return 0
}

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------

# Explicit `if` rather than `cmd && stage`: under `set -e` a short-circuited AND list
# is exempt by the letter of the manual, and relying on that reading to decide whether
# a QA run continues is exactly the kind of cleverness that silently skips a stage.
ENGINE_OK=true
if $DO_ENGINE; then engine_pass; fi

SHOTS_OK=true
if $DO_SHOTS; then
    if ! shots_pass; then
        SHOTS_OK=false
        echo "labor-sim: shots stage did not complete — the report will say so" >&2
    fi
fi

if $DO_UI; then ui_pass; fi

A11Y_OK=true
if $DO_A11Y; then
    if ! a11y_pass; then
        A11Y_OK=false
        echo "labor-sim: accessibility gate did not pass — the report will say so" >&2
    fi
fi

echo
echo "== report =="
swift scripts/labor-report.swift "$RUN"
echo
if ! $ENGINE_OK; then
    echo "labor-sim: NOTE — the engine tests failed; see $RUN/engine.log."
fi
if ! $SHOTS_OK; then
    echo "labor-sim: NOTE — the shots stage did not complete; the gallery is partial."
fi
if ! $A11Y_OK; then
    echo "labor-sim: NOTE — the accessibility gate failed; see $RUN/a11y/*.log."
fi
echo "labor-sim: $RUN/report.md"

# The report is written either way — a partial run's evidence is still evidence — but
# the exit code tells the truth about whether the gates held. Nothing consumed this
# script's status before, which is how a run whose fact assertion had never executed
# could read as a clean pass (F-0030).
if ! $ENGINE_OK || ! $SHOTS_OK || ! $A11Y_OK; then
    exit 1
fi
