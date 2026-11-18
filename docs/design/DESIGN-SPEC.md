# Hushlight — design spec

Carried out of the Setpoint monorepo's DESIGN-SPEC at the extraction (decision
0033), trimmed to what governs this app. The suite spec's screen inventory,
canvas-source-of-truth order, and coach-provenance gate do not apply here. The
authority order for visual truth is: HIG → this spec → `docs/design/hushlight/`
(the Nightstand identity record) → `docs/design/contractions/` (the shipped UI's
card sources and store shots).

## Tokens

All colour and type live in DesignKit. Call sites name a role
(`.dataText(.hero)`, `Palette.tint`), never a value. Gauges are linear tick tapes
— never rings or donuts. No fixed frame heights on text containers; data values
never truncate.

The palette is **Nightstand** (HL-001, decision 0034): a warm near-black room, one
amber ember as the single accent, sage for the verdict, cool blue-grey for an easing
trend. Literal values, one light/dark pair per role, defined only in
`Palette.swift`; nothing red exists and `PaletteContrastTests` fails if it appears.
Every documented contrast ratio in that file is recomputed by that suite, so a
drifting tone fails the build rather than the eye.

Data numerals are monospaced, split by scale: the hero numeral and the readout stats
are SF Rounded with monospaced digits, dense tabular data is true monospaced. Prose
is SF Pro. `Font.voice` — New York — is reserved for exactly two moments: the
first-launch greeting and the verdict headline.

## §8 · Acceptance gates

A screen is **done** when:

1. It reads as the same design in **both** appearances — and dark is the primary
   environment here, not an audit checkbox (decision 0018).
2. XL Dynamic Type: nothing truncates or overlaps. AX5 is gated by
   `scripts/a11y-ax5.sh` (SP-195; local, and CI's manual macOS tier): Apple's audit with zero suppressions, plus
   the layout invariants.
3. Gauges, badges, and every data value have `accessibilityLabel` /
   `accessibilityValue`; the one control that matters is reachable first.
4. Hex/fixed-font gate passes — `scripts/lint-literals.sh` must return nothing;
   `gate.sh` and CI both call it, so a local pass and a CI pass always mean the
   same thing.
5. No figure below its evidence floor — an em dash, never a zero (decisions
   0022–0026). Honest presentation is a design gate here, not just a data rule.

`scripts/gate.sh` runs 4 plus the DesignKit component checks (accessibility
declared, `ComponentMatrix` preview present) and then the build.
