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

## Home

**This public repository is the home of the project from 2026-11-18** (Christian's
call). `christianwainright/hushlight-private` keeps the full history and is archived
once its secrets are deleted; nothing syncs back to it. Its branches and this
repository's history are unrelated, so work starts from this `main`.

## Secrets

The five release secrets (`docs/submission-checklist-hushlight.md`) are **environment
secrets on `appstore`**, not repository secrets, and not in a separate private repo.
A second repo was weighed and rejected: it splits the release YAML from the code it
builds, adds a cross-repo checkout to keep honest, and its secrets would still be
guarded only by repository membership. The environment does better than that, and an
advisor review (Fable) agreed, with the hardening below folded in.

- **The environment gates every use.** Christian is its required reviewer (self-review
  allowed, since he is the only one), and only `main` may deploy to it. A run of
  `release.yml` or `listing.yml` waits for his approval before any secret is released,
  so even a merged workflow change cannot reach them unseen. It was created before any
  secret was entered, so no secret ever existed unprotected.
- **Forks cannot reach them.** Fork pull requests get no secrets, and workflows from
  every outside contributor wait for approval before running at all.
- **The token is read-only.** The repository default for `GITHUB_TOKEN` is read, each
  workflow declares `permissions: contents: read`, and Actions may not approve pull
  requests.
- **Only GitHub's own actions run.** The Actions allowlist admits `actions/*` and
  nothing else, which matches the zero-third-party rule.
- **Inputs are values, not script.** `release.yml` passes `build_number` through the
  environment, and Archive refuses anything but digits.
- **Secret scanning and push protection are on.** That setting, not this document, is
  what enforces "no secrets in Git".
- **Retiring the old copies:** the five secrets are deleted from `hushlight-private`
  before it is archived (an archived repo is read-only, and they would sit there
  indefinitely), and the Admin API key is revoked and reissued, since it has lived in
  two places.

## Rules from here

- **Public docs carry no personal life, no account internals and nothing about
  other projects.** That covers family, API key IDs, other teams or businesses on
  the developer account, and the internals of the monorepo Hushlight came from.
  Name the owner as owner; record a gate result as a fact ("completed on a device"),
  not as a story about whose night it was.
- **Secrets live on the `appstore` environment, never in Git and never repo-wide.**
  See §Secrets.

## Consequences

- GitHub-hosted macOS runners are free for public repositories, so the 10x cost
  that decision 0031 rests on no longer applies. 0031 stays manual-only until a
  later entry revisits it: the other reason it gives (iOS code is verified locally)
  still holds.
- Contributions are welcome under `CONTRIBUTING.md`. The privacy ratchet binds
  contributors exactly as it binds agents.
