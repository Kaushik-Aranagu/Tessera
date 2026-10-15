import Foundation

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
        public let kind: SetKind
        /// Epley on effective reps (reps + 10 − RPE when RPE is logged).
        public let e1RM: Double
        /// Only sets of up to 12 effective reps estimate a max honestly.
        public let isE1RMEligible: Bool
        public var volume: Double {
            weight * reps
        }
    }

    /// One exercise inside one finished (or started) workout.
    public struct Session: Identifiable {
        /// The exercise entry's id.
        public let id: UUID
        /// The workout's id, readable without loading the workout.
        public let workoutID: UUID
        public let workout: ObjectRecord
        public let entry: ObjectRecord
        public let date: Date
        /// Working sets in order; warm-ups are left out.
        public let sets: [LoggedSet]

        init(id: UUID, workoutID: UUID, workout: ObjectRecord, entry: ObjectRecord, date: Date, sets: [LoggedSet]) {
            self.id = id
            self.workoutID = workoutID
            self.workout = workout
            self.entry = entry
            self.date = date
            self.sets = sets
        }

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
    /// Rep maxes are tracked from 1 to 10 reps.
    public nonisolated static let repMaxRange = 1 ... 10
    /// Sets above this many effective reps don't estimate a one-rep max.
    public nonisolated static let e1RMRepLimit = 12.0

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) {
        self.store = store
        self.classes = classes
    }

    // MARK: History

    /// Sessions of an exercise class and its subclasses, newest first.
    public func sessions(of exercise: ClassDef, excludingWorkout excludedID: UUID? = nil) -> [Session] {
        let index = index
        let derived = store.derived
        let revision = store.revision
        let all: [Session]
        if let cached = derived.sessions[exercise.id], cached.revision == revision {
            all = cached.sessions
        } else {
            all = ClassResolver.descendants(of: exercise)
                .flatMap { index.sessionsByClass[$0.id] ?? [] }
                .sorted { $0.date > $1.date }
            derived.sessions[exercise.id] = (revision, all)
        }
        return excludedID.map { excluded in all.filter { $0.workoutID != excluded } } ?? all
    }

    public func bestSet(of exercise: ClassDef, excludingWorkout excludedID: UUID? = nil) -> LoggedSet? {
        records(for: exercise, excludingWorkout: excludedID).bestE1RM
    }

    public func records(for exercise: ClassDef, excludingWorkout excludedID: UUID? = nil) -> PersonalRecords {
        var records = PersonalRecords()
        for session in sessions(of: exercise, excludingWorkout: excludedID) {
            for set in session.sets {
                if set.isE1RMEligible, set.e1RM > (records.bestE1RM?.e1RM ?? -.infinity) {
                    records.bestE1RM = set
                }
                let reps = Int(set.reps.rounded())
                if Self.repMaxRange.contains(reps) {
                    records.bestWeightByReps[reps] = max(records.bestWeightByReps[reps] ?? 0, set.weight)
                }
            }
            records.bestSessionVolume = max(records.bestSessionVolume ?? 0, session.volume)
        }
        return records
    }

    /// Which records a set at this weight and reps would beat. Empty until there is history to beat.
    public func recordsBeaten(weight: Double, reps: Double, rpe: Double? = nil, for exercise: ClassDef,
                              excludingWorkout excludedID: UUID? = nil) -> [RecordKind]
    {
        let records = records(for: exercise, excludingWorkout: excludedID)
        guard let best = records.bestE1RM else { return [] }
        var beaten: [RecordKind] = []
        if Self.effectiveReps(reps, rpe: rpe) <= Self.e1RMRepLimit,
           let e1RM = e1RM(weight: weight, reps: reps, rpe: rpe), e1RM > best.e1RM + Self.tolerance
        {
            beaten.append(.e1RM)
        }
        let wholeReps = Int(reps.rounded())
        if Self.repMaxRange.contains(wholeReps), let previous = records.bestWeightByReps[wholeReps],
           weight > previous + Self.tolerance
        {
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
    public func e1RM(weight: Double, reps: Double, rpe: Double? = nil) -> Double? {
        guard let setClass = classes[.set], let source = ClassResolver.field("e1rm", of: setClass)?.expression,
              let formula = try? Formula.parse(source) else { return nil }
        var values = ["weight": weight, "reps": reps]
        values["rpe"] = rpe
        return formula.evaluate { values[$0] }
    }

    /// Reps plus the reps left in the tank: 5 @ RPE 8 is a 7-rep effort.
    public nonisolated static func effectiveReps(_ reps: Double, rpe: Double?) -> Double {
        reps + (10 - min(max(rpe ?? 10, 1), 10))
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
        try store.set("loggedAt", to: .date(.now), on: set)
        if isWarmup {
            try store.set("kind", to: .choice(SetKind.warmup.rawValue), on: set)
        }
        return set
    }

    // MARK: Volume

    /// Fractional working sets per muscle for the week containing `date`, keyed by muscle object id.
    /// A set counts 1 for each primary muscle of its exercise and 0.5 for each secondary one.
    public func weeklySets(weekContaining date: Date, calendar: Calendar = .current) -> [UUID: Double] {
        var counts: [UUID: Double] = [:]
        forEachEntry(inWeekOf: date, calendar: calendar) { exercise, sets in
            for muscle in store.linkedObjects("primaryMuscles", ofClass: exercise) {
                counts[muscle.id, default: 0] += Double(sets)
            }
            for muscle in store.linkedObjects("secondaryMuscles", ofClass: exercise) {
                counts[muscle.id, default: 0] += Double(sets) * 0.5
            }
        }
        return counts
    }

    private func forEachEntry(inWeekOf date: Date, calendar: Calendar, _ body: (ClassDef, Int) -> Void) {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: date) else { return }
        for (classID, session) in index.allSessions where week.contains(session.date) {
            guard let exercise = store.classDef(id: classID) else { continue }
            body(exercise, session.sets.count)
        }
    }

    /// Working sets per primary muscle for the week containing `date` (whole sets, primary muscles only).
    /// Prefer `weeklySets(weekContaining:)`, which also counts secondary muscles at half a set.
    public func weeklySetsPerMuscle(weekContaining date: Date,
                                    calendar: Calendar = .current) -> [UUID: Int]
    {
        var counts: [UUID: Int] = [:]
        forEachEntry(inWeekOf: date, calendar: calendar) { exercise, sets in
            for muscle in store.linkedObjects("primaryMuscles", ofClass: exercise) {
                counts[muscle.id, default: 0] += sets
            }
        }
        return counts
    }

    // MARK: Private

    func workoutDate(_ workout: ObjectRecord) -> Date? {
        (store.value("endedAt", of: workout) ?? store.value("startedAt", of: workout))?.dateValue
    }

    private func workingSets(in entry: ObjectRecord) -> [LoggedSet] {
        entry.orderedChildren.compactMap(loggedSet)
    }

    /// A counted set (not a warm-up) with weight and reps, else nil.
    func loggedSet(_ set: ObjectRecord) -> LoggedSet? {
        let kind = setKind(set)
        guard kind.counts,
              let weight = store.number("weight", of: set), let reps = store.number("reps", of: set),
              let e1RM = store.number("e1rm", of: set) else { return nil }
        let rpe = store.number("rpe", of: set)
        return LoggedSet(id: set.id, weight: weight, reps: reps, rpe: rpe, kind: kind, e1RM: e1RM,
                         isE1RMEligible: Self.effectiveReps(reps, rpe: rpe) <= Self.e1RMRepLimit)
    }

    /// The set's kind; the older warm-up flag still counts.
    public func setKind(_ set: ObjectRecord) -> SetKind {
        if store.value("isWarmup", of: set) == .bool(true) {
            return .warmup
        }
        return store.value("kind", of: set)?.stringValue.flatMap(SetKind.init(rawValue:)) ?? .working
    }
}
