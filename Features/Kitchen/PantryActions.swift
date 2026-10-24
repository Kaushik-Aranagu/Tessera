import Foundation
import TesseraCore

/// What a Pantry gesture did, in the room's receipt words: "Milk, used up. On To get." The Undo runs when he taps it
/// within 10 s. A refusal has a receipt and no Undo ("Three pins already. Unpin one first.").
struct KitchenOutcome {
    var receipt: String
    var undo: (() -> Void)?
    var refused = false
}

/// Everything the Pantry room does to a thing, behind one protocol so tests and previews can stand in.
@MainActor
protocol PantryActing: AnyObject {
    func setStock(_ ingredient: ObjectRecord, low: Bool, name: String) -> KitchenOutcome
    func usedUp(_ ingredient: ObjectRecord, name: String) -> KitchenOutcome
    func gotIt(_ ingredient: ObjectRecord, name: String) -> KitchenOutcome
    func notNow(_ ingredient: ObjectRecord, name: String) -> KitchenOutcome
    func pin(_ ingredient: ObjectRecord, on: Bool, name: String) -> KitchenOutcome
    func add(_ name: String, to place: UUID, placeName: String) -> KitchenOutcome
    func checkOff(_ line: ListContents.Item, name: String) -> KitchenOutcome
}

/// Core's Kitchen engine actions (core/kitchen-actions). Each runs as one op with one Undo. The words are the room's
/// own, with the real name (a private item shows its name in the room and nowhere outside it).
@MainActor
final class PantryEngineActions: PantryActing {
    private let engine: ActionEngine
    private let touch: () -> Void

    init(engine: ActionEngine, touch: @escaping () -> Void) {
        self.engine = engine
        self.touch = touch
    }

    private var place: (ObjectRecord) -> String? {
        { [engine] ingredient in
            let places = PantryPlaces(store: engine.store, classes: engine.classes)
            guard let home = places.place(of: ingredient) else { return nil }
            let name = PantryPlaces.shown(home, in: engine.store)
            return "the \(name.prefix(1).lowercased() + name.dropFirst())"
        }
    }

    private static let failed = KitchenOutcome(receipt: "Didn't save that. Try again.", undo: nil, refused: true)

    private func run(_ action: some EngineAction, receipt: String) -> KitchenOutcome {
        do {
            let result = try engine.perform(action, by: .user)
            let record: OpRecord? = result.record
            touch()
            return KitchenOutcome(receipt: receipt) { [engine, touch] in
                if let record {
                    _ = engine.undo(record)
                }
                touch()
            }
        } catch {
            // The only refusal a gesture can meet is the fourth pin.
            if String(describing: error).contains("threePins") {
                return KitchenOutcome(receipt: PantryStock.pinLimitLine, undo: nil, refused: true)
            }
            return Self.failed
        }
    }

    func setStock(_ ingredient: ObjectRecord, low: Bool, name: String) -> KitchenOutcome {
        run(SetIngredientStock(item: ingredient.id, level: low ? .low : .in),
            receipt: low ? "\(name), running low." : "\(name), back in.")
    }

    func usedUp(_ ingredient: ObjectRecord, name: String) -> KitchenOutcome {
        run(UseUpIngredient(item: ingredient.id), receipt: "\(name), used up. On \(PantryPlaces.toGet).")
    }

    func gotIt(_ ingredient: ObjectRecord, name: String) -> KitchenOutcome {
        let back = place(ingredient).map { "Back in \($0)." } ?? "Back in."
        return run(GotIngredient(item: ingredient.id), receipt: "\(name), got it. \(back)")
    }

    func notNow(_ ingredient: ObjectRecord, name: String) -> KitchenOutcome {
        run(SnoozeIngredient(item: ingredient.id), receipt: "\(name), not now. Asks again tomorrow.")
    }

    func pin(_ ingredient: ObjectRecord, on: Bool, name: String) -> KitchenOutcome {
        run(PinIngredient(item: ingredient.id, pinned: on), receipt: "\(name), \(on ? "pinned" : "unpinned").")
    }

    func checkOff(_ line: ListContents.Item, name: String) -> KitchenOutcome {
        run(CheckListItem(item: line.id, time: AppClock.now), receipt: "\(name), got it.")
    }

    func add(_ name: String, to place: UUID, placeName: String) -> KitchenOutcome {
        run(AddToPlace(name: name, place: place), receipt: "\(name), added to the \(placeName.lowercased()).")
    }
}
