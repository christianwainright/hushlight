# 0019 — The Live Activity's taps run in the app's process

**Status:** accepted
**Date:** 2026-08-10 · **Item:** SP-186
**Amends:** nothing. Confirms 0018's no-App-Group stance under a second process.

## Context

The contraction timer's primary environment is a locked phone at 3am. SP-186 put
the button on the lock screen: a Live Activity showing the pattern, with start/end
taps that must write to a store deliberately kept in the app's own sandbox —
decision 0018 rejected any App Group so labor data stays unreachable by everything
else. A widget extension is a separate process, which looks like a contradiction.

## Decision

**The extension only draws; every tap executes in the app's process.** The button
runs a `LiveActivityIntent` (`StartStopContractionIntent`, defined in `LaborKit`
so both targets see the type), and that conformance is load-bearing: the system
executes such intents in the app's process, where `LaborStore.container()`
resolves to the real store. No App Group entitlement was added to either target —
0018's fence stands even with a lock-screen writer.

Two supporting choices:

- **The elapsed count is `Text(timerInterval:)`** — the system renders each
  second; no content updates, no process wakes, hours of labor with no drain.
  Activity updates happen only on taps and episode changes.
- **One reconciliation point.** `LaborModel.reload()` syncs the activity on every
  store change: a live pattern keeps exactly one activity current; an empty or
  stale episode ends it. In-app taps and lock-screen taps converge on the same
  state because neither surface owns it — the store does. The app also gained the
  foreground `refresh()` hook it deliberately skipped while it was the only
  writer.

## What shipping an appex surfaced (kept because it bit twice)

- **The generated-plist flow drops `NSExtension`.** `INFOPLIST_KEY_
  NSExtensionPointIdentifier` produced a plist without the `NSExtension` dict, and
  the appex failed install with "invalid placeholder attributes". Both widget
  extensions now carry a stub `Info.plist` (merged with the generated one) holding
  the dict.
- **Placeholder validation requires version keys.** No target in the project ever
  set `MARKETING_VERSION`/`CURRENT_PROJECT_VERSION`; apps tolerate the missing
  `CFBundleVersion`, extension placeholders do not. Set project-wide.
- **`SetpointWidgets` was never embedded.** The Setpoint app target never declared
  the extension dependency, so decision 0012's widgets have never shipped inside
  any build — they compiled into the void. Found only because ContractionsWidgets
  hit the same install path with a fresh eye. Fixed (`embed: true`); Setpoint
  needs a reinstall before its widget exists on a device, which is also why
  SP-123's manual check would have found no widget to add.

## Verification

On simulator glass, end to end: activity appears when a pattern is live; the
system consent prompt granted; **Start tapped on the lock screen** → intent wrote
the record and flipped the card to a ticking elapsed with End; **End tapped** →
idle card; app relaunch showed 7 TOTAL with the lock-screen contraction's real
interval and its 15-second duration honestly dragging the average down; the wipe
ended the activity and left the lock screen bare. 32 LaborKit tests including the
ContentState derivation.
