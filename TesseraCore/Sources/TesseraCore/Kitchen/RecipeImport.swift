import Foundation

/// A recipe from a web page (docs/research/recipe-link-fetch.md §2, Design 32 `link-fetch-us.md`): schema.org Recipe
/// JSON-LD first (L1), then the page's visible text through the paste parser (L2). Pure: no network, no writes. No
/// HTML parser and no backtracking regex on page text: script tags are found with range searches, blocks are capped.
public enum RecipeImport {
    /// Every schema.org Recipe in the page's JSON-LD, in page order (the first is read; the count is said).
    public static func recipes(in html: String) -> [ParsedRecipe] {
        jsonLD(in: html).compactMap(parsed)
    }

    /// Whether the page marks itself paywalled (`isAccessibleForFree: false`) or asks to subscribe near the top.
    public static func isPaywalled(_ html: String) -> Bool {
        let nodes = jsonLDObjects(in: html)
        if nodes.contains(where: { node in
            (node["isAccessibleForFree"] as? Bool) == false
                || (node["isAccessibleForFree"] as? String)?.lowercased() == "false"
        }) {
            return true
        }
        let head = String(visibleText(html).prefix(4000)).lowercased()
        return head.contains("subscribe to") && head.contains("sign in")
    }

    // MARK: JSON-LD (L1)

    static func jsonLDObjects(in html: String) -> [[String: Any]] {
        var objects: [[String: Any]] = []
        var rest = html[...]
        while let open = rest.range(of: "application/ld+json", options: .caseInsensitive),
              let tagEnd = rest[open.upperBound...].firstIndex(of: ">"),
              let close = rest[tagEnd...].range(of: "</script>", options: .caseInsensitive)
        {
            let body = rest[rest.index(after: tagEnd) ..< close.lowerBound]
            rest = rest[close.upperBound...]
            guard body.utf8.count < 1_000_000,
                  let json = try? JSONSerialization.jsonObject(with: Data(body.utf8), options: .fragmentsAllowed)
            else { continue } // one broken block doesn't stop the search
            collect(json, depth: 0, into: &objects)
        }
        return objects
    }

    static func jsonLD(in html: String) -> [[String: Any]] {
        jsonLDObjects(in: html).filter(isRecipe)
    }

    private static func collect(_ node: Any, depth: Int, into objects: inout [[String: Any]]) {
        guard depth < 8 else { return }
        if let list = node as? [Any] {
            list.forEach { collect($0, depth: depth + 1, into: &objects) }
            return
        }
        guard let object = node as? [String: Any] else { return }
        objects.append(object)
        for key in ["@graph", "mainEntity"] {
            if let inner = object[key] {
                collect(inner, depth: depth + 1, into: &objects)
            }
        }
    }

    private static func isRecipe(_ object: [String: Any]) -> Bool {
        let types = object["@type"] as? [String] ?? [object["@type"] as? String ?? ""]
        return types.contains { $0.caseInsensitiveCompare("Recipe") == .orderedSame }
    }

    /// A Recipe node to a recipe: ingredients through the line parser (US amounts kept as written), steps from
    /// strings, HowToStep or HowToSection, times from ISO 8601, serves from the first number of the yield.
    static func parsed(_ node: [String: Any]) -> ParsedRecipe? {
        let title = text(node["name"]) ?? "Recipe"
        let rawIngredients = (node["recipeIngredient"] ?? node["ingredients"]) as? [Any] ?? []
        let ingredients = rawIngredients.compactMap { text($0) }.prefix(80).compactMap(IngredientLine.parse)
        var steps: [ParsedRecipe.Step] = []
        func add(_ step: String) {
            let clean = step.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !clean.isEmpty, clean.count <= 2000, steps.last?.text != clean, steps.count < 60 else { return }
            steps.append(.init(text: clean, timers: RecipeParser.durations(in: clean)))
        }
        func walk(_ value: Any?, depth: Int = 0) {
            guard depth < 6, let value else { return }
            if let string = value as? String {
                string.replacing(/(?i)<\/?li[^>]*>|<br\s*\/?>/, with: "\n").components(separatedBy: .newlines)
                    .compactMap { text($0) }.forEach(add)
            } else if let list = value as? [Any] {
                list.forEach { walk($0, depth: depth + 1) }
            } else if let object = value as? [String: Any] {
                if let items = object["itemListElement"] {
                    walk(items, depth: depth + 1) // HowToSection
                } else if let step = text(object["text"]) ?? text(object["name"]) {
                    add(step)
                }
            }
        }
        walk(node["recipeInstructions"])
        guard !ingredients.isEmpty || !steps.isEmpty else { return nil }
        let prep = (node["prepTime"] as? String).flatMap(minutes)
        let cook = (node["cookTime"] as? String).flatMap(minutes)
        let total = (node["totalTime"] as? String).flatMap(minutes)
            ?? (prep != nil || cook != nil ? (prep ?? 0) + (cook ?? 0) : nil)
        let yields = node["recipeYield"] as? [Any] ?? [node["recipeYield"] as Any]
        let serves = yields.lazy.compactMap { value -> Int? in
            if let number = value as? Int {
                return number
            }
            return (value as? String)?.firstMatch(of: /\d+/).flatMap { Int($0.0) }
        }.first
        return ParsedRecipe(title: title, serves: serves, activeMinutes: prep, totalMinutes: total,
                            ingredients: Array(ingredients), steps: steps, source: "")
    }

    /// "PT1H30M", "P0DT0H35M", "PT90M" → minutes; nil for zero or unreadable.
    static func minutes(_ iso: String) -> Double? {
        guard let match = iso.wholeMatch(of: /(?i)P(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:[\d.]+S)?)?/) else {
            return nil
        }
        let days = Double(match.1 ?? "0") ?? 0
        let hours = Double(match.2 ?? "0") ?? 0
        let total = days * 1440 + hours * 60 + (Double(match.3 ?? "0") ?? 0)
        return total > 0 ? total : nil
    }

    /// A JSON string with tags and entities gone.
    static func text(_ value: Any?) -> String? {
        guard let raw = value as? String else { return nil }
        let clean = entities(raw.replacing(/<[^>]{0,500}>/, with: " "))
            .replacing(/\s+/, with: " ").trimmingCharacters(in: .whitespaces)
        return clean.isEmpty ? nil : clean
    }

    // MARK: Visible text (L2)

    /// The page as lines of text: scripts, styles and page furniture dropped, block tags as line breaks, tags and
    /// entities gone. The recipe card (WPRM, Tasty) when there is one, else the article or main, else the body.
    public static func visibleText(_ html: String) -> String {
        var page = html
        for tag in ["script", "style", "noscript", "iframe", "nav", "header", "footer", "aside", "form", "svg"] {
            page = page
                .replacing(try! Regex("(?is)<\(tag)\\b.*?</\(tag)\\s*>"), with: " ") // swiftlint:disable:this force_try
        }
        page = page.replacing(/(?s)<!--.*?-->/, with: " ")
        for marker in ["wprm-recipe-container", "tasty-recipes", "<article", "<main"] {
            if let start = page.range(of: marker, options: .caseInsensitive) {
                page = String(page[start.lowerBound...])
                break
            }
        }
        page = page.replacing(/(?i)<(?:br|\/p|\/li|\/h[1-6]|\/div|\/tr|li|p|h[1-6])\b[^>]{0,500}>/, with: "\n")
        page = page.replacing(/<[^>]{0,2000}>/, with: " ")
        return entities(page).components(separatedBy: .newlines)
            .map { $0.replacing(/[ \t\u{00A0}]+/, with: " ").trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !noise.contains($0.lowercased()) }
            .joined(separator: "\n")
    }

    /// Blog furniture read as nothing (corpus gap 3).
    static let noise: Set<String> = ["jump to recipe", "print recipe", "print", "pin recipe", "save recipe", "rate",
                                     "share", "▢"]

    /// L2: the visible text through the paste parser, kept only with at least 2 ingredients and 1 step.
    public static func fromText(_ html: String) -> ParsedRecipe? {
        let text = visibleText(html)
        guard let parsed = RecipeParser.parse(text), parsed.ingredients.count >= 2, parsed.ingredients.count <= 80,
              !parsed.steps.isEmpty else { return nil }
        return parsed
    }

    static func entities(_ text: String) -> String {
        var out = text
        for (entity, character) in ["&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": "\"", "&#39;": "'", "&#039;": "'",
                                    "&apos;": "'", "&nbsp;": " ", "&frac12;": "½", "&frac14;": "¼", "&frac34;": "¾",
                                    "&#8217;": "’", "&#8211;": "–", "&deg;": "°", "&rsquo;": "’", "&ndash;": "–"]
        {
            out = out.replacingOccurrences(of: entity, with: character)
        }
        return out.replacing(/&#(\d{2,6});/) { match in
            Int(match.1).flatMap(UnicodeScalar.init).map { String(Character($0)) } ?? ""
        }
    }

    /// The recipe as text the paste screen paints and `CreateRecipe(text:)` saves: title, serves, ingredients, method.
    public static func text(of recipe: ParsedRecipe) -> String {
        var lines = [recipe.title]
        if let serves = recipe.serves {
            lines.append("Serves \(serves)")
        }
        if let total = recipe.totalMinutes {
            lines.append("Total time: \(Int(total)) min")
        }
        lines.append("")
        lines.append("Ingredients")
        lines += recipe.ingredients.map(\.original)
        lines.append("")
        lines.append("Method")
        lines += recipe.steps.enumerated().map { "\($0.offset + 1). \($0.element.text)" }
        return lines.joined(separator: "\n")
    }
}
