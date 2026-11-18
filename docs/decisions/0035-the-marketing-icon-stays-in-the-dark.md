# 0035 · The marketing icon stays in the dark

**Date:** 2026-08-23 · **Item:** HL-002 · **Status:** decided

## Context

iOS gives an app three icon slots — the base image, a dark-appearance variant, and a
tinted one — and the asset catalog's `ios-marketing` entry has always pointed at the
same file as the base. The Nightstand identity asks for two of those to be opposites:
the dark icon is *the* identity (a warm near-black field, one glowing ember, a soft
bloom), and the light variant inverts it to warm paper with a deep-amber bar and no
bloom.

That inversion is right on a home screen and wrong in the App Store. The naming and
positioning research is explicit about where this icon earns its keep: a results row
for "contraction timer" is a wall of lavender pastels, white circles and clinical
"Counter & Tracker" names, and our icon's whole job there is to read as *a calm
glowing thing in the dark*. The store shows the marketing icon. Pointing it at the
paper variant spends the one differentiator we have on the one surface that decides
whether the app is opened at all.

## Decision

The `ios-marketing` slot gets its own file, `icon-1024-marketing.png`, carrying the
dark ember artwork. The three appearance slots are unchanged in intent: paper on a
light home screen, ember-in-the-dark on a dark one, silhouette when tinted.

## Rationale

The alternative is to make the base image the dark ember and drop the paper
inversion, which would keep the store right and lose a piece of the identity for
every user whose phone is in light appearance — the same trade in the other
direction, and a worse one, because the home screen is where an app lives for the two
weeks it matters.

The cost of the split is honest and small: one more 1024 PNG in the repo, and the
rule that the marketing artwork and the dark variant must be regenerated together.
Both come out of the same generator in the same run, which is what keeps them from
drifting.

A store icon that does not match the icon a user then sees on their home screen is a
real (small) dissonance. It resolves the moment the phone is in dark appearance,
which is this app's primary environment by decision 0018 — and the two artworks are
the same drawing, not two designs.

## Boundaries

Nothing about the app's behaviour, and nothing about the App Store listing copy,
which HL-004 owns. If Apple's icon pipeline changes to a single `.icon` document with
its own appearance model, this entry is the thing to re-read: the split exists
because the marketing slot is separately addressable, and it stops being needed the
moment it is not.
