import Foundation
@testable import Tessera
import Testing

/// G24: the bought word uses his day, which starts at 4 AM.
@MainActor
struct PantryDayWordTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles") ?? .current
        return calendar
    }

    private func at(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute)) ?? .now
    }

    @Test func aSmallHoursCheckBelongsToTheDayBefore() {
        // Sat Oct 17, 11:40 pm and Sun Oct 18, 1:20 am are both Saturday's shop; Wednesday reads "bought Sat".
        let wednesday = at(21, 12)
        #expect(PantryDayWord.bought(at(17, 23, 40), now: wednesday, calendar: calendar) == "bought Sat")
        #expect(PantryDayWord.bought(at(18, 1, 20), now: wednesday, calendar: calendar) == "bought Sat")
        #expect(PantryDayWord.bought(at(18, 4, 5), now: wednesday, calendar: calendar) == "bought Sun")
    }

    @Test func todayYesterdayAndOlder() {
        let now = at(21, 12)
        #expect(PantryDayWord.bought(at(21, 9), now: now, calendar: calendar) == "bought today")
        #expect(PantryDayWord.bought(at(21, 2), now: now, calendar: calendar) == "bought yesterday")
        #expect(PantryDayWord.bought(at(3, 10), now: now, calendar: calendar) == "bought Oct 3")
        #expect(PantryDayWord.spoken(at(17, 10), now: now, calendar: calendar) == "bought Saturday")
    }
}
