import Foundation

/// Today, when the plan leaves it for rest (Product E2): Now shows a quiet "Rest day" line and keeps the next routine
/// one tap away, rather than offering today's routine as if it were due.
public struct RestDay {
    /// The next routine to do, from the plan's rolling order.
    public let next: ObjectRecord
    /// The day it falls on this week; nil when the week's sessions are done and it comes next week.
    public let nextDay: Date?

    /// "Rest day", the line Now shows.
    public static let line = "Rest day"
}

@MainActor
public extension TrainingLedger {
    /// Whether `now` is a rest day in `plan`: the week's rhythm (`sessionsPerWeek`, else the plan's own) leaves today
    /// free, nothing was trained today and no workout is under way. Nil on a training day, or for a plan without a
    /// rhythm (every day then offers the next routine).
    func restDay(plan: ObjectRecord?, now: Date = .now, sessionsPerWeek: Int? = nil,
                 calendar: Calendar = .current) -> RestDay?
    {
        guard let plan, !hasUnfinishedWorkout(on: now, calendar: calendar) else { return nil }
        let week = week(containing: now, plan: plan, now: now, sessionsPerWeek: sessionsPerWeek, calendar: calendar)
        guard let today = week.firstIndex(where: { $0.state == .today }), week[today].isRest else { return nil }
        if let ahead = week[(today + 1)...].first(where: { $0.planned != nil }), let routine = ahead.planned {
            return RestDay(next: routine, nextDay: ahead.day)
        }
        return nextRoutine(in: plan).map { RestDay(next: $0, nextDay: nil) }
    }

    /// A workout started or scheduled today that hasn't finished: today is in use, not a rest day.
    private func hasUnfinishedWorkout(on now: Date, calendar: Calendar) -> Bool {
        guard let workoutClass = classes[.workout] else { return false }
        return store.objects(of: workoutClass).contains { workout in
            guard store.value("endedAt", of: workout) == nil else { return false }
            let day = store.value("startedAt", of: workout)?.dateValue
                ?? store.value("scheduledFor", of: workout)?.dateValue
            return day.map { calendar.isDate($0, inSameDayAs: now) } ?? false
        }
    }
}

@MainActor
public extension NowPicker {
    /// Now's rest-day override: when today is a rest day in `plan`, the line and the next routine; else nil.
    func restDay(plan: ObjectRecord?, at now: Date = .now, sessionsPerWeek: Int? = nil,
                 calendar: Calendar = .current) -> RestDay?
    {
        TrainingLedger(store: engine.store, classes: engine.classes)
            .restDay(plan: plan, now: now, sessionsPerWeek: sessionsPerWeek, calendar: calendar)
    }
}
