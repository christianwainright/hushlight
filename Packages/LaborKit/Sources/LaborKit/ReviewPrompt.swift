import Foundation

/// When the app may ask the system for a rating (SP-216, decision 0029 §2), decided
/// by a pure predicate: dates in, bool out, so every guard is a table-driven test
/// rather than a claim.
///
/// The stance behind the guards: this app is used during one of the more charged
/// weeks of a person's life, and a rating sheet is the wrong thing to meet in it.
/// The prompt exists only at the calm — no contraction running, nothing recorded or
/// cleared for a week on either measure, past the first day — and only once per
/// install. The system's own throttle sits on top of ours; we count our attempt
/// regardless of whether the sheet actually appeared, because "we asked" is the fact
/// this predicate owns, and the OS keeps its own counsel about showing.
public enum ReviewPrompt {
    /// One attempt per install. Named once, like every defaults key here.
    public static let attemptedKey = "reviewPromptAttempted"
    /// Set on the app's first run, read only by this predicate.
    public static let firstLaunchKey = "firstLaunchDate"
    /// Stamped by the clear-all path: the record ending is exactly the moment the
    /// item calls "closure", and a rating sheet adjacent to it is the app asking
    /// "how was it?" at the worst imaginable time.
    public static let lastClearAllKey = "lastClearAllDate"

    /// The quiet window: no episode activity and no clear-all within it, on either
    /// side of tonight. Seven days keeps the prompt clear of the whole perinatal
    /// stretch a recent episode implies.
    public static let quietInterval: TimeInterval = 7 * 24 * 60 * 60
    /// "Not first launch," made concrete: at least one full day old.
    public static let minimumAge: TimeInterval = 24 * 60 * 60

    /// The one decision, pure. Every date is optional because absence means
    /// something different per guard: an unknown first launch reads as *first
    /// launch* (ineligible — age unproven is age zero), while an absent episode or
    /// clear-all date reads as *never happened* (no bar to asking).
    public static func isEligible(
        now: Date,
        firstLaunch: Date?,
        newestRecordEnd: Date?,
        isRunning: Bool,
        lastClearAll: Date?,
        alreadyAttempted: Bool
    ) -> Bool {
        guard !alreadyAttempted else { return false }
        guard !isRunning else { return false }
        guard let firstLaunch, now.timeIntervalSince(firstLaunch) >= minimumAge else {
            return false
        }
        if let newestRecordEnd, now.timeIntervalSince(newestRecordEnd) < quietInterval {
            return false
        }
        if let lastClearAll, now.timeIntervalSince(lastClearAll) < quietInterval {
            return false
        }
        return true
    }
}
