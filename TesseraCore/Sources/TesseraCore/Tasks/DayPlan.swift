import Foundation

/// The rules plan for "Plan my day" (M4 slice 6; docs/research/plan-my-day-scenarios.md R1 to R8 with
/// fixtures/plan-my-day-claude.md's changes, light-day.md C1 to C3). Pure: plain inputs in, a plan out, nothing
/// written. It is what Now shows at once, what Claude may reword, and what every failure falls back to ("Here's your
/// usual plan.").
public struct DayPlan: Sendable, Equatable {
    public enum Kind: String, Sendable, Equatable {
        case event, workout, timedTask, task
    }

    public struct Block: Sendable, Equatable {
        public let kind: Kind
        public let title: String
        public var start: Date
        public var end: Date
        /// The task or workout it stands for; nil for a calendar event.
        public let object: UUID?
        /// A plan line he accepts or skips (a task the rules placed). Fixed blocks never are.
        public let ghost: Bool
        /// A timed due the block ends by, kept only when the rules placed it before the due.
        public var due: Date?
        /// Where the workout was before an event pushed it (R3, A7).
        public var movedFrom: Date?
        /// A workout under way at open.
        public var running: Bool

        public var minutes: Int {
            Int(end.timeIntervalSince(start) / 60)
        }
    }

    public enum Skip: String, Sendable, Equatable {
        case cap, noFit
    }

    /// Today's window: from now (rounded up to 5 minutes, never before 07:00) to 21:00. Nil when it has closed.
    public let window: DateInterval?
    /// Time order.
    public let blocks: [Block]
    public let cap: Int
    public let light: Bool
    /// All-day titles, birthdays dropped.
    public let allDay: [String]
    /// Today's tasks the plan left out, and why.
    public let notPlanned: [(title: String, why: Skip)]

    /// The earliest task or workout block (R8); nil when the plan has none.
    public var startWith: Block? {
        blocks.first { $0.kind != .event }
    }

    public var ghosts: [Block] {
        blocks.filter(\.ghost)
    }

    /// Runs of ghost tasks back to back with no fixed block between them (what Claude may reorder inside).
    public var runs: [[Block]] {
        var runs: [[Block]] = []
        var current: [Block] = []
        for block in blocks {
            if block.ghost, let last = current.last, last.end == block.start {
                current.append(block)
            } else {
                if !current.isEmpty {
                    runs.append(current)
                }
                current = block.ghost ? [block] : []
            }
        }
        if !current.isEmpty {
            runs.append(current)
        }
        return runs
    }

    public static func == (lhs: DayPlan, rhs: DayPlan) -> Bool {
        lhs.window == rhs.window && lhs.blocks == rhs.blocks && lhs.cap == rhs.cap && lhs.light == rhs.light
            && lhs.allDay == rhs.allDay && lhs.notPlanned.map(\.title) == rhs.notPlanned.map(\.title)
    }
}

/// What the rules read. The store builder fills it from tasks, the day's workout and the training week; calendar
/// events come from the app once it reads the calendar.
public struct PlanInput: Sendable {
    public struct Task: Sendable {
        public let id: UUID
        public let title: String
        /// Planned for a time today.
        public var startsAt: Date?
        public var due: Date?
        /// A due with no time of day.
        public var dueIsDateOnly = false
        public var minutes: Double?
        public var rolls = 0
        public var rolledFrom: Date?
        public var updatedAt: Date
        /// A cook task: 45 minutes by default, never before 18:00.
        public var isCook = false

        public init(id: UUID = UUID(), title: String, startsAt: Date? = nil, due: Date? = nil,
                    dueIsDateOnly: Bool = false, minutes: Double? = nil, rolls: Int = 0, rolledFrom: Date? = nil,
                    updatedAt: Date, isCook: Bool = false)
        {
            self.id = id
            self.title = title
            self.startsAt = startsAt
            self.due = due
            self.dueIsDateOnly = dueIsDateOnly
            self.minutes = minutes
            self.rolls = rolls
            self.rolledFrom = rolledFrom
            self.updatedAt = updatedAt
            self.isCook = isCook
        }
    }

    public struct Event: Sendable {
        public let title: String
        public let start: Date
        public let end: Date
        public var allDay = false
        public var declined = false

        public init(title: String, start: Date, end: Date, allDay: Bool = false, declined: Bool = false) {
            self.title = title
            self.start = start
            self.end = end
            self.allDay = allDay
            self.declined = declined
        }
    }

    public struct Workout: Sendable {
        public let id: UUID?
        public let title: String
        /// Its planned time; a date with no time (00:00) means the first free hour from 17:00.
        public var scheduledFor: Date?
        public var startedAt: Date?
        public var endedAt: Date?

        public init(id: UUID? = nil, title: String, scheduledFor: Date? = nil, startedAt: Date? = nil,
                    endedAt: Date? = nil)
        {
            self.id = id
            self.title = title
            self.scheduledFor = scheduledFor
            self.startedAt = startedAt
            self.endedAt = endedAt
        }
    }

    public var now: Date
    public var calendar: Calendar
    public var events: [Event] = []
    /// Today's open tasks: planned or due today, and carried over.
    public var today: [Task] = []
    /// Undated tasks (Later).
    public var later: [Task] = []
    /// The day's workout; nil on a rest day or with no plan.
    public var workout: Workout?
    /// From light-day.md C1 to C3 (`DayPlanner.isLight`): two plan lines instead of three.
    public var light = false

    public init(now: Date, calendar: Calendar) {
        self.now = now
        self.calendar = calendar
    }
}

public enum DayPlanner {
    public static let windowFloorHour = 7
    public static let windowEndHour = 21
    public static let defaultTaskMinutes = 30.0
    public static let cookMinutes = 45.0
    public static let cookFromHour = 18
    public static let workoutMinutes = 60.0

    /// R1 to R8.
    public static func plan(_ input: PlanInput) -> DayPlan {
        let calendar = input.calendar
        let day = TesseraDay(calendar: calendar).day(of: input.now)
        let at = { (hour: Int) in calendar.date(byAdding: .hour, value: hour, to: day) ?? day }
        let allDay = input.events.filter { $0.allDay && !$0.declined && !$0.title.lowercased().contains("birthday") }
            .map(\.title)
        let cap = input.light ? 2 : 3
        // R1: now rounded up to 5 minutes, never before 07:00, to 21:00.
        let rounded = Date(timeIntervalSinceReferenceDate: (input.now.timeIntervalSinceReferenceDate / 300)
            .rounded(.up) * 300)
        let from = max(rounded, at(windowFloorHour)), to = at(windowEndHour)
        guard from < to else {
            return DayPlan(window: nil, blocks: [], cap: cap, light: input.light, allDay: allDay, notPlanned: [])
        }
        let window = DateInterval(start: from, end: to)
        // R2: fixed blocks.
        var fixed = input.events.filter { !$0.allDay && !$0.declined && $0.end > from && $0.start < to }
            .map { DayPlan.Block(kind: .event, title: $0.title, start: $0.start, end: $0.end, object: nil, ghost: false,
                                 due: nil, movedFrom: nil, running: false) }
        let timedToday = input.today.filter { task in
            guard task.rolls == 0, let start = task.startsAt else { return false }
            return start >= from && start < to
        }
        fixed += timedToday.map { task in
            let start = task.startsAt ?? from
            return DayPlan.Block(kind: .timedTask, title: task.title, start: start,
                                 end: start.addingTimeInterval((task.minutes ?? defaultTaskMinutes) * 60),
                                 object: task.id, ghost: false, due: nil, movedFrom: nil, running: false)
        }
        // R3: the workout.
        if let workout = input.workout, workout.endedAt == nil,
           let block = workoutBlock(workout, fixed: fixed, from: from, to: to, day: day, calendar: calendar)
        {
            fixed.append(block)
        }
        fixed.sort { $0.start < $1.start }
        // R4: the order.
        let timedIDs = Set(timedToday.map(\.id))
        let open = input.today.filter { !timedIDs.contains($0.id) }
        func by(_ key: @escaping (PlanInput.Task) -> Date) -> (PlanInput.Task, PlanInput.Task) -> Bool {
            { key($0) == key($1) ? $0.title < $1.title : key($0) < key($1) }
        }
        let carried = open.filter { $0.rolls >= 1 }.sorted(by: by { $0.rolledFrom ?? .distantPast })
        let rest = open.filter { $0.rolls == 0 }
        let timedDue = rest.filter { $0.due != nil && !$0.dueIsDateOnly && $0.startsAt == nil }
            .sorted(by: by { $0.due ?? .distantFuture })
        let dateDue = rest.filter { $0.due != nil && $0.dueIsDateOnly && $0.startsAt == nil }
            .sorted(by: by(\.updatedAt))
        // Today's timed tasks whose time has passed (A11); later ones are fixed blocks above.
        let passed = rest.filter { $0.startsAt.map { $0 < from } ?? false }
            .sorted(by: by { $0.startsAt ?? .distantPast })
        let undated = rest.filter { $0.startsAt == nil && $0.due == nil }.sorted(by: by(\.updatedAt))
        let later = input.later.sorted(by: by(\.updatedAt))
        let todayOrder = carried + timedDue + dateDue + passed + undated
        // R5: earliest gap that holds it; stop at the cap.
        var blocks = fixed
        var notPlanned: [(title: String, why: DayPlan.Skip)] = []
        var placed = 0
        for (index, task) in (todayOrder + later).enumerated() {
            let isToday = index < todayOrder.count
            guard placed < cap else {
                if isToday {
                    notPlanned.append((task.title, .cap))
                }
                continue
            }
            let minutes = task.minutes ?? (task.isCook ? cookMinutes : defaultTaskMinutes)
            let earliest = task.isCook ? max(from, at(cookFromHour)) : from
            guard let start = firstGap(minutes: minutes, after: earliest, before: to, busy: blocks) else {
                if isToday {
                    notPlanned.append((task.title, .noFit))
                }
                continue
            }
            let end = start.addingTimeInterval(minutes * 60)
            // A timed due stays only when the block ends by it (else Tess can't point at it).
            let due = task.dueIsDateOnly ? nil : task.due.flatMap { end <= $0 ? $0 : nil }
            blocks.append(DayPlan.Block(kind: .task, title: task.title, start: start, end: end, object: task.id,
                                        ghost: true, due: due, movedFrom: nil, running: false))
            blocks.sort { $0.start < $1.start }
            placed += 1
        }
        return DayPlan(window: window, blocks: blocks, cap: cap, light: input.light, allDay: allDay,
                       notPlanned: notPlanned)
    }

    /// R3: at its time; a date-only one in the first free hour from 17:00; an event over it wins and the workout
    /// moves to the first free hour after that event (A7). A running one sits at its start.
    static func workoutBlock(_ workout: PlanInput.Workout, fixed: [DayPlan.Block], from: Date, to: Date, day: Date,
                             calendar: Calendar) -> DayPlan.Block?
    {
        let hour = workoutMinutes * 60
        func block(_ start: Date, movedFrom: Date? = nil, running: Bool = false) -> DayPlan.Block {
            DayPlan.Block(kind: .workout, title: workout.title, start: start, end: start.addingTimeInterval(hour),
                          object: workout.id, ghost: false, due: nil, movedFrom: movedFrom, running: running)
        }
        if let started = workout.startedAt {
            return block(started, running: true)
        }
        guard let planned = workout.scheduledFor else { return nil }
        let dateOnly = calendar.dateComponents([.hour, .minute], from: planned) == DateComponents(hour: 0, minute: 0)
        if dateOnly {
            let evening = calendar.date(byAdding: .hour, value: 17, to: day) ?? day
            return firstGap(minutes: workoutMinutes, after: max(evening, from), before: to, busy: fixed)
                .map { block($0) }
        }
        let range = planned ..< planned.addingTimeInterval(hour)
        guard let clash = fixed.filter({ $0.start < range.upperBound && $0.end > range.lowerBound })
            .max(by: { $0.end < $1.end }) else { return block(planned) }
        return firstGap(minutes: workoutMinutes, after: clash.end, before: to, busy: fixed)
            .map { block($0, movedFrom: planned) }
    }

    /// The start of the earliest free stretch of `minutes` between `after` and `before`.
    static func firstGap(minutes: Double, after: Date, before: Date, busy: [DayPlan.Block]) -> Date? {
        var cursor = after
        for block in busy.sorted(by: { $0.start < $1.start }) where block.end > cursor {
            if block.start.timeIntervalSince(cursor) >= minutes * 60 {
                break
            }
            cursor = max(cursor, block.end)
        }
        return cursor.addingTimeInterval(minutes * 60) <= before ? cursor : nil
    }

    // MARK: Light (light-day.md)

    public enum LightReason: String, Sendable {
        case squeezedWeek, bookedDay, cutUpDay
    }

    /// C1 squeezed week, C2 booked day (480 minutes), C3 cut-up day (5 fixed blocks); first that fires. Sleep,
    /// energy and health are never inputs.
    public static func lightReason(trainingDay: Bool, perWeek: Int?, sessionsBeforeToday: Int, daysLeft: Int,
                                   bookedMinutes: Double, fixedBlocks: Int) -> LightReason?
    {
        if trainingDay, let perWeek, perWeek > 0 {
            let due = perWeek - sessionsBeforeToday
            if due >= daysLeft, due >= 2 {
                return .squeezedWeek
            }
        }
        if bookedMinutes >= 480 {
            return .bookedDay
        }
        return fixedBlocks >= 5 ? .cutUpDay : nil
    }
}
