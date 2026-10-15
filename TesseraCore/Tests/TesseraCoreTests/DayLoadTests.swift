import Foundation
@testable import TesseraCore
import Testing

@MainActor
struct DayLoadTests {
    @Test func plannedMinutesAgainstTheRestOfToday() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let list = TaskList(store: store, classes: classes)
        let calendar = Calendar.current
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 15, hour: 20)))
        // 20:00 → 23:00 is 180 free minutes.
        try engine.perform(CreateTask(title: "Write the brief", startsAt: now.addingTimeInterval(3600), minutes: 90),
                           by: .user)
        #expect(list.load(at: now).plannedMinutes == 90 && !list.load(at: now).isFull)

        let workout = try store.create(#require(classes[.workout]), title: "Push A")
        try store.set("scheduledFor", to: .date(now), on: workout)
        let carried = try engine.perform(CreateTask(title: "Call the bank", startsAt: now.addingTimeInterval(-86400),
                                                    minutes: 20), by: .user).output
        let load = list.load(at: now)
        #expect(load.freeMinutes == 180)
        #expect(load.plannedMinutes == 90 + 60 + 20)
        #expect(!load.isFull)

        try engine.perform(CreateTask(title: "Reply to emails", startsAt: now.addingTimeInterval(-86400), minutes: 45),
                           by: .user)
        let full = list.load(at: now)
        #expect(full.isFull && full.plannedMinutes == 215)
        // Moving the 45-minute carried task is enough.
        #expect(full.couldMove.map(\.title) == ["Reply to emails"])
        _ = carried
    }
}
