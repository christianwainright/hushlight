# 0052 · The icon is a lamp

**Date:** 2026-08-27 · **Item:** HL-035 · **Status:** decided — geometry and rendering superseded by 0055 · **Supersedes:** 0051

## Context

Christian rejected 0051's two-marks-on-the-tape icon outright ("that icon is
terrible"), one day after rejecting HL-002's single mark. Two rejections of the same
family is a verdict on the family: marks-on-a-baseline is an insider metaphor — it
requires knowing the app's tape component to read at all, and at 60 pt what survives
is horizontal amber lozenges, which is to say pills, in a medical category.

Christian took a design brief to an external generator (Grok) and returned two
photorealistic concept renders of a glowing bedside lamp — one the shade alone
nearly filling the frame, one a full table lamp with stem and round base — and
handed the choice and the rebuild back.

## Decision

The shade-fills-the-frame concept, rebuilt as versioned vector source in
`scripts/make-hushlight-icon.swift` from palette tokens:

- **One form:** a rounded-trapezoid lampshade, 63% of the canvas wide at the hem,
  56% tall, lit from within — `emberLive` at the bulb's height falling through
  `tint` to `emberSlabBottom` at the hem corners, darkened by distance from the
  light rather than by painted shadow. A soft halo around it dies before the
  corners; a sliver of base peeks from under the hem.
- **Light appearance:** the same silhouette in the deep light-ambers, plain
  top-to-bottom slab gradient, no glow — the lamp by day, switched off, still
  itself.
- **Tinted:** flat near-white shade, mid-gray base sliver, black field.
- The full-table-lamp render was declined for icon craft reasons: its stem and base
  go spindly below 76 pt and the glow-to-frame ratio drops; the shade-only version
  keeps one big luminous form at every size.

## Rationale

The lamp is the name. *Hushlight* promised "a calm glowing thing in the dark" and
two icon generations tried to say it with the instrument's data marks; the lamp says
it with the object every user already has at arm's reach at 3am, on the nightstand
the identity is named for. It is literal where the marks were coded — nothing to
decode at 29 pt, no pill to misread, and nothing else in the category looks like it.

Rebuilding from tokens rather than shipping the photographic render is not
fastidiousness: the render is portrait, off-palette, and photographic gradients turn
to mush under the App Store's downscale. The generator keeps the icon versioned
source, palette-locked, and regenerable — the same properties every previous icon
decision paid for.

## Boundaries

- The identity guardrails held and hold: no fetus, no flower, no moon, no monogram,
  no red, no text.
- Decision 0035 stands: `ios-marketing` keeps its own file carrying the dark
  artwork, regenerated in the same run.
- The layer-export rules stand: `background`/`foreground` ship no baked halo; the
  shade keeps its interior gradient in the export because that is artwork, not
  effect.
- 0051's one lasting coupling — the icon regenerates when the tape component
  changes — dissolves with 0051: the lamp shares palette tokens with the app and
  nothing else.
