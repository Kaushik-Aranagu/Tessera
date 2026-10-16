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
        // With a day in it ("get haircut thu"), it's a task, not shopping. "sun" in "buy sun cream" isn't a day:
        // a short weekday only counts at the end or before a time.
        let hasDate = Self.hasDate(trimmed, context: context)
        // "list: packing" or "new list films"; "list the car on ebay sat" is a task.
        if let match = trimmed.firstMatch(of: /^(?i)(?:list:|new\s+list[:\s])\s*(.+)$/) {
            let name = String(match.1).trimmingCharacters(in: .whitespaces)
            return name.isEmpty ? nil : .list(name: name.prefix(1).uppercased() + name.dropFirst())
        }
        if ["shop", "start shopping", "shopping", "go shopping", "at the shop"].contains(text) {
            // Already shopping: nothing to start.
            return context.process == Groceries.listID ? nil : .shop
        }
        // "remind me to reset the oven timer at 9 tomorrow" is a task: no kitchen reading for explicit tasks, and a
        // timer never has a day.
        if text.hasPrefix("todo") || text.hasPrefix("task") || text.hasPrefix("remind") {
            return nil
        }
        if !hasDate, let timer = parseTimer(text) {
            return timer
        }
        // "oat milk and eggs for groceries", "add eggs to the shopping list" (Design's Speak review), read before the
        // buy/get rule so its verb never lands in the item. Never money said about groceries ("spent $40 on
        // groceries", QA G1 on #282).
        if !hasDate, let match = trimmed.firstMatch(
            of: /^(?i)(?:(?:buy|get|add|pick up)\s+)?(.+?)\s+(?:for|on|to|onto)\s+(?:the\s+|my\s+)?(?:groceries|grocery list|shopping list|shopping)$/
        ), !Self.isMoney(trimmed) {
            let lines = Self.splitItems(String(match.1))
            return lines.isEmpty ? nil : .groceries(lines: lines)
        }
        if !hasDate, let match = trimmed
            .firstMatch(of: /^(?i)(?:buy|get|groceries:|grocery:|shopping:|add to groceries:?)\s+(.+)$/)
        {
            let lines = Self.splitItems(String(match.1))
            // "get" is a common verb ("get 5x5 squats done", "get up early"); unknown things still count ("get
            // coffee").
            if text.hasPrefix("get "), !lines.allSatisfy(isGettable) {
                return nil
            }
            // People, gifts, services and errands aren't groceries, after "buy" or "get" (Product: a clearly non-food
            // thing is a task; unclear stays Groceries). One such item is a task for Later; a list with one goes to
            // the model.
            if text.hasPrefix("get ") || text.hasPrefix("buy "), lines.contains(where: notGroceries) {
                guard lines.count == 1 else { return nil }
                return .task(title: trimmed.prefix(1).uppercased() + trimmed.dropFirst(), startsAt: nil)
            }
            return lines.isEmpty ? nil : .groceries(lines: lines)
        }
        // A bare comma list of short items: "milk, eggs, 2 lemons".
        if trimmed.contains(","), !trimmed.contains("\n") {
            let lines = Self.splitItems(trimmed)
            // At least one item reads as shopping, none is a set or an errand, and there's no day: "milk, coffee, tea"
            // is shopping (coffee and tea land in Other); "call mum, dentist" isn't.
            if lines.count >= 2, !hasDate, !Self.isMoney(trimmed), Self.isShoppingList(lines, looksLikeGroceries) {
                return .groceries(lines: lines)
            }
        }
        return parseCook(trimmed, context: context)
    }

    /// Money said, not things to buy: a currency sign or a spending verb ("spent $40 on groceries").
    static func isMoney(_ text: String) -> Bool {
        // A unit price ("chicken $1.29/lb") is a price on a thing to buy, never a spend (Research's US shop check).
        let spent = text.replacing(/(?i)[$£€₹]\s?\d+(?:[.,]\d+)?\s?\/\s?[a-z]+/, with: "")
        return spent.contains(where: { "$£€₹".contains($0) })
            || text.lowercased().firstMatch(of: /^(?:spent|spend|paid|pay|cost|bought)\b/) != nil
    }

    /// A comma-list item that reads as shopping: an amount, a known aisle or a known ingredient
    /// ("call mum, dentist" is not shopping).
    private func looksLikeGroceries(_ item: String) -> Bool {
        // "80x8", "80 for 8" and "5x5 squats" are sets, not shopping.
        guard item.split(separator: " ").count <= 4, item.contains(where: \.isLetter),
              item.firstMatch(of: /\d\s*(?:[x×]|for|by)\s*\d/) == nil, item.firstMatch(of: /\d\s*reps?\b/) == nil,
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
        // With no unit, a rest or plank of 30 or more is seconds ("rest timer 90"); anything else, a dough rest
        // included, is minutes.
        let bare = text.replacingOccurrences(of: "timer", with: " ").replacing(/[\d.]+/, with: " ")
            .split(whereSeparator: \.isWhitespace).joined(separator: " ")
        let isSeconds = match.2 == nil && number >= 30 && (bare == "rest" || bare == "plank")
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
        // Whole words only ("run" must not find "Brunch eggs"), split the same way on both sides so "stir-fry" finds
        // "stir-fry", and singular so "pancake" finds "Protein pancakes".
        func keys(_ text: String) -> [String] {
            text.lowercased().split { !$0.isLetter && !$0.isNumber }.map { IngredientLine.key(for: String($0)) }
        }
        let words = keys(query)
        guard !words.isEmpty else { return nil }
        return recipes.first { recipe in
            let title = Set(keys(recipe.title))
            return words.allSatisfy { title.contains($0) }
        }
    }

    static func isShoppingList(_ lines: [String], _ looksLikeGroceries: (String) -> Bool) -> Bool {
        guard !lines.contains(where: { $0.firstMatch(of: /\d\s*[x×]\s*\d/) != nil || startsWithErrand($0) }),
              lines.allSatisfy({ $0.split(separator: " ").count <= 4 && $0.contains(where: \.isLetter) })
        else { return false }
        return lines.contains(where: looksLikeGroceries)
    }

    /// "call mum", "email Sam", "skip lunges": things to do, not to buy.
    static func startsWithErrand(_ item: String) -> Bool {
        let verbs: Set = ["call", "email", "text", "ring", "book", "pay", "fix", "clean", "skip", "meet", "send",
                          "write", "check", "ask", "tell", "pick", "drop", "visit", "go", "do", "make", "finish"]
        return item.split(separator: " ").first.map { verbs.contains($0.lowercased()) } ?? false
    }

    /// After "buy" or "get": a person ("mum a card"), a gift shape ("Olive a present"), a service or non-shop word
    /// ("haircut", "tickets", "petrol"), or an errand verb. Anything unclear stays Groceries (Product, 4:30 PM PT).
    func notGroceries(_ item: String) -> Bool {
        let lower = item.lowercased()
        let people = /^(mum|mom|dad|nan|nana|gran|granny|grandma|grandad|grandpa|sis|bro|wife|husband|partner|kids|boss|her|him|them)\b/
        if lower.firstMatch(of: people) != nil || Self.startsWithErrand(lower) {
            return true
        }
        if lower.firstMatch(of: /^(?!(?:a|an|some|us|\d))\S+\s+(?:a|an|some)\s+\S/) != nil {
            return true
        }
        let services = /\b(haircut|jab|appointment|tickets?|flights?|phone|trainers|shoes|present|gift|plumber|petrol|cash|photos?|washed|booked|serviced|fixed)\b/
        if lower.firstMatch(of: services) != nil {
            return true
        }
        // "a/an" alone proves nothing ("buy a cake", "get a watermelon" stay Groceries; QA G9).
        return false
    }

    /// "get coffee" yes; "get up early", "get the car serviced", "get 5x5 squats done" no.
    private func isGettable(_ item: String) -> Bool {
        let first = item.split(separator: " ").first?.lowercased() ?? ""
        let notThings: Set = ["up", "the", "to", "back", "ready", "out", "in", "on", "off", "rid", "started", "going",
                              "home", "dressed", "done", "it", "me"]
        guard !notThings.contains(first), item.firstMatch(of: /\d\s*[x×]\s*\d/) == nil,
              !item.lowercased().hasSuffix(" done") else { return false }
        return looksLikeGroceries(item) || item.split(separator: " ").count <= 3
    }

    /// A day or time in the phrase, where a short weekday ("sun", "sat", "wed", "mon") only counts at the end or
    /// before a time.
    static func hasDate(_ phrase: String, context: TessContext) -> Bool {
        var words = phrase.split(separator: " ").map(String.init)
        let ambiguous: Set = ["sun", "sat", "wed", "mon"]
        words = words.enumerated().filter { index, word in
            guard ambiguous.contains(word.lowercased()), index < words.count - 1 else { return true }
            return TessDates.parseTime(words[index + 1].lowercased()) != nil
        }.map(\.element)
        return TessDates.extract(from: words, now: context.now, calendar: context.calendar).0 != nil
    }

    /// "milk, eggs and 2 lemons" → ["milk", "eggs", "2 lemons"].
    static func splitItems(_ text: String) -> [String] {
        text.replacing(/\s+and\s+/, with: ",")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}
