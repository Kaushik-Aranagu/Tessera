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
        // Tuesday (past): the day after Monday's session, with room in the week, was a planned rest.
        #expect(week.map(\.isRest) == [false, true, false, true, false, true, false])
        #expect(week.compactMap { $0.planned?.title } == ["Pull A", "Legs A", "Push B"])
        #expect(week[2].state == .today && week[3].state == .upcoming)

        // Already at the count: everything ahead rests. More than the days left: every day trains.
        let full = ledger.week(containing: now, plan: plan, now: now, sessionsPerWeek: 1, calendar: calendar)
        let restAhead = full.dropFirst(2).map(\.isRest)
        #expect(restAhead == [true, true, true, true, true])
        let none = ledger.week(containing: now, plan: plan, now: now, sessionsPerWeek: 0, calendar: calendar)
        #expect(none.allSatisfy { !$0.isRest })
        let busy = ledger.week(containing: now, plan: plan, now: now, sessionsPerWeek: 9, calendar: calendar)
        #expect(busy.allSatisfy { !$0.isRest })
    }
}

@MainActor
struct RestDayTests {
    @Test func aDoubleSessionDayCountsOnce() throws {
        // QA D7 on #219: two sessions on Monday are one done day toward the week, not two.
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let ledger = TrainingLedger(store: store, classes: classes)
        let plan = try #require(store.object(id: StarterContent.planID))
        let routines = store.linkedObjects("routines", of: plan)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        calendar.firstWeekday = 2
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 14, hour: 12)))
        let monday = now.addingTimeInterval(-2 * 86400)
        for index in 0 ..< 2 {
            let started = monday.addingTimeInterval(Double(index) * 8 * 3600)
            let workout = try engine.perform(StartRoutine(routine: routines[index].id, time: started), by: .user)
                .output
            let entry = try #require(workout.orderedChildren.first)
            try engine.perform(LogSet(entry: entry.id, weight: 80, reps: 8), by: .user)
            try engine.perform(FinishWorkout(workout: workout.id, time: started.addingTimeInterval(3600)), by: .user)
        }
        let week = ledger.week(containing: now, plan: plan, now: now, sessionsPerWeek: 4, calendar: calendar)
        #expect(week[0].done.count == 2)
        // Same as one session: 3 still due over the 5 days left.
        #expect(week.map(\.isRest) == [false, true, false, true, false, true, false])
        #expect(week.compactMap(\.planned).count == 3)
    }

    @Test func aRestDayKeepsTheNextRoutineOneTapAway() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let ledger = TrainingLedger(store: store, classes: classes)
        let plan = try #require(store.object(id: StarterContent.planID))
        let routines = store.linkedObjects("routines", of: plan)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        calendar.firstWeekday = 2
        // Push A done Monday. Four a week leaves 3: Tuesday rests (trained yesterday), then Wed, Fri, Sun.
        let tuesday = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 13, hour: 12)))
        let monday = tuesday.addingTimeInterval(-86400)
        let workout = try engine.perform(StartRoutine(routine: routines[0].id, time: monday), by: .user).output
        let entry = try #require(workout.orderedChildren.first)
        try engine.perform(LogSet(entry: entry.id, weight: 80, reps: 8), by: .user)
        try engine.perform(FinishWorkout(workout: workout.id, time: monday.addingTimeInterval(3600)), by: .user)

        let week = ledger.week(containing: tuesday, plan: plan, now: tuesday, sessionsPerWeek: 4, calendar: calendar)
        #expect(week.map(\.isRest) == [false, true, false, true, false, true, false])
        let rest = try #require(ledger.restDay(plan: plan, now: tuesday, sessionsPerWeek: 4, calendar: calendar))
        #expect(rest.next.title == "Pull A")
        #expect(rest.nextDay.map { calendar.component(.weekday, from: $0) } == 4) // Wednesday
        #expect(RestDay.line == "Rest day")
        #expect(NowPicker(engine: engine).restDay(plan: plan, at: tuesday, sessionsPerWeek: 4,
                                                  calendar: calendar)?.next.id == rest.next.id)

        // Wednesday is a training day; no rhythm means no rest days; a workout under way today isn't a rest day.
        let wednesday = tuesday.addingTimeInterval(86400)
        #expect(ledger.restDay(plan: plan, now: wednesday, sessionsPerWeek: 4, calendar: calendar) == nil)
        #expect(ledger.restDay(plan: plan, now: tuesday, calendar: calendar) == nil)
        try engine.perform(StartRoutine(routine: routines[1].id, time: tuesday), by: .user)
        #expect(ledger.restDay(plan: plan, now: tuesday, sessionsPerWeek: 4, calendar: calendar) == nil)
    }
}

@MainActor
struct WeekPastDayTests {
    @Test func pastEmptyDaysSayRestOrDue() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let ledger = TrainingLedger(store: store, classes: classes)
        let plan = try #require(store.object(id: StarterContent.planID))
        let routines = store.linkedObjects("routines", of: plan)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        calendar.firstWeekday = 2
        func at(_ day: Int, _ hour: Int) -> Date {
            calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour))!
        }
        // Three a week. Trained Mon; Tue rests after a training day; Wed was due and nothing happened; now Thu.
        let workout = try engine.perform(StartRoutine(routine: routines[0].id, time: at(12, 18)), by: .user).output
        try engine.perform(LogSet(entry: #require(workout.orderedChildren.first).id, weight: 80, reps: 8), by: .user)
        try engine.perform(FinishWorkout(workout: workout.id, time: at(12, 19)), by: .user)
        let week = ledger.week(containing: at(15, 12), plan: plan, now: at(15, 12), sessionsPerWeek: 3,
                               calendar: calendar)
        let tuesday = week[1], wednesday = week[2]
        #expect(tuesday.state == .past && tuesday.isRest && !tuesday.wasDue)
        #expect(wednesday.state == .past && wednesday.wasDue && !wednesday.isRest)

        // No rhythm given: the seeded plan's own (six routines run once a week = 6): Tue was due too.
        let seeded = ledger.week(containing: at(15, 12), plan: plan, now: at(15, 12), calendar: calendar)
        #expect(seeded[1].isRest && seeded[2].wasDue)
        // No plan: neither (a neutral ring).
        let none = ledger.week(containing: at(15, 12), plan: nil, now: at(15, 12), calendar: calendar)
        #expect(!none[2].isRest && !none[2].wasDue)
    }
}
