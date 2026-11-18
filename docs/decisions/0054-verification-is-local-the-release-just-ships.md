# 0054 · Verification is local; the release pipeline just ships

**Date:** 2026-09-05 · **Item:** HL-041 · **Status:** decided · **Extends:** 0031

## Context

Decision 0031 made the macOS CI tier manual-only for two reasons: macOS runners bill
at the 10x multiplier, and Christian verifies iOS code on his own machine. `release.yml`
was written after it and did not inherit the reasoning — it defaulted `run_tests` to
`true`, so every upload paid for a full macOS test run.

The 1.0 (2) attempt made the cost legible. It spent **35 minutes** in "Package tests
and D1 gate" and was cancelled before it ever reached Archive, re-proving a suite that
had gone green locally on the same commit minutes earlier. The previous run's logs give
the split:

| Package | Test time | Wall clock |
|---|---|---|
| DesignKit | 2.9 s | ~2m 18s |
| LaborKit | 20.8 s | ~2m 06s |
| **LaborSim** | **543.6 s** | **~11m 09s** |
| D1 gate + app build | — | 51 s |

LaborSim was 11 of 16.4 minutes on the fast `xcode-27` image, and roughly triple that
on the standard one. The gate — the part that catches the rules this project actually
cares about — is 51 seconds.

## Decision

**`run_tests` defaults to `false`.** The release pipeline archives, validates and
uploads. Turn tests on deliberately when there is a reason to want a second opinion:
before a first submission, or after a toolchain, runner-image or dependency change.

What still protects the artifact, with tests off:

1. **The ubuntu gate runs on every push** — the literal, logging, localization and
   row-figure linters, at about six seconds on the cheapest runner. That is the tier
   that encodes this project's actual invariants, and it never needed a simulator.
2. **Archive is a real compile.** A tree that does not build cannot upload; the
   failure simply arrives at Archive instead of at a test step.
3. **The runner checks out the pushed ref**, not anyone's worktree, so what ships is
   what was committed. That was the one honest advantage CI had over a local run, and
   it survives the change.

## Consequences

The obligation moves to where the work happens: `./scripts/test.sh` and
`./scripts/gate.sh` before pushing, and the buildlog entry says so. This is the same
bargain decision 0031 struck, applied to the pipeline 0031 predates.

It also removes a quiet failure mode. A 35-minute step on every upload is how an
upload stops being a thing anyone starts — and a release path people avoid is worse
than one that tests less.

## Rationale, and the fix this defers

The honest reading is that LaborSim should not cost this in the first place. It is
pure logic — a replay engine and an oracle, importing only Foundation, CryptoKit,
SwiftData and Testing — and it is dragged onto an iOS simulator only because it
depends on LaborKit, which imports `ActivityKit` for the Live Activity attributes and
is therefore iOS-only. Gate that import and the suite could run natively.

That is **HL-041**, and it is the change that removes the cost rather than relocating
it. This entry is the interim: stop paying 10x for a run whose result is already
known, while the thing that makes it expensive gets fixed on its own terms.
