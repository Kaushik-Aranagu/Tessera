import Foundation
@testable import Tessera
import TesseraCore
import Testing

@MainActor
struct ProcessWiringTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel

    init() {
        model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        DemoData.prepare(model)
    }

    @Test func startingAWorkoutMakesItNow() throws {
        let workout = try #require(model.tonightWorkout())
        model.startWorkout(workout)
        #expect(model.processes.running()?.subject?.id == workout.id)
        #expect(model.processes.ledger(now: AppClock.now).isEmpty)
    }

    @Test func anIdleWorkoutMovesToTheLedgerAndResumesAtItsSet() throws {
        let workout = try #require(model.tonightWorkout())
        model.startWorkout(workout)
        model.isWorkoutPresented = false
        model.tidyProcesses(now: AppClock.now.addingTimeInterval(3600))
        #expect(model.processes.running() == nil)
        let row = try #require(model.processes.ledger(now: AppClock.now.addingTimeInterval(3600)).first)
        #expect(row.state == .suspended)

        model.resume(row)
        #expect(model.isWorkoutPresented)
        #expect(model.processes.running()?.subject?.id == workout.id)
    }

    @Test func aPresentedWorkoutIsNeverSuspendedByTidy() throws {
        let routine = try #require(model.plan.flatMap { model.ledger.nextRoutine(in: $0) })
        model.startRoutine(routine)
        let workout = try #require(model.session?.workout)
        #expect(model.isWorkoutPresented)
        // An hour later on unlock, with the cover still up: still running.
        model.tidyProcesses(now: AppClock.now.addingTimeInterval(3600))
        #expect(model.processes.process(for: workout)?.state == .running)
        // Minimised and idle that long: suspended, as before.
        model.isWorkoutPresented = false
        model.tidyProcesses(now: AppClock.now.addingTimeInterval(3600))
        #expect(model.processes.process(for: workout)?.state == .suspended)
        // Back on the cover: running again.
        model.isWorkoutPresented = true
        model.tidyProcesses(now: AppClock.now.addingTimeInterval(3700))
        #expect(model.processes.process(for: workout)?.state == .running)
    }

    /// QA L2: the empty wrap-up's line carries the record its UNDO takes back.
    @Test func anEmptyWrapUpCanBeTakenBack() throws {
        let workout = try #require(model.tonightWorkout())
        model.startWorkout(workout)
        model.isWorkoutPresented = false
        model.tidyProcesses(now: AppClock.now.addingTimeInterval(3600))
        model.tidyProcesses(now: AppClock.now.addingTimeInterval(8 * 3600))
        #expect(model.processNotes.contains { $0.hasSuffix("no sets, not saved") })
        let undo = try #require(model.processUndo)
        #expect(model.object(workout.id)?.isDeleted ?? true)
        _ = model.engine.undo(undo)
        #expect(model.object(workout.id)?.isDeleted == false)
    }
}
