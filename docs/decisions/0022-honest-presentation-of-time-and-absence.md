# 0022 — Honest presentation of time and absence

**Status:** accepted (QA harness findings F-0004, F-0005, F-0016, F-0017, F-0021,
F-0022, F-0026 — first corpus run, decision 0021 process)
**Date:** 2026-08-16

## Context

The first 408-scenario QA run showed that the timer's figures are honest but
undated, and its silences are indistinguishable from its states. A screen 45
minutes after the last contraction renders the same present-tense figures it did
live; the guidance area goes blank exactly when evidence thins; the stale boundary
fires while a contraction is running and presents first-launch onboarding copy over
a live 121-minute count; at accessibility type the verdict — the one sentence the
app exists to deliver — sits entirely below the fold while data numerals wrap
mid-figure. None of these change what the app measures. All of them change what a
3 am reader believes it is saying.

## Decisions

1. **Staleness never fires against a running contraction.** The staleness clock
   (`> 2 h since latest start`) considers only *ended* contractions; while a record
   is open the episode is live by definition. The engine change is one guard in
   `PatternAnalysis.pattern`; the unit test that pins stale → `.empty` gains the
   running-record exception.
2. **The empty state remembers.** First launch keeps its current copy. When the
   store holds history but the pattern is stale, the state reads as a return, not
   an introduction: "Last contraction ended {n} ago." — a raw fact, no command.
3. **The header dates the data.** "LAST {n} AGO" joins SINCE — a raw fact, exempt
   from evidence floors, so present-tense averages can never masquerade as current
   for 45 silent minutes.
4. **The guidance area is never blank while an episode is live.** Below the verdict
   floor it states what is measured and what is missing, in figures: "Not at
   {rule} yet — averaging {i} apart and {d} long over {k} timed contractions." /
   "Last contraction {n} ago — not enough in the last hour to average." The
   malformed double-"yet" template is retired. No commands, no alarm register,
   evidence first — the voice rules hold.
5. **At accessibility type sizes the verdict leads.** `guidance()` renders above
   the readout when `dynamicTypeSize.isAccessibilitySize`; the three-column readout
   reflows to a stacked layout (ViewThatFits, the header's existing pattern). Data
   numerals never wrap mid-figure and never scale below legibility — reflow, not
   truncation, is always the answer (§8).
6. **A saturated tape yields.** Once `patternLength ≥ 1 h` the tick tape has said
   everything it can say; it stops rendering as live progress. Its final semantics
   (windowed continuity) belong to the sustained-dimension decision and are out of
   scope here.
7. **Zeros are never measurements.** The PATTERN slot renders an em dash below one
   minute (the "0 M" first impression), completing SP-191's zeros purge.

## Boundaries

No verdict mathematics change here beyond the staleness guard (which extends an
episode's *visibility*, never a verdict: the sustained window and floors are
untouched). Copy stays inside decision 0018's line — never "you are in labor",
never "you don't need to go yet", never a command.

## Alternatives rejected

- **A staleness banner instead of the running-record guard.** Explaining a
  contradiction is worse than not producing it.
- **Scaling numerals down at AXL.** Trades one truncation for another; reflow
  preserves both the figure and the type role.
- **Auto-expiring figures (blanking averages after n minutes).** The floors already
  define when figures mean something; dating the data keeps facts visible and
  honest without inventing a second expiry system.
