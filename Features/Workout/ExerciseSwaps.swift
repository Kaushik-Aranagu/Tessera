import Foundation
import TesseraCore

/// Swap within the movement (docs/product/workouts.md, "Swap within the pattern"): alternatives for an exercise,
/// first the same family, then the same movement pattern, each ranked by primary-muscle overlap and then by
/// whether the gym has the kit. Pattern, family, equipment and muscles come from Core's `ExerciseLibrary` seed
/// matched by name or alias; a class without a seed inherits its nearest ancestor's (Paused Bench → Bench Press),
/// and a class inside another's subtree always counts as the same family.
@MainActor
struct ExerciseSwaps {
    enum Group: Int, Comparable {
        case family, movement

        static func < (lhs: Group, rhs: Group) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        var title: String {
            switch self {
            case .family: "Same family"
            case .movement: "Same movement"
            }
        }
    }

    struct Option: Identifiable, Equatable {
        var id: UUID {
            exercise.id
        }

        let exercise: ClassDef
        let group: Group
        /// The converted load, snapped to what the gym can load for it. Nil when nothing maps.
        let load: Double?
        /// True when the load is a conversion rather than this exercise's own history.
        let isEstimate: Bool
        /// Dumbbells are loaded per hand ("≈ 32 each").
        let isPerHand: Bool

        static func == (lhs: Option, rhs: Option) -> Bool {
            lhs.id == rhs.id && lhs.load == rhs.load && lhs.group == rhs.group
        }
    }

    let store: ObjectStore
    let ledger: TrainingLedger
    /// Every exercise class you could do (system abstractions like Strength Exercise left out).
    let library: [ClassDef]

    /// At most this many rows show (design: four).
    static let limit = 4

    /// Ranked alternatives for `exercise`, loaded from `weight` (the weight on the dial).
    func options(for exercise: ClassDef, from weight: Double, excludingWorkout workoutID: UUID?) -> [Option] {
        let seed = Self.seed(for: exercise)
        let muscles = primaryMuscles(of: exercise, seed: seed)
        let ranked = library.compactMap { candidate -> (Option, Int, Bool)? in
            guard candidate.id != exercise.id else { return nil }
            let other = Self.seed(for: candidate)
            guard let group = Self.group(exercise, seed, candidate, other) else { return nil }
            let overlap = muscles.intersection(primaryMuscles(of: candidate, seed: other)).count
            let hasKit = !store.linkedObjects("equipment", ofClass: candidate).isEmpty
            let option = load(for: candidate, seed: other, from: (seed, weight), group: group,
                              excludingWorkout: workoutID)
            return (option, overlap, hasKit)
        }
        return ranked.sorted { lhs, rhs in
            if lhs.0.group != rhs.0.group {
                return lhs.0.group < rhs.0.group
            }
            if lhs.1 != rhs.1 {
                return lhs.1 > rhs.1
            }
            if lhs.2 != rhs.2 {
                return lhs.2
            }
            return lhs.0.exercise.name < rhs.0.exercise.name
        }
        .prefix(Self.limit)
        .map(\.0)
    }

    // MARK: Grouping

    private static func group(_ exercise: ClassDef, _ seed: ExerciseSeed?, _ candidate: ClassDef,
                              _ other: ExerciseSeed?) -> Group?
    {
        if ClassResolver.isSubclass(candidate, of: exercise) || ClassResolver.isSubclass(exercise, of: candidate) {
            return .family
        }
        guard let seed, let other else { return nil }
        if let family = seed.family, family == other.family {
            return .family
        }
        return seed.pattern == other.pattern ? .movement : nil
    }

    /// The library seed for a class: by name or alias, else the nearest ancestor's.
    static func seed(for exercise: ClassDef) -> ExerciseSeed? {
        for classDef in ClassResolver.lineage(of: exercise).reversed() {
            let name = classDef.name.lowercased()
            if let seed = ExerciseLibrary.seeds.first(where: { seed in
                seed.name.lowercased() == name || seed.aliases.contains { $0.lowercased() == name }
            }) {
                return seed
            }
        }
        return nil
    }

    private func primaryMuscles(of exercise: ClassDef, seed: ExerciseSeed?) -> Set<String> {
        let linked = store.linkedObjects("primaryMuscles", ofClass: exercise).map { $0.title.lowercased() }
        if !linked.isEmpty {
            return Set(linked)
        }
        return Set(seed?.primary.map { $0.name.lowercased() } ?? [])
    }

    // MARK: Loads

    /// `from` is the exercise being replaced: its seed and the weight on the dial.
    private func load(for candidate: ClassDef, seed: ExerciseSeed?, from: (seed: ExerciseSeed?, weight: Double),
                      group: Group, excludingWorkout workoutID: UUID?) -> Option
    {
        let (fromSeed, weight) = from
        let isPerHand = seed?.equipment == .dumbbell || seed?.equipment == .kettlebell
        // Its own history beats any conversion.
        let target = ledger.nextTarget(for: candidate, excludingWorkout: workoutID)
        if let own = target.weight {
            return Option(exercise: candidate, group: group, load: own, isEstimate: false, isPerHand: isPerHand)
        }
        guard weight > 0 else {
            return Option(exercise: candidate, group: group, load: nil, isEstimate: true, isPerHand: isPerHand)
        }
        let ratio = Self.ratio(from: fromSeed, to: seed, group: group)
        let snapped = store.loadProfile(for: candidate).nearest(to: weight * ratio)
        return Option(exercise: candidate, group: group, load: snapped, isEstimate: true, isPerHand: isPerHand)
    }

    /// A rough load mapping between equipment and mechanics. Every converted load is shown with "≈".
    static func ratio(from source: ExerciseSeed?, to target: ExerciseSeed?, group: Group) -> Double {
        let from = source?.equipment ?? .barbell
        let into = target?.equipment ?? from
        var ratio: Double = switch (from.isPerHand, into.isPerHand) {
        case (false, true): 0.4
        case (true, false): 2.5
        default: 1
        }
        if from != into, !from.isPerHand, !into.isPerHand {
            ratio *= into == .machine ? 0.9 : 0.8
        }
        if source?.mechanic == .compound, target?.mechanic == .isolation {
            ratio *= 0.3
        } else if group == .family, from == into {
            // A variant of the same lift on the same kit (paused, incline, close grip) runs a little lighter.
            ratio *= 0.9
        }
        return ratio
    }
}

private extension EquipmentKind {
    var isPerHand: Bool {
        self == .dumbbell || self == .kettlebell
    }
}

// MARK: - The action

/// Swaps an exercise entry for today only: the routine's slot, scheme and rule stay as they are.
/// - Nothing logged yet: the entry is relinked to the new exercise, with the converted target weight.
/// - Some sets logged: those stay with the old exercise (its entry now plans only what's done) and a new entry
///   carries the remaining sets, linked to the same slot.
///
/// Lives in the app for now; it belongs in Core's `TrainingActions` and `ActionRegistry` so Tess and intents can
/// call it ("swap to dumbbell press").
struct SwapExercise: EngineAction {
    static let descriptor = ActionDescriptor(
        name: "swapExercise",
        summary: "Swap an exercise in a workout for today, keeping its slot and scheme",
        parameters: [
            .init("entry", .object, "The exercise entry to swap"),
            .init("exercise", .classRef, "The exercise to do instead"),
            .init("targetWeight", .number, "Starting weight in kilograms", required: false),
        ]
    )

    var entry: UUID
    var exercise: UUID
    var targetWeight: Double?

    /// The entry that now carries the swapped exercise.
    func apply(_ transaction: inout Transaction) throws -> UUID {
        let entry = try transaction.object(entry, is: .exerciseEntry)
        guard let replacement = transaction.store.classDef(id: exercise) else {
            throw ActionError.objectNotFound(exercise)
        }
        guard try ClassResolver.isSubclass(replacement, of: transaction.classDef(.exercise)) else {
            throw ActionError.wrongClass(exercise, expected: SystemCatalog.Key.exercise.rawValue)
        }
        let logged = entry.orderedChildren.count
        guard logged > 0 else {
            try transaction.setClassLink("exercise", on: entry, to: replacement)
            try transaction.set("targetWeight", to: targetWeight.map(FieldValue.mass), on: entry)
            return entry.id
        }
        guard let workout = entry.parent else { throw ActionError.objectNotFound(self.entry) }
        let planned = transaction.store.number("targetSets", of: entry) ?? Double(logged)
        let remaining = max(planned - Double(logged), 1)
        let swapped = try transaction.create(transaction.classDef(.exerciseEntry), parent: workout)
        try transaction.setClassLink("exercise", on: swapped, to: replacement)
        try transaction.set("targetSets", to: .number(remaining), on: swapped)
        try transaction.set("targetReps", to: transaction.store.value("targetReps", of: entry), on: swapped)
        try transaction.set("targetWeight", to: targetWeight.map(FieldValue.mass), on: swapped)
        let slot = transaction.store.linkedObjects("slot", of: entry)
        if !slot.isEmpty {
            try transaction.setLinks("slot", on: swapped, to: slot)
        }
        try transaction.set("targetSets", to: .number(Double(logged)), on: entry)
        return swapped.id
    }

    func summary(in store: ObjectStore) -> String {
        "Swapped for \(store.classDef(id: exercise)?.name.lowercased() ?? "another exercise") today"
    }
}
