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

    @Test func fewerSessionsThanDaysLeaveRestDaysBetween() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let ledger = TrainingLedger(store: store, classes: classes)
        let plan = try #require(store.object(id: StarterContent.planID))
        let routines = store.linkedObjects("routines", of: plan)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        calendar.firstWeekday = 2
        // Wednesday 14 October 2026; Push A done Monday. Four a week leaves 3 due over the 5 days left.
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 14, hour: 12)))
        let monday = now.addingTimeInterval(-2 * 86400)
        let workout = try engine.perform(StartRoutine(routine: routines[0].id, time: monday), by: .user).output
        let entry = try #require(workout.orderedChildren.first)
        try engine.perform(LogSet(entry: entry.id, weight: 80, reps: 8), by: .user)
        try engine.perform(FinishWorkout(workout: workout.id, time: monday.addingTimeInterval(3600)), by: .user)

        let week = ledger.week(containing: now, plan: plan, now: now, sessionsPerWeek: 4, calendar: calendar)
        #expect(week.map(\.isRest) == [false, false, false, true, false, true, false])
        #expect(week.compactMap { $0.planned?.title } == ["Pull A", "Legs A", "Push B"])
        #expect(week[2].state == .today && week[3].state == .upcoming)

        // Already at the count: everything ahead rests. More than the days left: every day trains.
        let full = ledger.week(containing: now, plan: plan, now: now, sessionsPerWeek: 1, calendar: calendar)
        let restAhead = full.dropFirst(2).map(\.isRest)
        #expect(restAhead == [true, true, true, true, true])
        let busy = ledger.week(containing: now, plan: plan, now: now, sessionsPerWeek: 9, calendar: calendar)
        #expect(busy.allSatisfy { !$0.isRest })
    }
}
