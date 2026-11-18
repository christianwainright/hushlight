#!/bin/bash
# HL-006's pseudolocale leg: the German/Finnish stress test, without waiting for a
# translation to exist.
#
# Xcode's built-in "double-length pseudolanguage" needs no catalog entries at all —
# `-AppleLanguages (xx)` asks for a language nothing resolves to (so every lookup
# falls back to the base `en` value, catalog or not) and `-NSDoubleLocalizedStrings
# YES` then takes whatever string Foundation/SwiftUI actually resolved and expands
# it to roughly double length with accented characters substituted in. That is
# simultaneously the "~40%-expanded" and the "accented" leg the backlog item asks
# for, from one pair of launch arguments, against strings that do not need to be
# translated yet to be stressed.
#
# Screenshots only, across the three seeded states this repo already has DemoSeed
# scenarios for — 511 (a met textbook pattern), young (a partial, early one), wipe
# (the empty install) — at XL (`accessibility-extra-large`, the size
# `scripts/labor-sim.sh` calls "where the reflow starts"), both appearances: the
# same primary-plus-sweep sizes DESIGN-SPEC §8 already asks for, run once more
# under expansion instead of under real copy.
#
# LOCAL-ONLY, the same standing as scripts/labor-sim.sh: it
# drives a real simulator for a couple of minutes and owns the device while it
# runs. Never wired into scripts/test.sh or CI — `scripts/gate.sh` calls
# scripts/lint-localizable.sh for the automatic, always-on half of this item;
# this half is a look-at-the-screenshots tool, run by hand.
#
# What this script does NOT do, and why: it does not drive
# `HushlightUITests/LayoutInvariantTests` under the pseudo launch arguments. That
# suite's app instance is launched by XCUITest's own runner, which reads launch
# arguments from the test code (`XCUIApplication().launchArguments`), and adding a
# pseudo-mode switch there would mean editing test code — out of this item's scope
# ("do not touch … test-fixture strings"). What it does instead: an automated edge
# heuristic (below) as a mechanical first pass, and a human look at the screenshots
# as the actual layout-invariant check, exactly as `scripts/labor-sim.sh`'s own
# screenshots are the thing a person looks at — this script gets you the pictures.
set -euo pipefail

# `--pseudo` is the item's own name for this leg of the §8 flow (HL-006 in
# BACKLOG.md) and is accepted as the explicit, self-documenting way to run it; the
# script has exactly one mode today, so a bare invocation does the same thing.
case "${1:-}" in
    --pseudo|"") ;;
    -h|--help)
        sed -n '2,35p' "$0" | sed 's/^# \{0,1\}//'
        exit 0
        ;;
    *)
        echo "pseudo-check: unknown flag $1 (only --pseudo is defined)" >&2
        exit 1
        ;;
esac

cd "$(dirname "$0")/.."
REPO_ROOT=$(pwd)

if [ -z "${HUSHLIGHT_SIM:-}" ]; then
    HUSHLIGHT_SIM=$(./scripts/newest-sim.sh "iPhone")
fi
if [ -z "${HUSHLIGHT_SIM:-}" ]; then
    echo "pseudo-check: no iPhone simulator available; set HUSHLIGHT_SIM" >&2
    exit 1
fi
SIM=$HUSHLIGHT_SIM
BUNDLE_ID=net.wainright.hushlight

# Same content-size tokens `labor-sim.sh` uses, named the same way, so "XL" means
# the same simulator setting in both places.
SIZE_AXL=accessibility-extra-large
SIZE_DEFAULT=large

SETTLE_SECONDS=8

RUN="$REPO_ROOT/build/pseudo-check/$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$RUN/shots"
echo "pseudo-check: run $RUN (sim $SIM)"

sim_ui() {
    xcrun simctl ui "$SIM" appearance "$1" >/dev/null 2>&1 || true
    xcrun simctl ui "$SIM" content_size "$2" >/dev/null 2>&1 || true
}

restore_simulator() {
    sim_ui light "$SIZE_DEFAULT"
}
trap restore_simulator EXIT

echo
echo "== build =="
./scripts/build.sh Hushlight >/dev/null
APP=$(find ~/Library/Developer/Xcode/DerivedData/Hushlight-*/Build/Products/Debug-iphonesimulator \
    -maxdepth 1 -name "Hushlight.app" 2>/dev/null | head -1)
if [ -z "$APP" ]; then
    echo "pseudo-check: Hushlight.app not found in DerivedData" >&2
    exit 1
fi

xcrun simctl bootstatus "$SIM" -b >/dev/null 2>&1 || xcrun simctl boot "$SIM"
xcrun simctl terminate "$SIM" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl uninstall "$SIM" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl install "$SIM" "$APP"

# state name -> DemoSeed launch flag (decision 0021's fixtures; see DemoSeed.swift).
STATE_NAMES=(511 young wipe)
STATE_FLAGS=(-seedLabor511 -seedLaborYoung -seedLaborWipe)

shoot() {
    local appearance=$1 name=$2 flag=$3 out=$4
    xcrun simctl terminate "$SIM" "$BUNDLE_ID" >/dev/null 2>&1 || true
    xcrun simctl launch "$SIM" "$BUNDLE_ID" \
        "$flag" -uitesting \
        -AppleLanguages '(xx)' -NSDoubleLocalizedStrings YES \
        >/dev/null 2>&1 || {
        echo "pseudo-check: launch failed for $appearance/$name" >&2
        return 1
    }
    sleep "$SETTLE_SECONDS"
    xcrun simctl io "$SIM" screenshot "$out" >/dev/null 2>&1
    echo "  $appearance/$name -> $(basename "$out")"
}

echo
echo "== shots (pseudolocale: -AppleLanguages (xx) -NSDoubleLocalizedStrings YES, XL) =="
for appearance in dark light; do
    mkdir -p "$RUN/shots/$appearance"
    sim_ui "$appearance" "$SIZE_AXL"
    for i in "${!STATE_NAMES[@]}"; do
        shoot "$appearance" "${STATE_NAMES[$i]}" "${STATE_FLAGS[$i]}" \
            "$RUN/shots/$appearance/${STATE_NAMES[$i]}.png"
    done
done

xcrun simctl terminate "$SIM" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl launch "$SIM" "$BUNDLE_ID" -seedLaborWipe -uitesting >/dev/null 2>&1 || true
sleep 2
xcrun simctl terminate "$SIM" "$BUNDLE_ID" >/dev/null 2>&1 || true

echo
echo "== automated first pass: does anything touch the screen edge? =="
# A mechanical, imperfect proxy for truncation; the real check is a human looking at
# the screenshots. Extracted to `scripts/edge-scan.py` under HL-039 so this leg and
# `scripts/walk-gates.sh` cannot drift into two different definitions of "touches the
# edge". It never fails the script — findings are printed for a human to read,
# matching the item's "fix nothing yourself" stance.
python3 ./scripts/edge-scan.py "$RUN"

echo
echo "pseudo-check: shots in $RUN/shots — look at them; this script does not fail on its own findings"
