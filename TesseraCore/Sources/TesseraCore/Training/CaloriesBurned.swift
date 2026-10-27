import Foundation

/// Whether calories show, and the Health weight the app passes in for this call (held in memory, never stored).
public struct CaloriesOptions: Equatable, Sendable {
    public var on: Bool
    public var healthKg: Double?

    public init(on: Bool, healthKg: Double? = nil) {
        self.on = on
        self.healthKg = healthKg
    }
}

/// Calories, as an estimate: MET x body mass (kg) x hours, rounded to the nearest 10 and always said "about N kcal".
/// Behind the `caloriesBurned` Review switch, default Off. Per exercise and per workout; there is no daily budget.
/// METs are the 2024 Adult Compendium's, unchanged and never averaged (docs/research/reference-library-met-mapping.md).
/// Nothing here reaches Claude, the Sent log, logs or widgets.
public enum CaloriesBurned {
    public static let reviewKey = "caloriesBurned"
    /// Off unless he turned it on.
    public static func isOn(_ value: String?) -> Bool {
        value == "On"
    }

    public static let aboutLine = "Energy costs from the 2024 Adult Compendium of Physical Activities "
        + "(pacompendium.com). Herrmann SD, Willis EA, Ainsworth BE, et al. Journal of Sport and Health Science, "
        + "2024;13(1):6-12"

    /// kcal for a MET at a body mass for some minutes, rounded to the nearest 10. Nil with no weight or no time.
    public static func estimate(met: Double, weightKg: Double, minutes: Double) -> Int? {
        guard met > 0, weightKg > 0, minutes > 0 else { return nil }
        let kcal = met * weightKg * minutes / 60
        return Int((kcal / 10).rounded()) * 10
    }

    public static func line(_ kcal: Int) -> String {
        "about \(kcal) kcal"
    }

    /// The line for a finished workout, or nil: the switch is off, the workout is private, it is unfinished, or no
    /// weight is known. Only the two in-app places (the Day line and Home's done line) ask for it.
    @MainActor
    public static func line(forWorkout workout: ObjectRecord, store: ObjectStore,
                            classes: [SystemCatalog.Key: ClassDef], options: CaloriesOptions) -> String?
    {
        guard options.on, ObjectPrivacy.shownLabel(of: workout, in: store, classes: classes) == nil,
              let weight = MeProfile.weightKg(in: store, healthKg: options.healthKg),
              let kcal = forWorkout(workout, store: store, weightKg: weight) else { return nil }
        return line(kcal)
    }

    /// The estimate for a finished workout, from its length and each exercise's MET weighted by its working sets.
    /// Nil when it is unfinished, has no length, or no weight is known.
    @MainActor
    public static func forWorkout(_ workout: ObjectRecord, store: ObjectStore, weightKg: Double?) -> Int? {
        let parts = exerciseShares(of: workout, store: store)
        guard let weightKg, let minutes = minutes(of: workout, store: store), !parts.isEmpty else { return nil }
        let total = parts.reduce(0) { $0 + $1.sets }
        guard total > 0 else { return nil }
        let kcal = parts.reduce(0.0) { $0 + $1.met * weightKg * (minutes * $1.sets / total) / 60 }
        return kcal > 0 ? Int((kcal / 10).rounded()) * 10 : nil
    }

    /// The estimate for one exercise of a finished workout: its share of the workout's minutes by working sets.
    @MainActor
    public static func forExercise(_ entry: ObjectRecord, in workout: ObjectRecord, store: ObjectStore,
                                   weightKg: Double?) -> Int?
    {
        let parts = exerciseShares(of: workout, store: store)
        let total = parts.reduce(0) { $0 + $1.sets }
        guard let weightKg, let minutes = minutes(of: workout, store: store), total > 0,
              let mine = parts.first(where: { $0.id == entry.id }), mine.sets > 0 else { return nil }
        return estimate(met: mine.met, weightKg: weightKg, minutes: minutes * mine.sets / total)
    }

    struct Share {
        let id: UUID
        let met: Double
        let sets: Double
    }

    @MainActor
    static func exerciseShares(of workout: ObjectRecord, store: ObjectStore) -> [Share] {
        workout.orderedChildren.filter { !$0.isDeleted }.compactMap { entry in
            let sets = Double(entry.orderedChildren.count {
                !$0.isDeleted && store.value("kind", of: $0) != .choice("warmup")
            })
            guard sets > 0 else { return nil }
            let name = store.linkedClass("exercise", of: entry)?.name ?? entry.title
            return Share(id: entry.id, met: MetTable.met(forExercise: name), sets: sets)
        }
    }

    @MainActor
    static func minutes(of workout: ObjectRecord, store: ObjectStore) -> Double? {
        guard let start = store.value("startedAt", of: workout)?.dateValue,
              let end = store.value("endedAt", of: workout)?.dateValue, end > start else { return nil }
        // A workout left open for a day is not a day of effort: nothing over four hours is estimated.
        let minutes = end.timeIntervalSince(start) / 60
        return minutes <= 240 ? minutes : nil
    }
}

/// METs for the exercise library, from the 2024 Adult Compendium: one code and one unchanged MET per exercise.
public enum MetTable {
    /// code -> MET, exactly as the official table prints them.
    public static let metByCode: [String: Double] = [
        "02022": 3.8, "02024": 2.8, "02030": 3.5, "02050": 6.0, "02052": 5.0, "02054": 3.5, "02056": 3.0,
        "02058": 9.8, "17018": 4.5,
    ]
    /// The default for an exercise the table does not name: general resistance training.
    public static let defaultCode = "02054"

    public static func code(forExercise name: String) -> String {
        codeByExercise[name.lowercased()] ?? defaultCode
    }

    public static func met(forExercise name: String) -> Double {
        metByCode[code(forExercise: name)] ?? 3.5
    }

    static let codeByExercise: [String: String] = [
        "bench press": "02050",
        "incline bench press": "02050",
        "close-grip bench press": "02050",
        "dumbbell bench press": "02054",
        "incline dumbbell press": "02054",
        "machine chest press": "02054",
        "push-up": "02022",
        "dip": "02022",
        "cable fly": "02054",
        "pec deck": "02054",
        "overhead press": "02050",
        "seated dumbbell shoulder press": "02054",
        "machine shoulder press": "02054",
        "dumbbell lateral raise": "02054",
        "cable lateral raise": "02054",
        "barbell row": "02050",
        "one-arm dumbbell row": "02054",
        "seated cable row": "02054",
        "chest-supported row": "02054",
        "t-bar row": "02054",
        "face pull": "02054",
        "reverse pec deck": "02054",
        "pull-up": "02022",
        "chin-up": "02022",
        "assisted pull-up": "02054",
        "lat pulldown": "02054",
        "close-grip pulldown": "02054",
        "straight-arm pulldown": "02054",
        "back squat": "02052",
        "front squat": "02052",
        "goblet squat": "02054",
        "hack squat": "02054",
        "leg press": "02054",
        "smith machine squat": "02054",
        "bulgarian split squat": "02054",
        "walking lunge": "02054",
        "reverse lunge": "02054",
        "step-up": "02054",
        "deadlift": "02052",
        "sumo deadlift": "02052",
        "romanian deadlift": "02052",
        "dumbbell romanian deadlift": "02054",
        "good morning": "02054",
        "kettlebell swing": "02058",
        "hip thrust": "02054",
        "back extension": "02030",
        "cable pull-through": "02054",
        "leg extension": "02054",
        "lying leg curl": "02054",
        "seated leg curl": "02054",
        "hip adduction": "02054",
        "hip abduction": "02054",
        "standing calf raise": "02054",
        "seated calf raise": "02054",
        "barbell curl": "02054",
        "dumbbell curl": "02054",
        "hammer curl": "02054",
        "incline dumbbell curl": "02054",
        "preacher curl": "02054",
        "cable curl": "02054",
        "rope pushdown": "02054",
        "overhead cable extension": "02054",
        "skull crusher": "02054",
        "dumbbell overhead extension": "02054",
        "barbell shrug": "02054",
        "dumbbell shrug": "02054",
        "plank": "02024",
        "ab wheel rollout": "02056",
        "hanging leg raise": "02056",
        "cable crunch": "02054",
        "pallof press": "02054",
        "farmer's carry": "17018",
    ]
}
