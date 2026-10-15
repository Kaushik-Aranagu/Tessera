import Foundation

/// A recipe read from pasted text (kitchen slice 3): title, serves, times, ingredient lines and steps.
/// Pure: `RecipeParser.parse` never writes; `CreateRecipe` stores the result as objects.
public struct ParsedRecipe: Hashable, Sendable {
    public struct Step: Hashable, Sendable {
        public var text: String
        /// Durations mentioned in the step, in minutes ("simmer 20 min" → 20; "1–2 hours" → 60...120).
        public var timers: [ClosedRange<Double>]
    }

    public var title: String
    public var serves: Int?
    public var activeMinutes: Double?
    public var totalMinutes: Double?
    public var ingredients: [IngredientLine]
    public var steps: [Step]
    public var source: String
}

public enum RecipeParser {
    enum Mode { case unknown, ingredients, steps }

    /// Splits on "Ingredients" / "Method" headings when there are any, else by line shape: amounts and short
    /// lines are ingredients, sentences are steps. The text is kept verbatim in `source`.
    // swiftlint:disable:next cyclomatic_complexity
    public static func parse(_ text: String) -> ParsedRecipe? {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard !lines.isEmpty else { return nil }

        var title: String?
        var serves: Int?
        var active: Double?
        var total: Double?
        var ingredients: [IngredientLine] = []
        var steps: [ParsedRecipe.Step] = []
        var mode = Mode.unknown

        for (index, line) in lines.enumerated() {
            if let next = heading(of: line) {
                mode = next
                continue
            }
            if let count = servesCount(in: line) {
                serves = count
                continue
            }
            if let (kind, minutes) = timeLine(line) {
                if kind == "total" {
                    total = minutes
                } else if kind == "prep" || kind == "active" {
                    active = minutes
                }
                continue
            }
            // The first line is the title unless it opens with an amount ("200 g flour").
            if index == 0, title == nil, !startsWithAmount(line) {
                title = line.trimmingCharacters(in: CharacterSet(charactersIn: "#*: "))
                continue
            }
            let isIngredient = switch mode {
            case .ingredients: true
            case .steps: false
            // Before any heading (or with none), go by the line's shape.
            case .unknown: looksLikeIngredient(line)
            }
            if isIngredient, let parsed = IngredientLine.parse(line) {
                ingredients.append(parsed)
            } else {
                let body = stripNumbering(line)
                guard !body.isEmpty else { continue }
                steps.append(.init(text: body, timers: durations(in: body)))
            }
        }
        guard !ingredients.isEmpty || !steps.isEmpty else { return nil }
        return ParsedRecipe(title: title ?? "Untitled recipe", serves: serves, activeMinutes: active,
                            totalMinutes: total, ingredients: ingredients, steps: steps, source: text)
    }

    static func heading(of line: String) -> Mode? {
        let word = line.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "#*:- ").union(.whitespaces))
        if ["ingredients", "you will need", "you'll need", "shopping list"].contains(word)
            || word.hasPrefix("for the ") && word.count < 30
        {
            return .ingredients
        }
        if ["method", "directions", "instructions", "steps", "preparation", "how to make it", "to make"]
            .contains(word)
        {
            return .steps
        }
        return nil
    }

    /// "Serves 4", "Serves: 2-3", "For 4 people", "Makes 12".
    static func servesCount(in line: String) -> Int? {
        guard let match = line
            .firstMatch(
                of: /(?i)^(?:serves|servings|for|makes|yield)\s*:?\s*(\d+)(?:\s*(?:-|–|to)\s*\d+)?(?:\s+(?:people|persons|portions|servings))?\s*$/
            )
        else { return nil }
        return Int(match.1)
    }

    /// "Prep time: 15 min", "Total time 1 hour", "Cook: 20 mins".
    static func timeLine(_ line: String) -> (String, Double)? {
        // "Cook time: 20 min" or "Cook: 20 min", never a step like "Cook the pasta for 10 minutes."
        guard let match = line.firstMatch(of: /(?i)^(prep|active|cook|cooking|total)(?:\s+time\s*:?|\s*:)\s*(.+)$/),
              let minutes = durations(in: String(match.2)).first?.lowerBound else { return nil }
        let kind = match.1.lowercased()
        return (kind == "cooking" ? "cook" : kind, minutes)
    }

    /// An ingredient line starts with an amount, or is short and isn't a sentence.
    static func looksLikeIngredient(_ line: String) -> Bool {
        let clean = IngredientLine.clean(line)
        let words = clean.split(separator: " ").count
        // "1. Heat the oil" is a numbered step, not an amount.
        if clean.firstMatch(of: /^\d+[.)]\s/) != nil || clean.firstMatch(of: /(?i)^step\s*\d/) != nil {
            return false
        }
        if clean.first?.isNumber == true {
            return words <= 10 && !clean.hasSuffix(".")
        }
        if clean.firstMatch(of: /(?i)^an?\s+(pinch|handful|bunch|clove|can|tin|slice|sprig)/) != nil {
            return true
        }
        return words <= 5 && !clean.hasSuffix(".")
    }

    static func startsWithAmount(_ line: String) -> Bool {
        let clean = IngredientLine.clean(line)
        return clean.first?.isNumber == true
            || clean.firstMatch(of: /(?i)^an?\s+(pinch|handful|bunch|clove|can|tin|slice|sprig)/) != nil
    }

    static func stripNumbering(_ line: String) -> String {
        line.replacing(/^(?i)(?:step\s*)?\d+[.):]?\s+/, with: "")
            .replacing(/^[•\-–*·]\s*/, with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    /// Every duration in a step, in minutes: "20 min", "1–2 hours", "30 seconds", "1 hr 15 min".
    public static func durations(in text: String) -> [ClosedRange<Double>] {
        var found: [ClosedRange<Double>] = []
        // swiftlint:disable:next line_length
        let pattern = #/(?i)(\d+(?:[.,]\d+)?)(?:\s*(?:-|–|to)\s*(\d+(?:[.,]\d+)?))?\s*(hours?|hrs?|h|minutes?|mins?|m|seconds?|secs?|s)\b(?:\s+(?:and\s+)?(\d+)\s*(minutes?|mins?|m)\b)?/#
        for match in text.matches(of: pattern) {
            guard let low = Double(match.1.replacingOccurrences(of: ",", with: ".")) else { continue }
            let high = match.2.flatMap { Double($0.replacingOccurrences(of: ",", with: ".")) } ?? low
            let unit = match.3.lowercased()
            let factor: Double = unit.hasPrefix("h") ? 60 : unit.hasPrefix("s") ? 1.0 / 60 : 1
            let extra = match.4.flatMap { Double($0) } ?? 0
            found.append((low * factor + extra) ... (max(high, low) * factor + extra))
        }
        return found
    }
}
