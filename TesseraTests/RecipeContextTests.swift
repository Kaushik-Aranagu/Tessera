import Foundation
@testable import Tessera
import Testing

/// G57 and G60 (K87.7, K87.10): the drum fits the written size; the context line says hours and minutes and a
/// readable "cooked" age; a cook from another year carries its year.
@MainActor
struct RecipeContextTests {
    @Test func theDrumRunsToTwiceTheWrittenSizeNeverUnder12() {
        #expect(PortionDrum.range(written: 24) == 1 ... 48)
        #expect(PortionDrum.range(written: 14) == 1 ... 28)
        #expect(PortionDrum.range(written: 2) == 1 ... 12)
        #expect(PortionDrum.range(written: nil) == 1 ... 12)
        #expect(PortionDrum.range(written: 5000) == 1 ... 48)
    }

    @Test func durationsAreHoursAndMinutes() {
        #expect(RecipeCopy.duration(95) == "1 h 35 min")
        #expect(RecipeCopy.duration(100) == "1 h 40 min")
        #expect(RecipeCopy.duration(150) == "2 h 30 min")
        #expect(RecipeCopy.duration(60) == "1 h")
        #expect(RecipeCopy.duration(45) == "45 min")
    }

    @Test func cookedAgesReadAsPeopleSayThem() {
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        func ago(_ days: Double) -> String {
            RecipeCopy.relative(now.addingTimeInterval(-days * 86400), now: now)
        }
        #expect(ago(3) == "3 days ago")
        #expect(ago(40) == "40 days ago")
        #expect(ago(94) == "3 months ago")
        #expect(ago(400) == "last year")
    }

    @Test func aCookFromAnotherYearCarriesItsYearAndTheHouseClock() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 17, hour: 12)))
        let thisYear = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 10,
            day: 14,
            hour: 9,
            minute: 5
        )))
        let lastYear = try #require(calendar.date(from: DateComponents(year: 2025, month: 10, day: 14, hour: 21)))
        #expect(RecipeCopy.cookDay(thisYear, now: now, calendar: calendar).hasSuffix(", 9:05 am"))
        #expect(!RecipeCopy.cookDay(thisYear, now: now, calendar: calendar).contains("2026"))
        #expect(RecipeCopy.cookDay(lastYear, now: now, calendar: calendar).contains("2025"))
        #expect(RecipeCopy.cookDay(lastYear, now: now, calendar: calendar).hasSuffix(", 9 pm"))
    }

    /// G62: absurd stored values never trap the page.
    @Test func absurdValuesNeverCrash() {
        #expect(PortionDrum.range(written: Int.max) == 1 ... 48)
        #expect(PortionDrum.range(written: Int.min) == 1 ... 12)
        #expect(RecipeCopy.duration(.infinity) == "0 min")
        #expect(RecipeCopy.duration(.nan) == "0 min")
        #expect(RecipeCopy.duration(1e300) == "99 h 59 min")
        #expect(RecipeCopy.duration(-5) == "0 min")
    }
}
