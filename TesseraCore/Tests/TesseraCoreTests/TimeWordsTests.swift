import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Research time-words-sweep (board 0q, decisions 12:35 PM PT Oct 16): one 12-hour house time, and his 4 am day
/// wherever a day is named.
struct TimeWordsTests {
    static let la = TimeZone(identifier: "America/Los_Angeles")!

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = la
        return calendar
    }

    static func at(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    @Test func oneTwelveHourTime() {
        // TW9 to TW18: he never reads a 24-hour time.
        #expect(HouseTime.clock(Self.at(16, 18, 30), calendar: Self.calendar) == "6:30 pm")
        #expect(HouseTime.clock(Self.at(16, 19), calendar: Self.calendar) == "7 pm")
        #expect(HouseTime.clock(Self.at(16, 0, 5), calendar: Self.calendar) == "12:05 am")
        #expect(HouseTime.clock(Self.at(16, 12), calendar: Self.calendar) == "12 pm")
    }

    @Test func memoryNamesHisDay() {
        // TW26: a cook at 12:30 am Oct 17 was on his Oct 16.
        let line = TessMemory.when(Self.at(17, 0, 30), now: Self.at(20, 12), calendar: Self.calendar)
        #expect(line == "on Oct 16")
    }

    @Test func aTimeTessPicksNeverLandsInQuietHours() {
        // Product 0ab: "call mom thu" typed at 1 am Friday (his Thursday) lands at 7 am, not 2 am.
        let (date, _) = TessDates.extract(from: ["call", "mom", "thu"], now: Self.at(16, 1), calendar: Self.calendar)
        #expect(date == Self.at(16, 7))
        // "today" said at 23:10 would be midnight: 7 am instead.
        let (late, _) = TessDates.extract(from: ["call", "mom", "today"], now: Self.at(15, 23, 10),
                                          calendar: Self.calendar)
        #expect(late == Self.at(16, 7))
        // A time he says himself is kept.
        let (said, _) = TessDates.extract(from: ["call", "mom", "thu", "at", "1am"], now: Self.at(14, 12),
                                          calendar: Self.calendar)
        #expect(said == Self.at(15, 1))
    }

    @Test func aWeekdayCountsFromHisDay() throws {
        // TW29: "thu" said at 1 am Friday (still his Thursday, Oct 15) is today, not next week.
        let (date, _) = TessDates.extract(from: ["call", "mom", "thu"], now: Self.at(16, 1), calendar: Self.calendar)
        let found = try #require(date)
        #expect(found < Self.at(16, 12) && found > Self.at(16, 1))
        // Said on Friday afternoon, "thu" is next Thursday.
        let (next, _) = TessDates.extract(from: ["call", "mom", "thu"], now: Self.at(16, 15), calendar: Self.calendar)
        #expect(try #require(next) > Self.at(21, 0))
    }
}
