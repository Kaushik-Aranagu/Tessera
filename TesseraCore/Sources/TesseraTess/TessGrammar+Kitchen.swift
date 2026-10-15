import Foundation
import TesseraCore

/// Kitchen phrases (kitchen slice 9), through the same ghost row:
/// "buy milk", "milk, eggs, 2 lemons" → groceries; "cook carbonara" → starts cooking; "timer pasta 10",
/// "10 min timer" → a timer; "cook carbonara thu" or "carbonara thursday" → a dated task linking the recipe;
/// "list: packing" → a new list; "shop" → starts shopping; pasted text with an Ingredients heading → a recipe.
extension TessGrammar {
    func parseKitchen(_ phrase: String, context: TessContext) -> Parse? {
        let trimmed = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.contains("\n"), trimmed.firstMatch(of: /(?im)^\s*(ingredients|you will need)\s*:?\s*$/) != nil {
            return .recipe(text: trimmed)
        }
        let text = trimmed.lowercased()
        if let match = trimmed.firstMatch(of: /^(?i)(?:new\s+)?list[:\s]\s*(.+)$/) {
            let name = String(match.1).trimmingCharacters(in: .whitespaces)
            return name.isEmpty ? nil : .list(name: name.prefix(1).uppercased() + name.dropFirst())
        }
        if ["shop", "start shopping", "shopping", "go shopping", "at the shop"].contains(text) {
            return .shop
        }
        if let timer = parseTimer(text) {
            return timer
        }
        if let match = trimmed
            .firstMatch(of: /^(?i)(?:buy|get|groceries:|grocery:|shopping:|add to groceries:?)\s+(.+)$/)
        {
            let lines = Self.splitItems(String(match.1))
            return lines.isEmpty ? nil : .groceries(lines: lines)
        }
        // A bare comma list of short items: "milk, eggs, 2 lemons".
        if trimmed.contains(","), !trimmed.contains("\n") {
            let lines = Self.splitItems(trimmed)
            if lines.count >= 2, lines.allSatisfy({ $0.split(separator: " ").count <= 4 }),
               TessDates.extract(from: trimmed.split(separator: " ").map(String.init), now: context.now,
                                 calendar: context.calendar).0 == nil
            {
                return .groceries(lines: lines)
            }
        }
        return parseCook(trimmed, context: context)
    }

    /// "timer pasta 10", "pasta timer 10", "10 min timer", "timer 10 min pasta", "timer 10".
    private func parseTimer(_ text: String) -> Parse? {
        guard text.contains("timer") else { return nil }
        let rest = text.replacingOccurrences(of: "timer", with: " ")
        guard let match = rest.firstMatch(of: /(\d+(?:\.\d+)?)\s*(hours?|hrs?|h|minutes?|mins?|m)?\b/),
              let number = Double(match.1) else { return nil }
        let minutes = match.2.map { $0.hasPrefix("h") ? number * 60 : number } ?? number
        var label = rest
        label.removeSubrange(match.range)
        label = label.replacing(/\b(for|a|of|set)\b/, with: " ")
            .split(whereSeparator: \.isWhitespace).joined(separator: " ")
        let name = label.isEmpty ? "Timer" : label.prefix(1).uppercased() + label.dropFirst()
        return .timer(label: name, minutes: minutes)
    }

    /// "cook carbonara" (now) or "cook carbonara thu" / "carbonara thursday" (a dated task) for a known recipe.
    private func parseCook(_ phrase: String, context: TessContext) -> Parse? {
        var words = phrase.split(separator: " ").map(String.init)
        let explicit = words.first?.lowercased() == "cook" || words.first?.lowercased() == "make"
        if explicit {
            words.removeFirst()
        }
        let (date, remaining) = TessDates.extract(from: words, now: context.now, calendar: context.calendar)
        guard explicit || date != nil, let recipe = recipe(named: remaining.joined(separator: " ")) else { return nil }
        return .cook(recipe: recipe, on: date)
    }

    /// The recipe whose title matches: exact first, else the one containing every word said.
    func recipe(named name: String) -> ObjectRecord? {
        let query = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return nil }
        let recipes = RecipeBook(store: store, classes: classes).recipes()
        if let exact = recipes.first(where: { $0.title.lowercased() == query }) {
            return exact
        }
        let words = query.split(separator: " ")
        return recipes.first { recipe in
            let title = recipe.title.lowercased()
            return words.allSatisfy { title.contains($0) }
        }
    }

    /// "milk, eggs and 2 lemons" → ["milk", "eggs", "2 lemons"].
    static func splitItems(_ text: String) -> [String] {
        text.replacing(/\s+and\s+/, with: ",")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}
