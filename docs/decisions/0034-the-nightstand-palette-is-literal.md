# 0034 · The Nightstand palette is literal, and the room is warm

**Date:** 2026-08-23 · **Item:** HL-001 · **Status:** decided

## Context

Every colour in this app has been the iOS system palette wearing role names.
`screen` was `.systemGroupedBackground`, `primaryText` was `.label`, the tint was
`Color.blue`, and both appearances came free because the system supplies them. That
was the right call for a fitness suite handed off against system-coloured canvases,
and it carried into the extraction unchanged (decision 0033).

The Nightstand identity cannot be assembled out of it. The whole brief is one image
— a phone on the nightstand at 3am, a warm near-black room, a single ember of
lamplight — and the system palette is cool-neutral by construction: blue-black
backgrounds, pure-white text, a blue accent. There is no arrangement of system
colours that produces a warm room, because warmth is exactly what they leave out.

The tint has a second problem the extraction inherited: it was never really in
DesignKit. Ten call sites across the timer, the timeline, the how-it-works screen
and the widget reach for `Color.accentColor` directly, and `Color.white` is
hard-coded as the ink on the filled disc. On system blue that ink is legible and the
bypass is invisible. On apricot it is neither.

## Decision

1. **DesignKit holds literal values, one hex pair per role.** Nine roles from the
   identity record — room, surface, hairline, two text tones, the ember, the ember
   intensified, the sage verdict, the cool easing trend — each stated as an explicit
   light and dark value. There is no "derive dark from light": the warm near-black
   room and the warm paper are two designs, not one with a filter applied.

2. **The ember is the only accent, and it is defined in one place.** Every
   `Color.accentColor` becomes `Palette.tint`, or `Palette.emberLive` where the
   thing being drawn is the *live* contraction rather than a resting control. An
   `AccentColor` asset carries the same pair so system-drawn chrome — toolbar
   buttons, links, sheet controls — matches without a screen ever naming a colour.

3. **`onEmber` exists because ink runs backwards on a filled accent.** The ember is
   light in dark appearance and deep in light appearance, so text sitting *on* it
   inverts: near-black on apricot at night, warm paper on deep amber by day. This is
   the token that retires `Color.white`.

4. **Nothing red exists, and the ban is now mechanical.** `PaletteContrastTests`
   resolves every token in both appearances and fails if one lands in the alarm
   region of hue. The ratchet in CLAUDE.md said this; nothing enforced it.

5. **Every documented ratio is a computed test, not a claim.** The same suite
   recomputes each pair's WCAG ratio from the shipped values and fails on drift in
   either direction. Which is how we know the light ember measures **4.77:1** on
   this app's warm paper, where the identity research states ~5.2:1 — past AA's 4.5
   either way, and recorded rather than rounded away. The research measured against
   a whiter reference than the one that shipped.

6. **A gradient the ink sits on is a token, not a runtime mix.** The disc's fill was
   `tint.mix(with: .black, by: 0.12 / 0.32)`, calibrated when the ink was white and the
   fill was system blue — a case where darkening the fill *raised* contrast. Under
   `onEmber` the relationship inverts, and the bottom stop measured **3.70:1**: under
   AA, on the app's one control, in the appearance it was designed for. The stops are
   now `emberSlabTop` and `emberSlabBottom`, one light/dark pair each, held by the same
   suite as everything else. The general rule this establishes: a colour computed inside
   a view is the one colour the contrast suite cannot see, so any fill that carries text
   is named in DesignKit.

7. **Type splits by scale, not by kind.** The hero numeral and the readout stats
   become **SF Rounded with monospaced digits**; history rows, tape captions and
   section labels stay **true monospaced**. And `Font.voice` — New York, medium — is
   reserved for exactly two moments: the first-launch greeting and the verdict
   headline.

## Rationale

**On finding §6 the way we did.** The retint was mechanical — swap the accent token,
swap the ink — and it passed the build, the gates, and every existing test while
carrying a sub-AA control in dark appearance. Nothing was wrong with the work; the
defect lived in a comment that was true about a colour the app no longer uses. That is
the argument for §5 and §6 together: the ratios have to be recomputed by a machine from
the shipped values, and a value the machine cannot reach has to be moved somewhere it
can.

**On literal values.** The cost is real and worth naming: the app no longer inherits
OS palette changes, increased-contrast and other accessibility appearances no longer
adjust these colours for free, and every ratio becomes ours to hold. That is why §5
is not optional bookkeeping — it is the price of admission. What we buy is the only
thing the identity is *for*: a screen that reads as lamplight at 3am, warm-spectrum
by construction, so it survives Night Shift and Reduce White Point and is
structurally incapable of reading as an alarm. The category's failure mode is a red
hazard triangle; a palette that has no red in it cannot drift into one.

**On the two dark-mode tones we deliberately did not brighten.** Dark text is a
dimmed warm white at 15.75:1, not `#FFF`, and the raised surface is a 1.09:1 step
from the room rather than a card that announces itself. Both would score "better" on
a naive contrast sweep. Both would be wrong at 3am, where glare is the injury and a
surface should be felt rather than seen.

**On the type split.** The house rule — data numerals are monospaced — exists to
stop the column jittering as the seconds turn. The monospaced-*digit* trait is what
actually delivers that; the monospaced *face* is a means. So a 56 pt live numeral
can take SF Rounded's warmth and still hold its column, while a 13 pt history row
keeps the true monospaced face, where every glyph on the same advance is what lines
the page up. The rule is honoured at both ends, not bent at one.

**On the serif, twice.** A warm serif marks the two moments the app speaks as a
person rather than an instrument. A serif that appears anywhere else stops marking
anything, and an instrument that talks constantly is one a frightened reader learns
to ignore.

**Rejected: keeping system colours and tinting them.** A warm overlay on a
blue-black background is a muddy blue-black. The identity's premise is the
temperature of the room; there is no cheap version of it.

**Rejected: shipping the identity's 84 pt hero and the full-width slab now.** Both
belong to HL-003, which re-cuts the screen's layout with the ember tape and enters
through its own decision. A 84 pt numeral dropped into today's disc-and-columns
layout would fail §8 at accessibility sizes on the first run. Tokens first, geometry
after.

## Boundaries

No behaviour changes: no analysis, no verdict rule, no evidence floor, no copy is
touched by this entry. Every §8 gate applies unchanged, and the AX5 gate is the
proof that the new tones survive the environment decision 0018 calls primary. The
app icon still carries the old blue instrument — that is HL-002, deliberately next.
