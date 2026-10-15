import Foundation

/// Equipment as a trait: a class carries `equipment.barbell` (and optionally `unilateral`) in its traits,
/// inherited like any trait. Plate math, increments and the default progression come from it through
/// `loadProfile(for:)` and `ProgressionRule.default(for:)`, so callers never care where the kind came from.
public enum EquipmentTrait {
    public static let prefix = "equipment."
    public static let unilateral = "unilateral"

    public static func raw(_ kind: EquipmentKind) -> String {
        prefix + kind.rawValue
    }
}

public extension ObjectStore {
    /// An exercise someone can log, as opposed to a grouping class (Exercise, Strength Exercise, Barbell Lift,
    /// or a movement pattern or group from the library).
    func isConcreteExercise(_ classDef: ClassDef, root: ClassDef?) -> Bool {
        guard let root, classDef.id != root.id, isSubclass(classDef, ofClassID: root.id) else { return false }
        let key = classDef.systemKey ?? ""
        let groupings = ["system.exercise", "system.activity", "system.strengthExercise", "system.barbellLift"]
        return !groupings.contains(key) && !key.hasPrefix("library.pattern.") && !key.hasPrefix("library.group.")
    }

    /// The nearest equipment trait up the class's lineage.
    func equipmentKind(of classDef: ClassDef) -> EquipmentKind? {
        for node in lineage(of: classDef).reversed() {
            for raw in node.traitsRaw where raw.hasPrefix(EquipmentTrait.prefix) {
                if let kind = EquipmentKind(rawValue: String(raw.dropFirst(EquipmentTrait.prefix.count))) {
                    return kind
                }
            }
        }
        return nil
    }
}
