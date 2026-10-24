import Foundation
import Observation
import TesseraCore

/// What a Pantry gesture did, in the room's receipt words: "Milk, used up. On To get." The Undo runs when he taps it
/// within 10 s. A refusal has a receipt and no Undo ("Three pins already. Unpin one first.").
struct KitchenOutcome {
    var receipt: String
    var undo: (() -> Void)?
    var refused = false
}

/// Everything the Pantry room does to a thing, behind one protocol so Core's engine actions swap in when they land
/// (the 8 actions asked of Core on Oct 24: set stock, used up, got it, not now, pin, add to a place). Until then
/// `PantryLocalActions` keeps the changes on this page's own state so the room behaves end to end.
@MainActor
protocol PantryActing: AnyObject {
    func setStock(_ ingredient: ObjectRecord, low: Bool, name: String) -> KitchenOutcome
    func usedUp(_ ingredient: ObjectRecord, name: String) -> KitchenOutcome
    func gotIt(_ item: ListContents.Item, name: String) -> KitchenOutcome
    func notNow(_ ingredient: ObjectRecord, name: String) -> KitchenOutcome
    func pin(_ ingredient: ObjectRecord, on: Bool, in place: UUID, name: String) -> KitchenOutcome
    func add(_ name: String, to place: UUID, placeName: String) -> KitchenOutcome
}

/// The stand-in: pins, low marks, snoozes and added things live in memory for the page; used up and got it go through
/// the real Groceries actions that already exist. Replace with Core's actions; the room does not change.
@MainActor
@Observable
final class PantryLocalActions: PantryActing {
    static let maxPins = 3

    private let engine: ActionEngine
    private let touch: () -> Void

    /// Low by hand, on top of what the ledger knows.
    private(set) var lowByHand: Set<UUID> = []
    /// Not now: hidden until this date.
    private(set) var snoozed: [UUID: Date] = [:]
    /// Pinned ingredients by place, in the order they were pinned.
    private(set) var pins: [UUID: [UUID]] = [:]
    /// Used up: gone from the place until Groceries brings it back.
    private(set) var usedUpIDs: Set<UUID> = []
    /// Things added by hand: name and place, until Core stores them.
    private(set) var added: [(id: UUID, name: String, place: UUID)] = []

    init(engine: ActionEngine, touch: @escaping () -> Void) {
        self.engine = engine
        self.touch = touch
    }

    func isPinned(_ id: UUID, in place: UUID) -> Bool {
        pins[place]?.contains(id) == true
    }

    func isSnoozed(_ id: UUID, now: Date) -> Bool {
        (snoozed[id] ?? .distantPast) > now
    }

    func setStock(_ ingredient: ObjectRecord, low: Bool, name: String) -> KitchenOutcome {
        let id = ingredient.id
        if low {
            lowByHand.insert(id)
        } else {
            lowByHand.remove(id)
        }
        return KitchenOutcome(receipt: low ? "\(name), running low." : "\(name), back in.") { [weak self] in
            if low {
                self?.lowByHand.remove(id)
            } else {
                self?.lowByHand.insert(id)
            }
        }
    }

    func usedUp(_ ingredient: ObjectRecord, name: String) -> KitchenOutcome {
        let id = ingredient.id
        guard let record = try? engine.perform(AddGroceries(lines: [name]), by: .user).record else {
            return KitchenOutcome(receipt: "Didn't save that. Try again.", undo: nil, refused: true)
        }
        usedUpIDs.insert(id)
        touch()
        return KitchenOutcome(receipt: "\(name), used up. On To get.") { [weak self] in
            self?.usedUpIDs.remove(id)
            _ = self?.engine.undo(record)
            self?.touch()
        }
    }

    func gotIt(_ item: ListContents.Item, name: String) -> KitchenOutcome {
        guard let record = try? engine.perform(CheckListItem(item: item.id, time: AppClock.now), by: .user).record
        else {
            return KitchenOutcome(receipt: "Didn't save that. Try again.", undo: nil, refused: true)
        }
        touch()
        return KitchenOutcome(receipt: "\(name), got it. Back in the fridge.") { [weak self] in
            _ = self?.engine.undo(record)
            self?.touch()
        }
    }

    func notNow(_ ingredient: ObjectRecord, name: String) -> KitchenOutcome {
        let id = ingredient.id
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: AppClock.now) ?? AppClock.now
        snoozed[id] = Calendar.current.startOfDay(for: tomorrow)
        return KitchenOutcome(receipt: "\(name), not now. Asks again tomorrow.") { [weak self] in
            self?.snoozed[id] = nil
        }
    }

    func pin(_ ingredient: ObjectRecord, on: Bool, in place: UUID, name: String) -> KitchenOutcome {
        let id = ingredient.id
        var list = pins[place] ?? []
        if on {
            guard list.count < Self.maxPins else {
                return KitchenOutcome(receipt: "Three pins already. Unpin one first.", undo: nil, refused: true)
            }
            list.append(id)
        } else {
            list.removeAll { $0 == id }
        }
        pins[place] = list
        return KitchenOutcome(receipt: on ? "\(name), pinned." : "\(name), unpinned.") { [weak self] in
            var back = self?.pins[place] ?? []
            if on {
                back.removeAll { $0 == id }
            } else {
                back.append(id)
            }
            self?.pins[place] = back
        }
    }

    func add(_ name: String, to place: UUID, placeName: String) -> KitchenOutcome {
        let id = UUID()
        added.append((id, name, place))
        return KitchenOutcome(receipt: "\(name), added to the \(placeName.lowercased()).") { [weak self] in
            self?.added.removeAll { $0.id == id }
        }
    }
}
