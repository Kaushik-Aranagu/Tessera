import Foundation
import TesseraCore

/// A recipe's need against the pantry's have (Pantry state, kitchen-v2 PS): no counting, only In, Low and Out. A line
/// counts when it is something to buy: not a staple, not "to taste", not optional (as Groceries skips them, sheet
/// 67). In and Low are had (Low still has some); Out and anything the pantry hasn't seen are short.
///
/// The engine is Core's (B10 ruling): this reads the app-side `PantryLedger` through `states()`. When Core's pantry
/// state lands, `states()` is the one place its `Ingredient.state` plugs in; nothing else here changes.
struct NeedHave: Equatable {
    /// One recipe line as the pantry sees it.
    struct Line: Equatable {
        let ingredient: UUID?
        /// A line to buy: not a staple, "to taste" or optional.
        let counts: Bool
        let state: PantryLedger.State
    }

    let lines: [Line]

    /// Lines to buy.
    var need: Int {
        lines.count(where: \.counts)
    }

    /// Lines to buy the pantry has, In or Low.
    var have: Int {
        lines.count { $0.counts && ($0.state == .have || $0.state == .low) }
    }

    /// Lines to buy the pantry knows about, whatever their state.
    var known: Int {
        lines.count { $0.counts && $0.state != .unknown }
    }

    /// Lines to buy that are out or unknown.
    var short: Int {
        need - have
    }

    /// "Have 6 of 9."; nil when nothing in it is bought (all staples) or the pantry knows nothing of it.
    var line: String? {
        guard need > 0, known > 0 else { return nil }
        return "Have \(have) of \(need)."
    }

    /// The word at a row's right: "In", "Low", "Out"; nil for a line that isn't bought or that the pantry hasn't seen.
    static func word(for line: Line) -> String? {
        line.counts ? line.state.shownWord : nil
    }

    /// Whether a recipe line is one to buy (Groceries' own skip rule).
    @MainActor
    static func counts(_ line: RecipeBook.Line, store: ObjectStore) -> Bool {
        guard let ingredient = line.ingredient else { return false }
        let staple = line.isStaple || AisleGuide.isStaple(IngredientLine.key(for: store.displayTitle(of: ingredient)))
        return !staple && !line.line.toTaste && !line.line.optional
    }

    /// The recipe's lines against the pantry's states (ingredient id to state; missing is unknown).
    @MainActor
    static func lines(_ lines: [RecipeBook.Line], states: [UUID: PantryLedger.State],
                      store: ObjectStore) -> [Line]
    {
        lines.map { line in
            Line(ingredient: line.ingredient?.id, counts: counts(line, store: store),
                 state: line.ingredient.flatMap { states[$0.id] } ?? .unknown)
        }
    }
}

extension PantryLedger {
    /// Every known ingredient's state, read once (each `entry(for:)` reads every fact again).
    func states() -> [UUID: State] {
        Dictionary(entries().map { ($0.id, $0.state) }, uniquingKeysWith: { first, _ in first })
    }
}

extension PantryLedger.State {
    /// The screen word with Pantry state on (ruling 5, Oct 19): "In", "Low", "Out"; nil when unknown. Ink only.
    var shownWord: String? {
        switch self {
        case .have: "In"
        case .low: "Low"
        case .out: "Out"
        case .unknown: nil
        }
    }
}
