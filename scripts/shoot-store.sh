#!/bin/bash
# App Store screenshot capture for Hushlight — the 6.9" raw set (SP-196, HL-037).
#
# This script produces the *raw* captures in docs/design/hushlight/store/raw/. The
# framed store screenshots and the app previews are built from them by
# scripts/make-store-frames.swift and scripts/make-store-preview.sh — the full recipe,
# including the tap-driven shots and the recordings, is docs/design/hushlight/store/README.md.
#
#   ./scripts/shoot-store.sh setup           # resolve device, build, install once,
#                                             # suppress How It Works, status bar 9:41
#   ./scripts/shoot-store.sh shot1           # 01 verdict met, dark     -seedLabor511 + a provider number
#   ./scripts/shoot-store.sh shot3           # 03 button at rest, light -seedLaborWipe
#   ./scripts/shoot-store.sh shot4           # 04 pattern building, dark -seedLaborYoung
#   ./scripts/shoot-store.sh nav timing      # stages 02 (mid-contraction) and 05 (lock screen)
#   ./scripts/shoot-store.sh nav history     # stages 06 — seeds + launches, leaves the app on
#                                             # Timer so "History" can be tapped
#   ./scripts/shoot-store.sh nav guidance    # stages 07 — for the "Guidance" tap
#   ./scripts/shoot-store.sh capture <name>  # screenshots whatever is on screen now
#   ./scripts/shoot-store.sh cleanup         # status bar clear, store wiped, neutral
#
# Why the tap shots are two steps instead of one: this Xcode's `simctl help io`
# offers only `screenshot`, `recordVideo` and `enumerate` — there is no touch
# injection in `simctl` at all — and HushlightUITests is app source, out of
# scope for this script to add a driver method to (Wave 5's brief is explicit:
# touch only this script and its output directory). So `nav <screen>` gets the app
# sitting on the right screen and prints where to tap; the tap itself is one human
# tap (or the iOS Simulator tool's tap at the printed point), then `capture` takes
# the shot the same way every other shot does. Shots 1, 3 and 4 need no tap at all.
#
# Deliberately NOT `scripts/labor-sim.sh` with different flags: that harness passes
# `-uitesting` to every shot, which freezes TimelineView (RuntimeFlags.swift) — the
# QA gates want a still tree to assert against, store shots want the app behaving
# normally. Reusing it would mean re-adding the one flag this script exists to drop.
set -euo pipefail

cd "$(dirname "$0")/.."

BUNDLE_ID=net.wainright.hushlight

# HL-048: the language the app is shot in. Empty means English, which keeps the
# original flat `raw/` layout so every existing path and the committed English frames
# stay where they were. Any other value shoots into `raw/<lang>/` and launches the app
# under `-AppleLanguages`, which is the same mechanism `pseudo-check.sh` uses for its
# double-length pass — the app resolves to that language exactly as it would on a
# phone set to it.
#
#   HUSHLIGHT_STORE_LANG=ja ./scripts/shoot-store.sh setup
#   HUSHLIGHT_STORE_LANG=ja ./scripts/shoot-store.sh shot1
#
# Frames are then composited per language from its own spec, which carries that
# language's captions:
#
#   swift scripts/make-store-frames.swift \
#       docs/design/hushlight/store/spec/ja.json docs/design/hushlight/store
STORE_LANG=${HUSHLIGHT_STORE_LANG:-}
OUT_DIR=docs/design/hushlight/store/raw${STORE_LANG:+/$STORE_LANG}
SETTLE_SECONDS=4

# The launch arguments that select the language, or nothing at all for English. A
# locale is set alongside the language so dates and numbers match the words — a
# Japanese screenshot carrying a US date reads as a half-translated app, which is the
# thing these shots exist to disprove.
#
# **Resolved once, here, not inside the launch helpers.** An unknown language has to
# fail before `setup` builds and installs anything: the first version of this checked
# lazily, and `HUSHLIGHT_STORE_LANG=nope setup` ran a full build and reported success
# on a simulator it had already changed.
LANG_ARGS=()
if [ -n "$STORE_LANG" ]; then
    case "$STORE_LANG" in
        es) STORE_LOCALE=es_ES ;; fr) STORE_LOCALE=fr_FR ;; de) STORE_LOCALE=de_DE ;;
        it) STORE_LOCALE=it_IT ;; pt-BR) STORE_LOCALE=pt_BR ;; ja) STORE_LOCALE=ja_JP ;;
        ko) STORE_LOCALE=ko_KR ;; zh-Hans) STORE_LOCALE=zh_CN ;;
        *)
            echo "shoot-store: unknown HUSHLIGHT_STORE_LANG '$STORE_LANG'" >&2
            echo "  expected one of: es fr de it pt-BR ja ko zh-Hans (or unset for English)" >&2
            exit 1
            ;;
    esac
    LANG_ARGS=(-AppleLanguages "($STORE_LANG)" -AppleLocale "$STORE_LOCALE")
fi
# Expanding an *empty* array with `"${LANG_ARGS[@]}"` is an "unbound variable" under
# `set -u` on the bash 3.2 macOS ships, so every English shot has failed since the
# language argument arrived — silently, because the callers discarded the exit code.
# `${arr[@]+"${arr[@]}"}` expands to nothing when the array is empty and to the quoted
# elements otherwise, on every bash. The localized shots worked because their array
# was never empty.

# The system default, never an accessibility size — DESIGN-SPEC's XL/AX5 gates are
# labor-sim.sh's job, not the storefront's.
SIZE=large

# ---------------------------------------------------------------------------
# Device — a 6.9" iPhone 17 Pro Max. $HUSHLIGHT_SIM (labor-sim.sh's variable)
# defaults to a 6.3" iPhone 17 Pro, which is the wrong shelf for this listing, so
# this script resolves its own device instead of reading that variable.
# ---------------------------------------------------------------------------
resolve_device() {
    if [ -n "${HUSHLIGHT_STORE_SIM:-}" ]; then
        SIM="$HUSHLIGHT_STORE_SIM"
        return
    fi
    # Newest available runtime (HL-038). A store shot should be taken under the OS
    # the reviewer and the buyer are actually running, which is the newest one
    # installed — not the iOS 27 this used to demand for a floor that no longer
    # exists. HUSHLIGHT_STORE_SIM pins a specific device when that matters.
    SIM=$(./scripts/newest-sim.sh "iPhone 17 Pro Max")
    if [ -z "$SIM" ]; then
        # No 6.9" device in the set: make one on the newest runtime installed. The
        # runtime identifier is resolved rather than spelled, because the old
        # hardcoded `iOS-27-0` here would fail on exactly the machine that needs
        # this branch — one that has never carried a beta.
        local runtime
        runtime=$(xcrun simctl list runtimes -j \
            | /usr/bin/python3 -c '
import json, sys
rs = [r for r in json.load(sys.stdin)["runtimes"]
      if r.get("isAvailable") and r.get("platform") == "iOS"]
rs.sort(key=lambda r: [int(p) for p in r["version"].split(".")])
print(rs[-1]["identifier"] if rs else "")')
        if [ -z "$runtime" ]; then
            echo "shoot-store: no available iOS simulator runtime" >&2
            exit 1
        fi
        echo "shoot-store: no iPhone 17 Pro Max available; creating one on $runtime" >&2
        SIM=$(xcrun simctl create "iPhone 17 Pro Max (store shots)" \
            com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max "$runtime")
    fi
}
resolve_device

sim_ui() {
    xcrun simctl ui "$SIM" appearance "$1" >/dev/null 2>&1 || true
    xcrun simctl ui "$SIM" content_size "$2" >/dev/null 2>&1 || true
}

app_path() {
    find ~/Library/Developer/Xcode/DerivedData/Hushlight-*/Build/Products/Debug-iphonesimulator \
        -maxdepth 1 -name "Hushlight.app" 2>/dev/null | head -1
}

# The night, on a daytime machine. The seeds anchor to the real clock, so a shot taken
# at 1pm reads "SINCE 12:11 PM" — the wrong room for a nightstand app. Launching the
# app in a time zone nine hours ahead (`SIMCTL_CHILD_TZ`, honoured by Foundation's
# TimeZone.current) turns an afternoon here into the small hours there, and the status
# bar is overridden to the same clock so the two agree. The lock screen's own clock
# cannot be moved and is not overridden — its shot never shows the status bar time.
STORE_TZ=${HUSHLIGHT_STORE_TZ:-Asia/Tokyo}

# **The overridden clock is always 12-hour, and nothing here can change that.**
# `--time` takes a moment, not a format: `16:38` comes back as `4:38`. Measured against
# every lever there is — the device language set to `de`, and `AppleICUForce24HourTime`
# forced on, each with a SpringBoard restart — the synthetic status bar `status_bar
# override` draws ignores both. So a German shot carries a 12-hour clock above the app's
# own 24-hour readout. The two agree on the moment (15:47 against a stretch that began
# at 14:39) and disagree on convention, which is a real if small tell, and the price of
# a curated status bar: full battery, full bars, and a 3am clock in a daytime room.
# Passing 24-hour in is still worth doing — it is unambiguous input, where a 12-hour
# string leaves the AM/PM to guesswork.
status_bar_now() {
    xcrun simctl status_bar "$SIM" override \
        --time "$(TZ=$STORE_TZ date +%-H:%M)" --batteryState charged --batteryLevel 100 \
        --cellularBars 4 --wifiBars 3 >/dev/null
}

# Launch with a seed and leave the app on Timer. Used by every shot and by the
# tap-driven steps in the README.
launch() {
    xcrun simctl terminate "$SIM" "$BUNDLE_ID" >/dev/null 2>&1 || true
    status_bar_now
    SIMCTL_CHILD_TZ=$STORE_TZ xcrun simctl launch "$SIM" "$BUNDLE_ID" "$@" ${LANG_ARGS[@]+"${LANG_ARGS[@]}"} >/dev/null
    sleep "$SETTLE_SECONDS"
}

# One launch -> one screenshot. No `-uitesting` — see the header. Same "terminate,
# launch with the scenario flag, settle, shoot" shape as labor-sim.sh's
# shoot_snapshot, minus the flag that harness needs and this one must not carry.
shoot() {
    local out=$1
    shift
    xcrun simctl terminate "$SIM" "$BUNDLE_ID" >/dev/null 2>&1 || true
    status_bar_now
    SIMCTL_CHILD_TZ=$STORE_TZ xcrun simctl launch "$SIM" "$BUNDLE_ID" "$@" ${LANG_ARGS[@]+"${LANG_ARGS[@]}"} >/dev/null
    sleep "$SETTLE_SECONDS"
    mkdir -p "$OUT_DIR"
    xcrun simctl io "$SIM" screenshot "$OUT_DIR/$out.png" >/dev/null 2>&1
    echo "shoot-store: $OUT_DIR/$out.png"
}

# **The simulator's own language, not just the app's.** `-AppleLanguages` is a launch
# argument and reaches exactly one process; three things a store shot needs are rendered
# by others:
#
#   * the **status bar clock**, which SpringBoard re-renders in the device locale — a
#     German app under an English device shows a 12-hour clock above its own 24-hour
#     readout, which is the same tell as a US date in a Japanese screenshot;
#   * the **Lock Screen date**, likewise SpringBoard's;
#   * the **Live Activity**, rendered by `HushlightWidgets`, a separate process the
#     system starts — a fully Japanese app showed an English "CONTRACTIONS / End" card
#     until the device language was set.
#
# So the device language is set here and restored in `cleanup`. SpringBoard is
# kickstarted rather than the simulator rebooted: seconds instead of a minute, and it
# picks the change up either way. The launch arguments stay as well — they cost nothing
# and they pin the app even if a device change has not settled.
set_device_language() {
    [ -z "$STORE_LANG" ] && return 0
    xcrun simctl spawn "$SIM" defaults write -g AppleLanguages -array "$STORE_LANG" >/dev/null 2>&1
    xcrun simctl spawn "$SIM" defaults write -g AppleLocale -string "$STORE_LOCALE" >/dev/null 2>&1
    xcrun simctl spawn "$SIM" launchctl kickstart -k system/com.apple.SpringBoard >/dev/null 2>&1
    sleep 14
}

restore_device_language() {
    xcrun simctl spawn "$SIM" defaults write -g AppleLanguages -array en-US >/dev/null 2>&1
    xcrun simctl spawn "$SIM" defaults write -g AppleLocale -string en_US >/dev/null 2>&1
    xcrun simctl spawn "$SIM" launchctl kickstart -k system/com.apple.SpringBoard >/dev/null 2>&1
}

cmd_setup() {
    mkdir -p "$OUT_DIR"
    xcrun simctl bootstatus "$SIM" -b >/dev/null 2>&1 || xcrun simctl boot "$SIM"
    set_device_language

    if ! ./scripts/build.sh Hushlight >/dev/null; then
        echo "shoot-store: Hushlight failed to build" >&2
        exit 1
    fi
    local app
    app=$(app_path)
    if [ -z "$app" ]; then
        echo "shoot-store: Hushlight.app not found in DerivedData" >&2
        exit 1
    fi

    # Installed once for the whole sweep, same discipline as labor-sim.sh's
    # shots_pass: only the launch argument changes between shots, never the binary
    # — reinstalling per shot cost that harness minutes for nothing.
    xcrun simctl terminate "$SIM" "$BUNDLE_ID" >/dev/null 2>&1 || true
    xcrun simctl uninstall "$SIM" "$BUNDLE_ID" >/dev/null 2>&1 || true
    xcrun simctl install "$SIM" "$app" >/dev/null

    # Suppress the How It Works sheet without a tap. TimerScreen.swift only sets
    # `hasSeenHowItWorks` from the sheet's *onDismiss* closure, and this script's
    # whole point is to run without `-uitesting` (the one thing that would
    # otherwise gate the sheet off) — so nothing here can prevent the sheet from
    # appearing except pre-setting the value its `.onAppear` check reads.
    #
    # **This write outlives the app.** `simctl spawn defaults write` lands in the
    # simulator's device-level preference store, which `simctl uninstall` does not
    # touch — so without `cmd_cleanup`'s delete, one run of this script suppresses
    # the first-launch sheet on this simulator *forever*, across every fresh
    # install anyone ever tests on it. That exact leak masked SP-190's first-launch
    # AC and cost a session an afternoon chasing a phantom app regression.
    #
    # The delete lives in `cmd_cleanup`, NOT in an EXIT trap here: each shoot-store
    # invocation is its own process, so a trap on *setup* fires the moment setup
    # returns — deleting the suppression before a single shot is taken, which is
    # how the first post-fix run captured five screenshots of the How It Works
    # sheet. The suppression must span the whole session of commands; only
    # `cleanup` may end it. A run that crashes before cleanup leaks until the next
    # `cleanup` heals it — accepted, and exactly why cleanup deletes
    # unconditionally.
    xcrun simctl spawn "$SIM" defaults write "$BUNDLE_ID" hasSeenHowItWorks -bool YES

    # Full battery, full signal, and a clock that agrees with the app — see
    # `status_bar_now`. Cleared again in `cleanup`.
    status_bar_now

    sim_ui light "$SIZE"
    echo "shoot-store: setup done on $SIM${STORE_LANG:+ (language $STORE_LANG)}"
}

# The no-tap shots, numbered as they appear in the store (spec.json). 02, 05, 06 and
# 07 need a tap and are staged by `nav` — see the README.
cmd_shot1() { sim_ui dark "$SIZE"; shoot "01-verdict-dark" -seedLabor511 -seedProviderNumber 5550100; }
cmd_shot3() { sim_ui light "$SIZE"; shoot "03-rest-light" -seedLaborWipe; }
cmd_shot4() { sim_ui dark "$SIZE"; shoot "04-building-dark" -seedLaborYoung; }

# Seeds and launches, then stops short of the screenshot — the app is left running
# on Timer, one tap away from the screen the shot actually wants.
cmd_nav() {
    case "${1:-}" in
        timing)
            sim_ui dark "$SIZE"
            launch -seedLaborYoung
            echo "shoot-store: Timer is up (dark, young pattern) — tap Start (220,858 pt), wait ~40 s, then:"
            echo "  ./scripts/shoot-store.sh capture 02-timing-dark"
            echo "  then press Lock, press Home, and:  ./scripts/shoot-store.sh capture 05-lockscreen-dark"
            ;;
        history)
            sim_ui light "$SIZE"
            launch -seedLabor511
            echo "shoot-store: Timer is up (light, 5-1-1 seed) — tap 'History' (57,83 pt), then:"
            echo "  ./scripts/shoot-store.sh capture 06-history-light"
            ;;
        guidance)
            sim_ui dark "$SIZE"
            launch -seedLaborWipe
            echo "shoot-store: Timer is up (dark, wiped store) — tap 'Guidance' (339,83 pt), then:"
            echo "  ./scripts/shoot-store.sh capture 07-guidance-dark"
            ;;
        *)
            echo "shoot-store: nav needs 'timing', 'history' or 'guidance'" >&2
            exit 1
            ;;
    esac
}

# HL-048: the four tap-driven shots, driven from `HushlightUITests/StoreShots` rather
# than from a point on the screen. See that file for why a coordinate could not survive
# translation. Three of the four run here; the Lock Screen one is called out below.
#
#   HUSHLIGHT_STORE_LANG=ja ./scripts/shoot-store.sh sweep
#
# Each shot is its own `xcodebuild test` invocation because **appearance is a device
# setting, not a test setting**: 02 and 07 are dark, 06 is light, and one invocation
# could only be one of them. `TEST_RUNNER_STORE_LANG` is Xcode's documented way into a
# UI-test process's environment — the prefix is stripped, so the test reads `STORE_LANG`.
#
# Screenshots come back as attachments in the result bundle, because a test process on
# the simulator cannot write to a host path. `xcresulttool` exports them and the
# manifest maps each back to the name the test gave it, which is the raw filename — so
# there is no mapping table here to drift.
cmd_sweep() {
    local tmp; tmp=$(mktemp -d); trap 'rm -rf "$tmp"; trap - RETURN' RETURN
    mkdir -p "$OUT_DIR"
    local ok=0
    # test name -> appearance
    local plan=("testTimingShot:dark" "testHistoryShot:light" "testGuidanceShot:dark")
    for entry in "${plan[@]}"; do
        local test=${entry%%:*} appearance=${entry##*:}
        sim_ui "$appearance" "$SIZE"
        status_bar_now
        local bundle="$tmp/$test.xcresult"
        echo "shoot-store: $test ($appearance${STORE_LANG:+, $STORE_LANG})"
        if ! xcodebuild test \
                -project Hushlight.xcodeproj -scheme Hushlight \
                -destination "id=$SIM" \
                -only-testing:"HushlightUITests/StoreShots/$test" \
                -resultBundlePath "$bundle" \
                TEST_RUNNER_STORE_LANG="$STORE_LANG" > "$tmp/$test.log" 2>&1; then
            echo "shoot-store: $test failed — tail of the log:" >&2
            tail -25 "$tmp/$test.log" >&2
            ok=1
            continue
        fi
        xcrun xcresulttool export attachments --path "$bundle" \
            --output-path "$tmp/$test-out" >/dev/null 2>&1
        /usr/bin/python3 - "$tmp/$test-out" "$OUT_DIR" << 'PY'
import json, os, re, shutil, sys
src, dest = sys.argv[1], sys.argv[2]
manifest = os.path.join(src, "manifest.json")
if not os.path.exists(manifest):
    sys.exit("shoot-store: no attachment manifest — the test produced no screenshot")
for test in json.load(open(manifest)):
    for attachment in test.get("attachments", []):
        name = attachment.get("suggestedHumanReadableName") or attachment.get("name")
        exported = attachment.get("exportedFileName")
        if not name or not exported:
            continue
        # XCTest appends its own disambiguator to the name the test gave —
        # `06-history-light_0_089C8CF4-…-53810C61A98D.png`. Strip it, or every
        # sweep writes a new file instead of replacing the last one, and the
        # per-language spec's `source` path never matches anything.
        stem = re.sub(r"_\d+_[0-9A-Fa-f-]{36}$", "", os.path.splitext(name)[0])
        shutil.copyfile(os.path.join(src, exported), os.path.join(dest, stem + ".png"))
        print(f"shoot-store: {dest}/{stem}.png")
PY
    done
    echo
    echo "shoot-store: 05-lockscreen is NOT part of this sweep — see the note below."
    return $ok
}

# 05-lockscreen, and why it is not in `sweep`.
#
# Three things break the obvious version of this shot, and the first is the one that
# matters beyond this script:
#
#   1. **`-AppleLanguages` does not reach the Live Activity.** It is a launch argument
#      for the *app*, and the Live Activity is rendered by `HushlightWidgets`, a
#      separate process the system starts on its own. A Japanese app therefore shows an
#      English card on the Lock Screen under this override — proven, not assumed, by a
#      shot that came back reading "CONTRACTIONS" and "End" beside a fully Japanese
#      app. **This is an artefact of the override, not a shipping bug**: a phone whose
#      system language is Japanese runs both processes in Japanese. But it means this
#      one shot cannot be taken with a launch argument; the simulator's own language
#      has to be set, which needs a reboot per language.
#   2. **The Live Activities permission prompt** covers the card on first use and has
#      to be accepted once per install.
#   3. **The lock clock.** With a `status_bar override` in force, SpringBoard's Lock
#      Screen renders "Sat Jan 1" — which `cmd_capture` already clears for any name
#      containing `lockscreen`, and which a hand-rolled screenshot taken in the wrong
#      order will get wrong. Use `capture`, not `simctl io` directly.
#
# So this shot is deliberately left to a documented sequence rather than half-automated:
#
#   xcrun simctl spawn <sim> defaults write -g AppleLanguages -array ja
#   xcrun simctl shutdown <sim> && xcrun simctl boot <sim>
#   HUSHLIGHT_STORE_LANG=ja ./scripts/shoot-store.sh setup
#   HUSHLIGHT_STORE_LANG=ja ./scripts/shoot-store.sh nav timing   # tap the slab, accept
#                                                                 # the Live Activities prompt
#   # lock the device, then:
#   HUSHLIGHT_STORE_LANG=ja ./scripts/shoot-store.sh capture 05-lockscreen-dark
# Everything one language needs, in one command — the six shots a launch argument can
# reach. 05-lockscreen is the exception and the block above says why.
#
#   for l in es fr de it pt-BR ja ko zh-Hans; do HUSHLIGHT_STORE_LANG=$l ./scripts/shoot-store.sh all; done
cmd_all() {
    cmd_setup
    cmd_shot1
    cmd_shot3
    cmd_shot4
    cmd_sweep
}

cmd_capture() {
    local name=${1:-}
    if [ -z "$name" ]; then
        echo "shoot-store: capture needs an output name" >&2
        exit 1
    fi
    mkdir -p "$OUT_DIR"
    # The lock screen shot must not carry the time override: with one set, SpringBoard's
    # lock clock reads "Sat Jan 1". The status bar is hidden there anyway.
    case "$name" in *lockscreen*) xcrun simctl status_bar "$SIM" clear; xcrun simctl status_bar "$SIM" override \
        --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3 >/dev/null ;; esac
    xcrun simctl io "$SIM" screenshot "$OUT_DIR/$name.png" >/dev/null 2>&1
    echo "shoot-store: $OUT_DIR/$name.png"
}

# The exit path, straight out of DemoSeed's own contract (see labor-sim.sh's
# shots_pass): a seeded pattern must never outlive the pass, and appearance /
# content size are device-wide settings a later manual look would inherit.
cmd_cleanup() {
    # The device language is device-wide and would otherwise outlive the pass, exactly
    # as the appearance and content-size settings below would.
    restore_device_language
    xcrun simctl status_bar "$SIM" clear >/dev/null 2>&1 || true
    # The device-level sheet suppression — see the long comment at the write. Runs
    # here too so a `cleanup` invocation can heal a simulator poisoned by a run
    # from before the trap existed.
    xcrun simctl spawn "$SIM" defaults delete "$BUNDLE_ID" hasSeenHowItWorks >/dev/null 2>&1 || true
    xcrun simctl terminate "$SIM" "$BUNDLE_ID" >/dev/null 2>&1 || true
    xcrun simctl launch "$SIM" "$BUNDLE_ID" -seedLaborWipe >/dev/null 2>&1 || true
    sleep 2
    xcrun simctl terminate "$SIM" "$BUNDLE_ID" >/dev/null 2>&1 || true
    sim_ui light "$SIZE"
    echo "shoot-store: cleanup done — $SIM left neutral (light/$SIZE, status bar cleared, store wiped)"
}

usage() {
    sed -n '2,33p' "$0" | sed 's/^# \{0,1\}//'
    exit "${1:-0}"
}

case "${1:-}" in
    setup)   cmd_setup ;;
    shot1)   cmd_shot1 ;;
    shot3)   cmd_shot3 ;;
    shot4)   cmd_shot4 ;;
    nav)     cmd_nav "${2:-}" ;;
    sweep)   cmd_sweep ;;
    all)     cmd_all ;;
    capture) cmd_capture "${2:-}" ;;
    cleanup) cmd_cleanup ;;
    -h|--help|"") usage 0 ;;
    *) echo "shoot-store: unknown command '$1'" >&2; usage 1 ;;
esac
