import Foundation
@testable import TesseraCore
import Testing

/// Together piece 2: one pair of hands across the workout, the cook and the routines.
@MainActor
struct OneHandsTests {
    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    func at(_ hour: Int, _ minute: Int = 0, day: Int = 22) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    /// Push A planned today, usually at 18:00 for 60 minutes (three past workouts).
    func pushPlan(title: String = "Push A", startHour: Int = 18) throws -> ObjectRecord {
        let routine = try engine.perform(CreateRoutine(title: title), by: .user).output
        let plan = try engine.perform(CreatePlan(title: "PPL", routines: [routine.id]), by: .user).output
        for week in 1 ... 3 {
            let workout = try store.create(#require(engine.classes[.workout]), title: title)
            try store.setLinks("routine", on: workout, to: [routine])
            try store.set("endedAt", to: .date(at(startHour + 1, day: 22 - week)), on: workout)
            let entry = try store.create(#require(engine.classes[.exerciseEntry]), parent: workout)
            try store.setClassLink("exercise", on: entry, to: #require(engine.classes[.benchPress]))
            let ledger = TrainingLedger(store: store, classes: engine.classes)
            let first = try ledger.logSet(weight: 80, reps: 5, in: entry)
            let last = try ledger.logSet(weight: 80, reps: 5, in: entry)
            try store.set("loggedAt", to: .date(at(startHour, day: 22 - week)), on: first)
            try store.set("loggedAt", to: .date(at(startHour + 1, day: 22 - week)), on: last)
        }
        return plan
    }

    func cook(serveAt: Date) throws {
        let chicken = try engine.perform(
            CreateRecipe(
                text: "Chicken\nIngredients\n1 onion\nMethod\n1. Season it.\n2. Bake for 33 minutes.\n3. Plate it."
            ),
            by: .user
        ).output
        let pasta = try engine.perform(
            CreateRecipe(
                text: "Pasta\nIngredients\n1 cup pasta\nMethod\n1. Boil water.\n2. Cook for 10 minutes.\n3. Drain."
            ),
            by: .user
        ).output
        try engine.perform(StartCookSession(recipes: [chicken.id, pasta.id], serveAt: serveAt, time: at(9)), by: .user)
    }

    var table: ProcessTable {
        ProcessTable(engine: engine)
    }

    @Test func noHistoryMeansNoEventsAndNoCollisions() {
        #expect(table.handsEvents(on: at(9), plan: nil, calendar: calendar).isEmpty)
        #expect(table.collisions(on: at(9), plan: nil, calendar: calendar).isEmpty)
    }

    @Test func aWorkoutIsItsUsualStartAndLength() throws {
        let plan = try pushPlan()
        let events = table.handsEvents(on: at(9), plan: plan, calendar: calendar)
        #expect(events.count == 1)
        let workout = try #require(events.first)
        #expect(workout.app == .training && workout.start == at(18) && workout.end == at(19))
        #expect(!workout.isFixed)
    }

    @Test func aCooksWaitsAreFreeSoOnlyItsHandsCollide() throws {
        let plan = try pushPlan()
        // Serve at 19:00: the cook's hands stretches sit in its last minutes; the chicken waits 33 minutes in between.
        try cook(serveAt: at(19))
        let events = table.handsEvents(on: at(9), plan: plan, calendar: calendar)
        let kitchen = try #require(events.first { $0.app == .kitchen })
        #expect(kitchen.isFixed && kitchen.hands.count >= 2)
        #expect(kitchen.hands.map(\.duration).reduce(0, +) < kitchen.end.timeIntervalSince(kitchen.start))
    }

    @Test func aCooksHandsOnTheWorkoutMoveTheWorkoutAfterThem() throws {
        let plan = try pushPlan()
        try cook(serveAt: at(18, 30))
        let collisions = table.collisions(on: at(9), plan: plan, calendar: calendar)
        let collision = try #require(collisions.first)
        #expect(Set([collision.a.app, collision.b.app]) == [.training, .kitchen])
        let fix = try #require(collision.fix)
        // The cook is fixed to its serve time; the workout moves, to a start with its hands clear of the cook's.
        #expect(fix.app == .training && fix.by > 0)
        let moved = DateInterval(start: fix.newStart, duration: 3600)
        let kitchen = try #require(table.handsEvents(on: at(9), plan: plan, calendar: calendar)
            .first { $0.app == .kitchen })
        #expect(kitchen.hands.allSatisfy { moved.intersection(with: $0).map { $0.duration == 0 } ?? true })
    }

    @Test func twoMovableThingsLeaveTheLaterOneToMove() throws {
        let plan = try pushPlan()
        // A routine usually at 18:30 for 30 minutes: 7 runs.
        let runs = (1 ... 8).map { day in
            RoutineRun(start: at(18, 30, day: 22 - day), end: at(19, 0, day: 22 - day))
        }
        let routines = [RoutinesLanding.Item(name: "Stretch", count: 4, runs: runs)]
        let collisions = table.collisions(on: at(9), plan: plan, routines: routines, calendar: calendar)
        let collision = try #require(collisions.first)
        #expect(collision.at == at(18, 30) && collision.overlap == 1800)
        let fix = try #require(collision.fix)
        #expect(fix.app == .routines && fix.newStart == at(19))
    }

    @Test func aChainOfThreeOverlapsIsThreeCollisionsEachWithItsOwnFix() throws {
        let plan = try pushPlan()
        func runs(_ hour: Int, _ minute: Int, minutes: Int) -> [RoutineRun] {
            (1 ... 8).map { day in
                let start = at(hour, minute, day: 22 - day)
                return RoutineRun(start: start, end: start.addingTimeInterval(Double(minutes) * 60))
            }
        }
        let routines = [
            RoutinesLanding.Item(name: "Stretch", count: 8, runs: runs(18, 30, minutes: 30)),
            RoutinesLanding.Item(name: "Journal", count: 8, runs: runs(18, 45, minutes: 30)),
        ]
        let found = table.collisions(on: at(9), plan: plan, routines: routines, calendar: calendar)
        // Workout 18:00-19:00, Stretch 18:30-19:00, Journal 18:45-19:15: all three pairs overlap, earliest first.
        #expect(found.count == 3)
        #expect(found.map(\.at) == [at(18, 30), at(18, 45), at(18, 45)])
        #expect(found.map(\.overlap).sorted() == [900, 900, 1800])
        // The later starter of each pair moves, past the other's hands; no fix chains onto another.
        let fixes = found.compactMap(\.fix)
        #expect(fixes.count == 3)
        #expect(fixes.filter { $0.label == "Stretch" }.map(\.newStart) == [at(19)])
        #expect(fixes.filter { $0.label == "Journal" }.map(\.newStart).sorted() == [at(19), at(19)])
    }

    @Test func nothingOverlappingIsNoCollision() throws {
        let plan = try pushPlan(startHour: 7)
        let runs = (1 ... 8).map { day in RoutineRun(start: at(20, 0, day: 22 - day), end: at(20, 20, day: 22 - day)) }
        #expect(table.collisions(on: at(6), plan: plan, routines: [.init(name: "Wind down", count: 3, runs: runs)],
                                 calendar: calendar).isEmpty)
    }

    @Test func aPrivateRoutineReadsPrivateInEveryLabel() throws {
        let plan = try pushPlan()
        let runs = (1 ... 8).map { day in RoutineRun(start: at(18, 30, day: 22 - day), end: at(19, 0, day: 22 - day)) }
        let secret = RoutinesLanding.Item(name: "Knee rehab day", count: 4, isPrivate: true, runs: runs)
        let collision = try #require(table.collisions(on: at(9), plan: plan, routines: [secret], calendar: calendar)
            .first)
        let labels = [collision.a.label, collision.b.label, collision.fix?.label ?? ""]
        #expect(labels.contains("Private routine") && !labels.joined().contains("Knee"))
    }

    @Test func aPrivateWorkoutReadsPrivateWorkout() throws {
        let plan = try pushPlan(title: "Knee rehab day")
        let event = try #require(table.handsEvents(on: at(9), plan: plan, calendar: calendar).first)
        #expect(event.label == "Private workout")
    }

    // MARK: Active plan

    @Test func theActivePlanIsTheStarterPlanElseTheOldestLiveOne() throws {
        let starter = try #require(store.activePlan(classes: engine.classes))
        #expect(starter.id == StarterContent.planID)
        let routine = try engine.perform(CreateRoutine(title: "Day"), by: .user).output
        let first = try engine.perform(CreatePlan(title: "A", routines: [routine.id]), by: .user).output
        let second = try engine.perform(CreatePlan(title: "B", routines: [routine.id]), by: .user).output
        #expect(store.activePlan(classes: engine.classes)?.id == StarterContent.planID)
        store.softDelete(starter)
        #expect(store.activePlan(classes: engine.classes)?.id == first.id)
        store.softDelete(first)
        #expect(store.activePlan(classes: engine.classes)?.id == second.id)
    }
}
