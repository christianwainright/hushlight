# 0059 · One walk, not two

**Date:** 2026-09-05 · **Item:** HL-043 · **Status:** decided

## Context

HL-043 was filed to make the QA suite faster, and it named its target confidently:
"two parameterised replay tests are effectively all of it —
`theModelSnapshotTracksTheFold` (55 cases) and `theEngineAndTheOracleStillAgree` (9)".
That came from Swift Testing's own output, where both tests report durations near 250 s.

**Both numbers were wall clock, not cost.** Every suite in that run reported the same
248.85 s, because a parameterised test's reported duration spans from its first case
starting to its last case finishing — across a parallel run. It says when a test
finished, never what it consumed. The item was built on it anyway.

## Evidence

Instrumented, then attributed by running each test class alone against one pre-built
bundle:

| Class | Wall | Tests |
|---|---|---|
| **PureSweepTests** | **195.8 s** | 4 |
| PinTests | 16.6 s | 13 |
| StoreReplayTests | 7.6 s | 4 |
| ModelReplayTests | 7.4 s | 3 |
| everything else | < 5 s each | — |

`theModelSnapshotTracksTheFold` — one of the two the item blamed — lives in
ModelReplayTests, the whole of which is **7.4 s**. Phase timing inside it put the entire
55-case body at about four seconds: `generate` 6 ms, `run` 130–170 ms, the fold loop and
the results write about 1 ms each per case. The named tests were never the cost.
`PureSweepTests` is roughly 80% of the suite.

And PureSweep's own loop is already about as tight as it can be: an incremental
`ReplayEngine.Cursor` rather than re-folding per probe, record projection rebuilt only
when the cursor's generation changes, and Swift Testing parallelising the cases — 1,460
CPU-seconds inside 195 s of wall clock is roughly 7.5x. What remained was genuine
computation: `PatternAnalysis.pattern` evaluated at every one of 200,000+ probes.

**The duplication was in the app, not the harness.** `pattern(for:rule:now:)` called
`presentedMet` and `presentedFastMet`, and those two functions were identical line for
line except for which field they read off the same `rawPattern`. Both computed the same
pre-check, both computed the same `atNow`, both applied the same no-figures guard, and
both walked the same ten minutes at 30-second steps, reconstructing the same records and
re-deriving the same raw verdict at each step. Every latched probe did all of it twice.

Measured on a fixed store that reaches the latch — 14 contractions eight minutes apart,
so the pre-check passes, the raw verdict says no, and the walk runs its full grid — 2,000
calls, three runs each:

| | ms per `pattern()` call | median |
|---|---|---|
| two walks | 0.718 / 0.741 / 0.741 | **0.741** |
| one walk | 0.390 / 0.365 / 0.365 | **0.365** |

**2.03x.** The variance is tight and the figure is load-independent, which matters here:
the machine was running Spotlight at 50% CPU during this work, and a wall-clock
comparison of the sweep drifted by 70% between runs on that alone.

## Decision

`presentedLatch(for:rule:now:)` performs one backward walk and returns both flags.
`presentedMet` and `presentedFastMet` remain public and now read from it, so the tests
that call them directly are untouched and there is still exactly one implementation of
the latch — which is the rule `rawPattern` already states in its own comment about not
growing "a lean second copy".

**The fusion is exact, not approximate.** Each flag asks whether the raw verdict was true
at *any* instant on the grid, and existence does not depend on the order the grid is
walked or on which flag is being sought. The one behavioural difference is that the loop
now stops when both answers are known rather than when either is: that changes how soon
the walk ends, never what it concludes.

## Consequences

The app pays this once a second on screen — `TimelineView` drives `pattern()` at 1 Hz
while a contraction runs — so this is a battery and latency win on a phone at 3am, not
only a test-suite one. That was not the goal, and it is the better half of the result.

Correctness rests on the harness rather than on this argument. LaborSim's 176 tests pass
unchanged, which means `OracleMath` — a deliberately independent second implementation of
the same arithmetic (decision 0021) — still agrees with LaborKit at every probe of the
whole corpus. All six rubric mutations still apply verbatim: the pre-images they match
live in `rawPattern` and its helpers, none of which moved.

## Rationale

Three items in a row have now turned on the same thing, and it is worth stating as a
habit rather than rediscovering a fourth time: **HL-041's premise was wrong, F-0032's and
F-0038's evidence had expired, and HL-043 named the wrong tests.** Each was written in
good faith by someone reading a number that did not mean what it appeared to mean — a
reported duration, a test that "changed nothing", an element description.

The defence is not more caution about writing backlog items. It is measuring the thing
again before acting on it, which costs one instrumented run and has now three times
changed what the work was.
