import Foundation

/// SP-215, decision 0029 §1: whether a stale episode reads as **concluded** rather
/// than merely paused — the line the timer screen's quiet recap waits behind before
/// it acknowledges the stretch is over.
///
/// The predicate is pure, dates in and a bool out, the same shape `ReviewPrompt`
/// already takes for the same reason: every guard is a table-driven test rather
/// than a claim held in a comment.
public enum EpisodeClosure {
    /// Three days clear of `PatternAnalysis.episodeGap` — the floor an episode
    /// already has to clear to stop reading as *live* (the 2 h gap `rawPattern`
    /// applies before the readout goes quiet at all). That boundary answers "is
    /// this pattern still moving"; this one answers "does the stretch read as
    /// over." Early labor genuinely pauses for hours — sometimes the better part
    /// of a day — and resumes as the same stretch, and decision 0029 forbids the
    /// app from ever guessing at that resumption, so the recap has to outlast any
    /// realistic pause before it acknowledges closure. Three days is comfortably
    /// past the longest prodromal gap this app's own guideline rules were written
    /// for, and it is the minimum the item calls for: a longer wait only costs how
    /// soon a clearly finished night gets its quiet acknowledgment, never a false
    /// one.
    ///
    /// `episodeGap` is two hours; three days is ~36× that, which is the "floor"
    /// this threshold is built past — a record old enough to clear it has already
    /// cleared `rawPattern`'s own staleness gate many times over, so `isConcluded`
    /// below never has to re-check liveness against the gap itself, only against
    /// `isRunning`.
    public static let recapThreshold: Duration = .seconds(3 * 24 * 60 * 60)

    /// Whether the timer screen should show SP-215's recap in place of the shorter
    /// "last contraction ended … ago" line: nothing running, a newest-ended record
    /// on hand, and that record at least `recapThreshold` old.
    ///
    /// Reads the same `lastEndedAt` instant the header's own staleness clause and
    /// the timer screen's returning-reader copy already date from (F-0012: one
    /// instant, however many surfaces ask about it), so this can never disagree
    /// with what "LAST … AGO" on screen already says. `isRunning` is checked
    /// first and separately from `lastEndedAt`'s presence — a running episode can
    /// have no ended record at all (the very first contraction, still open), and
    /// that must read as "not concluded" for the obvious reason, not merely as
    /// "no evidence either way."
    public static func isConcluded(lastEndedAt: Date?, isRunning: Bool, now: Date) -> Bool {
        guard !isRunning, let lastEndedAt else { return false }
        return Duration.seconds(now.timeIntervalSince(lastEndedAt)) >= recapThreshold
    }
}
