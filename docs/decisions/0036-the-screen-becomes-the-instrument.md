# 0036 · The screen becomes the instrument

**Date:** 2026-08-24 · **Item:** HL-003 · **Status:** decided

## Context

HL-001 gave the app the Nightstand identity's colours and type. What it could not
give it is the identity's *shape*, because the shape is a different screen: a
full-width slab where the circle is, an ember tape where the tick tape and the node
timeline are, an 84 pt live numeral where a 56 pt one sits inside a disc, a verdict
that arrives like dawn, and a glow that breathes at a guided respiration rate.

That is not a redesign for its own sake. Every piece answers something the walkthrough
or the competitor scan already found: a centred circle wastes the thumb zone
(Freya and Bloom both do it, and the reviews say "in transition I gave up"); the tick
tape and the node timeline say the same thing twice in two visual languages; and the
one feature the category's beloved app is credited for — paced breathing — costs us
nothing if the glow already breathes.

It is also the riskiest item in the document. `HushlightUITests` anchors on this
screen three ways: accessibility labels, copy fragments, and geometry. A rewrite that
moves all three at once has no way to tell a layout regression from a test that needs
re-cutting.

## Decision

**Land it in four slices, in this order, each passing §8, the AX5 gate and the QA
harness on its own.** The strategy that makes that possible: **freeze the
accessibility contract and change the geometry under it.** "Start contraction" and
"End contraction" describe the *action*, not the shape — a slab carries them verbatim,
and the mechanics suite survives a change that replaces the control it taps.

1. **The slab, and the hero leaves the disc.** The circle becomes a full-width
   bottom-anchored slab, and the live numeral moves out of it into the top of the
   scrolling content at the identity's ~84 pt. The two are one slice because neither
   works alone: 84 pt cannot fit inside a disc, and 56 pt alone in an empty upper
   third reads under-scaled. This goes first because every later slice's accessibility
   arithmetic is measured against the new bottom inset.
2. **The ember tape, with its elapsed-position scale marks.** Bar width is duration,
   the gap between bars is the interval, and the marks that make it numerate are part
   of the slice rather than a follow-up — a tape without a scale is atmosphere, and
   numerate is the whole positioning. Its window is `rule.sustainedWindow`, so
   decision 0026's honesty (a lull empties the leading edge) is what the geometry
   shows rather than something the copy has to say.
3. **The verdict as dawn.** Sage wash, leg meters, `Font.voice` on a true headline
   with the evidence staying prose.
4. **The breath-paced glow.** 4 s swelling, 6 s settling — roughly six breaths a
   minute, the calming cadence — as ambient light rather than a breathing *feature*.

## Rationale

**On the idle hero.** The identity shows "7:42 since last" in the hero slot when
nothing is running. We are not doing that: the header already prints `LAST 2 M AGO`,
and `SnapshotFactAssertionTests` anchors on that fact. Two renderings of one figure at
different scales is how a screen starts contradicting itself. Idle, the hero slot is
empty and the readout leads.

**On what the verdict may not lose.** The identity's own sample verdict copy —
"a good moment to call your midwife or provider and get moving" — drops the guideline
attribution and the their-instructions-come-first hedge. It is not shippable, and slice
3 rewrites around the existing sentence structure rather than the sample. The string
`guideline many providers use` is both a voice rule and a test anchor; it survives.

**On the leg meters.** They must read the same quantities the sentences do —
sustained evidence, the interval *range*, the duration average. A meter that
generalises where the sentence hedges is F-0012 again, in a new medium.

**Rejected: one big rewrite.** It would be faster to write and impossible to verify.
The harness's value is that a failure means something; a change that invalidates every
anchor at once converts it into noise for the length of the item.

**Rejected: keeping the circle and re-tinting it.** The circle is the category's
convention, adopted deliberately in SP-187 for good reasons that have since expired:
it was a competitor's *structurally good idea* borrowed before this app had an
identity of its own. The identity's answer — the entire lower third is the target, and
the thumb never has to find a centre — is strictly better on the axis this app is
judged by.

## Boundaries

No analysis, no verdict rule, no evidence floor, no threshold moves in any slice. The
Live Activity's contract is untouched. Every slice keeps: the em dash over a zero, the
provider-first hedge, the start-to-start definition, and the rule that nothing on this
screen ever shouts. When a slice needs a UI test re-cut, the re-cut lands in the same
commit with a comment saying which anchor moved and why.
