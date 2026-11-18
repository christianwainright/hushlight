#!/bin/bash
# HL-058c: the iPad store set — two raw captures per language, on a 13" iPad Pro.
#
#   ./scripts/shoot-store-ipad.sh            # English into docs/design/hushlight/store/raw-ipad/
#   ./scripts/shoot-store-ipad.sh ja         # one language into raw-ipad/ja/
#   ./scripts/shoot-store-ipad.sh all        # English and the eight others
#
# `HushlightUITests/StoreShotsPad` drives the app (rotation needs XCUIDevice; simctl has
# no touch or orientation injection — the HL-048 reason), this script sets what a test
# cannot: appearance per shot (Hand is light, Stand is dark, the mix the iPhone set
# uses), the 9:41 status bar, and the device. Built once, then test-without-building
# per language, so eighteen runs cost one compile.
#
# The 13" slot is the one App Store Connect requires for an iPad app; the capture is
# 2064×2752, which that slot accepts. `make-store-frames.swift` frames it from
# spec-ipad.json (and spec-ipad/<lang>.json).
set -euo pipefail
cd "$(dirname "$0")/.."

# By name, not type identifier: the identifiers carry memory-size suffixes that differ
# between Xcode releases ("…-M5-12GB", "…-M5-16GB"); the name is the part that says 13".
DEVICE_NAME=${HUSHLIGHT_PAD_DEVICE_NAME:-iPad Pro 13-inch}
OUT_ROOT=docs/design/hushlight/store/raw-ipad
LANGS=(es fr de it pt-BR ja ko zh-Hans)
DERIVED=build/store-ipad

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
        echo "shoot-store-ipad: no simulator named '$DEVICE_NAME…'" >&2; exit 1
    fi
    echo "$udid"
}

# An unknown language has to fail before the build, not capture English into a folder
# named for a typo — the same rule shoot-store.sh applies (HL-048).
case "${1:-}" in
    ""|all) ;;
    *)  known=no; for l in "${LANGS[@]}"; do [ "$l" = "$1" ] && known=yes; done
        [ "$known" = yes ] || { echo "shoot-store-ipad: unknown language '$1' (one of: ${LANGS[*]}, or 'all')" >&2; exit 2; } ;;
esac

SIM=$(resolve_device)
xcrun simctl boot "$SIM" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$SIM" -b >/dev/null
echo "shoot-store-ipad: $SIM"

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
    local lang=$1 test=$2 appearance=$3 name=$4
    local out=$OUT_ROOT; [ -n "$lang" ] && out=$OUT_ROOT/$lang
    mkdir -p "$out"
    xcrun simctl ui "$SIM" appearance "$appearance"
    xcrun simctl status_bar "$SIM" override --time 9:41 --batteryState charged --batteryLevel 100 \
        --wifiBars 3 --cellularBars 4 --operatorName "" >/dev/null
    local scratch; scratch=$(mktemp -d -t store-ipad)
    local result=$scratch/run.xcresult log=$scratch/xcodebuild.log
    if ! STORE_LANG="$lang" TEST_RUNNER_STORE_LANG="$lang" xcodebuild test-without-building \
        -project Hushlight.xcodeproj -scheme Hushlight -derivedDataPath "$DERIVED" \
        -only-testing:"HushlightUITests/StoreShotsPad/$test" \
        -destination "platform=iOS Simulator,id=$SIM" -resultBundlePath "$result" \
        > "$log" 2>&1; then
        echo "shoot-store-ipad: $test failed for '${lang:-en}' — $log" >&2
        grep -E "error: -\[|error:|Executed [0-9]+ test" "$log" | grep -v warning | tail -4 >&2
        return 1
    fi
    local export; export=$(mktemp -d -t store-ipad-export)
    xcrun xcresulttool export attachments --path "$result" --output-path "$export" >/dev/null
    local png; png=$(ls "$export"/*.png 2>/dev/null | head -1 || true)
    [ -n "$png" ] || { echo "shoot-store-ipad: the result bundle carried no screenshot" >&2; return 1; }
    cp "$png" "$out/$name.png"
    # `XCUIScreen.main.screenshot()` on an iPad hands back the framebuffer in its
    # portrait pixel order whatever the interface orientation, so the landscape shot
    # arrives lying on its side. A quarter turn puts the status bar back on top.
    if [ "$test" = testStandShot ]; then
        sips -r -90 "$out/$name.png" >/dev/null
    fi
    echo "shoot-store-ipad: $out/$name.png ($(sips -g pixelWidth -g pixelHeight "$out/$name.png" | awk '/pixel/ {printf "%s ", $2}'))"
}

shoot_language() {
    local lang=$1
    shoot "$lang" testHandShot  light pad-hand
    shoot "$lang" testStandShot dark  pad-stand
}

case "${1:-}" in
    "")   shoot_language "" ;;
    all)  shoot_language ""; for l in "${LANGS[@]}"; do shoot_language "$l"; done ;;
    *)    shoot_language "$1" ;;
esac
echo "shoot-store-ipad: done"
