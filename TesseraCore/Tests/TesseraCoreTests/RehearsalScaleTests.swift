import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// A rehearsal must stay inside its 2 s budget on years of history (TESSERA_SCALE=1500 is about five years). The
/// budget is asserted in optimized builds only; a debug build prints the timings.
@MainActor
struct RehearsalScaleTests {
    @Test func aTryStaysInsideTheBudgetOnYearsOfHistory() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let ledger = TrainingLedger(store: store, classes: classes)
        let bench = try #require(classes[.benchPress])
        let workoutClass = try #require(classes[.workout])
        let entryClass = try #require(classes[.exerciseEntry])
        for day in 0 ..< ScaleTests.workouts {
            let workout = store.create(workoutClass, title: "Day \(day)")
            try store.set("endedAt", to: .date(Date(timeIntervalSince1970: 1_700_000_000 + Double(day) * 86400)),
                          on: workout)
            for _ in 0 ..< 5 {
                let entry = store.create(entryClass, parent: workout)
                try store.setClassLink("exercise", on: entry, to: bench)
                for set in 0 ..< 5 {
                    try ledger.logSet(weight: 60 + Double(day % 40), reps: Double(5 + set), in: entry)
                }
            }
        }
        try store.context.save()
        let clock = ContinuousClock()
        // The app reads the real store's labels all the time, so they are warm before a rehearsal starts.
        let warm = clock.measure { _ = PrivateWords.labels(in: store.context) }
        let rehearsal = Rehearsal(engine: engine)
        rehearsal.seconds = 1000
        var seconds: [Double] = []
        for index in 1 ... Rehearsal.budget {
            let took = clock.measure {
                _ = rehearsal.try([Rehearsal.Call(name: "createTask", json: #"{"title":"Try \#(index)","due":null}"#)])
            }
            seconds.append(Double(took.components.seconds) + Double(took.components.attoseconds) / 1e18)
        }
        print("REHEARSAL \(ScaleTests.workouts) workouts, \(store.context.objects.count) objects: labels \(warm), "
            + "tries \(seconds)")
        #if !DEBUG
            #expect(seconds.allSatisfy { $0 < Rehearsal.seconds })
        #endif
    }
}
