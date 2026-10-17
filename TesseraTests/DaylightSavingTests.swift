import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// docs/research/fixtures/dst-nov-1.md DS18 and DS35: Los Angeles, the night clocks fall back (Nov 1, 2026).
@MainActor
struct DaylightSavingTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        calendar.locale = Locale(identifier: "en_US")
        return calendar
    }

    private func utc(_ iso: String) -> Date {
        ISO8601DateFormatter().date(from: iso)!
    }

    /// DS18: a session from 12:50 am PDT, past the second-pass 1 am hour, files under Saturday and says so.
    @Test func finishLineNamesSaturdayAcrossTheChange() {
        let line = WorkoutFinishView.dayLine(startedAt: utc("2026-11-01T07:50:00Z"),
                                             endedAt: utc("2026-11-01T09:10:00Z"), calendar: calendar)
        #expect(line == "Saturday, 12:50 am to 1:10 am")
        let late = WorkoutFinishView.dayLine(startedAt: utc("2026-11-01T07:50:00Z"),
                                             endedAt: utc("2026-11-01T10:10:00Z"), calendar: calendar)
        #expect(late == "Saturday, 12:50 am to 2:10 am")
    }

    /// DS35: Sun 6 pm PDT to the next Sun 6 pm PST is 7 days, not 7 d 1 h rounded up to 8.
    @Test func trendSameClockOneWeekIsSevenDays() throws {
        let first = utc("2026-10-26T01:00:00Z")
        let now = utc("2026-11-02T02:00:00Z")
        let trend = try #require(ExerciseDigest.trend([(first, 100), (now, 105)], now: now, calendar: calendar))
        #expect(trend.span == "7 days")
    }

    @Test func trendWithinOneDayIsOneDay() throws {
        let first = utc("2026-11-01T08:00:00Z")
        let now = utc("2026-11-01T10:30:00Z")
        let trend = try #require(ExerciseDigest.trend([(first, 100)], now: now, calendar: calendar))
        #expect(trend.span == "1 day")
    }
}
