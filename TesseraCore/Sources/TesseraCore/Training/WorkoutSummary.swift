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

    /// What Tess says when the workout is done, the thing first: "Push Day A done, 1 of 5 exercises." Unmasked, so
    /// internal: the app only reaches the masked `doneLine(in:)` (QA on #787).
    var doneLine: String {
        Self.doneLine(title: title, done: exercisesDone, planned: exercisesPlanned)
    }

    /// "Push Day A done, 1 of 1 exercise." and, when nothing was planned, just "Push Day A done." (never "0 of 0").
    private static func doneLine(title: String, done: Int, planned: Int) -> String {
        guard planned > 0 else { return "\(title) done." }
        return "\(title) done, \(done) of \(planned) \(planned == 1 ? "exercise" : "exercises")."
    }

    /// The done line with a private routine title masked (QA on #781): "Private workout done, 1 of 5 exercises."
    @MainActor
    public func doneLine(in store: ObjectStore) -> String {
        let lastKg = BodyWeight.lastKg(in: store)
        let shown = PrivateWords.isPrivateTitle(title, lastWeightKg: lastKg) ? ObjectPrivacy.routineLabel : title
        return Self.doneLine(title: shown, done: exercisesDone, planned: exercisesPlanned)
    }

    /// Tess's line: "6 of 6 exercises, 22 sets, 1 best." Counts, never judgement ("best", not "record": Product).
    public var line: String {
        var parts: [String] = []
        // Nothing planned says no "0 of 0".
        if exercisesPlanned > 0 {
            parts.append("\(exercisesDone) of \(exercisesPlanned) \(exercisesPlanned == 1 ? "exercise" : "exercises")")
        }
        parts.append("\(sets) \(sets == 1 ? "set" : "sets")")
        if !records.isEmpty {
            parts.append("\(records.count) \(records.count == 1 ? "best" : "bests")")
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

    /// Workouts finished on his day containing the moment `date` (04:00 to 04:00), newest first: today's history on
    /// Home. A workout belongs to the day it started: Push A from 22:50 to 00:40 is Friday's, and a session crossing
    /// 04:00 stays on its first day.
    func finishedWorkouts(on date: Date, calendar: Calendar = .current) -> [WorkoutSummary] {
        finishedWorkouts(onDay: TesseraDay(calendar: calendar).day(of: date), calendar: calendar)
    }

    /// The same for a day key (a midnight from `TesseraDay.day(of:)`, as `week` and Review pass).
    /// Cached for the store's revision and time zone (after a flight, the old zone's keys would all miss).
    func finishedWorkouts(onDay day: Date, calendar: Calendar = .current) -> [WorkoutSummary] {
        guard let workoutClass = classes[.workout] else { return [] }
        let derived = store.cache.derived
        let revision = store.revision
        let tesseraDay = TesseraDay(calendar: calendar)
        let zone = calendar.timeZone.identifier
        if let cached = derived.daySummaries[day], cached.revision == revision, derived.workoutDaysZone == zone {
            return cached.summaries
        }
        if derived.workoutDays?.revision != revision || derived.workoutDaysZone != zone {
            // Each workout files under the day it started where he was (Research 127 T1): a hotel-gym Wednesday
            // stays Wednesday once he is home.
            let zones = OpZones(store: store)
            var days: [Date: [UUID]] = [:]
            for workout in store.objects(of: workoutClass) {
                guard let ended = store.value("endedAt", of: workout)?.dateValue else { continue }
                let started = store.value("startedAt", of: workout)?.dateValue ?? ended
                days[zones.dayKey(of: started, for: workout.id, calendar: calendar), default: []].append(workout.id)
            }
            derived.workoutDays = (revision, days)
            derived.workoutDaysZone = zone
            derived.daySummaries = [:]
        }
        let summaries = (derived.workoutDays?.days[day] ?? [])
            .compactMap { store.object(id: $0) }
            .map(summary)
            // A workout finished with no sets is not a session he did (Product 8:30 PM PT).
            .filter { $0.sets > 0 }
            .sorted { ($0.endedAt ?? .distantPast) > ($1.endedAt ?? .distantPast) }
        derived.daySummaries[day] = (revision, summaries)
        return summaries
    }
}
