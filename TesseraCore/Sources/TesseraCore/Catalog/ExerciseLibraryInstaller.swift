import Foundation
import SwiftData

/// Installs `ExerciseLibrary` as exercise classes. Waiting on Kaushik's class-tree decision; both shapes are here
/// so switching is one argument.
///
/// - `.patternSpine` (recommended): Exercise > Strength Exercise > movement pattern (Horizontal Push, Hinge…)
///   > group for isolation and core moves (Curl, Lateral Raise…) > the exercise. Equipment is a trait
///   (`equipment.barbell`), so a barbell, dumbbell or machine bench press all sit under Horizontal Push and swap
///   within it. Bench Press moves from Barbell Lift to Horizontal Push.
/// - `.equipmentClasses` (today's shape): barbell lifts under Barbell Lift, everything else under Strength Exercise.
///   Equipment is still recorded as a trait, so plate math and progression work the same either way.
///
/// Variants (Incline DB Press → DB Bench Press) are their own classes linked by `variantOf`, never subclasses,
/// so their records stay separate. Installing is idempotent: ids derive from seed keys.
@MainActor
public enum ExerciseLibraryInstaller {
    public enum Shape: String, Sendable, CaseIterable {
        case patternSpine
        case equipmentClasses
    }

    public static let package = CatalogPackage(id: "library", version: 1, name: "Tessera exercise library",
                                               source: "Written by Tessera in its own words", license: "Tessera")

    /// Kaushik's pick (2026-10-15): the movement-pattern spine with equipment as a trait.
    public static let chosenShape = Shape.patternSpine

    /// Installs the library once per package version; cheap to call on every launch.
    @discardableResult
    public static func installIfNeeded(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) throws -> Bool {
        let marker = SystemCatalog.stableID("library.pattern.\(MovementPattern.horizontalPush.rawValue)")
        if let installed = store.classDef(id: marker), installed.packageVersion >= package.version,
           classes[.benchPress]?.parent?.id == marker
        {
            return false
        }
        try install(shape: chosenShape, store: store, classes: classes)
        return true
    }

    @discardableResult
    public static func install(shape: Shape, store: ObjectStore,
                               classes: [SystemCatalog.Key: ClassDef]) throws -> [String: ClassDef]
    {
        guard let strength = classes[.strengthExercise], let lift = classes[.barbellLift] else { return [:] }
        let muscles = try MuscleLibrary.install(store: store, classes: classes)
        let equipment = try installEquipment(store: store, classes: classes)
        var installed: [String: ClassDef] = [:]

        for seed in ExerciseLibrary.seeds {
            let parent: ClassDef = switch shape {
            case .patternSpine: try groupClass(for: seed, under: strength, store: store)
            case .equipmentClasses: seed.equipment == .barbell ? lift : strength
            }
            let classDef: ClassDef
            if seed.key == "benchPress", let bench = classes[.benchPress] {
                classDef = bench
            } else if let existing = store.classDef(id: SystemCatalog.stableID("library.\(seed.key)")) {
                classDef = existing
            } else {
                classDef = ClassDef(name: seed.name, symbolName: symbol(for: seed.equipment), colorRole: "training",
                                    systemKey: "library.\(seed.key)")
                classDef.id = SystemCatalog.stableID("library.\(seed.key)")
                store.context.insert(classDef)
            }
            classDef.parent = parent
            var traits = classDef.traitsRaw
                .filter { !$0.hasPrefix(EquipmentTrait.prefix) && $0 != EquipmentTrait.unilateral }
            traits.append(EquipmentTrait.raw(seed.equipment))
            if seed.isUnilateral {
                traits.append(EquipmentTrait.unilateral)
            }
            classDef.traitsRaw = traits
            classDef.packageID = classDef.packageID ?? package.id
            installed[seed.key] = classDef

            let profile = store.ensureClassObject(of: classDef)
            try store.set("repMin", to: .number(Double(seed.repRange.lowerBound)), on: profile)
            try store.set("repMax", to: .number(Double(seed.repRange.upperBound)), on: profile)
            try store.set("restSeconds", to: .duration(Double(seed.restSeconds)), on: profile)
            try store.set("pattern", to: .choice(seed.pattern.rawValue), on: profile)
            try store.set("family", to: seed.family.map(FieldValue.text), on: profile)
            try store.set("mechanic", to: .choice(seed.mechanic.rawValue), on: profile)
            try store.set("logType", to: .choice(seed.logType.rawValue), on: profile)
            try store.set("aliases", to: seed.aliases.isEmpty ? nil : .text(seed.aliases.joined(separator: ", ")),
                          on: profile)
            if store.value("notes", of: profile) == nil {
                try store.set("notes", to: .richText(seed.cue), on: profile)
            }
            try store.setLinks("primaryMuscles", on: profile, to: seed.primary.compactMap { muscles[$0] })
            try store.setLinks("secondaryMuscles", on: profile, to: seed.secondary.compactMap { muscles[$0] })
            try store.setLinks("equipment", on: profile, to: equipment[seed.equipment].map { [$0] } ?? [])
        }
        for seed in ExerciseLibrary.seeds {
            guard let classDef = installed[seed.key],
                  let base = seed.variantOf.flatMap({ installed[$0] }) else { continue }
            try store.setClassLink("variantOf", on: store.ensureClassObject(of: classDef), to: base)
        }
        store.invalidateCaches()
        return installed
    }

    /// The pattern class (and, for isolation and core moves, the group class under it).
    private static func groupClass(for seed: ExerciseSeed, under strength: ClassDef,
                                   store: ObjectStore) throws -> ClassDef
    {
        let pattern = spineClass(key: "pattern.\(seed.pattern.rawValue)", name: title(seed.pattern.rawValue),
                                 parent: strength, store: store)
        try store.set("pattern", to: .choice(seed.pattern.rawValue), on: store.ensureClassObject(of: pattern))
        // Families (Bench Press, Row, Deadlift…) are recorded on each exercise, not made into classes: a family
        // class named "Bench Press" would clash with the lift itself, and swaps rank by family anyway.
        guard seed.family == nil, let group = seed.group else { return pattern }
        return spineClass(key: "group.\(group)", name: title(group), parent: pattern, store: store)
    }

    private static func spineClass(key: String, name: String, parent: ClassDef, store: ObjectStore) -> ClassDef {
        let id = SystemCatalog.stableID("library.\(key)")
        if let existing = store.classDef(id: id) {
            return existing
        }
        let classDef = ClassDef(name: name, parent: nil, symbolName: "figure.strengthtraining.traditional",
                                colorRole: "training", systemKey: "library.\(key)")
        classDef.id = id
        classDef.packageID = package.id
        classDef.packageVersion = package.version
        store.context.insert(classDef)
        classDef.parent = parent
        return classDef
    }

    /// One Equipment object per kind, so exercises can link to it and the gym's plates can be edited in one place.
    private static func installEquipment(store: ObjectStore,
                                         classes: [SystemCatalog.Key: ClassDef]) throws -> [EquipmentKind: ObjectRecord]
    {
        guard let equipmentClass = classes[.equipment] else { return [:] }
        var existing: [String: ObjectRecord] = [:]
        for object in store.objects(of: equipmentClass) {
            if let kind = store.value("kind", of: object)?.stringValue {
                existing[kind] = object
            }
        }
        var result: [EquipmentKind: ObjectRecord] = [:]
        for kind in EquipmentKind.allCases {
            let object = existing[kind.rawValue] ?? store.create(equipmentClass, title: equipmentName(kind))
            if store.value("kind", of: object) == nil {
                try store.set("kind", to: .choice(kind.rawValue), on: object)
            }
            result[kind] = object
        }
        return result
    }

    static func equipmentName(_ kind: EquipmentKind) -> String {
        switch kind {
        case .barbell: "Barbell"
        case .dumbbell: "Dumbbells"
        case .ezBar: "EZ Bar"
        case .cable: "Cable Stack"
        case .machine: "Machine"
        case .smith: "Smith Machine"
        case .kettlebell: "Kettlebells"
        case .bodyweight: "Bodyweight"
        case .band: "Bands"
        }
    }

    static func symbol(for kind: EquipmentKind) -> String {
        switch kind {
        case .barbell, .ezBar, .smith, .dumbbell, .kettlebell: "dumbbell"
        case .cable, .machine: "figure.strengthtraining.functional"
        case .bodyweight, .band: "figure.core.training"
        }
    }

    /// "horizontalPush" → "Horizontal Push", "LateralRaise" → "Lateral Raise".
    static func title(_ camel: String) -> String {
        var words: [String] = []
        var current = ""
        for character in camel {
            if character.isUppercase, !current.isEmpty {
                words.append(current)
                current = ""
            }
            current.append(character)
        }
        words.append(current)
        return words.map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined(separator: " ")
    }
}
