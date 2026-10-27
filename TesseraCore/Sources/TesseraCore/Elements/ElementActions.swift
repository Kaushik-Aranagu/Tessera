import Foundation

// The six actions behind Tess's element calls (docs/ai/harness/element-actions.md): pin a note or list, set the rain
// alert, rest today, tend a routine, plant one, pause one. Each is an `EngineAction`, pending as Tess with a 10 s Undo,
// and none deletes anything. Words about routines and notes only: no place, no money.

// MARK: - Reading the rests and the runs

/// What a screen reads of rests and tended runs. A rest is a row; it holds from `from` to `until` (empty is open)
/// unless
/// `endedAt` ended it.
@MainActor
public struct RestBook {
    public let store: ObjectStore
    public let classes: [SystemCatalog.Key: ClassDef]

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) {
        self.store = store
        self.classes = classes
    }

    /// The live rests of one kind.
    func rests(scope: String, routine: UUID? = nil) -> [ObjectRecord] {
        guard let restClass = classes[.rest] else { return [] }
        return store.objects(of: restClass).filter { rest in
            guard !rest.isDeleted, store.value("scope", of: rest)?.stringValue == scope else { return false }
            guard let routine else { return true }
            return store.linkedObjects("routine", of: rest).contains { $0.id == routine }
        }
    }

    /// Whether a rest holds on `day`: begun by then, not ended early, and not past its `until`.
    func holds(_ rest: ObjectRecord, on day: Date, calendar: Calendar) -> Bool {
        let tessera = TesseraDay(calendar: calendar)
        guard let from = store.value("from", of: rest)?.dateValue, tessera.day(of: from) <= tessera.day(of: day)
        else { return false }
        if let ended = store.value("endedAt", of: rest)?.dateValue, tessera.day(of: ended) <= tessera.day(of: day) {
            return false
        }
        if let until = store.value("until", of: rest)?.dateValue, tessera.day(of: until) < tessera.day(of: day) {
            return false
        }
        return true
    }

    /// Today is a training rest day (a `restDay` call).
    public func isTrainingRest(on day: Date, calendar: Calendar = .current) -> Bool {
        rests(scope: "training").contains { holds($0, on: day, calendar: calendar) }
    }

    /// The live pause on a routine, if one holds on `day`.
    public func pause(of routine: UUID, on day: Date, calendar: Calendar = .current) -> ObjectRecord? {
        rests(scope: "routine", routine: routine).first { holds($0, on: day, calendar: calendar) }
    }

    /// The days a routine was tended (not through a workout), as Tessera days.
    public func tendedDays(of routine: UUID, calendar: Calendar = .current) -> Set<Date> {
        guard let runClass = classes[.routineRun] else { return [] }
        let tessera = TesseraDay(calendar: calendar)
        return Set(store.objects(of: runClass).compactMap { run -> Date? in
            guard !run.isDeleted, store.linkedObjects("routine", of: run).contains(where: { $0.id == routine }),
                  let day = store.value("day", of: run)?.dateValue else { return nil }
            return tessera.day(of: day)
        })
    }
}

enum ElementActionLine {
    /// A title as any surface outside the room says it.
    @MainActor static func shown(_ object: ObjectRecord, in store: ObjectStore) -> String {
        let classes = PrivateWords.systemClasses(in: store.context)
        return ObjectPrivacy.shownLabel(of: object, in: store, classes: classes) ?? object.title
    }
}

// MARK: - pinNote

/// Pins a note or a list to the Log's Pinned window, or unpins it. A private note can be pinned and stays "Private
/// note".
public struct SetPinned: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "setPinned", summary: "Pin or unpin a note or list",
        parameters: [.init("object", .object, "The note or list"),
                     .init("pinned", .boolean, "Pin or unpin; the opposite of now when left out", required: false)],
        isOfferedToModel: false
    )

    public var object: UUID
    public var pinned: Bool?

    public init(object: UUID, pinned: Bool? = nil) {
        self.object = object
        self.pinned = pinned
    }

    public func apply(_ transaction: inout Transaction) throws -> Bool {
        let target = try transaction.object(object)
        guard let classDef = target.classDef,
              [SystemCatalog.Key.note, .list].contains(where: { key in
                  transaction.classes[key].map { ClassResolver.isSubclass(classDef, of: $0) } == true
              })
        else { throw ActionError.wrongClass(object, expected: "note or list") }
        let now = transaction.store.value("pinned", of: target) == .bool(true)
        let on = pinned ?? !now
        try transaction.set("pinned", to: .bool(on), on: target)
        try transaction.set("pinnedAt", to: on ? .date(transaction.now) : nil, on: target)
        return on
    }

    public func summary(in store: ObjectStore) -> String {
        "\(store.object(id: object).map { ElementActionLine.shown($0, in: store) } ?? "It"), pin changed"
    }

    public func receipt(in store: ObjectStore, output on: Bool) -> String? {
        guard let target = store.object(id: object) else { return nil }
        return "\(ElementActionLine.shown(target, in: store)), \(on ? "pinned" : "unpinned")"
    }

    public func receipt(in _: ObjectStore) -> String? {
        nil
    }
}

// MARK: - rainAlert

/// Turns the rain alert on or off and sets how long before rain it speaks. The app's weather refresh schedules the
/// notice; nothing here names a place.
public struct SetRainAlert: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "setRainAlert", summary: "Turn the rain alert on or off",
        parameters: [.init("on", .boolean, "On or off; on when left out", required: false),
                     .init("leadMinutes", .integer, "Minutes before rain, 30 when left out", required: false)],
        isOfferedToModel: false
    )

    public var on: Bool?
    public var leadMinutes: Int?

    public init(on: Bool? = nil, leadMinutes: Int? = nil) {
        self.on = on
        self.leadMinutes = leadMinutes
    }

    public func apply(_ transaction: inout Transaction) throws -> (on: Bool, lead: Int) {
        let object = try transaction.store.object(id: SettingsStore.objectID)
            ?? transaction.create(transaction.classDef(.settings), title: "Settings", id: SettingsStore.objectID)
        // A deleted settings row has no op that brings it back, so it is refused rather than revived outside the log.
        guard !object.isDeleted else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "refused: settingsGone")
        }
        let enabled = on ?? true
        let current = transaction.store.number("rainAlertLead", of: object).map { Int($0) }
        let lead = min(max(leadMinutes ?? current ?? 30, 5), 24 * 60)
        try transaction.set("rainAlert", to: .bool(enabled), on: object)
        try transaction.set("rainAlertLead", to: .number(Double(lead)), on: object)
        return (enabled, lead)
    }

    public func summary(in _: ObjectStore) -> String {
        on == false ? "Rain alert off" : "Rain alert on"
    }

    public func receipt(in _: ObjectStore, output: (on: Bool, lead: Int)) -> String? {
        guard output.on else { return "Rain alert off" }
        let minutes = output.lead
        let words = minutes == 60 ? "an hour" : minutes % 60 == 0 && minutes > 60 ? "\(minutes / 60) hours" : "\(minutes) minutes"
        return "You'll hear \(words) before rain"
    }

    public func receipt(in _: ObjectStore) -> String? {
        nil
    }
}

// MARK: - restDay and pauseRoutine

/// A rest row: a training rest day, or a routine paused. `until` empty means open.
public struct TakeRest: EngineAction {
    public enum Scope: String, Codable, Sendable {
        case training, routine
    }

    public static let descriptor = ActionDescriptor(
        name: "takeRest", summary: "Rest today, or pause a routine",
        parameters: [.init("scope", .string, "training or routine"),
                     .init("routine", .object, "The routine, for a pause", required: false),
                     .init("from", .date, "The first day; today when left out", required: false),
                     .init("until", .date, "The last day; open when left out", required: false)],
        isOfferedToModel: false
    )

    public var scope: Scope
    public var routine: UUID?
    public var from: Date?
    public var until: Date?

    public init(scope: Scope, routine: UUID? = nil, from: Date? = nil, until: Date? = nil) {
        self.scope = scope
        self.routine = routine
        self.from = from
        self.until = until
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let name = Self.descriptor.name
        let tessera = TesseraDay(calendar: transaction.calendar)
        // Stored days are the 4 am start of the logical day, so reading one back (`day(of:)`) gives the same day.
        let moment = from ?? transaction.now
        let first = tessera.start(of: moment)
        let book = RestBook(store: transaction.store, classes: transaction.classes)
        var target: ObjectRecord?
        switch scope {
        case .training:
            // A day with a workout going is not a rest day.
            let ledger = TrainingLedger(store: transaction.store, classes: transaction.classes)
            if ledger.hasWorkoutUnderway(on: moment, calendar: transaction.calendar) {
                throw ActionError.invalidArguments(action: name, reason: "refused: workoutGoing")
            }
            // A session planned for today beats rest, as it does on Now and Home.
            if ledger.hasPlannedSession(on: moment, calendar: transaction.calendar) {
                throw ActionError.invalidArguments(action: name, reason: "refused: sessionPlanned")
            }
        case .routine:
            guard let routine else { throw ActionError.invalidArguments(action: name, reason: "refused: noRoutine") }
            target = try transaction.object(routine, is: .routine)
        }
        if let until, tessera.start(of: until) < first {
            throw ActionError.invalidArguments(action: name, reason: "refused: backwards")
        }
        // Resting again while a rest holds changes nothing: the same row comes back.
        if scope == .training, let held = book.rests(scope: "training").first(where: {
            book.holds($0, on: first, calendar: transaction.calendar)
        }) {
            return held
        }
        if scope == .routine, let routine, let held = book.pause(
            of: routine,
            on: first,
            calendar: transaction.calendar
        ) {
            return held
        }
        let rest = try transaction.create(transaction.classDef(.rest), title: scope == .training ? "Rest" : "Pause")
        try transaction.set("scope", to: .choice(scope.rawValue), on: rest)
        try transaction.set("from", to: .date(first), on: rest)
        try transaction.set("until", to: until.map { FieldValue.date(tessera.start(of: $0)) }, on: rest)
        if let target {
            try transaction.setLinks("routine", on: rest, to: [target])
        }
        return rest
    }

    public func summary(in _: ObjectStore) -> String {
        scope == .training ? "Rest today" : "Paused a routine"
    }

    public static let workoutGoingLine = "A workout is already going"
    public static let sessionPlannedLine = "There's a session planned today"

    public static func refusalLine(_ error: any Error) -> String? {
        guard case let ActionError.invalidArguments(_, reason) = error else { return nil }
        switch reason {
        case "refused: workoutGoing": return workoutGoingLine
        case "refused: sessionPlanned": return sessionPlannedLine
        default: return nil
        }
    }

    public func receipt(in store: ObjectStore, output rest: ObjectRecord) -> String? {
        switch scope {
        case .training:
            let classes = PrivateWords.systemClasses(in: store.context)
            let ledger = TrainingLedger(store: store, classes: classes)
            // The rest row holds the day it was made for, so the receipt needs no clock of its own.
            let day = store.value("from", of: rest)?.dateValue ?? from ?? .distantPast
            if let planClass = classes[.plan], let plan = store.objects(of: planClass).first(where: { !$0.isDeleted }),
               let next = ledger.nextRoutine(in: plan, now: day)
            {
                return "Rest today. Next is \(ElementActionLine.shown(next, in: store))"
            }
            return "Rest today"
        case .routine:
            guard let routine = store.linkedObjects("routine", of: rest).first else { return nil }
            let shown = ElementActionLine.shown(routine, in: store)
            guard let until = store.value("until", of: rest)?.dateValue else { return "\(shown), resting" }
            return "\(shown), resting until \(TesseraDay.weekdayName(of: until, calendar: .current))"
        }
    }

    public func receipt(in _: ObjectStore) -> String? {
        nil
    }
}

/// Ends a pause early (he said resume).
public struct ResumeRoutine: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "resumeRoutine", summary: "Resume a paused routine",
        parameters: [.init("routine", .object, "The routine"), .init("at", .date, "Defaults to now", required: false)],
        isOfferedToModel: false
    )

    public var routine: UUID
    public var at: Date?

    public init(routine: UUID, at: Date? = nil) {
        self.routine = routine
        self.at = at
    }

    public func apply(_ transaction: inout Transaction) throws {
        let target = try transaction.object(routine, is: .routine)
        guard let pause = RestBook(store: transaction.store, classes: transaction.classes)
            .pause(of: target.id, on: at ?? transaction.now, calendar: transaction.calendar)
        else { throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "refused: notPaused") }
        try transaction.set("endedAt", to: .date(at ?? transaction.now), on: pause)
    }

    public func summary(in _: ObjectStore) -> String {
        "Resumed a routine"
    }

    public func receipt(in store: ObjectStore) -> String? {
        store.object(id: routine).map { "\(ElementActionLine.shown($0, in: store)), back" }
    }
}

// MARK: - tendRoutine

/// A routine done for today without a workout (a Watch tree held, or its steps opened). Once a day: the second tend
/// changes nothing. Tending a paused routine ends the pause. The training ledger never reads a run.
public struct TendRoutine: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "tendRoutine", summary: "Tend a routine",
        parameters: [.init("routine", .object, "The routine"), .init("at", .date, "Defaults to now", required: false)],
        isOfferedToModel: false
    )

    public var routine: UUID
    public var at: Date?

    public init(routine: UUID, at: Date? = nil) {
        self.routine = routine
        self.at = at
    }

    /// False once it was already tended today (nothing is written then).
    public func apply(_ transaction: inout Transaction) throws -> Bool {
        let target = try transaction.object(routine, is: .routine)
        let when = at ?? transaction.now
        let tessera = TesseraDay(calendar: transaction.calendar)
        let day = tessera.start(of: when)
        let book = RestBook(store: transaction.store, classes: transaction.classes)
        if book.tendedDays(of: target.id, calendar: transaction.calendar).contains(tessera.day(of: when)) {
            return false
        }
        let run = try transaction.create(transaction.classDef(.routineRun), title: "Tended")
        try transaction.setLinks("routine", on: run, to: [target])
        try transaction.set("day", to: .date(day), on: run)
        try transaction.set("doneAt", to: .date(when), on: run)
        try transaction.set("stepsDone", to: .number(Double(target.orderedChildren.count)), on: run)
        try transaction.set("by", to: .choice("tended"), on: run)
        if let pause = book.pause(of: target.id, on: when, calendar: transaction.calendar) {
            try transaction.set("endedAt", to: .date(when), on: pause)
        }
        return true
    }

    public func summary(in store: ObjectStore) -> String {
        "Tended \(store.object(id: routine).map { ElementActionLine.shown($0, in: store) } ?? "a routine")"
    }

    public func receipt(in store: ObjectStore, output wrote: Bool) -> String? {
        guard let target = store.object(id: routine) else { return nil }
        let shown = ElementActionLine.shown(target, in: store)
        return wrote ? "\(shown), done for today" : "\(shown) is done for today"
    }

    public func receipt(in _: ObjectStore) -> String? {
        nil
    }
}

// MARK: - plantRoutine

/// Plants a routine: its cadence and its grove, picked on the phone from the name (no model). A private name is planted
/// as "Private routine".
public struct PlantRoutine: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "plantRoutine", summary: "Plant a routine",
        parameters: [.init("name", .string, "What it is, e.g. Journal"),
                     .init("cadence", .string, "day, week or month; day when left out", required: false),
                     .init("weekdays", .string, "Days, 1 Sunday to 7 Saturday, comma separated", required: false)],
        isOfferedToModel: false
    )

    public var name: String
    public var cadence: String?
    public var weekdays: String?

    public init(name: String, cadence: String? = nil, weekdays: String? = nil) {
        self.name = name
        self.cadence = cadence
        self.weekdays = weekdays
    }

    /// What a routine with a private name is planted as.
    public static let privateName = "Private routine"

    static let groves: [(grove: String, words: [String])] = [
        ("mind", ["journal", "read", "reading", "meditate", "meditation", "study", "write", "writing", "pray"]),
        ("home", ["tidy", "clean", "water plants", "laundry", "dishes", "declutter", "vacuum"]),
        ("body", ["walk", "stretch", "swim", "run", "yoga", "gym", "lift", "cycle", "bike"]),
    ]

    /// The grove for a name; body when unsure.
    public static func grove(for name: String) -> String {
        let lower = name.lowercased()
        for (grove, words) in groves where words.contains(where: { lower.contains($0) }) {
            return grove
        }
        return "body"
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 60, !looksLikeClaudeKey(trimmed) else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "refused: name")
        }
        let isPrivate = ObjectPrivacy.isPrivateTitle(trimmed, lastWeightKg: BodyWeight.lastKg(in: transaction.store))
        // The real name stays on the device; `ObjectPrivacy.shownLabel` says "Private routine" wherever it is shown.
        let routine = try transaction.create(transaction.classDef(.routine), title: trimmed)
        let days = (weekdays ?? "").split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            .filter { (1 ... 7).contains($0) }
        let rhythm = ["day", "week", "month"].contains(cadence ?? "") ? cadence! : "day"
        try transaction.set("cadence", to: .choice(days.isEmpty ? rhythm : "week"), on: routine)
        if !days.isEmpty {
            try transaction.set("fixedWeekdays", to: .text(Set(days).sorted().map(String.init).joined(separator: ",")),
                                on: routine)
        }
        try transaction.set("grove", to: .choice(isPrivate ? "body" : Self.grove(for: trimmed)), on: routine)
        return routine
    }

    public func summary(in _: ObjectStore) -> String {
        "Planted a routine"
    }

    public func receipt(in store: ObjectStore, output routine: ObjectRecord) -> String? {
        // The stored name is the real one; the receipt says the private label when either privacy rule calls it private.
        let hidden = ObjectPrivacy.isPrivateTitle(routine.title, lastWeightKg: BodyWeight.lastKg(in: store))
        return "\(hidden ? Self.privateName : ElementActionLine.shown(routine, in: store)), planted"
    }

    public func receipt(in _: ObjectStore) -> String? {
        nil
    }
}
