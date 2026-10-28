import Foundation

// What the sink knows (Design sheet 388): batches of dirty dishes that went in together, open until washed. A cook adds
// one (plates, pans, a board), a hand-added `addDishes` covers the rest, and `washDishes` closes every open load in one
// op group. Nothing resets on its own and nothing is guessed. Dishes are not private, and there are no streaks: no
// count of clear days or washes in a row.

public enum Sink {
    public struct Facts: Equatable, Sendable {
        /// Dishes waiting: the total count of the open loads.
        public let waiting: Int
        /// When the oldest open load went in.
        public let since: Date?
        /// About how long they take: 1.5 minutes a dish, rounded to the nearest 5, at least 5.
        public let minutes: Int
        /// When the sink was last washed (for "last washed" only; never a streak).
        public let lastWashed: Date?
    }

    @MainActor
    static func loads(_ store: ObjectStore) -> [ObjectRecord] {
        guard let loadClass = store.classDef(named: "Sink Load") else { return [] }
        return store.objects(of: loadClass)
    }

    @MainActor
    public static func openLoads(in store: ObjectStore) -> [ObjectRecord] {
        loads(store).filter { store.value("washedAt", of: $0)?.dateValue == nil }
            .sorted { (store.value("at", of: $0)?.dateValue ?? .distantPast)
                < (store.value("at", of: $1)?.dateValue ?? .distantPast)
            }
    }

    @MainActor
    public static func facts(store: ObjectStore, now _: Date = .now) -> Facts {
        let open = openLoads(in: store)
        let waiting = open.reduce(0) { $0 + Int(store.number("count", of: $1) ?? 0) }
        let washed = loads(store).compactMap { store.value("washedAt", of: $0)?.dateValue }.max()
        return Facts(waiting: waiting, since: open.first.flatMap { store.value("at", of: $0)?.dateValue },
                     minutes: minutes(forDishes: waiting), lastWashed: washed)
    }

    /// 1.5 minutes a dish, rounded to the nearest 5, at least 5 (7 dishes read "About 10 minutes").
    public static func minutes(forDishes count: Int) -> Int {
        let raw = Double(count) * 1.5
        return max(5, Int((raw / 5).rounded(.toNearestOrAwayFromZero)) * 5)
    }

    // MARK: Words

    /// "breakfast" before 11 AM today, "lunch" from 11 to 4, "dinner" after 4, "yesterday", a weekday for the past week
    /// ("Monday"), and the month and day before that ("October 20").
    public static func when(_ date: Date, now: Date, calendar: Calendar = .current) -> String {
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: date),
                                           to: calendar.startOfDay(for: now)).day ?? 0
        if days <= 0 {
            let hour = calendar.component(.hour, from: date)
            return hour < 11 ? "breakfast" : hour < 16 ? "lunch" : "dinner"
        }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US")
        if days == 1 {
            return "yesterday"
        }
        if days < 7 {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        }
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date)
    }

    /// The ticket's lines while dishes wait: title, "{n} waiting", "since {when}". Nil when the sink is clear.
    public static func ticket(_ facts: Facts, now: Date, calendar: Calendar = .current) -> [String]? {
        guard facts.waiting > 0 else { return nil }
        let since = facts.since.map { "since \(when($0, now: now, calendar: calendar))" } ?? ""
        return ["Dishes", "\(facts.waiting) waiting", since].filter { !$0.isEmpty }
    }

    /// The widget card's lines: "Since lunch", the number and its unit, "Waiting in the sink", "About 10 minutes".
    public static func card(_ facts: Facts, now: Date, calendar: Calendar = .current)
        -> (header: String, number: Int, unit: String, line: String, about: String)?
    {
        guard facts.waiting > 0 else { return nil }
        let when = facts.since.map { when($0, now: now, calendar: calendar) } ?? ""
        let header = when.isEmpty ? "In the sink" : "Since \(when)"
        return (header.prefix(1).uppercased() + header.dropFirst(), facts.waiting,
                facts.waiting == 1 ? "dish" : "dishes", "Waiting in the sink", "About \(facts.minutes) minutes")
    }

    /// The Wash action word's object: "{n} dishes", "1 dish" or "the sink is clear".
    public static func washObject(_ facts: Facts) -> String {
        switch facts.waiting {
        case 0: "the sink is clear"
        case 1: "1 dish"
        default: "\(facts.waiting) dishes"
        }
    }

    // MARK: Writes

    /// One load for a cook (or a session of cooks): plates are the largest serves, each recipe adds its cookware (one
    /// when it has none), and a board adds one. Serves are never guessed: unknown serves add no plates.
    @MainActor
    static func addCookLoad(for cooks: [ObjectRecord], source: ObjectRecord, at time: Date,
                            in transaction: inout Transaction) throws
    {
        guard !cooks.isEmpty else { return }
        let store = transaction.store
        var plates = 0
        var pans = 0
        for cook in cooks {
            let recipe = store.linkedObjects("recipe", of: cook).first
            let serves = store.number("serves", of: cook) ?? recipe.flatMap { store.number("serves", of: $0) } ?? 0
            plates = max(plates, Int(serves))
            pans += Int(recipe.flatMap { store.number("cookware", of: $0) } ?? 1)
        }
        // A private recipe never lends its name to the label.
        let labelClasses = PrivateWords.systemClasses(in: store.context)
        let label = cooks.first.flatMap { store.linkedObjects("recipe", of: $0).first }.map {
            ObjectPrivacy.shownLabel(of: $0, in: store, classes: labelClasses) ?? $0.title
        } ?? "Cooking"
        try addLoad(count: plates + pans + 1, label: label, at: time, source: source, in: &transaction)
    }

    @MainActor
    @discardableResult
    static func addLoad(count: Int, label: String?, at time: Date, source: ObjectRecord?,
                        in transaction: inout Transaction) throws -> ObjectRecord
    {
        let load = try transaction.create(transaction.classDef(.sinkLoad), title: label ?? "Dishes")
        try transaction.set("count", to: .number(Double(max(1, count))), on: load)
        try transaction.set("at", to: .date(time), on: load)
        if let label, !label.isEmpty {
            try transaction.set("label", to: .text(label), on: load)
        }
        if let source {
            try transaction.setLinks("source", on: load, to: [source])
        }
        return load
    }

    /// The board's sample: one open load of 7, labeled "Lunch", at 12:40 PM today ("7 waiting, since lunch").
    @MainActor
    @discardableResult
    public static func seedSample(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef], now: Date,
                                  calendar: Calendar = .current) throws -> ObjectRecord?
    {
        guard let loadClass = classes[.sinkLoad], openLoads(in: store).isEmpty else { return nil }
        let load = store.create(loadClass, title: "Lunch")
        try store.set("count", to: .number(7), on: load)
        try store.set("at", to: calendar.date(bySettingHour: 12, minute: 40, second: 0, of: now).map { .date($0) },
                      on: load)
        try store.set("label", to: .text("Lunch"), on: load)
        return load
    }
}

// MARK: - Actions

/// Dishes added by hand: a meal that was not cooked here. Nothing is guessed (no meal times, no plates for leftovers).
public struct AddDishes: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "addDishes", summary: "Put dishes in the sink",
        parameters: [
            .init("count", .integer, "How many dishes"),
            .init("label", .string, "What they were from, e.g. Lunch", required: false),
            .init("at", .date, "Defaults to now", required: false),
        ]
    )

    public var count: Int
    public var label: String?
    public var at: Date?

    public init(count: Int, label: String? = nil, at: Date? = nil) {
        self.count = count
        self.label = label
        self.at = at
    }

    public func apply(_ transaction: inout Transaction) throws {
        guard count >= 1 else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "that is no dishes")
        }
        try Sink.addLoad(count: count, label: label, at: at ?? transaction.now, source: nil, in: &transaction)
    }

    public func summary(in _: ObjectStore) -> String {
        "Added dishes"
    }

    public func receipt(in _: ObjectStore) -> String? {
        "\(count) \(count == 1 ? "dish" : "dishes"), in the sink"
    }
}

/// Wash: every open load gets `washedAt`, in one op group. With nothing open it writes nothing.
public struct WashDishes: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "washDishes", summary: "Wash the dishes",
        parameters: [.init("at", .date, "Defaults to now", required: false)]
    )

    public var at: Date?

    public init(at: Date? = nil) {
        self.at = at
    }

    /// How many loads were washed (0 when the sink was already clear).
    public func apply(_ transaction: inout Transaction) throws -> Int {
        let store = transaction.store
        let open = Sink.openLoads(in: store)
        let when = at ?? transaction.now
        for load in open {
            try transaction.set("washedAt", to: .date(when), on: load)
        }
        return open.count
    }

    public var logsWhenEmpty: Bool {
        false
    }

    public func summary(in _: ObjectStore) -> String {
        "Washed the dishes"
    }

    public func receipt(in _: ObjectStore) -> String? {
        nil
    }

    public func receipt(in _: ObjectStore, output washed: Int) -> String? {
        washed > 0 ? "Dishes, done" : "The sink is clear"
    }
}
