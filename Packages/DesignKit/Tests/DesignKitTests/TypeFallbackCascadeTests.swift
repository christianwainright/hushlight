import CoreText
import SwiftUI
import Testing
import UIKit
@testable import DesignKit

/// HL-009 item 3: decision 0045's boundary is "name the fallback explicitly, never
/// let the system pick per screen" for the scripts SF Rounded and New York do not
/// cover. `FontResolutionTests` already treats font substitution as a question of
/// evidence rather than assumption (SP-019's "checked rather than assumed"); this
/// suite asks the same question of the identity's actual type roles
/// (`DataTextRole`, `Font.voice`) against every script HL-008's language wave could
/// plausibly ship, using `CTFontCreateForString` — the exact mechanism CoreText (and
/// so UIKit/SwiftUI's text rendering underneath it) uses to pick a substitute font
/// per run when the requested face has no glyph for a character. This is on-device
/// truth about iOS 27's own cascade tables, not a guess about what "should" happen.
///
/// **What the evidence found**, recorded here so Typography.swift's doc comments can
/// state it as fact:
///
/// - **Rounded (`.hero`/`.stat`) is genuinely covered for Arabic and Hebrew.** iOS
///   ships real rounded companions — SF Arabic Rounded, SF Hebrew Rounded — at a
///   matching weight. The "SF Rounded has no Arabic cut" premise in HL-009's backlog
///   entry is true of the *Latin* SF Rounded face itself but not of what a reader
///   actually sees: the system substitutes a same-family, same-weight rounded face.
/// - **Devanagari, CJK and Korean have no rounded cut** and fall back to each
///   script's plain system sans (SF Devanagari / PingFang / Apple SD Gothic Neo),
///   still at the correct weight. This is the one honest gap the backlog item
///   anticipated — named here, not hidden.
/// - **Monospaced (`.row`/`.label`) stays legible everywhere.** Devanagari, CJK and
///   Korean get Apple's own system faces; Arabic and Hebrew fall back to Courier
///   New — not an Apple design, but a real fixed-pitch face, so column alignment
///   (the entire reason `.row`/`.label` are monospaced) still holds.
/// - **Serif (`Font.voice`) is the one role that actually misbehaves,** and it is
///   scoped correctly today because of it: Hebrew substitutes Times New Roman
///   *Bold* for a Medium request — a non-Apple face at the wrong weight, not merely
///   a design mismatch — and CJK substitutes Songti SC Bold, because Songti SC ships
///   no Medium cut at all to ask for. Neither Apple nor any public API offers a
///   better substitute (`SF Arabic`/`SF Hebrew`/`SF Devanagari` are private,
///   dot-prefixed system faces — not nameable from app code, and hardcoding them
///   is exactly the fragile-across-OS-updates complexity 0045 warns against
///   inventing). `Font.voice` stays what decision 0034 §7 already scoped it to: two
///   English moments carrying no figures. HL-008 must re-run this evidence for
///   whatever script it actually ships before routing translated prose through
///   `Font.voice` — the constraint is now measured, not assumed.
@Suite("Type fallback cascade (HL-009)")
struct TypeFallbackCascadeTests {
    /// One clause per script HL-008's reach list (BACKLOG.md's language wave) or
    /// HD-4's open RTL/non-Latin candidates could plausibly need. Digits and prose
    /// both, because a script can lose its own font's coverage on one and not the
    /// other (Devanagari's own digit block is separate from its letters in Unicode).
    private struct Script {
        let label: String
        let sample: String
    }

    private static let scripts: [Script] = [
        Script(label: "Arabic digits", sample: "٠١٢٣٤٥٦٧٨٩"),
        Script(label: "Arabic prose", sample: "الطلق"),
        Script(label: "Hebrew prose", sample: "צירים"),
        Script(label: "Devanagari digits", sample: "०१२३४५६७८९"),
        Script(label: "Devanagari prose", sample: "प्रसव"),
        Script(label: "CJK prose", sample: "陣痛"),
        Script(label: "Korean prose", sample: "진통"),
    ]

    /// Runs CoreText's own substitution for `sample` against `base`, returning the
    /// PostScript name CoreText actually selected — `base`'s own name when the face
    /// already covers the run, a different name when it fell back.
    private static func substitutedFace(for sample: String, base: UIFont) -> String {
        let ctBase = base as CTFont
        let cfString = sample as CFString
        let range = CFRangeMake(0, CFStringGetLength(cfString))
        let substituted = CTFontCreateForString(ctBase, cfString, range)
        return CTFontCopyPostScriptName(substituted) as String
    }

    private static func systemFont(design: UIFontDescriptor.SystemDesign, weight: UIFont.Weight, size: CGFloat) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = base.fontDescriptor.withDesign(design) else { return base }
        return UIFont(descriptor: descriptor, size: size)
    }

    /// The instrument vocabulary (decisions 0022–0026, CLAUDE.md) is ASCII digits and
    /// Latin mono-caps ("NOW", "CHECK", "H", "M") — the figures this app never lets
    /// a locale reformat. This is the structural reason that vocabulary is safe under
    /// every script HL-008 could ship: it never leaves the requested face at all, in
    /// any role, so there is no fallback face for it to inherit a wrong weight or a
    /// foreign identity from. HL-007/HL-009's UI-level digit guard
    /// (`LocaleFormatUITests`) proves this at the pixel; this proves *why* it holds.
    @Test func instrumentVocabularyNeverLeavesItsRequestedFace() {
        let roundedHero = Self.systemFont(design: .rounded, weight: .semibold, size: DataTextRole.hero.size)
        let monoRow = Self.systemFont(design: .monospaced, weight: .regular, size: DataTextRole.row.size)
        let monoLabel = Self.systemFont(design: .monospaced, weight: .regular, size: DataTextRole.label.size)
        let voice = Self.systemFont(design: .serif, weight: .medium, size: 22)

        for face in [roundedHero, monoRow, monoLabel, voice] {
            let baseName = face.fontName
            for vocabulary in ["0123456789", "NOW", "CHECK", "H", "M"] {
                #expect(
                    Self.substitutedFace(for: vocabulary, base: face) == baseName,
                    "\(baseName) fell back for instrument glyph '\(vocabulary)' — the mono-caps vocabulary must never leave its requested face"
                )
            }
        }
    }

    /// Arabic and Hebrew get genuine rounded companions at `.hero`'s weight — the
    /// evidence behind Typography.swift's doc comment correcting HL-009's "no Arabic
    /// cut" premise for the *rounded* role specifically. Checked on family identity
    /// (contains "Arabic"/"Hebrew") rather than the exact private PostScript name, so
    /// this does not pin to an internal string an OS point release is free to rename.
    @Test func roundedGetsScriptMatchedCompanionsForArabicAndHebrew() {
        let hero = Self.systemFont(design: .rounded, weight: .semibold, size: DataTextRole.hero.size)
        let arabic = Self.substitutedFace(for: "الطلق", base: hero)
        let hebrew = Self.substitutedFace(for: "צירים", base: hero)
        #expect(arabic.localizedCaseInsensitiveContains("Arabic"))
        #expect(hebrew.localizedCaseInsensitiveContains("Hebrew"))
        // Both weight-suffixed the way the base request was: `.rounded` asked for
        // `.semibold`, and CoreText's cascade preserved that rather than snapping to
        // whatever the substitute's default happens to be — print rather than assert
        // the exact suffix spelling, which is exactly `FontResolutionTests`' own
        // "observation, not an assertion about which ones exist" stance.
        print("HL-009 rounded cascade — Arabic: \(arabic), Hebrew: \(hebrew)")
        // Devanagari/CJK/Korean printed too, un-asserted: this is the honest gap —
        // no rounded cut exists for them, so the substitute is each script's plain
        // system sans rather than a rounded companion (still weight-matched).
        for script in Self.scripts where !script.label.contains("Arabic") && !script.label.contains("Hebrew") {
            print("HL-009 rounded cascade — \(script.label): \(Self.substitutedFace(for: script.sample, base: hero))")
        }
    }

    /// `.row`/`.label` (monospaced) evidence — printed for the same reason as the
    /// serif suite: Typography.swift's claim that alignment survives fallback
    /// everywhere is a statement about real substitutes, not an assumption.
    @Test func monospacedCascadeEvidence() {
        let row = Self.systemFont(design: .monospaced, weight: .regular, size: DataTextRole.row.size)
        for script in Self.scripts {
            print("HL-009 monospaced cascade — \(script.label): \(Self.substitutedFace(for: script.sample, base: row))")
        }
    }

    /// `Font.voice` is the one role the evidence found actually misbehaving —
    /// recorded so the finding is reproducible, not just narrated. No `#expect`
    /// pins the substitute's exact name (an OS update is free to change it); the
    /// weight-and-identity drift is the finding, stated in this file's own doc
    /// comment and in Typography.swift, backed by this printed evidence.
    @Test func serifCascadeEvidenceForNonLatinScripts() {
        let voice = Self.systemFont(design: .serif, weight: .medium, size: 22)
        for script in Self.scripts {
            let substituted = Self.substitutedFace(for: script.sample, base: voice)
            print("HL-009 Font.voice cascade — \(script.label): \(substituted)")
        }
    }

    /// Every role's base request resolves to a real, non-nil font — the minimum bar
    /// "the system fallback is correct and consistent" has to clear before this
    /// suite's finding (serif is the exception) can be trusted at all.
    @Test func everyRoleResolvesANonPlaceholderBaseFont() {
        let roles: [(String, UIFont)] = [
            ("hero", Self.systemFont(design: .rounded, weight: .semibold, size: DataTextRole.hero.size)),
            ("stat", Self.systemFont(design: .rounded, weight: .semibold, size: DataTextRole.stat.size)),
            ("row", Self.systemFont(design: .monospaced, weight: .regular, size: DataTextRole.row.size)),
            ("label", Self.systemFont(design: .monospaced, weight: .regular, size: DataTextRole.label.size)),
            ("voice", Self.systemFont(design: .serif, weight: .medium, size: 22)),
        ]
        for (name, font) in roles {
            #expect(!font.fontName.isEmpty, "\(name) role resolved an empty font name")
        }
    }
}
