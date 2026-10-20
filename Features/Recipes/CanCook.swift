import Foundation
import TesseraCore

/// What can I cook (sheet 104 section 2, kitchen-v2 CC): the CAN COOK shelf on Recipes, ranked by what is missing,
/// ties by not cooked lately. A recipe is judged only when the pantry knows at least 60% of its lines to buy and at
/// least 3 of them (G209); below that bar it waits in "N to check" when something of it is known. Staples, "to taste"
/// and optional lines never count. Counts only: "Ready", "1 short", "2 short"; never a percent, never what is missing.
///
/// The engine is Core's (B10 ruling): the ranking reads `NeedHave` built from the app-side pantry. When Core's
/// can-cook count lands, `Candidate` is the shape it fills; the shelf view doesn't change.
struct CanCook: Equatable {
    /// One recipe as the ranking sees it.
    struct Candidate: Equatable {
        let id: UUID
        /// The name, or "Private recipe".
        let name: String
        let isPrivate: Bool
        let need: Int
        let have: Int
        let known: Int
        let lastCooked: Date?
        /// Its place on the shelf (newest first), the last tie-break, so a private recipe never ranks by name.
        let order: Int

        var short: Int {
            need - have
        }
    }

    struct Row: Identifiable, Equatable {
        let id: UUID
        let name: String
        let isPrivate: Bool
        /// "Ready", "1 short", "2 short"; nil for a row in "to check".
        let word: String?
    }

    /// Six rows a page (sheet 90).
    static let pageSize = 6
    /// Nothing beyond 2 short shows (sheet 104).
    static let mostShort = 2

    /// Ready first, then 1 short, then 2 short.
    let judged: [Row]
    /// Below the bar, with something known (CC-E2).
    let toCheck: [Row]

    init(_ candidates: [Candidate]) {
        let ranked = candidates.filter { $0.need > 0 && Self.isJudged(need: $0.need, known: $0.known) }
            .filter { $0.short <= Self.mostShort }
            .sorted(by: Self.ranks)
        judged = ranked.map { Row(id: $0.id, name: $0.name, isPrivate: $0.isPrivate, word: Self.word(short: $0.short)) }
        toCheck = candidates.filter { $0.need > 0 && $0.known > 0 && !Self.isJudged(need: $0.need, known: $0.known) }
            .sorted { $0.order < $1.order }
            .map { Row(id: $0.id, name: $0.name, isPrivate: $0.isPrivate, word: nil) }
    }

    /// G209: at least 60% of the lines to buy known, and at least 3 (staples never count, CC-E4).
    static func isJudged(need: Int, known: Int) -> Bool {
        known >= 3 && known * 10 >= need * 6
    }

    /// Fewest short first; then the one cooked longest ago (never cooked first); then the shelf's own order.
    static func ranks(_ lhs: Candidate, _ rhs: Candidate) -> Bool {
        if lhs.short != rhs.short {
            return lhs.short < rhs.short
        }
        switch (lhs.lastCooked, rhs.lastCooked) {
        case (nil, .some): return true
        case (.some, nil): return false
        case let (left?, right?) where left != right: return left < right
        default: return lhs.order < rhs.order
        }
    }

    static func word(short: Int) -> String {
        short == 0 ? "Ready" : "\(short) short"
    }

    /// The empty shelf's line (sheet 104).
    static let empty = "Nothing is ready yet."

    /// "2 to check" (sheet 114 section 7).
    static func toCheckHeading(_ count: Int) -> String {
        "\(count) to check"
    }

    /// The shelf read from the store: every recipe against the pantry.
    @MainActor
    init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef], states: [UUID: PantryLedger.State]) {
        let book = RecipeBook(store: store, classes: classes)
        let log = CookLog(store: store, classes: classes)
        let weight = BodyWeight.lastKg(in: store)
        let recipes = book.recipes().filter { !$0.isDeleted }.sorted { $0.createdAt > $1.createdAt }
        self.init(recipes.enumerated().map { index, recipe in
            let title = store.displayTitle(of: recipe)
            let isPrivate = ObjectPrivacy.isPrivateRecipeTitle(title, lastWeightKg: weight)
            let needHave = NeedHave(lines: NeedHave.lines(book.lines(of: recipe), states: states, store: store))
            return Candidate(id: recipe.id, name: isPrivate ? ObjectPrivacy.recipeLabel : title, isPrivate: isPrivate,
                             need: needHave.need, have: needHave.have, known: needHave.known,
                             lastCooked: log.lastCooked(recipe), order: index)
        })
    }
}
