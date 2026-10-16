import Foundation
@testable import TesseraCore
import Testing

@MainActor
struct RecordHintTests {
    @Test func hintsBeforeTheSetAndOneCelebrationAfter() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let ledger = TrainingLedger(store: store, classes: classes)
        let plan = try #require(store.object(id: StarterContent.planID))
        let pushA = try #require(store.linkedObjects("routines", of: plan).first)

        let last = try engine.perform(StartRoutine(routine: pushA.id), by: .user).output
        let lastBench = try #require(last.orderedChildren.first)
        for (weight, reps) in [(80.0, 5.0), (80, 5), (75, 8)] {
            try engine.perform(LogSet(entry: lastBench.id, weight: weight, reps: reps), by: .user)
        }
        try engine.perform(FinishWorkout(workout: last.id), by: .user)

        let today = try engine.perform(StartRoutine(routine: pushA.id), by: .user).output
        let bench = try #require(today.orderedChildren.first)
        // Opens at 80 × 5: equal, so no hint. 82.5 × 5 beats the 5RM.
        #expect(ledger.nextSetHint(for: bench) == nil)
        let hint = try #require(ledger.recordHint(for: bench, weight: 82.5, reps: 5))
        #expect(hint.text == "beats 5RM" && hint.previous == "was 80 × 5")
        #expect(ledger.recordHint(for: bench, weight: 80, reps: 6)?.text == "best e1RM")

        let first = try engine.perform(LogSet(entry: bench.id, weight: 82.5, reps: 5), by: .user).output
        #expect(ledger.shouldCelebrate(first))
        // A second record in the same session doesn't celebrate again.
        let second = try engine.perform(LogSet(entry: bench.id, weight: 85, reps: 5), by: .user).output
        #expect(!ledger.shouldCelebrate(second))
        let ordinary = try engine.perform(LogSet(entry: bench.id, weight: 70, reps: 5), by: .user).output
        #expect(!ledger.shouldCelebrate(ordinary))
    }
}
