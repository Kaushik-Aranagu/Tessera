import Foundation
@testable import TesseraCore
import Testing

@MainActor
struct PrefillTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine
    let ledger: TrainingLedger

    init() throws {
        classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
        ledger = TrainingLedger(store: store, classes: classes)
    }

    func pushA() throws -> ObjectRecord {
        let plan = try #require(store.object(id: StarterContent.planID))
        return try #require(store.linkedObjects("routines", of: plan).first)
    }

    @Test func setsOpenAtLastTimeThenCarryThisSessionsWeight() throws {
        // First time: nothing logged, so the slot's target.
        let first = try engine.perform(StartRoutine(routine: pushA().id), by: .user).output
        let bench = try #require(first.orderedChildren.first)
        let opening = ledger.prefill(for: bench)
        #expect(opening.source == .target && opening.weight == nil && opening.reps == 5)
        #expect(throws: ActionError.self) { try engine.perform(LogNextSet(entry: bench.id), by: .user) }

        for (weight, reps) in [(80.0, 8.0), (80, 7), (80, 6), (77.5, 8)] {
            try engine.perform(LogSet(entry: bench.id, weight: weight, reps: reps), by: .user)
        }
        try engine.perform(FinishWorkout(workout: first.id), by: .user)

        // Next time: set 1 opens at last time's set 1, and one hold logs it.
        let second = try engine.perform(StartRoutine(routine: pushA().id), by: .user).output
        let entry = try #require(second.orderedChildren.first)
        #expect(ledger.prefill(for: entry) == SetPrefill(weight: 80, reps: 8, source: .lastTime))
        let logged = try engine.perform(LogNextSet(entry: entry.id), by: .user)
        #expect(logged.record.summary == "Logged 80 × 8")
        #expect(store.value("source", of: logged.output) == .choice("hold"))

        // He goes heavier on set 2; set 3 keeps his weight with last time's reps for set 3.
        try engine.perform(LogSet(entry: entry.id, weight: 82.5, reps: 7), by: .user)
        #expect(ledger.prefill(for: entry) == SetPrefill(weight: 82.5, reps: 6, source: .thisSession))
        // Past last time's set count, the last set's reps.
        try engine.perform(LogNextSet(entry: entry.id), by: .user)
        try engine.perform(LogNextSet(entry: entry.id), by: .user)
        #expect(ledger.prefill(for: entry) == SetPrefill(weight: 82.5, reps: 8, source: .thisSession))
    }
}
