import Foundation
import TesseraCore

/// Kitchen phrases (kitchen slice 9), through the same ghost row:
/// "buy milk", "milk, eggs, 2 lemons" → groceries; "cook carbonara" → starts cooking; "timer pasta 10",
/// "10 min timer" → a timer; "cook carbonara thu" or "carbonara thursday" → a dated task linking the recipe;
/// "list: packing" → a new list; "shop" → starts shopping; pasted text with an Ingredients heading → a recipe.
extension TessGrammar {
    /// Pasted text with an Ingredients heading.
    func parsePastedRecipe(_ phrase: String) -> Parse? {
        let trimmed = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("\n"),
              trimmed.firstMatch(of: /(?im)^\s*(ingredients|you will need)\s*:?\s*$/) != nil else { return nil }
        return .recipe(text: trimmed)
    }

    func parseKitchen(_ phrase: String, context: TessContext) -> Parse? {
        let trimmed = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        let text = trimmed.lowercased()
        // With a day in it ("get haircut thu"), it's a task, not shopping.
        let hasDate = TessDates.extract(from: trimmed.split(separator: " ").map(String.init), now: context.now,
                                        calendar: context.calendar).0 != nil
        // "list: packing" or "new list films"; "list the car on ebay sat" is a task.
        if let match = trimmed.firstMatch(of: /^(?i)(?:list:|new\s+list[:\s])\s*(.+)$/) {
            let name = String(match.1).trimmingCharacters(in: .whitespaces)
            return name.isEmpty ? nil : .list(name: name.prefix(1).uppercased() + name.dropFirst())
        }
        if ["shop", "start shopping", "shopping", "go shopping", "at the shop"].contains(text) {
            return .shop
        }
        // "remind me to reset the oven timer at 9 tomorrow" is a task: no kitchen reading for explicit tasks, and a
        // timer never has a day.
        if text.hasPrefix("todo") || text.hasPrefix("task") || text.hasPrefix("remind") {
            return nil
        }
        if !hasDate, let timer = parseTimer(text) {
            return timer
        }
        if !hasDate, let match = trimmed
            .firstMatch(of: /^(?i)(?:buy|get|groceries:|grocery:|shopping:|add to groceries:?)\s+(.+)$/)
        {
            let lines = Self.splitItems(String(match.1))
            // "get" is a common verb ("get 5x5 squats done", "get up early"): only shopping when it reads as shopping.
            if text.hasPrefix("get "), !lines.allSatisfy(looksLikeGroceries) {
                return nil
            }
            return lines.isEmpty ? nil : .groceries(lines: lines)
        }
        // A bare comma list of short items: "milk, eggs, 2 lemons".
        if trimmed.contains(","), !trimmed.contains("\n") {
            let lines = Self.splitItems(trimmed)
            // Every item needs a word ("bench 80, 8" is a lift, not a list), and no day ("call mum, thu").
            if lines.count >= 2, !hasDate, lines.allSatisfy(looksLikeGroceries) {
                return .groceries(lines: lines)
            }
        }
        return parseCook(trimmed, context: context)
    }

    /// A comma-list item that reads as shopping: an amount, a known aisle or a known ingredient
    /// ("call mum, dentist" is not shopping).
    private func looksLikeGroceries(_ item: String) -> Bool {
        // "80x8" and "5x5 squats" are sets, not shopping.
        guard item.split(separator: " ").count <= 4, item.contains(where: \.isLetter),
              item.firstMatch(of: /\d\s*[x×]\s*\d/) == nil,
              let line = IngredientLine.parse(item) else { return false }
        return line.amount != nil || AisleGuide.aisle(for: line.name) != nil
            || IngredientBook(store: store, classes: classes).find(line.name) != nil
    }

    /// "timer pasta 10", "pasta timer 10", "10 min timer", "timer 10 min pasta", "timer 10".
    private func parseTimer(_ text: String) -> Parse? {
        guard text.contains("timer") else { return nil }
        let rest = text.replacingOccurrences(of: "timer", with: " ")
        guard let match = rest
            .firstMatch(of: /(\d+(?:\.\d+)?)\s*(hours?|hrs?|h|minutes?|mins?|m|seconds?|secs?|s)?\b/),
            let number = Double(match.1) else { return nil }
        // With no unit, a rest or plank of 30 or more is seconds ("rest timer 90"); anything else is minutes.
        let isSeconds = match.2 == nil && number >= 30 && (text.contains("rest") || text.contains("plank"))
        let minutes = match.2.map { $0.hasPrefix("h") ? number * 60 : $0.hasPrefix("s") ? number / 60 : number }
            ?? (isSeconds ? number / 60 : number)
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
        let name = remaining.joined(separator: " ")
        guard explicit || date != nil else { return nil }
        if let recipe = recipe(named: name) {
            return .cook(recipe: recipe, on: date)
        }
        // "cook lasagne" with no such recipe is still something to do.
        guard explicit, phrase.lowercased().hasPrefix("cook "), !name.isEmpty else { return nil }
        return .task(title: "Cook \(name)", startsAt: date)
    }

    /// The recipe whose title matches: exact first, else the one containing every word said.
    func recipe(named name: String) -> ObjectRecord? {
        let query = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return nil }
        let recipes = RecipeBook(store: store, classes: classes).recipes()
        if let exact = recipes.first(where: { $0.title.lowercased() == query }) {
            return exact
        }
        // Whole words only: "run" must not find "Brunch eggs".
        let words = query.split(separator: " ").map(String.init)
        return recipes.first { recipe in
            let title = Set(recipe.title.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init))
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
