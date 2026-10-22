import Foundation

/// A ready-made workout: a name, where it is done, how long it takes, and its exercises with sets and reps. Written
/// by Research in our own words. Read-only until someone adds it, which makes a real routine (one undo per step) and
/// adopts the extra exercises it needs.
public struct ReadyWorkout: Sendable, Hashable, Identifiable {
    public enum Group: String, CaseIterable, Sendable {
        case push, pull, legs, fullBody, short

        public var name: String {
            switch self {
            case .push: "Push"
            case .pull: "Pull"
            case .legs: "Legs"
            case .fullBody: "Full body"
            case .short: "Short"
            }
        }
    }

    public enum Level: String, Sendable { case beginner, intermediate }

    public struct Slot: Sendable, Hashable {
        public let exercise: String
        public let sets: Int
        public let repMin: Int
        public let repMax: Int
    }

    /// Research's label, e.g. "W04". Stable.
    public let id: String
    public let title: String
    public let group: Group
    public let place: LibraryExercise.Place
    public let level: Level
    public let minutes: Int
    public let about: String
    public let slots: [Slot]

    /// push, pull or legs when it is one of those days, so the routine keeps its colour.
    public var routineKind: RoutineKind? {
        switch group {
        case .push: .push
        case .pull: .pull
        case .legs: .legs
        case .fullBody, .short: nil
        }
    }

    /// The muscles its exercises work as primary movers, most worked first.
    public var muscles: [MuscleSeed] {
        var counts: [MuscleSeed: Int] = [:]
        for slot in slots {
            for muscle in ReadyWorkouts.details(of: slot.exercise)?.primary ?? [] {
                counts[muscle, default: 0] += slot.sets
            }
        }
        return counts.sorted { $0.value != $1.value ? $0.value > $1.value : $0.key.name < $1.key.name }.map(\.key)
    }

    public var equipment: Set<EquipmentKind> {
        Set(slots.compactMap { ReadyWorkouts.details(of: $0.exercise)?.equipment })
    }
}

public enum ReadyWorkouts {
    public static let all: [ReadyWorkout] = parse()

    public static func workout(id: String) -> ReadyWorkout? {
        all.first { $0.id == id }
    }

    /// Words are a name, a group, a muscle or a kind of equipment ("legs", "biceps", "dumbbells", "home");
    /// `group`, `muscle`, `equipment` and `place` narrow it exactly.
    public static func search(_ text: String = "", group: ReadyWorkout.Group? = nil, muscle: MuscleSeed? = nil,
                              equipment: EquipmentKind? = nil, place: LibraryExercise.Place? = nil) -> [ReadyWorkout]
    {
        let words = text.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
        return all.filter { workout in
            if let group, workout.group != group {
                return false
            }
            if let place, workout.place != place {
                return false
            }
            if let muscle, !workout.muscles.contains(muscle) {
                return false
            }
            if let equipment, !workout.equipment.contains(equipment) {
                return false
            }
            return words.allSatisfy { word in
                workout.title.lowercased().contains(word) || workout.group.name.lowercased().contains(word)
                    || workout.place.rawValue == word
                    || workout.muscles.contains { $0.searchWords.contains(word) }
                    || workout.equipment.contains { $0.searchWords.contains(word) }
            }
        }
    }

    /// What an exercise name stands for: one of the 72 we wrote, else one of the extras.
    static func details(of name: String) -> (primary: [MuscleSeed], equipment: EquipmentKind)? {
        if let seed = seed(named: name) {
            return (seed.primary, seed.equipment)
        }
        return LibraryExtras.exercise(named: name).map { ($0.primary, $0.equipment) }
    }

    static func seed(named name: String) -> ExerciseSeed? {
        let wanted = LibraryExtras.normalised(name)
        return ExerciseLibrary.seeds.first {
            LibraryExtras.normalised($0.name) == wanted || $0.aliases
                .contains { LibraryExtras.normalised($0) == wanted }
        }
    }

    /// The exercise class for a slot: ours is looked up, an extra is adopted now.
    @MainActor
    static func exerciseClass(named name: String, store: ObjectStore,
                              classes: [SystemCatalog.Key: ClassDef]) throws -> ClassDef?
    {
        if let seed = seed(named: name) {
            if seed.key == "benchPress" {
                return classes[.benchPress]
            }
            return store.classDef(id: SystemCatalog.stableID("library.\(seed.key)"))
        }
        guard let extra = LibraryExtras.exercise(named: name) else { return nil }
        return try LibraryAdopter.adopt(extra, store: store, classes: classes)
    }

    /// Makes a routine from the workout with the actions you already have, so each step undoes: a routine, then one
    /// slot per exercise. Returns the routine.
    @MainActor
    @discardableResult
    public static func add(_ workout: ReadyWorkout, using engine: ActionEngine) throws -> ObjectRecord {
        try ExerciseLibraryInstaller.installIfNeeded(store: engine.store, classes: engine.classes)
        let routine: ObjectRecord = try engine.perform(CreateRoutine(
            title: workout.title, kind: workout.routineKind?.rawValue
        ), by: .user).output
        for slot in workout.slots {
            guard let exerciseClass = try exerciseClass(named: slot.exercise, store: engine.store,
                                                        classes: engine.classes) else { continue }
            _ = try engine.perform(AddSlot(routine: routine.id, exercise: exerciseClass.id, sets: Double(slot.sets),
                                           repMin: Double(slot.repMin), repMax: Double(slot.repMax)), by: .user)
        }
        return routine
    }

    private static func parse() -> [ReadyWorkout] {
        LibraryExtras.workoutTable.split(separator: "\n").compactMap { line in
            let parts = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            guard parts.count == 8, let group = ReadyWorkout.Group(rawValue: parts[2]),
                  let place = LibraryExercise.Place(rawValue: parts[3]),
                  let level = ReadyWorkout.Level(rawValue: parts[4]), let minutes = Int(parts[5]) else { return nil }
            let slots: [ReadyWorkout.Slot] = parts[7].split(separator: ";").compactMap { text in
                let fields = text.split(separator: ":").map(String.init)
                guard fields.count == 4, let sets = Int(fields[1]), let low = Int(fields[2]),
                      let high = Int(fields[3]) else { return nil }
                return ReadyWorkout.Slot(exercise: fields[0], sets: sets, repMin: low, repMax: high)
            }
            return ReadyWorkout(id: parts[0], title: parts[1], group: group, place: place, level: level,
                                minutes: minutes, about: parts[6], slots: slots)
        }
    }
}
