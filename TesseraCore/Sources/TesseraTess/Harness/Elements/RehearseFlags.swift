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

    /// The line the model reads when an ask is rehearsed. It holds no item of his, so it goes to Claude as is.
    public static func line(_ reason: RehearseReason, count asked: Int?) -> String {
        let why = reason == .bulk ? "This ask changes many things" : "This ask changes the shape of a plan or a list"
        let match = asked.map { " He named \($0); the rehearsal checks the changes match." } ?? ""
        return "\(why). Rehearse first: call rehearse with the calls you would make; it writes nothing.\(match) "
            + "If every check passes, make the same calls. If not, change nothing and tell him what went wrong."
    }
}
