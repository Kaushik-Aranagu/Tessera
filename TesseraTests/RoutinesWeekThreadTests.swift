import Foundation
@testable import Tessera
import Testing

/// Week thread v2 (feature 168): which of the seven days had a run.
struct RoutinesWeekThreadTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }

    private func date(_ day: Int, _ hour: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: 0)) ?? .now
    }

    @Test func sevenDaysEndingTodayOldestFirst() {
        let days = RoutinesWeekThreadData.days(runs: [], now: date(22, 12), calendar: calendar)
        #expect(days.count == 7)
        #expect(days.last?.date == calendar.startOfDay(for: date(22, 12)))
        #expect(days.first?.date == calendar.startOfDay(for: date(16, 12)))
        #expect(!RoutinesWeekThreadData.hasThread(days))
    }

    @Test func aDayRanWhenAnyRunStartedOnIt() {
        let runs = [date(22, 7), date(20, 9), date(20, 21), date(10, 8)]
        let days = RoutinesWeekThreadData.days(runs: runs, now: date(22, 12), calendar: calendar)
        #expect(days.map(\.ran) == [false, false, false, false, true, false, true])
        #expect(RoutinesWeekThreadData.hasThread(days))
    }

    @Test func aRunBeforeFourBelongsToTheDayBefore() {
        let days = RoutinesWeekThreadData.days(runs: [date(21, 2)], now: date(22, 12), calendar: calendar)
        #expect(days.map(\.ran) == [false, false, false, false, true, false, false])
    }

    @Test func spokenNamesOnlyTheDaysThatRan() {
        let days = RoutinesWeekThreadData.days(runs: [date(22, 7), date(20, 9)], now: date(22, 12), calendar: calendar)
        let spoken = RoutinesWeekThreadData.spoken(days, calendar: calendar)
        #expect(spoken == "Ran on Tuesday and Thursday")
        for word in ["miss", "streak", "gap", "red"] {
            #expect(!spoken.lowercased().contains(word))
        }
    }
}
