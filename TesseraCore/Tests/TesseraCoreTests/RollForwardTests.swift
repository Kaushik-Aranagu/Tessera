import Foundation
@testable import TesseraCore
import Testing

@MainActor
struct RollForwardTests {
    @Test func unfinishedTasksRollAtFourAndRestInLaterAfterSeven() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let list = TaskList(store: store, classes: classes)
        let calendar = Calendar.current
        let monday = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 12, hour: 18)))
        let task = try engine.perform(CreateTask(title: "Call the bank", startsAt: monday), by: .user).output
        let done = try engine.perform(CreateTask(title: "Stand-up", startsAt: monday), by: .user).output
        try engine.perform(SetTaskDone(task: done.id), by: .user)

        // 01:00 Tuesday is still Monday's day: nothing rolls.
        #expect(list.rollForward(engine: engine, now: monday.addingTimeInterval(7 * 3600)) == nil)
        // 05:00 Tuesday: it rolls to Tuesday 18:00, once.
        let tuesday = monday.addingTimeInterval(11 * 3600)
        #expect(list.rollForward(engine: engine, now: tuesday) == "Call the bank carried into today.")
        #expect(store.value("startsAt", of: task)?.dateValue == monday.addingTimeInterval(86400))
        #expect(store.number("rolls", of: task) == 1 && store.value("rolledFrom", of: task)?.dateValue == monday)
        #expect(list.rollForward(engine: engine, now: tuesday) == nil)
        #expect(store.value("startsAt", of: done)?.dateValue == monday)

        // Six more nights: the seventh roll puts it in Later.
        var lines: [String?] = []
        for night in 2 ... 7 {
            lines.append(list.rollForward(engine: engine, now: tuesday.addingTimeInterval(Double(night - 1) * 86400)))
        }
        #expect(lines.last == "Call the bank moved to Later.")
        #expect(list.later().map(\.id) == [task.id])

        // One undo puts the last roll back.
        #expect(engine.undoLatest(action: RollForwardTasks.descriptor.name) != nil)
        #expect(store.value("startsAt", of: task) != nil && store.number("rolls", of: task) == 6)
    }
}
