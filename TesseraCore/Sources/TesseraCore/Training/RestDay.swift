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
        // A planned session beats rest (Product 3:05 AM; RG5): Now and Home agree, no "Rest day" beside a START key.
        guard let plan, !hasWorkoutUnderway(on: now, calendar: calendar),
              !hasPlannedSession(on: now, calendar: calendar) else { return nil }
        // A rest he took for today (the Deck's "Rest" or Tess's restDay): today is a rest day; a rolling plan's next
        // routine
        // stays next, and the next session date is the next training day.
        if RestBook(store: store, classes: classes).isTrainingRest(on: now, calendar: calendar),
           let next = nextRoutine(in: plan, now: now, calendar: calendar)
        {
            return RestDay(next: next, nextDay: nil)
        }
        let week = week(containing: now, plan: plan, now: now, sessionsPerWeek: sessionsPerWeek, calendar: calendar)
        guard let today = week.firstIndex(where: { $0.state == .today }), week[today].isRest else { return nil }
        if let ahead = week[(today + 1)...].first(where: { $0.planned != nil }), let routine = ahead.planned {
            return RestDay(next: routine, nextDay: ahead.day)
        }
        return nextRoutine(in: plan, now: now, calendar: calendar).map { RestDay(next: $0, nextDay: nil) }
    }
}

@MainActor
extension TrainingLedger {
    /// A workout scheduled for his day containing `now` and not finished or started (a time set on a rest day).
    /// The same test as Home's `plannedSession(on:)`, so Now and Home agree (RG5).
    func hasPlannedSession(on now: Date, calendar: Calendar) -> Bool {
        guard let workoutClass = classes[.workout] else { return false }
        let day = TesseraDay(calendar: calendar)
        return store.objects(of: workoutClass).contains { workout in
            guard !workout.isDeleted, store.value("endedAt", of: workout) == nil,
                  let date = store.value("scheduledFor", of: workout)?.dateValue
                  ?? store.value("startedAt", of: workout)?.dateValue else { return false }
            return day.isSameDay(date, now)
        }
    }

    /// A workout started today and not finished: today is in use, not a rest day. One that is only scheduled (a gym
    /// nudge on a rest day) doesn't count. A started, unfinished workout is always a process (running or set aside),
    /// so only the process table is read: cheap at any history size, and nothing made ahead of time is missed
    /// (QA E7, N5).
    func hasWorkoutUnderway(on now: Date, calendar: Calendar) -> Bool {
        guard let workoutClass = classes[.workout], let processClass = classes[.process] else { return false }
        return store.objects(of: processClass).contains { record in
            let process = ProcessSnapshot(record, store: store)
            guard let workout = process.subject, workout.classDef?.id == workoutClass.id,
                  store.value("endedAt", of: workout) == nil else { return false }
            return store.value("startedAt", of: workout)?.dateValue
                .map { TesseraDay(calendar: calendar).isSameDay($0, now) } ?? false
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
