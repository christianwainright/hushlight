#!/usr/bin/env swift
// App Store marketing frames and preview overlays for Hushlight (HL-037).
//
//   swift scripts/make-store-frames.swift <spec.json> <out-dir>
//
// Reads a spec of framed screenshots and preview text cards and renders:
//   frames/<id>.png          1320×2868, opaque — the store screenshot (or, for a frame
//                            with "device": "ipad", the 13" capture's own size — HL-058c;
//                            with "device": "duo", the iPhone Duo capture's — HL-064)
//   preview/card-<id>.png            886×1920, alpha — a text card, on its own scrim, that
//                                    fades over the footage
//   preview/layout.json              where the footage goes, for make-store-preview.sh —
//                                    the whole canvas, since App Review round 2
//
// Build tooling under scripts/, so it draws with CoreGraphics and names hex directly —
// the values are copies of DesignKit's Palette tokens (Nightstand, HL-001) and must
// follow them if they move. Type is the app's own: New York for the headline (the
// voice role — the register the app uses when it speaks as a person), SF Pro for the
// subline, SF Mono caps for the eyebrow, exactly as the timer's own labels are set.
//
// The layout is authored once in the 1320×2868 frame space; preview assets are the same
// geometry scaled by 886/1320. A preview used to be the screenshot come to life — room,
// device, bezel — until App Review round 2 (2026-09-09) rejected that under Guideline
// 2.3.4: a preview must show the app as it will appear on the device, and device frames
// are the named exclusion. Framed *screenshots* remain allowed (Apple accepted all 98);
// framed previews do not. So a preview is now the footage full-bleed, and the only thing
// drawn over it is text, which the same guideline names as allowed.
import AppKit
import CoreText
import Foundation

// MARK: Spec

struct Spec: Decodable {
    struct Frame: Decodable {
        let id: String
        let source: String
        let appearance: String
        let eyebrow: String
        let headline: String
        let subline: String?
        /// "ipad" for the HL-058c set, "duo" for HL-064's; absent means the 6.9" iPhone
        /// capture.
        let device: String?
    }
    struct Card: Decodable {
        let id: String
        let appearance: String
        let eyebrow: String?
        let headline: String
        let subline: String?
    }
    let frames: [Frame]
    let cards: [Card]
}

// MARK: Palette (copies of DesignKit Palette.swift — Nightstand)

struct Appearance {
    let room: CGColor          // Palette.screen
    let glow: CGColor          // Palette.tint, laid in as lamplight behind the device
    let primary: CGColor       // Palette.primaryText
    let secondary: CGColor     // Palette.secondaryText
    let ember: CGColor         // Palette.tint
    let bezel: CGColor
    let bezelEdge: CGColor     // Palette.hairline, low alpha

    static func named(_ name: String) -> Appearance {
        name == "light" ? light : dark
    }
    static let dark = Appearance(
        room: hex(0x0E0C0A), glow: hex(0xF0A868), primary: hex(0xEDE6DB),
        secondary: hex(0xA89D8F), ember: hex(0xF0A868), bezel: hex(0x1A1613),
        bezelEdge: hex(0x2B251F, alpha: 0.9))
    static let light = Appearance(
        room: hex(0xFAF6EF), glow: hex(0xA55A24), primary: hex(0x2A2520),
        secondary: hex(0x6B6154), ember: hex(0xA55A24), bezel: hex(0x1A1613),
        bezelEdge: hex(0x2B251F, alpha: 0.9))
}

func hex(_ v: UInt32, alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((v >> 16) & 0xFF) / 255,
            green: CGFloat((v >> 8) & 0xFF) / 255,
            blue: CGFloat(v & 0xFF) / 255, alpha: alpha)
}

// MARK: Layout — the iPhone frame space is 1320×2868; the iPad's is its own capture

struct Layout {
    let scale: CGFloat                  // 1 for frames, 886/1320 for preview assets
    let canvas: CGSize
    let screenOrigin: CGPoint           // top-left origin, y measured from the top of the canvas
    let screenSize: CGSize
    let screenCornerRadius: CGFloat
    let bezelWidth: CGFloat
    let margin: CGFloat
    let textTop: CGFloat
    let eyebrowSize: CGFloat
    let headlineSize: CGFloat
    let sublineSize: CGFloat

    var bezelRect: CGRect { CGRect(origin: screenOrigin, size: screenSize).insetBy(dx: -bezelWidth, dy: -bezelWidth) }
    var bezelCornerRadius: CGFloat { screenCornerRadius + bezelWidth }
    var textWidth: CGFloat { canvas.width - 2 * margin }

    /// The 6.9" iPhone frame. Apple's preview size is 886×1920, not the 886×1925 a pure
    /// scale gives — the canvas is clamped and the five pixels come off the bleed at the
    /// bottom. The device: the 1320×2868 capture at 0.74, bezel 28 around it, set so its
    /// lower bezel runs just off the canvas — the Start slab stays whole, the frame reads
    /// as a phone resting on the room's floor rather than floating.
    static func phone(scale: CGFloat) -> Layout {
        let canvas = CGSize(width: (1320 * scale).rounded(), height: scale == 1 ? 2868 : 1920)
        let screenScale: CGFloat = 0.74
        let screenSize = CGSize(width: 1320 * screenScale * scale, height: 2868 * screenScale * scale)
        return Layout(
            scale: scale, canvas: canvas,
            screenOrigin: CGPoint(x: (canvas.width - screenSize.width) / 2, y: 748 * scale),
            screenSize: screenSize,
            screenCornerRadius: 168 * screenScale * scale, // the 17 Pro Max's display corner, ~56 pt
            bezelWidth: 28 * scale,
            margin: 96 * scale, textTop: 168 * scale,
            eyebrowSize: 34 * scale, headlineSize: 108 * scale, sublineSize: 46 * scale)
    }

    /// The iPad frame (HL-058c): the canvas is the capture's own size — 2064×2752
    /// portrait for *Hand*, 2752×2064 landscape for *Stand* — which is what the 13" slot
    /// takes. The device sits at 0.74 like the phone, with the flat, even bezel and the
    /// small corner an iPad Pro actually has; landscape keeps the copy off the full
    /// width, since a headline across 2,700 pixels reads as a banner, not a sentence.
    static func pad(capture: CGSize) -> Layout {
        let landscape = capture.width > capture.height
        let screenScale: CGFloat = 0.74
        let screenSize = CGSize(width: capture.width * screenScale, height: capture.height * screenScale)
        let textTop: CGFloat = landscape ? 120 : 168
        let screenTop: CGFloat = landscape ? 560 : 748
        return Layout(
            scale: 1, canvas: capture,
            screenOrigin: CGPoint(x: (capture.width - screenSize.width) / 2, y: screenTop),
            screenSize: screenSize,
            screenCornerRadius: 44 * screenScale,          // iPad Pro's display corner, ~22 pt at 2×
            bezelWidth: 44,
            margin: landscape ? capture.width * 0.17 : 120, textTop: textTop,
            eyebrowSize: 40, headlineSize: landscape ? 116 : 128, sublineSize: 52)
    }

    /// The iPhone Duo frame (HL-064): the canvas is the capture's own size — 1398×2034
    /// from the outer display, 2007×2853 from the inner — both slots App Store Connect
    /// takes for the Duo. Both displays share one aspect, near the iPad's, so the iPad
    /// portrait geometry carries over in proportion: device at 0.74, its top at 27% of
    /// the height so the lower bezel runs just off the canvas, type scaled to the width
    /// against the iPad's 2064. The corner is a phone's, not a slab's.
    static func duo(capture: CGSize) -> Layout {
        let screenScale: CGFloat = 0.74
        let k = capture.width / 2064
        let screenSize = CGSize(width: capture.width * screenScale, height: capture.height * screenScale)
        return Layout(
            scale: 1, canvas: capture,
            screenOrigin: CGPoint(x: (capture.width - screenSize.width) / 2, y: (capture.height * 0.272).rounded()),
            screenSize: screenSize,
            screenCornerRadius: 168 * screenScale * capture.width / 1320,
            bezelWidth: 28 * capture.width / 1320,
            margin: 120 * k, textTop: 168 * k,
            eyebrowSize: 40 * k, headlineSize: 128 * k, sublineSize: 52 * k)
    }
}

// MARK: Fonts

func font(_ size: CGFloat, weight: NSFont.Weight, design: NSFontDescriptor.SystemDesign) -> NSFont {
    let base = NSFont.systemFont(ofSize: size, weight: weight)
    guard let d = base.fontDescriptor.withDesign(design), let f = NSFont(descriptor: d, size: size) else {
        return base
    }
    return f
}

// MARK: Drawing

/// A bitmap context with a top-left origin, so layout reads like the spec.
func makeContext(size: CGSize, opaque: Bool) -> CGContext {
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    let info: CGImageAlphaInfo = opaque ? .noneSkipLast : .premultipliedLast
    let ctx = CGContext(data: nil, width: Int(size.width), height: Int(size.height),
                        bitsPerComponent: 8, bytesPerRow: 0, space: space,
                        bitmapInfo: info.rawValue)!
    ctx.translateBy(x: 0, y: size.height)
    ctx.scaleBy(x: 1, y: -1)
    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)
    ctx.setAllowsFontSmoothing(true)
    ctx.setShouldSmoothFonts(true)
    return ctx
}

func write(_ ctx: CGContext, to url: URL) {
    let image = ctx.makeImage()!
    let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
    print("make-store-frames: \(url.path)")
}

/// The room: flat warm near-black (or paper), and one ember of lamplight rising from
/// behind the device. Many close stops from radius zero — far-spaced stops mach-band
/// into rings on a near-black field (HL-035's lesson).
func drawRoom(_ ctx: CGContext, layout: Layout, appearance: Appearance) {
    ctx.setFillColor(appearance.room)
    ctx.fill(CGRect(origin: .zero, size: layout.canvas))

    let center = CGPoint(x: layout.canvas.width / 2, y: layout.screenOrigin.y + layout.screenSize.height * 0.55)
    let radius = layout.canvas.width * 0.95
    let peak: CGFloat = appearance.room == Appearance.dark.room ? 0.34 : 0.16
    var colors: [CGColor] = []
    var locations: [CGFloat] = []
    let steps = 24
    let glow = appearance.glow.components!
    for i in 0...steps {
        let t = CGFloat(i) / CGFloat(steps)
        // Ease-out falloff; alpha reaches zero before the edge so nothing clips.
        let a = peak * pow(1 - t, 2.2)
        colors.append(CGColor(srgbRed: glow[0], green: glow[1], blue: glow[2], alpha: a))
        locations.append(t)
    }
    let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                              colors: colors as CFArray, locations: locations)!
    ctx.saveGState()
    ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0,
                           endCenter: center, endRadius: radius, options: [])
    ctx.restoreGState()
}

func roundedPath(_ rect: CGRect, radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

func drawBezel(_ ctx: CGContext, layout: Layout, appearance: Appearance) {
    let outer = roundedPath(layout.bezelRect, radius: layout.bezelCornerRadius)

    // Soft shadow under the device so it sits on the room rather than floating on it.
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: 18 * layout.scale), blur: 64 * layout.scale,
                  color: CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.45))
    ctx.setFillColor(appearance.bezel)
    ctx.addPath(outer)
    ctx.fillPath()
    ctx.restoreGState()

    // A hairline catching the lamplight along the bezel's outer edge.
    ctx.saveGState()
    ctx.setStrokeColor(appearance.bezelEdge)
    ctx.setLineWidth(2 * layout.scale)
    ctx.addPath(roundedPath(layout.bezelRect.insetBy(dx: 1, dy: 1), radius: layout.bezelCornerRadius - 1))
    ctx.strokePath()
    ctx.restoreGState()
}

func drawScreenshot(_ ctx: CGContext, layout: Layout, image: CGImage) {
    let rect = CGRect(origin: layout.screenOrigin, size: layout.screenSize)
    ctx.saveGState()
    ctx.addPath(roundedPath(rect, radius: layout.screenCornerRadius))
    ctx.clip()
    // CGContext.draw expects a bottom-left origin; flip back for the image only.
    ctx.translateBy(x: 0, y: rect.maxY + rect.minY)
    ctx.scaleBy(x: 1, y: -1)
    ctx.interpolationQuality = .high
    ctx.draw(image, in: rect)
    ctx.restoreGState()
}

/// Draws one attributed paragraph, centred, starting at `top`; returns the height used.
@discardableResult
func drawText(_ ctx: CGContext, _ string: NSAttributedString, top: CGFloat, layout: Layout) -> CGFloat {
    let setter = CTFramesetterCreateWithAttributedString(string)
    let constraint = CGSize(width: layout.textWidth, height: .greatestFiniteMagnitude)
    let size = CTFramesetterSuggestFrameSizeWithConstraints(setter, CFRange(), nil, constraint, nil)
    let rect = CGRect(x: layout.margin, y: top, width: layout.textWidth, height: ceil(size.height) + 4)
    let path = CGPath(rect: rect, transform: nil)
    let frame = CTFramesetterCreateFrame(setter, CFRange(), path, nil)
    ctx.saveGState()
    // CoreText draws bottom-up; flip within the text rect.
    ctx.translateBy(x: 0, y: rect.minY + rect.maxY)
    ctx.scaleBy(x: 1, y: -1)
    CTFrameDraw(frame, ctx)
    ctx.restoreGState()
    return rect.height
}

func textHeight(_ string: NSAttributedString, layout: Layout) -> CGFloat {
    let setter = CTFramesetterCreateWithAttributedString(string)
    let constraint = CGSize(width: layout.textWidth, height: .greatestFiniteMagnitude)
    return ceil(CTFramesetterSuggestFrameSizeWithConstraints(setter, CFRange(), nil, constraint, nil).height) + 4
}

func attributed(_ text: String, font: NSFont, color: CGColor, tracking: CGFloat = 0, lineHeight: CGFloat) -> NSAttributedString {
    let style = NSMutableParagraphStyle()
    style.alignment = .center
    style.minimumLineHeight = lineHeight
    style.maximumLineHeight = lineHeight
    return NSAttributedString(string: text, attributes: [
        .font: font,
        .foregroundColor: NSColor(cgColor: color)!,
        .kern: tracking,
        .paragraphStyle: style,
    ])
}

/// The scrim under a preview card. Over full-bleed footage the card's zone is the app's
/// own status bar, header and readout, and a serif headline across a mono figure is
/// unreadable in both directions. So each card carries a gradient from near-opaque at
/// the top edge to clear a little past where the device used to begin, baked into the
/// card so it arrives and leaves with the words. It uses the bezel tone, which agrees
/// with the dark appearance's text colours; both previews are dark. A light preview
/// would want a light scrim and there is none, which is written here rather than
/// silently wrong.
func drawScrim(_ ctx: CGContext, layout: Layout, appearance: Appearance) {
    let bottom = layout.bezelRect.minY + 120 * layout.scale
    // Near-solid from the top edge through the whole text zone, then the fade: a gradient
    // that thinned across the zone let the Lock Screen's clock read through a headline.
    guard let top = appearance.bezel.copy(alpha: 0.96), let clear = appearance.bezel.copy(alpha: 0),
          let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                    colors: [top, top, clear] as CFArray, locations: [0, 0.72, 1]) else { return }
    ctx.saveGState()
    ctx.clip(to: CGRect(x: 0, y: 0, width: layout.canvas.width, height: bottom))
    ctx.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: bottom), options: [])
    ctx.restoreGState()
}

/// Eyebrow, headline, subline — the same stack on a frame and on a preview card.
/// Frames are top-aligned so a swiped set keeps one baseline; a card is centred in the
/// zone above the device, because a lone headline left top-aligned leaves a hole.
func drawCopy(_ ctx: CGContext, layout: Layout, appearance: Appearance,
              eyebrow: String?, headline: String, subline: String?, centered: Bool) {
    var parts: [(NSAttributedString, CGFloat)] = []   // string, gap after
    if let eyebrow, !eyebrow.isEmpty {
        let f = font(layout.eyebrowSize, weight: .medium, design: .monospaced)
        parts.append((attributed(eyebrow.uppercased(), font: f, color: appearance.ember,
                                 tracking: layout.eyebrowSize * 0.18, lineHeight: layout.eyebrowSize * 1.3),
                      28 * layout.scale))
    }
    let hf = font(layout.headlineSize, weight: .medium, design: .serif)
    parts.append((attributed(headline, font: hf, color: appearance.primary,
                             tracking: -layout.headlineSize * 0.01, lineHeight: layout.headlineSize * 1.12),
                  30 * layout.scale))
    if let subline, !subline.isEmpty {
        let sf = font(layout.sublineSize, weight: .regular, design: .default)
        parts.append((attributed(subline, font: sf, color: appearance.secondary,
                                 lineHeight: layout.sublineSize * 1.34), 0))
    }
    var y = layout.textTop
    if centered {
        let block = parts.enumerated().reduce(CGFloat(0)) { acc, e in
            acc + textHeight(e.element.0, layout: layout) + (e.offset == parts.count - 1 ? 0 : e.element.1)
        }
        let zoneBottom = layout.bezelRect.minY - 36 * layout.scale
        y = max(layout.textTop * 0.6, layout.textTop * 0.6 + (zoneBottom - layout.textTop * 0.6 - block) / 2)
    }
    for (index, part) in parts.enumerated() {
        y += drawText(ctx, part.0, top: y, layout: layout)
        if index < parts.count - 1 { y += part.1 }
    }
}

// MARK: Main

let args = CommandLine.arguments
guard args.count == 3 else {
    FileHandle.standardError.write("usage: make-store-frames.swift <spec.json> <out-dir>\n".data(using: .utf8)!)
    exit(2)
}
let specURL = URL(fileURLWithPath: args[1])
let outDir = URL(fileURLWithPath: args[2])
let spec = try JSONDecoder().decode(Spec.self, from: Data(contentsOf: specURL))
let specDir = specURL.deletingLastPathComponent()
let fm = FileManager.default
try fm.createDirectory(at: outDir.appendingPathComponent("frames"), withIntermediateDirectories: true)
try fm.createDirectory(at: outDir.appendingPathComponent("preview"), withIntermediateDirectories: true)

// Frames: 1320×2868 for the iPhone set, the capture's own size for the iPad set; opaque.
for frame in spec.frames {
    let appearance = Appearance.named(frame.appearance)
    let sourceURL = frame.source.hasPrefix("/") ? URL(fileURLWithPath: frame.source) : specDir.appendingPathComponent(frame.source)
    guard let src = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
        FileHandle.standardError.write("make-store-frames: cannot read \(sourceURL.path)\n".data(using: .utf8)!)
        exit(1)
    }
    let frameLayout: Layout
    if frame.device == "ipad" {
        let capture = CGSize(width: image.width, height: image.height)
        let sizes: [CGSize] = [CGSize(width: 2064, height: 2752), CGSize(width: 2752, height: 2064)]
        guard sizes.contains(capture) else {
            FileHandle.standardError.write("make-store-frames: \(frame.source) is \(image.width)×\(image.height), not a 13\" iPad capture\n".data(using: .utf8)!)
            exit(1)
        }
        frameLayout = .pad(capture: capture)
    } else if frame.device == "duo" {
        let capture = CGSize(width: image.width, height: image.height)
        let sizes: [CGSize] = [CGSize(width: 1398, height: 2034), CGSize(width: 2007, height: 2853)]
        guard sizes.contains(capture) else {
            FileHandle.standardError.write("make-store-frames: \(frame.source) is \(image.width)×\(image.height), not an iPhone Duo capture\n".data(using: .utf8)!)
            exit(1)
        }
        frameLayout = .duo(capture: capture)
    } else {
        guard image.width == 1320, image.height == 2868 else {
            FileHandle.standardError.write("make-store-frames: \(frame.source) is \(image.width)×\(image.height), not a 6.9\" capture\n".data(using: .utf8)!)
            exit(1)
        }
        frameLayout = .phone(scale: 1)
    }
    let ctx = makeContext(size: frameLayout.canvas, opaque: true)
    drawRoom(ctx, layout: frameLayout, appearance: appearance)
    drawBezel(ctx, layout: frameLayout, appearance: appearance)
    drawScreenshot(ctx, layout: frameLayout, image: image)
    drawCopy(ctx, layout: frameLayout, appearance: appearance,
             eyebrow: frame.eyebrow, headline: frame.headline, subline: frame.subline, centered: false)
    write(ctx, to: outDir.appendingPathComponent("frames/\(frame.id).png"))
}

// Preview assets: 886×1920. Full-bleed — no room, no bezel — for the reason the header
// gives. The cards keep the frame's text geometry, so a preview and its screenshot still
// share one voice; what changed is what sits under the words.
// An iPad spec carries no cards — the previews are the iPhone's — and must not touch
// `preview/`, so the whole section is skipped when there is nothing to draw.
    let previewLayout = Layout.phone(scale: 886.0 / 1320.0)
    if !spec.cards.isEmpty {
    for card in spec.cards {
        let appearance = Appearance.named(card.appearance)
        let ctx = makeContext(size: previewLayout.canvas, opaque: false)
        drawScrim(ctx, layout: previewLayout, appearance: appearance)
        drawCopy(ctx, layout: previewLayout, appearance: appearance,
                 eyebrow: card.eyebrow, headline: card.headline, subline: card.subline, centered: true)
        write(ctx, to: outDir.appendingPathComponent("preview/card-\(card.id).png"))
    }

    // Where the footage goes, in preview pixels, for the ffmpeg side: the whole canvas.
    // `fullBleed` is asserted by make-store-preview.sh, so a stale layout from the framed
    // era cannot quietly put a bezel back.
    let layoutJSON: [String: Any] = [
        "canvas": ["width": Int(previewLayout.canvas.width), "height": Int(previewLayout.canvas.height)],
        "screen": ["x": 0, "y": 0, "width": Int(previewLayout.canvas.width), "height": Int(previewLayout.canvas.height)],
        "fullBleed": true,
    ]
    let data = try JSONSerialization.data(withJSONObject: layoutJSON, options: [.prettyPrinted, .sortedKeys])
    try data.write(to: outDir.appendingPathComponent("preview/layout.json"))
    print("make-store-frames: preview/layout.json")
}
