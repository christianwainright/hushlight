# 0038 — Visible text is never hidden from VoiceOver, however well another element covers the fact

**Status:** accepted
**Supersedes:** the `liveHero` accessibility note written in HL-003 slice 1
**Related:** 0027 (accessibility conformance), 0037 (the tape carries the hour)

## Context

HL-003 slice 1 moved the running elapsed count out of the control — "the hero
leaves the disc" — and gave it the identity's full `.dataText(.hero)` size. It is
now the largest thing on a running screen. That slice also marked it
`.accessibilityHidden(true)`, with a reasoned argument: the button's own
`accessibilityValue` (`spokenButtonValue(now:)`) already speaks the same figure on
demand, so leaving the numeral visible to VoiceOver would put two elements on one
fact — and the second of them would change under her finger once a second.

The argument is coherent and it is still wrong. `XCUIAccessibilityAuditTypeElementDetection`
reported it at dark/AX5 on `running/scrolled`:

```
A11Y[running/scrolled] elementDetection — Potentially inaccessible text — unknown element
  detail: This element appears to display text that should be represented using the accessibility API.
```

`unknown element` — `issue.element` is nil — is the audit saying there is no
element there at all, which is exactly what `.accessibilityHidden(true)` produces.

Measured three ways on one machine, one simulator, one content size:

| Code state | `running` | `running/scrolled` |
|---|---|---|
| main (no `liveHero` at all) | 0 | 0 |
| HL-003 slice 2 as written | 0 | **1** |
| HL-003 slice 2, hide removed | 0 | 0 |

The same slice had already met this finding once and answered it correctly. The
ember tape's end caps were folded into the tape's combined element in a first
draft, leaving "1 H AGO" / "NOW" drawn with nothing backing them; `EmberTape`
carries the correction and the comment explaining it. `liveHero` is the same
mistake with a better excuse.

## Decision

**A visible word gets a real accessible counterpart. There is no exception for a
word some other element also mentions.**

Reachability of the *fact* is not the test. A control's `accessibilityValue`
answers "what will this button act on"; it does not stand in for a figure printed
600 points away in the scroll content, and it is not reached by the swipe
navigation a reader uses to find out what is on a screen. Covering the fact
somewhere is a good reason to keep a second element *short* — never a reason to
delete it.

`liveHero` therefore speaks for itself:

- `.accessibilityLabel(LaborFormat.spoken(elapsed))` — a duration, never the
  printed `0:14`. A numeral slot read glyph by glyph is not a measurement, the
  same rule every other spoken figure on this screen already keeps.
- `.accessibilityAddTraits(.updatesFrequently)` — the API's own way to say "this
  figure moves". This is what answers slice 1's real worry: the trait tells
  VoiceOver to re-read the value when she asks for it rather than treating each
  tick as new content to interrupt her with. The `TimelineView` still never
  decides when she is spoken to.

`.accessibilityHidden(true)` stays legitimate for things that are **not text** —
the readout's hairline dividers, the timeline's connector rule — and for text that
is genuinely redundant *in place*, where a combined parent element already speaks
the same words at the same spot. `EpisodeTimeline`'s connector row is the second
kind: the interval it prints is spoken by the node element immediately beside it,
and the audit has never reported it, at either appearance or either content size.

## Consequences

- One extra swipe stop on a running screen, between the verdict line and the
  header, carrying the elapsed time as a spoken duration.
- The figure is now reachable two ways — by swiping the content, and by asking the
  button. That is the intended shape, not a defect to tidy away.
- Dark/AX5, all twenty audited states: findings = 0, suppressions = 0.
