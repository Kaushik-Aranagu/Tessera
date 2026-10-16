import Foundation

/// One week as the phone counts it (Design 46's bands; the pack for the week story, AI-11). Counts, titles and short
/// exercise names only: never body weight, money, notes or health, even when logged (Research, AI-11 eval). The
/// Review bands for weight and money read their own figures elsewhere, not through this lens.
public struct WeekFacts: Equatable, Sendable {
    public struct Day: Equatable, Sendable {
        /// The day's 04:00 start.
        public let date: Date
        /// 1 Sunday to 7 Saturday.
        public let weekday: Int
        /// Trained, with the routines finished that day.
        public let trained: [String]
        /// The routine the plan had for it; nil on a rest day, a day before first use, or with no plan.
        public let planned: String?
        /// A past planned day with nothing done (never "missed" in words).
        public let wasDue: Bool
        public let tasksDone: Int
        /// Recipes cooked that day.
        public let cooked: [String]
        /// Whether the day is before the first thing he ever did in the app.
        public let beforeFirstUse: Bool

        public var isToday = false
    }

    public struct Record: Equatable, Sendable {
        /// Short name: "Bench".
        public let exercise: String
        /// "e1RM" or "5RM".
        public let kind: String
    }

    /// One of the week's lines, with the day it belongs to.
    public struct Line: Equatable, Sendable {
        public let day: Date
        public let line: DayLine
    }

    public let days: [Day]
    /// Days with a finished workout.
    public let trainedDays: Int
    /// Days the plan had a routine for, counted from first use (not from Monday).
    public let plannedDays: Int
    public let routinesDone: [String]
    public let records: [Record]
    public let tasksDone: Int
    public let cookedDays: Int
    public let recipesCooked: [String]
    /// The next planned routine and its day; nil when the plan has ended or there is none.
    public let next: (title: String, day: Date?)?
    /// The three lines worth telling: a record first, then a first time, then the fullest day.
    public let bestLines: [Line]

    public static func == (lhs: WeekFacts, rhs: WeekFacts) -> Bool {
        lhs.days == rhs.days && lhs.records == rhs.records && lhs.bestLines == rhs.bestLines
            && lhs.next?.title == rhs.next?.title && lhs.next?.day == rhs.next?.day
            && lhs.routinesDone == rhs.routinesDone && lhs.recipesCooked == rhs.recipesCooked
    }
}

/// Builds `WeekFacts` from the store, on the pattern of `HomeFacts`.
@MainActor
public struct WeekFactsBuilder {
    public let engine: ActionEngine
    public var calendar: Calendar

    public init(engine: ActionEngine, calendar: Calendar = .current) {
        self.engine = engine
        self.calendar = calendar
    }

    var store: ObjectStore {
        engine.store
    }

    /// The week containing `date`, read at `now`.
    public func facts(weekContaining date: Date, plan: ObjectRecord?, now: Date = .now) -> WeekFacts {
        let ledger = TrainingLedger(store: store, classes: engine.classes)
        let tesseraDay = TesseraDay(calendar: calendar)
        let today = tesseraDay.today(now)
        let week = ledger.week(containing: date, plan: plan, now: now, calendar: calendar)
        let firstUse = firstUse()
        let cooks = cooksByDay()
        let dones = tasksDoneByDay()
        var records: [WeekFacts.Record] = []
        var routinesDone: [String] = []
        let days = week.map { weekDay -> WeekFacts.Day in
            let before = firstUse.map { weekDay.day < tesseraDay.day(of: $0) } ?? true
            for summary in weekDay.done {
                routinesDone.append(summary.title)
                records += summary.records.map {
                    WeekFacts.Record(exercise: ExerciseWords.short($0.exercise), kind: Self.kindWord($0.kind))
                }
            }
            let planned = before ? nil : weekDay.planned.map { store.displayTitle(of: $0) }
            var day = WeekFacts.Day(date: weekDay.day, weekday: calendar.component(.weekday, from: weekDay.day),
                                    trained: weekDay.done.map(\.title), planned: planned,
                                    wasDue: weekDay.wasDue && !before, tasksDone: dones[weekDay.day] ?? 0,
                                    cooked: cooks[weekDay.day] ?? [], beforeFirstUse: before)
            day.isToday = weekDay.state == .today
            return day
        }
        let planLive = plan.map { !Self.hasEnded($0, store: store, now: now) } ?? false
        let nextRoutine = planLive ? plan.flatMap { ledger.nextRoutine(in: $0) } : nil
        let nextDay = week.first { $0.state != .past && $0.done.isEmpty && $0.planned?.id == nextRoutine?.id }?.day
        let plannedDays = days.count { day in
            !day.beforeFirstUse && (!day.trained.isEmpty || day.wasDue || (day.date >= today && day.planned != nil))
        }
        return WeekFacts(days: days, trainedDays: days.count { !$0.trained.isEmpty }, plannedDays: plannedDays,
                         routinesDone: routinesDone, records: records, tasksDone: days.reduce(0) { $0 + $1.tasksDone },
                         cookedDays: days.count { !$0.cooked.isEmpty },
                         recipesCooked: Array(NSOrderedSet(array: days.flatMap(\.cooked))) as? [String] ?? [],
                         next: nextRoutine.map { (store.displayTitle(of: $0), nextDay) },
                         bestLines: bestLines(for: week.map(\.day), now: now))
    }

    /// A day's own lines, for the tap on a day (Design 46). `moment` is any instant in his day (04:00 to 04:00).
    public func lines(on moment: Date, now: Date = .now, isRestDay: Bool = false) -> [DayLine] {
        DayStory.lines(engine: engine, on: moment, calendar: calendar, now: now, isRestDay: isRestDay)
    }

    /// The same for a day key as `WeekFacts.Day.date` carries it (a midnight, which on its own would read as the
    /// day before under the 04:00 rule).
    public func lines(onDay key: Date, now: Date = .now, isRestDay: Bool = false) -> [DayLine] {
        lines(on: Self.noon(of: key, calendar: calendar), now: now, isRestDay: isRestDay)
    }

    static func noon(of key: Date, calendar: Calendar) -> Date {
        calendar.date(bySettingHour: 12, minute: 0, second: 0, of: key) ?? key.addingTimeInterval(12 * 3600)
    }

    /// The three lines worth telling, over the week's days up to today: a record first, then a first time ("New
    /// routine:", "Saved"), then the fullest finished thing, each at most once a day.
    func bestLines(for days: [Date], now: Date) -> [WeekFacts.Line] {
        let today = TesseraDay(calendar: calendar).today(now)
        var ranked: [(rank: Int, line: WeekFacts.Line)] = []
        for day in days where day <= today {
            for line in lines(onDay: day, now: now) where line.kind == .finished {
                let rank = line.text.contains(", PR.") ? 0
                    : line.text.hasPrefix("New ") || line.text.hasPrefix("Saved ") ? 1
                    : line.text.contains(" min") ? 2 : 3
                ranked.append((rank, WeekFacts.Line(day: day, line: line)))
            }
        }
        var seenDays = Set<Date>()
        return ranked.sorted { ($0.rank, $0.line.day) < ($1.rank, $1.line.day) }
            .filter { seenDays.insert($0.line.day).inserted }
            .prefix(3).map(\.line)
    }

    /// The first thing he did: the oldest op that isn't the system's. Nil in an empty store.
    func firstUse() -> Date? {
        store.context.operations.values.lazy.filter { $0.actor != .system }.map(\.createdAt).min()
    }

    func cooksByDay() -> [Date: [String]] {
        guard let cookClass = engine.classes[.cook] else { return [:] }
        let day = TesseraDay(calendar: calendar)
        var cooks: [Date: [String]] = [:]
        for cook in store.objects(of: cookClass) where !cook.isDeleted {
            guard let at = store.value("cookedAt", of: cook)?.dateValue else { continue }
            cooks[day.day(of: at), default: []].append(store.displayTitle(of: cook))
        }
        return cooks
    }

    func tasksDoneByDay() -> [Date: Int] {
        guard let taskClass = engine.classes[.task] else { return [:] }
        let day = TesseraDay(calendar: calendar)
        var dones: [Date: Int] = [:]
        for task in store.objects(of: taskClass) where !task.isDeleted {
            guard store.value("isDone", of: task) == .bool(true),
                  let at = store.value("doneAt", of: task)?.dateValue else { continue }
            dones[day.day(of: at), default: 0] += 1
        }
        return dones
    }

    /// A plan with a start and a length has ended once its weeks are up.
    static func hasEnded(_ plan: ObjectRecord, store: ObjectStore, now: Date) -> Bool {
        guard let start = store.value("startsOn", of: plan)?.dateValue, let weeks = store.number("weeks", of: plan),
              weeks > 0 else { return false }
        return now >= start.addingTimeInterval(weeks * 7 * 86400)
    }

    static func kindWord(_ kind: TrainingLedger.RecordKind) -> String {
        switch kind {
        case .e1RM: "e1RM"
        case let .repMax(reps): "\(reps)RM"
        }
    }
}
