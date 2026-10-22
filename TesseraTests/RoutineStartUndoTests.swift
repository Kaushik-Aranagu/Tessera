import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// UNDO on Routines' Start (QA on #1225): taking back a fresh run leaves nothing behind; once a set is logged the
/// run stays.
@MainActor
struct RoutineStartUndoTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel

    init() {
        model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
    }

    private func started() throws -> (workout: ObjectRecord, record: OpRecord, entryIDs: [UUID]) {
        let routine = try #require(model.todaysRoutine())
        let result = try model.engine.perform(StartRoutine(routine: routine.id, time: AppClock.now), by: .user)
        let workout = result.output
        model.session = WorkoutSession(workout: workout, model: model)
        return (workout, result.record, workout.orderedChildren.map(\.id))
    }

    @Test func anUndoStraightAfterStartLeavesNoWorkoutEntriesOrProcess() throws {
        let (workout, record, entryIDs) = try started()
        #expect(!entryIDs.isEmpty)
        #expect(RoutinesStarter.takeBack(workout: workout, record: record, model: model))
        #expect(model.session == nil)
        let workouts = try model.store.objects(of: #require(model.classDef(.workout))).map(\.id)
        #expect(!workouts.contains(workout.id))
        let entries = try model.store.objects(of: #require(model.classDef(.exerciseEntry))).map(\.id)
        #expect(entryIDs.allSatisfy { !entries.contains($0) })
        #expect(ProcessTable(engine: model.engine).running()?.subject?.id != workout.id)
    }

    @Test func anUndoAfterALoggedSetIsRefusedAndTheRunStays() throws {
        let (workout, record, _) = try started()
        try #require(model.session).logSet()
        #expect(RoutinesStarter.hasLoggedSets(workout))
        #expect(!RoutinesStarter.takeBack(workout: workout, record: record, model: model))
        #expect(model.session?.workout.id == workout.id)
        let workouts = try model.store.objects(of: #require(model.classDef(.workout))).map(\.id)
        #expect(workouts.contains(workout.id))
    }
}
