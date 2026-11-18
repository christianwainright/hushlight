# 0030 — The macOS CI tier is opt-in, not per-commit

**Status:** superseded by [0031](0031-no-automatic-macos-ci.md) the same day — the
macOS tier now has no automatic trigger at all, and `[ci full]` no longer exists.
The cost measurements below stand and are why 0031 went further.
**Date:** 2026-08-23

## Context

> **Correction, filed the same day, after the first run under this rule.** The
> original context below blamed *frequency* — "4–12 commits a day, a twelve-commit
> burst queuing twelve macOS runs." **That was wrong**, inferred from `git log`
> without checking the Actions history. The decision stands; its stated cause did
> not survive contact with the data, and the real numbers are recorded here instead
> of quietly deleted.

The commit rate is real — 4–12 a day, straight on `main`, no merge commits — but
commits are not what triggers CI. **Pushes are, and they are rare.** There have
been **18 CI runs on `main` in the project's entire life.** Roughly thirty commits
spanning 2026-08-16 to 2026-08-23 arrived in a *single* push and produced exactly
one run.

The bill is **duration**, not count. That one run:

| Step | Time |
|---|---|
| Test affected suites | 22m 51s |
| Build affected schemes | 0m 48s |
| Accessibility gate at AX5 | 11m 07s |
| **Total** | **~35 min** |

At the **10x** macOS multiplier that is roughly **350 billable minutes for one
run**. A handful of those is the whole invoice.

This does not weaken the decision — it sharpens it. SP-192's path filtering is the
right lever for *scope* and works: a docs-only diff resolves to nothing. But it
cannot help when the diff is genuinely wide, and a push carrying a week of commits
always is. When a single run costs ~350 billable minutes, **starting one should be
a deliberate act.** That, not run frequency, is why the tier is opt-in.

It also names the larger remaining lever plainly: ~23 minutes of tests and ~11
minutes of AX5 per run. Opt-in decides *how often* that price is paid; it does
nothing about the price. Reducing it is separate work and is not claimed here.

## Decision

**The macOS build-and-test tier runs only when something asks for it.** The
ubuntu `gate` job is unchanged and still runs on every commit: the §8 literal
lint, the no-remote-dependency grep, and the `affected.sh` computation are the
per-commit safety net, and they cost approximately nothing.

Three ways the macOS tier runs:

1. **`[ci full]` in a commit message.** Every commit in the push is checked, not
   just the head one — a docs commit landing on top of a flagged one must not
   swallow the request.
2. **Manual `workflow_dispatch`**, which tests everything — a hand-triggered run
   has no meaningful base to diff against.
3. **Any pull request.** A PR is an explicit review point and this repo opens
   almost none, so the tier still runs there unasked.

**Deliberately no scheduled sweep** (Christian's call, 2026-08-23). A nightly
would put the expensive tier back on a timer — a run nobody asked for, possibly
on a day that changed nothing — which is a smaller version of the problem this
decision exists to fix. Both remaining entrances are deliberate acts.

The commit message is read through the expression layer (`contains(join(...))`)
into an `env:` value, never interpolated into a `run:` block. Commit messages
are untrusted text and a shell interpolation there is a script-injection hole.

## Consequences

**An unflagged commit is verified locally or not at all.** Nothing catches it
later — there is no timer, and the next flagged run diffs from its own push base,
not from the last green one, so an unverified commit can slide past entirely.
That is the trade, stated plainly.

What makes it acceptable is that the local loop was always the real first line of
defence: `./scripts/test.sh $(./scripts/affected.sh suites origin/main)` runs the
same suites CI would, off the same dependency map. CI's job here shrinks to what
a developer machine genuinely cannot do — SP-042a means app-target UI tests may
not launch locally at all, so the AX5 accessibility gate needs a runner.

The agent convention that carries this: **a session that finishes a real code
item flags its last commit `[ci full]`.** Docs, backlog, and decision commits do
not. With no sweep behind it, that habit is not a nicety — it is the whole
verification story for anything the local loop cannot run.

Rejected alternatives, and why:

- **Collapse bursts only** (`cancel-in-progress: true` on main). Saves maybe
  60–70% on a burst day and nothing on a spread-out day, and it silently drops
  the per-commit verdict SP-192's comment was written to protect. Half the
  saving for the same loss of granularity.
- **Nightly-only, no flag.** Cheapest, but it removes the ability to verify
  something *now*, which matters most exactly when a change is risky.
- **Opt-in plus a nightly backstop.** The first draft of this decision. Rejected
  on the same ground as the rule itself: an unasked-for daily macOS run is the
  cost pattern being removed, and a backstop that fires whether or not anything
  needs checking invites leaning on it instead of on the flag.

This supersedes the *always-on* half of SP-192 — that any qualifying push starts
the tier unasked. Its scope half — `affected.sh` as
the one dependency map — stands unchanged, and still narrows every run that does
happen: a flagged push builds only what it touched.
