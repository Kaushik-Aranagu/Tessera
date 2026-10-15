import Foundation
@testable import TesseraCore
import Testing

@MainActor
struct WeekViewTests {
    @Test func doneDaysThenTheRollingPlanAhead() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let ledger = TrainingLedger(store: store, classes: classes)
        let plan = try #require(store.object(id: StarterContent.planID))
        let routines = store.linkedObjects("routines", of: plan)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        calendar.firstWeekday = 2 // Monday
        // Wednesday 14 October 2026, noon.
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 14, hour: 12)))
        let monday = now.addingTimeInterval(-2 * 86400)

        // Push A done on Monday; Tuesday skipped.
        let workout = try engine.perform(StartRoutine(routine: routines[0].id, time: monday), by: .user).output
        let entry = try #require(workout.orderedChildren.first)
        try engine.perform(LogSet(entry: entry.id, weight: 80, reps: 8), by: .user)
        try engine.perform(FinishWorkout(workout: workout.id, time: monday.addingTimeInterval(3600)), by: .user)

        let week = ledger.week(containing: now, plan: plan, now: now, calendar: calendar)
        #expect(week.count == 7)
        #expect(week.map(\.state) == [.done, .past, .today, .upcoming, .upcoming, .upcoming, .upcoming])
        #expect(week[0].done.first?.title == "Push A")
        // No debt: the missed Tuesday doesn't shift anything; Pull A is next, today.
        #expect(week.compactMap { $0.planned?.title } == ["Pull A", "Legs A", "Push B", "Pull B", "Legs B"])
    }
}
