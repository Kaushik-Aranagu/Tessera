import Foundation

/// The time zone each thing happened in, read once from the op log (every record carries the zone it was written in).
/// Day buckets read it so a hotel-gym Wednesday stays Wednesday once he is home (Research 127, T1 and T2).
@MainActor
public struct OpZones {
    public let store: ObjectStore
    let zones: [UUID: TimeZone]

    /// Actions whose zone is the moment that files the object under a day.
    static let starts: Set<String> = ["startWorkout", "startRoutine", "logExercise"]
    static let finishes: Set<String> = ["setTaskDone", "finishCooking", "finishWorkout", "finishWorkoutEarly"]

    public init(store: ObjectStore) {
        self.store = store
        let derived = store.cache.derived
        if let cached = derived.opZones, cached.revision == store.revision {
            zones = cached.zones
            return
        }
        var started: [UUID: TimeZone] = [:], finished: [UUID: TimeZone] = [:], made: [UUID: TimeZone] = [:]
        for record in store.context.operations.values.sorted(by: { $0.createdAt < $1.createdAt }) {
            guard let zone = record.zone.flatMap(TimeZone.init(identifier:)) else { continue }
            if Self.starts.contains(record.action) {
                for id in record.objectIDs where started[id] == nil {
                    started[id] = zone
                }
            }
            if Self.finishes.contains(record.action) {
                // The latest finish wins: a task done, reopened and done again files where it was last done.
                for id in record.objectIDs {
                    finished[id] = zone
                }
            }
            for op in record.ops {
                if case let .create(object, _, _, _) = op, made[object] == nil {
                    made[object] = zone
                }
            }
        }
        var zones = made
        zones.merge(finished) { _, finish in finish }
        zones.merge(started) { _, start in start }
        self.zones = zones
        derived.opZones = (store.revision, zones)
    }

    /// The zone the object was started in (a workout), finished in (a task, a cook) or made in; nil for rows from
    /// before zones were stamped, which read in the calendar's zone.
    public func zone(of id: UUID) -> TimeZone? {
        zones[id]
    }

    /// The day key (a midnight in `calendar`) for a moment, read in the object's own zone: 21:30 in New York is that
    /// Wednesday wherever he reads it later.
    public func dayKey(of date: Date, for id: UUID, calendar: Calendar) -> Date {
        TesseraDay(calendar: calendar).day(of: date, in: zone(of: id))
    }
}

public extension TesseraDay {
    /// The midnight key, in this calendar, of the day `date` fell on in `zone` (his 04:00 day there). Nil zone reads
    /// in the calendar's own zone.
    func day(of date: Date, in zone: TimeZone?) -> Date {
        guard let zone, zone != calendar.timeZone else { return day(of: date) }
        var there = calendar
        there.timeZone = zone
        let key = TesseraDay(calendar: there).day(of: date)
        let parts = there.dateComponents([.year, .month, .day], from: key)
        return calendar.date(from: parts) ?? day(of: date)
    }
}
