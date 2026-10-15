import Foundation
@testable import TesseraCore
import Testing

@MainActor
struct NowPickerTests {
    @Test func oneRuleForNowAndTheNextThree() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let picker = NowPicker(engine: engine)
        let calendar = Calendar.current
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 15, hour: 14)))
        func task(_ title: String, at hour: Double?, minutes: Double = 30) throws -> ObjectRecord {
            try engine.perform(CreateTask(title: title, startsAt: hour.map { now.addingTimeInterval(($0 - 14) * 3600) },
                                          minutes: minutes), by: .user).output
        }
        let carried = try task("Call the bank", at: -10) // yesterday
        let current = try task("Review the plan", at: 13.75, minutes: 45) // 13:45–14:30, still going
        let later = try task("Groceries", at: 18)
        let workout = try store.create(#require(classes[.workout]), title: "Push A")
        try store.set("scheduledFor", to: .date(now.addingTimeInterval(2 * 3600)), on: workout)
        _ = try task("Done already", at: 9)
        try engine.perform(SetTaskDone(task: #require(TaskList(store: store, classes: classes).all()
                .first { $0.title == "Done already" }).id), by: .user)

        // The task in progress is Now; then the workout at 16:00, groceries at 18:00, then the carried-over call.
        let pick = picker.pick(at: now, calendar: calendar)
        #expect(pick.now?.id == current.id && pick.now?.endsAt == now.addingTimeInterval(30 * 60))
        #expect(pick.next.map(\.id) == [workout.id, later.id, carried.id])

        // A running process beats everything.
        try engine.perform(StartTask(task: later.id, nextStep: "List the basics"), by: .user)
        let running = picker.pick(at: now, calendar: calendar)
        #expect(running.now?.kind == .process && running.now?.id == later.id)
        #expect(running.now?.nextStep == "List the basics")
        #expect(!running.next.contains { $0.id == later.id })
    }
}
