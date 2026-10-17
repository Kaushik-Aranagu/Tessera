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

/// Plan my day's keep: the same move as `MoveTask`, under its own name so a task's story can tell a keep
/// ("planned") from a hand move ("moved") in the op log (Research drawn-sides-acceptance Q4). Not offered to Tess or
/// Siri.
public struct KeepPlannedTask: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "keepPlannedTask",
        summary: "Keep a task at the time Plan my day proposed",
        parameters: MoveTask.descriptor.parameters
    )

    public var task: UUID
    public var to: Date?
    public var time: Date?
    public var calendar: Calendar?

    public init(task: UUID, to: Date? = nil, time: Date? = nil, calendar: Calendar? = nil) {
        self.task = task
        self.to = to
        self.time = time
        self.calendar = calendar
    }

    public func apply(_ transaction: inout Transaction) throws {
        try move.apply(&transaction)
    }

    public func summary(in store: ObjectStore) -> String {
        move.summary(in: store)
    }

    public func receipt(in store: ObjectStore) -> String? {
        move.receipt(in: store)
    }

    private var move: MoveTask {
        MoveTask(task: task, to: to, time: time, calendar: calendar)
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
    /// His calendar (the device's when nil): his day and his quiet hours are read in it.
    public var calendar: Calendar?

    public init(task: UUID, to: Date? = nil, later: Bool? = nil, time: Date? = nil, calendar: Calendar? = nil) {
        self.time = time
        self.calendar = calendar
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
        let calendar = calendar ?? .current
        let day = TesseraDay(calendar: calendar)
        let current = store.value("startsAt", of: task)?.dateValue
        let base = max(current ?? now, day.start(of: now))
        var target = to ?? day.adding(days: 1, to: base)
        // "Not now" never lands in his quiet hours, 23:00 to 07:00: it moves to the next 7 am instead (Product 0ab,
        // 2:00 PM PT). A time he picks himself (`to`) is kept.
        if to == nil {
            let hour = calendar.component(.hour, from: target)
            // The target itself moves to 7 am on its own calendar day (QA F1 and F2 on #553, Research EQ26): a target
            // at 11:20 pm Friday lands at 7 am Friday, still ahead of a "Not now" said Thursday night.
            if hour >= 23 || hour < 7 {
                target = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: target) ?? target
            }
        }
        try transaction.set("startsAt", to: .date(target), on: task)
        if let due = store.value("due", of: task)?.dateValue, due < target {
            try transaction.set("due", to: .date(target), on: task)
        }
    }

    public func summary(in store: ObjectStore) -> String {
        let title = store.object(id: task)?.title ?? "it"
        // Thing first in his history (Product 2:48 PM PT): "Stretch, moved to Later".
        return later == true ? "\(title), moved to Later" : "\(title), moved"
    }

    /// "Call mom, in Later", "Call mom, tomorrow at 6:30 pm", "Call mom, Thursday at 6:30 pm" (copy-pass rule 6).
    public func receipt(in store: ObjectStore) -> String? {
        guard let object = store.object(id: task) else { return nil }
        guard later != true, let at = store.value("startsAt", of: object)?.dateValue else {
            return "\(object.title), in Later"
        }
        let calendar = Calendar.current
        let day = TesseraDay(calendar: calendar)
        let now = time ?? .now
        let en = Locale(identifier: "en_US")
        // Within the week, the weekday; further out, the date, so "Thursday" is never next week's (QA on #512).
        let word = day.isSameDay(at, now) ? "today"
            : day.isSameDay(at, day.adding(days: 1, to: now)) ? "tomorrow"
            : at < day.adding(days: 7, to: day.day(of: now)) ? at.formatted(.dateTime.weekday(.wide).locale(en))
            : at.formatted(.dateTime.month(.abbreviated).day().locale(en))
        return "\(object.title), \(word) at \(DayStoryClock.sentenceTime(at, calendar: calendar))"
    }
}
