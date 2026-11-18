# 0031 — No automatic macOS CI. Verification is local.

**Status:** accepted (Christian's call, 2026-08-23)
**Supersedes:** [0030](0030-the-macos-tier-is-opt-in.md)
**Date:** 2026-08-23

## Context

Decision 0030, hours old, made the macOS tier opt-in: a `[ci full]` commit flag,
a manual dispatch, or any PR would start it. It measured the real cost — ~35
minutes a run, ~350 billable minutes at the 10x multiplier — but it kept three
automatic doors open and then wrote an agent convention (*"end a session that
changed real code with `[ci full]`"*) that walked through one of them on every
working session. An opt-in that agents are instructed to opt into is not opt-in.
It is the old bill with extra steps.

The simpler fact 0030 danced around: **Christian does not need iOS builds to
happen remotely.** He has the toolchain, the simulator, and the same scripts CI
runs. A hosted macOS runner was never buying verification he lacked — it was
buying a slower, costlier copy of what his laptop already does.

## Decision

**No automatic trigger reaches the macOS job. Ever.**

Push, pull request, schedule, commit message, label, branch name — none of them
can start it. The job's condition is `github.event_name == 'workflow_dispatch'`
and there is nothing else to satisfy. **`[ci full]` is gone**, along with the
commit-message parsing that read it; the convention telling agents to write it
is struck from CLAUDE.md and replaced by the opposite instruction.

What still runs automatically is the ubuntu `gate` job, unchanged: the §8 literal
lint, the no-remote-dependency grep, and the `affected.sh` computation. It costs
seconds on the cheapest runner and it catches the class of mistake a local build
genuinely can miss — a banned hex literal, a remote package appearing. A push
that skips the macOS tier prints a `::notice::` saying so and pointing at the
local scripts, so a green check is never mistaken for "the app compiles."

The job is kept, not deleted. **Manual dispatch is the one door**, for the case
that actually justifies a hosted runner: SP-042a means app-target UI tests may
not launch on a developer machine at all, so the AX5 accessibility gate has no
guaranteed local home. Before a submission, or when that gate must be proven,
Christian presses Run workflow. Deleting the job would throw that away to save
nothing — an unstarted job costs zero.

## Consequences

**CI no longer tells you whether the app builds. That is now entirely local.**
`./scripts/test.sh $(./scripts/affected.sh suites origin/main)` is the contract,
and an agent that has not run it has not verified anything. The honest phrasing
that goes in every future session: *green on GitHub means the lint passed, and
nothing more.*

The risk this accepts is a compile break reaching `main` unnoticed. It is a real
risk and it is the right trade here: a solo repo where the one developer builds
locally before every commit does not need a second machine to repeat the build at
10x the price, and the cost of the break is a local rebuild, not a shipped defect.

This also makes the remaining performance work (~23 min of test-step overhead,
~11 min of AX5) matter less urgently, since it is now paid only when asked for.
It does not make it wrong — a manual run is still worth being fast, and the
overhead is 76% waste either way. That work stays queued, unclaimed here.
