import Foundation
@testable import Tessera
import TesseraCore
import Testing

@MainActor
struct AppModelTests {
    let container = TesseraSchema.makeContainer(inMemory: true)

    @Test func withoutDemoHomeTrainsFromHisPlan() throws {
        let model = AppModel(context: container.mainContext)
        // Fresh install: no history, no workout object, just the PPL×2 plan.
        #expect(model.tonightWorkout() == nil)
        let routine = try #require(model.todaysRoutine())
        #expect(routine.title == "Push A")
        #expect(routine.orderedChildren.count == 5)

        model.startRoutine(routine)
        let session = try #require(model.session)
        #expect(model.isWorkoutPresented)
        #expect(session.entries.count == 5)
        #expect(session.currentExercise?.name == "Bench Press")
        // Started: today's training is the running workout now, not the routine.
        #expect(model.todaysRoutine() == nil)
    }

    @Test func aFinishedWorkoutIsSavedIntoTodayOnHome() throws {
        let model = AppModel(context: container.mainContext)
        let routine = try #require(model.todaysRoutine())
        model.startRoutine(routine)
        let session = try #require(model.session)
        session.logSet()
        session.skipRest()
        session.logSet()
        session.finish(early: true)
        #expect(model.engine.history(limit: 1).first?.action == "finishWorkoutEarly")
        model.isWorkoutPresented = false
        model.session = nil
        model.touch()

        let done = try #require(model.finishedToday().first)
        #expect(done.title == "Push A")
        #expect(done.line == "1 of 5 exercises, 2 sets.")
        // Trained today: Home shows the done state, not the next routine; the plan rolls on to Pull A.
        #expect(model.todaysRoutine() == nil)
        #expect(model.plan.flatMap { model.ledger.nextRoutine(in: $0) }?.title == "Pull A")
        let today = try #require(HomeData.lanes(model, now: AppClock.now).first { $0.offset == 0 })
        #expect(today.workouts.count == 1)
    }

    @Test func demoDataProducesALivedInDay() throws {
        let model = AppModel(context: container.mainContext)
        DemoData.prepare(model)

        // The 18 muscles come with Core's exercise library now (the demo used to make its own four).
        #expect(model.objects(of: .muscle).count == 18)
        // Eight timed tasks, plus three undated ones for Plan my day to place.
        #expect(model.objects(of: .task).count == 11)
        let schedule = model.schedule()
        #expect(schedule.count == 9)
        #expect(model.currentTask()?.title == "Groceries for the week")

        let workout = try #require(model.tonightWorkout())
        #expect(workout.orderedChildren.count == 5)

        let bench = try #require(model.classDef(.benchPress))
        #expect(model.history(of: bench).count == 4)
        let best = try #require(model.bestSet(of: bench))
        #expect(best.weight == 82.5 && best.reps == 7)
        #expect(model.prototype(of: bench) != nil)
    }

    @Test func workoutSessionLogsSetsThroughTheModel() throws {
        let model = AppModel(context: container.mainContext)
        DemoData.prepare(model)
        let workout = try #require(model.tonightWorkout())
        model.startWorkout(workout)
        let session = try #require(model.session)

        #expect(session.currentExercise?.name == "Bench Press")
        // The library's bench runs dp(+2.5, 5, 8): last time 82.5 × 7, so aim for 7 again; 8 would be a best.
        #expect(session.weight == 82.5 && session.reps == 7)
        #expect(session.restSeconds == 180) // the library's bench rest
        #expect(!session.isPersonalRecord)
        session.reps = 8
        #expect(session.isPersonalRecord)

        session.logSet()
        let entry = try #require(session.currentEntry)
        #expect(session.loggedSets(of: entry).count == 1)
        #expect(session.restEndsAt != nil)
        // Plates per side come from Core's weight dial for his kit (20 kg bar, plates down to 1.25).
        session.weight = 82.5
        #expect(session.platesPerSide == [25, 5, 1.25])
        #expect(session.plateLine == "25 + 5 + 1.25")
        #expect(session.spokenLoad == "82.5 kilograms, 31.25 per side")
    }

    @Test func commandInterpreterLogsAndAnswers() {
        let model = AppModel(context: container.mainContext)
        DemoData.prepare(model)
        let interpreter = CommandInterpreter(model: model)

        let logged = interpreter.run("log bench 82.5x8")
        #expect(model.session != nil)
        let best = model.session?.lastSeated?.records.isEmpty == false
        #expect(logged == (best ? "Bench press 82.5 × 8, logged, best." : "Bench press 82.5 × 8, logged."))
        #expect(!logged.contains("e1RM"))
        #expect(interpreter.run("what's my bench best?").contains("e1RM"))
        #expect(interpreter.run("stretch at 21:00").hasPrefix("Drying"))
        #expect(model.pendingCapture != nil)
    }

    @Test func commandInterpreterNeverTitlesATaskWithPrivateWords() {
        // Board 0ah (Research AU): a "?" line skips Tess and lands here; walled text is never a task title.
        let model = AppModel(context: container.mainContext)
        let interpreter = CommandInterpreter(model: model)
        #expect(interpreter.run("what's the wifi password?") == "It's in your private notes.")
        #expect(interpreter.run("did I pay rent 2100?") == "That stays on this phone.")
        #expect(interpreter.run("door code 4417") == "Private note, kept.")
        // Built at run time and plainly fake: nothing key-shaped is committed (#487).
        let key = ["sk", "ant", "TEST"].joined(separator: "-") + "-FAKE"
        #expect(interpreter.run(key) == claudeKeyLine)
        let titles = model.store.context.objects.values.map(\.title)
        #expect(!titles.contains { $0.contains("4417") || $0.contains("password") || $0.contains("2100") })
        #expect(!titles.contains { $0.contains("sk-ant") } && model.pendingCapture == nil)
    }
}
