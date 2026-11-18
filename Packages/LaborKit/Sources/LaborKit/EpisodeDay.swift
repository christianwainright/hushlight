import Foundation

/// Which calendar day an episode's start reads as, relative to the reader's current
/// clock — the pure decision behind the timer header's "SINCE" clause (SP-214,
/// decision 0022 §3). `LaborFormat`, app-side and untested per SP-042a, turns this
/// into mono-caps ("SINCE YESTERDAY 5:13 PM") or spoken words ("since yesterday at
/// 5:13 PM"); this type only decides *which* word applies, so that decision — the
/// part with edge cases worth pinning — can live in LaborKitTests instead of
/// ceremony-free but unverifiable app code.
public enum EpisodeDay: Equatable, Sendable {
    /// `start` falls on the same calendar day as `now`. The common case, and the
    /// header adds no word for it — the whole point of dating the exceptions rather
    /// than the rule.
    case today
    /// `start` falls on the calendar day immediately before `now`'s.
    case yesterday
    /// Two or more calendar days back — or, in principle, after `now` (a device
    /// clock correction). Rendered as the weekday name.
    case older

    /// `now` is the reader's current moment, not a value cached from when the
    /// episode began — the same live clock the header already renders against
    /// every second. Comparison is by calendar day, not by a fixed 86,400-second
    /// window: a calendar day can be 23 or 25 hours across a DST transition, and
    /// "yesterday" as "24 hours ago" would misdate an episode that started shortly
    /// before a spring-forward midnight.
    ///
    /// **Timezone changes mid-episode.** `calendar` defaults to `.current`, read at
    /// call time. If the device's timezone changes while an episode is open (a
    /// flight, a manual correction), a header rendered again after the change is
    /// classified against *that* new reading, not whatever the calendar said when
    /// the episode started — deliberately: there is one honest answer to "which day
    /// is it", and it is the one on the reader's device right now, not a frozen
    /// snapshot from hours ago. This is the same trade `isDateInToday`/
    /// `isDateInYesterday` make implicitly (they always compare against the device's
    /// live "now"); this function makes the same comparison explicit and
    /// parametrized so it can be pinned in a test.
    public static func describe(start: Date, now: Date, calendar: Calendar = .current) -> EpisodeDay {
        if calendar.isDate(start, inSameDayAs: now) { return .today }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(start, inSameDayAs: yesterday) {
            return .yesterday
        }
        return .older
    }
}
