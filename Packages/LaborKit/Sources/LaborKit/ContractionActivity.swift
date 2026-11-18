// `os(iOS)`, not `canImport(ActivityKit)`, and the difference is not cosmetic: this
// guard and its siblings in `StartStopContractionIntent` and LaborSim's sentinel were
// written as `canImport` and **gated nothing**. ActivityKit imports perfectly well on
// macOS — every symbol in it is merely marked unavailable there — so the condition was
// always true and the guard was decorative. Measured under HL-041, which built this
// package for macOS and got 19 unavailability errors straight through the `#if`.
//
// The module is still not macOS-buildable and deliberately is not (decision 0056):
// `LaborModel`'s Live Activity reconciliation is ungated, because there is no second
// platform to build for. These guards are correct in form rather than load-bearing.
#if os(iOS)
import ActivityKit
import Foundation

/// The Live Activity's contract — lives here so the app (which starts and updates
/// the activity) and the widget extension (which renders it) share one definition.
///
/// The content is deliberately small and self-updating: `startedAt` drives a
/// `Text(timerInterval:)` on the lock screen, so the elapsed count ticks without a
/// single content update or process wake. Updates happen only on taps and episode
/// changes — a labor can run for hours without draining anything.
public struct ContractionActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        /// Nil when no contraction is running — the button reads "Start".
        public var runningSince: Date?

        /// Figures for the idle state, mirroring the app's evidence rules: nil
        /// below the floor, and the lock screen prints an em dash, not a zero.
        ///
        /// The average leads and the last gap is its fallback (SP-213): the idle
        /// lock screen is the surface read during the drive in, and answering
        /// "how far apart?" with one pair's gap hands triage an outlier. The same
        /// figure the app's own INTERVAL column leads with, under the same floor —
        /// nil below three contractions, exactly as `PatternAnalysis` withholds it.
        public var averageIntervalSeconds: Int?
        public var lastIntervalSeconds: Int?
        public var contractionCount: Int

        public init(
            runningSince: Date? = nil,
            averageIntervalSeconds: Int? = nil,
            lastIntervalSeconds: Int? = nil,
            contractionCount: Int = 0
        ) {
            self.runningSince = runningSince
            self.averageIntervalSeconds = averageIntervalSeconds
            self.lastIntervalSeconds = lastIntervalSeconds
            self.contractionCount = contractionCount
        }
    }

    /// When this activity was requested — static for its whole life, which is what
    /// makes it the right shape for an attribute rather than content. ActivityKit
    /// ends an activity eight hours after it starts and tells nobody; without its own
    /// birth time the app cannot know how close to that ceiling it is, and so cannot
    /// replace it while it still has the chance (decision 0028).
    public var startedAt: Date

    public init(startedAt: Date = Date()) {
        self.startedAt = startedAt
    }

    /// Six hours, against ActivityKit's eight — a wide enough margin that a
    /// foreground (or a lock-screen tap) shortly before the ceiling still replaces
    /// rather than races it, and long enough that ordinary short sessions are never
    /// churned. Moved here from `LaborModel` by SP-205, because a constant private
    /// to one caller is how the other caller shipped without the check.
    public static let rearmAge: TimeInterval = 6 * 60 * 60

    /// **The rearm decision, in one place** (SP-205, completing decision 0028).
    /// The app-foreground path has asked this since SP-186; the lock-screen intent
    /// did not, and a woman timing entirely from the lock screen — the promised
    /// workflow — silently lost the button at the eight-hour kill. Both callers now
    /// read this predicate, so they cannot drift apart (the F-0002 lesson, again).
    public func needsReplacement(now: Date = Date()) -> Bool {
        now.timeIntervalSince(startedAt) > Self.rearmAge
    }
}

extension ActivityState {
    /// One definition of "present on the lock screen" (decision 0028). ActivityKit
    /// keeps an activity in its static list after it has ended — the system's own
    /// eight-hour termination included — for as long as four hours before
    /// dismissal, and code that counted those took update branches onto dead
    /// activities. `.active` and `.stale` are the only states that count; every
    /// surface that asks the question reads this one predicate so they cannot
    /// drift apart (the F-0002 lesson, applied here).
    public var countsAsPresent: Bool {
        self == .active || self == .stale
    }
}

extension ContractionActivityAttributes.ContentState {
    /// The one mapping from the analysis to the lock screen, kept pure so the
    /// package tests can pin it: running state wins; otherwise the idle figures,
    /// honouring the same minimum-evidence rules as the app's readout.
    public static func from(_ pattern: LaborPattern) -> Self {
        Self(
            runningSince: pattern.running?.startedAt,
            averageIntervalSeconds: pattern.averageInterval.map { Int($0.components.seconds) },
            lastIntervalSeconds: pattern.lastInterval.map { Int($0.components.seconds) },
            contractionCount: pattern.episode.count
        )
    }
}
#endif
