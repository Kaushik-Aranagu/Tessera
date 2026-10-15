import Foundation
@testable import Tessera
import TesseraCore
import Testing

@MainActor
struct AppModelTests {
    let container = TesseraSchema.makeContainer(inMemory: true)

    @Test func demoDataProducesALivedInDay() throws {
        let model = AppModel(context: container.mainContext)
        DemoData.prepare(model)

        // The 18 muscles come with Core's exercise library now (the demo used to make its own four).
        #expect(model.objects(of: .muscle).count == 18)
        #expect(model.objects(of: .task).count == 8)
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
        #expect(PlateMath.perSide(82.5) == [25, 5, 1.25])
    }

    @Test func commandInterpreterLogsAndAnswers() {
        let model = AppModel(context: container.mainContext)
        DemoData.prepare(model)
        let interpreter = CommandInterpreter(model: model)

        #expect(interpreter.run("log bench 82.5x8").hasPrefix("Logged bench press 82.5 × 8"))
        #expect(model.session != nil)
        #expect(interpreter.run("what's my bench best?").contains("e1RM"))
        #expect(interpreter.run("stretch at 21:00").hasPrefix("Drying"))
        #expect(model.pendingCapture != nil)
    }
}
