import Foundation
@testable import TesseraCore
import Testing

@MainActor
struct ExerciseOverviewTests {
    @Test func exercisePageAndSessionSwap() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let ledger = TrainingLedger(store: store, classes: classes)
        let plan = try #require(store.object(id: StarterContent.planID))
        let pushA = try #require(store.linkedObjects("routines", of: plan).first)
        let bench = try #require(classes[.benchPress])
        let now = Date(timeIntervalSince1970: 1_792_000_000)

        for (day, weight) in [(20.0, 77.5), (13, 80), (6, 82.5)] {
            let time = now.addingTimeInterval(-day * 86400)
            let workout = try engine.perform(StartRoutine(routine: pushA.id, time: time), by: .user).output
            let entry = try #require(workout.orderedChildren.first)
            try engine.perform(LogSet(entry: entry.id, weight: weight, reps: 5), by: .user)
            try engine.perform(FinishWorkout(workout: workout.id, time: time), by: .user)
        }
        let page = ledger.overview(of: bench, recent: 2, now: now)
        #expect(page.bestSet?.weight == 82.5 && page.repMaxes == [5: 82.5])
        #expect(page.recentSessions.count == 2 && page.sessionCount == 3)
        #expect(page.trend.map(\.volume) == [387.5, 400, 412.5])

        // Bench taken: swap to dumbbell press for today; the routine still says Bench Press.
        let today = try engine.perform(StartRoutine(routine: pushA.id, time: now), by: .user).output
        let entry = try #require(today.orderedChildren.first)
        let swaps = ledger.swapCandidates(for: bench)
        let dbPress = try #require(swaps.first { $0.name.contains("Dumbbell") })
        try engine.perform(SwapEntryExercise(entry: entry.id, exercise: dbPress.id), by: .user)
        #expect(store.linkedClass("exercise", of: entry)?.id == dbPress.id)
        #expect(store.number("targetWeight", of: entry) == nil)
        #expect(store.linkedClass("exercise", of: pushA.orderedChildren[0])?.id == bench.id)
    }
}
