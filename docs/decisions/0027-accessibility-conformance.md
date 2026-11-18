# 0027 — Accessibility conformance: the quiet register, the disc, and a gate that runs

> Copy carried out of the Setpoint monorepo at the Hushlight extraction (drove the AX5 gate this repo enforces);
> the Setpoint original governs that repo. See decision 0033.

**Status:** accepted (Christian, 2026-08-17 — contrast scope and the type-role floor
answered directly; the rest follows from an HIG audit and is agent-decided per the
autonomy model)
**Date:** 2026-08-17

## Context

An HIG pass on 2026-08-16 — code conformance, Apple's current published guidance
fetched live, and a visual review of 31 rendered screens — found the timer
structurally strong and failing in the one environment decision 0018 names as
primary: dark appearance at accessibility text sizes, at 3am.

Verified on the simulator rather than predicted: at AX5 the button label wrapped
mid-word ("Sta / rt"), the caption truncated with an ellipsis, the label rendered
*outside* the blue disc, and every figure plus the verdict banner was off-screen with
nothing left to scroll to — in a seeded 5-1-1 **met** state, so the one sentence the
product exists to deliver was unreachable.

Everything built in SP-193/194 ran past it. The harness pinned
`accessibility-extra-large` (AX3, one size below the break) and its assertion stage
checked text content, not layout — it would have passed identically at `medium`.

## Decision 1 — the quiet register clears AA, in two tiers

`Palette.secondaryText` and `ghostText` adopt measured AA-passing tones: **5.88:1** and
**4.59:1** on the light grouped background, against primary's 9.80:1. Light only; dark
measured 6.36:1 already and is untouched, the same asymmetry `warningText` and
`tintText` document. This closes **SP-018** for all five apps.

Decision 0008 filed this rather than deciding it, and 0008's own argument is what
settles it: *DESIGN-SPEC §0 ranks Apple HIG above this spec and above the canvases*, so
raising the tone is arbitration inside the source-of-truth order, not a deviation from
it.

**Two tones where the parked token sketched one.** A single 0.73 value for both would
have cleared AA and flattened ghost into secondary — Train's pending-set language and
its section labels are different voices, and a fix that makes them one voice trades a
contrast defect for a hierarchy defect. AA is a floor, so keeping a tier means the
louder tier moves further.

Consequence, handled in the same change: the Train `XCTExpectFailure` and the
"Contrast nearly passed" suppression both leave with their reason. Writing that
expectation strict rather than `.nonStrict()` is what made the fix visible instead of
silently absorbed.

## Decision 2 — `.label` is 11 pt

HIG's floor for custom type is 11 pt. The role was held at 10 to keep one fitness-app
header on a single line; it carries the timer's `CHECK · OVER 3 MIN` flag and every
word of its Dynamic Island. It also becomes a genuine `.caption2` match, so it can
declare Dynamic Type rather than only perform it. `InsightView` takes the stacked
fallback it already has.

## Decision 3 — at accessibility sizes the verdict leads absolutely

`guidance()` renders above `header()`, not merely above `readout()`. The header is
~208 pt at AX5 — three wrapped lines of mono caps plus the chip — and capping the
button alone still left the verdict below the fold on smaller devices. Identity and the
rule chip can afford to be scrolled to; the sentence that says calling is reasonable
cannot. Guidance's toolbar item is pinned, so the rule stays one tap away.

## Decision 4 — the disc is square, floored, and roofed

The AX5 break was never really the inset size. `Circle()` inscribes the **smaller side**
of the box it backs, and padding on four edges against independent min-width and
min-height floors produced a non-square box: the disc drew at `min(W, H)` while the
label occupied the full `W × H` and escaped on the long axis.

The frame is square; the label's box is an inscribed rectangle stated as fractions of
the diameter (0.78 × 0.62 — corners a hair inside the arc); the diameter has a roof of
280, dropping to the 216 floor at accessibility sizes where the caption steps outside
the disc and the circle has nothing left to grow for. Fractions rather than a scaled
constant because the corner correction is a function of the content's *shape*, not the
type size.

**Pre-agreed answer for a future 667 pt device** (none exists at the iOS 27 floor): the
216 floor and the vertical budget collide there at ~62% of the screen. The lever is to
drop the caption at accessibility sizes on short containers — decided now so it is not
re-derived under pressure later.

## Decision 5 — the gate is strict, and its one exclusion is visible

`ContractionsUITests` gains Apple's audit with **zero suppressions** — the issue handler
returns `false` always, there is no `accepted` set, and findings are logged by
`issue.auditType` rather than by substring-matching Apple's prose. It runs seven states
at rest and scrolled, replacing the fitness suite's positional bottom-bar suppression by
removing the occlusion instead of the finding. Categories are named explicitly rather
than `.all`, so a toolchain bump cannot silently change what the gate means. The runner
asserts the content size it observed rather than trusting what the script set.

`LayoutInvariantTests` sits beside it because Apple's audit structurally cannot catch
two of the three AX5 symptoms: a label that *wraps* is not clipped, and no category
asks whether the verdict is reachable. It asserts the banner leads and is hittable, that
the readout and header took their stacked branches, and that the button bar's far corner
still toggles the model.

**`.dynamicType` is excluded, with evidence** (F-0032). Three eliminations changed
nothing, and then the proof: it flags `"Tap when it begins"`, which is `.font(.prose)` —
plain `Font.body`, measured 226 × 126 pt at AX5. A stock system text style cannot be a
non-scaling font, so the finding describes the audit rather than the app. This is not a
suppression in the sense the rest of the gate argues against: a suppression hides a
finding the tool got right, and the exclusion is printed in the log line every run. It
returns the moment a toolchain stops reporting it. `.textClipped` still catches the
failure `.dynamicType` is meant to predict, and the layout invariants assert the reflow
directly.

## Boundaries and what stays open

The AX5 leg joins CI (path-filtered on the Contractions scheme, via a script that
creates and traps-deletes its own simulator — content size is a device-wide setting).
It is green: 11 tests, zero findings. SP-042a means app-target tests may not launch
locally, so CI is the only machine where this is guaranteed to run.

The default-size leg carries `.contrast` and stays **local and red**, tracked as
**F-0034**: 38 contrast findings on its first run, none of them regressions and none
provably pre-existing. The first one triaged is already disproven — the disc's rendered
fill sampled from real pixels is `(3, 104, 195)`, giving white text **5.50:1**, and the
values the audit appears to be reading are antialiased glyph edges. Given F-0032, the
tool's contrast judgement is suspect here too, and re-toning a palette against an audit
that is demonstrably wrong about `Font.body` would be the wrong move. It needs a triage
wave, not a reflex.

## Alternatives rejected

- **One tone for both tiers**, as the parked token proposed — clears AA, flattens the
  hierarchy.
- **`.nonStrict()` on the Train expectation** — a suppression that can never report
  itself obsolete.
- **Dropping the caption at accessibility sizes** to buy height: 2 lines out of a
  32-line verdict, at the cost of the only thing telling a first-time user the button
  is a toggle.
- **`scrollEdgeEffectStyle(.soft)`** to fade text shearing under the bar: tried, and a
  cropped before/after shows it does nothing on a `safeAreaInset` bar with a material
  background. Removed rather than shipped as an unverified claim.
- **Suppressing `.dynamicType` inside the handler** rather than excluding the category:
  same effect, less visible.
