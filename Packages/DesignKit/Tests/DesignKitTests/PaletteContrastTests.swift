import SwiftUI
import Testing
import UIKit
@testable import DesignKit

/// Palette.swift's doc comments state a contrast ratio for every text pair — this suite
/// is what keeps that claim honest. An eyeballed ratio is a guess about a rendered pixel;
/// this one resolves the actual `UIColor` for each appearance and runs the WCAG 2.1 math
/// against it, so a hex edit that quietly erodes legibility (or drifts the doc comment
/// away from the shipped value) fails a build instead of waiting for someone to notice at
/// 3am. It also stands guard on the one rule with no numeric form: nothing in this palette
/// may read as red. HL-001, decision 0034.
@Suite("Palette contrast")
struct PaletteContrastTests {
    // MARK: WCAG 2.1 contrast math

    /// sRGB channel linearization (WCAG 2.1 §1.4.3 formula), applied per channel before
    /// the luminance weighting below.
    private static func linearize(_ channel: CGFloat) -> Double {
        let c = Double(channel)
        return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
    }

    private static func relativeLuminance(_ color: UIColor) -> Double {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b)
    }

    private static func contrastRatio(_ a: UIColor, _ b: UIColor) -> Double {
        let la = relativeLuminance(a)
        let lb = relativeLuminance(b)
        let hi = max(la, lb)
        let lo = min(la, lb)
        return (hi + 0.05) / (lo + 0.05)
    }

    /// Resolves a `Palette` token to the concrete `UIColor` iOS would actually draw in
    /// the given appearance — the same resolution the compositor does, not an
    /// approximation of it.
    private static func resolve(_ color: Color, _ style: UIUserInterfaceStyle) -> UIColor {
        UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
    }

    /// AA's floor for normal-size text (WCAG 2.1 SC 1.4.3). Every pair Palette.swift
    /// claims a ratio for is claimed to carry text, so every pair is held to it — this
    /// is the assertion the whole suite exists to make.
    private static let aaNormalText = 4.5

    /// The tolerance a computed ratio must land within of the documented one. 0.05 is
    /// tight enough to catch a real drift (a re-picked hex, a rounding slip in the doc
    /// comment) but loose enough to absorb floating-point noise in the linearization.
    private static let tolerance = 0.05

    private static func assertMatchesDocumented(
        _ measured: Double, _ documented: Double, _ label: String
    ) {
        #expect(measured >= aaNormalText, "\(label): \(measured) fails AA 4.5:1")
        #expect(abs(measured - documented) < tolerance,
                "\(label): measured \(measured), Palette.swift's doc comment claims \(documented)")
    }

    // MARK: Text on the room's background

    /// Every token Palette.swift documents against `screen`, in the dark appearance,
    /// checked against the value each doc comment states. If a hex edit moves the
    /// number, this is the table to update — not the tolerance above.
    @Test func darkOnScreenMatchesDocumentedRatios() {
        let screen = Self.resolve(Palette.screen, .dark)
        let cases: [(String, Color, Double)] = [
            ("primaryText", Palette.primaryText, 15.75),
            ("secondaryText", Palette.secondaryText, 7.33),
            ("tint", Palette.tint, 9.77),
            ("emberLive", Palette.emberLive, 12.70),
            ("goTime", Palette.goTime, 11.14),
            ("easing", Palette.easing, 9.14),
        ]
        for (name, color, documented) in cases {
            let ratio = Self.contrastRatio(Self.resolve(color, .dark), screen)
            Self.assertMatchesDocumented(ratio, documented, "\(name) dark on screen")
        }
    }

    /// The same six tokens, in the light appearance.
    @Test func lightOnScreenMatchesDocumentedRatios() {
        let screen = Self.resolve(Palette.screen, .light)
        let cases: [(String, Color, Double)] = [
            ("primaryText", Palette.primaryText, 14.09),
            ("secondaryText", Palette.secondaryText, 5.63),
            ("tint", Palette.tint, 4.77),
            ("emberLive", Palette.emberLive, 6.27),
            ("goTime", Palette.goTime, 5.89),
            ("easing", Palette.easing, 5.29),
        ]
        for (name, color, documented) in cases {
            let ratio = Self.contrastRatio(Self.resolve(color, .light), screen)
            Self.assertMatchesDocumented(ratio, documented, "\(name) light on screen")
        }
    }

    // MARK: onEmber ink on a filled surface

    /// `onEmber` inverts with appearance on purpose (dark ink in light mode, light ink
    /// in dark mode) so it stays legible on whichever ember fill is under it. Checked
    /// against both fills the doc comment names: the ordinary ember (`tint`) and the
    /// intensified one (`emberLive`).
    @Test func onEmberOnFillsMatchesDocumentedRatios() {
        let cases: [(String, Color, Double, Double)] = [
            ("onEmber on tint", Palette.tint, 9.77, 4.77),
            ("onEmber on emberLive", Palette.emberLive, 12.70, 6.27),
            // The slab's two gradient stops. They are here because their predecessor —
            // a `tint.mix(with: .black)` computed inside the view — measured 3.70:1 at
            // the bottom stop and no suite could see it. Every colour the ink actually
            // lands on is a colour this file has to know about.
            ("onEmber on emberSlabTop", Palette.emberSlabTop, 11.25, 5.53),
            ("onEmber on emberSlabBottom", Palette.emberSlabBottom, 7.43, 7.38),
        ]
        for (name, fill, documentedDark, documentedLight) in cases {
            let dark = Self.contrastRatio(Self.resolve(Palette.onEmber, .dark), Self.resolve(fill, .dark))
            let light = Self.contrastRatio(Self.resolve(Palette.onEmber, .light), Self.resolve(fill, .light))
            Self.assertMatchesDocumented(dark, documentedDark, "\(name) dark")
            Self.assertMatchesDocumented(light, documentedLight, "\(name) light")
        }
    }

    /// `tintText` is the one token that answers to a *fill* rather than to the room, so
    /// it is checked against `tintFill` — the surface a tinted capsule actually puts it
    /// on. The ember itself measures 3.93:1 there in light appearance, which is why this
    /// token stopped being an alias for it.
    @Test func tintTextClearsAAOnTheSurfaceItIsFor() {
        for style: UIUserInterfaceStyle in [.dark, .light] {
            // `tintFill` is `tint` at 15% — composite it over the room the way the
            // compositor will, rather than measuring against a colour with alpha in it.
            let composited = Self.composite(Palette.tintFill, over: Palette.screen, style)
            let ratio = Self.contrastRatio(Self.resolve(Palette.tintText, style), composited)
            #expect(ratio >= Self.aaNormalText,
                    "\(style): tintText on tintFill is \(ratio), under AA")
        }
    }

    /// `Palette.inputFill` is a third surface several inks are drawn on — the slip
    /// strip's sentence, Guidance's "Call right away" header, History's per-episode
    /// summary line and its trend caption — that none of them were ever measured
    /// against before HL-019: `secondaryText`, `tint`, and `easing` all clear AA
    /// against `Palette.screen` but drop under it on the darker `inputFill` (4.42:1,
    /// 3.74:1, 4.15:1 in light appearance respectively). `inputFill` is opaque, so
    /// unlike `tintFill`/`goTimeFill` this needs no compositing — the room never
    /// shows through it.
    @Test func textOnInputFillClearsAA() {
        for style: UIUserInterfaceStyle in [.dark, .light] {
            let fill = Self.resolve(Palette.inputFill, style)
            let cases: [(String, Color)] = [
                ("secondaryTextOnFill", Palette.secondaryTextOnFill),
                ("tintText", Palette.tintText),
                ("easingText", Palette.easingText),
            ]
            for (name, ink) in cases {
                let ratio = Self.contrastRatio(Self.resolve(ink, style), fill)
                #expect(ratio >= Self.aaNormalText, "\(style): \(name) on inputFill is \(ratio), under AA")
            }
        }
    }

    /// `goTimeFill` (HL-003 slice 3) carries three different inks over it, not one:
    /// the headline sits in `goTime` itself, the two evidence sentences in
    /// `primaryText`, and the evidence rows' leg names in `secondaryText` — the one
    /// that actually decided the wash's opacity (see `Palette.goTimeFill`'s doc
    /// comment). All three have to clear AA on the composite, same discipline
    /// `tintTextClearsAAOnTheSurfaceItIsFor` holds for the ember's fill; a wash this
    /// file cannot see the true colour of is exactly the gap decision 0034 §6 closed
    /// for `emberSlabTop`/`Bottom`.
    @Test func goTimeFillClearsAAForEveryInkColour() {
        for style: UIUserInterfaceStyle in [.dark, .light] {
            let composited = Self.composite(Palette.goTimeFill, over: Palette.screen, style)
            let cases: [(String, Color)] = [
                ("primaryText", Palette.primaryText),
                ("goTime", Palette.goTime),
                ("secondaryText", Palette.secondaryText),
            ]
            for (name, ink) in cases {
                let ratio = Self.contrastRatio(Self.resolve(ink, style), composited)
                #expect(ratio >= Self.aaNormalText, "\(style): \(name) on goTimeFill is \(ratio), under AA")
            }
        }
    }

    /// Flattens a translucent token onto an opaque one. `resolvedColor` keeps the alpha,
    /// and a ratio taken against a colour with alpha in it is a ratio against nothing.
    private static func composite(
        _ top: Color, over bottom: Color, _ style: UIUserInterfaceStyle
    ) -> UIColor {
        let t = resolve(top, style)
        let b = resolve(bottom, style)
        var tr: CGFloat = 0, tg: CGFloat = 0, tb: CGFloat = 0, ta: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        t.getRed(&tr, green: &tg, blue: &tb, alpha: &ta)
        b.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        return UIColor(
            red: tr * ta + br * (1 - ta),
            green: tg * ta + bg * (1 - ta),
            blue: tb * ta + bb * (1 - ta),
            alpha: 1
        )
    }

    // MARK: The room's structure

    /// `raised` is documented as "a *small* step from `screen`... felt, not announced" —
    /// 1.09:1 dark, 1.06:1 light. A step this small isn't a contrast pair carrying text
    /// (nothing is legible at 1.1:1); it's a structural claim about the room, so it gets
    /// its own band rather than the AA floor above.
    @Test func raisedIsASmallStepFromScreen() {
        for style: UIUserInterfaceStyle in [.dark, .light] {
            let ratio = Self.contrastRatio(Self.resolve(Palette.raised, style), Self.resolve(Palette.screen, style))
            #expect(ratio > 1.02, "\(style) raised/screen step \(ratio) is flat enough to read as no step at all")
            #expect(ratio < 1.20, "\(style) raised/screen step \(ratio) is loud enough to be announced, not felt")
        }
    }

    /// `hairline` (and `tick`, which is defined as the same token) is decorative by
    /// contract — nothing carrying a figure is drawn in it, so it is never held to AA.
    /// It still has to stay in the decorative register rather than sliding up toward a
    /// value that would tempt a future call site to put text on it.
    @Test func hairlineStaysDecorative() {
        for style: UIUserInterfaceStyle in [.dark, .light] {
            let ratio = Self.contrastRatio(Self.resolve(Palette.hairline, style), Self.resolve(Palette.screen, style))
            #expect(ratio < 2.0, "\(style) hairline/screen ratio \(ratio) is legible enough to carry a figure")
        }
    }

    // MARK: The ratchet — no token is red

    /// The danger band, in degrees of hue on the standard 0–360 wheel (0 = pure red).
    /// Measured first, drawn second: `tint` and `emberLive` — the only warm-red-adjacent
    /// tokens in the file — sit at hue 25.0–28.2° in both appearances (checked by hand
    /// against `UIColor.getHue` before this band was picked). A hazard red sits at hue
    /// 0–15° or so (iOS system red `#FF3B30` measures ~4°); nothing in a palette built
    /// to be structurally incapable of reading as an alarm should ever need to sit that
    /// low. The band below stops at 20° — five degrees of margin under the lowest
    /// measured ember hue — so it would catch an actual slide toward red (a future hex
    /// edit that saturates and rotates `tint` down past 20°) without ever flagging the
    /// ember for being exactly what it's supposed to be. No token is exempted by name:
    /// the ember tokens pass because they measure clear of the line, which is the
    /// honest version of "excluded" — if an edit ever pushed one of them under 20°, this
    /// test is supposed to fail, not wave it through.
    private static let redHueUpperBound: CGFloat = 20.0 / 360.0
    private static let redHueLowerBound: CGFloat = 340.0 / 360.0 // wraps through 0°
    /// Below this saturation a hue reading is noise (a near-neutral warm grey reporting
    /// some nominal hue) rather than a colour anyone would perceive as red.
    private static let meaningfulSaturation: CGFloat = 0.15

    /// Every public token this file can see a `Color` for, by name, so the check below
    /// is exhaustive rather than a sample. `tintFill`/`tintBorder` are `tint` at reduced
    /// alpha and `tintText`/`tick` are aliases — included anyway, because the ratchet is
    /// about what a token *is*, not about deduplicating the list.
    @Test func noTokenIsRed() {
        let tokens: [(String, Color)] = [
            ("screen", Palette.screen),
            ("raised", Palette.raised),
            ("hairline", Palette.hairline),
            ("pendingFill", Palette.pendingFill),
            ("inputFill", Palette.inputFill),
            ("primaryText", Palette.primaryText),
            ("secondaryText", Palette.secondaryText),
            ("onEmber", Palette.onEmber),
            ("tint", Palette.tint),
            ("emberLive", Palette.emberLive),
            ("tintFill", Palette.tintFill),
            ("tintBorder", Palette.tintBorder),
            ("goTimeFill", Palette.goTimeFill),
            ("tintText", Palette.tintText),
            ("goTime", Palette.goTime),
            ("easing", Palette.easing),
            ("easingText", Palette.easingText),
            ("secondaryTextOnFill", Palette.secondaryTextOnFill),
            ("tick", Palette.tick),
            ("emberSlabTop", Palette.emberSlabTop),
            ("emberSlabBottom", Palette.emberSlabBottom),
        ]
        for (name, color) in tokens {
            for style: UIUserInterfaceStyle in [.dark, .light] {
                let resolved = Self.resolve(color, style)
                var h: CGFloat = 0, s: CGFloat = 0, v: CGFloat = 0, a: CGFloat = 0
                resolved.getHue(&h, saturation: &s, brightness: &v, alpha: &a)
                let inDangerBand = s >= Self.meaningfulSaturation
                    && (h <= Self.redHueUpperBound || h >= Self.redHueLowerBound)
                #expect(!inDangerBand,
                        "\(name) \(style): hue \(h * 360)°, sat \(s) reads as red/alarm")
            }
        }
    }
}
