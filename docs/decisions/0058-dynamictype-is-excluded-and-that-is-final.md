# 0058 · `.dynamicType` is excluded, and that is now a decision

**Date:** 2026-09-05 · **Item:** SP-195 (F-0032) · **Status:** decided

## Context

`AccessibilityAuditTests.baseAuditTypes` has never included `.dynamicType`. F-0032
recorded why in SP-195 phase 4 and left the disposition as *decision-needed*, which is
what kept SP-195 at `[~]` — the item says plainly that it stays open until F-0032 is
"fixed or genuinely accepted, not merely reported open".

F-0032's evidence was strong but is now largely about views that no longer exist. Its
headline proof was a `MiniCircle` scaling 3.7x, and decision 0036 replaced the disc it
belonged to with a slab. An exclusion resting on measurements of deleted code is an
exclusion nobody can re-check — the exact condition that let F-0034 and F-0036 go stale
until HL-019 re-triaged them from scratch.

So it was re-measured against today's tree, by `HushlightUITests/DynamicTypeAuditDiagnostics`.

## Evidence

`.dynamicType` fires on **two** element classes today, not F-0032's four. Same build,
iPhone 16 Pro on iOS 18.5, run at both sizes:

| Element | default | AX5 | growth |
|---|---|---|---|
| `SectionHeader` "YOUR GUIDELINE" | 362.0 × **25.8** | 362.0 × **60.5** | **2.34x** |
| toolbar `History` button | **62.7** × 33.7 | **73.7** × 33.7 | 1.18x wide, height system-fixed |

The audit's detail on both is *"User will not be able to change the font size of this
element"*. The first grows by a factor of 2.34 between the two runs. Whatever the audit
is detecting, it is not whether the text scales.

**F-0032's root cause survives the re-measurement, and is now the whole list.** Both
survivors are exactly what it predicted: composed or UIKit-hosted nodes — a
`.accessibilityElement(children: .combine)`d `SectionHeader`, and a toolbar item. Its
negative control still holds: the timer's own section label, a plain `Text`, is not
flagged in any state.

Neither is fixable in app code. `SectionHeader` combines its children deliberately, so
that a ruled heading speaks as one phrase instead of two fragments. The toolbar item is
system chrome whose text growth Apple caps — 62.7 → 73.7 pt across a 3.5x type increase
is the system's ceiling, not the app's.

Note also what *has* been fixed rather than excluded: decision 0027 gave the `.label`
and `.row` roles real matching text styles (`caption2`, `footnote`) precisely so they
**declare** Dynamic Type rather than only performing it. `.hero` and `.stat` keep the
`@ScaledMetric` path because no style in the ramp is 26 or 56 pt. That work is why the
list is two elements and not twenty.

## Decision

**`.dynamicType` stays out of the gate, permanently, as an accepted limitation.**

1. The reason now lives **at the exclusion site** in `baseAuditTypes`, with the
   measurement, rather than only in a findings file. The next reader of that array
   learns why without archaeology.
2. It is **excluded, not suppressed.** No `accepted` set, no sentence-matching against
   Apple's prose — SP-195's "zero suppressions" holds literally. The category is not
   silenced inside a passing gate; it simply is not one of the questions the gate asks.
3. The evidence stays reproducible. `DynamicTypeAuditDiagnostics` runs the category on
   demand at whichever content size you point it at, so this decision can be re-checked
   in one command instead of re-derived. It is a diagnostic, skipped by name in
   `labor-sim.sh` alongside `SmallTargetDiagnostics`.

## Consequences

**SP-195 closes.** Both things holding it open are now genuinely accepted with current
measurements rather than reported open: F-0038 by decision 0057, F-0032 by this entry.
The AX5 gate passes with zero findings and zero suppressions, and the light + `large`
leg's residue is dispositioned.

If a future OS starts naming these elements differently, or `SectionHeader` stops
combining, the diagnostic is the way to find out — not a rerun of the archaeology this
entry had to do.

## Rationale

Two decisions in one day have now turned on the same lesson: **evidence about deleted
code is not evidence.** F-0038's leg-row hypothesis was right and was disbelieved
because its test was never validated; F-0032's diagnosis was right and had become
uncheckable because its examples were removed. Both were closed by re-measuring against
what actually ships.

The cheap defence is where the reason is written. A rationale in a findings file ages
out of sight; a rationale next to the line it justifies gets read every time someone
touches that line. That is why the comment moved.
