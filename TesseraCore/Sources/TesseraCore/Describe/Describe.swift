import Foundation

/// One past-tense line of an object's story: when it happened and what kind of change it was.
public struct DescribeLine: Equatable, Sendable {
    public let time: Date
    public let text: String

    public init(time: Date, text: String) {
        self.time = time
        self.text = text
    }
}

/// Round 5 Describe: one fixed sentence per class and a short past-tense story per object, both built on the phone
/// from the object and its op records. Never a money, body or health value; a private object gives its label (the
/// sentence) or no lines and a count (the story). Nothing here goes to Claude: Tess's code does not reference it.
@MainActor
public enum Describe {
    public static let maxStoryLines = 8
    public static let privateThing = "something private"

    // MARK: Sentence

    /// "Pay rent, due Friday." One template per class (task, workout, list item, recipe); nil for any other class.
    public static func sentence(_ object: ObjectRecord, in store: ObjectStore,
                                classes: [SystemCatalog.Key: ClassDef], calendar: Calendar = .current) -> String?
    {
        guard !object.isDeleted, let kind = kind(of: object, classes: classes) else { return nil }
        if let label = ObjectPrivacy.shownLabel(of: object, in: store, classes: classes) {
            // An item of a private list reads as an item, whatever wide label the export gave it.
            return kind == .listItem ? "Private item" : label
        }
        switch kind {
        case .task: return taskSentence(object, in: store, calendar: calendar)
        case .workout: return workoutSentence(object, in: store, classes: classes)
        case .listItem: return itemSentence(object, in: store, classes: classes)
        case .recipe: return recipeSentence(object, in: store)
        default: return nil
        }
    }

    private static func taskSentence(_ task: ObjectRecord, in store: ObjectStore, calendar: Calendar) -> String {
        let title = clean(task.title, fallback: "Task")
        if store.value("isDone", of: task) == .bool(true) {
            return "\(title), done."
        }
        let due = store.value("due", of: task)?.dateValue ?? store.value("startsAt", of: task)?.dateValue
        if let due {
            return "\(title), due \(TesseraDay.weekdayName(of: due, calendar: calendar))."
        }
        return "\(title), still to do."
    }

    private static func workoutSentence(_ workout: ObjectRecord, in store: ObjectStore,
                                        classes: [SystemCatalog.Key: ClassDef]) -> String
    {
        let routine = store.linkedObjects("routine", of: workout).first
        // A workout of a private routine is private even when its own title is plain: its words never print.
        if let routine, ObjectPrivacy.shownLabel(of: routine, in: store, classes: classes) != nil {
            return ObjectPrivacy.routineLabel
        }
        let title = clean(routine?.title ?? workout.title, fallback: "Workout")
        guard store.value("startedAt", of: workout)?.dateValue != nil else { return "\(title), planned." }
        guard store.value("endedAt", of: workout)?.dateValue != nil else { return "\(title), under way." }
        let ledger = TrainingLedger(store: store, classes: classes)
        var exercises = 0, sets = 0
        for entry in workout.orderedChildren where !entry.isDeleted {
            let counted = entry.orderedChildren.count { !$0.isDeleted && ledger.loggedSet($0) != nil }
            if counted > 0 {
                exercises += 1
                sets += counted
            }
        }
        return "\(title), \(count(exercises, "exercise")), \(count(sets, "set"))."
    }

    private static func itemSentence(_ item: ObjectRecord, in store: ObjectStore,
                                     classes _: [SystemCatalog.Key: ClassDef]) -> String
    {
        let name = clean(item.title, fallback: "Item")
        let done = store.value("isDone", of: item) == .bool(true) ? ", done" : ""
        guard let list = item.parent, !list.isDeleted else { return "\(name)\(done)." }
        // A private list makes its items private (shownLabel above); a name that only reads private here masks too.
        if ObjectPrivacy.isPrivateWord(list.title, in: store) {
            return "Private item"
        }
        return "\(name) on \(clean(list.title, fallback: "a list"))\(done)."
    }

    private static func recipeSentence(_ recipe: ObjectRecord, in store: ObjectStore) -> String {
        var parts = [clean(recipe.title, fallback: "Recipe")]
        if let serves = store.number("serves", of: recipe), serves > 0, serves < 1000 {
            parts.append("serves \(Self.number(serves))")
        }
        if let total = store.number("totalMinutes", of: recipe), total >= 1, total < 100_000 {
            parts.append(HouseTime.minutes(Int(total)))
        }
        return parts.joined(separator: ", ") + "."
    }

    // MARK: Story

    /// What changed, newest first, at most 8 lines. A private object, or a class that can carry money, body or health
    /// values, has none.
    public static func story(_ object: ObjectRecord, engine: ActionEngine, calendar: Calendar,
                             now: Date) -> [DescribeLine]
    {
        guard storyAllowed(object, engine: engine) else { return [] }
        return Array(allLines(object, engine: engine, calendar: calendar, now: now).prefix(maxStoryLines))
    }

    /// How many changes the story has in all ("3 changes"), also for a private object (a count, never a line). A
    /// class that can carry money, body or health values counts none.
    public static func storyCount(_ object: ObjectRecord, engine: ActionEngine) -> Int {
        guard kind(of: object, classes: engine.classes) != nil else { return 0 }
        let records = committed(touching: object, engine: engine)
        if isPrivate(object, in: engine.store, classes: engine.classes) {
            return records.count
        }
        return allLines(object, engine: engine, calendar: .current, now: .now).count
    }

    private static func storyAllowed(_ object: ObjectRecord, engine: ActionEngine) -> Bool {
        kind(of: object, classes: engine.classes) != nil
            && !isPrivate(object, in: engine.store, classes: engine.classes)
    }

    /// The one private rule for a sentence, a story and a count: the object is private by its label, or it is a workout
    /// of a private routine (even when its own title is plain).
    public static func isPrivate(_ object: ObjectRecord, in store: ObjectStore,
                          classes: [SystemCatalog.Key: ClassDef]) -> Bool
    {
        if ObjectPrivacy.shownLabel(of: object, in: store, classes: classes) != nil {
            return true
        }
        guard object.classDef?.id == classes[.workout]?.id,
              let routine = store.linkedObjects("routine", of: object).first else { return false }
        return ObjectPrivacy.shownLabel(of: routine, in: store, classes: classes) != nil
    }

    private static func committed(touching object: ObjectRecord, engine: ActionEngine) -> [OpRecord] {
        engine.history(of: object.id, limit: .max).filter { $0.state == .committed && $0.actor != .system }
    }

    private static func allLines(_ object: ObjectRecord, engine: ActionEngine, calendar: Calendar,
                                 now: Date) -> [DescribeLine]
    {
        let store = engine.store
        var keys: [UUID: String] = [:]
        for field in store.context.all(FieldDef.self) where keys[field.id] == nil {
            keys[field.id] = field.key
        }
        func day(_ date: Date) -> String {
            calendar.isDate(date, inSameDayAs: now) ? "today" : TesseraDay.weekdayName(of: date, calendar: calendar)
        }
        var lines: [DescribeLine] = []
        for record in committed(touching: object, engine: engine) {
            let ops = record.ops.filter { $0.objectID == object.id }
            let creating = ops.contains {
                if case .create = $0 {
                    true
                } else {
                    false
                }
            }
            // Newest first, so inside one record the later op comes first too.
            for op in ops.reversed() {
                switch op {
                case .create:
                    lines.append(.init(time: record.createdAt, text: "Made \(day(record.createdAt))."))
                case .setTitle where !creating:
                    lines.append(.init(time: record.createdAt, text: "Renamed \(day(record.createdAt))."))
                case let .setValue(_, field, _, new) where !creating:
                    if let text = valueLine(key: keys[field], new: new, object: object, engine: engine,
                                            day: day, at: record.createdAt)
                    {
                        lines.append(.init(time: record.createdAt, text: text))
                    }
                case let .setLinks(_, _, old, new):
                    for target in new where !old.contains(target) {
                        if let name = linkName(target, engine: engine) {
                            lines.append(.init(time: record.createdAt, text: "Linked to \(name)."))
                        }
                    }
                case .softDelete:
                    lines.append(.init(time: record.createdAt, text: "Deleted."))
                case .restore:
                    lines.append(.init(time: record.createdAt, text: "Restored."))
                default: break
                }
            }
        }
        return lines
    }

    /// Only the kind of change for a known key; never the old or new text.
    private static func valueLine(key: String?, new: FieldValue?, object: ObjectRecord, engine: ActionEngine,
                                  day: (Date) -> String, at time: Date) -> String?
    {
        guard let key else { return nil }
        let isItem = kind(of: object, classes: engine.classes) == .listItem
        switch key {
        case "isDone":
            guard let done = new.map({ $0 == .bool(true) }) else { return nil }
            if done {
                return isItem ? "Checked off \(day(time))." : "Done \(day(time))."
            }
            return isItem ? "Unchecked \(day(time))." : "Reopened \(day(time))."
        case "startsAt", "due", "dueAt", "scheduledFor":
            guard let date = new?.dateValue else { return "Date cleared \(day(time))." }
            return "Moved to \(day(date))."
        case "startedAt":
            return new == nil ? nil : "Started \(day(time))."
        case "endedAt":
            return new == nil ? nil : "Finished \(day(time))."
        default:
            return nil
        }
    }

    private static func linkName(_ target: LinkTarget, engine: ActionEngine) -> String? {
        switch target {
        case let .classDef(id):
            return engine.store.classDef(id: id)?.name
        case let .object(id):
            guard let other = engine.store.object(id: id), !other.isDeleted else { return nil }
            if ObjectPrivacy.shownLabel(of: other, in: engine.store, classes: engine.classes) != nil
                || ObjectPrivacy.isPrivateWord(other.title, in: engine.store)
            {
                return privateThing
            }
            let title = clean(other.title, fallback: "")
            return title.isEmpty ? nil : title
        }
    }

    // MARK: Helpers

    /// The classes Describe speaks about. Money, body and health classes (spend, pool, profile, weigh-ins) are not
    /// here, so they get no sentence and no story.
    private enum Kind { case task, workout, routine, listItem, list, recipe, note }

    private static func kind(of object: ObjectRecord, classes: [SystemCatalog.Key: ClassDef]) -> Kind? {
        guard let classDef = object.classDef else { return nil }
        let table: [(SystemCatalog.Key, Kind)] = [(.task, .task), (.workout, .workout), (.routine, .routine),
                                                  (.listItem, .listItem), (.list, .list), (.recipe, .recipe),
                                                  (.note, .note)]
        return table.first { key, _ in classes[key].map { ClassResolver.isSubclass(classDef, of: $0) } ?? false }?.1
    }

    private static func count(_ value: Int, _ noun: String) -> String {
        "\(value) \(noun)\(value == 1 ? "" : "s")"
    }

    private static func number(_ value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(format: "%g", value)
    }

    /// A title as it reads in a sentence: no "!" and no em dash, no closing full stop, spaces trimmed.
    private static func clean(_ text: String, fallback: String) -> String {
        var out = text.replacingOccurrences(of: "!", with: "")
            .replacingOccurrences(of: "\u{2014}", with: ",")
            .replacingOccurrences(of: "\u{2013}", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        while out.hasSuffix(".") || out.hasSuffix(",") {
            out.removeLast()
        }
        out = out.trimmingCharacters(in: .whitespaces)
        return out.isEmpty ? fallback : out
    }
}
