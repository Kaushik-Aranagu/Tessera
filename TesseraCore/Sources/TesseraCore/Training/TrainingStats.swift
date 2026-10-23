import Foundation

/// Training Stats (Product build sheet, Oct 22): one page of facts computed on the phone from the ledger. Engine only:
/// pure reads, no writes, nothing stored. A private workout is excluded everywhere through `isCounted` (the Log shows
/// it as an outline row only). No number leads, there is no streak, no "lost", "broke" or "down", and a lower lift
/// reads "holding near its best". Calorie numbers never leave this file for Claude, a log, a backup, the op log, an
/// export or a widget.
public enum StatsMass {
    public static let poundsPerKilo = 2.20462

    /// A lift in the display unit: kg or lb, rounded for reading (kg to 0.5, lb to 5). Convert at output only.
    public static func text(kg: Double, unit: MassUnit) -> String {
        switch unit {
        case .kilograms: "\(trimmed((kg * 2).rounded() / 2)) kg"
        case .pounds: "\(trimmed((kg * poundsPerKilo / 5).rounded() * 5)) lb"
        }
    }

    /// The number alone, as a set weight reads inside a sentence ("82.5", "185"): kg to 0.5, lb to 5.
    public static func number(kg: Double, unit: MassUnit) -> String {
        switch unit {
        case .kilograms: trimmed((kg * 2).rounded() / 2)
        case .pounds: trimmed((kg * poundsPerKilo / 5).rounded() * 5)
        }
    }

    /// An estimate ("about 93 kg"): kg to the whole, lb to 5.
    public static func estimate(kg: Double, unit: MassUnit) -> String {
        switch unit {
        case .kilograms: "\(Int(kg.rounded())) kg"
        case .pounds: "\(Int((kg * poundsPerKilo / 5).rounded() * 5)) lb"
        }
    }

    /// The step a change is counted in: 2.5 kg or 5 lb.
    public static func step(_ unit: MassUnit) -> Double {
        unit == .kilograms ? 2.5 : 5
    }

    public static func inDisplay(_ kg: Double, _ unit: MassUnit) -> Double {
        unit == .kilograms ? kg : kg * poundsPerKilo
    }

    static func trimmed(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%g", value)
    }
}

@MainActor
public struct TrainingStats {
    public enum Range: Sendable {
        case threeMonths, year

        /// 91 days ending today, or 52 weeks.
        var days: Int {
            self == .threeMonths ? 91 : 364
        }

        var word: String {
            self == .threeMonths ? "3 months" : "the year"
        }
    }

    public struct Best: Equatable, Sendable {
        public let exercise: String
        /// The estimated one-rep max in kilograms.
        public let e1RM: Double
        public let date: Date
    }

    public struct StrengthLine: Equatable, Sendable {
        public enum Change: Equatable, Sendable {
            /// Up by this many display steps (2.5 kg, 5 lb).
            case up(steps: Int)
            case steady
            case holding
            /// One session so far: the first number.
            case first
            /// Not enough on either end of the range to say.
            case none
        }

        public let exercise: String
        public let sessions: Int
        /// Best e1RM per week with a session, oldest first, in kilograms.
        public let points: [Double]
        public let bestRing: Double
        public let change: Change
        public let nowKg: Double?
    }

    public struct MuscleRow: Equatable, Sendable {
        public enum Band: Equatable, Sendable { case below, within, above }
        public let name: String
        public let sets: Double
        public let band: Band
    }

    public struct VolumeWeek: Equatable, Sendable {
        public let start: Date
        public let perMuscle: [String: Double]
        public var total: Double {
            perMuscle.values.reduce(0, +)
        }
    }

    public struct Volume: Equatable, Sendable {
        public static let minTarget = 10.0
        public static let maxTarget = 20.0
        public let weeks: [VolumeWeek]
        /// The current week: the top six by sets, plus any under target with at least one set.
        public let rows: [MuscleRow]
        public let totalSets: Double
    }

    public struct HabitWeek: Equatable, Sendable {
        public let start: Date
        public let sessions: Int
        /// Sessions on each day of the week, Monday first.
        public let days: [Int]
        public let sets: Int
        public let isLight: Bool
        /// A week with nothing: drawn as a hairline, never as a miss.
        public var isEmpty: Bool {
            sessions == 0
        }
    }

    public struct Habit: Equatable, Sendable {
        public let weeks: [HabitWeek]
        public let usual: Int
        /// Weeks in a row, only for a finished run of 3 or more.
        public let bestRun: Int?
        public var current: HabitWeek? {
            weeks.last
        }
    }

    public struct Balance: Equatable, Sendable {
        public let push: Double
        public let pull: Double
        public let lower: Double
        public var isPushPullEven: Bool {
            pull > 0 && (0.8 ... 1.25).contains(push / pull)
        }

        public var upperShare: Double {
            (push + pull) / max(push + pull + lower, 0.0001)
        }

        public var isUpperLowerEven: Bool {
            (0.4 ... 0.6).contains(upperShare)
        }
    }

    public struct LogRow: Equatable, Sendable {
        /// The workout's id, so a tap opens it without matching a title and a date. An id carries no name.
        public let workout: UUID
        public let date: Date
        public let title: String
        public let setsText: String?
        public let duration: String?
        public let calories: String?
        public let isPrivate: Bool
    }

    public struct LogMonth: Equatable, Sendable {
        public let month: Date
        public let rows: [LogRow]
    }

    public static let pushMuscles: Set<String> = ["Chest", "Front Delts", "Side Delts", "Triceps"]
    public static let pullMuscles: Set<String> = ["Lats", "Upper Back", "Rear Delts", "Biceps", "Forearms"]
    public static let lowerMuscles: Set<String> = ["Quads", "Hamstrings", "Glutes", "Adductors", "Abductors", "Calves"]

    public let ledger: TrainingLedger

    var store: ObjectStore {
        ledger.store
    }

    var classes: [SystemCatalog.Key: ClassDef] {
        ledger.classes
    }

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) {
        ledger = TrainingLedger(store: store, classes: classes)
    }

    // MARK: Counting

    /// Whether a workout is private: its flag, its own title or the routine it came from (the rule of
    /// `ObjectPrivacy.label`, with the body weight read once for the whole call, not once per session).
    func privateWorkouts() -> (isPrivate: (ObjectRecord) -> Bool, reset: () -> Void) {
        let last = BodyWeight.lastKg(in: store)
        var memo: [UUID: Bool] = [:]
        // The title rule is a set of patterns; a few titles repeat across hundreds of workouts, so ask once per title.
        var titles: [String: Bool] = [:]
        func isPrivateTitle(_ title: String) -> Bool {
            if let known = titles[title] {
                return known
            }
            let result = title == ObjectPrivacy.routineLabel || PrivateWords.isPrivateTitle(title, lastWeightKg: last)
            titles[title] = result
            return result
        }
        let check: (ObjectRecord) -> Bool = { workout in
            if let known = memo[workout.id] {
                return known
            }
            let routine = store.linkedObjects("routine", of: workout).first
            let flagged = store.value("isPrivate", of: workout) == .bool(true)
            let result = flagged || isPrivateTitle(workout.title) || (routine.map { isPrivateTitle($0.title) } ?? false)
            memo[workout.id] = result
            return result
        }
        return (check, { memo = [:] })
    }

    /// Counted = not a private workout: the one filter every stat goes through except the Log.
    public func isCounted(_ session: TrainingLedger.Session) -> Bool {
        !privateWorkouts().isPrivate(session.workout)
    }

    func counted() -> [(exercise: ClassDef, session: TrainingLedger.Session)] {
        let isPrivate = privateWorkouts().isPrivate
        return ledger.index.allSessions.compactMap { entry in
            guard !isPrivate(entry.session.workout),
                  let exercise = store.classDef(id: entry.classID) else { return nil }
            return (exercise, entry.session)
        }
    }

    func rangeStart(_ range: Range, now: Date, calendar: Calendar) -> Date {
        let day = TesseraDay(calendar: calendar)
        if range == .year {
            let week = day.week(containing: now).start
            return calendar.date(byAdding: .weekOfYear, value: -51, to: week) ?? week
        }
        return day.start(of: day.day(-(range.days - 1), after: now))
    }

    /// The weeks a range covers, oldest first, ending with the week of `now`.
    func weeks(_ range: Range, now: Date, calendar: Calendar) -> [DateInterval] {
        let day = TesseraDay(calendar: calendar)
        var result: [DateInterval] = []
        var cursor = day.week(containing: rangeStart(range, now: now, calendar: calendar))
        let last = day.week(containing: now)
        while cursor.start <= last.start {
            result.append(cursor)
            guard let next = calendar.date(byAdding: .weekOfYear, value: 1, to: cursor.start) else { break }
            cursor = day.week(containing: next.addingTimeInterval(3600 * 12))
        }
        return result
    }

    // MARK: Best

    /// The newest session in the range whose best e1RM beat every earlier counted one for that exercise.
    public func bestInRange(_ range: Range, now: Date, calendar: Calendar = .current) -> Best? {
        let start = rangeStart(range, now: now, calendar: calendar)
        var newest: Best?
        for (exercise, sessions) in Dictionary(grouping: counted(), by: { $0.exercise.id }).values.map({ (
            $0[0].exercise,
            $0.map(\.session)
        ) }) {
            var top = 0.0
            for session in sessions.sorted(by: { $0.date < $1.date }) {
                let best = session.sets.filter(\.isE1RMEligible).map(\.e1RM).max() ?? 0
                guard best > top + 0.05 else { continue }
                top = best
                if session.date >= start, session.date <= now, newest.map({ session.date > $0.date }) ?? true {
                    newest = Best(exercise: exercise.name, e1RM: best, date: session.date)
                }
            }
        }
        return newest
    }

    // MARK: Strength

    /// Lifts with an estimated max and at least 3 counted sessions in the range (top 6 by sessions), then lifts with
    /// exactly one session as "first number" lines.
    public func strengthLines(_ range: Range, now: Date, unit: MassUnit = .kilograms, calendar: Calendar = .current)
        -> [StrengthLine]
    {
        let day = TesseraDay(calendar: calendar)
        let start = rangeStart(range, now: now, calendar: calendar)
        let weeks = weeks(range, now: now, calendar: calendar)
        let recentStart = now.addingTimeInterval(-28 * 86400)
        var lines: [StrengthLine] = []
        var firsts: [StrengthLine] = []
        let grouped = Dictionary(grouping: counted(), by: { $0.exercise.id })
        for group in grouped.values {
            let exercise = group[0].exercise
            let all = group.map(\.session).sorted { $0.date < $1.date }
            let inRange = all.filter { $0.date >= start && $0.date <= now }
            func best(_ session: TrainingLedger.Session) -> Double? {
                session.sets.filter(\.isE1RMEligible).map(\.e1RM).max()
            }
            let eligible = inRange.filter { best($0) != nil }
            guard !eligible.isEmpty else { continue }
            let points = weeks.compactMap { week in
                eligible.filter { week.contains($0.date) }.compactMap(best).max()
            }
            let ring = points.max() ?? 0
            if eligible.count == 1 {
                firsts.append(StrengthLine(exercise: exercise.name, sessions: 1, points: points, bestRing: ring,
                                           change: .first, nowKg: ring))
                continue
            }
            guard eligible.count >= 3 else { continue }
            let nowKg = eligible.filter { $0.date >= recentStart }.compactMap(best).max()
            // The "then" window: the first 28 days of the range, or of the lift when it began later.
            let first = all.first.map { max($0.date, start) } ?? start
            let thenEnd = first.addingTimeInterval(28 * 86400)
            let thenKg = eligible.filter { $0.date >= first && $0.date < thenEnd }.compactMap(best).max()
            var change = StrengthLine.Change.none
            if let nowKg, let thenKg, thenEnd <= recentStart {
                let stepSize = StatsMass.step(unit)
                let steps = Int(((StatsMass.inDisplay(nowKg, unit) - StatsMass.inDisplay(thenKg, unit)) / stepSize)
                    .rounded(.toNearestOrAwayFromZero))
                change = steps > 0 ? .up(steps: steps) : (steps == 0 ? .steady : .holding)
            }
            lines.append(StrengthLine(exercise: exercise.name, sessions: eligible.count, points: points,
                                      bestRing: ring, change: change, nowKg: nowKg))
        }
        _ = day
        let top = lines.sorted { $0.sessions != $1.sessions ? $0.sessions > $1.sessions : $0.exercise < $1.exercise }
        let single = firsts.sorted { $0.exercise < $1.exercise }
        return Array((top.prefix(6) + single).prefix(6))
    }

    // MARK: Volume

    /// Fractional sets per muscle per week (primary 1, secondary 0.5), counted workouts only.
    public func volume(_ range: Range, now: Date, calendar: Calendar = .current) -> Volume {
        let weeks = weeks(range, now: now, calendar: calendar)
        var credit: [UUID: [(String, Double)]] = [:]
        func muscles(_ exercise: ClassDef) -> [(String, Double)] {
            if let cached = credit[exercise.id] {
                return cached
            }
            let result = store.linkedObjects("primaryMuscles", ofClass: exercise).map { ($0.title, 1.0) }
                + store.linkedObjects("secondaryMuscles", ofClass: exercise).map { ($0.title, 0.5) }
            credit[exercise.id] = result
            return result
        }
        var perWeek = [Date: [String: Double]](uniqueKeysWithValues: weeks.map { ($0.start, [:]) })
        for (exercise, session) in counted() {
            guard let week = weeks.first(where: { $0.contains(session.date) }) else { continue }
            for (name, factor) in muscles(exercise) {
                perWeek[week.start, default: [:]][name, default: 0] += Double(session.sets.count) * factor
            }
        }
        let volumeWeeks = weeks.map { VolumeWeek(start: $0.start, perMuscle: perWeek[$0.start] ?? [:]) }
        let current = volumeWeeks.last?.perMuscle ?? [:]
        func band(_ sets: Double) -> MuscleRow.Band {
            sets < Volume.minTarget ? .below : (sets > Volume.maxTarget ? .above : .within)
        }
        let all = current.map { MuscleRow(name: $0.key, sets: $0.value, band: band($0.value)) }
            .sorted { $0.sets != $1.sets ? $0.sets > $1.sets : $0.name < $1.name }
        var rows = Array(all.prefix(6))
        for row in all.dropFirst(6) where row.band == .below && row.sets >= 1 {
            rows.append(row)
        }
        return Volume(weeks: volumeWeeks, rows: rows, totalSets: current.values.reduce(0, +))
    }

    // MARK: Habit

    /// Sessions per week and day, the usual, the best finished run and (behind its switch) light weeks.
    public func habit(_ range: Range, now: Date, lightWeeks: Bool = false, calendar: Calendar = .current) -> Habit {
        let day = TesseraDay(calendar: calendar)
        let weeks = weeks(range, now: now, calendar: calendar)
        // The 4 weeks before the range also feed the light-week median.
        let lead = (1 ... 4).compactMap { calendar.date(byAdding: .weekOfYear, value: -$0, to: weeks[0].start) }
            .map { day.week(containing: $0.addingTimeInterval(3600 * 12)) }
        let allWeeks = lead.reversed() + weeks
        var workouts: [UUID: Date] = [:]
        var setsByWeek: [Date: Int] = [:]
        for (_, session) in counted() {
            workouts[session.workoutID] = session.date
            if let week = allWeeks.first(where: { $0.contains(session.date) }) {
                setsByWeek[week.start, default: 0] += session.sets.count
            }
        }
        var daysByWeek: [Date: [Int]] = [:]
        for date in workouts.values {
            guard let week = allWeeks.first(where: { $0.contains(date) }) else { continue }
            var counts = daysByWeek[week.start] ?? Array(repeating: 0, count: 7)
            let offset = calendar.dateComponents([.day], from: week.start, to: day.start(of: date)).day ?? 0
            counts[min(max(offset, 0), 6)] += 1
            daysByWeek[week.start] = counts
        }
        func sessions(_ week: DateInterval) -> Int {
            (daysByWeek[week.start] ?? []).reduce(0, +)
        }
        let firstTrained = allWeeks.first { sessions($0) > 0 }?.start
        func isLight(_ week: DateInterval, index: Int) -> Bool {
            guard lightWeeks, index >= 4, let firstTrained,
                  allWeeks[index - 4].start >= firstTrained else { return false }
            let previous = (1 ... 4).map { setsByWeek[allWeeks[index - $0].start] ?? 0 }.sorted()
            let median = Double(previous[1] + previous[2]) / 2
            let sets = setsByWeek[week.start] ?? 0
            return sets > 0 && median > 0 && Double(sets) <= 0.6 * median
        }
        let built = weeks.enumerated().map { offset, week -> HabitWeek in
            HabitWeek(
                start: week.start,
                sessions: sessions(week),
                days: daysByWeek[week.start] ?? Array(repeating: 0, count: 7),
                sets: setsByWeek[week.start] ?? 0,
                isLight: isLight(week, index: offset + lead.count)
            )
        }
        // From the first week he trained: the empty weeks before he began say nothing about his usual.
        let began = built.firstIndex { $0.sessions > 0 } ?? built.count
        let ordinary = built[began...].filter { !$0.isLight }.map(\.sessions).sorted()
        let usual = ordinary.isEmpty ? 0 : ordinary.count.isMultiple(of: 2)
            ? (ordinary[ordinary.count / 2 - 1] + ordinary[ordinary.count / 2] + 1) / 2 : ordinary[ordinary.count / 2]
        // Finished runs only: weeks in a row with a session that an empty, already finished week ended. The run still
        // going (through the latest week, or ended by the week now under way) is never told.
        var best = 0
        var run = 0
        for (index, week) in built.enumerated() {
            guard week.sessions > 0 else {
                run = 0
                continue
            }
            run += 1
            let nextIsEmptyAndPast = index + 2 < built.count && built[index + 1].sessions == 0
            if nextIsEmptyAndPast {
                best = max(best, run)
            }
        }
        return Habit(weeks: built, usual: usual, bestRun: best >= 3 ? best : nil)
    }

    // MARK: Balance

    /// Average weekly sets of push, pull and lower over the range's weeks (counted workouts only).
    public func balance(_ range: Range, now: Date, calendar: Calendar = .current) -> Balance? {
        let volume = volume(range, now: now, calendar: calendar)
        let active = volume.weeks.filter { $0.total > 0 }
        guard !active.isEmpty else { return nil }
        func average(_ names: Set<String>) -> Double {
            active
                .reduce(0) { sum, week in sum + names.reduce(0) { $0 + (week.perMuscle[$1] ?? 0) } } /
                Double(active.count)
        }
        let result = Balance(push: average(Self.pushMuscles), pull: average(Self.pullMuscles),
                             lower: average(Self.lowerMuscles))
        return result.push + result.pull + result.lower > 0 ? result : nil
    }

    // MARK: Log

    /// Every workout with sets, newest first, grouped by month. A private one is an outline row: date and
    /// "Private workout" only. Calories only when the switch is on and a weight is known.
    public func logMonths(now: Date, calories: CaloriesOptions = CaloriesOptions(on: false),
                          calendar: Calendar = .current) -> [LogMonth]
    {
        let isPrivate = privateWorkouts().isPrivate
        var byWorkout: [UUID: (workout: ObjectRecord, date: Date, sets: Int, first: Date?, last: Date?)] = [:]
        for (_, session) in ledger.index.allSessions {
            var entry = byWorkout[session.workoutID] ?? (session.workout, session.date, 0, nil, nil)
            entry.sets += session.sets.count
            for set in session.entry.orderedChildren {
                if let at = store.value("loggedAt", of: set)?.dateValue {
                    entry.first = min(entry.first ?? at, at)
                    entry.last = max(entry.last ?? at, at)
                }
            }
            byWorkout[session.workoutID] = entry
        }
        let rows = byWorkout.values.filter { $0.date <= now }.sorted { $0.date > $1.date }.map { entry -> LogRow in
            if isPrivate(entry.workout) {
                return LogRow(
                    workout: entry.workout.id,
                    date: entry.date,
                    title: ObjectPrivacy.routineLabel,
                    setsText: nil,
                    duration: nil,
                    calories: nil,
                    isPrivate: true
                )
            }
            let minutes = entry.first.flatMap { first in entry.last.map { Int($0.timeIntervalSince(first) / 60) } }
            return LogRow(
                workout: entry.workout.id, date: entry.date, title: entry.workout.title,
                setsText: "\(entry.sets) \(entry.sets == 1 ? "set" : "sets")",
                duration: minutes.map { HouseTime.minutes($0) },
                calories: CaloriesBurned.line(
                    forWorkout: entry.workout,
                    store: store,
                    classes: classes,
                    options: calories
                ),
                isPrivate: false
            )
        }
        var months: [LogMonth] = []
        for row in rows {
            let month = TesseraDay(calendar: calendar).month(containing: row.date).start
            if let last = months.last, last.month == month {
                months[months.count - 1] = LogMonth(month: month, rows: last.rows + [row])
            } else {
                months.append(LogMonth(month: month, rows: [row]))
            }
        }
        return months
    }
}
