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
    /// free, nothing was trained today and no workout has been started. Nil on a training day, or for a plan without a
    /// rhythm (every day then offers the next routine).
    func restDay(plan: ObjectRecord?, now: Date = .now, sessionsPerWeek: Int? = nil,
                 calendar: Calendar = .current) -> RestDay?
    {
        guard let plan, !hasWorkoutUnderway(on: now, calendar: calendar) else { return nil }
        let week = week(containing: now, plan: plan, now: now, sessionsPerWeek: sessionsPerWeek, calendar: calendar)
        guard let today = week.firstIndex(where: { $0.state == .today }), week[today].isRest else { return nil }
        if let ahead = week[(today + 1)...].first(where: { $0.planned != nil }), let routine = ahead.planned {
            return RestDay(next: routine, nextDay: ahead.day)
        }
        return nextRoutine(in: plan).map { RestDay(next: $0, nextDay: nil) }
    }
}

@MainActor
extension TrainingLedger {
    /// A workout started today and not finished: today is in use, not a rest day. One that is only scheduled (a gym
    /// nudge on a rest day) doesn't count. Only workouts made in the last two weeks are looked at, so this stays cheap
    /// with years of history (QA E7).
    func hasWorkoutUnderway(on now: Date, calendar: Calendar) -> Bool {
        guard let workoutClass = classes[.workout] else { return false }
        let recent = now.addingTimeInterval(-14 * 86400)
        return store.objects(of: workoutClass).contains { workout in
            guard workout.createdAt > recent, store.value("endedAt", of: workout) == nil else { return false }
            return store.value("startedAt", of: workout)?.dateValue
                .map { calendar.isDate($0, inSameDayAs: now) } ?? false
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
