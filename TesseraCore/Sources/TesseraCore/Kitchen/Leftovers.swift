import Foundation

// Leftovers (Design's Galley levels): food kept from a cook, with the day it goes out. The Tonight and Leftovers doors
// read
// these. Nothing is guessed: no day goes out unless it was said, and a row exists only for a leftover he kept.

public enum Leftovers {
    public struct Row: Equatable, Sendable {
        public enum State: Equatable, Sendable {
            /// Goes out today (wine).
            case today
            /// The day it should have gone out has passed.
            case overdue
            case later
            /// No day was given.
            case noDate
        }

        public let id: UUID
        public let what: String
        public let cookedOn: Date?
        public let goesOutOn: Date?
        public let source: UUID?
        public let state: State
        /// "Goes out today", "Went out Monday", "Cooked Thursday", "Goes out Friday" (no cooked day), or empty.
        public let sub: String
        /// "Today", "Fri", or empty when no day was given.
        public let value: String
    }

    @MainActor
    static func objects(_ store: ObjectStore) -> [ObjectRecord] {
        guard let leftoverClass = store.classDef(named: "Leftover") else { return [] }
        return store.objects(of: leftoverClass)
    }

    /// The open leftovers, the one going out first first; ones with no day last, then by what they are.
    @MainActor
    public static func rows(store: ObjectStore, now: Date, calendar: Calendar = .current) -> [Row] {
        let today = calendar.startOfDay(for: now)
        let rows = objects(store).filter { store.value("doneAt", of: $0)?.dateValue == nil }.map { object -> Row in
            let cooked = store.value("cookedOn", of: object)?.dateValue
            let out = store.value("goesOutOn", of: object)?.dateValue
            let what = store.value("what", of: object)?.stringValue ?? object.title
            let days = out
                .map { calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: $0)).day ?? 0 }
            let state: Row.State = days.map { $0 == 0 ? .today : $0 < 0 ? .overdue : .later } ?? .noDate
            return Row(id: object.id, what: what, cookedOn: cooked, goesOutOn: out,
                       source: store.linkedObjects("source", of: object).first?.id, state: state,
                       sub: sub(state: state, cooked: cooked, out: out, calendar: calendar),
                       value: value(state: state, out: out, calendar: calendar))
        }
        return rows.sorted { left, right in
            switch (left.goesOutOn, right.goesOutOn) {
            case let (a?, b?): a != b ? a < b : left.what < right.what
            case (nil, _?): false
            case (_?, nil): true
            case (nil, nil): left.what < right.what
            }
        }
    }

    static func weekday(_ date: Date, _ calendar: Calendar, short: Bool = false) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = short ? "EEE" : "EEEE"
        return formatter.string(from: date)
    }

    static func sub(state: Row.State, cooked: Date?, out: Date?, calendar: Calendar) -> String {
        switch state {
        case .today: return "Goes out today"
        case .overdue: return out.map { "Went out \(weekday($0, calendar))" } ?? ""
        case .later:
            if let cooked {
                return "Cooked \(weekday(cooked, calendar))"
            }
            return out.map { "Goes out \(weekday($0, calendar))" } ?? ""
        case .noDate: return cooked.map { "Cooked \(weekday($0, calendar))" } ?? ""
        }
    }

    static func value(state: Row.State, out: Date?, calendar: Calendar) -> String {
        switch state {
        case .today: "Today"
        case .overdue, .later: out.map { weekday($0, calendar, short: true) } ?? ""
        case .noDate: ""
        }
    }

    /// The Leftovers door's line: "Eat the rice today", else "Eat the dal by Friday"; nil with nothing kept (the door
    /// then says "Nothing here yet").
    @MainActor
    public static func line(store: ObjectStore, now: Date, calendar: Calendar = .current) -> String? {
        let rows = rows(store: store, now: now, calendar: calendar)
        if let first = rows.first(where: { $0.state == .today || $0.state == .overdue }) {
            return "Eat the \(first.what.lowercased()) today"
        }
        guard let next = rows.first(where: { $0.state == .later }), let out = next.goesOutOn else { return nil }
        return "Eat the \(next.what.lowercased()) by \(weekday(out, calendar))"
    }

    /// The Tonight door's row for the leftover going out today, if any: "Leftover, goes out today", value "side".
    @MainActor
    public static func tonight(store: ObjectStore, now: Date, calendar: Calendar = .current)
        -> (what: String, sub: String, value: String)?
    {
        rows(store: store, now: now, calendar: calendar).first { $0.state == .today || $0.state == .overdue }
            .map { ($0.what, "Leftover, goes out today", "side") }
    }

    /// The sample: rice that goes out today (cooked two days ago) and dal that goes out two days from now (cooked
    /// yesterday). Once; nothing is added over leftovers he already has.
    @MainActor
    @discardableResult
    public static func seedSample(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef], now: Date,
                                  calendar: Calendar = .current) throws -> [ObjectRecord]
    {
        guard let leftoverClass = classes[.leftover], objects(store).isEmpty else { return [] }
        let today = calendar.startOfDay(for: now)
        func day(_ offset: Int) -> Date {
            calendar.date(byAdding: .day, value: offset, to: today) ?? today
        }
        var made: [ObjectRecord] = []
        for (what, cooked, out) in [("Rice", -2, 0), ("Dal", -1, 2)] {
            let object = store.create(leftoverClass, title: what)
            try store.set("what", to: .text(what), on: object)
            try store.set("cookedOn", to: .date(day(cooked)), on: object)
            try store.set("goesOutOn", to: .date(day(out)), on: object)
            made.append(object)
        }
        return made
    }
}

/// Keeps food from a cook: what it is, and optionally when it was cooked, the day it goes out and the Cook it came
/// from.
/// No day is guessed.
public struct AddLeftover: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "addLeftover", summary: "Keep a leftover",
        parameters: [.init("what", .string, "What it is, e.g. rice"),
                     .init("cookedOn", .date, "When it was cooked", required: false),
                     .init("goesOutOn", .date, "The day it goes out, only if said", required: false),
                     .init("cook", .object, "The cook it came from", required: false)]
    )

    public var what: String
    public var cookedOn: Date?
    public var goesOutOn: Date?
    public var cook: UUID?

    public init(what: String, cookedOn: Date? = nil, goesOutOn: Date? = nil, cook: UUID? = nil) {
        self.what = what
        self.cookedOn = cookedOn
        self.goesOutOn = goesOutOn
        self.cook = cook
    }

    public func apply(_ transaction: inout Transaction) throws -> UUID {
        let name = what.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "what is it?")
        }
        let object = try transaction.create(transaction.classDef(.leftover), title: name)
        try transaction.set("what", to: .text(name), on: object)
        try transaction.set("cookedOn", to: cookedOn.map { .date($0) }, on: object)
        try transaction.set("goesOutOn", to: goesOutOn.map { .date($0) }, on: object)
        if let cook {
            try transaction.setLinks("source", on: object, to: [transaction.object(cook, is: .cook)])
        }
        return object.id
    }

    public func summary(in _: ObjectStore) -> String {
        "Kept a leftover"
    }

    public func receipt(in _: ObjectStore) -> String? {
        "\(what.capitalized), kept"
    }
}

/// Eaten or thrown out: the leftover is done.
public struct FinishLeftover: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "finishLeftover", summary: "Done with a leftover",
        parameters: [.init("leftover", .object, "The leftover"), .init("at", .date, "Defaults to now", required: false)]
    )

    public var leftover: UUID
    public var at: Date?

    public init(leftover: UUID, at: Date? = nil) {
        self.leftover = leftover
        self.at = at
    }

    public func apply(_ transaction: inout Transaction) throws {
        let object = try transaction.object(leftover, is: .leftover)
        try transaction.set("doneAt", to: .date(at ?? transaction.now), on: object)
    }

    public func summary(in _: ObjectStore) -> String {
        "Finished a leftover"
    }

    public func receipt(in store: ObjectStore) -> String? {
        store.object(id: leftover).map { "\($0.title), done" }
    }
}
