import Foundation

// Editing a plan's cycle and its days (Design 44: Routines page, ROLLS ON / FIXED DAYS, the DAYS line). Every change is
// an op-log row, so each one UNDOes.

/// How a plan hands out its routines: in order, whatever the day, or each routine on its own weekdays.
public enum ScheduleMode: String, Codable, Sendable, CaseIterable {
    /// The next routine comes next; a missed day rolls on (Product's rule).
    case rolling
    /// Each routine has fixed weekdays; a missed day does not roll on (Product 1fdd1c6).
    case fixed
}

/// Weekdays as the calendar numbers them (1 Sunday to 7 Saturday), and as Tess says them.
public enum Weekdays {
    public static let names = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    public static let short = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    public static func name(_ weekday: Int) -> String {
        names[(weekday - 1 + 7) % 7]
    }

    /// "Mondays and Thursdays" for the receipt.
    static func plural(_ weekdays: [Int]) -> String {
        let words = weekdays.map { name($0) + "s" }
        switch words.count {
        case 0: return "no days"
        case 1: return words[0]
        default: return words.dropLast().joined(separator: ", ") + " and " + words.last!
            // swiftlint:disable:previous force_unwrapping
        }
    }

    /// Stored as "2,5" on the routine; Monday first in the order he reads.
    static func encode(_ weekdays: Set<Int>) -> String {
        ordered(weekdays).map(String.init).joined(separator: ",")
    }

    static func decode(_ text: String?) -> Set<Int> {
        Set((text ?? "").split(separator: ",").compactMap { Int($0) }.filter { (1 ... 7).contains($0) })
    }

    /// Monday to Sunday, as the DAYS line lists them.
    public static func ordered(_ weekdays: Set<Int>) -> [Int] {
        [2, 3, 4, 5, 6, 7, 1].filter(weekdays.contains)
    }
}

/// Adds a routine to a plan's cycle, at the end or at `at`. With CreateRoutine this is "Make a routine".
public struct AddRoutineToPlan: EngineAction {
    public static let descriptor = ActionDescriptor(name: "addRoutineToPlan", summary: "Add a routine to a plan",
                                                    parameters: [
                                                        .init("plan", .object, "The plan"),
                                                        .init("routine", .object, "The routine"),
                                                        .init("at", .integer, "Position in the cycle, 0 first",
                                                              required: false),
                                                    ])

    public var plan: UUID
    public var routine: UUID
    public var at: Int?

    public init(plan: UUID, routine: UUID, at: Int? = nil) {
        self.plan = plan
        self.routine = routine
        self.at = at
    }

    /// Returns the weekdays this routine took from others in the plan (newer pick wins, Product 4b857dc).
    public func apply(_ transaction: inout Transaction) throws -> [WeekdayHandoff] {
        let plan = try transaction.object(plan, is: .plan)
        let routine = try transaction.object(routine, is: .routine)
        var cycle = transaction.store.linkedObjects("routines", of: plan).filter { $0.id != routine.id }
        cycle.insert(routine, at: max(0, min(at ?? cycle.count, cycle.count)))
        try transaction.setLinks("routines", on: plan, to: cycle)
        // A routine arriving with days of its own takes them from the routines already here (QA L1 on #341).
        let days = PlanSchedule.weekdays(of: routine, store: transaction.store)
        return try PlanSchedule.take(days, for: routine, transaction: &transaction)
    }

    public func summary(in store: ObjectStore) -> String {
        "\(store.object(id: routine)?.title ?? "Routine") added to \(store.object(id: plan)?.title ?? "the plan")"
    }
}

/// Moves a routine within the cycle (hold and drag on the Routines page).
public struct MoveRoutineInPlan: EngineAction {
    public static let descriptor = ActionDescriptor(name: "moveRoutineInPlan", summary: "Reorder a plan's routines",
                                                    parameters: [
                                                        .init("plan", .object, "The plan"),
                                                        .init("routine", .object, "The routine"),
                                                        .init("to", .integer, "New position, 0 first"),
                                                    ])

    public var plan: UUID
    public var routine: UUID
    public var to: Int

    public init(plan: UUID, routine: UUID, to: Int) {
        self.plan = plan
        self.routine = routine
        self.to = to
    }

    public func apply(_ transaction: inout Transaction) throws {
        let plan = try transaction.object(plan, is: .plan)
        var cycle = transaction.store.linkedObjects("routines", of: plan)
        guard let from = cycle.firstIndex(where: { $0.id == routine }) else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "routine is not in the plan")
        }
        let moved = cycle.remove(at: from)
        cycle.insert(moved, at: max(0, min(to, cycle.count)))
        try transaction.setLinks("routines", on: plan, to: cycle)
    }

    public func summary(in store: ObjectStore) -> String {
        "Moved \(store.object(id: routine)?.title ?? "the routine")"
    }
}

/// Takes a routine out of the cycle. The routine and every workout from it stay in history.
public struct DropRoutineFromPlan: EngineAction {
    public static let descriptor = ActionDescriptor(name: "dropRoutineFromPlan", summary: "Drop a routine from a plan",
                                                    parameters: [
                                                        .init("plan", .object, "The plan"),
                                                        .init("routine", .object, "The routine"),
                                                    ])

    public var plan: UUID
    public var routine: UUID

    public init(plan: UUID, routine: UUID) {
        self.plan = plan
        self.routine = routine
    }

    public func apply(_ transaction: inout Transaction) throws {
        let plan = try transaction.object(plan, is: .plan)
        let cycle = transaction.store.linkedObjects("routines", of: plan).filter { $0.id != routine }
        guard cycle.count < transaction.store.linkedObjects("routines", of: plan).count else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "routine is not in the plan")
        }
        try transaction.setLinks("routines", on: plan, to: cycle)
        // Its days go with it, so re-adding it later never puts two routines on one weekday (QA L1 on #341).
        let dropped = try transaction.object(routine, is: .routine)
        if transaction.store.value("fixedWeekdays", of: dropped) != nil {
            try transaction.set("fixedWeekdays", to: nil, on: dropped)
        }
    }

    public func summary(in store: ObjectStore) -> String {
        "\(store.object(id: routine)?.title ?? "Routine") dropped"
    }
}

/// ROLLS ON or FIXED DAYS.
public struct SetScheduleMode: EngineAction {
    public static let descriptor = ActionDescriptor(name: "setScheduleMode", summary: "Rolling or fixed days",
                                                    parameters: [
                                                        .init("plan", .object, "The plan"),
                                                        .init("mode", .string, "rolling or fixed"),
                                                    ])

    public var plan: UUID
    public var mode: ScheduleMode

    public init(plan: UUID, mode: ScheduleMode) {
        self.plan = plan
        self.mode = mode
    }

    public func apply(_ transaction: inout Transaction) throws {
        let plan = try transaction.object(plan, is: .plan)
        try transaction.set("scheduleMode", to: .choice(mode.rawValue), on: plan)
    }

    public func summary(in store: ObjectStore) -> String {
        let title = store.object(id: plan)?.title ?? "The plan"
        return mode == .fixed ? "\(title) on fixed days" : "\(title) rolls on"
    }
}

/// Which routine a weekday came from when another took it: "Thursday was Pull A's."
public struct WeekdayHandoff: Equatable, Sendable {
    public let weekday: Int
    public let from: UUID
    public let fromTitle: String

    /// "Thursday was Pull A's. Push A has it now."
    public func line(to routine: String) -> String {
        "\(Weekdays.name(weekday)) was \(fromTitle)'s. \(routine) has it now"
    }
}

/// Sets a routine's fixed weekdays. One routine per day: a weekday another routine in the same plans had moves here,
/// and the result says which routine lost it, so the editor can say so in one line.
public struct SetRoutineWeekdays: EngineAction {
    public static let descriptor = ActionDescriptor(name: "setRoutineWeekdays", summary: "Pin a routine to weekdays",
                                                    parameters: [
                                                        .init("routine", .object, "The routine"),
                                                        .init("weekdays", .json, "Weekday numbers, 1 Sunday to 7"),
                                                    ])

    public var routine: UUID
    public var weekdays: [Int]

    public init(routine: UUID, weekdays: [Int]) {
        self.routine = routine
        self.weekdays = weekdays
    }

    public func apply(_ transaction: inout Transaction) throws -> [WeekdayHandoff] {
        let routine = try transaction.object(routine, is: .routine)
        let chosen = Set(weekdays.filter { (1 ... 7).contains($0) })
        guard chosen.count == weekdays.count else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "weekdays are 1 to 7")
        }
        try transaction.set("fixedWeekdays", to: .text(Weekdays.encode(chosen)), on: routine)
        return try PlanSchedule.take(chosen, for: routine, transaction: &transaction)
    }

    public func summary(in store: ObjectStore) -> String {
        let title = store.object(id: routine)?.title ?? "Routine"
        guard !weekdays.isEmpty else { return "\(title), no fixed days" }
        return "\(title) on \(Weekdays.plural(Weekdays.ordered(Set(weekdays))))"
    }
}

/// Reading a plan's schedule.
@MainActor
public enum PlanSchedule {
    public static func mode(of plan: ObjectRecord, store: ObjectStore) -> ScheduleMode {
        store.value("scheduleMode", of: plan)?.stringValue.flatMap(ScheduleMode.init(rawValue:)) ?? .rolling
    }

    /// The routine's fixed weekdays (1 Sunday to 7 Saturday); empty when it has none.
    public static func weekdays(of routine: ObjectRecord, store: ObjectStore) -> Set<Int> {
        Weekdays.decode(store.value("fixedWeekdays", of: routine)?.stringValue)
    }

    /// The routine pinned to a date's weekday, in a fixed-days plan.
    public static func routine(on date: Date, in plan: ObjectRecord, store: ObjectStore,
                               calendar: Calendar) -> ObjectRecord?
    {
        let weekday = calendar.component(.weekday, from: date)
        return store.linkedObjects("routines", of: plan).first { weekdays(of: $0, store: store).contains(weekday) }
    }

    /// One routine per weekday: every other routine sharing a plan with this one loses the days it now has, and the
    /// result says which routine lost which day.
    static func take(_ days: Set<Int>, for routine: ObjectRecord,
                     transaction: inout Transaction) throws -> [WeekdayHandoff]
    {
        guard !days.isEmpty else { return [] }
        var handoffs: [WeekdayHandoff] = []
        for other in siblings(of: routine, store: transaction.store, classes: transaction.classes) {
            let theirs = Weekdays.decode(transaction.store.value("fixedWeekdays", of: other)?.stringValue)
            let taken = theirs.intersection(days)
            guard !taken.isEmpty else { continue }
            handoffs += Weekdays.ordered(taken)
                .map { WeekdayHandoff(weekday: $0, from: other.id, fromTitle: other.title) }
            try transaction.set("fixedWeekdays", to: .text(Weekdays.encode(theirs.subtracting(taken))), on: other)
        }
        return handoffs
    }

    /// Whether any routine in the plan has a fixed day; without one, fixed mode falls back to rolling (QA L3).
    public static func hasFixedDays(_ plan: ObjectRecord, store: ObjectStore) -> Bool {
        store.linkedObjects("routines", of: plan).contains { !weekdays(of: $0, store: store).isEmpty }
    }

    /// Routines that share a plan with this one.
    static func siblings(of routine: ObjectRecord, store: ObjectStore,
                         classes: [SystemCatalog.Key: ClassDef]) -> [ObjectRecord]
    {
        guard let planClass = classes[.plan] else { return [] }
        var seen = Set<UUID>([routine.id])
        return store.objects(of: planClass).filter { !$0.isDeleted }
            .map { store.linkedObjects("routines", of: $0) }
            .filter { cycle in cycle.contains { $0.id == routine.id } }
            .flatMap(\.self)
            .filter { seen.insert($0.id).inserted }
    }
}
