import CryptoKit
import Foundation
import SwiftData

/// Built-in classes every install starts with. Seeding is idempotent, and system classes and fields
/// get deterministic ids derived from their keys, so separate devices seed identical ids before CloudKit
/// sync merges them.
@MainActor
enum SystemCatalog {
    enum Key: String, CaseIterable {
        case thing, activity, exercise, strengthExercise, barbellLift, benchPress
        case muscle, equipment
        case workout, exerciseEntry, set
        case routine, task, note

        var systemKey: String {
            "system.\(rawValue)"
        }
    }

    private struct FieldSpec {
        var key: String
        var name: String
        var kind: FieldKind
        var unit: String?
        var defaultValue: FieldValue?
        var target: Key?
        var options: [String] = []
        var expression: String?
        /// Overrides the default of an inherited field with this key instead of declaring a new one.
        var overrides: String?
    }

    private struct ClassSpec {
        var key: Key
        var name: String
        var parent: Key?
        var symbol: String
        var colorRole: String
        var traits: [ClassTrait] = []
        var fields: [FieldSpec] = []
    }

    /// Order matters: parents before children, link targets before fields that use them.
    private static let specs: [ClassSpec] = [
        ClassSpec(key: .thing, name: "Thing", symbol: "circle", colorRole: "neutral", fields: [
            FieldSpec(key: "notes", name: "Notes", kind: .richText),
        ]),
        ClassSpec(key: .muscle, name: "Muscle", parent: .thing, symbol: "figure.arms.open", colorRole: "training"),
        ClassSpec(key: .equipment, name: "Equipment", parent: .thing, symbol: "dumbbell", colorRole: "training"),
        ClassSpec(key: .activity, name: "Activity", parent: .thing, symbol: "figure.walk", colorRole: "training"),
        ClassSpec(key: .exercise, name: "Exercise", parent: .activity, symbol: "figure.strengthtraining.traditional",
                  colorRole: "training", fields: [
                      FieldSpec(key: "primaryMuscles", name: "Primary muscles", kind: .refList, target: .muscle),
                      FieldSpec(key: "equipment", name: "Equipment", kind: .refList, target: .equipment),
                      FieldSpec(
                          key: "restSeconds",
                          name: "Rest",
                          kind: .duration,
                          unit: "s",
                          defaultValue: .duration(90)
                      ),
                  ]),
        ClassSpec(key: .strengthExercise, name: "Strength Exercise", parent: .exercise,
                  symbol: "figure.strengthtraining.traditional", colorRole: "training", traits: [.measurable], fields: [
                      FieldSpec(key: "restSeconds", name: "Rest", kind: .duration, defaultValue: .duration(120),
                                overrides: "restSeconds"),
                  ]),
        ClassSpec(key: .barbellLift, name: "Barbell Lift", parent: .strengthExercise, symbol: "dumbbell",
                  colorRole: "training", fields: [
                      FieldSpec(key: "restSeconds", name: "Rest", kind: .duration, defaultValue: .duration(180),
                                overrides: "restSeconds"),
                  ]),
        ClassSpec(
            key: .benchPress,
            name: "Bench Press",
            parent: .barbellLift,
            symbol: "dumbbell",
            colorRole: "training"
        ),
        ClassSpec(key: .workout, name: "Workout", parent: .activity, symbol: "figure.run", colorRole: "training",
                  traits: [.schedulable, .timed], fields: [
                      FieldSpec(key: "startedAt", name: "Started", kind: .date),
                      FieldSpec(key: "endedAt", name: "Ended", kind: .date),
                  ]),
        ClassSpec(key: .exerciseEntry, name: "Exercise Entry", parent: .thing, symbol: "list.bullet",
                  colorRole: "training", fields: [
                      FieldSpec(key: "exercise", name: "Exercise", kind: .classRef, target: .exercise),
                  ]),
        ClassSpec(key: .set, name: "Set", parent: .thing, symbol: "number", colorRole: "training",
                  traits: [.trackable, .measurable], fields: [
                      FieldSpec(key: "weight", name: "Weight", kind: .mass, unit: "kg"),
                      FieldSpec(key: "reps", name: "Reps", kind: .number),
                      FieldSpec(key: "rpe", name: "RPE", kind: .number),
                      FieldSpec(key: "isWarmup", name: "Warm-up", kind: .bool, defaultValue: .bool(false)),
                      FieldSpec(key: "e1rm", name: "Estimated 1RM", kind: .computed, unit: "kg",
                                expression: "weight * (1 + reps / 30)"),
                  ]),
        ClassSpec(key: .routine, name: "Plan", parent: .thing, symbol: "calendar", colorRole: "planning",
                  traits: [.schedulable], fields: [
                      FieldSpec(key: "cadence", name: "Cadence", kind: .choice, defaultValue: .choice("week"),
                                options: ["day", "week", "month"]),
                  ]),
        ClassSpec(key: .task, name: "Task", parent: .thing, symbol: "checkmark.circle", colorRole: "planning",
                  traits: [.schedulable], fields: [
                      FieldSpec(key: "due", name: "Due", kind: .date),
                      FieldSpec(key: "isDone", name: "Done", kind: .bool, defaultValue: .bool(false)),
                  ]),
        ClassSpec(key: .note, name: "Note", parent: .thing, symbol: "note.text", colorRole: "neutral"),
    ]

    /// Inserts any missing system classes and returns all of them by key.
    @discardableResult
    static func seed(in context: ModelContext) throws -> [Key: ClassDef] {
        var classes = try existing(in: context)
        for spec in specs where classes[spec.key] == nil {
            let classDef = ClassDef(
                name: spec.name,
                parent: spec.parent.flatMap { classes[$0] },
                symbolName: spec.symbol,
                colorRole: spec.colorRole,
                traits: spec.traits,
                systemKey: spec.key.systemKey
            )
            classDef.id = stableID(spec.key.systemKey)
            context.insert(classDef)
            for (index, fieldSpec) in spec.fields.enumerated() {
                let field = FieldDef(
                    name: fieldSpec.name,
                    key: fieldSpec.key,
                    kind: fieldSpec.kind,
                    sortIndex: index,
                    unit: fieldSpec.unit,
                    defaultValue: fieldSpec.defaultValue
                )
                field.id = stableID("\(spec.key.systemKey).\(fieldSpec.key)")
                field.enumOptions = fieldSpec.options
                field.expression = fieldSpec.expression
                field.targetClassID = fieldSpec.target.map { stableID($0.systemKey) }
                if let overridden = fieldSpec.overrides,
                   let parent = classDef.parent,
                   let inherited = ClassResolver.field(overridden, of: parent)
                {
                    field.overridesFieldID = inherited.id
                }
                field.owner = classDef
                context.insert(field)
            }
            classes[spec.key] = classDef
        }
        try context.save()
        return classes
    }

    static func existing(in context: ModelContext) throws -> [Key: ClassDef] {
        let all = try context.fetch(FetchDescriptor<ClassDef>(predicate: #Predicate { $0.systemKey != nil }))
        var result: [Key: ClassDef] = [:]
        for classDef in all {
            guard let key = Key.allCases.first(where: { $0.systemKey == classDef.systemKey }) else { continue }
            // Keep the oldest if CloudKit sync ever produced a duplicate.
            if let current = result[key], current.createdAt <= classDef.createdAt {
                continue
            }
            result[key] = classDef
        }
        return result
    }

    /// Deterministic UUID from a string (SHA-256, formatted as an RFC 4122 v5-style UUID).
    static func stableID(_ name: String) -> UUID {
        // The "tessera:" salt is part of every system id — never change it.
        var bytes = Array(SHA256.hash(data: Data("tessera:\(name)".utf8)).prefix(16))
        bytes[6] = (bytes[6] & 0x0F) | 0x50
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }
}
