import Foundation
@testable import TesseraCore
import Testing

@MainActor
struct WorkoutProgressWarmupTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let store: ObjectStore
    let engine: ActionEngine
    let start = Date(timeIntervalSince1970: 1_800_000_000)

    init() throws {
        store = ObjectStore(context: container.mainContext)
        let classes = try SystemCatalog.seed(in: container.mainContext)
        engine = ActionEngine(store: store, classes: classes)
        try StarterContent.installIfNeeded(store: store, classes: classes)
    }

    @Test func aWarmupDoesNotMoveTheNextWorkingSetAlong() throws {
        let plan = try #require(store.object(id: StarterContent.planID))
        let routine = try #require(store.linkedObjects("routines", of: plan).first)
        let workout = try engine.perform(StartRoutine(routine: routine.id, time: start), by: .user).output
        let entry = try #require(workout.orderedChildren.first)
        let before = WorkoutProgress(of: workout, store: store)
        #expect(before.setIndex == 0)
        // Two warm-ups (by kind, and by the older flag): the first working set is still next.
        _ = try engine.perform(LogSet(entry: entry.id, weight: 20, reps: 10, isWarmup: true, time: start), by: .user)
        _ = try engine.perform(LogSet(entry: entry.id, weight: 40, reps: 5, kind: .warmup, time: start), by: .user)
        let warm = WorkoutProgress(of: workout, store: store)
        #expect(warm.setIndex == 0 && warm.entry?.id == before.entry?.id)
        #expect(warm.entriesStarted == 0 && warm.nextStep == before.nextStep)
        // A working set does move it, and a drop set counts as a working one.
        _ = try engine.perform(LogSet(entry: entry.id, weight: 60, reps: 5, time: start), by: .user)
        #expect(WorkoutProgress(of: workout, store: store).setIndex == 1)
        _ = try engine.perform(LogSet(entry: entry.id, weight: 50, reps: 8, kind: .drop, time: start), by: .user)
        #expect(WorkoutProgress(of: workout, store: store).setIndex == 2)
        // The ledger and the progress read a set's kind the same way.
        let sets = entry.orderedChildren
        let ledger = TrainingLedger(store: store, classes: engine.classes)
        for set in sets {
            #expect(ledger.setKind(set) == store.setKind(of: set))
        }
        #expect(sets.map { store.setKind(of: $0) } == [.warmup, .warmup, .working, .drop])
    }
}
