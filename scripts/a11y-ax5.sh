#!/bin/bash
# The contraction timer's accessibility gate at AX5, on a simulator of its own.
#
#   ./scripts/a11y-ax5.sh
#
# Runs `HushlightUITests/AccessibilityAuditTests` (Apple's audit, zero suppressions)
# and `HushlightUITests/LayoutInvariantTests` (the stacked-branch geometry contract)
# at dark + accessibility-extra-extra-extra-large.
#
# **Why this exists as a separate script from scripts/labor-sim.sh's own a11y stage.**
# CI runs this gate as well as a developer machine (SP-042a is closed — the legs
# run locally now). CI has no long-lived simulator to point at, and
# content size is a **device-wide** setting: leaving AX5 on a shared runner would
# silently re-size every later job on that machine. So this script creates its own
# device and deletes it on every exit path, and the trap is the load-bearing part.
set -euo pipefail

cd "$(dirname "$0")/.."

DEVICE_NAME="hushlight-a11y-ax5-$$"
DEVICE_TYPE=${HUSHLIGHT_A11Y_DEVICE_TYPE:-com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro}
CONTENT_SIZE=accessibility-extra-extra-extra-large
# `UIContentSizeCategory.accessibilityExtraExtraExtraLarge.rawValue`. The tests print
# what they actually observe; this is what they must print.
EXPECTED_CATEGORY=UICTContentSizeCategoryAccessibilityXXXL

UDID=""
cleanup() {
    if [ -n "$UDID" ]; then
        xcrun simctl shutdown "$UDID" >/dev/null 2>&1 || true
        xcrun simctl delete "$UDID" >/dev/null 2>&1 || true
        echo "a11y-ax5: deleted $DEVICE_NAME ($UDID)"
    fi
}
trap cleanup EXIT

# Newest available iOS runtime rather than a pinned version string: the runner image
# names its runtime with a build suffix, and hard-coding "iOS-27-0" has broken on every
# image bump so far.
#
# HUSHLIGHT_A11Y_RUNTIME overrides it with a version prefix — "18", "18.5", "26.4" —
# matched against the available runtimes. HL-039 needs the audit run *below* the newest,
# because the floor is iOS 18.0 (decision 0053) and every AX5 leg on record had been
# taken on 26 or 27. Newest stays the default: that is what CI should audit.
RUNTIME=$(HUSHLIGHT_A11Y_RUNTIME="${HUSHLIGHT_A11Y_RUNTIME:-}" xcrun simctl list runtimes -j \
    | /usr/bin/python3 -c '
import json, os, sys
want = os.environ.get("HUSHLIGHT_A11Y_RUNTIME", "").strip()
runtimes = [r for r in json.load(sys.stdin)["runtimes"]
            if r.get("isAvailable") and r.get("platform") == "iOS"]
runtimes.sort(key=lambda r: [int(p) for p in r["version"].split(".")])
if want:
    runtimes = [r for r in runtimes
                if r["version"] == want or r["version"].startswith(want + ".")]
print(runtimes[-1]["identifier"] if runtimes else "")')

if [ -z "$RUNTIME" ]; then
    echo "a11y-ax5: no available iOS simulator runtime${HUSHLIGHT_A11Y_RUNTIME:+ matching '$HUSHLIGHT_A11Y_RUNTIME'}" >&2
    exit 1
fi

UDID=$(xcrun simctl create "$DEVICE_NAME" "$DEVICE_TYPE" "$RUNTIME")
echo "a11y-ax5: created $DEVICE_NAME ($UDID) on $RUNTIME"
xcrun simctl bootstatus "$UDID" -b

xcrun simctl ui "$UDID" appearance dark
xcrun simctl ui "$UDID" content_size "$CONTENT_SIZE"

LOG=$(mktemp -t a11y-ax5)
set +e
xcodebuild test -project Hushlight.xcodeproj -scheme Hushlight \
    -only-testing:HushlightUITests/AccessibilityAuditTests \
    -only-testing:HushlightUITests/LayoutInvariantTests \
    -destination "platform=iOS Simulator,id=$UDID" > "$LOG" 2>&1
status=$?
set -e

grep -E "^A11Y|^LAYOUT\[" "$LOG" | sed 's/^/  /' || true

# The silent-no-op trap, three-for-three in this repository: `xcodebuild` prints
# TEST SUCCEEDED over `Executed 0 tests` whenever a test file was added without a
# subsequent `xcodegen generate` (F-0030). An affirmative count is the only thing that
# has ever caught it.
executed=$(grep -oE "Executed [0-9]+ test" "$LOG" | tail -1 | grep -oE "[0-9]+" || true)
if [ -z "${executed:-}" ] || [ "$executed" -eq 0 ]; then
    echo "a11y-ax5: executed no tests — the bundle is missing from the generated project." >&2
    echo "          Did 'xcodegen generate' run? This is F-0030." >&2
    tail -40 "$LOG" >&2
    exit 1
fi

# And the size trap: a test process cannot set the device's content size, so the only
# proof this ran at AX5 is the runner saying so.
observed=$(grep -o "A11Y SIZE: [A-Za-z]*" "$LOG" | tail -1 | awk '{print $3}' || true)
if [ "${observed:-}" != "$EXPECTED_CATEGORY" ]; then
    echo "a11y-ax5: ran at '${observed:-<no A11Y SIZE line>}', expected $EXPECTED_CATEGORY." >&2
    echo "          The gate proved nothing about the size it claims." >&2
    exit 1
fi
echo "a11y-ax5: size confirmed by the runner: $observed ($executed test(s) executed)"

if [ "$status" -ne 0 ]; then
    echo "a11y-ax5: FAILED"
    grep -E "error:|XCTAssert" "$LOG" | head -40 | sed 's/^/    /' || true
    exit "$status"
fi

echo "a11y-ax5: PASSED (zero findings, zero suppressions)"
