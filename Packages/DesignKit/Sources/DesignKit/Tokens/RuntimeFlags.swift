import Foundation
import SwiftUI

/// Launch-argument switches that change runtime behaviour for automation.
public enum RuntimeFlags {
    /// Set by the UI test target. Anything that redraws on a timer must go quiet under
    /// it: a `TimelineView` ticking once a second keeps the accessibility tree in
    /// permanent flux, and `performAccessibilityAudit` times out waiting for it to
    /// settle rather than reporting anything. Train's rest countdown did exactly that.
    public static let isUITesting = ProcessInfo.processInfo.arguments.contains("-uitesting")
}

extension TimelineSchedule where Self == PeriodicTimelineSchedule {
    /// A one-second tick that stands still under UI testing. The condition lives in the
    /// parameters rather than the type so both branches stay a `PeriodicTimelineSchedule`
    /// — SwiftUI has no type-erased schedule to return instead.
    public static var secondly: PeriodicTimelineSchedule {
        secondly(from: .now)
    }

    /// Anchored variant, for countdowns that measure against a fixed start.
    ///
    /// The still branch keeps `date` as its anchor and only stretches the interval.
    /// It used to anchor at `.distantFuture`, which does hold the tree still — but a
    /// periodic schedule snaps to its anchor's grid, and the first entry on
    /// `.distantFuture`'s hourly grid at or after now is *the next whole UTC hour*. So
    /// every frozen screen rendered with a clock up to an hour in the future. Nothing
    /// caught it because the accessibility audit only asks whether the tree settles.
    /// SP-193's simulator pass asks what the numbers say, and found a seeded 1 h 10 m
    /// labor reading "1 H 55 M" — with `sustainedMet` satisfied by the drift rather
    /// than by the body. Anchoring at `date` costs the freeze nothing and makes the
    /// frozen clock the real one.
    public static func secondly(from date: Date) -> PeriodicTimelineSchedule {
        RuntimeFlags.isUITesting
            ? .periodic(from: date, by: 3_600)
            : .periodic(from: date, by: 1)
    }
}
