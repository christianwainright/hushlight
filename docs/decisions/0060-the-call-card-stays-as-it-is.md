# 0060 · The call-right-away card stays as it is

**Date:** 2026-09-05 · **Item:** HL-025 (F-0043) · **Status:** decided — **declined**

## Context

HL-025 proposed two additions to Guidance's "Call right away — pattern aside" card. A
midwife lens had flagged them as omissions from the standard triage list:

1. **Second-stage pressure** — "strong pressure low down, or a sudden urge to push."
2. **The preeclampsia family** — persistent headache, visual changes, epigastric or
   upper-abdominal pain — whose point is that it *does not feel like labor* to the
   person having it.

The card today lists water breaking, bleeding, reduced fetal movement, regular
contractions before 37 weeks, and "anything that feels wrong to you."

The wording was drafted on 2026-08-26, written into `GuidanceScreen.swift`, reviewed,
and then deliberately reverted — on the grounds that an agent satisfying its own human
gate is not a gate. It has sat in the backlog since, awaiting a clinician.

## Decision

**Christian declined the additions, 2026-09-05. The card ships unchanged.**

No code changes. The drafted bullets and the reviewer's open questions stay recorded in
HL-025's backlog entry rather than being deleted, so the reasoning survives if the call
is ever revisited.

## Rationale

This is the owner's call to make and it is squarely within the second hard gate's
spirit: the entry itself says *"do not ship agent-authored warning signs,"* and the
decision not to ship them is as much a human decision as the decision to ship them would
have been. An agent has no standing to overrule it in either direction.

Worth stating plainly, because a decision entry that only records the outcome is less
useful than one that records the shape: the app's existing card already ends with
**"Anything that feels wrong to you"**, and its whole register is that the timer is not
the authority — every surface says the provider's instructions come first, and the
verdict banner itself says calling is reasonable rather than telling anyone to. The two
proposed bullets would have named symptoms that the catch-all covers in general terms.
Whether a named symptom is recognised where a vague feeling is not is a clinical
question, and no one qualified to answer it has.

## Consequences

**HL-025 closes as declined, not as done**, and the distinction matters for anyone
reading the list later: the omissions were identified, the copy was written, and a human
chose not to add it. That is a different state from "nobody noticed."

**This entry exists mainly to stop the item being re-filed.** The preeclampsia gap is the
kind of thing a fresh review of the card would flag again in six months, and without a
record the next session would redraft the same two bullets and re-open the same gate.
F-0043 stays in the findings log pointing here.

If a clinician is ever engaged for HL-008's medical-copy verification — HD-4 requires a
named human for translated medical surfaces — this card is worth putting in front of
them at the same time. That is a suggestion attached to work already planned, not a
reopening of this decision.
