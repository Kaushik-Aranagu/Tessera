import Foundation

/// One day in the week view: what was done, or which routine comes next if it's still ahead.
public struct WeekDay: Identifiable {
    public enum State: String, Sendable {
        case done, today, upcoming, past
    }

    public var id: Date {
        day
    }

    public let day: Date
    public let state: State
    /// Workouts finished that day.
    public let done: [WorkoutSummary]
    /// The routine projected for this day (today if nothing is done yet, and each day after), in rolling order.
    public let planned: ObjectRecord?
    /// A day the plan leaves for rest: ahead, when the plan has fewer sessions a week than days left; past, when the
    /// plan as it stood that morning would have rested it.
    public var isRest = false
    /// A past day with nothing done that the plan, as it stood that morning, would have trained. Review draws its ring
    /// only for these, never for a planned rest day. Never a "miss" in words.
    public var wasDue = false
}

@MainActor
public extension TrainingLedger {
    /// The week containing `date`: done days show their workouts; today and later days show the plan's next
    /// routines in rolling order. With a weekly count (`sessionsPerWeek`, else the plan's own), the sessions still
    /// due this week are spread over the days left, today first, and the days between are rest. Without one, every
    /// day ahead gets the next routine. Past days with nothing done carry `isRest` or `wasDue` (never "missed" in
    /// words).
    func week(containing date: Date, plan: ObjectRecord?, now: Date = .now, sessionsPerWeek: Int? = nil,
              calendar: Calendar = .current) -> [WeekDay]
    {
        // His days (04:00 to 04:00): at 01:00 Saturday it is still Friday, and Friday's late session counts there.
        let tesseraDay = TesseraDay(calendar: calendar)
        let dates = tesseraDay.weekDays(containing: date)
        guard !dates.isEmpty else { return [] }
        let cycle = plan.map { store.linkedObjects("routines", of: $0) } ?? []
        if let plan, PlanSchedule.mode(of: plan, store: store) == .fixed,
           PlanSchedule.hasFixedDays(plan, store: store)
        {
            return fixedWeek(dates: dates, plan: plan, now: now, calendar: calendar)
        }
        let next = plan.flatMap { nextRoutine(in: $0, now: now, calendar: calendar) }
        var cursor = next.flatMap { routine in cycle.firstIndex { $0.id == routine.id } } ?? 0
        let today = tesseraDay.today(now)
        let done = dates.map { finishedWorkouts(onDay: $0, calendar: calendar) }
        let ahead = dates.indices.filter { done[$0].isEmpty && dates[$0] >= today }
        // Zero or less means no rhythm (QA E4): every day ahead gets the next routine, as without a count.
        let perWeek = (sessionsPerWeek ?? plan.flatMap { store.number("sessionsPerWeek", of: $0) }.map { Int($0) })
            .flatMap { $0 > 0 ? $0 : nil }
        var training = Set(ahead)
        if let perWeek {
            let trainedYesterday = calendar.date(byAdding: .day, value: -1, to: today)
                .map { !finishedWorkouts(onDay: $0, calendar: calendar).isEmpty } ?? false
            let startsToday = ahead.first.map { calendar.isDate(dates[$0], inSameDayAs: today) } ?? false
            training = Self.spread(ahead, due: max(0, perWeek - done.count { !$0.isEmpty }),
                                   trainedYesterday: trainedYesterday && startsToday)
            // A workout under way today makes today a training day, whatever the spread says (QA E6).
            if hasWorkoutUnderway(on: now, calendar: calendar), let first = ahead.first,
               calendar.isDate(dates[first], inSameDayAs: today)
            {
                training.insert(first)
            }
        }
        // Past empty days: what the plan would have said that morning (the seeded plan's rhythm when none is set:
        // a short cycle runs twice a week, a long one once).
        // An explicit 0 means no rhythm here too.
        let pastRhythm = sessionsPerWeek != nil ? perWeek : perWeek ?? (cycle.isEmpty ? nil
            : cycle.count <= 3 ? min(cycle.count * 2, 6) : min(cycle.count, 7))
        func wasDue(_ index: Int) -> Bool {
            guard let pastRhythm else { return false }
            let before = done[..<index].count { !$0.isEmpty }
            let yesterday = index > 0 ? !done[index - 1].isEmpty
                : calendar.date(byAdding: .day, value: -1, to: dates[0])
                .map { !finishedWorkouts(onDay: $0, calendar: calendar).isEmpty } ?? false
            let thatWeek = Array(index ..< dates.count)
            return Self.spread(thatWeek, due: max(0, pastRhythm - before), trainedYesterday: yesterday)
                .contains(index)
        }
        return dates.indices.map { index in
            let day = dates[index]
            if !done[index].isEmpty {
                return WeekDay(day: day, state: .done, done: done[index], planned: nil)
            }
            if day < today {
                let due = wasDue(index)
                return WeekDay(day: day, state: .past, done: [], planned: nil, isRest: pastRhythm != nil && !due,
                               wasDue: due)
            }
            let state: WeekDay.State = calendar.isDate(day, inSameDayAs: today) ? .today : .upcoming
            guard training.contains(index) else {
                return WeekDay(day: day, state: state, done: [], planned: nil, isRest: !cycle.isEmpty)
            }
            var planned: ObjectRecord?
            if !cycle.isEmpty {
                planned = cycle[cursor % cycle.count]
                cursor += 1
            }
            return WeekDay(day: day, state: state, done: [], planned: planned)
        }
    }

    /// A fixed-days plan's week: each day shows its pinned routine; a day with none is rest; a past fixed day with
    /// nothing done was due and does not roll on (Product 1fdd1c6).
    private func fixedWeek(dates: [Date], plan: ObjectRecord, now: Date, calendar: Calendar) -> [WeekDay] {
        let tesseraDay = TesseraDay(calendar: calendar)
        let today = tesseraDay.today(now)
        return dates.map { day in
            let done = finishedWorkouts(onDay: day, calendar: calendar)
            if !done.isEmpty {
                return WeekDay(day: day, state: .done, done: done, planned: nil)
            }
            let pinned = PlanSchedule.routine(on: day, in: plan, store: store, calendar: calendar)
            if day < today {
                return WeekDay(day: day, state: .past, done: [], planned: nil, isRest: pinned == nil,
                               wasDue: pinned != nil)
            }
            let state: WeekDay.State = calendar.isDate(day, inSameDayAs: today) ? .today : .upcoming
            return WeekDay(day: day, state: state, done: [], planned: pinned, isRest: pinned == nil)
        }
    }

    /// The days that train: `due` sessions spread evenly over `days` (3 over 5 trains every other day), the first
    /// day first, unless it trained the day before and there's room: then the first day rests and the spread starts
    /// the day after (so a rest day can be today).
    static func spread(_ days: [Int], due: Int, trainedYesterday: Bool) -> Set<Int> {
        guard due < days.count else { return Set(days) }
        let pool = trainedYesterday ? Array(days.dropFirst()) : days
        let left = pool.count
        guard left > 0 else { return [] }
        let steps = due <= 1 ? Array(0 ..< min(due, left))
            : (0 ..< due).map { Int((Double($0 * (left - 1)) / Double(due - 1)).rounded()) }
        return Set(steps.map { pool[$0] })
    }
}
