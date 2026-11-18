# 0057 · The audit names nothing; ask the tree instead

**Date:** 2026-09-05 · **Item:** HL-019 · **Status:** decided

## Context

F-0038 parked the light + `large` accessibility leg's residue — ~50 `contrast` and 15
`hitRegion` findings, every one reported with `issue.element == nil` — as "reproducible
and unlocated", and said closing it "needs a tool this session did not have (Xcode's
Accessibility Inspector or equivalent live-tree browser)".

Two instruments were available and had not been tried.

## Evidence

**1. An older runtime is a better witness.** The same leg, same build, same device
model (iPhone 16 Pro), run on iOS 18.5 and 27.0:

| | Total findings | `unknown element` | **Named** |
|---|---|---|---|
| iOS 18.5 | 79 | 62 | **17** |
| iOS 27.0 | 76 | 69 | **7** |

The pile is not a Liquid Glass artefact — it reproduces below 26 — but 18.5's audit
attaches role, frame and label to **ten more** findings than 27.0 does. Some of what
F-0038 called unlocatable was locatable one OS back.

**2. The tree answers what the audit will not.** `XCUIElementQuery` hands over every
element with its frame, so instead of asking the audit which element it means, ask the
tree the audit's own question — what here is under 44 pt — and reconcile the counts.
`HushlightUITests/SmallTargetDiagnostics` does exactly that. It asserts nothing.

## What the two instruments found

**`hitRegion` is `LegRowView`, and F-0038's original hypothesis was right.** The pile is
exactly 3 findings in each of six states — `met`, `met/scrolled`, `met/call`,
`met/call/scrolled`, `history`, `history/scrolled` — identical on both runtimes. F-0038
suspected the three leg rows, tested a 44 pt floor on them, saw the count hold at 3, and
recorded "exonerated". The control it never ran is the one that settles it:

- `empty` reports **zero** `hitRegion` findings.
- `empty` carries **the same three undersized toolbar buttons** as `met` — `History`
  62.7×28.3, `Guidance` 39.7×39.0, `How it works` 34.0×34.0.
- Therefore the toolbar cannot be what `met` is flagged for.
- What `met` and `history` have and `empty` does not is exactly three non-interactive
  rows at **15.7 pt tall**: `apart`, `long`, `holding` — `LegRowView`, in the verdict
  banner and in History's `PinnedLegHeader`.

The count, the states, and the measured frames now agree. The earlier elimination test
did not disprove the hypothesis; it failed to change what it was trying to change.

**`contrast` disagrees with the pixels, again.** Six of the newly-named findings are the
readout's em dashes. Sampled from the screenshot at the audit's own reported frame, the
glyph is `(107, 97, 84)` — exactly `Palette.secondaryText` — on `(250, 246, 239)` —
exactly `Palette.screen` — for **5.63:1**, matching `PaletteContrastTests`' documented
value to the digit and clearing AA's 4.5:1. That is the eleventh named contrast finding
on this leg to be measured and the eleventh to pass. Two of them —
`CALL RIGHT AWAY — PATTERN ASIDE` and the slip strip's sentence — are findings F-0034
*deliberately fixed*, and they still fire.

## Decision

1. **`hitRegion` is located and dispositioned as an accepted limitation.** The flagged
   elements are `LegRowView`'s three rows: read-only figures, `type=1` (not buttons),
   carrying no action. Apple's 44 pt rule is a *touch target* rule and these are not
   touch targets. Meeting it would add roughly 85 pt to the verdict banner — the screen's
   most-read surface, at the moment it matters most — to enlarge something nobody taps.
   **Not fixed, on purpose**, and this entry is the measurement that justifies it.
2. **`contrast` on this leg is not trustworthy against this app's rendering.** Eleven
   named findings measured, eleven passing, two of them already-corrected call sites.
   The category stays reported and un-suppressed; it does not gate.
3. **`SmallTargetDiagnostics` stays in the repo, and out of every gate.** It is skipped
   by name in `labor-sim.sh`'s UI stage. A file that deliberately cannot fail must never
   look like part of a gate that can.

## Consequences

F-0038's `hitRegion` half closes with a cause. Its `contrast` half closes as a
documented limitation rather than a mystery. What remains genuinely unlocated is the
`unknown element` residue that neither runtime names — smaller than before, and no
longer the whole pile.

The wider lesson is cheap and reusable: when a tool refuses to say what it means, a
**control** is worth more than another attempt at the tool. `empty` versus `met` did in
one run what a year of staring at `unknown element` could not.

## Rationale

This repo has twice closed a finding as "exonerated, not confirmed" on the strength of a
negative elimination test (F-0036's connector rows, F-0038's leg rows). Both times the
test changed something and the count did not move, and both times that was read as
evidence about the *hypothesis* rather than about the *test*. It is worth naming: a
negative result from an instrument you have not validated is not evidence. The control
is what validates it.
