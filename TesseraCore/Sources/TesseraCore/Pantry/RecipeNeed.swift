import Foundation

/// What a recipe needs that the pantry does not say he has (Pantry v2 spec, section c). Pure over lines and a state
/// lookup: it never reads amounts or serves, so a size change cannot change what is missing.
@MainActor
public struct RecipeNeed {
    public struct Line {
        public let ingredient: ObjectRecord
        /// The name any string may print: "Private item" for a walled ingredient.
        public let label: String
    }

    /// Told to be out.
    public let out: [Line]
    /// Nothing says either way ("to check"): opens the ingredient, adds nothing.
    public let unknown: [Line]
    /// Low is not missing, but the recipe page can say it.
    public let low: [Line]
    /// A private recipe gives counts and no names (K89.1, R13).
    public let hidesNames: Bool
    /// A recipe with no ingredient lines is not judged: never cookable (R16).
    public let isJudged: Bool
    /// The lines counted (not staple, optional or to taste) and how many of them have a known state.
    public let counted: Int
    public let known: Int

    /// Enough is known for the CAN COOK word to stop being grey for this recipe (G209): at least 60% of the counted
    /// lines, never fewer than 3 (a short recipe needs every line known). It does not change the order.
    public var isTrusted: Bool {
        guard isJudged, counted > 0 else { return false }
        return known >= min(counted, max(3, Int((Double(counted) * 0.6).rounded(.up))))
    }

    /// Missing and to check together: 0 is "can cook now".
    public var score: Int {
        out.count + unknown.count
    }

    /// The names a line may print: none for a private recipe.
    public var outNames: [String] {
        hidesNames ? [] : out.map(\.label)
    }

    public var unknownNames: [String] {
        hidesNames ? [] : unknown.map(\.label)
    }
}

public extension RecipeMath {
    /// The need of a recipe's lines. Staples, "to taste" and optional lines are skipped; a line with no ingredient is
    /// skipped; one ingredient on two lines counts once; `in` and `low` are not missing; `out` is missing; unknown, or
    /// a deleted ingredient, is "to check".
    @MainActor
    static func missing(lines: [RecipeBook.Line], state: (ObjectRecord) -> PantryState,
                        isPrivateIngredient: (ObjectRecord) -> Bool, hidesNames: Bool = false) -> RecipeNeed
    {
        var seen = Set<UUID>()
        var out: [RecipeNeed.Line] = [], unknown: [RecipeNeed.Line] = [], low: [RecipeNeed.Line] = []
        var counted = 0, known = 0
        for line in lines {
            guard let ingredient = line.ingredient, !line.isStaple, !line.line.toTaste, !line.line.optional,
                  seen.insert(ingredient.id).inserted else { continue }
            let shown = RecipeNeed.Line(
                ingredient: ingredient,
                label: isPrivateIngredient(ingredient) ? "Private item" : ingredient.title
            )
            counted += 1
            switch ingredient.isDeleted ? PantryState.unknown : state(ingredient) {
            case .out: out.append(shown); known += 1
            case .low: low.append(shown); known += 1
            case .unknown: unknown.append(shown)
            case .have: known += 1
            }
        }
        return RecipeNeed(out: out, unknown: unknown, low: low, hidesNames: hidesNames, isJudged: !lines.isEmpty,
                          counted: counted, known: known)
    }
}

/// One recipe on the CAN COOK shelf.
@MainActor
public struct CookCandidate {
    public let recipe: ObjectRecord
    public let need: RecipeNeed
    /// The newest finished cook, nil when never cooked.
    public let lastCooked: Date?
}

public extension PantryBook {
    /// A recipe's need from the state the pantry knows. A private recipe gives counts and no names.
    func need(for recipe: ObjectRecord) -> RecipeNeed {
        let book = RecipeBook(store: store, classes: classes)
        let privateRecipe = ObjectPrivacy.label(of: recipe, in: store, classes: classes) != nil
        return RecipeMath.missing(
            lines: book.lines(of: recipe),
            state: { entry(for: $0).state },
            isPrivateIngredient: { entry(for: $0).isPrivate },
            hidesNames: privateRecipe
        )
    }

    /// The recipes in CAN COOK order: fewest missing (out plus to check) first, then fewest out, then not cooked
    /// lately (never cooked first, then the oldest cook). A recipe with no lines goes after the rest.
    func canCook(_ recipes: [ObjectRecord]) -> [CookCandidate] {
        let book = RecipeBook(store: store, classes: classes)
        let all = recipes.map { CookCandidate(recipe: $0, need: need(for: $0), lastCooked: book.lastCooked($0)) }
        return all.sorted { lhs, rhs in
            if lhs.need.isJudged != rhs.need.isJudged {
                return lhs.need.isJudged
            }
            if lhs.need.score != rhs.need.score {
                return lhs.need.score < rhs.need.score
            }
            if lhs.need.out.count != rhs.need.out.count {
                return lhs.need.out.count < rhs.need.out.count
            }
            return (lhs.lastCooked ?? .distantPast) < (rhs.lastCooked ?? .distantPast)
        }
    }

    /// "N you can cook now": recipes with nothing missing and nothing to check (a number only; private ones count).
    func cookableCount(_ recipes: [ObjectRecord]) -> Int {
        recipes.count { need(for: $0).isJudged && need(for: $0).score == 0 }
    }
}
