import Foundation
@testable import TesseraCore
import Testing

/// docs/research/day-boundary.md §4, X1 to X12: Los Angeles, en_US (week starts Sunday).
struct TesseraDayTests {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        calendar.locale = Locale(identifier: "en_US")
        return calendar
    }()

    static func at(_ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0, _ second: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute,
                                           second: second))!
    }

    static func key(_ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day))!
    }

    struct Row: Sendable, CustomTestStringConvertible {
        let name: String
        let moment: Date
        let day: Date
        var testDescription: String {
            name
        }
    }

    static let rows: [Row] = [
        Row(name: "X1 Sat 00:00:00", moment: at(10, 17, 0), day: key(10, 16)),
        Row(name: "X2 Sat 00:40", moment: at(10, 17, 0, 40), day: key(10, 16)),
        Row(name: "X3 Sat 01:00", moment: at(10, 17, 1), day: key(10, 16)),
        Row(name: "X5 Sat 02:15", moment: at(10, 17, 2, 15), day: key(10, 16)),
        Row(name: "X6 Sat 03:59:59", moment: at(10, 17, 3, 59, 59), day: key(10, 16)),
        Row(name: "X7 Sat 04:00", moment: at(10, 17, 4), day: key(10, 17)),
        Row(name: "X8 Sun 00:30", moment: at(10, 18, 0, 30), day: key(10, 17)),
        // 1 Nov: 01:30 happens twice (PDT, then PST); both are Saturday. 03:30 PST is still Saturday.
        Row(name: "X9 first 01:30", moment: Date(timeIntervalSince1970: 1_793_521_800), day: key(10, 31)),
        Row(name: "X10 second 01:30", moment: Date(timeIntervalSince1970: 1_793_525_400), day: key(10, 31)),
        Row(name: "X11 Sun 03:30 PST", moment: at(11, 1, 3, 30), day: key(10, 31)),
        Row(name: "X12 Sun 04:00 PST", moment: at(11, 1, 4), day: key(11, 1)),
    ]

    @Test(arguments: rows) func dayOf(_ row: Row) {
        let tessera = TesseraDay(calendar: Self.calendar)
        #expect(tessera.day(of: row.moment) == row.day)
        #expect(tessera.interval(of: row.moment).contains(row.moment))
    }

    @Test func intervalsAreWallClockAcrossDST() {
        let tessera = TesseraDay(calendar: Self.calendar)
        let saturday = tessera.interval(of: Self.at(10, 31, 12))
        #expect(saturday.duration == 25 * 3600) // 04:00 PDT to 04:00 PST
        #expect(tessera.interval(of: Self.at(11, 2, 12)).duration == 24 * 3600)
        #expect(tessera.start(of: Self.at(10, 17, 1)) == Self.at(10, 16, 4))
        #expect(tessera.end(of: Self.at(10, 17, 1)) == Self.at(10, 17, 4))
        #expect(tessera.isSameDay(Self.at(10, 16, 22, 50), Self.at(10, 17, 0, 40)))
        #expect(!tessera.isSameDay(Self.at(10, 17, 3, 59), Self.at(10, 17, 4)))
    }

    @Test func aWeekEndsAtFourOnSunday() {
        let tessera = TesseraDay(calendar: Self.calendar)
        // A session Sat 23:30 to Sun 00:20 stays in the week of 11 to 17 Oct (X8).
        let week = tessera.week(containing: Self.at(10, 18, 0, 20))
        #expect(week.start == Self.at(10, 11, 4) && week.end == Self.at(10, 18, 4))
        #expect(tessera.weekDays(containing: Self.at(10, 18, 0, 20)).first == Self.key(10, 11))
    }

    @Test func springForwardIsRightToo() throws {
        // 14 Mar 2027: clocks jump 02:00 to 03:00. 03:30 is still Saturday 13; 04:30 is Sunday 14 (the old minus-4-h
        // rule said Saturday until 05:00). The day is 23 h long.
        let tessera = TesseraDay(calendar: Self.calendar)
        let saturday = try #require(Self.calendar.date(from: DateComponents(year: 2027, month: 3, day: 13)))
        let sunday = try #require(Self.calendar.date(from: DateComponents(year: 2027, month: 3, day: 14)))
        let at0330 = try #require(Self.calendar.date(from: DateComponents(
            year: 2027,
            month: 3,
            day: 14,
            hour: 3,
            minute: 30
        )))
        let at0430 = try #require(Self.calendar.date(from: DateComponents(
            year: 2027,
            month: 3,
            day: 14,
            hour: 4,
            minute: 30
        )))
        #expect(tessera.day(of: at0330) == saturday && tessera.day(of: at0430) == sunday)
        #expect(RollForwardTasks.logicalDay(of: at0430, calendar: Self.calendar) == sunday)
        #expect(try tessera.interval(of: #require(Self.calendar.date(byAdding: .hour, value: 12, to: saturday)))
            .duration
            == 23 * 3600)
    }

    @Test func theRollForwardUsesTheSameRule() {
        #expect(RollForwardTasks.logicalDay(of: Self.at(11, 1, 3, 30), calendar: Self.calendar) == Self.key(10, 31))
    }
}
