# 0044 — The card fill needed its own inks

**Status:** accepted
**Item:** HL-019
**Related:** 0034 (the Nightstand palette is literal), 0027 (accessibility conformance),
0043 (the trend caption)

## Context

HL-019 exists to triage F-0034 (38 `contrast` findings, filed against `main` at
b5d86c3, before the Nightstand rebrand) and F-0036 (7 `elementDetection` findings,
same run). The item's own method, stated in the backlog: measure before touching a
token, because F-0032 is standing proof this audit can be confidently wrong.

A fresh run of the light + `large` leg against today's code (post-HL-003, post the
amber re-tokening) does not reproduce either filed list. `elementDetection` is now
**zero across all eighteen states**, in two independent full runs — F-0036 reads as
incidentally closed by decision 0038's `liveHero`/tape-end-cap work, which landed
after F-0036 was measured. `contrast` instead reads **66**, not 38, redistributed
across different elements, plus a new category the original runs never reported:
**15 `hitRegion`** findings. The rebrand changed what there is to find, which is
exactly why the item forbade re-tuning a palette against a stale list.

### Method

Every *named* finding (the audit gave a real element, not `unknown element`) was
checked against actual rendered pixels — `xcrun simctl io screenshot`, cropped to
the element's own reported frame, sampled with the same WCAG 2.1 relative-luminance
math `PaletteContrastTests` already runs — rather than argued from the token
tables alone. This is decision 0038's screenshot-plus-tree technique, applied to
colour instead of geometry.

**Two outcomes, both evidence-first:**

1. **Four real call sites, one root cause.** `Palette.secondaryText`,
   `Palette.tint`, and `Palette.easing` are all documented and tested only against
   `Palette.screen`. Four call sites draw one of them on `Palette.inputFill`
   instead — a darker, warmer fill none of the three was ever measured against:
   - Guidance's "Call right away — pattern aside" header (`SectionHeader`, on the
     callout card)
   - History's per-episode "AVG … APART · … LONG · OVER …" line
   - History's trend caption (`TrendCaptionText`, both the sentence and its
     "closer"/"farther" phrase)
   - The slip strip's "Recorded … — likely a slip." sentence

   Measured on `inputFill` in light appearance: `secondaryText` 4.42:1, `tint`
   3.74:1, `easing` 4.15:1 — all under AA's 4.5:1. This is decision 0034 §6's
   exact class of gap, one surface later: a fill several call sites actually draw
   text on, that the token was only ever checked against the room.

2. **Nine named findings, zero real ones.** Every other *named* contrast finding
   the leg reported — both toolbar links (`History`, `Guidance`), the real slab's
   "Start", the How It Works miniature's "Start", its "5-1-1 ›" chip, and its
   "Your guideline" heading — measures well clear of AA when the actual pixels are
   sampled:

   | Element | Measured colours | Ratio | Audit said |
   |---|---|---|---|
   | Toolbar `History`/`Guidance` | `#0C0C0C` on `#F9F5F0`-ish glass | **18.0:1** | Contrast failed |
   | Slab "Start" (real + miniature) | `onEmber` on `emberSlabTop`/`Bottom` | **6.1–6.9:1** | Contrast failed |
   | Miniature "5-1-1 ›" chip | `primaryText` on `screen` | **14.1:1** | Contrast failed |
   | "Your guideline" heading | `primaryText` on `screen` | **14.1:1** | Contrast failed |

   The toolbar pair is the most interesting miss: the audit is comparing against
   the button's declared tint (`Palette.tint`, resolved from `AccentColor`), but
   iOS 27's Liquid Glass toolbar chrome renders plain-text bar buttons in the
   system label colour regardless — near-black on the glass pill, not the ember
   the app names. Whatever the audit is checking, it is once again not the
   composited pixel, the same conclusion F-0032 reached about `.dynamicType` on
   this toolchain.

3. **A residual pile that resists both techniques.** After the four real fixes,
   roughly fifty `contrast` findings and all fifteen `hitRegion` findings remain,
   every one reported as `unknown element` — `issue.element` is nil, so there is
   no frame to screenshot and no debugDescription to diff. The `hitRegion` count
   is the most tractable-looking: exactly 3 findings on `met`, `met/scrolled`,
   `met/call`, `history`, and `history/scrolled` — precisely the five states where
   `LegRowView` (`Hushlight/LegRows.swift`) renders three rows, once each in the
   verdict banner and in `PinnedLegHeader`. Tested directly, decision-0038 style:
   giving each row `.frame(minHeight: 44)` and re-running `testMetVerdictIsAccessible`
   left `met`'s `hitRegion` count unchanged at 3. **Exonerated**, not confirmed —
   the same negative result F-0036's own connector-row test produced. Nothing else
   tried explains the remaining pile, named or not.

4. **A scrolled state names a moving target, not a fixed one.** `guidance/scrolled`
   kept naming Guidance's "Call right away" header even after §1's fix landed.
   Isolated (`testGuidanceIsAccessible` alone, that token forced to ~11:1 to
   remove any doubt about the number), the finding did disappear — but the same
   state then named two *different*, already-passing elements instead ("Breath
   pacer while timing" and its caption, `secondaryText`/`primaryText` on
   `Palette.screen`, untouched by this entry). The state scrolls a long page over
   several synthesized swipes, and which content the audit samples when it fires
   is not fixed run to run. This is a second axis of instability on top of §3's
   per-state reproducibility, and it is why the residual pile (F-0038) is filed
   as unlocatable rather than chased finding by finding: a target that moves
   between two runs of the identical build cannot be pinned down by re-running it
   a third time.

## Decision

1. **Fix what pixel evidence confirmed.** Two new tokens, `Palette.secondaryTextOnFill`
   (5.01:1 light / 5.45:1 dark on `inputFill`) and `Palette.easingText` (4.88:1 /
   6.80:1) — and `Palette.tintText` gains a third documented surface rather than a
   fourth token, since its existing deepened value already clears `inputFill`
   (4.92:1 / 7.26:1) with no new hex needed. `SectionHeader` and
   `sectionLabelText()` take an `onFill:` flag; the other three call sites swap
   their token directly. `PaletteContrastTests.textOnInputFillClearsAA` holds all
   three against `inputFill` in both appearances, and both new tokens join
   `noTokenIsRed`'s exhaustive list. Dark appearance was already clear on every
   one of these pairs (5.45–7.26:1) — nothing in dark moves.

2. **Record the nine disproven findings as measured, not argued.** F-0034 is
   updated in place rather than superseded: it now carries the pixel table above
   instead of the pre-rebrand list it was filed against. It stays `open` — the
   toolbar finding in particular (a toolchain-level Liquid Glass behaviour, not
   an app defect) has no fix inside this app's code, and joins F-0032/F-0033 as
   the same standing "this audit is measurably wrong here" class, not a
   suppression.

3. **File the residual pile as F-0038, `open`, not `accepted`.** It is real
   enough to be reproducible (two independent full runs, near-identical counts)
   and specific enough to resist a broad explanation (the one elimination test
   available came back negative). It is not diagnosable further with the tools
   this session had — no Accessibility Inspector, no on-device element browser,
   only `xcodebuild test`, `simctl`, and screenshots. Closing it needs the tool
   that can name an anonymous `SwiftUI.AccessibilityNode`, which is not one of
   these.

4. **HL-019 stays `[~]`, not `[x]`.** Its own acceptance criterion —
   `scripts/labor-sim.sh`'s a11y gate passing both legs — is not met: the light
   leg carries zero suppressions by design (`AccessibilityAuditTests`'s stated
   contract), so F-0038's unresolved findings keep it red. That is the gate
   working as built, not a reason to relax it by excluding `contrast` or
   `hitRegion` from the audited categories the way `.dynamicType` was excluded —
   this leg exists *for* contrast, and blindly widening the exclusion is the
   exact move the item was written to prevent ("a palette re-tuned against an
   unvalidated audit is worse than the finding," restated here as "an exclusion
   written against an unvalidated audit is worse than the finding").

## Rationale

**On fixing four and disproving nine in the same pass.** Both directions used the
identical method — resolve the actual `UIColor` the compositor draws, not the
token the code names — so neither conclusion is a guess in the direction the
triage wanted to go. The four fixes have failing numbers before and passing
numbers after, in both appearances, held by a test. The nine disproven findings
have passing numbers the audit called failing, sampled from the same screenshots
the same run produced. Evidence, not disposition, decided which finding got a
token and which got a paragraph.

**On not touching `easing`'s or `tint`'s existing values.** Both are documented
and tested against `Palette.screen` for the day something draws them there
directly; today, nothing does — every live call site sits on `inputFill`. Deepening
the tokens themselves rather than adding fill-specific variants would have been
simpler, but it borrows tomorrow's a screen-drawn `easing` or `tint` against a
ratio calibrated for a fill it will never sit on — the same reasoning `tintText`
already established for the ember, applied consistently rather than re-litigated.

**On leaving F-0038 open rather than accepting it.** An accepted-limitation entry
needs a measurement that justifies the acceptance (F-0033's pattern: the toolbar
cannot scale with Dynamic Type because it is system chrome, measured and named).
F-0038 has no such measurement — it has an absence of one, which is a different
thing. Filing it `open` says plainly that the investigation stopped at the edge
of what this session's tools could show, not that the residue has been judged
harmless.

## Boundaries

No behaviour, verdict rule, or copy changes. Dark appearance is untouched — every
ratio this entry changes is a light-appearance-only number, and every dark
pairing it checked was already clear of AA before this entry existed.
