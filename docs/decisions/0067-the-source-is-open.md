# 0067 · The source is open

**Date:** 2026-11-18 · **Item:** HL-070 · **Status:** decided (license and history
Christian's: MIT, a fresh single commit, nothing personal in the tree)

## Context

1.0 is live and 1.1 is uploaded. The app is free forever and collects nothing, so
the source holds no business secret. Publishing it lets anyone check the privacy
claims instead of taking them on trust, and it lets the project stand as a portfolio
piece. Licensing is a hard gate (CLAUDE.md §Autonomy, gate 1), so the license and the
form of the history were Christian's decisions.

## Decision

- **MIT.** The source, the docs and the design record are all under it. The README
  asks that no build ship under the Hushlight name or with its icon. MIT carries no
  trademark clause, so that request is the line, not the license.
- **A fresh single commit, not the history.** The 240-commit private history stays
  in the private repository as the record. The public repository begins at one
  commit. The history was not unsafe to publish: an audit found no keys,
  certificates or provisioning files in any commit. It was personal, though. It
  carried the owner's family context, other businesses and projects, account
  internals and key identifiers, and rewriting 240 commits to remove them would
  have cost more than the trail is worth to a reader who has the decisions.
- **What the snapshot leaves out.** `docs/history/` (the pre-extraction archive,
  which mostly describes another repository's apps). The build log before this
  entry: `docs/BUILDLOG.md` restarts here, and earlier `log` dates in the backlog
  point at the private record. Decision 0020's body is replaced by the part that
  still governs this repository.
- **What stays.** Every other decision, the design record, the QA rubric and
  findings, the store copy, the agent charter in `CLAUDE.md`, and the bundle IDs,
  team ID and support address the shipped binary already makes public.

## Rules from here

- **Public docs carry no personal life, no account internals and nothing about
  other projects.** That covers family, API key IDs, other teams or businesses on
  the developer account, and the internals of the monorepo Hushlight came from.
  Name the owner as owner; record a gate result as a fact ("completed on a device"),
  not as a story about whose night it was.
- **Secrets stay in GitHub Actions secrets.** `release.yml` and `listing.yml` are
  `workflow_dispatch`-only and run only for people with write access. Pull requests
  from forks run the ubuntu gate, which reads no secret.

## Consequences

- GitHub-hosted macOS runners are free for public repositories, so the 10x cost
  that decision 0031 rests on no longer applies. 0031 stays manual-only until a
  later entry revisits it: the other reason it gives (iOS code is verified locally)
  still holds.
- Contributions are welcome under `CONTRIBUTING.md`. The privacy ratchet binds
  contributors exactly as it binds agents.
