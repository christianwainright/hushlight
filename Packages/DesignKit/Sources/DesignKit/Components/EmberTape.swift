import SwiftUI

/// The identity's signature instrument (decision 0037): a horizontal timeline of raw
/// contractions over the trailing hour, right edge pinned to "now". Deliberately
/// linear — the brief rules out rings and donuts (spec §3) — and deliberately a raw
/// record rather than a derived fill. `TickTapeGauge`'s single progress bar retired
/// with this component: it asserted a fill percentage that stood in for evidence,
/// where this shows the evidence itself. A reader checks the app's continuity claim
/// against the picture — bars all the way back to the left edge, or a growing gap at
/// the leading edge — rather than trusting a number (decision 0037's rationale).
///
/// DesignKit has no dependencies and keeps none (CLAUDE.md), so this takes plain
/// geometry — fractions of the window, already resolved — rather than
/// `LaborKit.TapeGeometry` or `Contraction`. The app is what converts one to the
/// other.
///
/// The baseline and grid are drawn every time, with or without a single bar to show —
/// the resting instrument (empty install, or a pattern that has entirely aged out of
/// the hour) is this same view with an empty `bars` array. An axis that appears only
/// once there is data to put on it would be a surprise rather than an instrument
/// (decision 0037 §3), which is also why this is what `GhostTimeline`'s silhouette
/// retired into rather than keeping a separate decorative stand-in.
public struct EmberTape: View {
    /// One bar's position, already resolved to fractions of the window by
    /// `PatternAnalysis.tape(for:window:now:)`. See that function for what "clipped"
    /// and "floored" mean — this view draws exactly what it is given, true to scale.
    public struct Bar: Equatable, Sendable {
        /// 0…1 — 0 at the window's left edge, 1 at `now`.
        public let start: Double
        /// 0…1 — the bar's width as a fraction of the window.
        public let width: Double
        /// A soft glow, blooming past the bar; the bar's own geometry stays true to
        /// scale regardless (decision 0037 §4).
        public let isLive: Bool
        /// Suspect bars draw as an outline with no fill — texture, not colour, the
        /// same discipline `EpisodeTimeline`'s CHECK flags already keep (decision
        /// 0037 §5). This view does not distinguish *which* mistake it was; the words
        /// for that stay on the timeline row and in History.
        public let isSuspect: Bool

        public init(start: Double, width: Double, isLive: Bool, isSuspect: Bool) {
            self.start = start
            self.width = width
            self.isLive = isLive
            self.isSuspect = isSuspect
        }
    }

    /// HL-003 slice 4: whether the live bar's glow may breathe at all. The idle
    /// slab's `breathing(while:)` (SP-188, `TimerScreen.swift`) reads this same
    /// environment value the same way — motion is polish, and polish must never
    /// cost someone who has asked the system for stillness.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// `false` while settled (low), `true` while swelled (high) — driven by the
    /// `.task` below, not by `phaseAnimator`'s own automatic cycling. On-device
    /// testing found that cycling silent here: this tape sits under
    /// `TimerScreen`'s `TimelineView(.secondly)`, which rebuilds the whole
    /// screen, `EmberTape` included, once a second, and across a full breath
    /// cycle of screenshots — at both the spec's 0.30–0.60 swing and a
    /// deliberately exaggerated 0.05–0.98 one — the rendered shadow never
    /// differed by a single pixel. A plain `@State`, toggled from this view's own
    /// `.task`, survives that rebuild the same way every other `@State` on this
    /// screen already does (`TimerScreen`'s `slip`, its `corrections` counter);
    /// `phaseAnimator`'s internal phase-clock, nested three closures deep inside
    /// a `ForEach` over a freshly-computed `[Bar]`, evidently did not.
    @State private var breathIsSwelled = false

    private let bars: [Bar]
    /// The grid's cell width, as a fraction of the window — the selected rule's own
    /// interval threshold over the hour (5-1-1 → 1/12, 4-1-1 → 1/15, 3-1-1 → 1/20),
    /// never a fixed wall-clock number (decision 0037 §2). Gaps sitting at or inside
    /// one cell are decision 0024's frequency share made visible; silence spanning
    /// more than three cells is decision 0026's continuity break — both readable off
    /// the grid with no caption.
    private let tickCellFraction: Double
    private let leadingCaption: String
    private let trailingCaption: String
    /// Spoken forms of the two end caps (HL-023, F-0051). The printed captions are
    /// mono-caps instrument vocabulary — `1 H AGO` reads aloud as "1 H ago", the H
    /// a letter — and every other H/M in this app already routes through a spoken
    /// pair. DesignKit stays dependency-free: the app supplies both strings rather
    /// than this component knowing how to say a duration.
    private let leadingCaptionSpoken: String
    private let trailingCaptionSpoken: String
    /// Stable across every pattern state — a reader who heard the resting and the
    /// live instrument disagree would be hearing two instruments (mirrors
    /// `TickTapeGauge`'s retired `label` convention, which existed for the same
    /// reason).
    private let accessibilityLabel: String
    /// The raw count, spoken — never a percentage (decision 0037 §7). A raw record
    /// needs no evidence floor, so this is never withheld the way the readout's
    /// figures are.
    private let accessibilityValue: String

    /// - Parameters:
    ///   - bars: The tape's geometry. Empty draws the resting instrument.
    ///   - tickCellFraction: The grid's cell width as a fraction of the window.
    ///   - leadingCaption: The left end cap, e.g. "1 H AGO".
    ///   - trailingCaption: The right end cap, e.g. "NOW".
    ///   - leadingCaptionSpoken: How the left cap is read aloud, e.g. "one hour ago".
    ///   - trailingCaptionSpoken: How the right cap is read aloud, e.g. "now".
    ///   - accessibilityLabel: A stable label, unchanged by how many bars are drawn.
    ///   - accessibilityValue: The spoken raw count.
    public init(
        bars: [Bar],
        tickCellFraction: Double,
        leadingCaption: String,
        trailingCaption: String,
        leadingCaptionSpoken: String,
        trailingCaptionSpoken: String,
        accessibilityLabel: String,
        accessibilityValue: String
    ) {
        self.bars = bars
        self.tickCellFraction = tickCellFraction
        self.leadingCaption = leadingCaption
        self.trailingCaption = trailingCaption
        self.leadingCaptionSpoken = leadingCaptionSpoken
        self.trailingCaptionSpoken = trailingCaptionSpoken
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityValue = accessibilityValue
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Metrics.EmberTape.captionGap) {
            GeometryReader { geometry in
                ZStack(alignment: .bottomLeading) {
                    grid(size: geometry.size)
                    ForEach(Array(bars.enumerated()), id: \.offset) { _, bar in
                        barView(bar, totalWidth: geometry.size.width)
                    }
                }
            }
            .frame(height: Metrics.EmberTape.barRegionHeight)
            // Opaque to VoiceOver on its own: the grid and bars are the picture the
            // raw count already speaks for, and a percent-free instrument has no
            // second figure to lose by combining them (decision 0037 §7).
            .accessibilityElement()
            .accessibilityLabel(accessibilityLabel)
            .accessibilityValue(accessibilityValue)

            // The end caps stay **outside** that combine, as ordinary text — visible
            // words need a real accessible counterpart of their own. A first draft
            // folded them into the combine above, leaving "1 H AGO" / "NOW" on
            // screen with nothing backing them; corrected before it could become
            // exactly the kind of finding `XCUIAccessibilityAuditTypeElementDetection`
            // exists to catch. They read as two more swipe stops beside the tape's
            // own figure, not duplicated inside it — the axis's own bounds, spoken
            // once.
            HStack {
                Text(leadingCaption)
                    .dataText(.label)
                    .foregroundStyle(Palette.secondaryText)
                    .accessibilityLabel(leadingCaptionSpoken)
                Spacer(minLength: Metrics.space3)
                Text(trailingCaption)
                    .dataText(.label)
                    .foregroundStyle(Palette.secondaryText)
                    .accessibilityLabel(trailingCaptionSpoken)
            }
        }
        // Decision 0045: the tape's time axis is fixed — past on the left, NOW on
        // the right — in every locale, because it is the app's rendering of a
        // tocograph strip, not prose. `barView`'s own `.offset(x:)` already draws
        // in raw, unmirrored points (SwiftUI never flips a numeric offset for
        // layout direction), so the bars alone would already hold their axis. What
        // would NOT hold it is everything *around* them: `ZStack(alignment:
        // .bottomLeading)` resolves to bottom-*trailing* under an RTL environment,
        // which moves each bar's zero-offset anchor to the opposite edge before
        // the offset even applies, and the end-cap `HStack` above would silently
        // swap which caption sits on which side — "NOW" drifting to the left edge
        // while its accessible position claims the right. Pinning the whole
        // component to `.leftToRight` here is what keeps the anchor and the
        // offset agreeing, so the drawing holds its axis as one unit while the
        // *screen* around this view mirrors normally (0045's boundary: this is
        // not license to hard-code layout — the tape still sizes and positions by
        // geometry, never by a `.left`/`.right` literal).
        .environment(\.layoutDirection, .leftToRight)
        // Runs for as long as this `EmberTape` is on screen, whether or not a
        // live bar is currently drawn — harmless when there is none, and it
        // means the breath is always mid-cycle rather than restarting from
        // "settled" the instant a contraction starts. `.task` ties its lifetime
        // to *this view's identity*, not to how often its body re-evaluates
        // (`TimerScreen`'s `TimelineView(.secondly)` does that once a second),
        // which is exactly the durability `phaseAnimator`'s own cycling did not
        // have here (see `breathIsSwelled`'s doc comment).
        // Keyed on the setting, so flipping Reduce Motion mid-session restarts
        // (or retires) the loop rather than leaving a decision made at view
        // birth in charge. The render side (`glowOpacityFraction`) pins to mid
        // the instant the setting turns on regardless — this key only fixes the
        // other direction, where stillness had been chosen and motion is asked
        // for again.
        .task(id: reduceMotion) {
            guard !reduceMotion, !RuntimeFlags.isUITesting else { return }
            while !Task.isCancelled {
                withAnimation(.easeInOut(duration: 4)) { breathIsSwelled = true }
                try? await Task.sleep(for: .seconds(4))
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 6)) { breathIsSwelled = false }
                try? await Task.sleep(for: .seconds(6))
            }
        }
    }

    // MARK: The axis — grid and baseline, full width, always

    private func grid(size: CGSize) -> some View {
        Canvas(opaque: false) { context, canvasSize in
            var baseline = Path()
            baseline.addRect(
                CGRect(
                    x: 0, y: canvasSize.height - Metrics.hairline,
                    width: canvasSize.width, height: Metrics.hairline
                )
            )
            context.fill(baseline, with: .color(Palette.hairline))

            guard tickCellFraction > 0, tickCellFraction < 1 else { return }
            // Interior marks only: the two edges already carry the end-cap captions,
            // and a grid line sitting exactly under one of them would read as a
            // border rather than a rhythm mark.
            var lines = Path()
            var x = tickCellFraction
            while x < 1 - 0.0001 {
                let px = CGFloat(x) * canvasSize.width
                lines.addRect(
                    CGRect(
                        x: px, y: 0,
                        width: Metrics.EmberTape.gridLineWidth, height: canvasSize.height
                    )
                )
                x += tickCellFraction
            }
            context.fill(lines, with: .color(Palette.tick))
        }
    }

    // MARK: Bars

    @ViewBuilder
    private func barView(_ bar: Bar, totalWidth: CGFloat) -> some View {
        let width = max(CGFloat(bar.width) * totalWidth, Metrics.EmberTape.barMinWidth)
        let x = CGFloat(bar.start) * totalWidth

        Group {
            if bar.isSuspect {
                Capsule()
                    .strokeBorder(Palette.secondaryText, lineWidth: Metrics.EmberTape.suspectStrokeWidth)
            } else if bar.isLive {
                liveBar
            } else {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Palette.emberSlabTop, Palette.emberSlabBottom],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        }
        .frame(width: width, height: Metrics.EmberTape.barHeight)
        .offset(x: x)
    }

    /// HL-003 slice 4: the live bar's glow, breathing at the guided respiration
    /// cadence — swells over ~4 s, settles over ~6 s, roughly six breaths a
    /// minute (decision 0036 slice 4; the Nightstand identity's own numbers, the
    /// `motion` field of `docs/design/hushlight/design-directions.json`) — the
    /// brightening of the live mound doubling as a breath pacer with no
    /// "breathing feature" UI anywhere on screen. The asymmetry is the whole
    /// spec: a symmetric autoreverse (one duration, mirrored) cannot produce a
    /// 4/6 split, only a 5/5 one.
    ///
    /// Two stacked capsules rather than one animated shadow. The first attempt
    /// animated `.shadow(color:)` directly — `breathIsSwelled`'s doc comment has
    /// the measurement — and across a full breath cycle of on-device screenshots
    /// the rendered shadow never changed by a single pixel, at the spec's
    /// 0.30–0.60 swing or a deliberately exaggerated 0.05–0.98 one: whatever
    /// `phaseAnimator` was doing internally, it was not reaching the compositor
    /// here. `.opacity()` is: it is one of the handful of properties SwiftUI's
    /// implicit-animation system is guaranteed to interpolate, so the breath
    /// drives that instead. The **back** capsule carries the shadow, baked at
    /// `liveGlowOpacityHigh` — a fixed, pre-defined use of the existing
    /// `emberLive` token, never a runtime-mixed colour (decision 0034 §6) — and
    /// its own `.opacity()` is what swings, scaling the shadow's *effective*
    /// alpha down to exactly `liveGlowOpacityLow` at the low end (`low / high`
    /// is the fraction) and back up to exactly `high` at the top. The **front**
    /// capsule is a second, undimmed, un-shadowed `emberLive` fill in the same
    /// position: it is what a reader actually sees as "the bar", and it never
    /// dims, so only the halo — which blooms past the bar and so is never
    /// covered by that front layer — visibly breathes. The bar's own geometry
    /// (both capsules share `barView`'s `width`/`height`/`offset`) stays true to
    /// scale throughout (decision 0037 §4). Numerals elsewhere on the screen are
    /// untouched.
    private var liveBar: some View {
        ZStack {
            Capsule()
                .fill(Palette.emberLive)
                .shadow(
                    color: Palette.emberLive.opacity(Metrics.EmberTape.liveGlowOpacityHigh),
                    radius: Metrics.EmberTape.liveGlowRadius
                )
                .opacity(glowOpacityFraction)
            Capsule()
                .fill(Palette.emberLive)
        }
    }

    /// The multiplier `liveBar` applies to its shadow-casting back layer, chosen
    /// so the *effective* shadow opacity — `glowOpacityFraction *
    /// liveGlowOpacityHigh` — lands on exactly `liveGlowLow`, `-Mid`, or `-High`.
    /// Reduce Motion and `-uitesting` both hold at the mid fraction: stillness at
    /// the same brightness the breath swings around, not a gentler cycle — this
    /// codebase's stance under Reduce Motion — and the harness's screenshots
    /// stay pixel-identical seconds apart.
    private var glowOpacityFraction: Double {
        guard !reduceMotion, !RuntimeFlags.isUITesting else {
            return Metrics.EmberTape.liveGlowOpacityMid / Metrics.EmberTape.liveGlowOpacityHigh
        }
        let level = breathIsSwelled
            ? Metrics.EmberTape.liveGlowOpacityHigh
            : Metrics.EmberTape.liveGlowOpacityLow
        return level / Metrics.EmberTape.liveGlowOpacityHigh
    }
}

#if DEBUG
#Preview("EmberTape") {
    ComponentMatrix {
        VStack(alignment: .leading, spacing: Metrics.space5) {
            // Resting: an empty install, or a pattern that has entirely aged out of
            // the hour. Grid and baseline still stand — the axis is not data.
            EmberTape(
                bars: [],
                tickCellFraction: 1.0 / 12.0,
                leadingCaption: "1 H AGO",
                trailingCaption: "NOW",
                leadingCaptionSpoken: "one hour ago",
                trailingCaptionSpoken: "now",
                accessibilityLabel: "contractions in the last hour",
                accessibilityValue: "0"
            )

            // A textbook 5-1-1 rhythm: bars sitting inside each grid cell reads as an
            // even cadence with no caption needed.
            EmberTape(
                bars: (0..<11).map { i in
                    EmberTape.Bar(
                        start: Double(i) * (1.0 / 12.0),
                        width: 1.0 / 60.0,
                        isLive: false,
                        isSuspect: false
                    )
                },
                tickCellFraction: 1.0 / 12.0,
                leadingCaption: "1 H AGO",
                trailingCaption: "NOW",
                leadingCaptionSpoken: "one hour ago",
                trailingCaptionSpoken: "now",
                accessibilityLabel: "contractions in the last hour",
                accessibilityValue: "11"
            )

            // A young pattern: bars only near the right edge, the rest of the tape
            // honestly empty rather than stretched to fill it.
            EmberTape(
                bars: [
                    EmberTape.Bar(start: 0.83, width: 1.0 / 60.0, isLive: false, isSuspect: false),
                    EmberTape.Bar(start: 0.90, width: 1.0 / 60.0, isLive: false, isSuspect: false),
                    EmberTape.Bar(start: 0.96, width: 0.04, isLive: true, isSuspect: false)
                ],
                tickCellFraction: 1.0 / 12.0,
                leadingCaption: "1 H AGO",
                trailingCaption: "NOW",
                leadingCaptionSpoken: "one hour ago",
                trailingCaptionSpoken: "now",
                accessibilityLabel: "contractions in the last hour",
                accessibilityValue: "3"
            )

            // A suspect either side — a three-minute-plus outline dominating its
            // neighbours, and a slip at its visibility floor — beside a live bar's
            // glow at the right edge.
            EmberTape(
                bars: [
                    EmberTape.Bar(start: 0.10, width: 200.0 / 3600.0, isLive: false, isSuspect: true),
                    EmberTape.Bar(start: 0.40, width: 1.0 / 60.0, isLive: false, isSuspect: false),
                    EmberTape.Bar(start: 0.55, width: 1.0 / 370.0, isLive: false, isSuspect: true),
                    EmberTape.Bar(start: 0.94, width: 0.06, isLive: true, isSuspect: false)
                ],
                tickCellFraction: 1.0 / 12.0,
                leadingCaption: "1 H AGO",
                trailingCaption: "NOW",
                leadingCaptionSpoken: "one hour ago",
                trailingCaptionSpoken: "now",
                accessibilityLabel: "contractions in the last hour",
                accessibilityValue: "4"
            )
        }
    }
}
#endif
