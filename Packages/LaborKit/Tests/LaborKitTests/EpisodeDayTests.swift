import Foundation
import Testing
@testable import LaborKit

/// SP-214: the pure day-word decision behind the timer header's "SINCE" clause and
/// History's midnight markers. `EpisodeDay` is the only piece of this item that can
/// be package-tested — `LaborFormat` is app-target with no test bundle (SP-042a).
@Suite("Episode day")
struct EpisodeDayTests {
    /// A fixed calendar/timezone so every test is independent of the machine
    /// running it — the whole reason this decision moved out of `LaborFormat`.
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)!
    }

    @Test func sameCalendarDayReadsAsToday() {
        let now = date(2026, 8, 24, 4, 0)
        let start = date(2026, 8, 24, 17, 13)
        // `start` is later in the day than `now` here on purpose: the header can
        // render for an episode that started earlier *tonight*, and "today" must
        // hold regardless of which side of `now` the clock time falls on.
        #expect(EpisodeDay.describe(start: start, now: now, calendar: calendar) == .today)
    }

    @Test func lateNightAndEarlyMorningOnTheSameDayIsStillToday() {
        let now = date(2026, 8, 24, 23, 55)
        let start = date(2026, 8, 24, 0, 5)
        #expect(EpisodeDay.describe(start: start, now: now, calendar: calendar) == .today)
    }

    @Test func theCalendarDayBeforeReadsAsYesterday() {
        let now = date(2026, 8, 24, 4, 0)
        let start = date(2026, 8, 23, 23, 40)
        #expect(EpisodeDay.describe(start: start, now: now, calendar: calendar) == .yesterday)
    }

    /// A minute either side of midnight is still a full calendar day apart —
    /// exactly the DemoSeed `-seedLaborMidnight` shape.
    @Test func justAfterMidnightAgainstJustBeforeIsYesterday() {
        let now = date(2026, 8, 24, 0, 10)
        let start = date(2026, 8, 23, 23, 50)
        #expect(EpisodeDay.describe(start: start, now: now, calendar: calendar) == .yesterday)
    }

    @Test func twoCalendarDaysBackReadsAsOlder() {
        let now = date(2026, 8, 24, 4, 0)
        let start = date(2026, 8, 22, 17, 13)
        #expect(EpisodeDay.describe(start: start, now: now, calendar: calendar) == .older)
    }

    /// A year boundary is still just one calendar day, by this measure — the
    /// comparison is on the day, not the year.
    @Test func aYearBoundaryIsStillJustYesterday() {
        let now = date(2027, 1, 1, 0, 30)
        let start = date(2026, 12, 31, 23, 50)
        #expect(EpisodeDay.describe(start: start, now: now, calendar: calendar) == .yesterday)
    }

    /// Two days back across the same year boundary reads as `.older`, the same as
    /// any other two-day gap.
    @Test func twoDaysBackAcrossAYearBoundaryReadsAsOlder() {
        let now = date(2027, 1, 1, 4, 0)
        let start = date(2026, 12, 30, 17, 13)
        #expect(EpisodeDay.describe(start: start, now: now, calendar: calendar) == .older)
    }

    /// A clock set backwards past `now` (F-0011's family of findings) is not a
    /// crash — it is simply not `.today` or `.yesterday`, and `.older` is the
    /// honest fallback rather than a trapped precondition.
    @Test func aStartAfterNowIsNeitherTodayNorYesterday() {
        let now = date(2026, 8, 24, 4, 0)
        let start = date(2026, 8, 26, 17, 13)
        #expect(EpisodeDay.describe(start: start, now: now, calendar: calendar) == .older)
    }
}
