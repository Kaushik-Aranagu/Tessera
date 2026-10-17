import Foundation
import TesseraCore

/// Receipts name the thing first (docs/research/receipts-thing-first.md; decisions 12:35 PM PT Oct 16): "Push A,
/// taken back.", "Bench press, moved to 3.". The op summaries stay verb-first log text and are never shown raw.
enum Receipt {
    /// The UNDO line. An undo with several changes names the thing they touched ("Push A, taken back.").
    static func takenBack(_ thing: String) -> String {
        thing.isEmpty ? "Taken back." : "\(thing), taken back."
    }

    /// A routine dropped from the plan, and its UNDO line: "Legs B, dropped.", "Legs B, back on the plan.".
    static func dropped(_ routine: String) -> String {
        "\(routine), dropped."
    }

    static func backOnPlan(_ routine: String) -> String {
        "\(routine), back on the plan."
    }

    /// The exercise a routine edit touches, read before the change runs (a removed slot is gone after it).
    @MainActor
    static func exercise(of action: any EngineAction, in store: ObjectStore) -> String? {
        func slotExercise(_ id: UUID) -> String? {
            store.object(id: id).flatMap { store.linkedClass("exercise", of: $0)?.name }
        }
        switch action {
        case let add as AddSlot: return store.classDef(id: add.exercise)?.name
        case let swap as SwapSlotExercise: return store.classDef(id: swap.exercise)?.name
        case let move as MoveSlot: return slotExercise(move.slot)
        case let edit as EditSlot: return slotExercise(edit.slot)
        case let delete as DeleteObject: return slotExercise(delete.object)
        default: return nil
        }
    }

    /// The routine editor's line after a change: "Bench press, added.", "Squat, swapped in.", "Bench press, moved
    /// to 3.", "Bench press, removed.", "Bench press, 4 × 8–12.". `summary` is the op's log text, the fallback.
    static func routineEdit(_ action: any EngineAction, exercise: String?, summary: String) -> String {
        guard let exercise else { return summary + "." }
        switch action {
        case is AddSlot: return "\(exercise), added."
        case is SwapSlotExercise: return "\(exercise), swapped in."
        case let move as MoveSlot: return "\(exercise), moved to \(move.toIndex + 1)."
        case is DeleteObject: return "\(exercise), removed."
        case is EditSlot:
            // The summary is "Bench press: 4 × 8–12"; the thing already leads, so only the colon goes.
            return summary.replacingOccurrences(of: "\(exercise): ", with: "\(exercise), ") + "."
        default: return summary + "."
        }
    }
}
