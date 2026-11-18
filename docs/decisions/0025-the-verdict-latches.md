# 0025 — The verdict latches

**Status:** accepted (finding F-0009 — 61 scenarios flap; the met-reorder yanks
scroll position mid-contraction)
**Date:** 2026-08-16

## Context

`met` is recomputed instantaneously; a mean drifting across its threshold as old
intervals age out of the window flips it, the banner appears and vanishes, and the
timer screen reorders (verdict-leads-when-met) on every flip — with a spring
animation that can insert a several-hundred-point block above the reader's scroll
position and then take it back. Alarm that retracts itself teaches the user to
distrust the one sentence that matters.

## Decisions

1. **Onset is immediate; release is debounced.** `met` turning true is never
   delayed — the safety asymmetry forbids adding latency to the alarm side. Once
   true, the *presented* verdict holds until the raw verdict has been continuously
   false for **10 minutes**; a single tick of contrary evidence cannot retract it.
2. **Statelessly.** No stored flag — wall-clock truth applies to the verdict too. A
   pure helper derives the latched verdict from (records, rule, now) by evaluating
   the raw verdict over the trailing ten minutes at 30-second cadence: latched =
   raw(now) OR any raw(t) in the window with no ≥10-minute false run since. Kill
   and relaunch reproduce the same latched state from the same records.
3. **The screen reorders only on latched transitions**, so layout changes are as
   rare as genuine state changes. The banner shows live figures always; if the
   pattern truly decays, the banner leaves once — ten minutes after the evidence
   went, not the instant a mean wobbled.
4. Metrics: the flap counter keys on the latched verdict; the raw flap count stays
   recorded in results for calibration.

## Boundaries

The underlying dimensions and floors are untouched; this is a presentation latch
over an unchanged raw verdict, and the raw verdict remains what the oracle checks
exactly. Ten minutes is the harness-calibrated release: long enough to absorb every
observed wobble (worst observed flap spacing < 7 min), short enough that a genuine
fizzle reads honestly within one contraction's spacing.

## Alternatives rejected

- **Symmetric hysteresis (delayed onset).** Trades alarm latency for calm — the
  wrong direction under the ranking law.
- **Margin-based hysteresis (release below threshold − ε).** Tunes forever and
  still flaps at the margin's own edge; time-based release is legible and testable.
- **Animation-only fixes.** The reorder is the symptom; the retracting verdict is
  the defect.

## Amendment (2026-08-16, post-implementation run 20260816T192715Z)

The corpus reclassified the churn: of 69 residual flaps, 54 were the verdict
vanishing because the in-window count dipped below the evidence floor mid-labor
(a contraction aging out, a missed tap) — not mean drift, which the latch as
implemented (on `GuidelineStatus`) already absorbs. A verdict that leaves because
one contraction aged out of the hour while labor visibly continues is exactly the
retraction this decision exists to stop. **The latch therefore moves to the
pattern level:** `presentedMet` survives sub-floor evidence dips under the same
single 10-minute release clock, rendering with whatever figures still stand their
own floors plus 0022's dating — and the banner never renders with no figures at
all. Decay through the dimensions and decay through the floor now read the same
way: the banner leaves once, ten minutes after the evidence went.
