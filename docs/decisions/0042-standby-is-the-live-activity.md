# 0042 · StandBy is the Live Activity, because the ratchet says so

**Date:** 2026-08-24 · **Item:** HL-013 · **Status:** decided

## Context

The identity's brief is literal: this phone will be charging on the nightstand, and
HL-013 asks for a landscape ember-tape clock — time since the last contraction,
legible across a room. The obvious implementation is a WidgetKit widget in StandBy's
widget rotation. It is also impossible here: a widget extension reads shared
storage, shared storage means an App Group, and the privacy ratchet forbids the App
Group (decisions 0018, 0033 — the store lives in the app's own sandbox precisely so
nothing else can reach it).

## Decision

**The StandBy surface is the Live Activity.** iOS presents a live activity
full-screen in StandBy on its own; ActivityKit *pushes* content into the extension,
which is how the lock screen already works without shared storage. HL-013's scope is
therefore not a new widget but the existing activity's night presentation:

1. **Honour `isLuminanceReduced`.** StandBy's night mode dims the panel and expects
   surfaces to go darker still: the activity's background drops to true black-on-
   nothing, the glow effects stand down, and only the figures remain. The system's
   red night tint is system furniture (the F-0033 class) — our palette stays
   red-free and the OS may tint as it pleases.
2. **Distance type.** In the reduced-luminance presentation the leading figure — the
   live count while running, the idle line otherwise — takes the hero role's scale,
   because the reading distance is a nightstand's, not a hand's.
3. **Nothing new is stored, shared, or entitled.** The content is exactly the
   `ContentState` the app already pushes.

## Rationale

The alternative — asking Christian to relax the App Group rule for a nicer clock —
is the request the ratchet exists to make unthinkable. The Live Activity route costs
that nothing: it uses the mechanism the app already trusts, and StandBy support
degrades gracefully to "the lock screen, larger" on devices that never charge
sideways.

## Boundaries

Verification is device-gated: the simulator does not present StandBy, so the item
can reach `[R]` on code and lock-screen evidence but closes only after a night on
the physical nightstand — the same honest gate HL-011 carries.
