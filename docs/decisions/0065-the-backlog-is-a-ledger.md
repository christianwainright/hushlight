# 0065 · The backlog is a ledger, not a log

**Date:** 2026-09-13 · **Item:** none (Christian's ask: "clean up and organize the
backlog… it needs to be very clear what has been developed, and what still needs to be
developed… standardize the whole thing") · **Status:** decided

## Context

`docs/BACKLOG.md` had grown to 2,071 lines for 92 items. Ninety were `[x]`, one `[R]`,
one `[ ]` — and reading it, that was the one thing you could not tell. Three habits had
compounded. Every closed item carried its whole build narrative inline, so the file
duplicated the BUILDLOG at a different granularity and a closed item could run to eighty
lines. Items were filed under the wave that noticed them, not what they were: HL-051
through HL-058 — App Review, the release pipeline, the iPad — sat under "L ·
Localization" because that was the open section when they were filed; SP-195 sat under
"rescued from the suite backlog"; HL-038 through HL-046 sat under the identity section.
And the things a close left for a person — an unrecorded device check, a resubmission,
a clinician's read — lived as an "Open:" or "Yours:" clause inside a `[x]` line, where a
reader looking for open work would never look. Three formats for a closing note
(`*(done — …)*`, `*(built — …)*`, dated italic paragraphs) and one emoji.

## Decision

The backlog is a **ledger**: one entry per item, one to three sentences on what it
delivers, and a trail (`→ decision NNNN · F-00NN · log YYYY-MM-DD`) to where the record
is. The narrative belongs in the BUILDLOG; the reasoning in the decisions; the findings
in the register. Concretely:

1. **§2 is the only place work lives.** In-flight items, then a table of every human
   action closed items have left behind (with the item it came from, the gate, and the
   date), then parked items, then open findings that have no item. A `[x]` line never
   carries an open clause; if a close leaves something for a person, it becomes a row in
   §2.2.
2. **§3 is grouped by what a thing is** — instrument, history, lock screen, guidance,
   design, accessibility, harness and engineering, localization, release and store —
   and sorted by ID inside each group. The wave sections (A1, A1.1, A1.2, A1.3, HL, L)
   are gone from the live file; the BUILDLOG and the archive keep that chronology.
3. **Two closed outcomes are named in bold on the line** rather than hidden in a
   parenthesis: **declined** and **superseded**. Both stay `[x]`.
4. *(`docs/history/` stayed private when the source was opened — decision 0067.)*
   **The old file is archived verbatim** as `docs/history/BACKLOG-narratives.md`, the
   same treatment `BUILDLOG-pre-split.md` got. Nothing written there was deleted; the
   ledger's trail points at it implicitly through the decision and log references.
5. **Closing an item from now on** (DoD #4, unchanged in substance): the BUILDLOG entry
   carries the narrative; the backlog line gets its mark, its sentences and its trail,
   in the same commit.

## Rationale

The file has two readers with two questions. Christian opens it to know what is done
and what is not; an agent opens it to find the first `[N]` or `[ ]` (CLAUDE.md §Start
here). Neither is served by prose. The prose was written for a third reason — so the
reasoning behind a close would survive — and that reason is real, which is why the
answer is *move* rather than *cut*: the BUILDLOG already holds an entry for almost
every close, the decisions hold the reasoning, and the archive holds the rest.

Grouping by kind rather than by wave was the harder call. Chronology is honest and the
waves were real events. But "what has been developed" is a question about the product,
and a reader asking it should not have to know that the history-row fix was found on the
26th and the icon on the 27th. The BUILDLOG is chronology; two files should not be.

Three corrections were made while rewriting, each checked against the source rather
than the old line: HL-042's decision is 0055, not 0056 (0056 is HL-041's); HD-2 is done,
not open — the app record exists and 1.0 has been submitted through it; and HL-051's
"attach 1.0 (3)" step was stale, since 1.0 (5) is the build under review and HL-055
says to resubmit it unchanged. One item was filed, not fixed (DoD #5): HL-059, the
findings register's status table still reading `open` for nine A1.3 findings their items
closed.

The cost of being wrong: a one-line summary can misstate a close. Every line was
written from the archived note and the trail points at the full record, so the fix for
a wrong line is to read the trail and correct the line — not to grow it back.

## Consequences

- `CLAUDE.md` §Start here names the ledger rule in one sentence.
- A closed line that grows past three sentences, or acquires an "Open:" clause, is a
  regression against this entry. Move the words to the BUILDLOG or to §2.2.
- `docs/history/BACKLOG-narratives.md` is read-only history. Nothing is appended to it.
- Section anchors changed: anything that cited "A1.3" or "the L section" of the backlog
  now cites the item ID, which is the stable thing. `scripts/pseudo-check.sh`'s comment
  was the one such reference in code.
- Revisit if the ledger stops answering Christian's two questions at a glance — the
  test is whether §2 fits on a screen and §3 needs no explanation.
