# 0023 — Duration evidence under real thumbs

**Status:** accepted (findings F-0006, F-0007, F-0015 — the first corpus run's
headline; 46 of 221 truly-met scenarios never showed a verdict)
**Date:** 2026-08-16

## Context

The verdict's duration dimension is a hard `average ≥ 60 s`. The harness showed the
recorded average systematically understates the true one: a user taps start late —
reaction time plus waiting to be sure it is real (noise-model medians 3–25 s by
profile) — and taps end when it ends, so recorded duration ≈ true − start-latency,
while start-to-start intervals cancel the latency out. A true 75 s contraction
recorded as 55 s is permanently unmet. This one mechanism, compounded by lost taps,
accounts for every suppression in the run; the evidence floors were exonerated
(starvation p50 −235 min). The suppressed users are precisely the exhausted ones —
the safety asymmetry's worst case.

PatternAnalysis's founding comment says "no fudge factors: a near-miss is visible
as a near-miss instead of being quietly rounded into a pass." The current behavior
violates the same principle in the other direction: real passes are quietly rounded
into misses by a measurement artifact. The principle we keep is *visibility*, not
the number 60.

## Decisions

1. **The duration dimension gains a stated measurement allowance: `durationMet` at
   recorded average ≥ 50 s.** The displayed figures remain exact — a 55 s average
   prints 0:55, never rounds — so a near-miss is still visible as exactly what it
   is. The allowance is disclosed, not silent: the Guidance explainer states that
   timing starts at the tap, recorded durations run behind the felt minute, and the
   guideline check allows for that. `GuidelineRule.durationThreshold` (60 s, the
   rule as stated) and the new `durationEvidenceThreshold` (50 s, what the boolean
   uses) both exist so copy can name each honestly.
   *Calibration evidence:* at 8 s median latency (typical solo) suppressions were 5;
   at 20–25 s (exhausted/chaotic) they were 39. A 10 s allowance recovers the
   typical-and-better population without accepting Braxton-Hicks-length
   contractions (true 30–55 s BH recordings still fail at 50 s minus latency).
2. **Suspect presence relieves the duration floor by one.** With ≥6 in window and
   ≥1 suspect among them, the usable-duration floor drops from 3 to 2: a forgotten
   stop-tap is itself evidence a contraction happened and ran long, and it must not
   be able to null the entire verdict (F-0007's edge).
3. **The window keeps its bridging interval.** An interval whose *later* endpoint
   starts in-window is last-hour evidence; dropping it because its earlier endpoint
   predates the window biased averages toward recent spacing and delayed the floors
   (F-0015). `startToStartIntervals` over the window now includes the entry
   interval.
4. **How It Works gains one line** in the interval lesson's register: timing starts
   at the tap, so recorded durations run a little behind the felt contraction.

## Boundaries

Displayed figures never change meaning; only the boolean's threshold and the
evidence accounting do. The 5/4/3-minute interval thresholds and the sustained hour
are untouched here. LaborKitTests' duration boundary cases move to the new
threshold both-sides (49 s fails, 50 s passes) — the tests are the contract and
move with the decision, in the same commit.

## Alternatives rejected

- **Lower the displayed rule to 5-0:50-1.** The rule is the providers' language;
  the app must speak it. The allowance is measurement calibration, not a new rule.
- **Robust statistics (p75/max) on durations.** Latency shifts the whole
  distribution; no order statistic recovers what wasn't recorded.
- **Trailing-edge anchoring (time from previous end).** Changes the clinical
  definition of frequency the app exists to get right.

## Amendment (2026-08-16, post-implementation run 20260816T192715Z)

Measured effect: suppressions 46 → 38. The allowance recovered the typical-and-
better population (typicalSolo 5→3, clockHostile 2→1, plus onset-delta collapses:
partnerDiligent 16.0→0.1 min, typicalSolo 42.5→20.7); the residual concentrates
where start-latency (20–25 s median) exceeds the 10 s allowance. **The allowance
stays 50 s.** A tap timer cannot recover seconds nobody recorded; widening further
would admit true Braxton-Hicks-length contractions to the verdict. The residual is
an accepted limitation of tap-based measurement, mitigated by 0022's presentation
(the partial line always names the recorded duration, so a met frequency beside
"lasting 0:48" is visible evidence a provider call can weigh) and by How It Works
teaching the latency. Four clean-thumb false-mets on true 50–55 s patterns are the
trade's other side — S2 alarm accepted over S4 silence, per the ranking law. The
truth oracle's duration margins align with this calibration in the harness wave
(mustNotFire at ≤45 s), so the gray zone brackets the decided threshold rather
than the superseded one.
