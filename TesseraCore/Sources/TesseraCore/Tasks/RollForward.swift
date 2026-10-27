import Foundation

/// Nightly roll-forward (M2 slice 2): at the day change (04:00, not midnight), unfinished tasks from earlier days
/// move to today at the same time of day. After 7 rolls a task goes to Later. One action, so one undo.
public struct RollForwardTasks: EngineAction {
    /// The day changes at 04:00, so a late-night task still belongs to "today".
    public static var dayStartHour: Int {
        TesseraDay.startHour
    }

    public static let rollsBeforeLater = 7

    public static let descriptor = ActionDescriptor(
        name: "rollForwardTasks",
        summary: "Roll unfinished tasks to today",
        parameters: [
            .init("time", .date, "Now; defaults to the current time", required: false),
        ]
    )

    public var time: Date?

    public init(time: Date? = nil) {
        self.time = time
    }

    /// The tasks that rolled to today and the ones that went to Later.
    public struct Outcome: Sendable {
        public var rolled: [UUID] = []
        public var toLater: [UUID] = []
        /// Titles, so one moved task is named in the line.
        public var titles: [UUID: String] = [:]

        /// One neutral line for Tess, name first (lines audit 2, item 5), or nil when nothing moved. Never counts
        /// misses.
        public var line: String? {
            func tasks(_ count: Int) -> String {
                count == 1 ? "1 task" : "\(count) tasks"
            }
            switch (rolled.count, toLater.count) {
            case (0, 0): return nil
            case (_, 0):
                let one = rolled.count == 1 ? rolled.first.flatMap { titles[$0] } : nil
                return "\(one ?? tasks(rolled.count)) carried into today"
            case (0, _):
                let one = toLater.count == 1 ? toLater.first.flatMap { titles[$0] } : nil
                return "\(one ?? tasks(toLater.count)) moved to Later"
            default: return "\(tasks(rolled.count)) carried into today, \(toLater.count) to Later"
            }
        }
    }

    public func apply(_ transaction: inout Transaction) throws -> Outcome {
        let now = time ?? .now
        let calendar = Calendar.current
        let today = Self.logicalDay(of: now, calendar: calendar)
        let store = transaction.store
        var outcome = Outcome()
        for task in try store.objects(of: transaction.classDef(.task)) {
            guard store.value("isDone", of: task) != .bool(true),
                  let startsAt = store.value("startsAt", of: task)?.dateValue else { continue }
            let day = Self.logicalDay(of: startsAt, calendar: calendar)
            guard day < today else { continue }
            let rolls = Int(store.number("rolls", of: task) ?? 0) + 1
            if store.value("rolledFrom", of: task) == nil {
                try transaction.set("rolledFrom", to: .date(startsAt), on: task)
            }
            try transaction.set("rolls", to: .number(Double(rolls)), on: task)
            if rolls >= Self.rollsBeforeLater {
                try transaction.set("startsAt", to: nil, on: task)
                try transaction.set("due", to: nil, on: task)
                outcome.toLater.append(task.id)
                outcome.titles[task.id] = task.title
            } else {
                let days = calendar.dateComponents([.day], from: day, to: today).day ?? 1
                let moved = calendar.date(byAdding: .day, value: days, to: startsAt) ?? startsAt
                try transaction.set("startsAt", to: .date(moved), on: task)
                outcome.rolled.append(task.id)
                outcome.titles[task.id] = task.title
            }
        }
        return outcome
    }

    /// The day (its midnight key) a moment belongs to: `TesseraDay`, the one rule (DST-safe).
    public static func logicalDay(of date: Date, calendar: Calendar) -> Date {
        TesseraDay(calendar: calendar).day(of: date)
    }

    public func summary(in _: ObjectStore) -> String {
        "Rolled unfinished tasks forward"
    }
}

@MainActor
public extension TaskList {
    /// Runs the roll-forward if anything needs it (call on launch and when the app comes to the foreground).
    /// Returns Tess's line, or nil when nothing moved; nothing is logged when nothing moved.
    @discardableResult
    func rollForward(engine: ActionEngine, now: Date = .now, calendar: Calendar = .current) -> String? {
        let preview = RollForwardTasks.logicalDay(of: now, calendar: calendar)
        let needed = today(now, calendar: calendar).contains { item in
            item.isCarriedOver || item.when
                .map { RollForwardTasks.logicalDay(of: $0, calendar: calendar) < preview } == true
        }
        guard needed, let result = try? engine.perform(RollForwardTasks(time: now), by: .system) else { return nil }
        return result.output.line
    }
}
