# 0047 · Two windows, and which one is speaking

**Date:** 2026-08-26 · **Item:** HL-021 · **Status:** decided

## Context

This app computes an average interval two ways, both correct, both necessary:

- **The rule's window.** `LaborPattern.averageInterval` reads the trailing
  `rule.sustainedWindow` — the hour the guideline is actually defined over (0026).
  The verdict, the readout columns, the banner's legs, History's pinned legs and the
  trend caption's "current" figure all read this.
- **The whole stretch.** `EpisodeSummary` reads every contraction in the episode.
  History's per-episode band, the closure recap and the call card read this.

Neither is a second derivation of the other (F-0012's sin); they answer different
questions. The walkthrough found that nothing on screen says which question is being
answered, and that the two collide in two places: History shows `APART 6:30` six lines
above `AVG 6:51 APART`, and the timer's banner shows `APART 5:00` one tap from a call
card quoting a different average for the same words. A partner reading figures aloud to
triage can be handed both.

Worse, and found only by reading the code: History's pinned legs are grouped for
VoiceOver under the label **"Tonight so far"** — a statement that is simply untrue of
figures covering the last hour.

## Decision

**Neither window changes. Every surface that prints an average must make its window
recoverable without leaving the screen.**

1. **The guideline's legs keep the rule's window** — they exist to show the rule being
   checked, and the rule is checked over the hour. Nothing about the verdict moves.
2. **History's episode band names its scope** in the band itself, since it sits directly
   beneath the legs and is the collision the walkthrough actually caught.
3. **The call card names the difference out loud**, because its reader is the one person
   who will be reading a *different* figure aloud a second later. One quiet line under
   the script, naming what the figures cover and what the timer's own figures cover.
4. **The false VoiceOver label is corrected.** "Tonight so far" becomes a description of
   what the legs are.

## Rationale

**Why not collapse to one statistic.** The obvious "fix" is to make everything read one
window. It fails in both directions: force the call card to the hour and its own sentence
("since 6:17 PM — 14 so far") starts lying about what it summarises; force the verdict to
the whole stretch and 0026's sustained-hour rule is gone, which is the one thing HL-021
was told not to touch. Two questions genuinely exist. The defect was never the arithmetic
— it was the silence about which question each surface answers.

**Why the call card gets a sentence and the banner does not.** The banner's legs sit
inside a card that already states the rule and its hour in words ("That meets the 5-1-1
guideline many providers use", where 5-1-1's third leg *is* the hour). The call card, by
contrast, is read aloud in isolation, by someone who was looking at the banner seconds
earlier. It is the only surface where a reader holds both figures at once, so it is the
only one that needs to name the difference rather than merely imply it.

**Why "HOLDING" is not caught by this.** The third leg is a span, not an average — how
long the stretch has run — and it reads correctly under either framing. Only averages
need a window stated, which is why this entry labels bands and cards rather than blanket-
captioning the leg group with a window that would be wrong for one of its three rows.

## Boundaries

No threshold, floor, window or latch moves. `PatternAnalysis` is untouched; this is a
copy and accessibility change. The call card's pinned sentence is unchanged — the new
line sits beneath it, so `CallSummaryTests`' verbatim pins still hold.
