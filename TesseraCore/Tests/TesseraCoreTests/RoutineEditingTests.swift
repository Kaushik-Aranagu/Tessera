import Foundation
@testable import TesseraCore
import Testing

@MainActor
struct RoutineEditingTests {
    @Test func reorderEditSwapRemoveAndUndo() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let plan = try #require(store.object(id: StarterContent.planID))
        let pushA = try #require(store.linkedObjects("routines", of: plan).first)
        let names = { pushA.orderedChildren.compactMap { store.linkedClass("exercise", of: $0)?.name } }
        let original = names()

        // Move Lateral Raise (4th) to the top.
        let lateral = pushA.orderedChildren[3]
        let move = try engine.perform(MoveSlot(slot: lateral.id, toIndex: 0), by: .user)
        #expect(names().first == original[3] && names().count == 5)
        engine.undo(move.record)
        #expect(names() == original)

        // Sets × reps.
        let bench = pushA.orderedChildren[0]
        let edit = try engine.perform(EditSlot(slot: bench.id, sets: 5, repMin: 3, repMax: 5), by: .user)
        #expect(edit.record.summary == "Bench Press: 5 × 3–5")
        #expect(throws: ActionError.self) { try engine.perform(EditSlot(slot: bench.id, repMin: 9), by: .user) }

        // Swap and remove.
        let dbPress = try #require(store.classDef(id: SystemCatalog.stableID("library.dbBenchPress")))
        try engine.perform(SwapSlotExercise(slot: pushA.orderedChildren[2].id, exercise: dbPress.id), by: .user)
        #expect(names()[2] == dbPress.name)
        let remove = try engine.perform(DeleteObject(object: pushA.orderedChildren[4].id), by: .user)
        #expect(names().count == 4)
        engine.undo(remove.record)
        #expect(names().count == 5)

        // A started workout follows the edited routine.
        let workout = try engine.perform(StartRoutine(routine: pushA.id), by: .user).output
        #expect(store.number("targetSets", of: workout.orderedChildren[0]) == 5)
    }
}
