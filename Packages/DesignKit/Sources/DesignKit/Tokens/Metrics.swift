import SwiftUI

/// Spacing, radii, and the geometry of the signature gauge. CSS px from the
/// handoff translate to pt 1:1 (spec §5).
public enum Metrics {
    // MARK: Spacing — 4-pt grid

    public static let space1: CGFloat = 4
    public static let space2: CGFloat = 8
    public static let space3: CGFloat = 12
    public static let space4: CGFloat = 16
    public static let space5: CGFloat = 20
    public static let space6: CGFloat = 24

    /// Standard screen inset.
    public static let screenMargin: CGFloat = 20

    // MARK: Radii

    /// Primary CTAs and text inputs.
    public static let ctaRadius: CGFloat = 14
    /// The identity's continuous-corner radius for the primary slab (HL-003 slice 1)
    /// — the full-width bottom control that replaced the circle. A token rather than
    /// a literal at the call site because the identity's 24 pt card radius
    /// (`docs/design/hushlight/`, `Palette.raised`'s reserved surfaces) will want a
    /// sibling here once a later item draws a card in it.
    public static let slabRadius: CGFloat = 28

    // MARK: Rules

    /// Hairline rules. Deliberately 0.5 pt, not `1 / displayScale` — the design
    /// calls for a consistent hairline across devices.
    public static let hairline: CGFloat = 0.5

    // MARK: Hit targets

    /// Minimum tappable dimension, per HIG.
    public static let minimumTapTarget: CGFloat = 44

    // MARK: The ember tape (decision 0037)

    /// The app's signature gauge — never rings or donuts (spec §3). `TickTapeGauge`'s
    /// derived-fill tape retired with HL-003 slice 2; `EmberTape` draws the raw record
    /// its progress bar used to summarize, and these are its geometry.
    public enum EmberTape {
        /// The whole canvas's height — the grid's full extent, and room above the
        /// bars for the live glow to bloom into without being clipped.
        public static let barRegionHeight: CGFloat = 44
        /// A bar's own height. Shorter than `barRegionHeight` on purpose, so the bars
        /// visibly rise *from* the baseline rather than filling the canvas — the grid
        /// remains legible above them.
        public static let barHeight: CGFloat = 32
        /// Minimum drawn bar width in points. `PatternAnalysis.tapeSlipWidthFloor`
        /// already floors a slip's *fraction* of the window; this is the belt to that
        /// suspenders — a safety floor in the unit DesignKit actually draws in, so a
        /// bar can never round away to nothing at a tape width the geometry layer
        /// didn't anticipate.
        public static let barMinWidth: CGFloat = 1.5
        /// Suspect bars draw as an outline, never a fill (decision 0037 §5) — texture,
        /// not colour, the discipline `EpisodeTimeline`'s CHECK flags already keep.
        public static let suspectStrokeWidth: CGFloat = 1.5
        /// The grid's line thickness. Full width, always — the axis, not data
        /// (decision 0037 §3).
        public static let gridLineWidth: CGFloat = 1
        /// Gap between the bar region and the end-cap captions below it.
        public static let captionGap: CGFloat = 8
        /// The live bar's glow radius — blooms past the bar; the bar geometry
        /// (`TapeBar.width`) stays true to scale regardless (decision 0037 §4).
        public static let liveGlowRadius: CGFloat = 10
        /// HL-003 slice 4: the breath-paced glow's two swing levels and the still
        /// point exactly between them. Only *opacity* on the existing `emberLive`
        /// token moves (decision 0034 §6 bans a runtime-mixed colour) — the radius
        /// above stays fixed, so the bloom's reach never changes, only its warmth.
        /// `liveGlowOpacityMid` is what this shadow drew, unconditionally, before
        /// this slice; keeping the swing centred on it means Reduce Motion and
        /// `-uitesting` freeze the glow at exactly the brightness it always had.
        public static let liveGlowOpacityLow: Double = 0.30
        public static let liveGlowOpacityHigh: Double = 0.60
        public static let liveGlowOpacityMid: Double = (liveGlowOpacityLow + liveGlowOpacityHigh) / 2
    }

    // MARK: Motion

    /// Press feedback scale. Swapped for an opacity change under Reduce Motion.
    public static let pressedScale: CGFloat = 0.96
    public static let pressedOpacity: Double = 0.7
}
