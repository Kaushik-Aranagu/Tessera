import Foundation

/// A recipe read from pasted text (kitchen slice 3): title, serves, times, ingredient lines and steps.
/// Pure: `RecipeParser.parse` never writes; `CreateRecipe` stores the result as objects.
public struct ParsedRecipe: Hashable, Sendable {
    public struct Step: Hashable, Sendable {
        public var text: String
        /// Durations mentioned in the step, in minutes ("simmer 20 min" → 20; "1–2 hours" → 60...120).
        public var timers: [ClosedRange<Double>]

        /// The timers the step offers: nothing over 24 hours (G9).
        public var offeredTimers: [ClosedRange<Double>] {
            RecipeParser.offeredTimers(timers)
        }
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

    /// How one line of pasted text was read (what the paste screen paints).
    public enum LineKind: Hashable, Sendable {
        case title, heading, meta
        case ingredient(IngredientLine)
        case step(text: String, timers: [ClosedRange<Double>])
        /// Read as nothing (a tap on the paste screen can make a line this).
        case ignored
    }

    /// Every non-empty line with how it reads: headings switch mode ("Ingredients", "Method"), "Serves 2" and
    /// "Total time: 25 min" are meta, the first line is the title unless it opens with an amount, and before any
    /// heading lines go by their shape (amounts and short lines are ingredients, sentences are steps).
    public static func classify(_ text: String) -> [(line: String, kind: LineKind)] {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        var mode = Mode.unknown
        var result: [(String, LineKind)] = []
        for (index, line) in lines.enumerated() {
            if let next = heading(of: line) {
                mode = next
                result.append((line, .heading))
            } else if servesCount(in: line) != nil || timeLine(line) != nil {
                result.append((line, .meta))
            } else if index == 0, !startsWithAmount(line) {
                result.append((line, .title))
            } else {
                let isIngredient = switch mode {
                case .ingredients: true
                case .steps: false
                case .unknown: looksLikeIngredient(line)
                }
                if isIngredient, let parsed = IngredientLine.parse(line) {
                    result.append((line, .ingredient(parsed)))
                } else {
                    let body = stripNumbering(line)
                    result.append((line, body.isEmpty ? .ignored : .step(text: body, timers: durations(in: body))))
                }
            }
        }
        return result
    }

    /// Splits on "Ingredients" / "Method" headings when there are any, else by line shape: amounts and short
    /// lines are ingredients, sentences are steps. The text is kept verbatim in `source`.
    public static func parse(_ text: String) -> ParsedRecipe? {
        parse(text, lines: classify(text))
    }

    /// The recipe from lines already classified (the paste screen's corrections included).
    public static func parse(_ text: String, lines: [(line: String, kind: LineKind)]) -> ParsedRecipe? {
        var title: String?
        var serves: Int?
        var active: Double?
        var total: Double?
        var ingredients: [IngredientLine] = []
        var steps: [ParsedRecipe.Step] = []
        for (line, kind) in lines {
            switch kind {
            case .title:
                title = title ?? line.trimmingCharacters(in: CharacterSet(charactersIn: "#*: "))
            case .meta:
                if let count = servesCount(in: line) {
                    serves = count
                } else if let (which, minutes) = timeLine(line) {
                    if which == "total" {
                        total = minutes
                    } else if which == "prep" || which == "active" {
                        active = minutes
                    }
                }
            case let .ingredient(parsed):
                ingredients.append(parsed)
            case let .step(body, timers):
                steps.append(.init(text: body, timers: timers))
            case .heading, .ignored:
                continue
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

    /// The longest kitchen timer: 24 hours. A longer duration ("48 hours") is read for the recipe clock but never
    /// offered as a timer (G9).
    public static let maxTimerMinutes: Double = 24 * 60

    /// The durations in a step that can become a timer (nothing over 24 hours).
    public static func offeredTimers(_ durations: [ClosedRange<Double>]) -> [ClosedRange<Double>] {
        durations.filter { $0.upperBound <= maxTimerMinutes }
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
