# 0051 · Two marks and the interval between them

**Date:** 2026-08-27 · **Item:** HL-034 · **Status:** superseded by [0052](0052-the-icon-is-a-lamp.md)

## Context

Christian's redline, 2026-08-27: "I need a much better app icon." HL-002 shipped the
Nightstand `icon_concept` faithfully — one amber capsule low on a baseline hairline,
a wide faint bloom — and the faithful rendering exposed three execution failures the
concept prose couldn't:

1. **The pill.** A 4:1 fully-rounded amber capsule, alone in the frame, is a
   pharmaceutical in a medical-category app. Nothing around it disambiguated.
2. **Timidity.** The mark covered ~4% of the canvas; at 60 pt it was a small dash on
   a brown square, invisible in a folder grid next to anything saturated.
3. **Light that didn't glow.** One radial wash at 0.4 alpha over a 1.7×-bar-width
   radius warms the field without ever reading as a lamp. For an app named
   *Hushlight*, the light was the least crafted thing in the image.

## Decision

The icon becomes one frame of the ember tape — the app's own hero component, and its
one clinical measurement made visible:

- **Two marks on the baseline, not one.** A settled mark at the tape's left edge,
  drawn with the app's past-bar slab gradient and dimmed — it has cooled. The live
  mark, longer (durations lengthen as labor builds) and glowing. The gap between
  them is the thing the app exists to measure: the start-to-start interval. The tape
  to the right of the live mark stays empty — the night still ahead.
- **A longer, lower live mark** (~4.4:1 against HL-002's 4:1), still a capsule —
  the tape's bars are capsules in the app and the icon keeps their language — but
  proportioned as a dash on a line, not a lozenge in a void. The companion mark and
  the baseline finish the disambiguation: this is a pattern, not a pill.
- **Layered light.** Two elliptical radial layers (flattened to 78% — light from a
  low source spreads along the surface it sits on), a tight glow holding brightness
  at the mark and a wash that dies before the corners so the icon keeps its dark
  silhouette in a grid. The bloom's centre sits slightly above the mark: light rises
  off an ember. The baseline is drawn crisp *over* the bloom and brightens where the
  lamp's light passes it, falling back to faint in both directions.
- **The light appearance drops the hot-centre gradient.** On paper, "hotter" means
  *darker* amber, and a dark centre in a light mark reads as uneven print, not
  intensity. Light marks take the app's own vertical slab gradient at full strength;
  the past mark the same at 0.45 alpha. No bloom on paper — that rule holds.
- **Tinted keeps the two-mark story**: live mark white (brightest in frame), past
  mark mid-gray, hairline faint — the OS's luminance ramp preserves the hierarchy.

## Rationale

The strongest thing the identity owns is not the bar — it is the *scene*: a calm
glowing thing in the dark, on an instrument. One mark alone had to carry scene,
brand, and function and managed none at 60 pt. Two marks with an interval carry all
three: the composition is literally what the user is doing at 3am (timing the gap
between this contraction and the last), it is drawn in the app's own component
language (slab gradient past bars, glowing live bar, the tape's baseline), and the
rebuilt bloom finally makes the name visible. Nothing new enters the palette; every
colour is a `Palette.swift` token copied under the existing must-move-together rule.

## Boundaries

- The identity is unchanged: Nightstand, ember on warm near-black, paper inversion,
  no fetus, no flower, no moon, no monogram, no red, no text.
- Decision 0035 stands: `ios-marketing` keeps its own file carrying the dark artwork,
  regenerated in the same run.
- The layer-export rules stand: `background`/`foreground` ship no baked light (the
  lit baseline travels with the *foreground's* future Icon Composer glow, not with
  the background's tape — it is lamplight, not tape).
- If the tape's in-app bar treatment changes (HL-003's slab gradients), the icon
  regenerates in the same commit — the icon is now a frame of that component, and
  drift between them is drift inside one drawing.
