# 0020 — The monorepo stands; releases are per-app with one invariant

> Carried from the private monorepo Hushlight was extracted from (decision 0033). The
> original governs that repository and its other apps; its text is not reproduced here.
> What follows is the part this repository still answers to.

**Status:** accepted · **Date:** 2026-08-14

## What carries

- **Releases are independent.** Hushlight shares no store, schema or App Group with
  any other app (decision 0018); its only shared ancestry was DesignKit, now a fork.
  Nothing outside this repository can hold a Hushlight release back.
- **Every shipped binary maps to a commit.** Each build that reaches App Store
  Connect gets a git tag (`hushlight-v1.1-b6`; `hushlight-v1.1` on the build that
  goes live), so a crash report from any binary in the wild resolves to source.
- **Each target owns its version pair.** `MARKETING_VERSION` and
  `CURRENT_PROJECT_VERSION` live per target in `project.yml`; the widget extension
  tracks the app's pair.
- **Cost scales with the change.** No dependency cache in CI, on purpose: the
  zero-third-party rule means SPM downloads nothing.

The tripwire that reopened the monorepo question for this app was the one the
original named: open-sourcing a piece of it. Decision 0033 took the extraction;
decision 0067 took the open-sourcing.
