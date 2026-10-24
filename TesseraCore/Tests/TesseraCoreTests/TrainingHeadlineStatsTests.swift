import Foundation
@testable import TesseraCore
import Testing

@MainActor
struct TrainingHeadlineStatsTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let stats: TrainingStats
    let plan: ObjectRecord
    let routine: ObjectRecord

    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }

    init() throws {
        classes = try SystemCatalog.seed(in: store.context)
        stats = TrainingStats(store: store, classes: classes)
        plan = try store.create(#require(classes[.plan]), title: "Strength plan")
        routine = try store.create(#require(classes[.routine]), title: "Strength day")
        try store.setLinks("routines", on: plan, to: [routine])
    }

    func date(_ day: Int, hour: Int = 12, minute: Int = 0, month: Int = 10,
              calendar: Calendar? = nil) throws -> Date
    {
        try #require((calendar ?? self.calendar).date(from: DateComponents(
            year: 2026, month: month, day: day, hour: hour, minute: minute
        )))
    }

    @discardableResult
    func session(at date: Date, weight: Double = 80, reps: Double = 5, rpe: Double? = nil,
                 routine: ObjectRecord? = nil, exercise: ClassDef? = nil, title: String = "Strength day",
                 finished: Bool = true, warmup: Bool = false, empty: Bool = false) throws -> ObjectRecord
    {
        let workout = try store.create(#require(classes[.workout]), title: title)
        try store.set("startedAt", to: .date(date), on: workout)
        if finished {
            try store.set("endedAt", to: .date(date.addingTimeInterval(60)), on: workout)
        }
        try store.setLinks("routine", on: workout, to: [routine ?? self.routine])
        let entry = try store.create(#require(classes[.exerciseEntry]), parent: workout)
        try store.setClassLink("exercise", on: entry, to: #require(exercise ?? classes[.benchPress]))
        if !empty {
            let set = try store.create(#require(classes[.set]), parent: entry)
            try store.set("weight", to: .mass(weight), on: set)
            try store.set("reps", to: .number(reps), on: set)
            try store.set("rpe", to: rpe.map(FieldValue.number), on: set)
            try store.set("loggedAt", to: .date(date), on: set)
            if warmup {
                try store.set("kind", to: .choice(SetKind.warmup.rawValue), on: set)
            }
        }
        return workout
    }

    func run(now: Date, goal: Int = 2) -> Int {
        stats.consecutiveWeeksOnPlan(plan: plan, sessionsPerWeek: goal, now: now, calendar: calendar)
    }

    @Test func noPlanGoalOrHistoryMakesNoRun() throws {
        let now = try date(22)
        #expect(run(now: now) == 0)
        #expect(stats.consecutiveWeeksOnPlan(plan: nil, sessionsPerWeek: 2, now: now, calendar: calendar) == 0)
        #expect(stats.consecutiveWeeksOnPlan(plan: plan, sessionsPerWeek: nil, now: now, calendar: calendar) == 0)
        try session(at: date(13))
        #expect(run(now: now, goal: 0) == 0)
        #expect(run(now: now, goal: -1) == 0)
        try store.setLinks("routines", on: plan, to: [])
        #expect(run(now: now, goal: 1) == 0)
    }

    @Test func incompleteWeekPreservesTheCurrentRunAndMeetingGoalAddsIt() throws {
        for day in [6, 8, 13, 15, 20] {
            try session(at: date(day))
        }
        let now = try date(22, hour: 18)
        #expect(run(now: now) == 2)
        try session(at: date(22))
        #expect(run(now: now) == 3)
    }

    @Test func aCompletedWeekBelowGoalEndsTheRunDespiteAnOlderLongRun() throws {
        for day in [1, 2, 6, 8, 13, 20] {
            try session(at: date(day))
        }
        #expect(try run(now: date(22)) == 0)
        try session(at: date(21))
        #expect(try run(now: date(22)) == 1)
    }

    @Test(arguments: ["unrelated", "privateWorkout", "privateRoutine", "running", "empty", "warmup", "deleted"])
    func onlyFinishedNonprivatePlanWorkoutsCount(kind: String) throws {
        let other = try store.create(#require(classes[.routine]), title: "Other day")
        if kind == "privateRoutine" {
            routine.title = "Knee rehab day"
        }
        let workout = try session(at: date(13), routine: kind == "unrelated" ? other : routine,
                                  title: kind == "privateWorkout" ? "Knee rehab day" : "Strength day",
                                  finished: kind != "running", warmup: kind == "warmup", empty: kind == "empty")
        if kind == "deleted" {
            workout.deletedAt = try date(14)
        }
        #expect(try run(now: date(22), goal: 1) == 0)
    }

    @Test func multipleExerciseEntriesCountAsOneWorkoutAndFutureFinishesWait() throws {
        let workout = try session(at: date(13))
        let entry = try store.create(#require(classes[.exerciseEntry]), parent: workout)
        try store.setClassLink("exercise", on: entry, to: #require(classes[.benchPress]))
        let set = try store.create(#require(classes[.set]), parent: entry)
        try store.set("weight", to: .mass(90), on: set)
        try store.set("reps", to: .number(5), on: set)
        #expect(try run(now: date(22)) == 0)
        try session(at: date(22, hour: 18))
        #expect(try run(now: date(22), goal: 1) == 1)
        #expect(try run(now: date(22, hour: 19), goal: 1) == 2)
    }

    @Test func mondayBoundaryUsesTheWorkoutsStartingDayAndDoesNotCountTheNewWeekTwice() throws {
        try session(at: date(12, hour: 4))
        let crossing = try session(at: date(19, hour: 3, minute: 59))
        try store.set("endedAt", to: .date(date(19, hour: 6)), on: crossing)
        #expect(try run(now: date(19), goal: 1) == 1)
        try session(at: date(19, hour: 4))
        #expect(try run(now: date(19), goal: 1) == 2)
        // At Monday 04:00 the new week's workout is not finished yet; the previous run survives.
        #expect(try run(now: date(19, hour: 4), goal: 1) == 1)
    }

    @Test func localWeeksSurviveTheAutumnClockChange() throws {
        var local = calendar
        local.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        try session(at: date(27, calendar: local))
        try session(at: date(2, hour: 4, month: 11, calendar: local))
        let now = try date(9, hour: 4, month: 11, calendar: local)
        #expect(stats.consecutiveWeeksOnPlan(plan: plan, sessionsPerWeek: 1, now: now, calendar: local) == 2)
    }

    @Test func aPrivateOrDeletedPlanMakesNoRun() throws {
        try session(at: date(13))
        plan.title = "Knee rehab plan"
        #expect(try run(now: date(22), goal: 1) == 0)
        plan.title = "Strength plan"
        plan.deletedAt = try date(21)
        #expect(try run(now: date(22), goal: 1) == 0)
    }

    func change(since: Date, now: Date, exercise: ClassDef? = nil) throws -> TrainingStats.E1RMChange? {
        try stats.e1RMChange(for: #require(exercise ?? classes[.benchPress]).id, since: since, now: now)
    }

    @Test func changeNeedsBothSidesOfAnExplicitDateForTheSelectedLift() throws {
        let since = try date(10)
        let now = try date(22)
        #expect(try change(since: since, now: now) == nil)
        try session(at: date(12))
        #expect(try change(since: since, now: now) == nil)
        try session(at: date(8), exercise: #require(classes[.barbellLift]))
        #expect(try change(since: since, now: now) == nil)
        #expect(stats.e1RMChange(for: UUID(), since: since, now: now) == nil)
        #expect(try stats.e1RMChange(for: #require(plan.classDef?.id), since: since, now: now) == nil)
        #expect(try change(since: now, now: now) == nil)
        #expect(try change(since: now.addingTimeInterval(1), now: now) == nil)
    }

    @Test func latestDatedEligiblePointsUseTheFormulaAndKeepKilograms() throws {
        try session(at: date(1), weight: 140)
        try session(at: date(8), weight: 70)
        let baseline = try session(at: date(10), weight: 80, rpe: 8)
        try session(at: date(15), weight: 120)
        let latest = try session(at: date(22), weight: 90)
        let since = try #require(store.value("endedAt", of: baseline)?.dateValue)
        let now = try #require(store.value("endedAt", of: latest)?.dateValue)
        let result = try #require(change(since: since, now: now))
        #expect(result.exerciseID == classes[.benchPress]?.id && result.exercise == "Bench Press")
        #expect(result.since == since && result.baselineDate == since && result.latestDate == now)
        #expect(abs(result.baselineKg - 80 * (1 + 7.0 / 30)) < 0.001)
        #expect(abs(result.latestKg - 105) < 0.001)
        #expect(abs(result.kilograms - (105 - result.baselineKg)) < 0.001)
        #expect(abs(MassUnit.pounds.fromKilograms(result.kilograms)
                - result.kilograms * MassUnit.poundsPerKilogram) < 0.001)
    }

    @Test(arguments: [
        "warmup",
        "highReps",
        "highEffectiveReps",
        "privateWorkout",
        "privateRoutine",
        "future",
        "deleted",
    ])
    func ineligibleComparisonsMakeNoClaim(kind: String) throws {
        try session(at: date(8))
        let privateRoutine = try store.create(#require(classes[.routine]), title: "Knee rehab day")
        let workout = try session(at: date(kind == "future" ? 23 : 15), weight: 150,
                                  reps: kind == "highReps" ? 13 : (kind == "highEffectiveReps" ? 12 : 5),
                                  rpe: kind == "highEffectiveReps" ? 8 : nil,
                                  routine: kind == "privateRoutine" ? privateRoutine : routine,
                                  title: kind == "privateWorkout" ? "Knee rehab day" : "Strength day",
                                  warmup: kind == "warmup")
        if kind == "deleted" {
            workout.deletedAt = try date(16)
        }
        #expect(try change(since: date(10), now: date(22)) == nil)
    }

    @Test func missingBaselineNoPostDatePointAndNonpositiveChangesHaveNoInventedGain() throws {
        try session(at: date(8), weight: 90)
        #expect(try change(since: date(10), now: date(22)) == nil)
        try session(at: date(15), weight: 80)
        let result = try #require(change(since: date(10), now: date(22)))
        #expect(result.kilograms < 0)
        try session(at: date(21), weight: 90)
        #expect(try change(since: date(10), now: date(22))?.kilograms == 0)
        #expect(try change(since: date(1), now: date(22)) == nil)
    }

    @Test func anIneligibleBaselineCannotBeComparedWithALaterNumber() throws {
        try session(at: date(8), weight: 150, warmup: true)
        try session(at: date(9), weight: 150, reps: 13)
        try session(at: date(15), weight: 90)
        #expect(try change(since: date(10), now: date(22)) == nil)
    }

    @Test func equalDateEntriesUseTheirBestEligibleSetWithoutWarmupOrHighRepInflation() throws {
        try session(at: date(8), weight: 70)
        try session(at: date(8), weight: 80)
        let latest = try session(at: date(15), weight: 90)
        try session(at: date(15), weight: 85)
        let entry = try #require(latest.orderedChildren.first)
        for (weight, reps, warmup) in [(200.0, 5.0, true), (200, 13, false)] {
            let set = try store.create(#require(classes[.set]), parent: entry)
            try store.set("weight", to: .mass(weight), on: set)
            try store.set("reps", to: .number(reps), on: set)
            if warmup {
                try store.set("kind", to: .choice(SetKind.warmup.rawValue), on: set)
            }
        }
        let result = try #require(change(since: date(10), now: date(22)))
        #expect(abs(result.baselineKg - 80 * (1 + 5.0 / 30)) < 0.001)
        #expect(abs(result.latestKg - 105) < 0.001)
    }

    @Test func subclassesAreIncludedButPrivateExerciseTitlesAreNot() throws {
        let bench = try #require(classes[.benchPress])
        let variation = store.createClass(name: "Pause bench", parent: bench)
        try session(at: date(8), exercise: variation)
        try session(at: date(15), weight: 90, exercise: variation)
        #expect(try change(since: date(10), now: date(22)) != nil)
        variation.name = "Knee rehab lift"
        #expect(try change(since: date(10), now: date(22)) == nil)
        #expect(try change(since: date(10), now: date(22), exercise: variation) == nil)
    }
}
