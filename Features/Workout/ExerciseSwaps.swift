import Foundation
import TesseraCore

/// Swap within the movement (docs/product/workouts.md, "Swap within the pattern"). The ranking is Core's
/// `TrainingLedger.swapCandidates(for:limit:)`: same family first, then same movement pattern, by primary-muscle
/// overlap. On top of it this adds what the panel shows: the group heading, and a starting load for each, the
/// exercise's own next target when it has history, else a conversion from the dialled weight (marked "≈").
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

    @MainActor
    struct Option: @MainActor Identifiable, @MainActor Equatable {
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

    /// At most this many rows show (design: four).
    static let limit = 4

    /// Ranked alternatives for `exercise`, loaded from `weight` (the weight on the dial).
    func options(for exercise: ClassDef, from weight: Double, excludingWorkout workoutID: UUID?) -> [Option] {
        let familyName = store.classValue("family", of: exercise)?.stringValue
        let ranked = ledger.swapCandidates(for: exercise, limit: Self.limit * 2).map { candidate in
            let sameFamily = familyName != nil
                && store.classValue("family", of: candidate)?.stringValue == familyName
            return (candidate, sameFamily ? Group.family : .movement)
        }
        // Core ranks the family first; keep one row for the best of the wider movement when there is one, so
        // a taken bench can still swap for something off the bench.
        let movement = ranked.filter { $0.1 == .movement }.prefix(1)
        let family = ranked.filter { $0.1 == .family }.prefix(Self.limit - movement.count)
        return (family + movement).map { candidate, group in
            load(for: candidate, replacing: (exercise, weight), group: group, excludingWorkout: workoutID)
        }
    }

    /// Whether an exercise is loaded per hand (dumbbells, kettlebells).
    static func isPerHand(_ exercise: ClassDef, store: ObjectStore) -> Bool {
        store.equipmentKind(of: exercise)?.isPerHand ?? false
    }

    // MARK: Loads

    /// `replacing` is the exercise being swapped out and the weight on its dial.
    private func load(for candidate: ClassDef, replacing: (exercise: ClassDef, weight: Double), group: Group,
                      excludingWorkout workoutID: UUID?) -> Option
    {
        let isPerHand = Self.isPerHand(candidate, store: store)
        // Its own history beats any conversion.
        if let own = ledger.nextTarget(for: candidate, excludingWorkout: workoutID).weight {
            return Option(exercise: candidate, group: group, load: own, isEstimate: false, isPerHand: isPerHand)
        }
        guard replacing.weight > 0 else {
            return Option(exercise: candidate, group: group, load: nil, isEstimate: true, isPerHand: isPerHand)
        }
        let ratio = Self.ratio(
            from: (store.equipmentKind(of: replacing.exercise), mechanic(of: replacing.exercise)),
            into: (store.equipmentKind(of: candidate), mechanic(of: candidate)),
            group: group
        )
        let snapped = store.loadProfile(for: candidate).nearest(to: replacing.weight * ratio)
        return Option(exercise: candidate, group: group, load: snapped, isEstimate: true, isPerHand: isPerHand)
    }

    private func mechanic(of exercise: ClassDef) -> Mechanic? {
        store.classValue("mechanic", of: exercise)?.stringValue.flatMap(Mechanic.init(rawValue:))
    }

    /// A rough load mapping between equipment and mechanics (Core has no conversion data yet). Every converted
    /// load is shown with "≈".
    static func ratio(from source: (EquipmentKind?, Mechanic?), into target: (EquipmentKind?, Mechanic?),
                      group: Group) -> Double
    {
        let from = source.0 ?? .barbell
        let into = target.0 ?? from
        var ratio: Double = switch (from.isPerHand, into.isPerHand) {
        case (false, true): 0.4
        case (true, false): 2.5
        default: 1
        }
        if from != into, !from.isPerHand, !into.isPerHand {
            ratio *= into == .machine ? 0.9 : 0.8
        }
        if source.1 == .compound, target.1 == .isolation {
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
