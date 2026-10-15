import Foundation
import TesseraCore

// The plan's week and month, as plain values (docs/design/plans.md, docs/product/workouts.md §5).
// Plans roll on: a missed day never creates debt, the next routine simply comes next. Below range is neutral.

/// Which paint a routine wears: Push vermilion, Pull cobalt, Legs cadmium; others by their place in the cycle.
enum RoutinePaint: Int, CaseIterable {
    case vermilion, cobalt, cadmium, sage

    static func of(_ title: String, cycle: [String]) -> RoutinePaint {
        let words = title.lowercased()
        if words.contains("push") {
            return .vermilion
        }
        if words.contains("pull") {
            return .cobalt
        }
        if words.contains("leg") || words.contains("lower") {
            return .cadmium
        }
        if words.contains("upper") {
            return .sage
        }
        var distinct: [String] = []
        for name in cycle where !distinct.contains(name) {
            distinct.append(name)
        }
        let index = distinct.firstIndex(of: title) ?? 0
        return RoutinePaint(rawValue: index % allCases.count) ?? .vermilion
    }

    /// The word under a week dab: the routine's first word ("Push Day A" → "Push").
    static func short(_ title: String) -> String {
        title.split(separator: " ").first.map(String.init) ?? title
    }
}

/// One finished (or running) workout, reduced to what the week and month need.
struct TrainedSession: Hashable {
    let workoutID: UUID
    let date: Date
    let routine: String
    let volume: Double
}

// MARK: - Week

struct PlanWeek: Equatable {
    enum State: Equatable {
        case done
        /// Today's session, not finished yet: links into live mode.
        case today
        case planned
        case rest
        /// Nothing planned, nothing done (no plan, or a past day the plan rolled past). Neutral.
        case open
    }

    struct Day: Identifiable, Equatable {
        var id: Date {
            date
        }

        let date: Date
        let state: State
        let routine: String?
        let paint: RoutinePaint?
        let workoutID: UUID?
    }

    let days: [Day]
    let done: Int
    /// Sessions the plan expects this week; nil without a plan.
    let planned: Int?

    /// Core's week (`ledger.week(containing:plan:)`) in the page's terms: done days carry their workout, today and
    /// later days the plan's next routines in rolling order, past days with nothing done stay neutral (never
    /// "missed"). `todayWorkoutID` is a workout already set up for today, so tapping today resumes it.
    @MainActor
    static func from(_ days: [WeekDay], cycle: [String], perWeek: Int?, todayWorkoutID: UUID?,
                     routine: (WorkoutSummary) -> String) -> PlanWeek
    {
        let mapped = days.map { day -> Day in
            switch day.state {
            case .done:
                let latest = day.done.first
                let title = latest.map(routine)
                return Day(date: day.day, state: .done, routine: title,
                           paint: title.map { RoutinePaint.of($0, cycle: cycle) }, workoutID: latest?.workout.id)
            case .today, .upcoming:
                guard let planned = day.planned else {
                    return Day(date: day.day, state: .open, routine: nil, paint: nil, workoutID: nil)
                }
                let isToday = day.state == .today
                return Day(date: day.day, state: isToday ? .today : .planned, routine: planned.title,
                           paint: RoutinePaint.of(planned.title, cycle: cycle),
                           workoutID: isToday ? todayWorkoutID : nil)
            case .past:
                return Day(date: day.day, state: .open, routine: nil, paint: nil, workoutID: nil)
            }
        }
        return PlanWeek(days: mapped, done: days.count { $0.state == .done }, planned: perWeek)
    }

    /// "3 of 6\nsessions"; without a plan, "2 sessions\nso far".
    var headline: String {
        if let planned {
            return "\(done) of \(planned)\nsessions"
        }
        switch done {
        case 0: return "A fresh\nweek"
        case 1: return "1 session\nso far"
        default: return "\(done) sessions\nso far"
        }
    }
}

/// Sessions a plan expects each week: a short cycle (Push / Pull / Legs) runs twice, a long one once.
enum PlanRhythm {
    static func perWeek(cycleCount: Int) -> Int? {
        guard cycleCount > 0 else { return nil }
        return cycleCount <= 3 ? min(cycleCount * 2, 6) : min(cycleCount, 7)
    }

    /// The month's planned count: "of 26" for six a week across October.
    static func perMonth(perWeek: Int, days: Int) -> Int {
        Int((Double(perWeek) * Double(days) / 7).rounded(.down))
    }
}

// MARK: - Sets per muscle

struct MuscleSets: Identifiable, Equatable {
    let id: UUID
    let name: String
    /// Fractional: primary sets count 1, secondary ½.
    let sets: Double
    let range: ClosedRange<Double>
    /// The routine that trained it most this week.
    let paint: RoutinePaint?

    /// "6½", "12", "0"
    var count: String {
        let whole = Int(sets.rounded(.down))
        let half = sets - Double(whole) >= 0.5
        return half ? (whole == 0 ? "½" : "\(whole)½") : "\(whole)"
    }

    /// The scale every row shares, so fills compare: a little past the highest range or count.
    static func scale(_ rows: [MuscleSets]) -> Double {
        max(22, (rows.map(\.range.upperBound) + rows.map(\.sets)).max().map { $0 + 2 } ?? 22)
    }

    /// Trained muscles first (most sets), then the rest by name.
    static func sorted(_ rows: [MuscleSets]) -> [MuscleSets] {
        rows.sorted { $0.sets == $1.sets ? $0.name < $1.name : $0.sets > $1.sets }
    }
}

// MARK: - Month

struct PlanMonth: Equatable {
    struct Cell: Identifiable, Equatable {
        let id: Int
        /// nil for the blanks before the 1st.
        let day: Int?
        let date: Date?
        let isToday: Bool
        let isFuture: Bool
        /// 0…1: volume against a usual session (Core's `relative`, 1.5 = full). nil when nothing was trained.
        let weight: Double?
        let paint: RoutinePaint?
        let workoutID: UUID?

        /// The dab's size, 26 to 42 pt.
        var size: Double {
            26 + (weight ?? 0) * 16
        }

        /// Light for lighter days, strong for heavier ones.
        var opacity: Double {
            0.35 + (weight ?? 0) * 0.55
        }
    }

    let cells: [Cell]
    let done: Int

    /// One day of Core's month heatmap (`TrainingLedger.DayVolume`).
    struct Volume {
        let day: Date
        let sessions: Int
        let relative: Double
    }

    static func build(days: [Volume], sessions: [TrainedSession], cycle: [String], now: Date,
                      calendar: Calendar) -> PlanMonth
    {
        guard let first = days.first?.day else { return PlanMonth(cells: [], done: 0) }
        let leading = (calendar.component(.weekday, from: first) - calendar.firstWeekday + 7) % 7
        let today = calendar.startOfDay(for: now)
        let byDay = Dictionary(grouping: sessions) { calendar.startOfDay(for: $0.date) }
        var cells = (0 ..< leading).map {
            Cell(id: -1 - $0, day: nil, date: nil, isToday: false, isFuture: false, weight: nil, paint: nil,
                 workoutID: nil)
        }
        for (index, day) in days.enumerated() {
            let session = byDay[day.day]?.max { $0.volume < $1.volume }
            let trained = day.sessions > 0
            cells.append(Cell(
                id: index + 1, day: index + 1, date: day.day, isToday: day.day == today, isFuture: day.day > today,
                weight: trained ? min(max(day.relative / 1.5, 0.15), 1) : nil,
                paint: session.map { RoutinePaint.of($0.routine, cycle: cycle) } ?? (trained ? .vermilion : nil),
                workoutID: session?.workoutID
            ))
        }
        return PlanMonth(cells: cells, done: days.reduce(0) { $0 + $1.sessions })
    }

    /// "Session 11\nof 26" (today's pending session is the 11th); without a plan, "4 sessions\nthis month".
    static func headline(done: Int, pendingToday: Bool, planned: Int?) -> String {
        guard let planned else {
            return done == 1 ? "1 session\nthis month" : "\(done) sessions\nthis month"
        }
        let current = done + (pendingToday ? 1 : 0)
        return current == 0 ? "\(planned) sessions\nplanned" : "Session \(current)\nof \(planned)"
    }

    /// Tess's one forward-looking line. Never counts misses.
    static func tessLine(done: Int, lastMonth: Int, leftThisWeek: Int, month: String, previous: String) -> String? {
        guard lastMonth > 0 else { return nil }
        if done >= lastMonth {
            return "\(month) is already level with \(previous). Anything more is extra."
        }
        let needed = lastMonth - done
        let words = SpokenTime.number(needed)
        let count = words.prefix(1).uppercased() + words.dropFirst()
        return needed <= leftThisWeek
            ? "\(count) more this week keeps \(month) level with \(previous)."
            : "\(count) more keeps \(month) level with \(previous)."
    }
}
