import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// Builder A's receipts, thing first (docs/research/receipts-thing-first.md RC7 to RC12).
@MainActor
struct ReceiptsTests {
    @Test func undoNamesTheRoutine() {
        #expect(Receipt.takenBack("Push A") == "Push A, taken back")
        #expect(Receipt.takenBack("") == "Taken back")
    }

    @Test func dropNamesTheRoutineAndItsUndoPutsItBack() {
        #expect(Receipt.dropped("Legs B") == "Legs B, dropped")
        #expect(Receipt.backOnPlan("Legs B") == "Legs B, back on the plan")
    }

    @Test func routineEditsNameTheExerciseFirst() {
        let slot = UUID()
        #expect(Receipt.routineEdit(AddSlot(routine: UUID(), exercise: UUID()), exercise: "Bench press",
                                    summary: "Added bench press to the routine") == "Bench press, added")
        #expect(Receipt.routineEdit(SwapSlotExercise(slot: slot, exercise: UUID()), exercise: "Squat",
                                    summary: "Swapped in Squat") == "Squat, swapped in")
        #expect(Receipt.routineEdit(MoveSlot(slot: slot, toIndex: 2), exercise: "Bench press",
                                    summary: "Moved Bench press to 3") == "Bench press, moved to 3")
        #expect(Receipt.routineEdit(DeleteObject(object: slot), exercise: "Bench press",
                                    summary: "Deleted it") == "Bench press, removed")
        #expect(Receipt.routineEdit(EditSlot(slot: slot, sets: 4), exercise: "Bench press",
                                    summary: "Bench press: 4 × 8–12") == "Bench press, 4 × 8–12")
        #expect(Receipt.routineEdit(MoveSlot(slot: slot, toIndex: 0), exercise: nil,
                                    summary: "Moved Exercise to 1") == "Moved Exercise to 1")
    }

    @Test func setLoggedNamesTheSet() {
        #expect(WorkoutLines.loggedLine(3) == "Set 3 logged")
        #expect(WorkoutLines.loggedLine(nil) == "Set, logged")
    }

    @Test func topSetCheckNamesTheSets() {
        #expect(TopSetCheckLine.acceptedLine(weight: 85, fromSet: 2, toSet: 4) == "Sets 2 to 4, 85 kg")
    }

    @Test func typedLogNamesTheExercise() {
        // No e1RM in a receipt; a new best still says so (Product, 2:29 PM PT Oct 16).
        #expect(CommandInterpreter.loggedReceipt(exercise: "Bench Press", weight: 82.5, reps: 8, best: true)
            == "Bench press 82.5 × 8, logged, best")
        #expect(CommandInterpreter.loggedReceipt(exercise: "Squat", weight: 100, reps: 5, best: false)
            == "Squat 100 × 5, logged")
    }
}
