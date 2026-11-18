import SwiftUI

/// Every colour in the app — the "Nightstand" identity (HL-001, decision 0034).
///
/// The brief is one image: a phone lying on the nightstand at 3am, a warm near-black
/// room, and a single soft ember of lamplight. Everything is warm-spectrum by
/// construction — no blue-black, no clinical white — so the screen reads as lamplight
/// rather than a laptop, survives Night Shift and Reduce White Point, and is
/// structurally incapable of reading as an alarm. **Nothing red exists here, and no
/// token may add it** (CLAUDE.md, the privacy-and-tone ratchet).
///
/// These are literal values rather than iOS system colours, which is the change
/// HL-001 makes: the system palette is cool-neutral, and a warm room cannot be
/// assembled out of it. Raw hex is banned everywhere else (spec §8,
/// `scripts/lint-literals.sh`) precisely so this file can hold it.
///
/// **Every ratio below is computed, not eyeballed** — `PaletteContrastTests` recomputes
/// them from these same values on both appearances and fails if one drifts.
public enum Palette {
    // MARK: The room

    /// Screen background. Dark: warm near-black, brown-black and OLED-friendly, so the
    /// phone can lie face-up all night at almost-off. Light: warm paper.
    public static let screen = warm(light: 0xFA_F6_EF, dark: 0x0E_0C_0A)

    /// One soft step up from the room, like an object catching lamplight. Deliberately a
    /// *small* step (1.09:1 dark, 1.06:1 light): a raised surface at 3am should be felt,
    /// not announced — the light-mode step is Apple's own grouped-card step to within a
    /// hundredth.
    ///
    /// **It carries a rule.** The iPad ledger and the reference card sit on it; the
    /// verdict banner and the slip strip stay on `inputFill`. A step this small genuinely disappears at low OLED brightness under
    /// Reduce White Point, so `raised` may never appear without a hairline edge or a
    /// shadow to carry its boundary. That rule is what makes 1.09 defensible; the number
    /// alone does not.
    public static let raised = warm(light: 0xFF_FD_F8, dark: 0x1A_16_13)

    /// Separators and the tape's rest marks. Never a pure grey — always warmed.
    /// Decorative by contract: nothing that carries a figure is drawn in it.
    public static let hairline = warm(light: 0xE9_E1_D4, dark: 0x2B_25_1F)

    /// Unfilled gauge tracks and pending fills.
    public static let pendingFill = warm(light: 0xEF_E8_DC, dark: 0x23_1E_19)

    /// Input fields and slightly heavier tracks — the idle half of a two-state control.
    public static let inputFill = warm(light: 0xE4_DB_CB, dark: 0x2F_28_21)

    // MARK: Text

    /// Dark-mode text is a dimmed warm white, deliberately not `#FFF`: 15.75:1 is far
    /// past AAA and glare is the thing that actually hurts at 3am. Light is warm ink at
    /// 14.09:1.
    public static let primaryText = warm(light: 0x2A_25_20, dark: 0xED_E6_DB)

    /// The quiet register: column captions, timestamps, the hedged sentence under the
    /// verdict, `CHECK · OVER 3 MIN`. 7.33:1 dark and 5.63:1 light — both clear AA at
    /// the 11 pt `.label` role, which is what SP-018 and decision 0027 were about. The
    /// Setpoint palette needed two alpha tiers to reach that; a warm palette designed
    /// for it needs one tone.
    public static let secondaryText = warm(light: 0x6B_61_54, dark: 0xA8_9D_8F)

    /// Ink on a filled ember surface — the slab, the disc, a filled capsule. Inverted
    /// against every other text token on purpose: the ember is *light* in dark
    /// appearance and *deep* in light appearance, so its ink runs the other way. This
    /// is the token that replaced `Color.white`, which was legible on system blue and
    /// is not legible on apricot.
    public static let onEmber = warm(light: 0xFA_F6_EF, dark: 0x0E_0C_0A)

    // MARK: The ember — the one accent

    /// Soft apricot-amber lamplight: buttons, links, the live glow, the tape's fill.
    /// Amber is melatonin-kind, preserves night vision, and cannot read as a hazard.
    /// 9.77:1 dark, 4.77:1 light.
    ///
    /// The identity record states ~5.2:1 for the light ember; against this app's actual
    /// warm-paper background it measures **4.77:1**. Still past AA's 4.5, and the
    /// discrepancy is recorded rather than rounded away — the research measured against
    /// a whiter reference than the one that shipped. If a future item needs margin at
    /// small sizes, deepen this value, do not re-state the ratio.
    public static let tint = warm(light: 0xA5_5A_24, dark: 0xF0_A8_68)

    /// The ember intensified — the live elapsed numeral and the pressed slab. The only
    /// "louder" colour in the system, and it is still candlelight. 12.70:1 dark,
    /// 6.27:1 light.
    ///
    /// It sits ~1.3:1 from `tint`, which is enough side by side and not enough in
    /// isolation: **no surface may ask the two to be told apart as colours.** They are
    /// stateful, not comparative — wherever `emberLive` appears, a second signal (a
    /// ticking count, the ring, a position on the tape) already says "live". A legend or
    /// a key pairing them as static swatches would be reading a distinction that is not
    /// there. The identity means the difference to be read as a *transition* — the ember
    /// brightening over a contraction's first seconds — which arrives with HL-003.
    public static let emberLive = warm(light: 0x8C_4A_1B, dark: 0xFF_C5_93)

    /// The two stops of the ember slab's gradient — the disc today, the full-width slab
    /// after HL-003 — lit from above in both appearances, and both legible under
    /// `onEmber`.
    ///
    /// They are tokens rather than a runtime `tint.mix(with: .black)` because that mix
    /// was measured for **white ink on system blue**, where darkening the fill *raised*
    /// contrast. Under `onEmber` the relationship inverts: dark ink on a darkening amber
    /// loses contrast, and the bottom stop measured **3.70:1** — under AA, on the
    /// app's one control, in the appearance it was designed for. A mix computed at
    /// runtime is also the one colour `PaletteContrastTests` cannot see. Named stops fix
    /// both problems at once.
    ///
    /// | | top | bottom |
    /// |---|---|---|
    /// | dark | 11.25:1 | 7.43:1 |
    /// | light | 5.53:1 | 7.38:1 |
    public static let emberSlabTop = warm(light: 0x96_52_1F, dark: 0xF7_B8_7C)
    /// The shaded lower stop. See `emberSlabTop`.
    public static let emberSlabBottom = warm(light: 0x7D_41_17, dark: 0xD9_8F_4E)

    /// A wash of ember behind a selected row or a tinted capsule. A tint, never a
    /// filled alarm block.
    public static let tintFill = tint.opacity(0.15)
    /// Borders on selected rows and chips.
    public static let tintBorder = tint.opacity(0.5)

    /// Ember text — on the room it is `tint` itself, which clears AA in both
    /// appearances as drawn (9.77:1 / 4.77:1), so the darkened light-mode variant the
    /// Setpoint palette needed for system blue is gone.
    ///
    /// It is still its own token because of the one surface where the ember is *not* on
    /// the room: ember text on `tintFill` measures 3.93:1 in light appearance, under AA.
    /// Deepened here rather than at `tint`, so a tinted capsule's label clears the floor
    /// (5.17:1 on `tintFill`, 6.27:1 on the room) without darkening every ember shape in
    /// the app to pay for it. Dark appearance keeps the ember unchanged — 7.62:1 on
    /// `tintFill` — the same light-only asymmetry the old palette documented.
    ///
    /// Its light value lands on `emberLive`'s: the deep end of the ember ramp, reached
    /// from two directions. They stay separate names because they answer to different
    /// things — one to a fill, one to a state.
    ///
    /// A third surface reaches the same token rather than a fourth one: History's
    /// trend caption (`TrendCaptionText`) draws its "closer" phrase in `tint` on
    /// `inputFill`, where undarkened `tint` measures 3.74:1 — under AA, worse than
    /// `tintFill`'s own gap. `tintText` already clears it there too (4.92:1 light,
    /// 7.26:1 dark) with no new hex needed (HL-019).
    public static let tintText = warm(light: 0x8C_4A_1B, dark: 0xF0_A8_68)

    /// `easing`'s own ink, deepened for the one surface it is actually drawn on
    /// today: the trend caption's "farther" phrase, `Palette.easing` on
    /// `inputFill` (`HistoryScreen.TrendCaptionText`). `easing` is documented
    /// against `screen` for the day something else draws it there (9.14:1 dark,
    /// 5.29:1 light), but every call site that exists right now sits on the card
    /// fill instead, where the undarkened value measures 4.15:1 in light
    /// appearance — under AA. The same reasoning as `tintText`, applied to the one
    /// ink `tintText` cannot stand in for: dark keeps `easing` unchanged (6.79:1 on
    /// `inputFill` already clears AA); light is deepened to 4.88:1 on `inputFill`
    /// (HL-019).
    public static let easingText = warm(light: 0x46_5F_71, dark: 0x9F_B4_C7)

    /// Quiet text on `inputFill` rather than the room — the slip strip's sentence,
    /// the callout header inside Guidance's "Call right away" card, and History's
    /// per-episode summary line and trend caption. `secondaryText` is documented
    /// only against `Palette.screen` (5.63:1 light, 7.33:1 dark); on the darker
    /// `inputFill` card its light value drops to 4.42:1 — under AA. The same class
    /// of gap decision 0034 §6 closed for the ember slab's gradient stops: a fill
    /// several call sites actually draw text on, that the original token was only
    /// ever measured against `screen`. Deepened here rather than at `secondaryText`
    /// itself, so the room's own quiet register — tape captions, section labels,
    /// timestamps, all read against `screen` — is not darkened to pay for a surface
    /// most of them never sit on. Dark appearance keeps `secondaryText`'s own value
    /// (5.45:1 on `inputFill` already clears AA), the same light-only asymmetry
    /// `tintText`'s doc comment describes. 5.01:1 light, measured on `inputFill`
    /// (HL-019).
    public static let secondaryTextOnFill = warm(light: 0x62_59_4D, dark: 0xA8_9D_8F)

    // MARK: Verdict and trend

    /// The go-time verdict and a completed 5-1-1 leg. First-light sage, not
    /// surgical-scrubs green — the verdict arrives like dawn, never a siren, and it is
    /// carried as text over a faint wash rather than a filled block. 11.14:1 dark,
    /// 5.89:1 light.
    public static let goTime = warm(light: 0x2F_6B_45, dark: 0xA9_CD_A8)

    /// The wash itself — HL-003 slice 3, the verdict's one moment of dawn: a faint
    /// sage rise behind the met/held banner, never a filled block. A token rather
    /// than an inline `.opacity()` at the call site (decision 0034 §6 — a colour
    /// computed inside a view is the one colour `PaletteContrastTests` cannot see).
    ///
    /// **0.10, not `tintFill`'s 0.15.** This wash carries three inks, not one —
    /// `primaryText` (the sentences), `goTime` itself (the headline), and
    /// `secondaryText` (the evidence rows' leg names) — and `secondaryText` is the
    /// one that decided the number: it holds 5.63:1 on `screen` but only 4.624:1 on
    /// a 0.14 wash, nine hundredths from failing at 11 pt where 4.5 is the actual
    /// bar. At 0.10 every ink on this surface clears AA with real margin —
    /// `primaryText` 13.37:1 dark / 12.26:1 light, `secondaryText` 6.22:1 dark /
    /// **4.90:1 light**, `goTime` 9.46:1 dark / **5.13:1 light** — light appearance
    /// narrowest throughout, same as every other pairing in this file
    /// (`PaletteContrastTests.goTimeFillClearsAAForEveryInkColour`).
    public static let goTimeFill = goTime.opacity(0.10)

    /// "Easing off" only: cool moonlight blue-grey, the semantic opposite of the
    /// warming ember. Warming means closer, cooling means easing — a nightstand-native
    /// metaphor that stays numerate and never judges. 9.14:1 dark, 5.29:1 light.
    public static let easing = warm(light: 0x4E_6A_7E, dark: 0x9F_B4_C7)

    // MARK: Gauge

    /// Tick marks on the tape. Graticule, not datum: the ember fill carries the figure,
    /// so these stay in the quiet register by design — but not at the hairline's, which
    /// was measured and rejected. `hairline` puts them at 1.29:1 on the dark room where
    /// the tape shipped at 2.45:1 and passed SP-195's audit there; halving the rhythm
    /// marks of the app's own instrument is not a change the identity asked for. These
    /// values hold that parity in both appearances (2.34:1 dark, 2.27:1 light against
    /// the 2.11:1 the light tape shipped with).
    ///
    /// Still short of HIG's 3:1 for a meaningful graphic, and deliberately: these are
    /// rest marks, not scale. HL-003's ember tape adds elapsed-position marks (0:30,
    /// 1:00, 1:30) that *do* carry figures, and those take their own register when they
    /// arrive — `secondaryText` for the mark and its caption, `tint` once the live mound
    /// has passed it. What must not happen is brightening this token to serve them,
    /// which would announce every rest mark on the tape to light three.
    public static let tick = warm(light: 0xB0_A4_93, dark: 0x57_4C_41)

    // MARK: -

    /// The one place a hex value becomes a colour. Both appearances are given
    /// explicitly — there is no "derive dark from light" here, because the warm
    /// near-black room and the warm paper are two designs, not one with a filter.
    static func warm(light: UInt32, dark: UInt32) -> Color {
        Color(
            UIColor { $0.userInterfaceStyle == .dark ? rgb(dark) : rgb(light) }
        )
    }

    static func rgb(_ hex: UInt32) -> UIColor {
        UIColor(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
