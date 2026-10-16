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
    /// A day ahead the plan leaves for rest (only when the plan has fewer sessions a week than days left).
    public var isRest = false
}

@MainActor
public extension TrainingLedger {
    /// The week containing `date`: done days show their workouts; today and later days show the plan's next
    /// routines in rolling order. With a weekly count (`sessionsPerWeek`, else the plan's own), the sessions still
    /// due this week are spread over the days left, today first, and the days between are rest. Without one, every
    /// day ahead gets the next routine. Past days with nothing done are just past, never "missed".
    func week(containing date: Date, plan: ObjectRecord?, now: Date = .now, sessionsPerWeek: Int? = nil,
              calendar: Calendar = .current) -> [WeekDay]
    {
        // His days (04:00 to 04:00): at 01:00 Saturday it is still Friday, and Friday's late session counts there.
        let tesseraDay = TesseraDay(calendar: calendar)
        let dates = tesseraDay.weekDays(containing: date)
        guard !dates.isEmpty else { return [] }
        let cycle = plan.map { store.linkedObjects("routines", of: $0) } ?? []
        let next = plan.flatMap(nextRoutine(in:))
        var cursor = next.flatMap { routine in cycle.firstIndex { $0.id == routine.id } } ?? 0
        let today = tesseraDay.today(now)
        let done = dates.map { finishedWorkouts(on: $0, calendar: calendar) }
        let ahead = dates.indices.filter { done[$0].isEmpty && dates[$0] >= today }
        // Zero or less means no rhythm (QA E4): every day ahead gets the next routine, as without a count.
        let perWeek = (sessionsPerWeek ?? plan.flatMap { store.number("sessionsPerWeek", of: $0) }.map { Int($0) })
            .flatMap { $0 > 0 ? $0 : nil }
        // Spread the sessions still due evenly over the days ahead: 3 over 5 days trains every other day. Today comes
        // first, unless it trained yesterday and there's room for the rest: then today rests and the spread starts
        // tomorrow (so a rest day can be today).
        var training = Set(ahead)
        if let perWeek {
            let due = max(0, perWeek - done.count { !$0.isEmpty })
            let trainedYesterday = calendar.date(byAdding: .day, value: -1, to: today)
                .map { !finishedWorkouts(on: $0, calendar: calendar).isEmpty } ?? false
            let startsToday = ahead.first.map { calendar.isDate(dates[$0], inSameDayAs: today) } ?? false
            // A workout under way today makes today a training day, whatever the spread says (QA E6).
            let busyToday = hasWorkoutUnderway(on: now, calendar: calendar)
            let pool = trainedYesterday && startsToday && due < ahead.count ? Array(ahead.dropFirst()) : ahead
            if due < ahead.count {
                let left = pool.count
                let steps = due <= 1 ? Array(0 ..< min(due, left))
                    : (0 ..< due).map { Int((Double($0 * (left - 1)) / Double(due - 1)).rounded()) }
                training = Set(steps.map { pool[$0] })
                if busyToday, let first = ahead.first, calendar.isDate(dates[first], inSameDayAs: today) {
                    training.insert(first)
                }
            }
        }
        return dates.indices.map { index in
            let day = dates[index]
            if !done[index].isEmpty {
                return WeekDay(day: day, state: .done, done: done[index], planned: nil)
            }
            if day < today {
                return WeekDay(day: day, state: .past, done: [], planned: nil)
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
}
