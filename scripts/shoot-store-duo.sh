#!/bin/bash
# HL-064: the iPhone Duo store set — three raw captures per language, one per pose.
#
#   ./scripts/shoot-store-duo.sh cover            # English, closed
#   ./scripts/shoot-store-duo.sh tabletop ja      # Japanese, half open
#   ./scripts/shoot-store-duo.sh open all         # English and the eight others, open flat
#
# **The pose comes first, from a person.** Nothing in XCTest or simctl folds a simulated
# Duo (decision 0066); Device Hub's hinge control does. Pose the "iPhone Duo" simulator —
# closed for `cover`, half open with the fold across for `tabletop`, flat for `open` —
# then run the matching shot. `HushlightUITests/StoreShotsDuo` asserts the layout the
# pose produces and fails, naming the pose, when the device is in another one.
#
# The capture is whichever display the pose lights: 1398×2034 from the outer, 2007×2853
# from the inner — both iPhone Duo slots in App Store Connect. `make-store-frames.swift`
# frames them from spec-duo.json (and spec-duo/<lang>.json). The App Store Connect API
# has no Duo display type yet, so frames-duo/ is uploaded by hand.
set -euo pipefail
cd "$(dirname "$0")/.."

DEVICE_NAME=${HUSHLIGHT_DUO_DEVICE_NAME:-iPhone Duo}
OUT_ROOT=docs/design/hushlight/store/raw-duo
LANGS=(es fr de it pt-BR ja ko zh-Hans)
DERIVED=build/store-duo

POSE=${1:-}
case "$POSE" in
    cover)    TEST=testCoverShot;    APPEARANCE=light ;;
    tabletop) TEST=testTabletopShot; APPEARANCE=dark ;;
    open)     TEST=testOpenShot;     APPEARANCE=light ;;
    *) echo "shoot-store-duo: first argument is the pose — cover, tabletop or open" >&2; exit 2 ;;
esac
shift
resolve_device() {
    local udid
    udid=$(xcrun simctl list devices available -j | /usr/bin/python3 -c '
import json, sys
want = sys.argv[1]
devs = [d for rt in json.load(sys.stdin)["devices"].values() for d in rt
        if d.get("isAvailable") and d["name"].startswith(want)]
devs.sort(key=lambda d: (d.get("state") != "Booted", d["name"]))
print(devs[0]["udid"] if devs else "")' "$DEVICE_NAME")
    if [ -z "$udid" ]; then
        echo "shoot-store-duo: no simulator named '$DEVICE_NAME…'" >&2; exit 1
    fi
    echo "$udid"
}

# An unknown language has to fail before the build, not capture English into a folder
# named for a typo — the same rule shoot-store.sh applies (HL-048).
case "${1:-}" in
    ""|all) ;;
    *)  known=no; for l in "${LANGS[@]}"; do [ "$l" = "$1" ] && known=yes; done
        [ "$known" = yes ] || { echo "shoot-store-duo: unknown language '$1' (one of: ${LANGS[*]}, or 'all')" >&2; exit 2; } ;;
esac

SIM=$(resolve_device)
xcrun simctl boot "$SIM" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$SIM" -b >/dev/null
echo "shoot-store-duo: $SIM"

# Whatever happens after this point — a failed build, test, export or rotation — the
# simulator is handed back with its own clock and appearance, not 9:41 in the dark.
restore() {
    xcrun simctl status_bar "$SIM" clear >/dev/null 2>&1 || true
    xcrun simctl ui "$SIM" appearance light >/dev/null 2>&1 || true
}
trap restore EXIT

# Built once. `xcodegen` first so a new test file is in the project (F-0030).
xcodegen generate >/dev/null
xcodebuild build-for-testing -project Hushlight.xcodeproj -scheme Hushlight \
    -destination "platform=iOS Simulator,id=$SIM" -derivedDataPath "$DERIVED" -quiet

shoot() {
    local lang=$1
    local out=$OUT_ROOT; [ -n "$lang" ] && out=$OUT_ROOT/$lang
    mkdir -p "$out"
    xcrun simctl ui "$SIM" appearance "$APPEARANCE"
    xcrun simctl status_bar "$SIM" override --time 9:41 --batteryState charged --batteryLevel 100 \
        --wifiBars 3 --cellularBars 4 --operatorName "" >/dev/null
    local scratch; scratch=$(mktemp -d -t store-duo)
    local result=$scratch/run.xcresult log=$scratch/xcodebuild.log
    if ! STORE_LANG="$lang" TEST_RUNNER_STORE_LANG="$lang" xcodebuild test-without-building \
        -project Hushlight.xcodeproj -scheme Hushlight -derivedDataPath "$DERIVED" \
        -only-testing:"HushlightUITests/StoreShotsDuo/$TEST" \
        -destination "platform=iOS Simulator,id=$SIM" -resultBundlePath "$result" \
        > "$log" 2>&1; then
        echo "shoot-store-duo: $TEST failed for '${lang:-en}' — $log" >&2
        grep -E "error: -\[|error:|Executed [0-9]+ test" "$log" | grep -v warning | tail -4 >&2
        return 1
    fi
    local export; export=$(mktemp -d -t store-duo-export)
    xcrun xcresulttool export attachments --path "$result" --output-path "$export" >/dev/null
    local png; png=$(ls "$export"/*.png 2>/dev/null | head -1 || true)
    [ -n "$png" ] || { echo "shoot-store-duo: the result bundle carried no screenshot" >&2; return 1; }
    cp "$png" "$out/duo-$POSE.png"
    echo "shoot-store-duo: $out/duo-$POSE.png ($(sips -g pixelWidth -g pixelHeight "$out/duo-$POSE.png" | awk '/pixel/ {printf "%s ", $2}'))"
}

case "${1:-}" in
    "")   shoot "" ;;
    all)  shoot ""; for l in "${LANGS[@]}"; do shoot "$l"; done ;;
    *)    shoot "$1" ;;
esac
echo "shoot-store-duo: done"
