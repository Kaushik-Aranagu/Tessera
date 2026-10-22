import Foundation

/// What the pantry says about one recipe at a size: which lines he has, which are short, which cannot be judged
/// (Kitchen have/short, PR 2, engine only). Computed on demand from the lines and a stock table the caller hands in;
/// nothing is stored and nothing syncs. The stock table is his pantry's state and never goes to Claude, a log, a
/// backup or a widget: a private recipe's speech reads "Private recipe" and carries no line.
public enum RecipeStock {
    /// What the pantry knows about one thing, by `IngredientLine.key(for:)`.
    public struct Entry: Sendable, Equatable {
        public enum State: Sendable, Equatable {
            case inStock, out
        }

        public let state: State
        /// How much is there, when he told it; compared only with an amount of the same dimension.
        public let amount: Double?
        public let unit: KitchenUnit?

        public init(_ state: State, amount: Double? = nil, unit: KitchenUnit? = nil) {
            self.state = state
            self.amount = amount
            self.unit = unit
        }
    }

    public enum Verdict: Sendable, Equatable {
        case have
        /// `n` more of the recipe's unit when the difference can be worked out, else one line.
        case short(Short)
        /// The pantry has nothing on this: never short, never added.
        case check
        /// A staple, "to taste", optional or "for serving" line: not judged.
        case skipped
    }

    public struct Short: Sendable, Equatable {
        public let amount: Double?
        public let unit: KitchenUnit?

        /// 1 for a line with no difference to work out.
        public var count: Double {
            amount ?? 1
        }
    }

    public struct Row: Sendable, Equatable {
        public let line: IngredientLine
        /// The one key everywhere ("Eggs" and "egg" are egg; "chopped fresh cilantro" is cilantro).
        public let key: String
        public let verdict: Verdict
    }

    /// Each line of the recipe at `serves` (from `recipeServes`), in the recipe's order.
    public static func rows(lines: [IngredientLine], recipeServes: Int, serves: Int, stock: [String: Entry],
                            isStaple: (String) -> Bool = { AisleGuide.isStaple($0) }) -> [Row]
    {
        let scaled = RecipeMath.scaled(lines, from: recipeServes, to: serves)
        return scaled.map { line in
            let key = IngredientLine.key(for: line.name)
            if line.toTaste || line.optional || isStaple(key) {
                return Row(line: line, key: key, verdict: .skipped)
            }
            return Row(line: line, key: key, verdict: verdict(for: line, entry: stock[key]))
        }
    }

    static func verdict(for line: IngredientLine, entry: Entry?) -> Verdict {
        guard let entry else { return .check }
        switch entry.state {
        case .out:
            return .short(Short(amount: nil, unit: nil))
        case .inStock:
            guard let need = line.amount, let have = entry.amount else { return .have }
            // Comparable: the same unit, or two units of one dimension that convert (cups against ml).
            if let unit = line.unit, entry.unit == unit {
                return have >= need ? .have : .short(Short(amount: difference(need, have, unit), unit: unit))
            }
            guard let unit = line.unit, let haveUnit = entry.unit, haveUnit.dimension == unit.dimension,
                  unit.dimension != .count, let needMetric = line.metricAmount,
                  let haveFactor = haveUnit.metricFactor, let unitFactor = unit.metricFactor else { return .have }
            let haveMetric = have * haveFactor
            if haveMetric >= needMetric {
                return .have
            }
            return .short(Short(amount: difference(needMetric / unitFactor, haveMetric / unitFactor, unit), unit: unit))
        }
    }

    /// The gap in the recipe's unit, to the same rounding a recipe line is shown at.
    static func difference(_ need: Double, _ have: Double, _ unit: KitchenUnit) -> Double {
        RecipeMath.round(need - have, unit: unit)
    }

    /// The names of the lines that are short, in order ("lemon", "rice"). A walled line (a medicine, a body fact,
    /// money)
    /// reads "Private item", whatever recipe it sits in: it is masked before the sentence is built.
    public static func shortNames(_ rows: [Row], isPrivateWord: (String) -> Bool = { _ in false }) -> [String] {
        rows.compactMap { row in
            guard case .short = row.verdict else { return nil }
            return isPrivateWord(row.line.name) || isPrivateWord(row.line.original) ? privateItem
                : row.line.name.lowercased()
        }
    }

    public static let privateItem = "Private item"

    /// "a and b", "a, b and c", "a, b and 2 more".
    static func join(_ names: [String]) -> String {
        switch names.count {
        case 0: ""
        case 1: names[0]
        case 2: "\(names[0]) and \(names[1])"
        case 3: "\(names[0]), \(names[1]) and \(names[2])"
        default: "\(names[0]), \(names[1]) and \(names.count - 2) more"
        }
    }

    /// One line a screen or Tess may say. A private recipe says only "Private recipe".
    public static func speech(_ rows: [Row], recipeIsPrivate: Bool, isPrivateWord: (String) -> Bool = { _ in false })
        -> String
    {
        if recipeIsPrivate {
            return "Private recipe"
        }
        let names = shortNames(rows, isPrivateWord: isPrivateWord)
        return names.isEmpty ? "Nothing is short." : "Short on \(join(names))."
    }
}

public extension RecipeStock {
    /// `speech` with the store's own private-word rule.
    @MainActor
    static func speech(_ rows: [Row], recipeIsPrivate: Bool, in store: ObjectStore) -> String {
        speech(rows, recipeIsPrivate: recipeIsPrivate) { ObjectPrivacy.isPrivateWord($0, in: store) }
    }
}
