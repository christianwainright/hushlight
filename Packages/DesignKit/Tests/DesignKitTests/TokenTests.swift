import SwiftUI
import Testing
@testable import DesignKit

/// Guards the token layer's shape. The visual gates live in DESIGN-SPEC §8 and are
/// checked on the simulator; these catch structural drift a screenshot wouldn't show.
@Suite("Design tokens")
struct TokenTests {
    @Test func displayRolesShrinkToFit() {
        #expect(DataTextRole.hero.isHero)
        #expect(DataTextRole.distance.isHero)
        #expect(!DataTextRole.stat.isHero)
        #expect(!DataTextRole.row.isHero)
        #expect(!DataTextRole.label.isHero)
    }

    /// The identity's split by scale (decision 0034): the instrument is rounded, the
    /// table is truly monospaced. Asserted because it is a design rule that a single
    /// convenient `.rounded` on a history row would quietly undo.
    @Test func theInstrumentIsRoundedAndTheTableIsMonospaced() {
        #expect(DataTextRole.hero.design == .rounded)
        #expect(DataTextRole.distance.design == .rounded)
        #expect(DataTextRole.stat.design == .rounded)
        #expect(DataTextRole.row.design == .monospaced)
        #expect(DataTextRole.label.design == .monospaced)
    }

    @Test func onlySectionLabelsCarryTracking() {
        #expect(DataTextRole.label.tracking == 1)
        #expect(DataTextRole.hero.tracking == 0)
    }

    @Test func spacingFollowsTheFourPointGrid() {
        let grid: [CGFloat] = [
            Metrics.space1, Metrics.space2, Metrics.space3,
            Metrics.space4, Metrics.space5, Metrics.space6
        ]
        #expect(grid == [4, 8, 12, 16, 20, 24])
    }

    /// The gauge is the app's signature element; its geometry is spec'd in §3.
    /// `TickTapeGauge`'s tokens retired with HL-003 slice 2 (decision 0037) — this
    /// pins `EmberTape`'s in the shape that replaced them.
    @Test func emberTapeGeometryMatchesTheSpec() {
        #expect(Metrics.EmberTape.barHeight < Metrics.EmberTape.barRegionHeight)
        #expect(Metrics.EmberTape.gridLineWidth == 1)
        #expect(Metrics.EmberTape.barMinWidth > 0)
    }

    /// HL-058: the stand's figure is the hero further away — larger, and otherwise
    /// the same instrument. A role that drifted in face, weight or scaling curve
    /// would be a second numeral, and the two are shown in the same place.
    @Test func distanceIsTheHeroFurtherAway() {
        #expect(DataTextRole.distance.size > DataTextRole.hero.size)
        #expect(DataTextRole.distance.weight == DataTextRole.hero.weight)
        #expect(DataTextRole.distance.relativeTo == DataTextRole.hero.relativeTo)
        #expect(DataTextRole.distance.matchingTextStyle == nil)
    }
}
