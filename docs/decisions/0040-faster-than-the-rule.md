# 0040 · Faster than the rule: the early line, and what may fire it

**Date:** 2026-08-24 · **Item:** SP-207 · **Status:** decided

## Context

Precipitous labor reads as reassurance today. At 2:00 apart, lasting 1:20, thirty
minutes in, the screen says only "Not at 5-1-1 yet" — because `sustainedMet` gates on
the full hour, and the hour is the one thing a fast labor does not grant. The
walkthrough ranked this among the harshest failures: the situation where waiting out
the window is exactly wrong is the situation the window silences.

The trap on the other side is inventing a clinical threshold. This app reports a
pattern against a guideline the user chose; a "precipitous alert" with its own
made-up numbers would be the diagnosis business the whole design refuses.

## Decision

1. **A second presented state, `fastMet`, strictly stronger than the rule on two
   legs and early only on the third.** It fires when, within the same analysis
   window and evidence floor the verdict already uses:
   - the **frequency share** holds at **half the rule's interval threshold** — the
     same two-thirds share machinery as `frequencyMet` (decision 0024), evaluated at
     `intervalThreshold / 2`. Under 5-1-1 that is two-thirds of gaps at or inside
     2:30. Half is not a medical number; it is "decisively tighter than the rule she
     chose", derived from her rule and nothing else.
   - **duration meets its normal bar** (`durationMet`, unchanged).
   - **continuity is unbroken so far**: no gap over `sustainedGapLimit` anywhere in
     the pattern — a burst-lull-burst is not a fast labor, it is the pattern 0026
     exists to catch.
   - the pattern is at least **twenty minutes** old — one third of the sustained
     window, so the claim "before the hour" has a floor under it and six quick taps
     cannot conjure it (`fastMetMinimumLength`, its own named constant).
   - and the full verdict is **not** met — `met` outranks it; the moment the hour
     completes, the ordinary verdict takes over and this state retires.

2. **It latches exactly as the verdict latches** (decision 0025, same mechanism,
   same ten minutes): a screen-reordering, call-suggesting banner may not flap on a
   windowed share wobbling across a boundary.

3. **The copy is measured figures plus the standing sentence.** The banner's shell
   and sage treatment are the met verdict's own (one banner grammar, decision 0036):
   the evidence line prints the same three bound figures every other shape prints,
   and the second line reads: "That is closer together than the 5-1-1 guideline
   asks, before the hour it also asks for. Calling your provider now is reasonable —
   their instructions come first." It describes her numbers against her rule. It
   names no condition, sets no new threshold, and keeps the anchor sentence
   (`guideline many providers use` stays the met shape's; this shape has its own
   stable wording for tests to hold).

4. **Engine, oracle, and fold move in the same edit** (the SP-194 rule), and the
   harness re-runs with the precipitous archetypes before the item closes. The
   oracle's judgement of "should have said something by now" for fast corpora is the
   evidence this feature is measured against, not the demo seed.

## Rationale

**Why half the threshold, and not a fixed "2 minutes".** A fixed number is a
clinical claim. Half *her* rule is a relational claim — "markedly inside what you
were told to watch for" — that scales with 4-1-1 and 3-1-1 automatically and can be
defended to a reviewer in one sentence.

**Why the share and not the mean.** The same reason as 0024: a mean is one outlier
away from lying in either direction, and this state suggests a call. Every
threshold-shaped question in this engine is a share question now; introducing a mean
here would be the inconsistency.

**Why twenty minutes.** Below it, the evidence floor (six in window) can technically
clear while the whole pattern is a ten-minute flurry — the kind false starts are made
of. A third of the window is long enough that the word "pattern" is honest and short
enough that a genuinely fast labor (which can deliver inside two hours) is told
something useful in time to act.

**Rejected: relaxing `sustainedMet` itself.** The hour is load-bearing for the
ordinary verdict (0026); bending it for the fast case would quietly weaken the slow
one. A separate state keeps both honest.

**Rejected: a distinct visual register.** A second, louder treatment is the alarm
register by the back door. The moment already has the screen's one moment of
priority; the fast case borrows it rather than escalating past it.

## Boundaries

No threshold, floor, latch duration, or window moves for the ordinary verdict. The
Live Activity contract is untouched (the lock screen's verdict line follows the app
on next update; a contract change for fast-met would be its own decision). The copy
ships through the same voice tests as everything else, and `Disclaimers.neverSays`
applies to it in full.
