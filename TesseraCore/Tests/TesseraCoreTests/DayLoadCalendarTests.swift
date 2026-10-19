import Foundation
@testable import TesseraCore
import Testing

/// M4 slice 3: day load uses the calendar's free time.
@MainActor
struct DayLoadCalendarTests {
    let store = ObjectStore.open(inMemory: true)
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }

    func at(_ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 20, hour: hour, minute: minute))!
    }

    func event(_ id: String, _ from: Date, _ to: Date, available: EventAvailability = .busy) -> CalendarEventInput {
        CalendarEventInput(externalID: id, title: id, start: from, end: to, availability: available,
                           calendarName: "Work", selfStatus: .accepted)
    }

    @Test func meetingsTakeTimeOffTheRestOfTheDay() throws {
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        let list = TaskList(store: store, classes: engine.classes)
        let plain = list.load(at: at(8), calendar: calendar)
        #expect(plain.freeMinutes == 15 * 60) // 08:00 to 23:00
        try engine.perform(SyncCalendar(
            inputs: [event("a", at(10), at(11)), event("b", at(10, 30), at(11, 30)), event("past", at(7), at(7, 30)),
                     event("free", at(14), at(15), available: .free)],
            windowStart: at(0), windowEnd: at(23, 59)
        ), by: .system)
        let busy = list.load(at: at(8), calendar: calendar)
        // 10:00 to 11:30 is one block of 90 minutes (the overlap is not counted twice); the free-availability one
        // never counts.
        #expect(busy.freeMinutes == 15 * 60 - 90)
        // Meetings already over take nothing from what is left of the day.
        #expect(list.load(at: at(12), calendar: calendar).freeMinutes == 11 * 60)
    }
}
