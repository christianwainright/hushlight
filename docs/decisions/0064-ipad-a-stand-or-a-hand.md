# 0064 · iPad: a stand, or a hand

**Date:** 2026-09-09 · **Item:** HL-058 · **Status:** decided (direction Christian's:
"let's make the app better on iPad… Build it"; design agent-drafted, `docs/design/
hushlight/ipad/`) · **Amends:** 0018's iPhone-only scope

## Context

Decision 0018 built one app for one object — the phone on the nightstand, one hand,
in the dark — and made it iPhone-only. On an iPad it ran in compatibility mode, a
phone-shaped window on a black slab; App Review tested it there (HL-055) and it worked.
Christian asked for it to be designed for the iPad rather than tolerated on it.

## Decision

1. **The app targets iPad**, with all four orientations there; iPhone stays portrait.
2. **Layout is chosen by the window, never the device.** Three regimes on the
   horizontal size class and the window's aspect: *compact* is the existing column
   (iPhone, Split View at a third, Slide Over); *hand* (regular, taller than wide)
   puts a live **ledger** of the current stretch beside the instrument; *stand*
   (regular, wider than tall) does the same and takes the leading figure to a new
   DesignKit role, `.distance`, for a room's reading distance.
3. **The ledger is History's rows, not a second instrument.** Same `HistoryRow`,
   same summary line, same evidence floors, History's own two controls (Undo, swipe
   to delete) and nothing else.
4. **Nothing crosses between devices.** The ratchet forbids the App Group and iCloud
   and the app has no network code, so the iPad keeps its own record, and Guidance
   says so in one sentence. Christian parked both an AirDrop hand-off and Handoff on
   2026-09-09; neither is built and neither is assumed.

## Rationale

The design's thesis: an iPad at a birth is either on a stand, read across the room —
HL-013's literal nightstand at full size, without StandBy, which iPad lacks — or in the
partner's hand, keeping the record, for whom History belongs beside the timer rather
than behind a tap. Widening the iPhone would serve neither. Size class rather than
idiom because Stage Manager and Split View give an iPad every width a phone has and
several it does not; a layout keyed to the device would be wrong in half of them.

## Boundaries

Every §8 gate runs on both regimes, AX5 included (`a11y-ax5.sh` takes an iPad device
type). Regime switches are continuous under Stage Manager and must not lose state —
anything a switch would rebuild is owned above it (the HL-057 lesson). Keyboard and
pointer (HL-058b) and the iPad store set (HL-058c) follow as their own items.
