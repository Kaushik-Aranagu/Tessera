import Foundation
import TesseraCore

/// What he has, inferred from what the phone already saw (pantry-acceptance.md §P): a shop clear makes each checked
/// item's ingredient in, with `lastBoughtAt` the check date; a finished cook makes each non-staple ingredient it used
/// low, and Produce out. Nothing is stored, nothing is counted or guessed, and an ingredient nothing has touched is
/// unknown. Time passing never changes a state.
///
/// App-side for now; this is the shape Core lifts into TesseraCore later (one type, read-only, no views touched).
@MainActor
struct PantryLedger {
    /// Out first: the order the page lists them in, and the order of certainty when two facts share an instant.
    enum State: Int, CaseIterable, Comparable {
        case out, low, have, unknown

        static func < (lhs: State, rhs: State) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        /// The state word: "out", "low", "in".
        var word: String {
            switch self {
            case .out: "out"
            case .low: "low"
            case .have: "in"
            case .unknown: "unknown"
            }
        }
    }

    struct Entry: Identifiable {
        let id: UUID
        let ingredient: ObjectRecord
        let state: State
        /// The last shop clear that had it checked; nil when it was never bought through Groceries.
        let lastBoughtAt: Date?
        let aisle: Aisle?
        /// A walled thing (a secret word, money, a body fact, a medicine): every surface reads `label`, never the name
        /// (QA M1 on #722).
        let isPrivate: Bool
        /// What any view, Tess line, widget or Spotlight shows: the name, or "Private item".
        let label: String
    }

    let store: ObjectStore
    let classes: [SystemCatalog.Key: ClassDef]

    /// Every ingredient with a known state, out then low then in, and inside a state in the shop's walk order.
    func entries() -> [Entry] {
        facts().values
            .filter { $0.state != .unknown && !$0.ingredient.isDeleted }
            .sorted { lhs, rhs in
                if lhs.state != rhs.state {
                    return lhs.state < rhs.state
                }
                let left = lhs.aisle.flatMap { Aisle.allCases.firstIndex(of: $0) } ?? Aisle.allCases.count
                let right = rhs.aisle.flatMap { Aisle.allCases.firstIndex(of: $0) } ?? Aisle.allCases.count
                if left != right {
                    return left < right
                }
                return lhs.label < rhs.label
            }
    }

    /// One ingredient's state; unknown when nothing has touched it.
    func entry(for ingredient: ObjectRecord) -> Entry {
        facts()[ingredient.id] ?? make(ingredient, state: .unknown, lastBoughtAt: nil)
    }

    /// The hero, in digits: "4 out, 2 low"; "Nothing out" when things are known but none is out or low; "Nothing yet"
    /// when nothing is known (sheet 78). In is never counted.
    static func hero(_ entries: [Entry]) -> String {
        let out = entries.count { $0.state == .out }, low = entries.count { $0.state == .low }
        let parts = [out > 0 ? "\(out) out" : nil, low > 0 ? "\(low) low" : nil].compactMap(\.self)
        if !parts.isEmpty {
            return parts.joined(separator: ", ")
        }
        return entries.isEmpty ? "Nothing yet" : "Nothing out"
    }

    /// The day of the last shop clear, if there was one.
    func lastShop() -> Date? {
        shopClears().map(\.1).max()
    }

    /// What the last finished cook used up, as it stands now (out or low; private things left out; nil for a private
    /// recipe): the recipe's title and the names, for Tess's line.
    func lastCookUsedUp() -> (recipe: String, names: [String])? {
        guard let cookClass = classes[.cook],
              let cook = store.objects(of: cookClass)
              .filter({ store.value("cookedAt", of: $0)?.dateValue != nil })
              .max(by: { (store.value("cookedAt", of: $0)?.dateValue ?? .distantPast)
                      < (store.value("cookedAt", of: $1)?.dateValue ?? .distantPast)
              }),
              let recipe = store.linkedObjects("recipe", of: cook).first, !recipe.isDeleted
        else { return nil }
        // A private recipe gets no cook line at all: even "Private recipe took ..." names what was in it (Kitchen
        // K89.1, FG9).
        let title = store.displayTitle(of: recipe)
        guard !ObjectPrivacy.isPrivateRecipeTitle(title, lastWeightKg: BodyWeight.lastKg(in: store)) else { return nil }
        let used = Set(RecipeBook(store: store, classes: classes).lines(of: recipe).compactMap(\.ingredient?.id))
        let names = entries().filter { used.contains($0.id) && $0.state != .have && !$0.isPrivate }
            .map { $0.label.lowercased() }
        return names.isEmpty ? nil : (title, names)
    }

    // MARK: - Facts

    private struct Event {
        let when: Date
        let state: State
    }

    /// The latest event wins; at the same instant the surer one does (out, then low, then in).
    private func facts() -> [UUID: Entry] {
        var events: [UUID: [Event]] = [:]
        var bought: [UUID: Date] = [:]
        var ingredients: [UUID: ObjectRecord] = [:]
        // What a private recipe's cook used reads "Private item" (G139): the names would give the recipe away.
        var maskedByCook: Set<UUID> = []
        func note(_ ingredient: ObjectRecord, _ state: State, at date: Date) {
            ingredients[ingredient.id] = ingredient
            events[ingredient.id, default: []].append(Event(when: date, state: state))
        }
        for (ingredient, when) in shopClears() {
            note(ingredient, .have, at: when)
            bought[ingredient.id] = max(bought[ingredient.id] ?? when, when)
        }
        for (ingredient, state, when, fromPrivate) in cookUses() {
            note(ingredient, state, at: when)
            if fromPrivate {
                maskedByCook.insert(ingredient.id)
            }
        }
        return ingredients.mapValues { ingredient in
            let last = (events[ingredient.id] ?? []).max { lhs, rhs in
                lhs.when != rhs.when ? lhs.when < rhs.when : lhs.state > rhs.state
            }
            return make(ingredient, state: last?.state ?? .unknown, lastBoughtAt: bought[ingredient.id],
                        masked: maskedByCook.contains(ingredient.id))
        }
    }

    /// What was bought, as Core reads it (G45): the rows a shop clear took off Groceries (never a row deleted
    /// another way, nor a clear that was undone), plus a basket put away to Later (Product 9:45 AM, ruling 5).
    private func shopClears() -> [(ObjectRecord, Date)] {
        let groceries = Groceries(store: store, classes: classes)
        return (groceries.shopClears() + groceries.putAwayBasket()).map { ($0.ingredient, $0.at) }
    }

    /// What finished cooks used: each non-staple ingredient low, Produce out.
    private func cookUses() -> [(ObjectRecord, State, Date, Bool)] {
        guard let cookClass = classes[.cook] else { return [] }
        let book = RecipeBook(store: store, classes: classes)
        return store.objects(of: cookClass).flatMap { cook -> [(ObjectRecord, State, Date, Bool)] in
            guard let when = store.value("cookedAt", of: cook)?.dateValue,
                  let recipe = store.linkedObjects("recipe", of: cook).first, !recipe.isDeleted
            else { return [] }
            let fromPrivate = ObjectPrivacy.label(of: recipe, in: store, classes: classes) != nil
            return book.lines(of: recipe).compactMap { line in
                // Optional and to-taste lines aren't counted as used (QA on #722).
                guard let ingredient = line.ingredient, !line.isStaple, !line.line.optional, !line.line.toTaste,
                      !isStaple(ingredient)
                else { return nil }
                return (ingredient, aisle(of: ingredient) == .produce ? .out : .low, when, fromPrivate)
            }
        }
    }

    private func make(_ ingredient: ObjectRecord, state: State, lastBoughtAt: Date?, masked: Bool = false) -> Entry {
        let title = store.displayTitle(of: ingredient)
        // The one private-title check (G105, G140), or an ingredient only a private cook used (G139).
        let walled = masked || ObjectPrivacy.isPrivateTitle(title, lastWeightKg: BodyWeight.lastKg(in: store))
        return Entry(id: ingredient.id, ingredient: ingredient, state: state, lastBoughtAt: lastBoughtAt,
                     aisle: aisle(of: ingredient), isPrivate: walled, label: walled ? "Private item" : title)
    }

    /// Staples are never low or out by cooking: the ingredient's own flag, or the shop guide's staples (as Groceries).
    private func isStaple(_ ingredient: ObjectRecord) -> Bool {
        store.value("isStaple", of: ingredient) == .bool(true)
            || AisleGuide.isStaple(IngredientLine.key(for: store.displayTitle(of: ingredient)))
    }

    private func aisle(of ingredient: ObjectRecord) -> Aisle? {
        store.value("aisle", of: ingredient)?.stringValue.flatMap(Aisle.init(rawValue:))
            ?? AisleGuide.aisle(for: store.displayTitle(of: ingredient))
    }
}
