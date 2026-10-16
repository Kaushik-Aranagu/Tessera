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
        // Before first use, nothing was planned. A first use after 17:00 leaves that day not due either, unless he
        // trained that evening: then the session counts and the day is due (Product 3113e2f, Research R5).
        let firstDay = firstUse.map { tesseraDay.day(of: $0) }
        let lateStart = firstUse.map { calendar.component(.hour, from: $0) >= 17 } ?? false
        let days = week.map { weekDay -> WeekFacts.Day in
            let before = firstDay.map { weekDay.day < $0 || (weekDay.day == $0 && lateStart && weekDay.done.isEmpty) }
                ?? true
            for summary in weekDay.done {
                routinesDone.append(summary.title)
                // One best per exercise (Research R1): a 5RM and an e1RM on the same set are one best.
                for record in summary.records {
                    let short = ExerciseWords.short(record.exercise)
                    if !records.contains(where: { $0.exercise == short }) {
                        records.append(WeekFacts.Record(exercise: short, kind: Self.kindWord(record.kind)))
                    }
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
        let planLive = plan.map { !Self.hasEnded($0, store: store, now: now, calendar: calendar) } ?? false
        let nextRoutine = planLive ? plan.flatMap { ledger.nextRoutine(in: $0, now: now, calendar: calendar) } : nil
        // Its day is looked for over the next seven days, not just this week: on Sunday night the line can still say
        // "first up Monday" (Research R2).
        var nextDay = week.first { $0.state != .past && $0.done.isEmpty && $0.planned?.id == nextRoutine?.id }?.day
        if nextDay == nil, let plan, let nextRoutine {
            let ahead = ledger.week(containing: tesseraDay.day(7, after: now), plan: plan, now: now,
                                    calendar: calendar)
            nextDay = ahead.first { $0.done.isEmpty && $0.planned?.id == nextRoutine.id }?.day
        }
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

    /// The same for a day key as `WeekFacts.Day.date` carries it: a midnight key, which read as a moment would fall in
    /// the day before under the 04:00 rule, so it is read at noon.
    public func lines(onDay key: Date, now: Date = .now, isRestDay: Bool = false) -> [DayLine] {
        lines(on: Self.noon(of: key, calendar: calendar), now: now, isRestDay: isRestDay)
    }

    static func noon(of key: Date, calendar: Calendar) -> Date {
        calendar.date(bySettingHour: 12, minute: 0, second: 0, of: key) ?? key.addingTimeInterval(12 * 3600)
    }

    /// The three lines worth telling, over the week's days up to today: a record first, then a first time (a routine,
    /// list or recipe made this week), then a finished workout, then the rest; each at most once a day. Ranked on the
    /// objects behind each line, never on its wording (QA L1 on #348).
    func bestLines(for days: [Date], now: Date) -> [WeekFacts.Line] {
        let today = TesseraDay(calendar: calendar).today(now)
        let weekStart = days.first ?? today
        var ranked: [(rank: Int, line: WeekFacts.Line)] = []
        for day in days where day <= today {
            for line in lines(onDay: day, now: now) where line.kind == .finished {
                ranked.append((rank(of: line, weekStart: weekStart), WeekFacts.Line(day: day, line: line)))
            }
        }
        var seenDays = Set<Date>()
        return ranked.sorted { ($0.rank, $0.line.day) < ($1.rank, $1.line.day) }
            .filter { seenDays.insert($0.line.day).inserted }
            .prefix(3).map(\.line)
    }

    func rank(of line: DayLine, weekStart: Date) -> Int {
        guard let id = line.objectIDs.first, let object = store.object(id: id), let classDef = object.classDef else {
            return 3
        }
        func isA(_ key: SystemCatalog.Key) -> Bool {
            engine.classes[key].map { store.isSubclass(classDef, ofClassID: $0.id) } ?? false
        }
        if isA(.workout) {
            // A record: a set flagged when it was logged (#344).
            let hasRecord = object.orderedChildren.contains { entry in
                entry.orderedChildren.contains { store.value("wasRecord", of: $0) == .bool(true) }
            }
            return hasRecord ? 0 : 2
        }
        if isA(.routine) || isA(.list) || isA(.recipe) || isA(.plan) {
            return object.createdAt >= weekStart ? 1 : 3
        }
        return 3
    }

    /// The first thing he did: the oldest op that isn't the system's. Nil in an empty store. One scan per store
    /// revision, cached (QA L2 on #348).
    func firstUse() -> Date? {
        let key = ObjectIdentifier(store.context)
        if let cached = Self.firstUseCache[key], cached.revision == store.revision {
            return cached.date
        }
        let date = store.context.operations.values.lazy.filter { $0.actor != .system }.map(\.createdAt).min()
        Self.firstUseCache[key] = (store.revision, date)
        return date
    }

    nonisolated(unsafe) static var firstUseCache: [ObjectIdentifier: (revision: Int, date: Date?)] = [:]

    func cooksByDay() -> [Date: [String]] {
        guard let cookClass = engine.classes[.cook] else { return [:] }
        let zones = OpZones(store: store)
        var cooks: [Date: [String]] = [:]
        for cook in store.objects(of: cookClass) where !cook.isDeleted {
            guard let at = store.value("cookedAt", of: cook)?.dateValue else { continue }
            cooks[zones.dayKey(of: at, for: cook.id, calendar: calendar), default: []]
                .append(store.displayTitle(of: cook))
        }
        return cooks
    }

    func tasksDoneByDay() -> [Date: Int] {
        guard let taskClass = engine.classes[.task] else { return [:] }
        let zones = OpZones(store: store)
        var dones: [Date: Int] = [:]
        for task in store.objects(of: taskClass) where !task.isDeleted {
            guard store.value("isDone", of: task) == .bool(true),
                  let at = store.value("doneAt", of: task)?.dateValue else { continue }
            dones[zones.dayKey(of: at, for: task.id, calendar: calendar), default: 0] += 1
        }
        return dones
    }

    /// A plan with a start and a length has ended once its weeks are up (counted in calendar days, so a DST change
    /// moves nothing; QA L5 on #348).
    static func hasEnded(_ plan: ObjectRecord, store: ObjectStore, now: Date, calendar: Calendar) -> Bool {
        guard let start = store.value("startsOn", of: plan)?.dateValue, let weeks = store.number("weeks", of: plan),
              weeks > 0, let end = calendar.date(byAdding: .day, value: Int(weeks) * 7, to: start) else { return false }
        return now >= end
    }

    static func kindWord(_ kind: TrainingLedger.RecordKind) -> String {
        switch kind {
        case .e1RM: "e1RM"
        case let .repMax(reps): "\(reps)RM"
        }
    }
}
