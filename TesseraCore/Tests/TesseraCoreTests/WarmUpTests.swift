import Foundation
import SwiftData
@testable import TesseraCore
import Testing

@MainActor
struct WarmUpTests {
    @Test func backgroundWarmUpMatchesTheSynchronousIndex() async throws {
        let container = TesseraSchema.makeContainer(inMemory: true)
        let context = container.mainContext
        let classes = try SystemCatalog.seed(in: context)
        let store = ObjectStore(context: context)
        let engine = ActionEngine(store: store, classes: classes)
        let bench = try #require(classes[.benchPress])
        for day in 0 ..< 5 {
            let workout = try store.create(#require(classes[.workout]), title: "Day \(day)")
            let entry = try engine.perform(AddExercise(workout: workout.id, exercise: bench.id), by: .user).output
            try engine.perform(LogSet(entry: entry.id, weight: 80 + Double(day), reps: 8, rpe: 9), by: .user)
            try engine.perform(LogSet(entry: entry.id, weight: 40, reps: 10, isWarmup: true), by: .user)
            try engine.perform(
                FinishWorkout(workout: workout.id, time: Date(timeIntervalSince1970: Double(day) * 86400)),
                by: .user
            )
        }
        try context.save()

        // The synchronous answer, from a fresh store with no cached index.
        let expected = TrainingLedger(store: ObjectStore(context: context), classes: classes).records(for: bench)

        let warm = ObjectStore(context: context)
        let ledger = TrainingLedger(store: warm, classes: classes)
        await ledger.warmUp()
        #expect(warm.derived.trainingIndex != nil)
        let records = ledger.records(for: bench)
        #expect(records.bestE1RM?.weight == expected.bestE1RM?.weight)
        #expect(records.bestE1RM?.e1RM == expected.bestE1RM?.e1RM)
        #expect(records.bestWeightByReps == expected.bestWeightByReps)
        #expect(ledger.sessions(of: bench).count == 5)

        // A write after warm-up is patched in, not lost.
        let workout = try store.create(#require(classes[.workout]), title: "Today")
        let entry = try ActionEngine(store: warm, classes: classes)
            .perform(AddExercise(workout: workout.id, exercise: bench.id), by: .user).output
        try ActionEngine(store: warm, classes: classes).perform(
            LogSet(entry: entry.id, weight: 100, reps: 5),
            by: .user
        )
        try ActionEngine(store: warm, classes: classes).perform(FinishWorkout(workout: workout.id), by: .user)
        #expect(ledger.records(for: bench).bestE1RM?.weight == 100)
    }
}
