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
        // Incremental (QA S1 on #377): the op log only grows, so only records not seen before are read, and nothing is
        // sorted. "First start wins" needs no order (a workout starts once); "latest finish wins" compares times.
        var state = derived.opZonesState ?? OpZonesState()
        let operations = store.context.operations
        // Nothing new in the log (a value changed): the zones stand.
        if operations.count != state.seen.count {
            for record in operations.values where !state.seen.contains(record.id) {
                state.seen.insert(record.id)
                guard let zone = record.zone.flatMap(TimeZone.init(identifier:)) else { continue }
                if Self.starts.contains(record.action) {
                    for id in record.objectIDs {
                        state.set(zone, for: id, rank: 2, at: record.createdAt)
                    }
                }
                if Self.finishes.contains(record.action) {
                    for id in record.objectIDs {
                        state.set(zone, for: id, rank: 1, at: record.createdAt)
                    }
                }
                for op in record.ops {
                    if case let .create(object, _, _, _) = op {
                        state.set(zone, for: object, rank: 0, at: record.createdAt)
                    }
                }
            }
        }
        zones = state.zones
        derived.opZonesState = state
        derived.opZones = (store.revision, state.zones)
    }

    /// How many records the log has been read through, for the incremental test.
    public static func recordsRead(in store: ObjectStore) -> Int {
        store.cache.derived.opZonesState?.seen.count ?? 0
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

/// What OpZones has read of the op log so far: each object's zone with the rank of the record that set it (a start
/// beats a finish beats a create; among finishes the latest wins), so a record read in any order lands right.
struct OpZonesState {
    var seen = Set<UUID>()
    var zones: [UUID: TimeZone] = [:]
    var ranks: [UUID: (rank: Int, at: Date)] = [:]

    mutating func set(_ zone: TimeZone, for id: UUID, rank: Int, at: Date) {
        if let current = ranks[id] {
            guard rank > current.rank || (rank == current.rank && rank == 1 && at >= current.at) else { return }
        }
        zones[id] = zone
        ranks[id] = (rank, at)
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
