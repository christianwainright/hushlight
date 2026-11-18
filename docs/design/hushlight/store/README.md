# The store set — screenshots and previews (HL-037)

What App Store Connect gets for the 6.9" slot, and how every file here was made so it
can be made again after the UI moves.

| Dir | What | In git |
|---|---|---|
| `raw/` | Simulator captures, 1320×2868, untouched | yes |
| `frames/` | The store screenshots — raw shot framed on the room with a headline | yes |
| `preview/` | Compositor parts for the videos: the text cards (`card-*.png`, each on its own scrim) and `layout.json` — full-bleed since App Review round 2, no room and no bezel | yes |
| `previews/*.edit` | Edit lists: which seconds of which recording, which card when | yes |
| `previews/*.mp4` | The app previews, 886×1920 H.264 | no — rebuilt from the edits |
| `rec/` | `simctl recordVideo` captures the edits cut from | no — re-record |
| `spec.json` | The frame and card copy | yes |

## Rebuild from what is committed

```bash
swift scripts/make-store-frames.swift docs/design/hushlight/store/spec.json docs/design/hushlight/store
```

That regenerates every frame and every preview part. (This used to pin
`DEVELOPER_DIR` to Xcode-beta; the pin went with HL-038.) The previews need the
recordings in `rec/` (see below), then:

```bash
./scripts/make-store-preview.sh docs/design/hushlight/store/previews/a-two-taps.edit    docs/design/hushlight/store/previews/a-two-taps.mp4
./scripts/make-store-preview.sh docs/design/hushlight/store/previews/b-lock-screen.edit docs/design/hushlight/store/previews/b-lock-screen.mp4
```

`ffmpeg` is required (`brew install ffmpeg`). The script refuses any cut outside Apple's
15–30 s window and prints the stream facts the upload form checks.

**Previews are full-bleed since App Review round 2 (2026-09-09).** They used to be the
screenshot frame brought to life — room, device, bezel — and Apple rejected that under
Guideline 2.3.4: a preview must show the app as it will appear on the device, and device
frames are the named exclusion. Framed *screenshots* are still allowed and all 98 were
accepted; framed previews are not. So the footage now fills the 886×1920 canvas and the
only thing drawn over it is the text cards, each on its own scrim so a headline survives
sitting over the app's header. `preview/layout.json` carries `fullBleed: true` and the
assembler refuses a layout without it, so a stale layout cannot put the bezel back. The
`bg-*.png` and `bezel-*.png` assets are gone; the compositor no longer emits them.

## Re-shooting the raw set

`./scripts/shoot-store.sh setup` once (boots a 6.9" simulator on the newest installed runtime — or creates one — builds, installs,
suppresses How It Works, sets the status bar). Then:

| Raw | How |
|---|---|
| `01-verdict-dark` | `shoot-store.sh shot1` |
| `03-rest-light` | `shoot-store.sh shot3` |
| `04-building-dark` | `shoot-store.sh shot4` |
| `02-timing-dark` | `shoot-store.sh nav timing`, tap Start at (220, 858) pt, wait ~40 s, `capture 02-timing-dark` |
| `05-lockscreen-dark` | continue from 02: press Lock, press Home, wait 2 s, `capture 05-lockscreen-dark` |
| `06-history-light` | `shoot-store.sh nav history`, tap (57, 83) pt, `capture 06-history-light` |
| `07-guidance-dark` | `shoot-store.sh nav guidance`, tap (339, 83) pt, `capture 07-guidance-dark` |

Taps come from the iOS Simulator tool (points, origin top-left, 440×956) or a finger on
the Simulator window; `simctl` has no touch injection. `shoot-store.sh cleanup` at the
end — it clears the status bar, the sheet suppression, and the seeded store.

**The clock.** The seeds anchor to the real clock, so a 1 pm capture would read
"SINCE 12:11 PM". `shoot-store.sh` launches the app under `SIMCTL_CHILD_TZ=Asia/Tokyo`
and overrides the status bar to the same clock, so an afternoon here is the small hours
on screen (`HUSHLIGHT_STORE_TZ` to change it). The lock screen shot drops the time
override — with one set, SpringBoard's lock clock reads "Sat Jan 1".

**First run on a fresh simulator.** The Live Activity asks "Allow Live Activities from
Hushlight?" on the lock screen the first time, and "…continue to allow…" the second.
Answer both (Allow / Always Allow) before recording; they do not come back.

## The other eight languages (HL-048)

The store ships fourteen listings across nine languages. English keeps the flat layout
this file already describes; every other language has its own `raw/<lang>/`,
`spec/<lang>.json` and `frames/<lang>/`. One command per language:

```bash
HUSHLIGHT_STORE_LANG=ja ./scripts/shoot-store.sh all      # six of the seven shots
swift scripts/make-store-frames.swift \
    docs/design/hushlight/store/spec/ja.json "$(mktemp -d)"   # then copy frames/ across
```

`all` is `setup` + the three no-tap shots + `sweep`, and **`sweep` drives the tap shots
from `HushlightUITests/StoreShots` rather than from a point on the screen**. That is the
whole reason it exists: `History` is 履歴 in Japanese and a narrower button, so a
coordinate is an English assumption inside a tool whose job is proving the app is not
English. The three targets carry accessibility *identifiers*, which are stable in every
language and invisible to VoiceOver.

**Setting the language is a device operation, not a launch argument, and that took two
findings to learn.** `-AppleLanguages` reaches exactly one process, and a store shot
needs three others to agree:

| Rendered by | What went wrong before the device language was set |
|---|---|
| `HushlightWidgets` | The Live Activity showed English `CONTRACTIONS / End` beside a fully Japanese app |
| SpringBoard (status bar) | `--time` is a *moment*, re-rendered in the device locale — passing `16:38` to an English device produced `4:38`, a 12-hour clock above a German 24-hour readout |
| SpringBoard (Lock Screen) | The date read `Sat Jan 1` while a `status_bar override` was in force |

So `setup` writes `AppleLanguages`/`AppleLocale` device-wide and kickstarts SpringBoard;
`cleanup` puts English back. Neither is optional — both settings outlive the pass
otherwise, the same hazard the appearance and content-size settings already carry.

**`05-lockscreen` is the one shot `sweep` does not take.** XCTest has no Lock button
press and neither does `simctl`, so it is staged and captured by hand — and the
Live Activities permission prompt has to be accepted once per install before the card
is clear:

```bash
HUSHLIGHT_STORE_LANG=ja ./scripts/shoot-store.sh setup
HUSHLIGHT_STORE_LANG=ja ./scripts/shoot-store.sh nav timing
# tap the slab, lock the device, accept "Allow Live Activities", wait ~30 s
HUSHLIGHT_STORE_LANG=ja ./scripts/shoot-store.sh capture 05-lockscreen-dark
```

Use `capture`, not `simctl io` — it clears the time override first, which is what keeps
the Lock Screen date honest.

**Only `frames/` is committed for the other languages.** The localized raws are 56 MB of
intermediate across eight languages and are byte-reproducible from the command above;
the framed output is what CI's metadata push uploads from a plain checkout, so that has
to be in the repository. The seven English raws stay tracked because they predate this
and are the reference the rest were shot against.

## Re-recording the previews

Recording is `xcrun simctl io <sim> recordVideo --codec h264 --force rec/<name>.mov`,
stopped with SIGINT. It is variable-frame-rate and emits nothing while the screen is
still; the assembler pads each segment to its nominal length so a dissolve never runs
out of frames.

- **a-two-taps-1** — `nav timing`; record; ~3 s rest; tap Start; ~28 s; tap End; ~5 s.
- **a-two-taps-2** — `shot1`'s launch (5-1-1 seed, provider number); record ~10 s still.
- **b-lock-screen** — `nav timing`; record; ~3 s; tap Start; ~4 s; Lock; Home; ~25 s.

Then find the seconds the taps land on (`ffmpeg -vf fps=1,scale=140:-1,tile=10x6` makes
a contact sheet) and set the `seg` lines in the `.edit` file. Ending a contraction from
the Live Activity button does not fire on the simulator, which is why preview B stops at
"it keeps counting" rather than showing the End tap there.

## What the copy is doing

Seven frames, in the order the store shows them; the first two carry the listing in
search results. Each headline is the app's own voice — New York medium, the register the
timer uses when it speaks as a person — with a mono-caps eyebrow like the timer's own
labels. No exclamation, no fear, no claim the app does not make: the verdict frame says
the app *says so* against *the guideline your provider gave you*, never that it knows.

Both appearances appear (frames 3 and 6 light) because the identity's daytime
translation is first-class, and because a light frame in a dark run stops the thumb.

## The iPad set (HL-058c)

Two frames, not seven — *Hand* (portrait, light: the verdict beside the ledger) and
*Stand* (landscape, dark: the count at `.distance`, the ledger's newest row reading
RUNNING) — because the iPad's story is the two places it sits, and the seven iPhone
frames already tell the rest. Shot on a 13" iPad Pro simulator, whose 2064×2752 capture
is what the one iPad slot App Store Connect requires takes.

```bash
./scripts/shoot-store-ipad.sh all          # raw-ipad/ and raw-ipad/<lang>/ — nine languages
./scripts/make-store-frames-ipad.sh        # frames-ipad/ and frames-ipad/<lang>/
```

`HushlightUITests/StoreShotsPad` drives the two shots (rotation needs `XCUIDevice`);
the script sets appearance, the 9:41 status bar and the language around each run, builds
once and tests-without-building eighteen times. A landscape capture comes back lying on
its side — `XCUIScreen` hands over the framebuffer in portrait pixel order — and the
script turns it upright. Captions live in `spec-ipad.json` and `spec-ipad/<lang>.json`;
`make-store-frames.swift` reads `"device": "ipad"` and lays the frame out at the
capture's own size, with an iPad Pro's flat bezel and small corner. `push-store-metadata.py`
sends `frames-ipad/` to the 13" slot (`APP_IPAD_PRO_3GEN_129`, named rather than
discovered, since no iPad set exists until the first push creates it).

