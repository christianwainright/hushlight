# 0068 · Outside code is the owner's to admit

**Date:** 2026-11-18 · **Item:** none (repository settings) · **Status:** decided
(Christian's: an outside pull request merges only on his explicit approval)

## Context

The repository is public (decision 0067). Anyone can fork it and open a pull
request; only the owner has write access. Until now the `main` ruleset required a
pull request and the `gate` check with zero approvals, so the merge itself was the
only approval, and nothing recorded it as one.

## Decision

- **The `main` ruleset requires one approving review from the code owner**
  (`CODEOWNERS` covers every path), and that approval must come after the most recent
  push, so a contributor cannot change the code after it is approved. Stale approvals
  are dismissed on push, as before.
- **The owner's own pull requests merge through the admin bypass**, which acts only
  through a pull request. GitHub does not let an author approve their own pull
  request, so without the bypass the owner could not merge at all.
- **Agents never approve, merge or start workflows for an outside pull request**
  (CLAUDE.md §Autonomy, gate 4). An agent working through the owner's `gh` login is
  the code owner as far as GitHub can tell, so the ruleset cannot stop it. The rule
  in CLAUDE.md is the control.
- **Workflows on a fork's pull request wait for the owner's approval** (the Actions
  setting "require approval for all external contributors", set under HL-070). No
  workflow uses `pull_request_target`, so a fork's run never sees a secret.

## Not done

Secret scanning for non-provider patterns and validity checks were requested and the
API left them disabled. They are part of GitHub Secret Protection, which this
account does not have on a user-owned repository. Provider-pattern scanning and push
protection stay on.
