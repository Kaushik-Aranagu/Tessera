import Foundation
import TesseraCore

/// The deterministic first step: gym shorthand and dated tasks, parsed instantly and offline.
/// Returns typed actions; it never writes. Anything it doesn't recognise goes to the model.
@MainActor
public struct TessGrammar {
    public enum Parse {
        /// Log sets of a named exercise (into the entry in focus if it's the same exercise, else today's workout).
        case lift(exercise: ClassDef, sets: Int, reps: Double, weight: Double)
        /// A set in the entry in focus: "same", "8", "80 x 8", "drop to 70 for 10".
        case set(entry: ObjectRecord, weight: Double, reps: Double, kind: SetKind, phrase: SetPhrase)
        case task(title: String, startsAt: Date?)
    }

    public enum SetPhrase: Equatable, Sendable {
        case same, repsOnly, full, drop
    }

    public let store: ObjectStore
    public let classes: [SystemCatalog.Key: ClassDef]

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) {
        self.store = store
        self.classes = classes
    }

    public func parse(_ phrase: String, context: TessContext) -> Parse? {
        let text = Self.normalize(phrase)
        guard !text.isEmpty else { return nil }
        let entry = context.entry.flatMap { store.object(id: $0) }
        if let entry, let parsed = parseRelativeSet(text, entry: entry) {
            return parsed
        }
        if let lift = parseLift(text, entry: entry) {
            return lift
        }
        return parseTask(phrase, context: context)
    }

    // MARK: Sets in focus

    private func parseRelativeSet(_ text: String, entry: ObjectRecord) -> Parse? {
        let last = lastSet(in: entry)
        if ["same", "same again", "again", "repeat", "one more"].contains(text), let last {
            return .set(entry: entry, weight: last.weight, reps: last.reps, kind: .working, phrase: .same)
        }
        if let reps = Self.number(text), reps.rounded() == reps, reps >= 1, reps <= 100, let last {
            return .set(entry: entry, weight: last.weight, reps: reps, kind: .working, phrase: .repsOnly)
        }
        if let match = text.firstMatch(of: /^drop(?: to)? (\d+(?:\.\d+)?)(?: kg)? (?:for|x) (\d+)$/),
           let weight = Double(match.1), let reps = Double(match.2)
        {
            return .set(entry: entry, weight: weight, reps: reps, kind: .drop, phrase: .drop)
        }
        if let match = text.firstMatch(of: /^(\d+(?:\.\d+)?)(?: kg)? (?:x|for) (\d+)$/),
           let weight = Double(match.1), let reps = Double(match.2)
        {
            return .set(entry: entry, weight: weight, reps: reps, kind: .working, phrase: .full)
        }
        return nil
    }

    private func lastSet(in entry: ObjectRecord) -> (weight: Double, reps: Double)? {
        for set in entry.orderedChildren.reversed() {
            if let weight = store.number("weight", of: set), let reps = store.number("reps", of: set) {
                return (weight, reps)
            }
        }
        return nil
    }

    // MARK: Named lifts

    /// "3x10 bench 80", "bench 3x10 80", "bench 80x8", "bench 80 for 8", "bench 3x8 at 80", "squat 100 5".
    private func parseLift(_ text: String, entry: ObjectRecord?) -> Parse? {
        var sets = 1
        var reps: Double?
        var weight: Double?
        var words: [Substring] = []
        var rest = Substring(text)

        if let scheme = rest.firstMatch(of: /(\d+) ?x ?(\d+)(?: (?:at|@) (\d+(?:\.\d+)?))?/) {
            let first = Double(scheme.1) ?? 0
            let second = Double(scheme.2) ?? 0
            if let atWeight = scheme.3.flatMap({ Double($0) }) {
                // "3x8 at 80": sets x reps at weight.
                sets = Int(first)
                reps = second
                weight = atWeight
            } else if first <= 10, second <= 30, Self.hasOtherNumber(rest, excluding: scheme.range) {
                // "3x10 bench 80": sets x reps, weight elsewhere.
                sets = Int(first)
                reps = second
            } else {
                // "80x8": weight x reps.
                weight = first
                reps = second
            }
            rest.removeSubrange(scheme.range)
        }
        for token in rest.split(separator: " ") {
            if let value = Double(token) {
                if weight == nil {
                    weight = value
                } else if reps == nil {
                    reps = value
                }
            } else if !["kg", "for", "at", "@", "of", "x", "sets", "reps"].contains(token) {
                words.append(token)
            }
        }
        guard let reps, let weight, !words.isEmpty, (1 ... 20).contains(sets), reps >= 1, reps <= 100,
              reps.rounded() == reps, weight > 0, weight <= 1000,
              let exercise = resolveExercise(words.joined(separator: " ")) else { return nil }
        if let entry, sets == 1, store.linkedClass("exercise", of: entry)?.id == exercise.id {
            return .set(entry: entry, weight: weight, reps: reps, kind: .working, phrase: .full)
        }
        return .lift(exercise: exercise, sets: sets, reps: reps, weight: weight)
    }

    private static func hasOtherNumber(_ text: Substring, excluding range: Range<Substring.Index>) -> Bool {
        var copy = text
        copy.removeSubrange(range)
        return copy.split(separator: " ").contains { Double($0) != nil }
    }

    /// Common gym names for built-in lifts.
    static let aliases: [String: String] = [
        "bench": "bench press", "bp": "bench press", "ohp": "overhead press", "press": "overhead press",
        "squat": "back squat", "squats": "back squat", "dl": "deadlift", "deads": "deadlift",
        "rdl": "romanian deadlift", "row": "barbell row", "rows": "barbell row", "pullups": "pull-up",
        "pull ups": "pull-up", "chinups": "chin-up", "curls": "curl", "dips": "dip", "lat pulldown": "lat pulldown",
    ]

    /// The exercise class whose name best matches: exact, then alias, then every word contained, shortest first.
    public func resolveExercise(_ query: String) -> ClassDef? {
        guard let root = classes[.exercise] else { return nil }
        let candidates = ClassResolver.descendants(of: root).filter { $0.id != root.id }
        let normalized = Self.normalize(query)
        let target = Self.aliases[normalized] ?? normalized
        let names = candidates.map { ($0, Self.normalize($0.name)) }
        if let exact = names.first(where: { $0.1 == target || $0.1 == normalized }) {
            return exact.0
        }
        let words = target.split(separator: " ").map { $0.hasSuffix("s") && $0.count > 3 ? $0.dropLast() : $0 }
        return names
            .filter { _, name in words.allSatisfy { name.contains($0) } }
            .min { $0.1.count < $1.1.count }?.0
    }

    // MARK: Tasks

    /// A task with a day or time cue ("dentist thu 3pm"), or one that says it's a task ("todo call mum").
    private func parseTask(_ phrase: String, context: TessContext) -> Parse? {
        var words = phrase.split(separator: " ").map(String.init)
        var explicit = false
        if let first = words.first?.lowercased().trimmingCharacters(in: .punctuationCharacters),
           ["todo", "task", "remind"].contains(first)
        {
            explicit = true
            words.removeFirst()
            if words.first?.lowercased() == "me" {
                words.removeFirst()
            }
            if words.first?.lowercased() == "to" {
                words.removeFirst()
            }
        }
        let (date, remaining) = TessDates.extract(from: words, now: context.now, calendar: context.calendar)
        let title = remaining.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, explicit || date != nil else { return nil }
        return .task(title: title.prefix(1).uppercased() + title.dropFirst(), startsAt: date)
    }

    // MARK: Helpers

    static func normalize(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: "×", with: "x")
            .replacingOccurrences(of: ",", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .trimmingCharacters(in: .punctuationCharacters)
    }

    static func number(_ text: String) -> Double? {
        Double(text.replacingOccurrences(of: " reps", with: ""))
    }
}

/// Finds a day and time in a phrase: "thu 3pm", "tomorrow", "today 18:30", "friday at 9".
enum TessDates {
    static let weekdays: [String: Int] = [
        "sun": 1, "sunday": 1, "mon": 2, "monday": 2, "tue": 3, "tues": 3, "tuesday": 3, "wed": 4, "wednesday": 4,
        "thu": 5, "thur": 5, "thurs": 5, "thursday": 5, "fri": 6, "friday": 6, "sat": 7, "saturday": 7,
    ]

    static func extract(from words: [String], now: Date, calendar: Calendar) -> (Date?, [String]) {
        var day: Date?
        var time: (hour: Int, minute: Int)?
        var remaining: [String] = []
        var index = 0
        while index < words.count {
            let word = words[index].lowercased().trimmingCharacters(in: .punctuationCharacters)
            if word == "today" || word == "tonight" {
                day = calendar.startOfDay(for: now)
                if word == "tonight", time == nil {
                    time = (20, 0)
                }
            } else if word == "tomorrow" || word == "tmrw" {
                day = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
            } else if let weekday = weekdays[word] {
                day = nextDate(weekday: weekday, after: now, calendar: calendar)
            } else if word == "at", index + 1 < words.count, let parsed = parseTime(words[index + 1].lowercased()) {
                time = parsed
                index += 1
            } else if let parsed = parseTime(word), word.contains(where: \.isLetter) || word.contains(":") {
                time = parsed
            } else {
                remaining.append(words[index])
            }
            index += 1
        }
        guard day != nil || time != nil else { return (nil, words) }
        var base = day ?? calendar.startOfDay(for: now)
        if day == nil, let time,
           let candidate = calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: base),
           candidate <= now
        {
            base = calendar.date(byAdding: .day, value: 1, to: base) ?? base
        }
        let (hour, minute) = time ?? (9, 0)
        return (calendar.date(bySettingHour: hour, minute: minute, second: 0, of: base), remaining)
    }

    /// The next given weekday; today counts only if it hasn't passed (it's the same day, so we keep it).
    static func nextDate(weekday: Int, after now: Date, calendar: Calendar) -> Date? {
        let today = calendar.component(.weekday, from: now)
        let offset = (weekday - today + 7) % 7
        return calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now))
    }

    /// "3pm", "3:30pm", "15:00", "9" (with "at"), "noon".
    static func parseTime(_ text: String) -> (hour: Int, minute: Int)? {
        let word = text.trimmingCharacters(in: .punctuationCharacters)
        if word == "noon" {
            return (12, 0)
        }
        guard let match = word.firstMatch(of: /^(\d{1,2})(?::(\d{2}))?(am|pm)?$/), let hour = Int(match.1) else {
            return nil
        }
        let minute = match.2.flatMap { Int($0) } ?? 0
        var result = hour
        if match.3 == "pm", hour < 12 {
            result += 12
        }
        if match.3 == "am", hour == 12 {
            result = 0
        }
        guard (0 ... 23).contains(result), (0 ... 59).contains(minute) else { return nil }
        return (result, minute)
    }
}
