import Foundation

/// A finished (or running) workout compressed to what Home shows, with Tess's one line.
public struct WorkoutSummary: Identifiable {
    public struct Record: Hashable, Sendable {
        public let exercise: String
        public let kind: TrainingLedger.RecordKind
        public let weight: Double
        public let reps: Double
    }

    public let id: UUID
    public let workout: ObjectRecord
    public let title: String
    public let startedAt: Date?
    public let endedAt: Date?
    public let exercisesDone: Int
    public let exercisesPlanned: Int
    public let sets: Int
    /// Working-set volume in kilograms.
    public let volume: Double
    public let records: [Record]

    public var duration: TimeInterval? {
        guard let startedAt, let endedAt else { return nil }
        return endedAt.timeIntervalSince(startedAt)
    }

    /// Tess's line: "6 of 6 exercises, 22 sets, 1 record." Counts, never judgement.
    public var line: String {
        var parts = ["\(exercisesDone) of \(exercisesPlanned) exercises", "\(sets) \(sets == 1 ? "set" : "sets")"]
        if !records.isEmpty {
            parts.append("\(records.count) \(records.count == 1 ? "record" : "records")")
        }
        return parts.joined(separator: ", ") + "."
    }
}

@MainActor
public extension TrainingLedger {
    /// Summarises a workout: exercises done of planned, working sets, volume, and records it set.
    func summary(of workout: ObjectRecord) -> WorkoutSummary {
        let entries = workout.orderedChildren
        var sets = 0
        var volume = 0.0
        var done = 0
        var records: [WorkoutSummary.Record] = []
        for entry in entries {
            let logged = entry.orderedChildren.compactMap(loggedSet)
            guard !logged.isEmpty else { continue }
            done += 1
            sets += logged.count
            volume += logged.reduce(0) { $0 + $1.volume }
            guard let exercise = store.linkedClass("exercise", of: entry) else { continue }
            // At most one record per exercise per session: the strongest kind beaten.
            let before = self.records(for: exercise, excludingWorkout: workout.id)
            guard before.bestE1RM != nil else { continue }
            var best: WorkoutSummary.Record?
            for set in logged {
                let beaten = recordsBeaten(weight: set.weight, reps: set.reps, rpe: set.rpe, for: exercise,
                                           excludingWorkout: workout.id)
                if let kind = beaten.first, best == nil || kind == .e1RM {
                    best = .init(exercise: exercise.name, kind: kind, weight: set.weight, reps: set.reps)
                }
            }
            if let best {
                records.append(best)
            }
        }
        return WorkoutSummary(
            id: workout.id, workout: workout, title: store.displayTitle(of: workout),
            startedAt: store.value("startedAt", of: workout)?.dateValue,
            endedAt: store.value("endedAt", of: workout)?.dateValue,
            exercisesDone: done, exercisesPlanned: entries.count, sets: sets, volume: volume, records: records
        )
    }

    /// Workouts finished on his day containing `date` (04:00 to 04:00), newest first: today's history on Home.
    /// A workout belongs to the day it started: Push A from 22:50 to 00:40 is Friday's, and a session crossing 04:00
    /// stays on its first day. `date` is a moment, or a day key (an exact midnight, as `week` and the day lanes pass).
    /// Cached for the store's revision and time zone (after a flight, the old zone's keys would all miss).
    func finishedWorkouts(on date: Date, calendar: Calendar = .current) -> [WorkoutSummary] {
        guard let workoutClass = classes[.workout] else { return [] }
        let derived = store.cache.derived
        let revision = store.revision
        let tesseraDay = TesseraDay(calendar: calendar)
        let day = date == calendar.startOfDay(for: date) ? date : tesseraDay.day(of: date)
        let zone = calendar.timeZone.identifier
        if let cached = derived.daySummaries[day], cached.revision == revision, derived.workoutDaysZone == zone {
            return cached.summaries
        }
        if derived.workoutDays?.revision != revision || derived.workoutDaysZone != zone {
            var days: [Date: [UUID]] = [:]
            for workout in store.objects(of: workoutClass) {
                guard let ended = store.value("endedAt", of: workout)?.dateValue else { continue }
                let started = store.value("startedAt", of: workout)?.dateValue ?? ended
                days[tesseraDay.day(of: started), default: []].append(workout.id)
            }
            derived.workoutDays = (revision, days)
            derived.workoutDaysZone = zone
            derived.daySummaries = [:]
        }
        let summaries = (derived.workoutDays?.days[day] ?? [])
            .compactMap { store.object(id: $0) }
            .map(summary)
            .sorted { ($0.endedAt ?? .distantPast) > ($1.endedAt ?? .distantPast) }
        derived.daySummaries[day] = (revision, summaries)
        return summaries
    }
}
