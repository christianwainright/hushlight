# 0041 · Naming the irregular early stretch, and licensing rest

**Date:** 2026-08-24 · **Item:** SP-209 · **Status:** decided

## Context

The irregular state prints its spread ("7:00–12:00") and stops. The silence reads as
something going wrong, and the walkthrough's long-haul lens named the cost: a woman
who takes variance for failure times every contraction for eight hours and arrives
exhausted at the moment that needs her rested. The fix is one sentence — and it is
the closest any copy in this app comes to describing her body rather than her
numbers, which is why it gets a decision instead of a commit message.

## Decision

1. **When it fires.** In the partial state only (never over a met, held, or
   fast-met banner), when the evidence floor is met and both hold:
   - the spread is **wide**: the interval range's upper bound is at least **1.5×**
     its lower bound;
   - the average is **well above the rule**: at least **1.5×** the chosen interval
     threshold (7:30 under 5-1-1).
   Both are relational — derived from her own figures and her own rule — and both
   live as named constants beside the share constants they resemble.

2. **What it says**, appended to the partial line's existing sentence:
   > "Spacing that varies before it settles is how early stretches often look. A
   > stretch timed now and then shows the same pattern — this doesn't need
   > watching continuously."
   The first sentence describes *stretches of timing* — the numbers' behaviour,
   not her body's. The second licenses rest as a fact about measurement: an
   intermittent sample of a slow, irregular pattern shows the same slow, irregular
   pattern. No prognosis ("it will settle"), no instruction ("stop timing"), no
   reassurance about outcomes ("everything is fine") — those are the three ways
   this sentence goes wrong.

3. **Spoken form matches**, and the line joins the voice tests: `neverSays` in
   full, plus its own pinned copy test so a future rewrite is a deliberate act.

## Rationale

**Why 1.5× twice.** The backlog's own motivating example — 7:00–12:00 against
5-1-1 — must fire (ratio 1.71, average ~9:30), and a barely-uneven pattern hovering
near the threshold must not: near the rule, variance is the story *tightening*, and
telling her to rest at 5:30 apart would be the opposite error. Relational bounds
scale with 4-1-1 and 3-1-1 for free.

**Why "often look" and not "is normal".** "Normal" is a clinical judgement about
her. "How early stretches often look" is an observation about timing data. The gap
between those two sentences is the app's entire licence to exist.

**Rejected: firing on wide spread alone.** Coupling (decision 0024's bimodal case)
produces wide spreads *at* the threshold — the exact pattern that deserves closer
attention, not a rest note.

## Boundaries

No engine change: both predicates read figures `LaborPattern` already carries. The
partial line's existing missing-leg wording (SP-201) is untouched; this line follows
it. If SP-207's fast-met state is present, it wins the surface outright.
