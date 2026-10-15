import Foundation

/// Nightly roll-forward (M2 slice 2): at the day change (04:00, not midnight), unfinished tasks from earlier days
/// move to today at the same time of day. After 7 rolls a task goes to Later. One action, so one undo.
public struct RollForwardTasks: EngineAction {
    /// The day changes at 04:00, so a late-night task still belongs to "today".
    public static let dayStartHour = 4
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

        /// One neutral line for Tess, or nil when nothing moved. Never counts misses.
        public var line: String? {
            switch (rolled.count, toLater.count) {
            case (0, 0): nil
            case (_, 0): rolled.count == 1 ? "Carried one task into today." : "Carried \(rolled.count) tasks into today."
            case (0, _): toLater.count == 1 ? "Put one task in Later." : "Put \(toLater.count) tasks in Later."
            default: "Carried \(rolled.count) into today, put \(toLater.count) in Later."
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
            } else {
                let days = calendar.dateComponents([.day], from: day, to: today).day ?? 1
                let moved = calendar.date(byAdding: .day, value: days, to: startsAt) ?? startsAt
                try transaction.set("startsAt", to: .date(moved), on: task)
                outcome.rolled.append(task.id)
            }
        }
        return outcome
    }

    /// The start (04:00) of the day a moment belongs to.
    static func logicalDay(of date: Date, calendar: Calendar) -> Date {
        let shifted = date.addingTimeInterval(-Double(dayStartHour) * 3600)
        return calendar.startOfDay(for: shifted)
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
    func rollForward(engine: ActionEngine, now: Date = .now) -> String? {
        let preview = RollForwardTasks.logicalDay(of: now, calendar: .current)
        let needed = today(now).contains { item in
            item.isCarriedOver || item.when
                .map { RollForwardTasks.logicalDay(of: $0, calendar: .current) < preview } == true
        }
        guard needed, let result = try? engine.perform(RollForwardTasks(time: now), by: .system) else { return nil }
        return result.output.line
    }
}
