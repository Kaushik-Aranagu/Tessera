import Foundation

// When Tess tries an ask's writes on a copy first (docs/ai/harness/rehearsal.md section 2). The picker reads his words,
// no model: a bulk ask ("move everything to tomorrow", "log 5 sets") or a structural one (a plan, a routine's slots,
// a list's sections) gets the `rehearse` tool and one line telling her to rehearse before she writes. A bound command
// never gets here: "done" and "as a column" are deterministic and already have Undo.

/// Why an ask is rehearsed.
public enum RehearseReason: String, Sendable, Equatable, Codable {
    /// More than `RehearseFlags.bulkLimit` records from one ask.
    case bulk
    /// It changes a plan, a routine's slots or a list's sections.
    case structural
}

public enum RehearseFlags {
    /// The rehearsal tool (Core's `Rehearsal`): runs her calls on a copy of his store and writes nothing.
    public static let tool = "rehearse"
    /// More records than this from one ask is bulk.
    static let bulkLimit = 3
    /// Things a count can count ("my 5 tasks", "6 sets").
    static let counted: Set<String> = ["tasks", "things", "items", "notes", "sets", "workouts", "routines", "reminders",
                                       "lists", "chores", "habits", "errands", "entries", "todos", "recipes", "meals",
                                       "events"]
    /// Words that reach every record of a kind.
    static let everything: Set<String> = ["everything", "anything"]
    /// Words that reach every record when a determiner or a counted word follows ("all my", "each task").
    static let quantifiers: Set<String> = ["all", "every", "each", "rest"]
    static let determiners: Set<String> = ["my", "the", "of", "these", "those", "them", "today's", "tomorrow's"]
    /// Words for a thing with a shape: a plan, a routine's slots, a list's sections.
    static let shapes: Set<String> = ["plan", "plans", "program", "split", "routine", "routines", "slots", "slot",
                                      "section", "sections"]
    /// Words that change a shape, said with a shape word.
    static let changes: Set<String> = ["move", "change", "edit", "swap", "add", "remove", "delete", "drop", "shift",
                                       "push", "redo", "make", "turn", "clear", "replace", "rename", "group", "sort"]
    /// Words that change a shape on their own.
    static let reshapes: Set<String> = ["reorder", "rearrange", "restructure", "regroup", "reorganize", "shuffle",
                                        "merge"]

    /// His words, lowercased, digits kept ("my 5 tasks").
    static func tokens(_ text: String) -> [String] {
        text.lowercased().split { !$0.isLetter && !$0.isNumber && $0 != "'" }.map(String.init)
    }

    /// The count his ask names for a counted thing ("move my 5 tasks", "log six sets"), which the rehearsal checks
    /// the diff against. Nil when he names none.
    public static func count(_ ask: String) -> Int? {
        let words = tokens(ask)
        for (index, word) in words.enumerated() where index + 1 < words.count {
            guard let number = Int(word) ?? AnswerCheck.numberWords[word].map({ Int($0) }) else { continue }
            if counted.contains(words[index + 1]) {
                return number
            }
        }
        return nil
    }

    /// Why this ask is rehearsed, or nil.
    public static func reason(_ ask: String) -> RehearseReason? {
        let words = tokens(ask)
        if let asked = count(ask), asked > bulkLimit {
            return .bulk
        }
        if !everything.isDisjoint(with: words) {
            return .bulk
        }
        for (index, word) in words.enumerated() where quantifiers.contains(word) && index + 1 < words.count {
            let next = words[index + 1]
            if determiners.contains(next) || counted.contains(next) {
                return .bulk
            }
        }
        if !reshapes.isDisjoint(with: words) {
            return .structural
        }
        if !shapes.isDisjoint(with: words), !changes.isDisjoint(with: words) {
            return .structural
        }
        return nil
    }

    /// What Claude reads about the rehearse tool (Core's tool is device-only; `TessRun` runs it for a Claude rung).
    public static let description = "Try your writes on a hidden copy of his things first. Give the exact calls you "
        + "would make: each tool's name and its arguments as JSON text, and expecting when he named a count. Nothing "
        + "of his changes and nothing is shown. Returns what would change and any check that failed. If every check "
        + "passes, make the same calls for real; if not, change nothing and tell him what went wrong"

    /// The calls and count from `rehearse`'s input. Arguments may come as JSON text (the schema) or as an object.
    public static func calls(_ input: Data) -> (calls: [Rehearsal.Call], expecting: Int?)? {
        guard let arguments = (try? JSONSerialization.jsonObject(with: input)) as? [String: Any],
              let list = arguments["calls"] as? [[String: Any]] else { return nil }
        let calls = list.compactMap { entry -> Rehearsal.Call? in
            guard let name = entry["name"] as? String, !name.isEmpty else { return nil }
            if let object = entry["arguments"] as? [String: Any],
               let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
            {
                return Rehearsal.Call(name: name, arguments: data)
            }
            return Rehearsal.Call(name: name, json: entry["arguments"] as? String ?? "{}")
        }
        return calls.isEmpty ? nil : (calls, arguments["expecting"] as? Int)
    }

    /// A rehearsal as a Claude rung reads it: its fragments as the Door's policy allows, never the receipts. Under
    /// strict a money, body or private line stays on the phone, and she hears how many.
    public static func forClaude(_ result: Rehearsal.Result, policy: DoorPolicy) -> String {
        let shown = result.fragments.filter { policy.allows($0, onClaude: true) }
        var lines = shown.map(\.text)
        let held = result.fragments.count - shown.count
        if held > 0 {
            lines.append("\(held) more held back on the phone (private, money or body)")
        }
        lines.append(result.passed ? "All checks passed." : "Checks failed: change nothing, and tell him why.")
        return lines.joined(separator: "\n")
    }

    /// The line the model reads when an ask is rehearsed. It holds no item of his, so it goes to Claude as is.
    public static func line(_ reason: RehearseReason, count asked: Int?) -> String {
        let why = reason == .bulk ? "This ask changes many things" : "This ask changes the shape of a plan or a list"
        let match = asked.map { " He named \($0); the rehearsal checks the changes match." } ?? ""
        return "\(why). Rehearse first: call rehearse with the calls you would make; it writes nothing.\(match) "
            + "If every check passes, make the same calls. If not, change nothing and tell him what went wrong."
    }
}
