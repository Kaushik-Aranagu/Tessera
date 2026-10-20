import Foundation

/// How full the rest of today is (M2 slice 7): planned minutes against free time, and what could move to Later.
public struct DayLoad {
    public let plannedMinutes: Double
    public let freeMinutes: Double
    /// Over capacity: Home shows "full", in a neutral colour.
    public var isFull: Bool {
        plannedMinutes > freeMinutes
    }

    /// Tasks that could move to Later to make the day fit: untimed or carried-over first, longest first, just
    /// enough to fit (or all of them if it still can't).
    public let couldMove: [TaskList.Item]
}

@MainActor
public extension TaskList {
    /// Untimed tasks count as 30 minutes; today's unfinished workout counts as an hour.
    static let defaultTaskMinutes = 30.0
    static let workoutMinutes = 60.0

    /// The rest of today, from now (or the start of the day) to the day's end (23:00 by default).
    /// `restDay` leaves out a workout still scheduled for today (the plan rests, so it doesn't load the day).
    func load(at now: Date = .now, dayStartHour: Int = 7, dayEndHour: Int = 23, restDay: Bool = false,
              calendar: Calendar = .current) -> DayLoad
    {
        let start = calendar.date(bySettingHour: dayStartHour, minute: 0, second: 0, of: now) ?? now
        let end = calendar.date(bySettingHour: dayEndHour, minute: 0, second: 0, of: now) ?? now
        let rangeStart = max(now, start)
        // The calendar's busy time comes off the free time (M4 slice 3): a day of meetings is a fuller day.
        let busy = CalendarBusy.minutes(store: store, classes: classes, from: rangeStart, to: end)
        let free = max(max(end.timeIntervalSince(rangeStart), 0) / 60 - busy, 0)

        let open = today(now, calendar: calendar).filter { !$0.isDone }
        // Timed tasks already over don't load the rest of the day; carried-over and untimed ones still do.
        let remaining = open.filter { item in
            guard !item.isCarriedOver, let when = item.when else { return true }
            return when.addingTimeInterval((item.minutes ?? 0) * 60) > now
        }
        let taskMinutes = remaining.reduce(0) { $0 + ($1.minutes ?? Self.defaultTaskMinutes) }
        let workouts = restDay ? 0 : classes[.workout].map { workoutClass in
            store.objects(of: workoutClass).filter { workout in
                store.value("endedAt", of: workout) == nil
                    && (store.value("scheduledFor", of: workout)?.dateValue)
                    .map { TesseraDay(calendar: calendar).isSameDay($0, now) } == true
            }.count
        } ?? 0
        let planned = taskMinutes + Double(workouts) * Self.workoutMinutes

        var couldMove: [TaskList.Item] = []
        if planned > free {
            var excess = planned - free
            let candidates = remaining
                .filter { $0.isCarriedOver || store.value("startsAt", of: $0.task) == nil }
                .sorted { ($0.minutes ?? Self.defaultTaskMinutes) > ($1.minutes ?? Self.defaultTaskMinutes) }
            for item in candidates where excess > 0 {
                couldMove.append(item)
                excess -= item.minutes ?? Self.defaultTaskMinutes
            }
        }
        return DayLoad(plannedMinutes: planned, freeMinutes: free, couldMove: couldMove)
    }
}
