import Foundation

/// Gathers a day's counts from the store (the inputs the copy rules read) and closes the day.
@MainActor
public struct ShutdownDay {
    public let store: ObjectStore
    public let classes: [SystemCatalog.Key: ClassDef]
    public let calendar: Calendar

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef], calendar: Calendar = .current) {
        self.store = store
        self.classes = classes
        self.calendar = calendar
    }

    /// Shutdown opens at 21:00. Late night is 23:00 or later, or 00:00 to 04:00 (it files to the day before).
    public static func isLateNight(_ now: Date, calendar: Calendar) -> Bool {
        calendar.component(.hour, from: now) >= 23 || calendar.component(.hour, from: now) < TesseraDay.startHour
    }

    public func inputs(at now: Date, firstEver: Bool = false) -> ShutdownInputs {
        var inputs = ShutdownInputs()
        let day = TesseraDay(calendar: calendar)
        let start = day.start(of: now), end = day.end(of: now)
        func inDay(_ date: Date?) -> Bool {
            date.map { $0 >= start && $0 < end } ?? false
        }
        let items = TaskList(store: store, classes: classes).today(now, calendar: calendar)
        inputs.tasks = items.filter(\.isDone).count
        inputs.rolling = items.filter { !$0.isDone }.map(\.title)
        if let workoutClass = classes[.workout] {
            let done = store.objects(of: workoutClass)
                .filter { !$0.isDeleted && inDay(store.value("endedAt", of: $0)?.dateValue) }
            inputs.workouts = done.count
            inputs.workoutName = done.first?.title
            inputs.sets = done.reduce(0) { total, workout in
                total + workout.orderedChildren.reduce(0) { $0 + $1.orderedChildren.count { !$0.isDeleted } }
            }
        }
        if let cookClass = classes[.cook] {
            let done = store.objects(of: cookClass)
                .filter { !$0.isDeleted && inDay(store.value("cookedAt", of: $0)?.dateValue) }
            inputs.cooks = done.count
            inputs.recipeName = done.first.flatMap { store.linkedObjects("recipe", of: $0).first?.title }
        }
        if let noteClass = classes[.note] {
            inputs.notes = store.objects(of: noteClass).count { !$0.isDeleted && inDay($0.createdAt) }
        }
        inputs.appsTouched = [inputs.workouts, inputs.cooks, inputs.tasks, inputs.lists, inputs.notes].count { $0 > 0 }
        inputs.firstShutdownEver = firstEver
        inputs.lateNight = Self.isLateNight(now, calendar: calendar)
        inputs.pastMidnight = calendar.component(.hour, from: now) < TesseraDay.startHour
        let attributed = day.day(of: now)
        inputs.attributedWeekday = TesseraDay.weekdayName(of: attributed, calendar: calendar)
        inputs.nextWeekday = TesseraDay.weekdayName(of: day.adding(days: 1, to: attributed), calendar: calendar)
        return inputs
    }

    /// The closed mark for the day containing `now`, if the day was closed.
    public func closedMark(for now: Date) -> ObjectRecord? {
        let id = CloseDay.objectID(day: TesseraDay(calendar: calendar).day(of: now), calendar: calendar)
        return store.object(id: id).flatMap { $0.isDeleted ? nil : $0 }
    }
}

/// Closes the day: kept rows go to tomorrow, the rest to Later, his line for tomorrow becomes a task at 8 am, and the
/// day's closed mark is written with the frozen Day log line. One action, so one undo ("Shutdown, taken back.").
/// The 22:00 silent close is the same action with `silent` set and no line.
public struct CloseDay: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "closeDay", summary: "Close the day", parameters: [
            .init("tomorrow", .json, "Task ids that roll to tomorrow", required: false),
            .init("later", .json, "Task ids that go to Later", required: false),
            .init("line", .string, "One line for tomorrow", required: false),
        ], isOfferedToModel: false
    )

    public var tomorrow: [UUID]
    public var later: [UUID]
    public var line: String?
    public var dayLine: String?
    public var closedAt: Date
    public var silent: Bool
    public var zoneIdentifier: String

    public init(tomorrow: [UUID] = [], later: [UUID] = [], line: String? = nil, dayLine: String? = nil,
                closedAt: Date, silent: Bool = false, calendar: Calendar = .current)
    {
        self.tomorrow = tomorrow
        self.later = later
        self.line = line
        self.dayLine = dayLine
        self.closedAt = closedAt
        self.silent = silent
        zoneIdentifier = calendar.timeZone.identifier
    }

    static func objectID(day: Date, calendar: Calendar) -> UUID {
        let parts = calendar.dateComponents([.year, .month, .day], from: day)
        return SystemCatalog.stableID(String(format: "closedDay:%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0,
                                             parts.day ?? 0))
    }

    @discardableResult
    public func apply(_ transaction: inout Transaction) throws -> UUID {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: zoneIdentifier) ?? .current
        let day = TesseraDay(calendar: calendar)
        let attributed = day.day(of: closedAt)
        for id in tomorrow {
            try MoveTask(task: id, time: closedAt, calendar: calendar).apply(&transaction)
        }
        for id in later {
            try MoveTask(task: id, later: true, time: closedAt, calendar: calendar).apply(&transaction)
        }
        var wrote: String?
        if let line = line?.trimmingCharacters(in: .whitespacesAndNewlines), !line.isEmpty {
            // 8 am on his next day: "Your line is waiting at 8 am".
            let nextDay = day.adding(days: 1, to: attributed)
            let eight = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: nextDay) ?? nextDay
            try CreateTask(title: line, startsAt: eight).apply(&transaction)
            wrote = line
        }
        let id = Self.objectID(day: attributed, calendar: calendar)
        let mark = try transaction.store.object(id: id).flatMap { $0.isDeleted ? nil : $0 }
            ?? transaction.create(transaction.classDef(.closedDay), title: "Closed day", id: id)
        try transaction.set("date", to: .date(attributed), on: mark)
        try transaction.set("closedAt", to: .date(closedAt), on: mark)
        try transaction.set("silent", to: .bool(silent), on: mark)
        try transaction.set("tomorrowLine", to: wrote.map(FieldValue.text), on: mark)
        try transaction.set("dayLine", to: dayLine.map(FieldValue.text), on: mark)
        return mark.id
    }

    public func summary(in _: ObjectStore) -> String {
        silent ? "Day closed" : "Shutdown complete"
    }
}
