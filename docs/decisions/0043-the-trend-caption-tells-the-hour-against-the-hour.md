# 0043 · The trend caption tells this hour against the last one

**Date:** 2026-08-24 · **Item:** HL-016 · **Status:** decided

## Context

The identity's judged grafts ask for a sentence-level proof of the numerate
positioning: "averaging 5:40 apart, was 7:10 an hour ago" — the trend as two real
figures rather than an arrow or a mood. It is new *analysis* wearing a design
costume: an hour-ago comparison window with its own evidence rules, which is why the
backlog routes it through a decision and the SP-194 discipline (oracle moves with
the engine; harness re-runs) before a pixel is drawn.

## Decision

1. **The comparison is window against window.** The current figure is the windowed
   average interval the screen already prints. The reference is the same statistic
   over the window immediately preceding it — shifted back by exactly one window
   length, computed by the same code path with a different `now`. No new statistic
   exists; one statistic is evaluated twice.
2. **Both windows must independently clear the average's own floor.** A caption
   comparing a real figure to a guess is worse than silence; below either floor,
   no caption. No em dash here — an absent comparison is not a measurement slot.
3. **A delta under one-sixth of the reference is steady, and steady says nothing.**
   `|current − previous| × 6 ≥ previous` fires the caption; under it, the caption is
   omitted — printing "was 7:10, now 7:05" invites reading noise as signal, the
   exact jitter-anxiety this app exists to refuse. One-sixth, integer arithmetic,
   named constants beside 0040's and 0041's.
4. **The direction is words and figures, never colour alone**: "closer than an hour
   ago" / "farther apart than an hour ago", with the previous figure printed. The
   colour joins the words — `tint` warming, `easing` cooling, the token pair 0034
   defined for exactly this metaphor — but the palette rule stands: words carry it,
   colour seconds it. The identity's "Gathering" label is rejected: it is a word
   about her body wearing a weather costume, and 0041 already drew that line.
5. **It renders on History**, under the current episode's summary band — the
   reflective surface, read between contractions — never on the timer, whose
   readout decision-0022 discipline already dates and bounds. Spoken form matches.
6. **Oracle and harness move with it** (SP-194): the oracle computes the same
   two-window delta independently; a T0 probe holds engine and oracle to exact
   agreement on fired/direction/figures across the corpus.

## Rationale

**Why one-sixth.** On a 7:10 reference, one-sixth is ~72 seconds — about the gap
jitter an honest thumb introduces tap to tap (decision 0023's territory), so the
caption fires on change bigger than the recording noise floor. Relational, so 3-1-1
tightens it automatically.

**Why the previous figure prints.** "Trending closer" asks to be trusted;
"averaging 5:40, was 7:10 an hour ago" can be checked against History's own rows.
The difference is the app's entire epistemics.

**Rejected: rendering on the timer.** The timer answers "what is happening now";
the trend answers "how has the night moved", a History question. Two surfaces
answering each other's questions is how screens start contradicting.

## Boundaries

No verdict logic touches this; the caption never says anything about the rule, only
about the two figures. Evidence floors, thresholds, the latch: untouched.
