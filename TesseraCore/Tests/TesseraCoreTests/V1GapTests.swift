import Foundation
@testable import TesseraCore
import Testing

/// Gaps iOS build hit while building v1 (first sessions, finishing early, day history, reset).
@MainActor
struct V1GapTests {
    let store = ObjectStore.open(inMemory: true)

    @Test func firstSessionGetsAStartingWeightAndTheSlotsReps() throws {
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let ledger = TrainingLedger(store: store, classes: classes)
        let plan = try #require(store.object(id: StarterContent.planID))
        let pushA = try #require(store.linkedObjects("routines", of: plan).first)
        let firstSlot = try #require(pushA.orderedChildren.first)
        let bench = try #require(store.linkedClass("exercise", of: firstSlot))
        let slotLow = try #require(store.number("repMin", of: firstSlot))

        // The exercise page asks without a slot and still gets the plan's rep range.
        let target = ledger.nextTarget(for: bench)
        #expect(target.reps == Int(slotLow))
        #expect(target.weight == nil) // no history; swaps read nil as "nothing of its own"
        #expect(store.startingWeight(for: bench) == 20) // the empty bar

        let workout = try engine.perform(StartRoutine(routine: pushA.id), by: .user).output
        for entry in workout.orderedChildren {
            #expect(store.number("targetWeight", of: entry) != nil)
        }
        let entry = try #require(workout.orderedChildren.first)
        #expect(ledger.prefill(for: entry).weight == 20)
    }

    @Test func finishingEarlySkipsWhatWasntStartedAndUndoes() throws {
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let plan = try #require(store.object(id: StarterContent.planID))
        let pushA = try #require(store.linkedObjects("routines", of: plan).first)
        let workout = try engine.perform(StartRoutine(routine: pushA.id), by: .user).output
        let first = try #require(workout.orderedChildren.first)
        try engine.perform(LogSet(entry: first.id, weight: 60, reps: 8), by: .user)

        let result = try engine.perform(FinishWorkoutEarly(workout: workout.id), by: .user)
        #expect(result.output.count == workout.orderedChildren.count - 1)
        #expect(store.value("skipped", of: first) == nil)
        #expect(workout.orderedChildren.dropFirst().allSatisfy { store.value("skipped", of: $0) == .bool(true) })
        #expect(store.value("endedAt", of: workout) != nil)

        engine.undo(result.record)
        #expect(store.value("endedAt", of: workout) == nil)
        #expect(workout.orderedChildren.allSatisfy { store.value("skipped", of: $0) != .bool(true) })
        #expect(ActionRegistry.descriptors.contains { $0.name == "finishWorkoutEarly" })
    }

    @Test func finishedWorkoutsIsCachedPerRevision() throws {
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let ledger = TrainingLedger(store: store, classes: classes)
        let plan = try #require(store.object(id: StarterContent.planID))
        let pushA = try #require(store.linkedObjects("routines", of: plan).first)
        let time = Date(timeIntervalSince1970: 1_792_000_000)
        let workout = try engine.perform(StartRoutine(routine: pushA.id, time: time), by: .user).output
        #expect(ledger.finishedWorkouts(on: time).isEmpty)
        let entry = try #require(workout.orderedChildren.first)
        try engine.perform(LogSet(entry: entry.id, weight: 60, reps: 5, time: time), by: .user)

        try engine.perform(FinishWorkout(workout: workout.id, time: time.addingTimeInterval(3600)), by: .user)
        let day = ledger.finishedWorkouts(on: time)
        #expect(day.map(\.id) == [workout.id])
        #expect(store.cache.derived.daySummaries.count == 1)
        #expect(ledger.finishedWorkouts(on: time.addingTimeInterval(-86400)).isEmpty)
    }

    @Test func aWorkoutWithNoSetsIsNoSession() throws {
        // Product 8:30 PM PT: started and finished with nothing logged, it isn't one of the day's workouts.
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let plan = try #require(store.object(id: StarterContent.planID))
        let pushA = try #require(store.linkedObjects("routines", of: plan).first)
        let time = Date(timeIntervalSince1970: 1_792_000_000)
        let workout = try engine.perform(StartRoutine(routine: pushA.id, time: time), by: .user).output
        try engine.perform(FinishWorkout(workout: workout.id, time: time.addingTimeInterval(600)), by: .user)
        #expect(TrainingLedger(store: store, classes: classes).finishedWorkouts(on: time).isEmpty)
    }

    @Test func resetPutsTheStarterPlanBack() throws {
        _ = try store.prepareCatalog()
        store.resetUserData()
        #expect(store.object(id: StarterContent.planID) != nil)
    }
}
