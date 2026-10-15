import Foundation
@testable import TesseraCore
import Testing

@MainActor
struct TaskTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine
    let list: TaskList
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }

    /// Thursday 15 October 2026, 10:00 GMT.
    let now = Date(timeIntervalSince1970: 1_792_058_400)

    init() throws {
        classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
        list = TaskList(store: store, classes: classes)
    }

    func add(_ title: String, hoursFromNow: Double?) throws -> ObjectRecord {
        try engine.perform(CreateTask(title: title, startsAt: hoursFromNow.map { now.addingTimeInterval($0 * 3600) },
                                      minutes: 30), by: .user).output
    }

    @Test func todayCarriesOverUndoneWorkWithoutCallingItOverdue() throws {
        let yesterday = try add("Call the bank", hoursFromNow: -24)
        let morning = try add("Stand-up", hoursFromNow: -1)
        let evening = try add("Groceries", hoursFromNow: 8)
        _ = try add("Dentist", hoursFromNow: 48)
        _ = try add("Someday: learn the cello", hoursFromNow: nil)

        try engine.perform(SetTaskDone(task: morning.id), by: .user)
        let today = list.today(now, calendar: calendar)
        #expect(today.map(\.title) == ["Call the bank", "Groceries", "Stand-up"])
        #expect(today.first?.isCarriedOver == true && today.first?.id == yesterday.id)
        #expect(today.last?.isDone == true)
        #expect(list.todayCounts(now, calendar: calendar) == (1, 3))
        #expect(list.upcoming(now, calendar: calendar).map(\.title) == ["Dentist"])
        #expect(list.later().map(\.title) == ["Someday: learn the cello"])

        // Done records when; reopening clears it.
        #expect(store.value("doneAt", of: morning) != nil)
        try engine.perform(SetTaskDone(task: morning.id, done: false), by: .user)
        #expect(store.value("doneAt", of: morning) == nil)
        _ = evening
    }

    @Test func notNowMovesItTomorrowOrToLater() throws {
        let task = try add("Stretch", hoursFromNow: 2)
        let moved = try engine.perform(MoveTask(task: task.id), by: .user)
        let startsAt = try #require(store.value("startsAt", of: task)?.dateValue)
        #expect(calendar.dateComponents([.day, .hour], from: startsAt) == DateComponents(day: 16, hour: 12))
        #expect(!list.today(now, calendar: calendar).contains { $0.id == task.id })
        engine.undo(moved.record)
        #expect(store.value("startsAt", of: task)?.dateValue == now.addingTimeInterval(7200))

        let later = try engine.perform(MoveTask(task: task.id, later: true), by: .user)
        #expect(later.record.summary == "Moved Stretch to Later")
        #expect(list.later().map(\.id) == [task.id])
        // Delete is undoable too.
        let delete = try engine.perform(DeleteObject(object: task.id), by: .user)
        #expect(list.later().isEmpty)
        engine.undo(delete.record)
        #expect(list.later().map(\.id) == [task.id])
    }
}
