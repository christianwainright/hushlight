import SwiftUI

/// Type roles — the "Nightstand" identity (HL-001, decision 0034). Four faces, each
/// with one job, and the only place `Font.system(size:)` is allowed: call sites name a
/// role, never a point size, so nothing bypasses Dynamic Type (spec §3, §8).
///
/// The house rule stands — data numerals are monospaced, prose is SF Pro — and the
/// identity splits it by scale, which is the one substantive change here. The hero
/// numeral is **SF Rounded with monospaced digits**: rounded softens a 3am instrument
/// reading to lamplight warmth, while the monospaced-digit trait keeps the column from
/// jittering as the seconds turn, which is the whole reason the rule exists. Dense
/// tabular data — history rows, tape captions, section labels — stays true monospaced,
/// where strict column alignment is the feature rather than a side effect.
///
/// **HL-009 §3 — the fallback for scripts these faces do not cover, named rather
/// than left to the system (decision 0045's boundary).** Measured on-device against
/// the real iOS 27 cascade (`TypeFallbackCascadeTests`, `CTFontCreateForString` — the
/// exact substitution mechanism SwiftUI's text rendering uses), not assumed:
///
/// - **`.rounded` (`.hero`/`.stat`) is genuinely covered for Arabic and Hebrew.** iOS
///   ships real rounded companions at a matching weight — `SF Arabic Rounded` and
///   `SF Hebrew Rounded` — so HL-009's backlog premise ("SF Rounded has no Arabic
///   cut") is true of the Latin face itself but not of what renders on screen.
///   Devanagari, CJK and Korean have no rounded cut and fall back to each script's
///   plain system sans (`SF Devanagari`, `PingFang SC`, `Apple SD Gothic Neo`) — the
///   one honest gap, still weight-matched, and legible rather than warm.
/// - **`.monospaced` (`.row`/`.label`) holds its one job — alignment — everywhere.**
///   Devanagari, CJK and Korean substitute Apple's own system faces at the requested
///   weight; Arabic and Hebrew substitute Courier New — not an Apple design, but a
///   genuine fixed-pitch face, so the column discipline this role exists for is
///   unbroken.
/// - **The mono-caps instrument vocabulary (ASCII digits, "NOW", "CHECK", "H", "M")
///   never leaves its requested face, in any role, under any script** — proven, not
///   assumed, by the same suite. There is structurally no fallback face for those
///   glyphs to inherit a wrong weight or a foreign identity from, which is *why*
///   HL-007/HL-009's locale-invariant-digit guard holds regardless of what language
///   ships around it.
///
/// `Font.voice`'s own doc comment carries the one role the evidence found actually
/// misbehaving — see it there, since the fix is a scope constraint on that font, not
/// a change to this enum.
public enum DataTextRole {
    /// 84 pt — the live elapsed numeral, the one figure the room is lit for.
    ///
    /// Landed with HL-003 slice 1: the numeral left the disc for the top of the
    /// scrolling content above a full-width slab, which is the room this size needed
    /// — inside the old disc it could not fit, and at accessibility sizes it would
    /// have failed §8 on the first run.
    case hero
    /// 132 pt — the hero at a room's distance (HL-058, decision 0064). The iPad on a
    /// stand is read from the bed, not the hand; the live count takes this role in
    /// the *Stand* regime and nowhere else. Same face, weight and scaling curve as
    /// `hero` — it is the hero further away, not a new instrument.
    case distance
    /// 26 pt — the readout columns: last interval, averages, pattern length.
    case stat
    /// 13 pt — history rows and basis lines.
    case row
    /// 11 pt — section labels and chips, uppercased with tracking. HIG's floor for
    /// custom type, and a real `caption2` match rather than a near one (decision 0027).
    case label

    var size: CGFloat {
        switch self {
        case .hero: 84
        case .distance: 132
        case .stat: 26
        case .row: 13
        case .label: 11
        }
    }

    /// Rounded reads lighter than the system face at the same weight, so the hero and
    /// the stats take semibold where the old monospaced roles took bold — the same
    /// optical weight, not a quieter one.
    var weight: Font.Weight {
        switch self {
        case .hero, .distance, .stat: .semibold
        case .row, .label: .regular
        }
    }

    /// The text style each role scales against, so Dynamic Type moves data numerals
    /// in proportion with the prose around them.
    var relativeTo: Font.TextStyle {
        switch self {
        case .hero, .distance: .largeTitle
        case .stat: .title2
        case .row: .footnote
        case .label: .caption2
        }
    }

    /// Mono caps get ~1 pt of tracking to match the handoff's letter-spacing.
    var tracking: CGFloat {
        self == .label ? 1 : 0
    }

    /// The display-sized roles, which get shrink-to-fit rather than wrapping.
    var isHero: Bool { self == .hero || self == .distance }

    /// Rounded for the instrument, true monospaced for the table. The split is the
    /// identity's, and it is a split by scale rather than by kind: a 56 pt numeral with
    /// monospaced *digits* holds its column just as well as a monospaced face and reads
    /// warmer at arm's length, while a 13 pt history row needs every glyph on the same
    /// advance to line up down the page.
    var design: Font.Design {
        switch self {
        case .hero, .distance, .stat: .rounded
        case .row, .label: .monospaced
        }
    }

    /// A text style whose default size matches this role closely enough to use
    /// directly. Preferred wherever one exists: a text-style font *declares* Dynamic
    /// Type support, where `.system(size:)` scaled by `@ScaledMetric` only behaves as
    /// though it does — visually identical, but an accessibility audit rightly flags
    /// the latter as unsupported, and assistive tech has no way to know it adapts.
    ///
    /// The instrument roles have no matching style — nothing in the ramp is 26 or
    /// 56 pt — so they keep the scaled-metric path. See decision 0008.
    var matchingTextStyle: Font.TextStyle? {
        switch self {
        case .row: .footnote     // 13 pt, exact
        // 11 pt, exact — and a real match rather than a near one. HIG's floor for
        // custom type is 11 pt, and this role carries the timer's `CHECK · OVER 3 MIN`
        // flag and every word of its Dynamic Island. Being a genuine style match is the
        // second win: the role declares Dynamic Type instead of only performing it,
        // which is what the audit was flagging (decision 0027).
        case .label: .caption2
        // No style in the ramp is 26, 84 or 132 pt, so these keep the scaled-metric path.
        case .hero, .distance, .stat: nil
        }
    }
}

private struct DataTextModifier: ViewModifier {
    private let role: DataTextRole
    /// Scales the role's actual size, not a unit value that then gets multiplied.
    /// `UIFontMetrics` applies a piecewise curve rather than a constant ratio, so
    /// scaling 1 and multiplying by 56 amplifies the quantization at the small end.
    @ScaledMetric private var size: CGFloat

    init(role: DataTextRole) {
        self.role = role
        _size = ScaledMetric(wrappedValue: role.size, relativeTo: role.relativeTo)
    }

    private var font: Font {
        let base: Font = if let style = role.matchingTextStyle {
            .system(style, design: role.design).weight(role.weight)
        } else {
            .system(size: size, weight: role.weight, design: role.design)
        }
        // Rounded is a proportional face; the digits have to be asked for. On the
        // monospaced roles the trait is already implied and asking again is a no-op, so
        // the one call covers both branches and no role can be added without it.
        return base.monospacedDigit()
    }

    func body(content: Content) -> some View {
        content
            .font(font)
            // `kerning`, not `tracking`: tracking adds its spacing after the final
            // glyph too, and SwiftUI does not count that in the text's measured width,
            // so the last character clips inside a tight frame. The audit caught it on
            // every mono-caps label.
            .kerning(role.tracking)
            // Hero numerals are instrument readings — a 56-pt figure at AX5 is wide
            // enough to wrap "185 lb × 6" into three lines, which is technically
            // legible and useless to read. Shrinking to fit keeps it on one line
            // without dropping a character; §5's ban is on *truncation*, and nothing
            // here truncates. Prose and data rows scale unrestricted.
            .lineLimit(role.isHero ? 1 : nil)
            .minimumScaleFactor(role.isHero ? 0.4 : 1)
    }
}

extension View {
    /// Monospaced data type at a named role. Never truncates — data values flow at
    /// every type size (spec §5).
    public func dataText(_ role: DataTextRole) -> some View {
        modifier(DataTextModifier(role: role))
    }

    /// The 10-pt mono caps used for every section label and chip.
    ///
    /// - Parameter onFill: `true` when this label is drawn on `Palette.inputFill`
    ///   rather than the room — a raised card, a list row background — where
    ///   undarkened `secondaryText` measures 4.42:1 in light appearance, under AA
    ///   (HL-019). Defaults to `false`; every section label ruled directly on
    ///   `Palette.screen` leaves this unset.
    public func sectionLabelText(onFill: Bool = false) -> some View {
        dataText(.label)
            .textCase(.uppercase)
            .foregroundStyle(onFill ? Palette.secondaryTextOnFill : Palette.secondaryText)
    }
}

/// Prose roles. These map onto text styles directly, so they need no scaling helper.
extension Font {
    /// Large screen titles.
    public static let screenTitle = Font.largeTitle.bold()
    /// A claim the app makes on a card — the verdict's evidence line.
    public static let claim = Font.body.weight(.semibold)
    /// Body prose — explanatory copy, the hedged sentence, guidance.
    public static let prose = Font.body

    /// **The midwife's voice.** New York, medium — a warm serif register reserved for
    /// the two moments the app speaks as a person rather than as an instrument: the
    /// first-launch greeting and the verdict headline. Two places, deliberately: a
    /// serif that shows up anywhere else stops marking anything, and an instrument that
    /// talks constantly is one a scared reader learns to ignore.
    ///
    /// **It never carries figures.** A sentence with a measurement in it is the
    /// instrument talking, whatever it is saying — and this face has no monospaced
    /// digits, so a recomputing average would jitter under it. Only one of the two
    /// moments exists today (the first-launch greeting); the verdict's headline is
    /// HL-003's, and until it exists the verdict's evidence line stays prose.
    ///
    /// **HL-009 §3 — this is the one role the fallback investigation found actually
    /// misbehaving, and it is scoped to Latin/Greek/Cyrillic prose because of it.**
    /// `TypeFallbackCascadeTests` measured the real iOS 27 cascade for every script
    /// on the language wave's reach list: Arabic, Devanagari, CJK and Korean all
    /// substitute a correctly-weighted Apple system face (`SF Arabic Medium`, `SF
    /// Devanagari Medium`, `PingFang SC Medium`, `Apple SD Gothic Neo Medium`) — not
    /// serif, since none of those scripts has a system serif companion, but sound.
    /// **Hebrew does not**: it substitutes `Times New Roman Bold` — a non-Apple face,
    /// at the wrong weight, for a single Hebrew word. There is no better public
    /// alternative to name instead (`SF Hebrew` is a private, dot-prefixed system
    /// face; hardcoding it is exactly the fragile-across-OS-releases complexity
    /// decision 0045 warns against inventing, and it still carries no serif register
    /// once named — `Arial Hebrew`, the one other public Hebrew family, has no Medium
    /// cut either). So the constraint is on the caller, not a workaround here: HL-008
    /// must re-run this evidence for whatever script it actually ships before routing
    /// translated prose through `Font.voice`, and Hebrew specifically needs a decision
    /// — accept the Times New Roman substitution, or drop `.voice` to `.claim`/`.prose`
    /// for that language — rather than inheriting whatever iOS happens to pick.
    public static let voice = Font.system(.title2, design: .serif).weight(.medium)
}
