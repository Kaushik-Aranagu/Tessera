import Foundation
@testable import TesseraCore
import Testing

@MainActor
struct StarterContentTests {
    @Test func firstLaunchHasHisPlanAndKit() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let ledger = TrainingLedger(store: store, classes: classes)
        let plan = try #require(store.object(id: StarterContent.planID))
        let routines = store.linkedObjects("routines", of: plan)
        #expect(routines.map(\.title) == ["Push A", "Pull A", "Legs A", "Push B", "Pull B", "Legs B"])
        #expect(routines.allSatisfy { $0.orderedChildren.count == 5 })
        #expect(ledger.nextRoutine(in: plan)?.title == "Push A")
        let firstSlot = try #require(routines.first?.orderedChildren.first)
        #expect(store.linkedClass("exercise", of: firstSlot)?.id == classes[.benchPress]?.id)
        #expect(store.number("sets", of: firstSlot) == 4)

        // Kit: 20 kg bar with plates down to 1.25 kg; dumbbells in 2 kg steps.
        let bench = try #require(classes[.benchPress])
        #expect(store.loadProfile(for: bench).next(above: 80) == 82.5)
        #expect(store.loadProfile(for: bench).nearest(to: 20) == 20)
        let dbPress = try #require(store.classDef(id: SystemCatalog.stableID("library.dbBenchPress")))
        #expect(store.loadProfile(for: dbPress).next(above: 22) == 24)

        // Starting Push A works end to end.
        let engine = ActionEngine(store: store, classes: classes)
        let workout = try engine.perform(StartRoutine(routine: #require(routines.first).id), by: .user).output
        #expect(workout.orderedChildren.count == 5)

        // Installs once.
        #expect(try StarterContent.installIfNeeded(store: store, classes: classes) == false)
        #expect(try store.objects(of: #require(classes[.plan])).count == 1)
    }
}
