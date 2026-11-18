# 0056 · The simulator was never the cost

**Date:** 2026-09-05 · **Item:** HL-041 · **Status:** decided — **do not do it**

## Context

HL-041 was filed on a hypothesis: LaborSim's suite is slow because it is dragged onto
an iOS simulator by LaborKit's `ActivityKit` import, and freeing it would make it fast.
Decision 0054 called it "the change that removes the cost rather than relocating it."

It was built. It works. It does not pay.

## Evidence

LaborKit and LaborSim were given `.macOS(.v15)`, the ActivityKit surface was gated, and
both packages built and tested natively. Measured head to head on one quiet machine:

| | Tests | Test time | Wall clock |
|---|---|---|---|
| LaborSim, iOS simulator | 176 | 266.8 s | **4:40.6** |
| LaborSim, native macOS | 174 | 248.9 s | **4:22.0** |

**About 7%.** The suite consumes ~1,460 CPU-seconds across ~5.6 cores; it is
compute-bound, and the host is nearly irrelevant. Two parameterised replay tests —
`theModelSnapshotTracksTheFold` (55 cases) and `theEngineAndTheOracleStillAgree` (9) —
are effectively the whole suite. The 543 s seen on CI is that same work on a three-core
runner, which the arithmetic predicts almost exactly. The simulator was never the cost.

The attempt also surfaced a reason not to want it. Run natively, **LaborKit fails two
tests that pass 213/213 on the simulator**, both on pluralization: the report body reads
"14 contraction across 2 episode". Its String Catalog resolves plurals differently in a
SwiftPM macOS build. No user is affected — the app is iOS-only and iOS is green — but it
means a native leg would not be testing the same thing the product does, which is the
opposite of what a test host is for.

## Decision

**HL-041 is closed without the migration.** No macOS platform in any manifest. The
authoritative suites keep running where the product runs.

What is kept is the defect the attempt uncovered: the `#if canImport(ActivityKit)`
guards in `ContractionActivity.swift`, `StartStopContractionIntent.swift` and LaborSim's
`LiveActivitySentinelTests.swift` **gated nothing**. ActivityKit imports fine on macOS —
its symbols are merely marked unavailable — so the condition was always true. Building
for macOS produced 19 unavailability errors straight through those `#if`s. They are now
`#if os(iOS)`, which is what they were always meant to say.

## Consequences

CLAUDE.md's existing warning — bare `swift build` in a package directory targets macOS
and will fail on iOS-only API — stands, and is now measured rather than asserted.

The real target, if the suite ever needs to be faster, is the ~1,460 CPU-seconds
themselves: the corpus size, the replay work per case, or the parameterisation of those
two tests. **HL-043** carries that. Nothing about it involves a host.

## Rationale

This entry exists because the work was done and the answer was no, and that is worth
more written down than quietly reverted. The hypothesis was plausible, cheap to test,
and wrong; a future session reading 0054's confident "this is the fix" would otherwise
rebuild it. Decision 0054 stands on its own evidence — tests do not belong on the
release path — but its closing argument about *why* LaborSim is expensive was mistaken,
and this supersedes that reasoning without disturbing that decision.
