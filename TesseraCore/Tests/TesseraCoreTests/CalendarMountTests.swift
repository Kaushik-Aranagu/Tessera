import Foundation
@testable import TesseraCore
import Testing

/// M4 slice 1: the calendar mount (docs/research/calendar-health-fixtures.md C01 to C19). Fixture day: Tuesday
/// 2026-10-20, Los Angeles.
@MainActor
struct CalendarMountTests {
    let store = ObjectStore.open(inMemory: true)
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }

    func at(_ day: Int, _ hour: Int, _ minute: Int = 0, month: Int = 10) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
    }

    var windowStart: Date {
        at(19, 0)
    }

    var windowEnd: Date {
        at(3, 23, 59, month: 11)
    }

    func engine() throws -> ActionEngine {
        try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    func sync(_ engine: ActionEngine, _ inputs: [CalendarEventInput], access: CalendarAccess = .fullAccess,
              start: Date? = nil, end: Date? = nil) throws -> SyncCalendar.Result
    {
        try engine.perform(SyncCalendar(inputs: inputs, windowStart: start ?? windowStart, windowEnd: end ?? windowEnd,
                                        access: access), by: .system).output
    }

    func events(_ engine: ActionEngine) -> [ObjectRecord] {
        let eventClass = engine.classes[.event]!
        return store.objects(of: eventClass).filter { !$0.isDeleted }
    }

    func standup(_ day: Int, title: String = "Standup", hour: Int = 9, minute: Int = 30) -> CalendarEventInput {
        CalendarEventInput(externalID: "standup-1", title: title, start: at(day, hour, minute),
                           end: at(day, hour, minute + 15), occurrenceDate: at(day, 9, 30), isRecurring: true,
                           calendarName: "Work", selfStatus: .accepted)
    }

    @Test func c01RecurringWithAnExceptionMirrorsEachOccurrence() throws {
        let engine = try engine()
        let days = [20, 21, 22, 23, 26, 28, 29, 30] // Oct 27 deleted from the series
        let result = try sync(engine, days.map { standup($0) })
        #expect(result.created == 8 && events(engine).count == 8)
        let keys = events(engine).compactMap { store.value("key", of: $0)?.stringValue }
        #expect(keys.contains("standup-1@2026-10-20T16:30Z") && !keys.contains { $0.contains("2026-10-27") })
    }

    @Test func c02AnEditedOccurrenceIsAnUpdateNotAnInsert() throws {
        let engine = try engine()
        try sync(engine, [standup(20), standup(21)])
        var moved = standup(21, title: "Standup (moved)", hour: 11, minute: 0)
        moved.occurrenceDate = at(21, 9, 30)
        moved.isDetached = true
        let result = try sync(engine, [standup(20), moved])
        #expect(result.created == 0 && result.updated == 1 && result.deleted == 0 && events(engine).count == 2)
        let edited = try #require(events(engine).first { $0.title == "Standup (moved)" })
        #expect(store.value("edited", of: edited) == .bool(true))
        #expect(store.value("start", of: edited)?.dateValue == at(21, 11))
    }

    @Test func aSyncWithNoNewsWritesNothing() throws {
        let engine = try engine()
        try sync(engine, [standup(20)])
        let before = engine.history(limit: 50).count
        let result = try sync(engine, [standup(20)])
        #expect(result == SyncCalendar.Result())
        #expect(engine.history(limit: 50).count == before)
    }

    @Test func c03To05DeclinedTentativeAndAllDayBusy() throws {
        let engine = try engine()
        let declined = CalendarEventInput(externalID: "qbr", title: "QBR", start: at(20, 13), end: at(20, 14),
                                          calendarName: "Work", selfStatus: .declined)
        let tentative = CalendarEventInput(externalID: "lunch", title: "Lunch?", start: at(20, 12), end: at(20, 13),
                                           availability: .tentative, selfStatus: .tentative)
        let allDay = CalendarEventInput(
            externalID: "offsite",
            title: "Team offsite",
            start: at(22, 0),
            end: at(22, 23, 59),
            isAllDay: true,
            availability: .free
        )
        try sync(engine, [declined, tentative, allDay])
        func busy(_ title: String) -> Bool? {
            events(engine).first { $0.title == title }.flatMap { store.value("busy", of: $0) } == .bool(true)
        }
        #expect(busy("QBR") == false && busy("Lunch?") == true && busy("Team offsite") == false)
        let day = CalendarDay(store: store, classes: engine.classes, day: at(20, 12), calendar: calendar)
        #expect(day.busyMinutes == 60) // the tentative lunch only
    }

    @Test func c07AnEventCrossingMidnightSplitsItsBusyMinutes() throws {
        let engine = try engine()
        let redeye = CalendarEventInput(externalID: "redeye", title: "Flight", start: at(25, 22, 30),
                                        end: at(26, 3, 45), timeZone: "America/Los_Angeles")
        try sync(engine, [redeye])
        #expect(events(engine).count == 1)
        let first = CalendarDay(store: store, classes: engine.classes, day: at(25, 12), calendar: calendar)
        let second = CalendarDay(store: store, classes: engine.classes, day: at(26, 12), calendar: calendar)
        #expect(first.busyMinutes == 90 && second.busyMinutes == 225)
    }

    @Test func c09DeletedInsideTheWindowIsAnOp() throws {
        let engine = try engine()
        let oneOnOne = CalendarEventInput(externalID: "1on1", title: "1:1", start: at(21, 15), end: at(21, 16))
        try sync(engine, [oneOnOne])
        let result = try sync(engine, [])
        #expect(result.deleted == 1 && events(engine).isEmpty)
        // A mirror writes no op: nothing of it is in the op log (and so none of it can reach a backup or an export).
        #expect(engine.history(limit: 20).isEmpty)
    }

    @Test func c10NoTitleStoresNoPlaceholderAndStaysBusy() throws {
        let engine = try engine()
        try sync(engine, [CalendarEventInput(externalID: "n", title: "", start: at(20, 16), end: at(20, 16, 30))])
        let event = try #require(events(engine).first)
        #expect(event.title == "" && store.value("busy", of: event) == .bool(true))
    }

    @Test func c11OtherPeoplesSharedCalendarsAreMirroredNotBusy() throws {
        let engine = try engine()
        let shared = CalendarEventInput(externalID: "fb", title: "Busy", start: at(20, 10), end: at(20, 11),
                                        calendarName: "Priya (shared)", calendarIsMine: false)
        try sync(engine, [shared])
        let event = try #require(events(engine).first)
        #expect(store.value("busy", of: event) == .bool(false) && store.value("countsForMe", of: event) == .bool(false))
    }

    @Test func c12BirthdayIsAnAllDayEventNeverBusy() throws {
        let engine = try engine()
        let birthday = CalendarEventInput(
            externalID: "bday",
            title: "Anya's Birthday",
            start: at(23, 0),
            end: at(23, 23, 59),
            isAllDay: true,
            calendarIsBirthday: true,
            birthdayContactID: "ABC123"
        )
        try sync(engine, [birthday])
        let event = try #require(events(engine).first)
        #expect(store.value("kind", of: event)?.stringValue == "birthday" && store
            .value("busy", of: event) == .bool(false))
        #expect(store.value("contactId", of: event)?.stringValue == "ABC123")
    }

    @Test func c13AZeroMinuteEventIsAMarker() throws {
        let engine = try engine()
        try sync(
            engine,
            [CalendarEventInput(externalID: "due", title: "Visa form due", start: at(20, 17), end: at(20, 17))]
        )
        let event = try #require(events(engine).first)
        #expect(store.value("marker", of: event) == .bool(true))
        #expect(CalendarDay(store: store, classes: engine.classes, day: at(20, 12), calendar: calendar)
            .busyMinutes == 0)
    }

    @Test func c14OverlapIsAUnionAndAConflict() throws {
        let engine = try engine()
        let design = CalendarEventInput(externalID: "a", title: "Design review", start: at(20, 10), end: at(20, 11))
        let vendor = CalendarEventInput(
            externalID: "b",
            title: "Vendor call",
            start: at(20, 10, 30),
            end: at(20, 11, 30)
        )
        try sync(engine, [design, vendor])
        let day = CalendarDay(store: store, classes: engine.classes, day: at(20, 12), calendar: calendar)
        #expect(day.busyMinutes == 90 && day.conflicts.count == 1)
    }

    @Test func c15TheSameEventInTwoCalendarsIsOneObject() throws {
        let engine = try engine()
        let shared = CalendarEventInput(
            externalID: "plan",
            title: "Offsite planning",
            start: at(20, 14),
            end: at(20, 15),
            calendarName: "Team (shared)",
            calendarIsMine: false,
            selfStatus: .unknown
        )
        let work = CalendarEventInput(externalID: "plan", title: "Offsite planning", start: at(20, 14), end: at(20, 15),
                                      calendarName: "Work", selfStatus: .accepted)
        try sync(engine, [shared, work])
        let event = try #require(events(engine).first)
        #expect(events(engine).count == 1 && store.value("calendarName", of: event)?.stringValue == "Work")
        #expect(store.value("busy", of: event) == .bool(true))
    }

    @Test func c16CancelledIsMirroredNeverBusy() throws {
        let engine = try engine()
        try sync(engine, [CalendarEventInput(externalID: "cxl", title: "Dentist", start: at(20, 8, 30), end: at(20, 9),
                                             isCancelled: true)])
        let event = try #require(events(engine).first)
        #expect(store.value("cancelled", of: event) == .bool(true) && store.value("busy", of: event) == .bool(false))
    }

    @Test func c17ARolledOutEventIsFrozenNotDeleted() throws {
        let engine = try engine()
        try sync(engine, [standup(19), standup(20)])
        // The window rolls: Oct 19 is out of the back, Oct 20 stays.
        let result = try sync(engine, [standup(20)], start: at(20, 0), end: at(4, 23, 59, month: 11))
        #expect(result.deleted == 0 && events(engine).count == 2)
        let old = try #require(events(engine).first { store.value("start", of: $0)?.dateValue == at(19, 9, 30) })
        #expect(store.value("frozen", of: old) == .bool(true))
    }

    @Test(arguments: [CalendarAccess.writeOnly, .denied, .restricted, .notDetermined])
    func c18And19NoAccessWritesNothingAndKeepsWhatWasThere(_ access: CalendarAccess) throws {
        let engine = try engine()
        try sync(engine, [standup(20)])
        let result = try sync(engine, [], access: access)
        #expect(result.access == access && result.deleted == 0 && events(engine).count == 1)
    }
}
