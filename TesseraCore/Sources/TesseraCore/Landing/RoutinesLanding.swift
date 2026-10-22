import Foundation

/// What the Routines landing says (design 131, Product build sheet Oct 22, trimmed). Pure: the rows arrive as plain
/// values (a routine's name, its step or exercise count, its runs, whether it is running), so the same words serve
/// workout days and step routines. The running workout is read with `ProcessTable.openWorkout()`; step routines have no
/// reader yet. A walled name is "Private routine" and a walled step "Private step", masked here and never later.
/// Nothing counts a miss: there is no streak, no "missed", no "skipped".
public enum RoutinesLanding {
    public struct Item: Sendable {
        public let name: String
        public let isWorkout: Bool
        /// Steps (or exercises for a workout day).
        public let count: Int
        public let isPrivate: Bool
        public let runs: [RoutineRun]
        /// When it was finished today, if it was.
        public let doneToday: Date?

        public init(name: String, isWorkout: Bool = false, count: Int, isPrivate: Bool = false,
                    runs: [RoutineRun] = [], doneToday: Date? = nil)
        {
            self.name = name
            self.isWorkout = isWorkout
            self.count = count
            self.isPrivate = isPrivate
            self.runs = runs
            self.doneToday = doneToday
        }
    }

    public struct Running: Sendable {
        public let name: String
        public let isPrivate: Bool
        public let step: String
        public let isStepPrivate: Bool
        public let secondsOnStep: TimeInterval
        public let isPaused: Bool

        public init(name: String, isPrivate: Bool = false, step: String, isStepPrivate: Bool = false,
                    secondsOnStep: TimeInterval, isPaused: Bool = false)
        {
            self.name = name
            self.isPrivate = isPrivate
            self.step = step
            self.isStepPrivate = isStepPrivate
            self.secondsOnStep = secondsOnStep
            self.isPaused = isPaused
        }
    }

    public struct Top: Equatable, Sendable {
        public let sentence: LandingSentence
        /// The step in large words, or nil when nothing runs.
        public let step: String?
        public let onThisStep: String?
        /// "Start Morning" words, at most three, on a quiet day.
        public let starts: [String]
    }

    public struct Facts: Equatable, Sendable {
        public let subtitle: LandingSentence
        public let top: Top
        public let lines: [String]
    }

    public static let privateRoutine = "Private routine"
    public static let privateStep = "Private step"
    public static let maxLines = 3
    public static let maxStarts = 3
    public static let recentDays = 30

    public static func facts(items: [Item], running: Running?, now: Date, calendar: Calendar = .current) -> Facts {
        let shown = { (item: Item) in item.isPrivate ? privateRoutine : item.name }
        let doneCount = items.count { $0.doneToday != nil }
        return Facts(
            subtitle: subtitle(total: items.count, done: doneCount),
            top: top(items: items, running: running, done: doneCount, now: now, calendar: calendar, shown: shown),
            lines: Array(ordered(items, now: now, calendar: calendar).prefix(maxLines)).map { line(
                $0,
                calendar: calendar
            ) }
        )
    }

    static func subtitle(total: Int, done: Int) -> LandingSentence {
        switch (total, done) {
        case (0, _): LandingSentence(text: "Nothing set up yet.", key: nil)
        case let (count, finished) where finished == count: LandingSentence(text: "All done today.", key: nil)
        case (1, _): LandingSentence(text: "1 routine.", key: nil)
        case let (count, 0): LandingSentence(text: "\(count) routines.", key: nil)
        case let (count, finished): LandingSentence(text: "\(count) routines, \(finished) done today.", key: nil)
        }
    }

    static func top(items: [Item], running: Running?, done: Int, now: Date, calendar: Calendar,
                    shown: (Item) -> String) -> Top
    {
        if let running {
            let name = running.isPrivate ? privateRoutine : running.name
            let step = running.isStepPrivate || running.isPrivate ? privateStep : running.step
            let minutes = Int(running.secondsOnStep / 60)
            if running.isPaused {
                return Top(sentence: LandingSentence(text: "\(name) is paused", key: name), step: step,
                           onThisStep: "Paused at \(HouseTime.minutes(minutes)) on this step", starts: [])
            }
            return Top(sentence: LandingSentence(text: "\(name) is running", key: name), step: step,
                       onThisStep: LandingSentences.onThisStep(seconds: running.secondsOnStep), starts: [])
        }
        if !items.isEmpty, done == items.count {
            return Top(sentence: LandingSentence(text: "Everything is done today", key: nil), step: nil,
                       onThisStep: nil, starts: [])
        }
        let recent = calendar.date(byAdding: .day, value: -recentDays, to: now) ?? now
        let starts = items.sorted { lhs, rhs in
            let lhsRuns = lhs.runs.count { $0.start >= recent }, rhsRuns = rhs.runs.count { $0.start >= recent }
            return lhsRuns != rhsRuns ? lhsRuns > rhsRuns : lhs.name < rhs.name
        }
        .prefix(maxStarts).map { "Start \(shown($0))" }
        return Top(sentence: LandingSentences.nothingRunning, step: nil, onThisStep: nil, starts: Array(starts))
    }

    /// Not done today first, then by runs in the last 30 days, then by name.
    static func ordered(_ items: [Item], now: Date, calendar: Calendar) -> [Item] {
        let recent = calendar.date(byAdding: .day, value: -recentDays, to: now) ?? now
        return items.sorted { lhs, rhs in
            if (lhs.doneToday == nil) != (rhs.doneToday == nil) {
                return lhs.doneToday == nil
            }
            let lhsRuns = lhs.runs.count { $0.start >= recent }, rhsRuns = rhs.runs.count { $0.start >= recent }
            return lhsRuns != rhsRuns ? lhsRuns > rhsRuns : lhs.name < rhs.name
        }
    }

    static func line(_ item: Item, calendar: Calendar) -> String {
        if item.isPrivate {
            return privateRoutine
        }
        if let done = item.doneToday {
            return "\(item.name), done at \(HouseTime.clock(done, calendar: calendar))"
        }
        if let usual = RoutineUsual.line(name: item.name, runs: item.runs, calendar: calendar) {
            return usual
        }
        let unit = item.isWorkout ? "exercise" : "step"
        return "\(item.name), \(item.count) \(unit)\(item.count == 1 ? "" : "s")"
    }
}
