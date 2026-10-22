import Foundation

/// Turns a library exercise into a real exercise class the first time it is needed (edited, logged, put in a
/// routine). Until then the entry stays read-only and costs nothing in the database. The class id comes from the
/// library id, so adopting twice gives the same class, on every device.
@MainActor
public enum LibraryAdopter {
    public static let packageID = "libraryExtras"

    public static func classID(for exercise: LibraryExercise) -> UUID {
        SystemCatalog.stableID("libraryExtra.\(exercise.id)")
    }

    /// The copy, if one was made.
    public static func adoptedClass(of exercise: LibraryExercise, store: ObjectStore) -> ClassDef? {
        store.classDef(id: classID(for: exercise))
    }

    /// Where it sits in the movement spine.
    static func pattern(for exercise: LibraryExercise) -> MovementPattern {
        let name = exercise.name.lowercased()
        if name.contains("lunge") {
            return .lunge
        }
        guard let lead = exercise.primary.first else { return .isolation }
        if lead == .abs || lead == .obliques {
            return .core
        }
        if exercise.mechanic == .isolation {
            return .isolation
        }
        return movements[lead] ?? .isolation
    }

    private static let movements: [MuscleSeed: MovementPattern] = [
        .chest: .horizontalPush, .frontDelts: .verticalPush, .sideDelts: .verticalPush, .triceps: .verticalPush,
        .lats: .verticalPull, .upperBack: .horizontalPull, .rearDelts: .horizontalPull, .quads: .squat,
        .glutes: .hinge, .hamstrings: .hinge, .lowerBack: .hinge,
    ]

    static func logType(for exercise: LibraryExercise) -> LogType {
        if exercise.name.lowercased().contains("plank") {
            return .duration
        }
        guard exercise.equipment == .bodyweight else { return .weightReps }
        let lead = exercise.primary.first
        return lead == .abs || lead == .obliques ? .repsOnly : .bodyweightPlus
    }

    /// Makes (or finds) the class. Idempotent.
    @discardableResult
    public static func adopt(_ exercise: LibraryExercise, store: ObjectStore,
                             classes: [SystemCatalog.Key: ClassDef]) throws -> ClassDef
    {
        if let existing = adoptedClass(of: exercise, store: store) {
            return existing
        }
        guard let strength = classes[.strengthExercise] else { throw ObjectStore.StoreError.unknownField("exercise") }
        let pattern = pattern(for: exercise)
        let parent = store.classDef(id: SystemCatalog.stableID("library.pattern.\(pattern.rawValue)")) ?? strength
        let classDef = store.createClass(name: exercise.name, parent: parent,
                                         symbolName: ExerciseLibraryInstaller.symbol(for: exercise.equipment),
                                         colorRole: "training", id: classID(for: exercise))
        classDef.traitsRaw.append(EquipmentTrait.raw(exercise.equipment))
        classDef.packageID = packageID

        let profile = store.ensureClassObject(of: classDef)
        let logType = logType(for: exercise)
        let isolation = exercise.mechanic == .isolation
        let reps: ClosedRange<Double> = logType == .duration ? 30 ... 60 : (isolation ? 10 ... 15 : 6 ... 10)
        try store.set("repMin", to: .number(reps.lowerBound), on: profile)
        try store.set("repMax", to: .number(reps.upperBound), on: profile)
        try store.set("restSeconds", to: .duration(logType == .duration ? 60 : (isolation ? 75 : 120)), on: profile)
        try store.set("pattern", to: .choice(pattern.rawValue), on: profile)
        try store.set("mechanic", to: .choice(exercise.mechanic.rawValue), on: profile)
        try store.set("logType", to: .choice(logType.rawValue), on: profile)
        try store.set("notes", to: .richText(exercise.cue), on: profile)

        let muscles = try MuscleLibrary.install(store: store, classes: classes)
        try store.setLinks("primaryMuscles", on: profile, to: exercise.primary.compactMap { muscles[$0] })
        try store.setLinks("secondaryMuscles", on: profile, to: exercise.secondary.compactMap { muscles[$0] })
        if let equipmentClass = classes[.equipment],
           let object = store.objects(of: equipmentClass).first(where: {
               store.value("kind", of: $0)?.stringValue == exercise.equipment.rawValue
           })
        {
            try store.setLinks("equipment", on: profile, to: [object])
        }
        store.invalidateCaches()
        return classDef
    }
}
