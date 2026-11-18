# 0033 · Hushlight is extracted from Setpoint and takes its name

**Date:** 2026-08-23 · **Item:** HL-000 · **Status:** decided

## Context

Decision 0020 put five apps in one repo; its own tripwire clause named LaborKit as
the plausible extraction candidate. Christian decided the contraction timer should
be its own product with its own identity, apart from the suite: name research (two
rounds, 52 candidates, 12 fully vetted) landed on **Hushlight**, and a
three-direction design study landed on the **Nightstand** identity — the record
lives in `docs/design/hushlight/`. The app
had never been submitted, so the bundle-id rename was free — after first release
it never is again.

## Decision

History-preserving extraction with `git filter-repo` from setpoint `main` @
`60d4b15` over the timer's closed path set: the three targets, LaborKit, LaborSim,
DesignKit, `docs/qa/`, `docs/design/contractions/`, the four store docs, the
decisions directory, scripts, CI, and root configs. Then, in waves:

- **DesignKit is a fork, pruned to the 8 files the app uses** — dropping the 20
  SharedModels-importing suite components (plus the unused MonthHeatMap) severs
  the package's `../SharedModels` edge entirely. The two copies drift deliberately
  from here; HL-001's Nightstand retokening is the first planned divergence.
- **The name**: bundle ids `net.wainright.hushlight` and `.widgets` (renamed
  together — an appex id must extend its host's), project/scheme/dirs/types
  Hushlight, shipped URLs `wainright.net/hushlight/*`, the QA harness's pointer
  files and env vars in lockstep. The on-screen `CONTRACTIONS` header stays: it
  names what is being timed, not the app, and it moves as one unit with the Live
  Activity header and the LayoutInvariantTests predicate if it ever changes.
- **Decisions 0001–0017 stayed behind**; the timer's record (0018, 0019,
  0021–0026, 0028, 0030–0032) carried, plus marked copies of the three mixed
  entries (0020, 0027, 0029) whose originals govern Setpoint.
- **CI keeps decision 0031's regime**: the ubuntu gate on every push, the macOS
  tier (`xcode-27`, a GitHub-hosted label) by manual dispatch only, with the
  affected-scope plumbing collapsed and the AX5 gate unconditional inside it.
- **Setpoint was left untouched** — nothing deleted, nothing rewritten. Removing
  the timer from the monorepo is deliberate future work there, not a side effect
  here. Until then the code exists in both repos; this one is authoritative for
  the timer from this commit forward.

## Rationale

The cut was clean by design — decisions 0017/0018 kept the timer out of the App
Group with zero suite dependencies, and the audit confirmed a closed dependency
graph with no reverse references. Preserving history keeps the SP-numbered
review trail attributable; the carve kept SP numbers on carried backlog items for
the same reason. A snapshot copy would have been simpler and worse.

## Consequences

- The backlog's open enhancement work (SP-205…SP-217) continues here unchanged.
- HD-1 (name goes final: manual TESS knockout, App Store Connect reservation) and
  HD-2 (the new record) are Christian's gates before submission.
- The `…setpoint.contractions` bundle id was never registered anywhere; no App
  Store Connect record, TestFlight build, or user data existed under it.
- Setpoint's copy of the timer code is dead the moment this repo's first real
  change lands; the follow-up removal there should cite this entry.
