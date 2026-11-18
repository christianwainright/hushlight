# 0048 · Seconds appear where a gap is printed beside them

**Date:** 2026-08-26 · **Item:** HL-022 · **Status:** decided
· **Amends:** 0022 (honest presentation of time and absence)

## Context

History prints a contraction's start time as a clock reading — `8:22 PM` — and, beside
it, the gap from the previous contraction computed to the second: `+5:30`. Subtract the
two displayed times and you get five minutes flat. The app says five thirty. It is right
and the reader is right; the clock reading simply dropped up to fifty-nine seconds
before the reader ever saw it.

The walkthrough's partner lens found this, and its reasoning is the one that matters:
the person reading History aloud to a triage nurse may be asked to confirm an interval
by reading two start times, and the nurse will do that subtraction herself. Every row
is a chance for the app to appear to contradict itself in front of a clinician.

The same shape appears in two more places: the timer's episode timeline (`8:00 PM` above
`3:10 apart`) and the plain-text export — which is worse, because that one reaches the
nurse in writing with nobody present to explain it.

## Decision

**A start time prints its seconds wherever a reader checks a gap against it.** That is
History's rows and the plain-text export — visible text and spoken form alike, so what is
heard matches what is seen (0038).

**The timer's episode timeline keeps the minute, and that is a measured trade, not an
oversight.** Its leading column is 76 pt holding two stacked values; a time carrying its
seconds wraps mid-token into `8:34:57 P / M`, which reads as broken rather than reflowed.
Widening the column to 98 fixed the wrap and was then measured pushing the entire screen
into horizontal overflow at AX5 — content spanning the full width instead of stopping at
the margin, against a pre-change capture of the identical state that stopped correctly.
Buying arithmetic-checkability on the glanceable instrument at the price of a broken
layout for the largest-type reader is the wrong trade; the two surfaces where a figure is
actually read to a clinician carry the seconds instead.

**Standalone clock readings keep the minute.** The header's `SINCE 7:18 PM`, History's
`FROM 7:07 PM`, the recap's date: nothing is printed next to them that a reader could
check by subtraction, and seconds there would be noise bought for nothing.

## Rationale

**Why not round the interval instead.** Printing `+6:00` beside two minute-precision
times would make the arithmetic agree and destroy the figure. Thirty seconds is the
difference between a pattern at 5:30 and one at 6:00, and the guideline the whole app
exists to check is defined on exactly that scale. Rounding the meaningful figure to
protect the decorative one is the wrong way round.

**Why not a note explaining the rounding.** A footnote per screen, to pre-empt an
arithmetic check, on a screen a woman reads in the dark. The app's answer to "these two
figures look inconsistent" should be to stop being inconsistent.

**Why the clock reading is the one that yields.** A duration is a measurement this app
took; a clock time is a label on a moment. When they disagree, the measurement is the
thing worth protecting — the same instinct as decision 0032's "displayed durations remain
exact — a slip prints 0:11, never rounded or hidden."

The cost is honest and small: three surfaces get five characters wider in a monospaced
column that was already carrying figures.

## Boundaries

No engine change. `PatternAnalysis.interval(from:to:)` is untouched and remains the one
definition of a start-to-start gap; this entry governs display only. Locale handling
goes through `Date.FormatStyle`, so a 24-hour locale gets its own shape and HL-007's
rule — instrument figures are locale-invariant, clock readings are not — is unaffected.
