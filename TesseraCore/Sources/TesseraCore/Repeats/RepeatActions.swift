import Foundation

/// Sheet 173: setting, skipping and stopping a repeat. Each is one logged change to the object's `repeats` text, so
/// the op log's Undo reverses it. Skipping and stopping never create or delete an object, and a rule is never copied.
public enum Repeats {
    /// The rule on an object, or nil.
    @MainActor public static func rule(of object: ObjectRecord, in store: ObjectStore) -> RepeatRule? {
        RepeatRule(encoded: store.value("repeats", of: object)?.stringValue)
    }

    /// The next day, or nil when it has no rule or has ended.
    @MainActor public static func next(of object: ObjectRecord, in store: ObjectStore, now: Date,
                                       calendar: Calendar) -> RepeatRule.DayStamp?
    {
        guard let rule = rule(of: object, in: store) else { return nil }
        let day = TesseraDay(calendar: calendar).day(of: now)
        return rule.next(today: .init(day, calendar: calendar), doneAt: store.value("doneAt", of: object)?.dateValue,
                         calendar: calendar)
    }

    /// The one plain line under a title: "Every other Friday". A private object's own words never appear in it.
    @MainActor public static func line(for object: ObjectRecord, in store: ObjectStore, calendar: Calendar) -> String? {
        rule(of: object, in: store)?.sentence(calendar: calendar)
    }

    /// "Rent, Friday": the name (its shown label when private) and the day, never an amount and never an action.
    @MainActor public static func noticeLine(for object: ObjectRecord, in store: ObjectStore,
                                             classes: [SystemCatalog.Key: ClassDef], now: Date,
                                             calendar: Calendar) -> String?
    {
        guard let next = next(of: object, in: store, now: now, calendar: calendar) else { return nil }
        let name = ObjectPrivacy.shownLabel(of: object, in: store, classes: classes)
            ?? AppSummaryLines.shown(object.title, in: store, classes: classes, of: object).text
        return "\(name), \(TesseraDay.weekdayName(of: next.date(calendar: calendar), calendar: calendar))"
    }
}

public struct SetRepeat: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "setRepeat", summary: "Make something repeat",
        parameters: [
            .init("object", .object, "The task, routine or occasion"),
            .init("kind", .string, "days, weeks, months or afterDone"),
            .init("every", .integer, "Every N (days, weeks or months)"),
            .init("weekday", .integer, "1 Sunday to 7 Saturday, for weeks", required: false),
            .init("dayOfMonth", .integer, "1 to 31, for months", required: false),
            .init("from", .date, "The first day; defaults to today", required: false),
        ], isOfferedToModel: false
    )

    public var object: UUID
    public var kind: String
    public var every: Int
    public var weekday: Int?
    public var dayOfMonth: Int?
    public var from: Date?
    /// The calendar the day is read in; the app passes its own.
    public var calendarID: String?

    public init(object: UUID, kind: String, every: Int = 1, weekday: Int? = nil, dayOfMonth: Int? = nil,
                from: Date? = nil, calendar: Calendar = .current)
    {
        self.object = object
        self.kind = kind
        self.every = every
        self.weekday = weekday
        self.dayOfMonth = dayOfMonth
        self.from = from
        calendarID = calendar.timeZone.identifier
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        if let calendarID, let zone = TimeZone(identifier: calendarID) {
            calendar.timeZone = zone
        }
        return calendar
    }

    /// The rule this builds, or nil when the arguments don't make one.
    func rule() -> RepeatRule? {
        let calendar = calendar
        let anchor = RepeatRule.DayStamp(from ?? .now, calendar: calendar)
        guard (1 ... 365).contains(every) else { return nil }
        switch kind {
        case "days": return RepeatRule(kind: .days(every), anchor: anchor)
        case "weeks":
            let day = weekday ?? calendar.component(.weekday, from: anchor.date(calendar: calendar))
            guard (1 ... 7).contains(day) else { return nil }
            return RepeatRule(kind: .weeks(every, weekday: day), anchor: anchor)
        case "months":
            let day = dayOfMonth ?? anchor.day
            guard (1 ... 31).contains(day) else { return nil }
            return RepeatRule(kind: .months(every, day: day), anchor: anchor)
        case "afterDone": return RepeatRule(kind: .afterDone(every), anchor: anchor)
        default: return nil
        }
    }

    public func apply(_ transaction: inout Transaction) throws {
        let target = try transaction.object(object)
        guard let rule = rule() else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "that is not a repeat")
        }
        try transaction.set("repeats", to: .text(rule.encoded), on: target)
    }

    public func summary(in _: ObjectStore) -> String {
        "Set a repeat"
    }

    public func receipt(in _: ObjectStore) -> String? {
        nil
    }
}

public struct SkipRepeat: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "skipRepeat", summary: "Skip this one",
        parameters: [
            .init("object", .object, "The repeating thing"),
            .init("time", .date, "Defaults to now", required: false),
        ], isOfferedToModel: false
    )

    public var object: UUID
    public var time: Date?
    public var calendarID: String?

    public init(object: UUID, time: Date? = nil, calendar: Calendar = .current) {
        self.object = object
        self.time = time
        calendarID = calendar.timeZone.identifier
    }

    public func apply(_ transaction: inout Transaction) throws {
        let target = try transaction.object(object)
        var calendar = Calendar(identifier: .gregorian)
        if let calendarID, let zone = TimeZone(identifier: calendarID) {
            calendar.timeZone = zone
        }
        guard var rule = Repeats.rule(of: target, in: transaction.store) else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "that does not repeat")
        }
        let today = RepeatRule.DayStamp(TesseraDay(calendar: calendar).day(of: time ?? .now), calendar: calendar)
        guard let next = rule.next(today: today,
                                   doneAt: transaction.store.value("doneAt", of: target)?.dateValue,
                                   calendar: calendar) else { return }
        // The next one is skipped: nothing on or before it counts, so the following step is next.
        rule.skippedThrough = next
        try transaction.set("repeats", to: .text(rule.encoded), on: target)
    }

    public func summary(in _: ObjectStore) -> String {
        "Skipped one"
    }

    public func receipt(in _: ObjectStore) -> String? {
        nil
    }
}

public struct StopRepeating: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "stopRepeating", summary: "Stop repeating",
        parameters: [
            .init("object", .object, "The repeating thing"),
            .init("time", .date, "Defaults to now", required: false),
        ], isOfferedToModel: false
    )

    public var object: UUID
    public var time: Date?
    public var calendarID: String?

    public init(object: UUID, time: Date? = nil, calendar: Calendar = .current) {
        self.object = object
        self.time = time
        calendarID = calendar.timeZone.identifier
    }

    public func apply(_ transaction: inout Transaction) throws {
        let target = try transaction.object(object)
        var calendar = Calendar(identifier: .gregorian)
        if let calendarID, let zone = TimeZone(identifier: calendarID) {
            calendar.timeZone = zone
        }
        guard var rule = Repeats.rule(of: target, in: transaction.store) else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "that does not repeat")
        }
        // Today still counts; nothing after it does.
        rule.end = RepeatRule.DayStamp(TesseraDay(calendar: calendar).day(of: time ?? .now), calendar: calendar)
        try transaction.set("repeats", to: .text(rule.encoded), on: target)
    }

    public func summary(in _: ObjectStore) -> String {
        "Stopped repeating"
    }

    public func receipt(in _: ObjectStore) -> String? {
        nil
    }
}
