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
}

@MainActor
public extension TrainingLedger {
    /// The week containing `date`: done days show their workouts; today and later days show the plan's next
    /// routines in rolling order, one a day. Past days with nothing done are just past, never "missed".
    func week(containing date: Date, plan: ObjectRecord?, now: Date = .now,
              calendar: Calendar = .current) -> [WeekDay]
    {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: date) else { return [] }
        let cycle = plan.map { store.linkedObjects("routines", of: $0) } ?? []
        let next = plan.flatMap(nextRoutine(in:))
        var cursor = next.flatMap { routine in cycle.firstIndex { $0.id == routine.id } } ?? 0
        let today = calendar.startOfDay(for: now)
        var days: [WeekDay] = []
        var day = interval.start
        while day < interval.end {
            let done = finishedWorkouts(on: day, calendar: calendar)
            let state: WeekDay.State
            var planned: ObjectRecord?
            if !done.isEmpty {
                state = .done
            } else if day < today {
                state = .past
            } else {
                state = calendar.isDate(day, inSameDayAs: today) ? .today : .upcoming
                if !cycle.isEmpty {
                    planned = cycle[cursor % cycle.count]
                    cursor += 1
                }
            }
            days.append(WeekDay(day: day, state: state, done: done, planned: planned))
            guard let following = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = following
        }
        return days
    }
}
