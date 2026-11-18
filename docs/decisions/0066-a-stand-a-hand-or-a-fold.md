# 0066 · iPhone Duo: a stand, a hand, or a fold

**Date:** 2026-10-28 · **Items:** HL-060 – HL-065 · **Status:** decided (direction
Christian's: "Do this. All of it… We especially want to highlight support for the duo";
design agent-drafted) · **Extends:** 0064

## Context

iOS 27.1 and the iPhone Duo shipped in October 2026. The Duo is two devices in one
evening: closed, a 5.4" phone (1398×2034, compact width); open, a 7.6" slab (2007×2853,
regular in both axes), which can stand half open with the hinge across it. Apps built
against the 27.1 SDK fill the inner display; older builds sit in black borders. iOS
27.1 adds the APIs that say where the fold is — `GeometryProxy.reservedRegions(kind:)`,
whose `.division` region is the hinge and `.occlusion` region the under-display camera
— and `onHingeChange`, which reports `closed`, `partiallyOpen` or `fullyOpen` and an
angle. Apple's guidance is the one 0064 already follows: lay out by the window, never by
the device.

## Decision

1. **The fold is the seam.** `LayoutRegime` gains a fourth regime, *tabletop*: a fold
   running across a half-open window puts the instrument on the upright half — the
   count at `.distance`, read from the bed, then the verdict when there is one — and
   gives the half lying on the nightstand to the button, all of it. The listing has
   said "the button is the whole lower half of the screen" since 1.0; on a Duo stood
   half open, the hinge is the line. It takes precedence over the size class, because
   it is the right answer at every width the window could have.
2. **Opened flat, a Duo is an iPad in a hand.** Regular in both axes, it gets 0064's
   *hand* regime with no new code. Held with the fold down the middle (a book), the
   ledger takes the trailing panel exactly, so no row of figures is broken by the
   crease. Closed, it is the compact column.
3. **Status, never angle.** The layout reads the hinge's status and the fold's frame.
   Nothing moves with the angle: an instrument that animated as it opened would be the
   app performing, which the voice rules out.
4. **The occlusion region is honoured** where it touches an edge (HL-062); safe areas do
   not include it.
5. **Everything is behind `#available(iOS 27.1, *)`.** The floor stays iOS 18.0 (0053);
   a device without a hinge never has a fold.
6. **The intent gets three more doors** (HL-065): an App Shortcut (Siri, the Action
   button) and a Control Center control, both running the existing
   `StartStopContractionIntent` — a `LiveActivityIntent`, so in the app's process. The
   control is a button, not a toggle: a toggle would have to read the store from the
   extension, which needs the App Group the ratchet forbids. The intent now speaks its
   result in Magic Tap's words, and **refuses to write if it ever runs inside an
   extension**, where the store it would open is an empty sandbox nothing reads.
7. **Declined: the count on the outer display while the Duo stands open.** The SDK's
   scene accessories are of two kinds: an external display, and camera capture, which
   presents only while a capture session runs. The second is the only route to the
   Duo's outer panel, and a contraction timer running the camera to earn it would break
   the ratchet's spirit if not its letter. Not built, not scaffolded.

## What a simulator can and cannot prove

Nothing in XCTest, `simctl` or `devicectl` poses a simulated Duo; Device Hub's hinge
control is a window. So the layout's *response* to a fold is proven with a test-only
`-simulateFold tabletop` (under `-uitesting` only, `FoldTests`), and the system's
*report* of one — the reserved region's frame, the hinge status, a contraction
surviving the scene's move between panels — waits for a person to pose the device. The
store shots refuse the simulated fold outright: `StoreShotsDuo` asserts the layout its
pose produces and never passes the flag, so a fold the system did not report cannot
reach the App Store.

## Consequences

HL-060, HL-061, HL-062, HL-064 and HL-065 sit at `[R]` until that posing happens; the
rows are in §2.2. The App Store Connect API has no Duo display type yet, so the Duo
frames are uploaded by hand (gate 2). Apple requires Duo screenshots on every submission
from April 2027; the tooling is ready for that.
