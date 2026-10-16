import Foundation

/// Plans run as a rolling sequence: a missed day never creates debt, the next routine simply comes next.
@MainActor
public extension TrainingLedger {
    /// The routine to do next in a plan: the one after the last finished workout from this plan. On fixed days:
    /// today's routine unless it was trained today, else the next weekday with one (a missed day does not roll on).
    func nextRoutine(in plan: ObjectRecord, now: Date = .now, calendar: Calendar = .current) -> ObjectRecord? {
        let cycle = store.linkedObjects("routines", of: plan)
        guard !cycle.isEmpty, let workoutClass = classes[.workout] else { return nil }
        if PlanSchedule.mode(of: plan, store: store) == .fixed {
            let day = TesseraDay(calendar: calendar)
            let today = day.today(now)
            let trainedToday = !finishedWorkouts(onDay: today, calendar: calendar).isEmpty
            return (trainedToday ? 1 ..< 8 : 0 ..< 7).lazy.compactMap { offset -> ObjectRecord? in
                calendar.date(byAdding: .day, value: offset, to: today)
                    .flatMap { PlanSchedule.routine(on: $0, in: plan, store: self.store, calendar: calendar) }
            }.first
        }
        let finished = store.objects(of: workoutClass)
            .filter { store.value("endedAt", of: $0) != nil }
            .compactMap { workout -> (Date, Int)? in
                guard let routine = store.linkedObjects("routine", of: workout).first,
                      let index = cycle.firstIndex(where: { $0.id == routine.id }),
                      let date = store.value("endedAt", of: workout)?.dateValue else { return nil }
                return (date, index)
            }
            .max { $0.0 < $1.0 }
        guard let last = finished else { return cycle[0] }
        return cycle[(last.1 + 1) % cycle.count]
    }

    struct DayVolume: Identifiable, Hashable, Sendable {
        public var id: Date {
            day
        }

        public let day: Date
        public let sessions: Int
        public let volume: Double
        /// Volume relative to a typical session (median of the last 90 days), clamped to 0...1.5.
        public let relative: Double
    }

    /// The month heatmap: one cell per day, filled by that day's volume relative to a typical session.
    func month(containing date: Date, calendar: Calendar = .current) -> [DayVolume] {
        let tesseraDay = TesseraDay(calendar: calendar)
        // The month of his day (00:30 on the 1st is still last month); sessions land on the day they belong to.
        guard let interval = calendar.dateInterval(of: .month, for: tesseraDay.day(of: date)) else { return [] }
        let typicalWindow = interval.end.addingTimeInterval(-90 * 86400)
        // Volume per workout, from the training index (warm-ups already left out).
        var workouts: [UUID: (date: Date, volume: Double)] = [:]
        for (_, session) in index.allSessions where session.date >= typicalWindow && session.date < interval.end {
            workouts[session.workoutID, default: (session.date, 0)].volume += session.volume
        }
        let recent = workouts.values.map(\.volume).filter { $0 > 0 }.sorted()
        let typical = recent.isEmpty ? 0 : recent[recent.count / 2]
        var byDay: [Date: (sessions: Int, volume: Double)] = [:]
        for workout in workouts.values where interval.contains(tesseraDay.day(of: workout.date)) {
            let day = tesseraDay.day(of: workout.date)
            byDay[day, default: (0, 0)].sessions += 1
            byDay[day, default: (0, 0)].volume += workout.volume
        }
        var days: [DayVolume] = []
        var day = interval.start
        while day < interval.end {
            let (sessions, volume) = byDay[day] ?? (0, 0)
            let relative = typical > 0 ? min(volume / typical, 1.5) : (volume > 0 ? 1 : 0)
            days.append(DayVolume(day: day, sessions: sessions, volume: volume, relative: relative))
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return days
    }
}

@MainActor
public extension TrainingLedger {
    /// "Session 6 of 14 this month": sessions done in the month containing `date`, and how many the plan
    /// expects (its sessions a week, else one per routine up to six, spread over the month's days).
    func monthCounts(containing date: Date, plan: ObjectRecord?,
                     calendar: Calendar = .current) -> (done: Int, planned: Int?)
    {
        let days = month(containing: date, calendar: calendar)
        let done = days.reduce(0) { $0 + $1.sessions }
        guard let plan else { return (done, nil) }
        let routines = store.linkedObjects("routines", of: plan).count
        let perWeek = store.number("sessionsPerWeek", of: plan) ?? Double(min(max(routines, 1), 6))
        return (done, Int((perWeek * Double(days.count) / 7).rounded()))
    }
}
