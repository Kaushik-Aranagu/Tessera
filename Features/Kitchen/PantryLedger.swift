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
                return store.displayTitle(of: lhs.ingredient) < store.displayTitle(of: rhs.ingredient)
            }
    }

    /// One ingredient's state; unknown when nothing has touched it.
    func entry(for ingredient: ObjectRecord) -> Entry {
        facts()[ingredient.id] ?? Entry(id: ingredient.id, ingredient: ingredient, state: .unknown, lastBoughtAt: nil,
                                        aisle: aisle(of: ingredient))
    }

    /// "4 out, 2 low", or "nothing known yet". In is never counted on the line.
    static func countsLine(_ entries: [Entry]) -> String {
        let out = entries.count { $0.state == .out }, low = entries.count { $0.state == .low }
        let parts = [out > 0 ? "\(out) out" : nil, low > 0 ? "\(low) low" : nil].compactMap(\.self)
        if !parts.isEmpty {
            return parts.joined(separator: ", ")
        }
        return entries.isEmpty ? "nothing known yet" : "nothing out"
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
        func note(_ ingredient: ObjectRecord, _ state: State, at date: Date) {
            ingredients[ingredient.id] = ingredient
            events[ingredient.id, default: []].append(Event(when: date, state: state))
        }
        for (ingredient, when) in shopClears() {
            note(ingredient, .have, at: when)
            bought[ingredient.id] = max(bought[ingredient.id] ?? when, when)
        }
        for (ingredient, state, when) in cookUses() {
            note(ingredient, state, at: when)
        }
        return ingredients.mapValues { ingredient in
            let last = (events[ingredient.id] ?? []).max { lhs, rhs in
                lhs.when != rhs.when ? lhs.when < rhs.when : lhs.state > rhs.state
            }
            return Entry(id: ingredient.id, ingredient: ingredient, state: last?.state ?? .unknown,
                         lastBoughtAt: bought[ingredient.id], aisle: aisle(of: ingredient))
        }
    }

    /// Checked items a shop clear took off Groceries: soft-deleted, done, with the date they were checked.
    private func shopClears() -> [(ObjectRecord, Date)] {
        guard let list = store.object(id: Groceries.listID) else { return [] }
        let groceries = Groceries(store: store, classes: classes)
        return (list.children ?? []).compactMap { item in
            guard item.isDeleted, store.value("isDone", of: item) == .bool(true),
                  let when = store.value("checkedAt", of: item)?.dateValue,
                  let ingredient = groceries.ingredient(of: item)
            else { return nil }
            return (ingredient, when)
        }
    }

    /// What finished cooks used: each non-staple ingredient low, Produce out.
    private func cookUses() -> [(ObjectRecord, State, Date)] {
        guard let cookClass = classes[.cook] else { return [] }
        let book = RecipeBook(store: store, classes: classes)
        return store.objects(of: cookClass).flatMap { cook -> [(ObjectRecord, State, Date)] in
            guard let when = store.value("cookedAt", of: cook)?.dateValue,
                  let recipe = store.linkedObjects("recipe", of: cook).first
            else { return [] }
            return book.lines(of: recipe).compactMap { line in
                guard let ingredient = line.ingredient, !line.isStaple, !isStaple(ingredient) else { return nil }
                return (ingredient, aisle(of: ingredient) == .produce ? .out : .low, when)
            }
        }
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
