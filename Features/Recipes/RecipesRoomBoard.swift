import Foundation
import TesseraCore

/// The Recipes room as data (sheet 233 v5), so the view only draws it: each recipe with how ready it is, in the four
/// lenses of the dial (Ready now, One short, Planned, All), quickest first with pinned ones on top. A private recipe is
/// only ever "Private recipe", and a walled ingredient only "Private item", in every line built here.
@MainActor
struct RecipesRoomBoard {
    enum Lens: String, CaseIterable, Identifiable {
        case ready = "Ready now", oneShort = "One short", planned = "Planned", all = "All"

        var id: String {
            rawValue
        }
    }

    struct Item: Identifiable, Equatable {
        let id: UUID
        /// The real name (the room only) and the label every outside line uses.
        let name: String
        let shown: String
        let isPrivate: Bool
        let minutes: Int?
        let isPinned: Bool
        /// The things it lacks, as shown names ("feta").
        let shorts: [String]
        /// The ingredients it uses that are running low ("milk").
        let lows: [String]
        /// Its first ingredients, as shown names.
        let uses: [String]
        let plannedFor: Date?

        var isReady: Bool {
            shorts.isEmpty
        }

        /// "5 min" (calories join this line once Core has the table).
        var detailOne: String {
            minutes.map { "\($0) min" } ?? ""
        }

        /// "needs feta", "milk low", "lemons, spaghetti and 4 more".
        var detailTwo: String {
            RecipesRoomBoard.detail(shorts: shorts, lows: lows, uses: uses)
        }
    }

    let items: [Item]
    let toGetCount: Int

    init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef], now: Date) {
        let book = RecipeBook(store: store, classes: classes)
        let ledger = PantryLedger(store: store, classes: classes)
        let weight = BodyWeight.lastKg(in: store)
        var stock: [String: RecipeStock.Entry] = [:]
        var lowKeys: Set<String> = []
        for entry in ledger.entries() {
            let key = IngredientLine.key(for: store.displayTitle(of: entry.ingredient))
            stock[key] = RecipeStock.Entry(entry.state == .out ? .out : .inStock)
            if entry.state == .low {
                lowKeys.insert(key)
            }
        }
        let pins = PantryStock(store: store, classes: classes).pinnedRecipes().map(\.id)
        let planned = Self.planned(store: store, classes: classes, now: now)
        let built: [Item] = book.recipes().filter { !$0.isDeleted }.map { recipe in
            let title = store.displayTitle(of: recipe)
            let isPrivate = ObjectPrivacy.isPrivateRecipeTitle(title, lastWeightKg: weight)
            let lines = book.lines(of: recipe)
            let rows = RecipeStock.rows(lines: lines.map(\.line), recipeServes: book.serves(recipe) ?? 2,
                                        serves: book.serves(recipe) ?? 2, stock: stock)
            let shorts = RecipeStock.shortNames(rows) { ObjectPrivacy.isPrivateWord($0, in: store) }
            let lows = rows.filter { lowKeys.contains($0.key) }.map { Self.said($0.line.name, store: store) }
            let uses = lines.prefix(3).map { Self.said($0.line.name, store: store) }
            return Item(id: recipe.id, name: isPrivate ? ObjectPrivacy.recipeLabel : title,
                        shown: isPrivate ? ObjectPrivacy.recipeLabel : KitchenText
                            .short(RecipeBook.shortName(ofTitle: title)),
                        isPrivate: isPrivate, minutes: book.totalMinutes(recipe).map { Int($0.rounded()) },
                        isPinned: pins.contains(recipe.id), shorts: shorts.map { $0.lowercased() },
                        lows: lows.map { $0.lowercased() }, uses: uses.map { $0.lowercased() },
                        plannedFor: planned[recipe.id])
        }
        items = Self.ordered(built, pinOrder: pins)
        toGetCount = Groceries(store: store, classes: classes).aisles().reduce(0) { $0 + $1.items.count }
    }

    private static func said(_ name: String, store: ObjectStore) -> String {
        ObjectPrivacy.isPrivateWord(name, in: store) ? "Private item" : name
    }

    /// When each recipe is next planned (an occasion that links it, today or later).
    private static func planned(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef], now: Date) -> [UUID: Date] {
        guard let occasionClass = classes[.occasion] else { return [:] }
        let start = TesseraDay(calendar: .current).start(of: now)
        var out: [UUID: Date] = [:]
        for occasion in store.objects(of: occasionClass) where !occasion.isDeleted {
            guard let day = store.value("start", of: occasion)?.dateValue, day >= start else { continue }
            for recipe in store.linkedObjects("links", of: occasion) {
                out[recipe.id] = min(out[recipe.id] ?? day, day)
            }
        }
        return out
    }

    // MARK: Pure rules

    /// Pinned ones first (in the order pinned), then quickest first; a recipe with no time goes last.
    static func ordered(_ items: [Item], pinOrder: [UUID]) -> [Item] {
        let pinned = pinOrder.compactMap { id in items.first { $0.id == id } }
        let rest = items.filter { item in !pinOrder.contains(item.id) }
            .sorted { ($0.minutes ?? .max, $0.shown) < ($1.minutes ?? .max, $1.shown) }
        return pinned + rest
    }

    func items(in lens: Lens) -> [Item] {
        switch lens {
        case .ready: items.filter(\.isReady)
        case .oneShort: items.filter { $0.shorts.count == 1 }
        case .planned: items.filter { $0.plannedFor != nil }
            .sorted { ($0.plannedFor ?? .distantFuture) < ($1.plannedFor ?? .distantFuture) }
        case .all: items
        }
    }

    func count(_ lens: Lens) -> Int {
        items(in: lens).count
    }

    /// The second detail line: what it needs, else what is running low in it, else what it uses.
    static func detail(shorts: [String], lows: [String], uses: [String]) -> String {
        if !shorts.isEmpty {
            switch shorts.count {
            case 1: return "needs \(shorts[0])"
            case 2: return "needs \(shorts[0]) and \(shorts[1])"
            default: return "needs \(shorts[0]) and \(shorts.count - 1) more"
            }
        }
        if let low = lows.first {
            return "\(low) low"
        }
        switch uses.count {
        case 0: return ""
        case 1: return uses[0]
        case 2, 3: return uses.dropLast().joined(separator: ", ") + " and " + uses[uses.count - 1]
        default: return uses.prefix(2).joined(separator: ", ") + " and \(uses.count - 2) more"
        }
    }

    /// "Fried rice is the quickest, 20 min." / "Lemon pasta uses the lemons."
    static func brief(_ ready: [Item]) -> (first: String, second: String) {
        guard let quick = ready.first(where: { $0.minutes != nil && !$0.isPrivate }) ?? ready.first else {
            return ("Nothing is ready yet.", "")
        }
        let first = quick.minutes.map { "\(quick.shown) is the quickest, \($0) min." } ?? "\(quick.shown) is ready."
        guard let user = ready.first(where: { !$0.lows.isEmpty && $0.id != quick.id }) ?? ready
            .first(where: { !$0.lows.isEmpty && !$0.isPrivate }),
            let low = user.lows.first
        else { return (first, "") }
        return (first, "\(user.shown) uses the \(low).")
    }

    /// The foot's word for the focused recipe: Cook now, Get it, Get 2 things.
    static func footWord(shorts: Int) -> String {
        switch shorts {
        case 0: "Cook now"
        case 1: "Get it"
        default: "Get \(shorts) things"
        }
    }

    /// "7 you can make now, quickest first".
    static func sectionLine(_ lens: Lens, count: Int) -> String {
        switch lens {
        case .ready: "\(count) you can make now, quickest first"
        case .oneShort: "\(count) one short, quickest first"
        case .planned: "\(count) planned"
        case .all: "\(count) \(count == 1 ? "recipe" : "recipes"), quickest first"
        }
    }

    /// "Feta and mascarpone, on To get."
    static func getReceipt(_ names: [String]) -> String {
        let head = names.count == 1 ? names[0] : names.dropLast()
            .joined(separator: ", ") + " and " + names[names.count - 1]
        return head.prefix(1).uppercased() + head.dropFirst() + ", on \(PantryPlaces.toGet)."
    }
}
