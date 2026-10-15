import Foundation

/// A unit an ingredient amount is written in. Metric units convert; spoons and cups stay as written, with a
/// metric equivalent on request; counted units (clove, pinch, can) don't convert.
public enum KitchenUnit: String, Sendable, Codable, CaseIterable {
    case gram = "g", kilogram = "kg", millilitre = "ml", litre = "l"
    case teaspoon = "tsp", tablespoon = "tbsp", cup
    case clove, pinch, handful, bunch, can, slice, sprig, piece, stick, head

    public enum Dimension: Sendable { case mass, volume, count }

    public var dimension: Dimension {
        switch self {
        case .gram, .kilogram: .mass
        case .millilitre, .litre, .teaspoon, .tablespoon, .cup: .volume
        default: .count
        }
    }

    /// Grams or millilitres per one of this unit (nil for counted units).
    public var metricFactor: Double? {
        switch self {
        case .gram, .millilitre: 1
        case .kilogram, .litre: 1000
        case .teaspoon: 5
        case .tablespoon: 15
        case .cup: 240
        default: nil
        }
    }

    /// Spoons and cups are kept as written (metric only on request).
    public var isKeptAsWritten: Bool {
        self == .teaspoon || self == .tablespoon || self == .cup
    }

    static let words: [String: KitchenUnit] = [
        "g": .gram, "gram": .gram, "grams": .gram, "gr": .gram,
        "kg": .kilogram, "kilo": .kilogram, "kilos": .kilogram, "kilogram": .kilogram, "kilograms": .kilogram,
        "ml": .millilitre, "millilitre": .millilitre, "millilitres": .millilitre, "milliliter": .millilitre,
        "milliliters": .millilitre,
        "l": .litre, "litre": .litre, "litres": .litre, "liter": .litre, "liters": .litre,
        "tsp": .teaspoon, "teaspoon": .teaspoon, "teaspoons": .teaspoon, "t": .teaspoon,
        "tbsp": .tablespoon, "tablespoon": .tablespoon, "tablespoons": .tablespoon, "tbs": .tablespoon,
        "cup": .cup, "cups": .cup,
        "clove": .clove, "cloves": .clove, "pinch": .pinch, "pinches": .pinch,
        "handful": .handful, "handfuls": .handful, "bunch": .bunch, "bunches": .bunch,
        "can": .can, "cans": .can, "tin": .can, "tins": .can,
        "slice": .slice, "slices": .slice, "sprig": .sprig, "sprigs": .sprig, "stick": .stick, "sticks": .stick,
        "head": .head, "heads": .head,
    ]

    public init?(word: String) {
        // In recipes a capital T is a tablespoon and a small t a teaspoon.
        if word == "T" || word == "T." {
            self = .tablespoon
            return
        }
        guard let unit = Self.words[word.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))] else {
            return nil
        }
        self = unit
    }
}

/// One line of a recipe's ingredients, read into parts: "2–3 cloves garlic, crushed" → 2...3 clove "garlic",
/// prep "crushed". The text is kept as written in `original`.
public struct IngredientLine: Hashable, Sendable, Codable {
    public var original: String
    public var amount: Double?
    /// The top of a range ("2–3"), else nil.
    public var amountMax: Double?
    public var unit: KitchenUnit?
    public var name: String
    public var prep: String?
    public var toTaste: Bool

    public init(original: String, amount: Double? = nil, amountMax: Double? = nil, unit: KitchenUnit? = nil,
                name: String, prep: String? = nil, toTaste: Bool = false)
    {
        self.original = original
        self.amount = amount
        self.amountMax = amountMax
        self.unit = unit
        self.name = name
        self.prep = prep
        self.toTaste = toTaste
    }

    /// The amount in grams or millilitres, when the unit converts.
    public var metricAmount: Double? {
        guard let amount, let factor = unit?.metricFactor else { return nil }
        return amount * factor
    }

    /// "15 ml" for "1 tbsp" (what a tap shows); nil when there's nothing to convert.
    public var metricText: String? {
        guard let unit, unit.isKeptAsWritten, let metric = metricAmount else { return nil }
        return "\(Self.format(metric)) ml"
    }

    /// The parser: amounts (whole, decimal, fractions, unicode fractions, ranges), an optional unit (also
    /// attached, "200g"), an optional "of", the name, then prep after a comma. "salt to taste" and "a handful of
    /// basil" read as you'd expect. Returns nil for an empty line.
    public static func parse(_ text: String) -> IngredientLine? {
        let original = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var rest = Self.clean(original)
        guard !rest.isEmpty else { return nil }

        var toTaste = false
        if let match = rest.firstMatch(of: /(?i),?\s*(to taste|as needed|to serve)\s*$/) {
            toTaste = match.1.lowercased() == "to taste"
            rest.removeSubrange(match.range)
        }

        var amount: Double?
        var amountMax: Double?
        // "a" / "an" / "one" as an amount only when a unit follows ("a pinch of salt", not "an onion").
        if let match = rest.firstMatch(of: /(?i)^(?:a|an)\s+(\p{L}+)\b/), KitchenUnit(word: String(match.1)) != nil {
            amount = 1
            rest = String(rest[match.1.startIndex...])
        } else if let match = rest.firstMatch(
            of: /^(\d+\s+\d+\/\d+|\d+\/\d+|\d+(?:[.,]\d+)?)(?:\s*(?:-|–|to)\s*(\d+\s+\d+\/\d+|\d+\/\d+|\d+(?:[.,]\d+)?))?/
        ) {
            amount = Self.number(String(match.1))
            amountMax = match.2.flatMap { Self.number(String($0)) }
            rest = String(rest[match.range.upperBound...])
        } else if let match = rest.firstMatch(of: /(?i)^an?\s+/) {
            amount = 1
            rest = String(rest[match.range.upperBound...])
        }
        rest = rest.trimmingCharacters(in: .whitespaces)

        var unit: KitchenUnit?
        if amount != nil, let match = rest.firstMatch(of: /^(\p{L}+\.?)(?=\s|$|\))/),
           let parsed = KitchenUnit(word: String(match.1))
        {
            unit = parsed
            rest = String(rest[match.range.upperBound...]).trimmingCharacters(in: .whitespaces)
        }
        if let match = rest.firstMatch(of: /(?i)^of\s+/) {
            rest = String(rest[match.range.upperBound...])
        }
        // A parenthetical ("(400 g)") is a note on the amount, not part of the name.
        rest = rest.replacing(/\s*\([^)]*\)/, with: "")

        var prep: String?
        if let comma = rest.firstIndex(of: ",") {
            let after = rest[rest.index(after: comma)...].trimmingCharacters(in: .whitespaces)
            prep = after.isEmpty ? nil : after
            rest = String(rest[..<comma])
        }
        var name = rest.trimmingCharacters(in: .whitespaces)
        // Size and freshness words describe this one, not the ingredient: "1 large onion" is an onion.
        var sizes: [String] = []
        while let match = name
            .firstMatch(of: /(?i)^(large|small|medium|big|fresh|ripe|cooked|extra[- ]large)\s+(.+)$/)
        {
            sizes.append(match.1.lowercased())
            name = String(match.2)
        }
        if !sizes.isEmpty {
            let size = sizes.joined(separator: " ")
            prep = prep.map { "\(size), \($0)" } ?? size
        }
        // "2 garlic cloves" is 2 cloves of garlic: a trailing unit word moves to the unit.
        if unit == nil, amount != nil,
           let match = name.firstMatch(of: /(?i)^(.+?)\s+(cloves?|sprigs?|sticks?|heads?|slices?)$/),
           let trailing = KitchenUnit(word: String(match.2))
        {
            unit = trailing
            name = String(match.1)
        }
        guard !name.isEmpty else { return nil }
        return IngredientLine(original: original, amount: amount, amountMax: amountMax, unit: unit, name: name,
                              prep: prep, toTaste: toTaste)
    }

    /// The name reduced for matching: lowercased, simple plurals made singular ("tomatoes" → "tomato").
    public static func key(for name: String) -> String {
        name.lowercased().split(separator: " ").map { singular(String($0)) }.joined(separator: " ")
    }

    static func singular(_ word: String) -> String {
        if ["cookies", "brownies", "smoothies", "veggies", "movies", "pies"].contains(word) {
            return String(word.dropLast())
        }
        if word.hasSuffix("ies"), word.count > 4 {
            return String(word.dropLast(3)) + "y"
        }
        if word.hasSuffix("oes") {
            return String(word.dropLast(2))
        }
        // "ves" → "f" only for the words that do that; cloves, olives and chives just lose the s.
        let fWords = ["leaves": "leaf", "halves": "half", "loaves": "loaf", "calves": "calf", "knives": "knife"]
        if let single = fWords[word] {
            return single
        }
        if word.hasSuffix("ches") || word.hasSuffix("shes") || word
            .hasSuffix("sses")
        {
            return String(word.dropLast(2))
        }
        if word.hasSuffix("s"), !word.hasSuffix("ss"), !word.hasSuffix("us"), word.count > 3 {
            return String(word.dropLast())
        }
        return word
    }

    static let fractions: [Character: String] = [
        "½": " 1/2", "¼": " 1/4", "¾": " 3/4", "⅓": " 1/3", "⅔": " 2/3", "⅛": " 1/8", "⅜": " 3/8", "⅝": " 5/8",
        "⅞": " 7/8",
    ]

    /// Unicode fractions to "a b/c", bullets and dashes at the start dropped, spaces collapsed.
    static func clean(_ text: String) -> String {
        var out = ""
        for character in text {
            out += fractions[character] ?? String(character)
        }
        out = out.replacing(/^[\s•\-–*·]+/, with: "")
        out = out.replacing(/\s+/, with: " ")
        return out.trimmingCharacters(in: .whitespaces)
    }

    static func number(_ text: String) -> Double? {
        let parts = text.replacingOccurrences(of: ",", with: ".").split(separator: " ")
        var total = 0.0
        for part in parts {
            if part.contains("/") {
                let pieces = part.split(separator: "/")
                guard pieces.count == 2, let top = Double(pieces[0]), let bottom = Double(pieces[1]), bottom != 0
                else { return nil }
                total += top / bottom
            } else {
                guard let value = Double(part) else { return nil }
                total += value
            }
        }
        return total
    }

    static func format(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0 ... 1)))
    }
}
