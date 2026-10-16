import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Product 8:36 PM PT Oct 15 (K887, A026, A027): a lift said with a past day asks "Bench 80 × 8 for Monday?". LOG puts
/// it in that day's workout; NOT NOW writes nothing; never a task.
@MainActor
struct DatedLiftAskTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine
    let tess: TessCaptureEngine
    /// Thursday 15 October 2026, 18:10 in Los Angeles.
    let context = TessContext(now: TesseraDayTests.at(10, 15, 18, 10), calendar: TesseraDayTests.calendar,
                              commitImmediately: true)

    init() throws {
        classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
        tess = TessCaptureEngine(engine: engine)
    }

    var workouts: [ObjectRecord] {
        (try? store.objects(of: #require(classes[.workout]))) ?? []
    }

    @Test func aPastDayAsksAndLogLogsIntoThatDay() async throws {
        let asked = await tess.capture("bench 80x8 mon", context: context)
        #expect(asked.line == "Bench 80 × 8 for Monday?" && asked.records.isEmpty && workouts.isEmpty)
        #expect(tess.pendingDatedLift != nil)
        let logged = tess.answer(TessDatedLiftAsk.Choice.log, context: context)
        #expect(logged.line == "Bench 80 × 8 logged for Monday." && logged.records.count == 1)
        let workout = try #require(workouts.first)
        let started = try #require(store.value("startedAt", of: workout)?.dateValue)
        #expect(TesseraDay(calendar: TesseraDayTests.calendar).day(of: started) == TesseraDayTests.at(10, 12, 0))
        #expect(store.value("endedAt", of: workout) != nil)
        #expect(ProcessTable(engine: engine).running() == nil)
    }

    @Test func setsAreStampedOnThatDayAndAnOpenWorkoutIsJoined() async throws {
        // QA D2: loggedAt is Monday, not now. QA D1: Monday's workout left open is still Monday's.
        let open = try store.create(#require(classes[.workout]), title: "Push")
        try engine.perform(AddExercise(workout: open.id, exercise: #require(classes[.benchPress]).id), by: .user)
        try store.set("startedAt", to: .date(TesseraDayTests.at(10, 12, 18)), on: open)
        _ = await tess.capture("squat 100x5 mon", context: context)
        _ = tess.answer(TessDatedLiftAsk.Choice.log, context: context)
        #expect(workouts.count == 1 && open.orderedChildren.count == 2)
        let set = try #require(open.orderedChildren.last?.orderedChildren.first)
        let logged = try #require(store.value("loggedAt", of: set)?.dateValue)
        #expect(TesseraDay(calendar: TesseraDayTests.calendar).day(of: logged) == TesseraDayTests.at(10, 12, 0))
    }

    @Test func twoWorkoutsThatDayPreferTheOneWithTheExercise() async throws {
        // QA P1, P2: Monday had a morning bench and an evening pull session; a dated bench joins the morning one, and
        // its set is stamped at that workout's end.
        let workoutClass = try #require(classes[.workout])
        let morning = try store.create(workoutClass, title: "Push")
        try engine.perform(AddExercise(workout: morning.id, exercise: #require(classes[.benchPress]).id), by: .user)
        try store.set("startedAt", to: .date(TesseraDayTests.at(10, 12, 7)), on: morning)
        try store.set("endedAt", to: .date(TesseraDayTests.at(10, 12, 8)), on: morning)
        let evening = try store.create(workoutClass, title: "Pull")
        try store.set("startedAt", to: .date(TesseraDayTests.at(10, 12, 18)), on: evening)
        try store.set("endedAt", to: .date(TesseraDayTests.at(10, 12, 19)), on: evening)
        _ = await tess.capture("bench 80x8 mon", context: context)
        _ = tess.answer(TessDatedLiftAsk.Choice.log, context: context)
        #expect(morning.orderedChildren.count == 1 && evening.orderedChildren.isEmpty)
        let set = try #require(morning.orderedChildren.first?.orderedChildren.last)
        #expect(store.value("loggedAt", of: set)?.dateValue == TesseraDayTests.at(10, 12, 8))
    }

    @Test func notNowWritesNothing() async {
        _ = await tess.capture("squat 100x5 tue", context: context)
        let skipped = tess.answer(TessDatedLiftAsk.Choice.notNow, context: context)
        #expect(skipped.records.isEmpty && workouts.isEmpty && tess.pendingDatedLift == nil)
    }

    @Test func saidAnswersWork() async {
        let asked = await tess.capture("yesterday bench 3x10 70", context: context)
        #expect(asked.line == "Bench 3 × 10 at 70 for Wednesday?")
        let logged = await tess.capture("log it", context: context)
        #expect(logged.line == "Bench 3 × 10 at 70 logged for Wednesday.")
        _ = await tess.capture("bench 80x8 mon", context: context)
        let no = await tess.capture("not now", context: context)
        #expect(no.records.isEmpty && workouts.count == 1)
    }

    @Test func aSecondLiftForTheSameDayJoinsItsWorkout() async {
        _ = await tess.capture("bench 80x8 mon", context: context)
        _ = tess.answer(TessDatedLiftAsk.Choice.log, context: context)
        _ = await tess.capture("squat 100x5 mon", context: context)
        _ = tess.answer(TessDatedLiftAsk.Choice.log, context: context)
        #expect(workouts.count == 1 && workouts.first?.orderedChildren.count == 2)
    }

    @Test func todaysNameLogsAsUsualAndNeverATask() async throws {
        let today = await tess.capture("bench 80x8 thu", context: context)
        #expect(today.records.count == 1 && tess.pendingDatedLift == nil)
        let tasks = try store.objects(of: #require(classes[.task]))
        #expect(tasks.isEmpty)
    }

    @Test func inALiveWorkoutItStillAsks() async throws {
        // K887: Bench in focus; the day word makes it an ask, not a Monday task.
        let workout = try store.create(#require(classes[.workout]), title: "Push")
        let entry = try engine.perform(AddExercise(workout: workout.id, exercise: #require(classes[.benchPress]).id),
                                       by: .user).output
        var live = context
        live.entry = entry.id
        let asked = await tess.capture("bench 80x8 mon", context: live)
        #expect(asked.line == "Bench 80 × 8 for Monday?" && asked.records.isEmpty)
    }
}
