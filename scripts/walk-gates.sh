#!/bin/bash
# DESIGN-SPEC §8's visual gates, walked on a runtime you choose (HL-039).
#
# The app's floor dropped from iOS 27.0 to 18.0 (decision 0053) and every §8 walk on
# record had been taken on 26 or 27 — that is, entirely on Liquid Glass. Nothing about
# the floor change breaks a compile, but `.background(.bar)`, `.toolbar` chrome and
# sheet presentation all *look* different before 26, and "reads as the same design in
# both appearances" is a claim about pixels. This script gets the pixels, on whichever
# runtime you point it at, so the claim can be checked instead of assumed.
#
# It is the sibling of `scripts/pseudo-check.sh` and shares its shape deliberately: the
# same three seeded states, the same appearance loop, the same edge heuristic
# (`scripts/edge-scan.py`, one definition, called by both). The differences are that
# this one runs under **real copy** rather than the pseudolocale, and sweeps **two
# content sizes** rather than one, because §8 asks for the default reading and the XL
# one and a floor change can break either.
#
# LOCAL-ONLY, the same standing as `labor-sim.sh` and `pseudo-check.sh`: it owns a
# simulator for a few minutes. Never wired into `test.sh` or CI. It does not fail on
# its own findings — §8 gate 1 is a person looking at two directories side by side,
# and this script's whole job is to make that comparison cheap.
#
#   HUSHLIGHT_SIM=<udid> ./scripts/walk-gates.sh     # a specific device
#   ./scripts/walk-gates.sh                          # the newest installed iPhone
#
# To compare two runtimes, run it once against each and diff the two `shots/`
# directories by eye. That comparison is the point; a single run is just pictures.
set -euo pipefail

cd "$(dirname "$0")/.."
REPO_ROOT=$(pwd)

if [ -z "${HUSHLIGHT_SIM:-}" ]; then
    HUSHLIGHT_SIM=$(./scripts/newest-sim.sh "iPhone")
fi
if [ -z "${HUSHLIGHT_SIM:-}" ]; then
    echo "walk-gates: no iPhone simulator available; set HUSHLIGHT_SIM" >&2
    exit 1
fi
SIM=$HUSHLIGHT_SIM
BUNDLE_ID=net.wainright.hushlight

# The same tokens `labor-sim.sh` and `pseudo-check.sh` use, named the same way, so
# "XL" means one thing across all three.
SIZE_AXL=accessibility-extra-large
SIZE_DEFAULT=large

SETTLE_SECONDS=12

RUNTIME_LABEL=$(xcrun simctl list devices 2>/dev/null \
    | awk -v sim="$SIM" '/^-- /{r=$0} index($0, sim){print r; exit}' \
    | sed 's/^-- //; s/ --$//')
RUNTIME_LABEL=${RUNTIME_LABEL:-unknown-runtime}
SLUG=$(printf '%s' "$RUNTIME_LABEL" | tr ' .' '--')

RUN="$REPO_ROOT/build/walk-gates/$(date -u +%Y%m%dT%H%M%SZ)-$SLUG"
mkdir -p "$RUN/shots"
echo "walk-gates: run $RUN"
echo "walk-gates: sim $SIM ($RUNTIME_LABEL)"

sim_ui() {
    xcrun simctl ui "$SIM" appearance "$1" >/dev/null 2>&1 || true
    xcrun simctl ui "$SIM" content_size "$2" >/dev/null 2>&1 || true
}

# Leave the device as it was found. A simulator left at AX5 in dark silently re-sizes
# every later job on this machine — `a11y-ax5.sh` makes the same point at more length.
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
    echo "walk-gates: Hushlight.app not found in DerivedData" >&2
    exit 1
fi

xcrun simctl bootstatus "$SIM" -b >/dev/null 2>&1 || xcrun simctl boot "$SIM"
xcrun simctl terminate "$SIM" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl uninstall "$SIM" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl install "$SIM" "$APP"

# **A warm-up launch, and it is load-bearing.** The first launch after an install pays
# for first-run work the later ones do not, and on a freshly created device the very
# first capture caught `TimerScreen`'s bottom `safeAreaInset` *mid-placement* — the
# pinned Start slab drawn at the top-left, clipped, overlapping the header. It looks
# exactly like a broken layout and it is not one: re-shot after a warm launch, the same
# state on the same runtime renders correctly. Padding every shot would hide it behind
# a bigger number; this pays the cost once, where it actually falls.
echo "walk-gates: warm-up launch (the first launch after install is not representative)"
xcrun simctl launch "$SIM" "$BUNDLE_ID" -seedLaborWipe -uitesting >/dev/null 2>&1 || true
sleep "$SETTLE_SECONDS"
xcrun simctl terminate "$SIM" "$BUNDLE_ID" >/dev/null 2>&1 || true

# state name -> DemoSeed launch flag (decision 0021's fixtures; see DemoSeed.swift).
STATE_NAMES=(511 young wipe)
STATE_FLAGS=(-seedLabor511 -seedLaborYoung -seedLaborWipe)

# A missed shot costs one cell of the grid; aborting costs the other eleven and the five
# minutes already spent. So every path here returns 0 and the miss is counted instead.
# That is deliberate rather than lazy: under `set -e` a bare `return 1` from a function
# called plainly in a loop ends the whole script, so "report and carry on" has to be
# written as returning success, not as returning an error nobody catches.
#
# The screenshot is checked rather than assumed: `simctl io` can fail while the device
# is busy, and a silenced failure that still printed its success line would leave
# `edge-scan.py` quietly scanning eleven images and reporting nothing wrong.
shoot() {
    local label=$1 name=$2 flag=$3 out=$4
    xcrun simctl terminate "$SIM" "$BUNDLE_ID" >/dev/null 2>&1 || true
    if ! xcrun simctl launch "$SIM" "$BUNDLE_ID" "$flag" -uitesting >/dev/null 2>&1; then
        echo "  $label/$name -> LAUNCH FAILED (skipped)" >&2
        MISSED=$((MISSED + 1))
        return 0
    fi
    sleep "$SETTLE_SECONDS"
    if ! xcrun simctl io "$SIM" screenshot "$out" >/dev/null 2>&1 || [ ! -s "$out" ]; then
        echo "  $label/$name -> SCREENSHOT FAILED (skipped)" >&2
        MISSED=$((MISSED + 1))
        return 0
    fi
    echo "  $label/$name -> $(basename "$out")"
}

MISSED=0

echo
echo "== shots: {dark,light} x {default,XL} x {511,young,wipe} =="
for appearance in dark light; do
    for size_name in default axl; do
        case "$size_name" in
            default) size=$SIZE_DEFAULT ;;
            axl)     size=$SIZE_AXL ;;
        esac
        label="$appearance-$size_name"
        mkdir -p "$RUN/shots/$label"
        sim_ui "$appearance" "$size"
        for i in "${!STATE_NAMES[@]}"; do
            shoot "$label" "${STATE_NAMES[$i]}" "${STATE_FLAGS[$i]}" \
                "$RUN/shots/$label/${STATE_NAMES[$i]}.png"
        done
    done
done

# Leave the store empty rather than holding a seeded fixture: the next person to open
# this simulator by hand should not find someone else's labor in it.
xcrun simctl terminate "$SIM" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl launch "$SIM" "$BUNDLE_ID" -seedLaborWipe -uitesting >/dev/null 2>&1 || true
sleep 2
xcrun simctl terminate "$SIM" "$BUNDLE_ID" >/dev/null 2>&1 || true

echo
echo "== automated first pass: does anything touch the screen edge? =="
python3 ./scripts/edge-scan.py "$RUN"

printf '%s\n' "$RUNTIME_LABEL" > "$RUN/runtime.txt"
echo
if [ "$MISSED" -gt 0 ]; then
    echo "walk-gates: $MISSED of 12 shots MISSED — the comparison below is incomplete." >&2
fi
echo "walk-gates: shots in $RUN/shots"
echo "walk-gates: this script does not fail on its own findings — look at them, and"
echo "            diff them against a run on another runtime (§8 gate 1)."
