import Foundation

// Landing pages talk (design/landing-pages-131.md): every sentence is computed on the phone from a fixed template and
// numbers it is handed. Nothing here is ever sent to Claude, a log, a backup or a widget: walled titles, money
// values, health, body and calorie facts stay on this phone, and the names that come in are already masked
// (`LandingNames`). A sentence is plain text plus the one key word the page draws in the app's accent.

public struct LandingSentence: Sendable, Hashable {
    public let text: String
    /// The word the page draws in the accent; always a substring of `text`, or nil.
    public let key: String?
}

public enum LandingNames {
    /// What a page shows for a thing: its words, or its private label when it is walled.
    @MainActor
    public static func shown(_ object: ObjectRecord, in store: ObjectStore,
                             classes: [SystemCatalog.Key: ClassDef]) -> String
    {
        ObjectPrivacy.shownLabel(of: object, in: store, classes: classes) ?? object.title
    }
}

public enum LandingSentences {
    // MARK: Training

    /// "Push A today, about 45 min. Bench opens at 82.5." The one number lives inside the sentence. Without a length
    /// or an opening lift the sentence is shorter; with nothing planned it is "Nothing planned today."
    public static func training(session: String?, minutes: Int?, opener: (exercise: String, weight: String)?)
        -> LandingSentence
    {
        guard let session else { return LandingSentence(text: "Nothing planned today.", key: nil) }
        var text = "\(session) today"
        if let minutes, minutes > 0 {
            text += ", about \(HouseTime.minutes(minutes))"
        }
        text += "."
        if let opener {
            text += " \(opener.exercise) opens at \(opener.weight)."
        }
        return LandingSentence(text: text, key: session)
    }

    // MARK: Kitchen

    /// "Tacos tonight, start at 6:05. Lemon is short." The dish leads; the start and the one short thing follow when
    /// they are known.
    public static func kitchen(dish: String?, start: String?, shortOf: String?) -> LandingSentence {
        guard let dish else { return LandingSentence(text: "Nothing planned for tonight.", key: nil) }
        var text = "\(dish) tonight"
        if let start {
            text += ", start at \(start)"
        }
        text += "."
        if let shortOf {
            text += " \(shortOf) \(HouseWords.isPlural(shortOf) ? "are" : "is") short."
        }
        return LandingSentence(text: text, key: dish)
    }

    /// "Cooking tacos, 8 min left." above both doors while a cook runs.
    public static func cooking(dish: String, minutesLeft: Int?) -> String {
        var text = "Cooking \(lowered(dish))"
        if let minutesLeft, minutesLeft > 0 {
            text += ", \(HouseTime.minutes(minutesLeft)) left"
        }
        return text + "."
    }

    public static func toGet(_ count: Int) -> String? {
        count > 0 ? "\(count) to get" : nil
    }

    public static func covers(dinners count: Int) -> String? {
        count > 0 ? "covers \(count) \(count == 1 ? "dinner" : "dinners")" : nil
    }

    // MARK: Money

    /// "Nothing is late. Rent is due Friday, and October is running a little under September." Clauses, never
    /// figures; a late bill is left to the waiting band (no counts of what was missed, never shaming).
    public static func money(nothingLate: Bool, due: (name: String, weekday: String)?, trend: String?)
        -> LandingSentence
    {
        var sentences: [String] = []
        if nothingLate {
            sentences.append("Nothing is late.")
        }
        switch (due, trend) {
        case let (due?, trend?): sentences.append("\(due.name) is due \(due.weekday), and \(trend).")
        case let (due?, nil): sentences.append("\(due.name) is due \(due.weekday).")
        case let (nil, trend?): sentences.append(capitalised(trend) + ".")
        case (nil, nil): break
        }
        let text = sentences.isEmpty ? "Nothing to report." : sentences.joined(separator: " ")
        return LandingSentence(text: text, key: due?.name ?? (nothingLate ? "Nothing is late" : nil))
    }

    // MARK: Notes

    public static let notesPrompt = LandingSentence(text: "Search or write. @ links a thing.", key: "@")
    public static let linkThem = "Link them"
    public static let makeAThing = "Make it a thing"

    // MARK: Notes (T-N1 to T-N10)

    /// T-N1, T-N2, T-N3, T-N4: the subtitle. Names are masked by the caller; no digit ever appears.
    public static func notesSubtitle(hasNotes: Bool, top: [String]) -> LandingSentence {
        guard hasNotes else { return LandingSentence(text: "A place for loose thoughts.", key: nil) }
        switch top.count {
        case 0: return LandingSentence(text: "Your notes are on their own.", key: "own")
        case 1: return LandingSentence(text: "\(top[0]) comes up most.", key: top[0])
        default: return LandingSentence(text: "\(top[0]) and \(top[1]) come up most.", key: top[0])
        }
    }

    /// T-N5: "You write about A, B, C, and D." (two: "A and B"; one: "A").
    public static func youWriteAbout(_ names: [String]) -> LandingSentence? {
        let list = Array(names.prefix(4))
        switch list.count {
        case 0: return nil
        case 1: return LandingSentence(text: "You write about \(list[0]).", key: nil)
        case 2: return LandingSentence(text: "You write about \(list[0]) and \(list[1]).", key: nil)
        default:
            let head = list.dropLast().joined(separator: ", ")
            return LandingSentence(text: "You write about \(head), and \(list[list.count - 1]).", key: nil)
        }
    }

    /// T-N6: nothing matches what was typed.
    public static func noThingCalled(_ typed: String) -> LandingSentence {
        LandingSentence(text: "No thing called \"\(typed)\". Return writes it as a note.", key: nil)
    }

    /// T-N7: a note is open. "Private note" for a walled one.
    public static func noteOpen(title: String, isPrivate: Bool) -> LandingSentence {
        let name = isPrivate ? "Private note" : title
        return LandingSentence(text: "\(name) is open.", key: name)
    }

    /// T-N8.
    public static func notesNames(day: String, thing: String) -> LandingSentence {
        LandingSentence(text: "Your note from \(day) names \(thing).", key: thing)
    }

    /// T-N9.
    public static func notThingYet(_ word: String) -> LandingSentence {
        LandingSentence(text: "@\(word) is not a thing yet.", key: "@\(word)")
    }

    /// T-N10: "A new note about A.", "A new note about A and B.", "New notes about A and B.", "A new loose note."
    public static func newNotes(count: Int, about names: [String]) -> LandingSentence {
        let list = Array(names.prefix(2))
        let joined = list.joined(separator: " and ")
        if list.isEmpty {
            return count == 1 ? LandingSentence(text: "A new loose note.", key: nil)
                : LandingSentence(text: "New loose notes.", key: nil)
        }
        let text = count == 1 ? "A new note about \(joined)." : "New notes about \(joined)."
        return LandingSentence(text: text, key: list[0])
    }

    // MARK: Lists

    /// "6 left of 24", small, under the lead list's next items.
    public static func leftOf(left: Int, total: Int) -> String? {
        guard total > 0, left >= 0, left <= total else { return nil }
        return "\(left) left of \(total)"
    }

    /// "3 to get, new from Tacos" under a list's line that fills; the second part only when something new came.
    public static func listLine(toGet: Int, newFrom: String?) -> String? {
        guard toGet > 0 else { return nil }
        if let newFrom {
            return "\(toGet) to get, new from \(newFrom)"
        }
        return "\(toGet) to get"
    }

    // MARK: Lists (T-L1 to T-L13)

    public static let startOneList = LandingSentence(text: "Start one with a few words.", key: nil)
    public static let resetIt = "Reset it"

    /// T-L2 and T-L5 (a walled name arrives as "Private list").
    public static func listRunning(_ name: String, left: Int) -> LandingSentence {
        LandingSentence(text: "\(name) is running, \(left) left.", key: name)
    }

    /// T-L3.
    public static func listDue(_ name: String, day: String) -> LandingSentence {
        LandingSentence(text: "\(name) is due \(day).", key: name)
    }

    /// T-L4.
    public static func listTouchedLast(_ name: String) -> LandingSentence {
        LandingSentence(text: "\(name) is the one you touched last.", key: name)
    }

    /// T-L6.
    public static func listLeft(_ left: Int) -> String {
        "\(left) left"
    }

    /// T-L9.
    public static func listRunningLine(left: Int) -> String {
        "Running, \(left) left"
    }

    /// T-L10.
    public static func listDueLine(day: String, left: Int) -> String {
        "Due \(day), \(left) left"
    }

    /// T-L11.
    public static func itemDueTomorrow(_ item: String, on list: String) -> LandingSentence {
        LandingSentence(text: "\(item) is due tomorrow on \(list).", key: item)
    }

    /// T-L12.
    public static func listDoneReset(_ name: String) -> LandingSentence {
        LandingSentence(text: "\(name) is done. Reset it for next time", key: name)
    }

    /// T-L13: "Groceries has 4 new, from Tacos." or "Groceries has 4 new."
    public static func listHasNew(_ name: String, count: Int, from source: String?) -> LandingSentence {
        let tail = source.map { ", from \($0)" } ?? ""
        return LandingSentence(text: "\(name) has \(count) new\(tail).", key: name)
    }

    // MARK: Routines

    public static func routineRunning(_ name: String) -> LandingSentence {
        LandingSentence(text: "\(name) is running", key: name)
    }

    /// "4 min on this step"; under a minute it says so.
    public static func onThisStep(seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        return minutes < 1 ? "Under a minute on this step" : "\(HouseTime.minutes(minutes)) on this step"
    }

    public static let nothingRunning = LandingSentence(text: "Nothing is running", key: nil)

    // MARK: Words

    /// "Tacos" reads "tacos" mid-sentence; "BLT" and "Pad Thai" keep their capitals.
    static func lowered(_ dish: String) -> String {
        let letters = Array(dish)
        guard letters.count > 1, letters[0].isUppercase, letters[1].isLowercase else { return dish }
        return dish.prefix(1).lowercased() + dish.dropFirst()
    }

    static func capitalised(_ text: String) -> String {
        text.prefix(1).uppercased() + text.dropFirst()
    }
}
