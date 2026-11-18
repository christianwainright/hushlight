# Decisions

One file per decision, numbered `NNNN-kebab-title.md`. These are the review trail for
autonomous work, not requests for permission — see `CLAUDE.md` §Autonomy.

Write one for anything non-obvious: architecture, schema, dependencies, resolving a
conflict between reference materials, a screen the canvases do not cover, or any place
you deviated from a spec. Do not relitigate an existing entry; if it turns out wrong,
write a new one that supersedes it and say so in both.

Template:

```markdown
# NNNN · Title

**Date:** YYYY-MM-DD · **Item:** HL-0NN · **Status:** decided | decision-needed | superseded by NNNN

## Context
What forced a choice.

## Decision
What was chosen, stated plainly.

## Rationale
Why, including what was rejected and the cost of being wrong.

## Consequences
What this commits us to, and what would make us revisit.
```

`decision-needed` marks an item parked on a hard gate (money, credentials, sensitive-data
invariants). Those get batched for the next checkpoint.
