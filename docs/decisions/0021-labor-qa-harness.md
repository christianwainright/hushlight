# 0021 — A QA harness judges the timer against a clinical-intent oracle

**Status:** accepted (Christian requested the capability 2026-08-16: "hundreds of
different pregnancy scenarios… see how the app actually behaves, evaluate, and
suggest improvements"; scope confirmed to include fixing the top findings)
**Date:** 2026-08-16

## Context

The contraction timer shipped A1 on 39 unit tests and one manual simulated-labor
device pass (SP-184). Those verify the engine's contract at its boundaries; they do
not answer the product question — across the real diversity of labors (precipitous,
prodromal, coupled back labor, multi-day latent phases) and the real diversity of
3am thumbs (missed taps, forgotten stops, app kills, clock changes), does the app
read true? Every pregnancy is different; the app must work for almost every one
that will come.

## Decision 1 — simulated labors, judged against two oracles

A new package, `Packages/LaborSim`, generates hundreds of deterministic scenarios:
a physiologic model (13 archetypes with clinically grounded parameter ranges) crossed
with a user-behavior noise model (6 profiles). Physiology and noise draw from
independent sub-streams of one seed, so the same true labor replays under every
noise profile. Each scenario is replayed through three legs — pure `PatternAnalysis`,
the real SwiftData store, the real `LaborModel` — and judged against:

1. **A mathematical oracle** — an independent reimplementation in a target with
   **zero dependencies** (`LaborOracle`, Int64 arithmetic, imports nothing from
   LaborKit). Differential testing: any disagreement is a bug in one of them.
2. **A clinical-intent oracle** — computed from the *noise-free* true stream: when
   was the guideline *genuinely* met? Zones (mustFire / gray / mustNotFire) carry
   margins and hysteresis so knife-edge luck never defines truth. The gap between
   what the body did and what the app said is the product metric: onset lag,
   false-met minutes, suppression, flap count.

A sampled simulator pass (14 promoted scenarios) seeds the real app via the
`DemoSeed` convention and verifies presentation on glass, dark + XL first.

## Decision 2 — the safety asymmetry is the ranking law

From the engine's own test doctrine: *a verdict that fires early is alarm; one that
fires late is worse.* Findings rank by severity class before anything else:

| Class | Meaning |
|---|---|
| S4 | A legitimate verdict suppressed, or a wrong figure on the safety path |
| S3 | A legitimate verdict delayed beyond threshold; data hidden longer than the floors require; stale masking |
| S2 | False met / early fire / flapping — alarm, bad but safer than late |
| S1 | Wrong or malformed presentation of correct values |
| S0 | Cosmetic |

Ranking key: (class, magnitude, corpus prevalence), descending.

## Decision 3 — verdict-math changes require a decision entry first

The verdict arithmetic and the verdict copy are product definition, not
implementation detail. A finding that indicts spec'd behavior (the coupling mean,
the absence of hysteresis, window staleness, lull-ripened sustainment) routes:
**decision entry first, then SP item, then code** — agent-authored per the autonomy
model, logged not asked, batched for checkpoint review. T0 bugs (crashes, oracle
disagreement, invariant violations) need no decision; they are wrong by existing
definition and jump the queue.

## Decision 4 — the not-built list is a hard suppression filter

Export/share, Watch app, notifications, localization, iPad, network/account/
analytics, HealthKit, home-screen widgets are intentionally absent (SP-185, decision
0018, parking lot). The harness config suppresses any finding that reduces to one of
these; a suppressed match is logged with its link and counts toward nothing. QA
against decisions, not against wishes.

## Decision 5 — corpus discipline

- Scenarios are **generated at test time from committed seeds** (SplitMix64,
  integer-second timestamps, epoch 1 800 000 000 — the test suite's own epoch).
  Determinism is pinned three ways: a corpus digest test, ~6 committed golden
  manifests, and frozen per-finding regression pins in `docs/qa/corpus/pins/`
  (additive-only).
- The corpus manifest (`docs/qa/corpus/manifest.json`) is semver'd and
  content-hashed; adding scenarios bumps minor, changing any existing one bumps
  major; reports are row-comparable only within a version.
- After every fix touching LaborKit or Contractions: full engine re-run, app-pass
  re-shots for the affected scenarios plus all pins. Every fixed finding pins its
  catching scenario. `LaborKitTests` remain the engine's unit tests; a T0 fix
  usually also lands one.

## Boundaries

The harness never adds a release-build seeding affordance (`DemoSeed` stays
`#if DEBUG`); it never files findings against the not-built list; it does not touch
the three hard gates. The rubric's copy checks enforce decision 0018's line — never
"you are in labor," never "you don't need to go yet," never a command — as
machine-checkable invariants (T0-14).

## Alternatives rejected

- **Recorded real-labor data.** Unobtainable at coverage, unshareable ethically, and
  unlabelable — the clinical-intent oracle requires knowing the true stream, which
  only a generative model provides.
- **Compressed-time UI replay of full labors.** The design's core is wall-clock
  truth (running state derives from stored timestamps); accelerating the clock
  tests a different app. Long-horizon behavior belongs to the engine legs; the
  simulator pass gets seeded snapshots plus short real-time interaction scripts.
- **Checking in ~400 manifest JSONs.** Reviewable in theory, drift-prone and heavy
  in practice; committed seeds + digest pin + golden fixtures give the same
  reproducibility with a reviewable surface.
- **A single fused oracle.** One oracle answering both "is the math right" and "was
  the verdict useful" cannot distinguish implementation bugs from design gaps; the
  two-oracle split is what makes the findings classification mechanical.
