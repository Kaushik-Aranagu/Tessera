import Foundation

/// Tasks for "Run my day" (M2). Overdue never shows as overdue: anything left undone rolls into today, quietly
/// counted, and deferring moves it forward without judgement.
@MainActor
public struct TaskList {
    public struct Item: Identifiable {
        public let id: UUID
        public let task: ObjectRecord
        public let title: String
        /// When it's planned to happen (startsAt), else its due date.
        public let when: Date?
        public let minutes: Double?
        public let isDone: Bool
        /// Left from an earlier day and carried into today (no red, no "overdue").
        public let isCarriedOver: Bool
        /// Nights it rolled forward (for the 7-roll rule; never shown as misses).
        public let rolls: Int
    }

    public let store: ObjectStore
    public let classes: [SystemCatalog.Key: ClassDef]

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) {
        self.store = store
        self.classes = classes
    }

    public func all() -> [Item] {
        guard let taskClass = classes[.task] else { return [] }
        return store.objects(of: taskClass).map { item($0, today: nil, calendar: .current) }
    }

    /// Today: undone tasks planned or due today, plus undone ones from earlier days, carried over; then what was
    /// done today. Ordered by time, with undated ones last.
    public func today(_ now: Date = .now, calendar: Calendar = .current) -> [Item] {
        guard let taskClass = classes[.task] else { return [] }
        // His day: 04:00 to 04:00 (TesseraDay), so a 23:00 task is still today at 01:00.
        let day = TesseraDay(calendar: calendar)
        let start = day.start(of: now), end = day.end(of: now)
        let today = day.day(of: now)
        // A task done where he was files under that day (Research 127 T2).
        let zones = OpZones(store: store)
        let items = store.objects(of: taskClass).compactMap { task -> Item? in
            let item = item(task, today: start, calendar: calendar)
            if item.isDone {
                let doneAt = store.value("doneAt", of: task)?.dateValue
                return doneAt.map { zones.dayKey(of: $0, for: task.id, calendar: calendar) == today } == true ? item
                    : nil
            }
            guard let when = item.when else { return nil }
            return when < end ? item : nil
        }
        return items.sorted { lhs, rhs in
            if lhs.isDone != rhs.isDone {
                return !lhs.isDone
            }
            return (lhs.when ?? .distantFuture) < (rhs.when ?? .distantFuture)
        }
    }

    /// Later: undone tasks with no date (where undated captures go, and where 7-times-rolled tasks rest).
    public func later() -> [Item] {
        all().filter { !$0.isDone && $0.when == nil }
    }

    /// Undone tasks planned after today, soonest first.
    public func upcoming(_ now: Date = .now, calendar: Calendar = .current) -> [Item] {
        let end = TesseraDay(calendar: calendar).end(of: now)
        return all().filter { !$0.isDone && ($0.when.map { $0 >= end } ?? false) }
            .sorted { ($0.when ?? .distantFuture) < ($1.when ?? .distantFuture) }
    }

    /// "3 of 5 done today".
    public func todayCounts(_ now: Date = .now, calendar: Calendar = .current) -> (done: Int, total: Int) {
        let items = today(now, calendar: calendar)
        return (items.count { $0.isDone }, items.count)
    }

    private func item(_ task: ObjectRecord, today: Date?, calendar _: Calendar) -> Item {
        let when = (store.value("startsAt", of: task) ?? store.value("due", of: task))?.dateValue
        let isDone = store.value("isDone", of: task) == .bool(true)
        return Item(
            id: task.id, task: task, title: task.title, when: when,
            minutes: store.number("length", of: task).map { $0 / 60 },
            isDone: isDone, isCarriedOver: !isDone && today.map { day in when.map { $0 < day } ?? false } == true,
            rolls: Int(store.number("rolls", of: task) ?? 0)
        )
    }
}

/// Moves a task: to another time (default: the same time tomorrow, "not now"), or to Later (no date). Undoable.
public struct MoveTask: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "moveTask",
        summary: "Move a task to another day, or to Later",
        parameters: [
            .init("task", .object, "The task"),
            .init("to", .date, "When; defaults to the same time tomorrow", required: false),
            .init("later", .boolean, "True to move it to Later, with no date", required: false),
            .init("time", .date, "Now; defaults to the current time", required: false),
        ]
    )

    public var task: UUID
    public var to: Date?
    public var later: Bool?
    /// Now; the app passes its clock.
    public var time: Date?

    public init(task: UUID, to: Date? = nil, later: Bool? = nil, time: Date? = nil) {
        self.time = time
        self.task = task
        self.to = to
        self.later = later
    }

    public func apply(_ transaction: inout Transaction) throws {
        let task = try transaction.object(task, is: .task)
        let store = transaction.store
        if later == true {
            try transaction.set("startsAt", to: nil, on: task)
            try transaction.set("due", to: nil, on: task)
            return
        }
        // "Not now": the same wall time on his next day. At 01:00 Saturday a Friday 23:00 task moves to Saturday 23:00
        // (his day still being Friday), not Sunday 00:00.
        let now = time ?? .now
        let day = TesseraDay()
        let current = store.value("startsAt", of: task)?.dateValue
        let base = max(current ?? now, day.start(of: now))
        let target = to ?? day.adding(days: 1, to: base)
        try transaction.set("startsAt", to: .date(target), on: task)
        if let due = store.value("due", of: task)?.dateValue, due < target {
            try transaction.set("due", to: .date(target), on: task)
        }
    }

    public func summary(in store: ObjectStore) -> String {
        let title = store.object(id: task)?.title ?? "it"
        return later == true ? "Moved \(title) to Later" : "Moved \(title)"
    }
}
