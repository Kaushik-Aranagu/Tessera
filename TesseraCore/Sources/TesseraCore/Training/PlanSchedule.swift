import Foundation

/// Plans run as a rolling sequence: a missed day never creates debt, the next routine simply comes next.
@MainActor
public extension TrainingLedger {
    /// The routine to do next in a plan: the one after the last finished workout from this plan.
    func nextRoutine(in plan: ObjectRecord) -> ObjectRecord? {
        let cycle = store.linkedObjects("routines", of: plan)
        guard !cycle.isEmpty, let workoutClass = classes[.workout] else { return nil }
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
        guard let interval = calendar.dateInterval(of: .month, for: date),
              let workoutClass = classes[.workout] else { return [] }
        var byDay: [Date: (Int, Double)] = [:]
        var recent: [Double] = []
        let typicalWindow = interval.end.addingTimeInterval(-90 * 86400)
        for workout in store.objects(of: workoutClass) {
            guard let ended = store.value("endedAt", of: workout)?.dateValue else { continue }
            let volume = workout.orderedChildren.reduce(0.0) { total, entry in
                total + entry.orderedChildren.reduce(0.0) { sum, set in
                    guard setKind(set).counts else { return sum }
                    return sum + (store.number("volume", of: set) ?? 0)
                }
            }
            if ended >= typicalWindow, ended < interval.end, volume > 0 {
                recent.append(volume)
            }
            guard interval.contains(ended) else { continue }
            let day = calendar.startOfDay(for: ended)
            let current = byDay[day] ?? (0, 0)
            byDay[day] = (current.0 + 1, current.1 + volume)
        }
        let typical = recent.sorted().dropFirst(recent.count / 2).first ?? 0
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
