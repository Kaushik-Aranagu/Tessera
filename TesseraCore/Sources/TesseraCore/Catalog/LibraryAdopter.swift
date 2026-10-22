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
        try adopt(exercise, store: store, classes: classes, afterCreate: nil)
    }

    /// `afterCreate` runs once the class exists and before it is filled in; a test throws from it to prove a failure
    /// midway leaves nothing behind.
    static func adopt(_ exercise: LibraryExercise, store: ObjectStore, classes: [SystemCatalog.Key: ClassDef],
                      afterCreate: (() throws -> Void)?) throws -> ClassDef
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

        do {
            try afterCreate?()
            let profile = store.ensureClassObject(of: classDef)
            for (key, value) in profileValues(for: exercise) {
                try store.set(key, to: value, on: profile)
            }

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
        } catch {
            discard(classDef, store: store)
            throw error
        }
        store.invalidateCaches()
        return classDef
    }

    /// What a fresh copy carries on its class object; also what "never edited" means.
    static func profileValues(for exercise: LibraryExercise) -> [(String, FieldValue)] {
        let logType = logType(for: exercise)
        let isolation = exercise.mechanic == .isolation
        let reps: ClosedRange<Double> = logType == .duration ? 30 ... 60 : (isolation ? 10 ... 15 : 6 ... 10)
        return [
            ("repMin", .number(reps.lowerBound)), ("repMax", .number(reps.upperBound)),
            ("restSeconds", .duration(logType == .duration ? 60 : (isolation ? 75 : 120))),
            ("pattern", .choice(pattern(for: exercise).rawValue)), ("mechanic", .choice(exercise.mechanic.rawValue)),
            ("logType", .choice(logType.rawValue)), ("notes", .richText(exercise.cue)),
        ]
    }

    /// Whether anyone changed the copy: its name, its numbers, notes or muscles. An edited copy is his, so it is never
    /// cleaned up even when nothing uses it yet.
    static func isEdited(_ classDef: ClassDef, store: ObjectStore) -> Bool {
        guard let exercise = LibraryExtras.all.first(where: { classID(for: $0) == classDef.id }) else { return true }
        guard classDef.name == exercise.name, let profile = store.classObject(of: classDef) else { return true }
        for (key, value) in profileValues(for: exercise) where store.value(key, of: profile) != value {
            return true
        }
        let primary = store.linkedObjects("primaryMuscles", of: profile).map(\.title)
        let secondary = store.linkedObjects("secondaryMuscles", of: profile).map(\.title)
        return primary != exercise.primary.map(\.name) || secondary != exercise.secondary.map(\.name)
    }

    /// Takes back a class that was started and not finished, so a failure never leaves half an exercise behind.
    private static func discard(_ classDef: ClassDef, store: ObjectStore) {
        if let profile = store.classObject(of: classDef) {
            store.context.delete(profile)
        }
        store.context.delete(classDef)
        store.invalidateCaches()
    }

    /// Removes adopted copies nothing uses any more (a workout was undone before anything was logged). A copy that a
    /// routine, a set or a link still points at stays, and so does one that was edited. Returns how many were removed.
    /// Adopting and removing a copy are both outside the op log on purpose: a copy is rebuilt from read-only library
    /// data with a stable id, so replay and sync never need to know it was made or taken back.
    @discardableResult
    public static func removeUnused(store: ObjectStore) -> Int {
        var removed = 0
        for classDef in store.allClasses() where classDef.packageID == packageID {
            let used = (classDef.incomingLinks ?? []).isEmpty == false
                || (classDef.subclasses ?? []).isEmpty == false
                || (classDef.objects ?? []).contains { !$0.isClassObject }
            if !used, !isEdited(classDef, store: store) {
                discard(classDef, store: store)
                removed += 1
            }
        }
        return removed
    }
}
