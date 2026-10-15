import Foundation
import SwiftData

/// Training history and records, derived from the object graph:
/// Workout → Exercise Entry (classRef to an exercise class) → Set.
/// Every number here is computed from the Set class's own formulas, so a user who edits the e1RM formula
/// changes records, hints and trends together.
@MainActor
public struct TrainingLedger {
    public struct LoggedSet: Identifiable, Hashable, Sendable {
        public let id: UUID
        public let weight: Double
        public let reps: Double
        public let rpe: Double?
        public let e1RM: Double
        public var volume: Double {
            weight * reps
        }
    }

    /// One exercise inside one finished (or started) workout.
    public struct Session: Identifiable {
        /// The exercise entry's id.
        public let id: UUID
        public let workout: ObjectRecord
        public let entry: ObjectRecord
        public let date: Date
        /// Working sets in order; warm-ups are left out.
        public let sets: [LoggedSet]

        public var bestE1RM: Double {
            sets.map(\.e1RM).max() ?? 0
        }

        public var volume: Double {
            sets.reduce(0) { $0 + $1.volume }
        }
    }

    public struct PersonalRecords {
        public var bestE1RM: LoggedSet?
        /// Heaviest weight lifted for each whole rep count.
        public var bestWeightByReps: [Int: Double] = [:]
        public var bestSessionVolume: Double?

        public var isEmpty: Bool {
            bestE1RM == nil
        }
    }

    public enum RecordKind: Hashable, Sendable {
        case e1RM
        /// Heaviest weight at this many reps.
        case repMax(Int)
    }

    public struct TrendPoint: Identifiable, Hashable, Sendable {
        public let id: UUID
        public let date: Date
        public let bestE1RM: Double
        public let volume: Double
    }

    public let store: ObjectStore
    public let classes: [SystemCatalog.Key: ClassDef]

    /// Records are compared with a little slack so floating-point noise never shows as a PR.
    private static let tolerance = 0.05

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) {
        self.store = store
        self.classes = classes
    }

    // MARK: History

    /// Sessions of an exercise class and its subclasses, newest first.
    public func sessions(of exercise: ClassDef, excludingWorkout excludedID: UUID? = nil) -> [Session] {
        guard let workoutClass = classes[.workout] else { return [] }
        return store.backlinks(to: exercise, includingSubclasses: true).compactMap { entry -> Session? in
            guard let workout = store.ancestor(of: entry, ofClass: workoutClass), workout.id != excludedID,
                  let date = workoutDate(workout) else { return nil }
            let sets = workingSets(in: entry)
            guard !sets.isEmpty else { return nil }
            return Session(id: entry.id, workout: workout, entry: entry, date: date, sets: sets)
        }
        .sorted { $0.date > $1.date }
    }

    public func bestSet(of exercise: ClassDef, excludingWorkout excludedID: UUID? = nil) -> LoggedSet? {
        records(for: exercise, excludingWorkout: excludedID).bestE1RM
    }

    public func records(for exercise: ClassDef, excludingWorkout excludedID: UUID? = nil) -> PersonalRecords {
        var records = PersonalRecords()
        for session in sessions(of: exercise, excludingWorkout: excludedID) {
            for set in session.sets {
                if set.e1RM > (records.bestE1RM?.e1RM ?? -.infinity) {
                    records.bestE1RM = set
                }
                let reps = Int(set.reps.rounded())
                records.bestWeightByReps[reps] = max(records.bestWeightByReps[reps] ?? 0, set.weight)
            }
            records.bestSessionVolume = max(records.bestSessionVolume ?? 0, session.volume)
        }
        return records
    }

    /// Which records a set at this weight and reps would beat. Empty until there is history to beat.
    public func recordsBeaten(weight: Double, reps: Double, for exercise: ClassDef,
                              excludingWorkout excludedID: UUID? = nil) -> [RecordKind]
    {
        let records = records(for: exercise, excludingWorkout: excludedID)
        guard let best = records.bestE1RM else { return [] }
        var beaten: [RecordKind] = []
        if let e1RM = e1RM(weight: weight, reps: reps), e1RM > best.e1RM + Self.tolerance {
            beaten.append(.e1RM)
        }
        let wholeReps = Int(reps.rounded())
        if let previous = records.bestWeightByReps[wholeReps], weight > previous + Self.tolerance {
            beaten.append(.repMax(wholeReps))
        }
        return beaten
    }

    /// Fewest reps at `weight` that would beat the best e1RM, or nil if there's nothing to beat or it takes over 30.
    public func repsToBeatBestE1RM(weight: Double, for exercise: ClassDef,
                                   excludingWorkout excludedID: UUID? = nil) -> Int?
    {
        guard let best = bestSet(of: exercise, excludingWorkout: excludedID) else { return nil }
        return (1 ... 30).first { reps in
            (e1RM(weight: weight, reps: Double(reps)) ?? 0) > best.e1RM + Self.tolerance
        }
    }

    /// One point per session in the last `days` days, oldest first.
    public func trend(of exercise: ClassDef, days: Int = 90, now: Date = .now) -> [TrendPoint] {
        let start = now.addingTimeInterval(-Double(days) * 86400)
        return sessions(of: exercise)
            .filter { $0.date >= start && $0.date <= now }
            .reversed()
            .map { TrendPoint(id: $0.id, date: $0.date, bestE1RM: $0.bestE1RM, volume: $0.volume) }
    }

    // MARK: Formulas

    /// Evaluates the Set class's own `e1rm` formula for values that aren't logged yet.
    public func e1RM(weight: Double, reps: Double) -> Double? {
        guard let setClass = classes[.set], let source = ClassResolver.field("e1rm", of: setClass)?.expression,
              let formula = try? Formula.parse(source) else { return nil }
        return formula.evaluate { ["weight": weight, "reps": reps][$0] }
    }

    // MARK: Logging

    /// Appends a working set to an exercise entry.
    @discardableResult
    public func logSet(weight: Double, reps: Double, rpe: Double? = nil, isWarmup: Bool = false,
                       in entry: ObjectRecord) throws -> ObjectRecord
    {
        guard let setClass = classes[.set] else { throw ObjectStore.StoreError.unknownField("set") }
        let set = store.create(setClass, parent: entry)
        try store.set("weight", to: .mass(weight), on: set)
        try store.set("reps", to: .number(reps), on: set)
        try store.set("rpe", to: rpe.map(FieldValue.number), on: set)
        if isWarmup {
            try store.set("isWarmup", to: .bool(true), on: set)
        }
        return set
    }

    // MARK: Volume

    /// Working sets per muscle for the week containing `date`, keyed by muscle object id.
    /// Each set counts once for every primary muscle of its exercise class.
    public func weeklySetsPerMuscle(weekContaining date: Date,
                                    calendar: Calendar = .current) -> [UUID: Int]
    {
        guard let workoutClass = classes[.workout],
              let week = calendar.dateInterval(of: .weekOfYear, for: date) else { return [:] }
        var counts: [UUID: Int] = [:]
        for workout in store.objects(of: workoutClass) {
            guard let when = workoutDate(workout), week.contains(when) else { continue }
            for entry in workout.orderedChildren {
                guard let exercise = store.linkedClass("exercise", of: entry) else { continue }
                let sets = workingSets(in: entry).count
                guard sets > 0 else { continue }
                for muscle in store.linkedObjects("primaryMuscles", ofClass: exercise) {
                    counts[muscle.id, default: 0] += sets
                }
            }
        }
        return counts
    }

    // MARK: Private

    private func workoutDate(_ workout: ObjectRecord) -> Date? {
        (store.value("endedAt", of: workout) ?? store.value("startedAt", of: workout))?.dateValue
    }

    private func workingSets(in entry: ObjectRecord) -> [LoggedSet] {
        entry.orderedChildren.compactMap { set -> LoggedSet? in
            guard store.value("isWarmup", of: set) != .bool(true),
                  let weight = store.number("weight", of: set), let reps = store.number("reps", of: set),
                  let e1RM = store.number("e1rm", of: set) else { return nil }
            return LoggedSet(id: set.id, weight: weight, reps: reps, rpe: store.number("rpe", of: set), e1RM: e1RM)
        }
    }
}
