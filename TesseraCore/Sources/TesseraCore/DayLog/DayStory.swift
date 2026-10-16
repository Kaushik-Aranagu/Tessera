import Foundation

/// One line of the Day log (docs/research/day-log-first.md, day-log-acceptance.md, Design's day-log-v1.md).
public struct DayLine: Equatable, Sendable {
    /// Which tier the page draws it in, so it never reads that out of the text (K8).
    public enum Kind: String, Sendable, Equatable {
        /// A thing that happened and is done: a finished workout, a cook, a capture, a note.
        case finished
        /// Today's workout, under way: numbers swap as sets land.
        case running
        /// A past workout never finished: the faint row, no words about it.
        case unfinished
        /// "Rest day", first, no time.
        case rest
        /// "Also: …", last, no time.
        case tail
    }

    /// When it started; nil for "Rest day" and the "Also:" tail.
    public let time: Date?
    /// Plain spaces around ×; the page swaps in no-break spaces when it draws.
    public let text: String
    /// What a tap opens (the first).
    public let objectIDs: [UUID]
    public let kind: Kind

    public init(time: Date?, text: String, objectIDs: [UUID], kind: Kind) {
        self.time = time
        self.text = text
        self.objectIDs = objectIDs
        self.kind = kind
    }

    /// "07:10": the column, 24 h, zero padded, in the calendar's zone (the zone he's in now).
    public func clock(_ calendar: Calendar) -> String? {
        time.map { DayStory.clock($0, calendar: calendar) }
    }

    /// "7:10 am, Push Day A, 52 minutes. Bench 82.5 by 8, PR." for VoiceOver.
    public func spoken(_ calendar: Calendar) -> String {
        let words = text.replacingOccurrences(of: " × ", with: " by ")
            .replacing(/(\d+) min\b/) { "\($0.1) minutes" }
        guard let time else { return words }
        return "\(DayStory.sentenceTime(time, calendar: calendar)), \(words)"
    }
}

/// What the fold needs to know about objects; the store in the app, a fake in a test if wanted.
@MainActor
public protocol DayLookup {
    func title(of id: UUID) -> String?
    /// The class's system key ("task", "note", "workout", "listItem"…).
    func kind(of id: UUID) -> String?
    func parent(of id: UUID) -> UUID?
    /// The workout above this object (entry or set), or the object itself when it is one.
    func groupRoot(of id: UUID) -> UUID?
    /// The root's own day time: a workout's `startedAt`, else the object's `createdAt` (a past-dated note's `on`).
    func dayTime(of id: UUID) -> Date?
    /// The zone of the record that created or started the root; nil means the calendar's zone (pre-v3 rows).
    func dayZone(of id: UUID) -> TimeZone?
    /// A workout's facts.
    func workout(_ id: UUID) -> (title: String, startedAt: Date?, endedAt: Date?, sets: Int)?
    /// "Bench 82.5 × 8", and whether it beat a record.
    func topSet(inWorkout id: UUID) -> (text: String, isPR: Bool)?
    /// A field's key ("isDone"), for reading a record's values.
    func fieldKey(_ id: UUID) -> String?
}

/// Folds the op log into a day's story: records by action, by his 4 AM day, groups by their root's start, loose things
/// counted, at most 6 lines. Pure: it never writes, and the same input always reads the same.
public enum DayStory {
    public static let maxLines = 6

    /// The 04:00 day start for a moment.
    public static func dayStart(for date: Date, calendar: Calendar) -> Date {
        TesseraDay(calendar: calendar).start(of: date)
    }

    /// Workout actions that fold into the workout's one line.
    static let workoutActions: Set = ["startWorkout", "startRoutine", "logSet", "logNextSet", "logExercise",
                                      "addExercise", "swapExercise", "finishWorkout", "finishWorkoutEarly"]
    static let ownLines: [String: String] = ["createRecipe": "Saved", "createList": "New list:",
                                             "createRoutine": "New routine:", "createPlan": "New plan:"]
    /// Edits, reorders, plumbing: never a line (day-log-first.md, the 26 drops).
    static let dropped: Set = [
        "editSet", "editRecipe", "editNote", "renameObject", "renameListSection", "moveListItem", "clearDoneItems",
        "addSlot", "moveSlot", "editSlot", "removeSlot", "swapSlotExercise", "deleteObject",
        "removeRecipeFromGroceries", "moveTask", "rollForwardTasks", "waitOnTask", "startTask", "goToCookStep",
        "startKitchenTimer", "stopKitchenTimer", "startProcess", "saveContext", "suspendProcess", "resumeProcess",
        "endProcess", "writeSettings",
    ]

    /// Actions with their own fold rule (the rest are workout, own-line or dropped).
    static let folded: Set = ["startCooking", "finishCooking", "startShop", "finishShop", "createTask", "addGroceries",
                              "addRecipeToGroceries", "addListItem", "setTaskDone", "checkListItem", "createNote"]

    /// Whether an action has a rule here (a test fails when a new action has none).
    public static func hasRule(for action: String) -> Bool {
        workoutActions.contains(action) || ownLines[action] != nil || dropped.contains(action) || folded
            .contains(action)
    }

    /// The lines for one of his days (`day`: any moment in it, read in `calendar`). `now` decides running vs past;
    /// `isRestDay` puts "Rest day" first.
    /// One fold, rule by rule in day-log-first.md's order, so it reads against the spec top to bottom.
    @MainActor
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    public static func lines(for records: [OpRecord], on day: Date, calendar: Calendar, lookup: any DayLookup,
                             now: Date = .now, isRestDay: Bool = false) -> [DayLine]
    {
        let target = key(TesseraDay(calendar: calendar).day(of: day), in: calendar)
        let today = key(TesseraDay(calendar: calendar).day(of: now), in: calendar)
        func onDay(_ instant: Date, zone: TimeZone?) -> Bool {
            var zoned = calendar
            zoned.timeZone = zone ?? calendar.timeZone
            return key(TesseraDay(calendar: zoned).day(of: instant), in: zoned) == target
        }
        func zone(of record: OpRecord) -> TimeZone? {
            record.zone.flatMap(TimeZone.init(identifier:))
        }
        func valueSet(_ record: OpRecord, _ field: String) -> FieldValue? {
            for op in record.ops {
                if case let .setValue(_, id, _, new) = op, lookup.fieldKey(id) == field {
                    return new
                }
            }
            return nil
        }
        func created(_ record: OpRecord, kind: String) -> [UUID] {
            record.ops.compactMap { op in
                if case let .create(object, _, _, _) = op, lookup.kind(of: object) == kind {
                    return object
                }
                return nil
            }
        }

        let standing = records.filter { $0.state == .committed && $0.actor != .system }
            .sorted { $0.createdAt < $1.createdAt }
        // Same-day pairs cancel: a thing made and deleted that day, a done reopened.
        var deletedToday = Set<UUID>()
        var reopenedToday = Set<UUID>()
        for record in standing where onDay(record.createdAt, zone: zone(of: record)) {
            if record.action == "deleteObject" {
                for op in record.ops {
                    if case let .softDelete(object) = op {
                        deletedToday.insert(object)
                    }
                }
            }
            if record.action == "setTaskDone", valueSet(record, "isDone") == .bool(false) {
                reopenedToday.formUnion(record.objectIDs)
            }
        }

        var lines: [DayLine] = []
        var seenRoots = Set<UUID>()
        // Loose counts, each at its first time.
        struct Count {
            var time: Date
            var objects: [UUID] = []
            var titles: [String] = []
        }
        var tasks: Count?, groceries: Count?, dones: Count?, notes: Count?
        var ticks: [UUID: Count] = [:]
        func add(_ count: inout Count?, at time: Date, objects: [UUID], titles: [String] = []) {
            if count == nil {
                count = Count(time: time)
            }
            count?.objects += objects
            count?.titles += titles
        }

        for record in standing where !dropped.contains(record.action) {
            let action = record.action
            // Workouts: one line per workout, on the day it started.
            if workoutActions.contains(action) {
                guard let root = record.objectIDs.lazy.compactMap({ lookup.groupRoot(of: $0) }).first,
                      !seenRoots.contains(root), let workout = lookup.workout(root), let started = workout.startedAt,
                      onDay(started, zone: lookup.dayZone(of: root)) else { continue }
                seenRoots.insert(root)
                guard workout.sets > 0 else { continue } // a 0-set workout is no session
                let top = lookup.topSet(inWorkout: root)
                let topText = top.map { ". \($0.text)\($0.isPR ? ", PR" : "")." } ?? "."
                if let ended = workout.endedAt {
                    let minutes = Int((ended.timeIntervalSince(started) / 60).rounded())
                    lines.append(DayLine(time: started, text: "\(workout.title), \(minutes) min\(topText)",
                                         objectIDs: [root], kind: .finished))
                } else if onDay(now, zone: calendar.timeZone), target == today {
                    lines.append(DayLine(time: started, text: "\(workout.title), \(sets(workout.sets))",
                                         objectIDs: [root], kind: .running))
                } else {
                    lines.append(DayLine(time: started, text: "\(workout.title), \(sets(workout.sets))\(topText)",
                                         objectIDs: [root], kind: .unfinished))
                }
                continue
            }
            switch action {
            case "startCooking":
                guard let cook = record.objectIDs.first(where: { lookup.kind(of: $0) == "cook" }),
                      !seenRoots.contains(cook), onDay(record.createdAt, zone: zone(of: record)),
                      let finish = standing
                      .first(where: { $0.action == "finishCooking" && $0.objectIDs.contains(cook) })
                else { continue }
                seenRoots.insert(cook)
                let minutes = Int((finish.createdAt.timeIntervalSince(record.createdAt) / 60).rounded())
                lines.append(DayLine(time: record.createdAt,
                                     text: "Cooked \(lookup.title(of: cook) ?? "it"), \(minutes) min",
                                     objectIDs: [cook], kind: .finished))
            case "startShop":
                guard onDay(record.createdAt, zone: zone(of: record)),
                      let finish = standing
                      .first(where: { $0.action == "finishShop" && $0.createdAt >= record.createdAt })
                else { continue }
                let items = finish.ops.count {
                    if case .softDelete = $0 {
                        true
                    } else {
                        false
                    }
                }
                guard items > 0 else { continue }
                lines.append(DayLine(time: record.createdAt,
                                     text: "Shopped, \(items) \(items == 1 ? "item" : "items")",
                                     objectIDs: [Groceries.listID], kind: .finished))
            case "createTask":
                let made = created(record, kind: "task").filter { !deletedToday.contains($0) }
                guard !made.isEmpty, onDay(record.createdAt, zone: zone(of: record)) else { continue }
                add(&tasks, at: record.createdAt, objects: made)
            case "addGroceries", "addRecipeToGroceries", "addListItem":
                let made = created(record, kind: "listItem")
                    .filter { lookup.parent(of: $0) == Groceries.listID && !deletedToday.contains($0) }
                guard !made.isEmpty, onDay(record.createdAt, zone: zone(of: record)) else { continue }
                add(&groceries, at: record.createdAt, objects: made)
            case "setTaskDone":
                guard valueSet(record, "isDone") == .bool(true), onDay(record.createdAt, zone: zone(of: record))
                else { continue }
                let done = record.objectIDs.filter { lookup.kind(of: $0) == "task" && !reopenedToday.contains($0) }
                add(&dones, at: record.createdAt, objects: done, titles: done.compactMap(lookup.title))
            case "checkListItem":
                guard valueSet(record, "isDone") == .bool(true), onDay(record.createdAt, zone: zone(of: record))
                else { continue }
                for item in record.objectIDs where lookup.kind(of: item) == "listItem" {
                    guard let list = lookup.parent(of: item), list != Groceries.listID else { continue }
                    var count: Count? = ticks[list]
                    add(&count, at: record.createdAt, objects: [item])
                    ticks[list] = count
                }
            case "createNote":
                // A note said afterwards lands on the day it's about (its own createdAt), in its record's zone.
                for note in created(record, kind: "note") where !deletedToday.contains(note) {
                    // A past-dated note ("watered the plants sat") carries its day as its own time, well before
                    // the record's; otherwise the record's time.
                    let own = lookup.dayTime(of: note) ?? record.createdAt
                    let time = own < record.createdAt.addingTimeInterval(-60) ? own : record.createdAt
                    guard onDay(time, zone: zone(of: record)) else { continue }
                    add(&notes, at: time, objects: [note], titles: [lookup.title(of: note) ?? "note"])
                }
            default:
                if let lead = ownLines[action] {
                    let key = String(action.dropFirst("create".count)).lowercased()
                    for object in created(record, kind: key) where !deletedToday.contains(object) {
                        guard onDay(record.createdAt, zone: zone(of: record)) else { continue }
                        lines.append(DayLine(time: record.createdAt, text: "\(lead) \(lookup.title(of: object) ?? "")",
                                             objectIDs: [object], kind: .finished))
                    }
                }
            }
        }

        // The loose counts, each one line at its first time.
        struct Loose {
            let line: DayLine
            let size: Int
            let tail: String
        }
        var loose: [Loose] = []
        if tasks != nil || groceries != nil {
            let first = min(tasks?.time ?? .distantFuture, groceries?.time ?? .distantFuture)
            var parts: [String] = []
            if let tasks {
                parts.append("\(tasks.objects.count) \(tasks.objects.count == 1 ? "task" : "tasks")")
            }
            if let groceries {
                parts.append("\(groceries.objects.count) \(groceries.objects.count == 1 ? "grocery" : "groceries")")
            }
            let size = (tasks?.objects.count ?? 0) + (groceries?.objects.count ?? 0)
            loose.append(Loose(line: DayLine(time: first, text: "Added \(parts.joined(separator: ", "))",
                                             objectIDs: (tasks?.objects ?? []) + (groceries?.objects ?? []),
                                             kind: .finished),
                               size: size, tail: parts.joined(separator: ", ")))
        }
        if let dones, !dones.objects.isEmpty {
            let text = dones.objects.count <= 2 ? "Done: \(dones.titles.joined(separator: ", "))"
                : "\(dones.objects.count) tasks done"
            loose.append(Loose(line: DayLine(time: dones.time, text: text, objectIDs: dones.objects, kind: .finished),
                               size: dones.objects.count, tail: "\(dones.objects.count) done"))
        }
        if let notes {
            let text = notes.objects.count == 1 ? "Note: \(notes.titles[0])" : "\(notes.objects.count) notes"
            loose.append(Loose(line: DayLine(time: notes.time, text: text, objectIDs: notes.objects, kind: .finished),
                               size: notes.objects.count,
                               tail: "\(notes.objects.count) \(notes.objects.count == 1 ? "note" : "notes")"))
        }
        for (list, count) in ticks.sorted(by: { $0.value.time < $1.value.time }) {
            let name = lookup.title(of: list) ?? "a list"
            loose.append(Loose(line: DayLine(time: count.time, text: "Ticked \(count.objects.count) on \(name)",
                                             objectIDs: [list] + count.objects, kind: .finished),
                               size: count.objects.count, tail: "ticked \(count.objects.count) on \(name)"))
        }

        // At most 6 lines: groups and own lines first, then the largest counts; the rest is one "Also:" tail.
        let room = maxLines - lines.count - (isRestDay ? 1 : 0)
        if loose.count > room, room >= 1 {
            let ranked = loose.sorted { ($0.size, $1.line.time ?? .distantFuture) > (
                $1.size,
                $0.line.time ?? .distantFuture
            ) }
            let kept = Array(ranked.prefix(room - 1))
            let rest = ranked.dropFirst(room - 1)
                .sorted { ($0.line.time ?? .distantFuture) < ($1.line.time ?? .distantFuture) }
            lines += kept.map(\.line)
            lines.append(DayLine(time: nil, text: "Also: \(rest.map(\.tail).joined(separator: ", ")).",
                                 objectIDs: rest.flatMap(\.line.objectIDs), kind: .tail))
        } else {
            lines += loose.map(\.line)
        }
        // By instant, never by the "HH:mm" text; the tail last.
        lines.sort { lhs, rhs in
            switch (lhs.time, rhs.time) {
            case let (left?, right?): left < right
            case (_?, nil): true
            default: false
            }
        }
        if isRestDay {
            lines.insert(DayLine(time: nil, text: "Rest day", objectIDs: [], kind: .rest), at: 0)
        }
        return lines
    }

    static func sets(_ count: Int) -> String {
        "\(count) \(count == 1 ? "set" : "sets")"
    }

    /// (year, month, day) of a day key, in the calendar it was made with.
    static func key(_ date: Date, in calendar: Calendar) -> DateComponents {
        calendar.dateComponents([.year, .month, .day], from: date)
    }

    static func clock(_ date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", parts.hour ?? 0, parts.minute ?? 0)
    }

    /// "6:12 pm", "11:20 pm", "12 pm".
    static func sentenceTime(_ date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        let hour = parts.hour ?? 0, minute = parts.minute ?? 0
        let twelve = hour % 12 == 0 ? 12 : hour % 12
        let half = hour < 12 ? "am" : "pm"
        return minute == 0 ? "\(twelve) \(half)" : String(format: "%d:%02d %@", twelve, minute, half)
    }
}

/// The Day log's view of the store: titles as stored, a workout's facts and top set, each root's day zone.
@MainActor
public struct StoreDayLookup: DayLookup {
    public let store: ObjectStore
    public let classes: [SystemCatalog.Key: ClassDef]
    let records: [OpRecord]
    let fields: [UUID: String]

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef], records: [OpRecord]) {
        self.store = store
        self.classes = classes
        self.records = records
        fields = Dictionary(
            store.context.all(FieldDef.self).map { ($0.id, $0.key) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    public func title(of id: UUID) -> String? {
        store.object(id: id).map(\.title)
    }

    public func kind(of id: UUID) -> String? {
        guard let classDef = store.object(id: id)?.classDef else { return nil }
        for (key, system) in classes where key != .thing && store.isSubclass(classDef, ofClassID: system.id) {
            if classDef.id == system.id {
                return key.rawValue
            }
        }
        return classes.first { store.isSubclass(classDef, ofClassID: $0.value.id) && $0.key != .thing }?.key.rawValue
    }

    public func parent(of id: UUID) -> UUID? {
        store.object(id: id)?.parent?.id
    }

    public func groupRoot(of id: UUID) -> UUID? {
        var object = store.object(id: id)
        while let current = object {
            if kind(of: current.id) == "workout" {
                return current.id
            }
            object = current.parent
        }
        return nil
    }

    public func dayTime(of id: UUID) -> Date? {
        guard let object = store.object(id: id) else { return nil }
        return store.value("startedAt", of: object)?.dateValue ?? object.createdAt
    }

    public func dayZone(of id: UUID) -> TimeZone? {
        records
            .first { ["startWorkout", "startRoutine", "logExercise"].contains($0.action) && $0.objectIDs.contains(id) }
            .flatMap(\.zone).flatMap(TimeZone.init(identifier:))
            ?? records.first { record in
                record.ops.contains {
                    if case let .create(object, _, _, _) = $0 {
                        object == id
                    } else {
                        false
                    }
                }
            }.flatMap(\.zone).flatMap(TimeZone.init(identifier:))
    }

    public func workout(_ id: UUID) -> (title: String, startedAt: Date?, endedAt: Date?, sets: Int)? {
        guard let workout = store.object(id: id) else { return nil }
        let sets = workout.orderedChildren.reduce(0) { total, entry in
            total + entry.orderedChildren.count { !$0.isDeleted && store.number("reps", of: $0) != nil }
        }
        return (store.displayTitle(of: workout), store.value("startedAt", of: workout)?.dateValue,
                store.value("endedAt", of: workout)?.dateValue, sets)
    }

    public func topSet(inWorkout id: UUID) -> (text: String, isPR: Bool)? {
        guard let workout = store.object(id: id) else { return nil }
        var best: (e1rm: Double, text: String, exercise: String, weight: Double, reps: Double)?
        for entry in workout.orderedChildren {
            let name = Self.shortName(store.linkedClass("exercise", of: entry)?.name ?? entry.title)
            for set in entry.orderedChildren where !set.isDeleted {
                guard let weight = store.number("weight", of: set), let reps = store.number("reps", of: set) else {
                    continue
                }
                if store.value("kind", of: set) == .choice("warmup") {
                    continue
                }
                let e1rm = weight * (1 + reps / 30)
                if best == nil || e1rm > best!.e1rm { // swiftlint:disable:this force_unwrapping
                    best = (e1rm, "\(name) \(Self.number(weight)) × \(Self.number(reps))", name, weight, reps)
                }
            }
        }
        guard let best else { return nil }
        let records = TrainingLedger(store: store, classes: classes).summary(of: workout).records
        let isPR = records.contains { $0.weight == best.weight && $0.reps == best.reps }
        return (best.text, isPR)
    }

    public func fieldKey(_ id: UUID) -> String? {
        fields[id]
    }

    static func shortName(_ name: String) -> String {
        ["Bench Press": "Bench", "Back Squat": "Squat", "Barbell Row": "Row", "Incline Bench Press": "Incline",
         "Overhead Press": "Press"][name] ?? name
    }

    static func number(_ value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(format: "%g", value)
    }
}

@MainActor
public extension DayStory {
    /// The app's call: the store's committed history for one of his days.
    static func lines(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef], records: [OpRecord], on day: Date,
                      calendar: Calendar = .current, now: Date = .now, isRestDay: Bool = false) -> [DayLine]
    {
        lines(for: records, on: day, calendar: calendar,
              lookup: StoreDayLookup(store: store, classes: classes, records: records), now: now,
              isRestDay: isRestDay)
    }
}
