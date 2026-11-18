# Hushlight on iPad — a design (2026-09-09, draft for HL-058)

*Nightstand* was written about one object: a phone lying face-up on the nightstand at
3am, one ember of lamplight. An iPad in that room is a different object, and the
design starts by saying which one. Today the app runs on iPad in iPhone-compatibility
mode — a phone-shaped window in the middle of a black slab, verified during App Review
round 2 (HL-055). It works. It is not designed.

`docs/design/hushlight/ipad/mockups.html` is the board this document describes.

## The thesis: a stand, or a hand

An iPad at a birth is in one of two places, and the two ask for different screens.

1. **On a stand.** The tray table in a delivery room, the nightstand at home, propped
   on the bed's rail. Nobody is holding it; the reading distance is a room's, not a
   hand's. This is the surface HL-013 wanted — "the nightstand is literal" — but at
   full size and without waiting for StandBy, which iPad does not have. What matters
   here: the figures, at distance; the tape; the verdict when it comes. The button
   matters less, because whoever taps it is more likely holding the phone.
2. **In a hand.** The partner's screen. They are not the one having contractions; they
   are keeping the record, reading it back to the nurse, watching the pattern build.
   For them the question is never "what is the count right now" alone — it is "what
   has the last hour looked like". History should not be a screen they navigate to.
   It should be beside the timer, always.

Both are the same app, the same one button, the same evidence floors. What changes
is what is on screen at once, and how large.

## The layout regimes

Three, chosen by the window's horizontal size class and width — never by device
model, because Split View and Stage Manager hand the app every width there is.

| Regime | Where it happens | What it is |
|---|---|---|
| **Compact** | iPhone; iPad Split View at one third; Slide Over | Today's single column, untouched. It already survives 320 pt. |
| **Regular · Hand** | iPad portrait, full screen or two-thirds | Two panes: the **instrument** (figures, tape, verdict, slab) and the **ledger** — the current stretch's History, live, beside it. |
| **Regular · Stand** | iPad landscape, full screen | The same two panes, with the instrument's leading figure taken to distance scale and the ledger quieter. Landscape is how a stand holds an iPad; the regime follows orientation, not a setting. |

**The instrument pane** is the iPhone timer, given room. The header row, the stat
trio, the tape, the verdict banner and the slab keep their order; the slab keeps its
role as the whole lower edge of the pane — the button is still a target you can hit
without looking. Nothing in it is new.

**The ledger pane** is History's timeline for the current stretch, read the way
History already reads — newest at the top, the gap printed where it happened, dashes
below the evidence floor — plus the per-episode averages. It is not a second
instrument: no controls except Undo and swipe-to-delete, which are History's own. When
there is no stretch, it says so in the same words the timer's empty state uses, and
does not fill the space with anything.

**Guidance and the How-it-works card** stay pushed screens and sheets in every regime.
They are read once and occasionally; giving them a permanent pane would spend the
room on the least-used thing.

## What "distance scale" means, and what it does not

- In *Stand*, the leading figure — the live count while a contraction is timed, the
  time-since-last otherwise — takes a larger role than `.hero`'s 84 pt. The number is
  one more type role in DesignKit (`.distance`, ~132 pt at default size), chosen by the
  regime, never by a per-screen font size: the ban on `Font.system(size:)` outside
  DesignKit holds.
- It scales with Dynamic Type like every other role, and at accessibility sizes the
  instrument's stat trio stacks exactly as on iPhone (`lint-row-figures.sh` already
  requires the branch). The AX5 gate runs on the iPad regimes too.
- It does not dim, tint, or "night mode" anything. The palette is already lamplight;
  iPadOS has no `isLuminanceReduced` for apps and the app does not invent one. The
  screen stays awake while timing, as it already does (HL-011).

## Orientation, multitasking, and a keyboard on the tray table

- **iPad supports all four orientations.** Required for Split View and Stage Manager,
  and a stand does not ask which way up it is. iPhone stays portrait-only (decision
  0018's reasoning about one-handed use in the dark is unchanged).
- **Every width is a first-class width.** The compact column at 320 pt is the iPhone
  layout; between 320 and the regular threshold the single column simply widens, with
  a maximum content width so a 700 pt column of prose does not happen. Stage Manager
  resizes are continuous; the regime switches at the size-class boundary and the
  layout must not lose state across the switch (the HL-057 lesson — hoist anything
  that would be reborn).
- **A hardware keyboard.** A Magic Keyboard on a tray table is plausible and cheap to
  honour: **Space** starts and ends a contraction, **⌘Z** undoes, **⌘J** opens
  History, **⌘G** Guidance (⌘H is iPadOS's own Home; ⌘1/⌘2/⌘L/⌘Y are Simulator.app's, which
  the harness cannot deliver — a shortcut that cannot be tested is not shipped), **Esc** closes a sheet — surfaced by holding ⌘, which is
  the system's own discoverability, so nothing new is drawn. Pointer hover on the
  capsules and the slab uses the system hover effect; nothing custom.

## The Lock Screen, and what the iPad does not get

- The Live Activity already appears on the iPad's Lock Screen (verified 2026-09-09,
  HL-055) and keeps working. No Dynamic Island, no StandBy — those are iPhone surfaces,
  and the app does not imitate them.
- **No widget**, still. The ratchet forbids the App Group a widget would need
  (decision 0042); iPad changes nothing about that.
- **No sync, and this is the hard part.** The ratchet says nothing a user times leaves
  the device, there is no iCloud entitlement, and there is no network code. So the
  iPad's record is the iPad's record: an iPhone timing in the bedroom and an iPad on the
  stand are two instruments, not one. The design says this plainly on Guidance rather
  than hiding it: *"This iPad keeps its own record. Nothing here is shared with your
  iPhone or with anyone."* That is the honest v1, and it is enough for both roles above
  — the partner's iPad *is* the record in the hand case, and the stand shows whatever
  device is doing the timing.

  **A decision for Christian, not for this design:** a user-initiated hand-off — the
  For the call export as a file she AirDrops from one device and opens on the other,
  where the app imports it. No network capability, nothing leaves without her tap,
  nothing arrives without her opening it; it is the share sheet the app already uses,
  in both directions. It is also a document type, an import path, and a merge rule,
  and it edges the ratchet's spirit even where it clears its letter. Filed as its own
  question (HL-058d), not assumed.

## The store

- iPad screenshots in the 13" slot (the one App Store Connect requires), fourteen
  storefronts, through the same pipeline as the iPhone set — `shoot-store-ipad.sh`,
  `make-store-frames.swift` with an iPad geometry, `push-store-metadata.py` with a second
  set. Two frames, not seven: *Hand* and *Stand*. The captions say what this document
  says — a stand, or a hand. *(Built: HL-058c.)*
- The listing gains one sentence; the review notes gain one, and lose "built for
  iPhone". The reviewer who tested on an iPad Air last time will find an iPad app.

## What does not change

The palette. The voice. One button. Start-to-start intervals. The evidence floors and
the em dash. No account, no network, no analytics, no ads. Red still not in the
palette. Every gate in DESIGN-SPEC §8 runs on every regime.

## Proposed items (drafted into BACKLOG as HL-058)

| | Size | Item |
|---|---|---|
| HL-058a | M | The regimes: size-class layout, the ledger pane, the `.distance` role, all orientations on iPad, state hoisted across regime switches. AX5 on both regimes. |
| HL-058b | S | Keyboard and pointer: Space / ⌘Z / ⌘J / ⌘G / Esc, system hover. |
| HL-058c | S | The store: two iPad frames × fourteen storefronts; listing and notes updated. |
| HL-058d | — | *Decision needed:* the AirDrop hand-off. Christian's call under gate 3. |

Ships as 1.1, after 1.0.1. Order: a, then b and c together; d only if decided.
