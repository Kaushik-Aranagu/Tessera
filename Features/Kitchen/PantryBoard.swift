import Foundation
import TesseraCore

/// The Pantry by places as data (Design 118, layout C; Kaushik, Oct 22), so the view only draws it. To get is the
/// Groceries list, pinned above the dial and grouped by shop section. Each place lists what is in it: everything he
/// put there (Core's `PantryPlaces`), and, until he puts a thing somewhere, the place its shop section suggests
/// (milk in the fridge door, rice on the shelf). Out and low say so in the hot colour; no amounts are stored yet, so
/// none are shown or guessed. Nothing here is sent to Claude.
@MainActor
struct PantryBoard {
    /// One row on the right half.
    enum Row: Identifiable {
        /// On the Groceries list: its words, its quantity, and whether a recipe asked for it.
        case toGet(ListContents.Item, label: String)
        /// In a place: the ingredient and what the ledger knows of it.
        case stock(PantryLedger.Entry)

        var id: UUID {
            switch self {
            case let .toGet(item, _): item.id
            case let .stock(entry): entry.id
            }
        }
    }

    struct Group {
        let label: String?
        let rows: [Row]
    }

    let toGet: [Group]
    let toGetCount: Int
    let places: [(id: UUID, name: String, groups: [Group], count: Int, low: String?)]

    init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef], label: (ListContents.Item) -> String) {
        let groceries = Groceries(store: store, classes: classes)
        let aisles = groceries.aisles()
        toGet = aisles
            .map { aisle in Group(label: aisle.aisle, rows: aisle.items.map { .toGet($0, label: label($0)) }) }
        toGetCount = aisles.reduce(0) { $0 + $1.items.count }

        let rails = PantryPlaces(store: store, classes: classes)
        let ledger = PantryLedger(store: store, classes: classes)
        let known = ledger.entries()
        var byPlace: [UUID: [(section: String?, entry: PantryLedger.Entry)]] = [:]
        var seen: Set<UUID> = []
        for entry in known {
            seen.insert(entry.id)
            if let place = rails.place(of: entry.ingredient) {
                byPlace[place.id, default: []].append((rails.section(of: entry.ingredient), entry))
            } else if let guess = Self.suggested(entry.aisle) {
                byPlace[guess.place, default: []].append((guess.section, entry))
            }
        }
        // Things he put somewhere that nothing has bought or cooked yet still live there, without a state word.
        for place in rails.places() {
            for ingredient in rails.ingredients(in: place) where !seen.contains(ingredient.id) {
                byPlace[place.id, default: []].append((rails.section(of: ingredient), ledger.entry(for: ingredient)))
            }
        }
        places = rails.places().map { place in
            let words = rails.sections(of: place)
            let shownWords = rails.shownSections(of: place)
            let items = (byPlace[place.id] ?? []).sorted { $0.entry.label < $1.entry.label }
            var groups: [Group] = zip(words, shownWords).compactMap { word, shown in
                let inside = items.filter { $0.section == word }.map { Row.stock($0.entry) }
                return inside.isEmpty ? nil : Group(label: shown, rows: inside)
            }
            let loose = items.filter { item in !words.contains { $0 == item.section } }.map { Row.stock($0.entry) }
            if !loose.isEmpty {
                groups.append(Group(label: nil, rows: loose))
            }
            let low = items.first { $0.entry.state == .low && !$0.entry.isPrivate }?.entry.label.lowercased()
            return (place.id, rails.name(of: place), groups, items.count, low)
        }
    }

    /// "7 to get"; "9 in the fridge · eggs running low"; "14 on the shelf".
    func subtitle(for open: String) -> String {
        if open == PantryPlaces.toGet {
            return toGetCount == 0 ? "nothing to get" : "\(toGetCount) to get"
        }
        guard let place = places.first(where: { $0.id.uuidString == open }) else { return "" }
        let line = "\(place.count) \(Self.where(place.name))"
        return place.low.map { "\(line) · \($0) running low" } ?? line
    }

    /// "in the fridge", "on the shelf", "on the counter", "in the cupboard".
    static func `where`(_ name: String) -> String {
        let word = name.lowercased()
        let on = ["shelf", "counter", "spice rack", "shelves"].contains(word)
        return "\(on ? "on" : "in") the \(word)"
    }

    /// What an empty place says: "Nothing in the fridge yet."
    func empty(for open: String) -> String {
        if open == PantryPlaces.toGet {
            return "Nothing to get. Add things on Groceries."
        }
        let name = places.first { $0.id.uuidString == open }?.name ?? "here"
        return "Nothing \(Self.where(name)) yet."
    }

    /// Where a thing usually lives by its shop section, until he puts it somewhere: one of the four seeded places and
    /// its section. Nil leaves it out of every place (household, other): it never guesses a cupboard he hasn't made.
    static func suggested(_ aisle: Aisle?) -> (place: UUID, section: String?)? {
        let fridge = PantryPlaces.defaultID("fridge"), freezer = PantryPlaces.defaultID("freezer")
        let shelf = PantryPlaces.defaultID("shelf"), counter = PantryPlaces.defaultID("counter")
        switch aisle {
        case .produce: return (fridge, "Drawer")
        case .bakery: return (counter, nil)
        case .dairy, .meatSeafood: return (fridge, "Shelves")
        case .frozen: return (freezer, "Drawers")
        case .cansJars, .pantry, .spices: return (shelf, nil)
        case .household, .other, nil: return nil
        }
    }
}
