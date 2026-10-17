import Foundation
@testable import Tessera
import Testing

/// Sheet 78's words for the Pantry front.
@MainActor
struct PantryCopyTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles") ?? .current
        return calendar
    }

    private func at(_ day: Int, _ hour: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour)) ?? .now
    }

    @Test func contextNamesTheShopsDay() {
        let wednesday = at(21, 12)
        #expect(PantryCopy.context(lastShop: at(17, 10), now: wednesday, calendar: calendar) == "since Saturday's shop")
        #expect(PantryCopy.context(lastShop: at(18, 1), now: wednesday, calendar: calendar) == "since Saturday's shop")
        #expect(PantryCopy.context(lastShop: at(21, 9), now: wednesday, calendar: calendar) == "since today's shop")
        #expect(PantryCopy.context(lastShop: at(3, 9), now: wednesday, calendar: calendar) == "since the Oct 3 shop")
        #expect(PantryCopy.context(lastShop: nil, now: wednesday, calendar: calendar) == nil)
    }

    @Test func tessNamesWhatTheLastCookUsedUp() {
        #expect(PantryCopy.tess(recipe: "Tacos", names: ["cilantro", "limes"]) == "Tacos took the cilantro and limes.")
        #expect(PantryCopy.tess(recipe: "Tacos", names: ["a", "b", "c"]) == "Tacos took the a, b and c.")
        #expect(PantryCopy.tess(recipe: "Tacos", names: ["a", "b", "c", "d", "e"]) == "Tacos took 5 things.")
        #expect(PantryCopy.list(["a", "b", "c"]) == "a, b and c")
        #expect(PantryCopy.list(["rice", "coffee", "milk", "eggs"]) == "rice, coffee and 2 more")
    }

    @Test func receiptsNameTheThingFirst() {
        #expect(PantryCopy.added("Milk") == "Milk, on Groceries.")
        #expect(PantryCopy.added("Private item") == "Private item, on Groceries.")
    }
}
