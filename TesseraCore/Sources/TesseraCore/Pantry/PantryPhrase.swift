import Foundation

/// The "out of milk" shapes (Pantry v2 spec, section b): a pure reader, no store. `resolve` then keeps only the names a
/// pantry can place (a known ingredient or the shop guide), so "out of breath" and "out of chalk" are not ours.
public struct PantryPhrase: Equatable {
    public enum Kind: Equatable {
        /// Out: state out plus a Groceries row.
        case out
        /// Low: state only.
        case low
        /// "have rice": in, the bought day untouched.
        case have
        /// "got/bought/picked up milk": in, and the bought day.
        case bought
        /// "pantry", "what do i have": opens Pantry.
        case open
    }

    public let kind: Kind
    /// The names as typed, trimmed of fillers. Empty for `.open`.
    public let items: [String]

    static let openWords: Set<String> = ["pantry", "open pantry", "show pantry", "what's out", "whats out",
                                         "what am i out of", "what do i have"]

    /// The phrase as the pantry reads it, or nil when it is not one. A phrase with a day or time, a reminder or a task
    /// word is never a pantry phrase ("remind me we're out of milk", "we'll be out of milk thu").
    public static func parse(_ phrase: String, hasDate: Bool = false) -> PantryPhrase? {
        var text = phrase.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        text = text.replacing(/[.!?]+$/, with: "").replacing("’", with: "'")
        guard !text.isEmpty else { return nil }
        if openWords.contains(text) {
            return PantryPhrase(kind: .open, items: [])
        }
        guard !hasDate, !text.hasPrefix("remind"), !text.hasPrefix("todo"), !text.hasPrefix("task") else { return nil }
        let shapes: [(Regex<(Substring, Substring)>, Kind)] = [
            (/^(?:we(?:'re| are)|i(?:'m| am)|all|just)?\s*(?:out of)\s+(.+)$/, .out),
            (/^(?:we )?(?:ran out of|(?:we've|we have|i've|i have) run out of)\s+(.+)$/, .out),
            (/^no more\s+(.+)$/, .out),
            (/^no\s+(.+?)\s+left$/, .out),
            (/^(?:running low on|low on)\s+(.+)$/, .low),
            (/^(?:we |i )?(?:have|restocked)\s+(.+)$/, .have),
            (/^(?:got|bought|picked up)\s+(.+)$/, .bought),
        ]
        for (regex, kind) in shapes {
            if let match = text.firstMatch(of: regex), let items = names(String(match.1), kind: kind) {
                return PantryPhrase(kind: kind, items: items)
            }
        }
        // "milk is out", "eggs are gone", "rice's low": a bare subject (no "the" or "my": it can mean left on the
        // counter).
        if let match = text.firstMatch(of: /^(.+?)(?:\s+is|\s+are|'s)\s+(out|gone|low)$/) {
            let subject = String(match.1)
            guard subject.firstMatch(of: /^(?:the|my|our|this|that|these|those)\s/) == nil,
                  let items = names(subject, kind: .out) else { return nil }
            return PantryPhrase(kind: match.2 == "low" ? .low : .out, items: items)
        }
        return nil
    }

    /// Splits and cleans the names; nil when any is not a pantry name (a digit, an article, too long).
    static func names(_ raw: String, kind _: Kind) -> [String]? {
        let parts = GroceryLines.split(raw)
        guard !parts.isEmpty else { return nil }
        var result: [String] = []
        for part in parts {
            var name = part.trimmingCharacters(in: .whitespaces)
            name = name.replacing(/^(?:(?:some|any|more|the|my|our|enough|all the|a bit of)\s+)+/, with: "")
                .replacing(/(?:\s+(?:again|now|today|too|as well|already|right now))+$/, with: "")
                .trimmingCharacters(in: .whitespaces)
            // Never counts, quantities or articles: "have 2 lemons", "have a lemon", "out of 5".
            let withoutPercent = name.replacing(/\d+%/, with: "")
            guard !name.isEmpty, withoutPercent.firstMatch(of: /\d/) == nil,
                  name.firstMatch(of: /^(?:a|an)\s/) == nil, name.split(separator: " ").count <= 4,
                  !stoplist.contains(name) else { return nil }
            result.append(name)
        }
        return result
    }

    /// Never the thing: "out of stock", "out of breath".
    static let stoplist: Set<String> = [
        "stock", "breath", "bed", "time", "range", "town", "office", "ideas", "luck", "order", "touch", "shape",
        "energy", "control", "reach", "sight", "practice", "reps", "sets", "meetings", "emails", "excuses",
    ]

    /// Keeps the phrase only when every name is placed: out and low take a known ingredient or an aisle-guide name
    /// (head-noun admission, "oat milk" finds milk's aisle); in is stricter, the whole name must be known.
    @MainActor
    public func resolve(in store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) -> PantryPhrase? {
        guard kind != .open else { return self }
        let known = Set((classes[.ingredient].map { store.objects(of: $0) } ?? []).filter { !$0.isDeleted }
            .map { IngredientLine.key(for: $0.title) })
        for name in items {
            let key = IngredientLine.key(for: name)
            switch kind {
            case .out, .low:
                guard known.contains(key) || AisleGuide.aisle(for: name) != nil else { return nil }
            default:
                guard known.contains(key) || AisleGuide.guideKnows(key) else { return nil }
            }
        }
        return self
    }
}
