# 0039 · The call script renders in LaborKit, and mm:ss exists twice

**Date:** 2026-08-24 · **Item:** SP-206 · **Status:** decided

## Context

SP-206's sentence — "Contractions every 5:00 on average (ranging 4:20–5:40), lasting
about 1:02, since 6:17 PM — 14 so far" — has to be asserted against literal text in
package tests: its clauses omit under evidence floors, and an omission rule that only
a screenshot can check is an omission rule that will drift. But the app's one
rendering vocabulary, `LaborFormat`, lives in the app target, and LaborKit is
dependency-free on purpose (decision 0018).

Something had to give: either the composition moves into the app (untestable at the
package level), or LaborKit gains a dependency (0018 says no), or LaborKit renders
the sentence itself with its own minimal formatting — a second implementation of
"seconds as mm:ss".

## Decision

The third. `CallSummary` composes *and renders* in LaborKit, with a private
`CallSummaryFormat` for mm:ss and time-of-day. The duplication is accepted, named,
and bounded.

## Rationale

The one-definition discipline this repo actually enforces (F-0012, SP-191) is about
**derivations**: two computations of an average will disagree, and did. It is not
about **renderings**: two formatters printing the same `Duration` as "4:50" cannot
disagree in a way that reaches a reader, and every figure the sentence quotes is
still read exactly once — through `EpisodeSummary`, which rests on the engine's one
`interval(from:to:)`.

The alternative worth naming: promote `LaborFormat`'s one-line formatters into a
shared dependency-free module both targets import. It is the cleaner end state and a
wider refactor than this item — it touches every screen `LaborFormat` serves — so it
stays an option this entry records rather than work this item smuggles in. If a third
formatter copy is ever about to appear, that refactor stops being optional.

## Boundaries

`CallSummaryFormat` stays private to LaborKit and renders nothing but this sentence
and its export. App surfaces keep rendering through `LaborFormat`, including the
export's per-contraction lines, which call the exact functions History's rows call.
