import Foundation
import TesseraCore

/// Pantry's front as data (pantry-acceptance.md S1 to S17, B12), so the view only draws it. USUALLY HAVE (S5, S6)
/// waits on Core's Research R engine and the state-word cycle (S7) on a stored `Ingredient.state`; neither is here.
@MainActor
struct PantryFront {
    /// "4 out, 2 low", "Nothing out", "Nothing yet" (S2, S11, S12).
    let hero: String
    /// "since Saturday's shop" (S1); nil before any shop.
    let context: String?
    /// The OUT and LOW groups; an empty group isn't drawn, not even its label (S8).
    let out: [PantryLedger.Entry]
    let low: [PantryLedger.Entry]
    /// Nothing known yet: the empty body shows (S12).
    let isEmpty: Bool
    /// Tess's line: what the last cook used up (S13); nil otherwise.
    let tess: String?

    init(ledger: PantryLedger, now: Date, calendar: Calendar = .current) {
        let entries = ledger.entries()
        hero = PantryLedger.hero(entries)
        context = PantryCopy.context(lastShop: ledger.lastShop(), now: now, calendar: calendar)
        out = entries.filter { $0.state == .out }
        low = entries.filter { $0.state == .low }
        isEmpty = entries.isEmpty
        tess = ledger.lastCookUsedUp().map { PantryCopy.tess(recipe: $0.recipe, names: $0.names) }
    }

    /// What a left swipe does (S10): add it, or say it's already there (no second row, no UNDO).
    enum Swipe: Equatable {
        case add(receipt: String)
        case already(receipt: String)
    }

    static func swipe(_ entry: PantryLedger.Entry, groceries: Groceries, store: ObjectStore) -> Swipe {
        if isListed(entry.ingredient, groceries: groceries, store: store) {
            return .already(receipt: "\(entry.label), already on Groceries.")
        }
        return .add(receipt: PantryCopy.added(entry.label))
    }

    /// On the list, open or checked: a row in the basket (checked, Done not yet held) covers the add, as it does for a
    /// planned recipe (gap hunt G47). `Groceries.isOn` counts open rows only.
    static func isListed(_ ingredient: ObjectRecord, groceries: Groceries, store: ObjectStore) -> Bool {
        if groceries.isOn(store.displayTitle(of: ingredient)) {
            return true
        }
        guard let list = groceries.list else { return false }
        return ListContents(store: store, classes: groceries.classes).done(in: list).contains { item in
            groceries.ingredient(of: item.object)?.id == ingredient.id
        }
    }
}
