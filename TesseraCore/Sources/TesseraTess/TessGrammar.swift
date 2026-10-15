import Foundation
import TesseraCore

/// The deterministic first step: gym shorthand and dated tasks, parsed instantly and offline.
/// Returns typed actions; it never writes. Anything it doesn't recognise goes to the model.
@MainActor
public struct TessGrammar {
    public enum Parse {
        /// Log sets of a named exercise (into the entry in focus if it's the same exercise, else today's workout).
        case lift(exercise: ClassDef, sets: Int, reps: Double, weight: Double, unit: MassUnit)
        /// A set in the entry in focus: "same", "8", "80 x 8", "drop to 70 for 10".
        /// `weight` is in kilograms; `unit` is how it was said.
        case set(entry: ObjectRecord, weight: Double, reps: Double, kind: SetKind, phrase: SetPhrase,
                 unit: MassUnit = .kilograms)
        case task(title: String, startsAt: Date?)
        /// "note: bar felt heavy" (or "note bar felt heavy").
        case note(body: String)
        /// Kitchen: "buy milk", "milk, eggs, 2 lemons".
        case groceries(lines: [String])
        /// "cook carbonara" (now, `on` nil) or "cook carbonara thu" (a dated task linking the recipe).
        case cook(recipe: ObjectRecord, on: Date?)
        /// "timer pasta 10", "10 min timer".
        case timer(label: String, minutes: Double)
        /// "list: packing".
        case list(name: String)
        /// "shop": start shopping the groceries list.
        case shop
        /// Pasted text with an Ingredients heading.
        case recipe(text: String)
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
        if let note = parseNote(phrase) {
            return note
        }
        if let recipe = parsePastedRecipe(phrase) {
            return recipe
        }
        let entry = context.entry.flatMap { store.object(id: $0) }
        if let entry, let parsed = parseRelativeSet(text, entry: entry) {
            return parsed
        }
        if let lift = parseLift(text, entry: entry) {
            return lift
        }
        // After lifts, so "bench 80x8, 82.5x6" stays a lift.
        if let kitchen = parseKitchen(phrase, context: context) {
            return kitchen
        }
        return parseTask(phrase, context: context)
    }

    /// "note: …" or "note …" at the start makes a note of the rest, keeping its text as typed.
    private func parseNote(_ phrase: String) -> Parse? {
        let trimmed = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let match = trimmed.firstMatch(of: /^(?i)note[:\s]\s*(.+)$/) else { return nil }
        let body = String(match.1).trimmingCharacters(in: .whitespacesAndNewlines)
        return body.isEmpty ? nil : .note(body: body)
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
        if let match = text.firstMatch(of: /^drop(?: to)? (\d+(?:\.\d+)?)(?: (kg|lb))? (?:for|x) (\d+)$/),
           let weight = Double(match.1), let reps = Double(match.3)
        {
            let unit = match.2.flatMap { MassUnit(parsing: String($0)) } ?? .kilograms
            return .set(entry: entry, weight: unit.toKilograms(weight), reps: reps, kind: .drop, phrase: .drop,
                        unit: unit)
        }
        if let match = text.firstMatch(of: /^(\d+(?:\.\d+)?)(?: (kg|lb))? (?:x|for) (\d+)$/),
           let weight = Double(match.1), let reps = Double(match.3)
        {
            let unit = match.2.flatMap { MassUnit(parsing: String($0)) } ?? .kilograms
            return .set(entry: entry, weight: unit.toKilograms(weight), reps: reps, kind: .working, phrase: .full,
                        unit: unit)
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
        var lift = LiftWords()
        var rest = Substring(text)
        if let scheme = rest.firstMatch(of: /(\d+) ?x ?(\d+)(?: (?:at|@) (\d+(?:\.\d+)?))?/) {
            lift.readScheme(Double(scheme.1) ?? 0, Double(scheme.2) ?? 0, at: scheme.3.flatMap { Double($0) },
                            weightElsewhere: Self.hasOtherNumber(rest, excluding: scheme.range))
            rest.removeSubrange(scheme.range)
        }
        rest.split(separator: " ").forEach { lift.read($0) }
        let (sets, unit, reps, weight, words) = (lift.sets, lift.unit, lift.reps, lift.weight, lift.words)
        guard let reps, let weight, !words.isEmpty, (1 ... 20).contains(sets), reps >= 1, reps <= 100,
              reps.rounded() == reps, weight > 0, unit.toKilograms(weight) <= 1000,
              let exercise = resolveExercise(words.joined(separator: " ")) else { return nil }
        if let entry, sets == 1, store.linkedClass("exercise", of: entry)?.id == exercise.id {
            return .set(entry: entry, weight: unit.toKilograms(weight), reps: reps, kind: .working, phrase: .full,
                        unit: unit)
        }
        return .lift(exercise: exercise, sets: sets, reps: reps, weight: weight, unit: unit)
    }

    /// The numbers and words of a lift phrase.
    private struct LiftWords {
        var sets = 1
        var unit = MassUnit.kilograms
        var reps: Double?
        var weight: Double?
        var words: [Substring] = []

        mutating func readScheme(_ first: Double, _ second: Double, at atWeight: Double?, weightElsewhere: Bool) {
            if let atWeight {
                // "3x8 at 80": sets x reps at weight.
                (sets, reps, weight) = (Int(first), second, atWeight)
            } else if first <= 10, second <= 30, weightElsewhere {
                // "3x10 bench 80": sets x reps, weight elsewhere.
                (sets, reps) = (Int(first), second)
            } else {
                // "80x8": weight x reps.
                (weight, reps) = (first, second)
            }
        }

        mutating func read(_ token: Substring) {
            if let parsed = MassUnit(parsing: String(token)) {
                unit = parsed
            } else if let value = Double(token) {
                if weight == nil {
                    weight = value
                } else if reps == nil {
                    reps = value
                }
            } else if !["for", "at", "@", "of", "x", "sets", "reps", "log", "logged", "add", "did"].contains(token) {
                words.append(token)
            }
        }
    }

    private static func hasOtherNumber(_ text: Substring, excluding range: Range<Substring.Index>) -> Bool {
        var copy = text
        copy.removeSubrange(range)
        return copy.split(separator: " ").contains { Double($0) != nil }
    }

    static let equipmentWords = ["db": "dumbbell", "bb": "barbell", "kb": "kettlebell", "ez": "ez"]

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
        let candidates = ClassResolver.descendants(of: root).filter { store.isConcreteExercise($0, root: root) }
        // Gym shorthand for equipment: "db press" is a dumbbell press.
        let normalized = Self.normalize(query).split(separator: " ")
            .map { Self.equipmentWords[String($0)] ?? String($0) }.joined(separator: " ")
        let target = Self.aliases[normalized] ?? normalized
        let names = candidates.map { ($0, Self.normalize($0.name)) }
        if let exact = names.first(where: { $0.1 == target || $0.1 == normalized }) {
            return exact.0
        }
        // Library exercises carry their own aliases ("Flat Bench", "RDL") on their class objects.
        for (classDef, _) in names {
            guard let aliases = store.classValue("aliases", of: classDef)?.stringValue else { continue }
            let list = aliases.split(separator: ",").map { Self.normalize(String($0)) }
            if list.contains(normalized) {
                return classDef
            }
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
            // "180lbs" and "80kg" become "180 lb" and "80 kg".
            .replacing(/(\d)(kgs?|lbs?)\b/) { "\($0.1) \($0.2.hasPrefix("k") ? "kg" : "lb")" }
            .replacing(/\blbs\b/, with: "lb")
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
        var fromWeekday = false
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
                fromWeekday = true
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
        var date = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: base)
        // "thu" on a Thursday evening means next Thursday, not this morning.
        if fromWeekday, let resolved = date, resolved <= now {
            date = calendar.date(byAdding: .day, value: 7, to: resolved)
        }
        return (date, remaining)
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
