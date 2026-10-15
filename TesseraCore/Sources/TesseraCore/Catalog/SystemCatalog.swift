import CryptoKit
import Foundation

/// Built-in classes every install starts with. Seeding is idempotent, and system classes and fields
/// get deterministic ids derived from their keys, so separate devices seed identical `id`s.
/// CloudKit does not merge records by our `id`, though: two devices that both seed will sync two copies.
/// A dedupe pass by `systemKey` / field id must run before sync is switched on (see docs/engine/research-01.md).
@MainActor
// The catalog is mostly declarative class specs; their length is the point.
// swiftlint:disable:next type_body_length
public enum SystemCatalog {
    public enum Key: String, CaseIterable, Sendable {
        case thing, activity, exercise, strengthExercise, barbellLift, benchPress
        case muscle, equipment
        case workout, exerciseEntry, set
        case routine, task, note
        case list, listItem
        case ingredient
        case process
        case slot, plan

        public var systemKey: String {
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
        ClassSpec(key: .muscle, name: "Muscle", parent: .thing, symbol: "figure.arms.open", colorRole: "training",
                  traits: [.measurable], fields: [
                      FieldSpec(key: "group", name: "Group", kind: .text),
                      FieldSpec(
                          key: "weeklySetsMin",
                          name: "Weekly sets from",
                          kind: .number,
                          defaultValue: .number(10)
                      ),
                      FieldSpec(key: "weeklySetsMax", name: "Weekly sets to", kind: .number, defaultValue: .number(20)),
                  ]),
        ClassSpec(key: .equipment, name: "Equipment", parent: .thing, symbol: "dumbbell", colorRole: "training",
                  fields: [
                      FieldSpec(key: "kind", name: "Kind", kind: .choice,
                                options: EquipmentKind.allCases.map(\.rawValue)),
                      FieldSpec(key: "barWeight", name: "Bar", kind: .mass, unit: "kg"),
                      // Plate sizes available in pairs, e.g. "25, 20, 15, 10, 5, 2.5, 1.25".
                      FieldSpec(key: "plates", name: "Plates", kind: .text),
                      // Fixed loads for dumbbells or a machine stack, e.g. "2, 4, 6, 8, 10, 12.5".
                      FieldSpec(key: "loads", name: "Loads", kind: .text),
                      FieldSpec(key: "increment", name: "Smallest step", kind: .mass, unit: "kg"),
                  ]),
        ClassSpec(key: .activity, name: "Activity", parent: .thing, symbol: "figure.walk", colorRole: "training"),
        ClassSpec(key: .exercise, name: "Exercise", parent: .activity, symbol: "figure.strengthtraining.traditional",
                  colorRole: "training", fields: [
                      FieldSpec(key: "primaryMuscles", name: "Primary muscles", kind: .refList, target: .muscle),
                      FieldSpec(key: "secondaryMuscles", name: "Secondary muscles", kind: .refList, target: .muscle),
                      FieldSpec(key: "equipment", name: "Equipment", kind: .refList, target: .equipment),
                      FieldSpec(
                          key: "restSeconds",
                          name: "Rest",
                          kind: .duration,
                          unit: "s",
                          defaultValue: .duration(90)
                      ),
                      FieldSpec(key: "repMin", name: "Reps from", kind: .number, defaultValue: .number(8)),
                      FieldSpec(key: "repMax", name: "Reps to", kind: .number, defaultValue: .number(12)),
                      FieldSpec(key: "progression", name: "Progression", kind: .text),
                      FieldSpec(key: "variantOf", name: "Variant of", kind: .classRef, target: .exercise),
                      // Swap pools and search: set on each library exercise's class object.
                      FieldSpec(key: "pattern", name: "Movement pattern", kind: .choice,
                                options: MovementPattern.allCases.map(\.rawValue)),
                      FieldSpec(key: "family", name: "Family", kind: .text),
                      FieldSpec(key: "mechanic", name: "Mechanic", kind: .choice, options: ["compound", "isolation"]),
                      FieldSpec(key: "logType", name: "Logged as", kind: .choice,
                                options: ["weightReps", "bodyweightPlus", "assisted", "repsOnly", "duration",
                                          "distanceLoad"]),
                      FieldSpec(key: "aliases", name: "Also called", kind: .text),
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
                      FieldSpec(key: "progression", name: "Progression", kind: .text,
                                defaultValue: .text("dp(+2.5, 8, 12)"), overrides: "progression"),
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
                      FieldSpec(key: "scheduledFor", name: "Scheduled", kind: .date),
                      FieldSpec(key: "startedAt", name: "Started", kind: .date),
                      FieldSpec(key: "endedAt", name: "Ended", kind: .date),
                      FieldSpec(key: "routine", name: "Routine", kind: .ref, target: .routine),
                  ]),
        ClassSpec(key: .exerciseEntry, name: "Exercise Entry", parent: .thing, symbol: "list.bullet",
                  colorRole: "training", fields: [
                      FieldSpec(key: "exercise", name: "Exercise", kind: .classRef, target: .exercise),
                      FieldSpec(key: "targetSets", name: "Target sets", kind: .number),
                      FieldSpec(key: "targetReps", name: "Target reps", kind: .number),
                      FieldSpec(key: "targetWeight", name: "Target weight", kind: .mass, unit: "kg"),
                      FieldSpec(key: "slot", name: "Slot", kind: .ref, target: .slot),
                      // Left without sets when the workout finished early.
                      FieldSpec(key: "skipped", name: "Skipped", kind: .bool),
                  ]),
        ClassSpec(key: .set, name: "Set", parent: .thing, symbol: "number", colorRole: "training",
                  traits: [.trackable, .measurable], fields: [
                      FieldSpec(key: "weight", name: "Weight", kind: .mass, unit: "kg"),
                      FieldSpec(key: "reps", name: "Reps", kind: .number),
                      FieldSpec(key: "rpe", name: "RPE", kind: .number),
                      FieldSpec(key: "isWarmup", name: "Warm-up", kind: .bool, defaultValue: .bool(false)),
                      FieldSpec(
                          key: "kind",
                          name: "Kind",
                          kind: .choice,
                          defaultValue: .choice(SetKind.working.rawValue),
                          options: SetKind.allCases.map(\.rawValue)
                      ),
                      FieldSpec(key: "source", name: "Logged with", kind: .choice,
                                options: SetSource.allCases.map(\.rawValue)),
                      FieldSpec(key: "loggedAt", name: "Logged", kind: .date),
                      // The unit the weight was entered in; the weight itself is always stored in kg.
                      FieldSpec(key: "enteredUnit", name: "Entered in", kind: .choice,
                                options: MassUnit.allCases.map(\.rawValue)),
                      // Epley on effective reps: with RPE logged, 5 @ 8 counts as a 7-rep effort.
                      FieldSpec(key: "e1rm", name: "Estimated 1RM", kind: .computed, unit: "kg",
                                expression: honestE1RM),
                      FieldSpec(key: "volume", name: "Volume", kind: .computed, unit: "kg",
                                expression: "weight * reps"),
                  ]),
        // A routine (Push Day A) is an ordered list of slots, held as its children.
        ClassSpec(key: .routine, name: "Routine", parent: .thing, symbol: "list.number", colorRole: "planning",
                  fields: [
                      FieldSpec(key: "cadence", name: "Cadence", kind: .choice, defaultValue: .choice("week"),
                                options: ["day", "week", "month"]),
                  ]),
        ClassSpec(key: .slot, name: "Slot", parent: .thing, symbol: "rectangle.stack", colorRole: "planning",
                  fields: [
                      FieldSpec(key: "exercise", name: "Exercise", kind: .classRef, target: .exercise),
                      FieldSpec(key: "sets", name: "Sets", kind: .number, defaultValue: .number(3)),
                      FieldSpec(key: "repMin", name: "Reps from", kind: .number),
                      FieldSpec(key: "repMax", name: "Reps to", kind: .number),
                      FieldSpec(key: "targetRPE", name: "Target RPE", kind: .number),
                      FieldSpec(key: "restSeconds", name: "Rest", kind: .duration, unit: "s"),
                      FieldSpec(key: "progression", name: "Progression", kind: .text),
                  ]),
        // A plan cycles through routines in order; a missed day just moves to the next routine.
        ClassSpec(key: .plan, name: "Plan", parent: .thing, symbol: "calendar", colorRole: "planning",
                  traits: [.schedulable], fields: [
                      FieldSpec(key: "routines", name: "Routines", kind: .refList, target: .routine),
                      FieldSpec(key: "startsOn", name: "Starts", kind: .date),
                      FieldSpec(key: "weeks", name: "Weeks", kind: .number),
                      FieldSpec(key: "sessionsPerWeek", name: "Sessions a week", kind: .number),
                  ]),
        ClassSpec(key: .task, name: "Task", parent: .thing, symbol: "checkmark.circle", colorRole: "planning",
                  traits: [.schedulable], fields: [
                      FieldSpec(key: "startsAt", name: "Starts", kind: .date),
                      FieldSpec(key: "length", name: "Length", kind: .duration),
                      FieldSpec(key: "due", name: "Due", kind: .date),
                      FieldSpec(key: "isDone", name: "Done", kind: .bool, defaultValue: .bool(false)),
                      FieldSpec(key: "doneAt", name: "Done at", kind: .date),
                      // Nightly roll-forward: the day it was first planned for, and how many nights it rolled.
                      FieldSpec(key: "rolledFrom", name: "First planned", kind: .date),
                      FieldSpec(key: "rolls", name: "Rolled", kind: .number),
                  ]),
        // Plain text with @ links; `about` holds the objects it mentions (classes via their class objects).
        ClassSpec(key: .note, name: "Note", parent: .thing, symbol: "note.text", colorRole: "neutral", fields: [
            FieldSpec(key: "body", name: "Body", kind: .text),
            FieldSpec(key: "about", name: "About", kind: .refList, target: .thing),
        ]),
        // The actionable list block (groceries, packing, any list). Items are the list's children, in order.
        ClassSpec(key: .list, name: "List", parent: .thing, symbol: "list.bullet", colorRole: "planning"),
        ClassSpec(key: .listItem, name: "List Item", parent: .thing, symbol: "circle", colorRole: "planning",
                  fields: [
                      FieldSpec(key: "quantity", name: "Quantity", kind: .text),
                      FieldSpec(key: "isDone", name: "Done", kind: .bool, defaultValue: .bool(false)),
                      FieldSpec(key: "checkedAt", name: "Checked", kind: .date),
                      FieldSpec(key: "section", name: "Section", kind: .text),
                      FieldSpec(key: "about", name: "About", kind: .refList, target: .thing),
                  ]),
        // Something you cook with. Recipe lines and grocery items link to one; it knows its aisle and if it's a staple.
        ClassSpec(key: .ingredient, name: "Ingredient", parent: .thing, symbol: "carrot", colorRole: "health",
                  fields: [
                      FieldSpec(key: "aisle", name: "Aisle", kind: .text),
                      FieldSpec(key: "isStaple", name: "Staple", kind: .bool, defaultValue: .bool(false)),
                  ]),
        ClassSpec(key: .process, name: "Process", parent: .thing, symbol: "circle.dotted", colorRole: "neutral",
                  traits: [.timed], fields: [
                      FieldSpec(key: "subject", name: "Subject", kind: .ref, target: .thing),
                      FieldSpec(key: "ownerApp", name: "App", kind: .text),
                      FieldSpec(key: "state", name: "State", kind: .choice, defaultValue: .choice("running"),
                                options: ProcessState.allCases.map(\.rawValue)),
                      FieldSpec(key: "resumePoint", name: "Resume point", kind: .text),
                      FieldSpec(key: "nextStep", name: "Next step", kind: .text),
                      FieldSpec(key: "startedAt", name: "Started", kind: .date),
                      FieldSpec(key: "lastTouchedAt", name: "Last touched", kind: .date),
                      FieldSpec(key: "waitingOn", name: "Waiting on", kind: .text),
                      FieldSpec(key: "checkAt", name: "Check at", kind: .date),
                      FieldSpec(key: "endedAt", name: "Ended", kind: .date),
                      FieldSpec(key: "endReason", name: "End reason", kind: .choice,
                                options: ProcessEndReason.allCases.map(\.rawValue)),
                  ]),
    ]

    /// Built-in classes ship as a versioned package. Bump `version` whenever a spec changes; seeding then
    /// refreshes shipped names, symbols, units, options, defaults and formulas, except what the person edited.
    public static let package = CatalogPackage(id: "system", version: 3, name: "Tessera built-ins",
                                               source: "Tessera", license: "Tessera")

    static let honestE1RM = "weight * (1 + (reps + 10 - coalesce(rpe, 10)) / 30)"

    /// Formulas earlier builds shipped; seeding upgrades a system field still using one of them.
    private static let retiredExpressions: [String: Set<String>] = [
        "system.set.e1rm": ["weight * (1 + reps / 30)"],
    ]

    /// Inserts any missing system classes and returns all of them by key.
    @discardableResult
    public static func seed(in context: TesseraContext) throws -> [Key: ClassDef] {
        var classes = try existing(in: context)
        for spec in specs {
            let classDef: ClassDef
            if let existing = classes[spec.key] {
                classDef = existing
                // Earlier builds called the routine class "Plan"; Plan is now its own class.
                if spec.key == .routine, existing.name == "Plan" {
                    existing.name = spec.name
                }
            } else {
                classDef = ClassDef(
                    name: spec.name,
                    parent: spec.parent.flatMap { classes[$0] },
                    symbolName: spec.symbol,
                    colorRole: spec.colorRole,
                    traits: spec.traits,
                    systemKey: spec.key.systemKey
                )
                classDef.id = stableID(spec.key.systemKey)
                context.insert(classDef)
                classes[spec.key] = classDef
            }
            let needsRefresh = classDef.packageVersion < package.version
            if needsRefresh {
                refresh(classDef, from: spec)
            }
            // Adds fields introduced in later versions to classes seeded by earlier ones.
            let present = Set((classDef.ownFields ?? []).map(\.id))
            for (index, fieldSpec) in spec.fields.enumerated() {
                let fieldID = stableID("\(spec.key.systemKey).\(fieldSpec.key)")
                if present.contains(fieldID) {
                    if needsRefresh, let field = classDef.ownFields?.first(where: { $0.id == fieldID }) {
                        refresh(field, from: fieldSpec)
                    }
                    upgradeExpression(of: fieldID, in: classDef, to: fieldSpec.expression,
                                      key: "\(spec.key.systemKey).\(fieldSpec.key)")
                    continue
                }
                let field = FieldDef(
                    name: fieldSpec.name,
                    key: fieldSpec.key,
                    kind: fieldSpec.kind,
                    sortIndex: index,
                    unit: fieldSpec.unit,
                    defaultValue: fieldSpec.defaultValue
                )
                field.id = fieldID
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
        }
        try context.save()
        return classes
    }

    /// Applies the package's class spec, keeping the person's edits (the overlay).
    private static func refresh(_ classDef: ClassDef, from spec: ClassSpec) {
        if !classDef.isUserModified {
            classDef.name = spec.name
            classDef.symbolName = spec.symbol
            classDef.colorRole = spec.colorRole
            classDef.traitsRaw = spec.traits.map(\.rawValue)
        }
        classDef.packageID = package.id
        classDef.packageVersion = package.version
    }

    private static func refresh(_ field: FieldDef, from spec: FieldSpec) {
        guard !field.isUserModified else { return }
        field.name = spec.name
        field.unit = spec.unit
        field.enumOptions = spec.options
        field.defaultValue = spec.defaultValue
        if spec.expression != nil {
            field.expression = spec.expression
        }
    }

    /// Moves a system formula forward, unless the person has edited it.
    private static func upgradeExpression(of fieldID: UUID, in classDef: ClassDef, to expression: String?,
                                          key: String)
    {
        guard let expression, let retired = retiredExpressions[key],
              let field = classDef.ownFields?.first(where: { $0.id == fieldID }),
              let current = field.expression, retired.contains(current) else { return }
        field.expression = expression
    }

    public static func existing(in context: TesseraContext) throws -> [Key: ClassDef] {
        let all = context.all(ClassDef.self).filter { $0.systemKey != nil }
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
    public nonisolated static func stableID(_ name: String) -> UUID {
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
