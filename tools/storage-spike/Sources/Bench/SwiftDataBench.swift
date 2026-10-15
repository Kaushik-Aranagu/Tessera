import Foundation
import SwiftData

@MainActor
enum SDBench {
    static func container(_ dir: URL) throws -> ModelContainer {
        let schema = Schema(sdModels)
        let configuration = ModelConfiguration(
            schema: schema, url: dir.appending(path: "store.sqlite"), cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: configuration)
    }

    static func build(dir: URL, mode: String) throws {
        let perWorkout = mode != "oneTx"
        let freshContext = mode == "perWorkoutFresh"
        let container = try container(dir)
        let context = ModelContext(container)
        context.autosaveEnabled = false

        func makeClass(_ name: String, _ key: String, parent: ClassDef?) -> ClassDef {
            let classDef = ClassDef(name: name, systemKey: key)
            context.insert(classDef)
            classDef.parent = parent
            return classDef
        }
        func makeField(_ key: String, _ kind: String, on owner: ClassDef, expression: String? = nil) -> FieldDef {
            let field = FieldDef(key: key, kind: kind)
            context.insert(field)
            field.owner = owner
            field.expression = expression
            return field
        }
        let workoutClass = makeClass("Workout", "system.workout", parent: nil)
        let entryClass = makeClass("Exercise Entry", "system.exerciseEntry", parent: nil)
        let setClass = makeClass("Set", "system.set", parent: nil)
        let lift = makeClass("Barbell Lift", "system.barbellLift", parent: nil)
        let exercises = [makeClass("Bench Press", "system.benchPress", parent: lift)]
            + (0 ..< 4).map { makeClass("Lift \($0)", "user.lift\($0)", parent: lift) }
        let ids = FieldIDs(
            weight: makeField("weight", "mass", on: setClass).id,
            reps: makeField("reps", "number", on: setClass).id,
            rpe: makeField("rpe", "number", on: setClass).id,
            kind: makeField("kind", "choice", on: setClass).id,
            isWarmup: makeField("isWarmup", "bool", on: setClass).id,
            endedAt: makeField("endedAt", "date", on: workoutClass).id,
            exercise: makeField("exercise", "classRef", on: entryClass).id
        )
        _ = makeField("e1rm", "computed", on: setClass, expression: "weight * (1 + reps / 30)")
        try context.save()

        let catalogIDs = ([workoutClass, entryClass, setClass] + exercises).map(\.persistentModelID)
        try measure("sd.insert.\(mode)") {
            var context = context
            var workoutClass = workoutClass, entryClass = entryClass, setClass = setClass, exercises = exercises
            for day in 0 ..< Fixture.workouts {
                if freshContext {
                    // A short-lived context per workout, as an importer would use.
                    context = ModelContext(container)
                    context.autosaveEnabled = false
                    let resolved = catalogIDs.map { context.model(for: $0) as! ClassDef }
                    workoutClass = resolved[0]; entryClass = resolved[1]; setClass = resolved[2]
                    exercises = Array(resolved[3...])
                }
                let date = Fixture.workoutDate(day)
                // Insert first, then set relationships (setting them in init is quadratic).
                let workout = ObjectRecord(title: "Day \(day)", createdAt: date)
                context.insert(workout)
                workout.classDef = workoutClass
                var workoutValues = FieldValues()
                workoutValues[ids.endedAt] = .date(date)
                workout.valuesData = try Fixture.encoder.encode(workoutValues)
                for (index, exercise) in exercises.enumerated() {
                    let entry = ObjectRecord(title: "", createdAt: date)
                    context.insert(entry)
                    entry.classDef = entryClass
                    entry.parent = workout
                    entry.sortIndex = index
                    let link = ObjectLink(fieldID: ids.exercise)
                    context.insert(link)
                    link.from = entry
                    link.toClass = exercise
                    for setIndex in 0 ..< Fixture.setsPerEntry {
                        let set = ObjectRecord(title: "", createdAt: date)
                        context.insert(set)
                        set.classDef = setClass
                        set.parent = entry
                        set.sortIndex = setIndex
                        set.valuesData = try Fixture.encoder.encode(Fixture.setValues(day: day, set: setIndex, ids: ids))
                    }
                }
                if perWorkout { try context.save() }
            }
            if !perWorkout { try context.save() }
        }
    }

    struct Plan {
        var setClass: UUID, workoutClass: UUID, bench: UUID
        var ids: FieldIDs
    }

    static func plan(_ context: ModelContext) throws -> Plan {
        let classes = try context.fetch(FetchDescriptor<ClassDef>())
        let fields = try context.fetch(FetchDescriptor<FieldDef>())
        func cls(_ key: String) -> UUID { classes.first { $0.systemKey == key }!.id }
        func fld(_ key: String) -> UUID { fields.first { $0.key == key }!.id }
        return Plan(
            setClass: cls("system.set"), workoutClass: cls("system.workout"), bench: cls("system.benchPress"),
            ids: FieldIDs(weight: fld("weight"), reps: fld("reps"), rpe: fld("rpe"), kind: fld("kind"),
                          isWarmup: fld("isWarmup"), endedAt: fld("endedAt"), exercise: fld("exercise"))
        )
    }

    /// Mirrors TrainingIndexBuilder.facts: sets with parent prefetched, exercise links with from/toClass
    /// prefetched, walk entry → workout, decode JSON values into plain structs.
    static func facts(_ context: ModelContext, _ plan: Plan) throws -> [EntryFact] {
        var setsByEntry: [UUID: [ObjectRecord]] = [:]
        let setClass = plan.setClass
        var descriptor = FetchDescriptor<ObjectRecord>(predicate: #Predicate {
            $0.deletedAt == nil && $0.classDef?.id == setClass
        })
        descriptor.relationshipKeyPathsForPrefetching = [\.parent]
        for set in try context.fetch(descriptor) {
            guard let entryID = set.parent?.id else { continue }
            setsByEntry[entryID, default: []].append(set)
        }
        let exerciseField = plan.ids.exercise
        var links = FetchDescriptor<ObjectLink>(predicate: #Predicate { $0.fieldID == exerciseField })
        links.relationshipKeyPathsForPrefetching = [\.from, \.toClass]
        var facts: [EntryFact] = []
        var workoutDates: [UUID: Date] = [:]
        for link in try context.fetch(links) {
            guard let entry = link.from, entry.deletedAt == nil, let exercise = link.toClass,
                  let sets = setsByEntry[entry.id], let workout = entry.parent,
                  workout.classDef?.id == plan.workoutClass, workout.deletedAt == nil else { continue }
            let date: Date
            if let cached = workoutDates[workout.id] {
                date = cached
            } else {
                guard let value = workout.values[plan.ids.endedAt]?.dateValue else { continue }
                workoutDates[workout.id] = value
                date = value
            }
            let logged = sets.sorted { ($0.sortIndex, $0.createdAt) < ($1.sortIndex, $1.createdAt) }
                .compactMap { loggedSet(id: $0.id, values: $0.values, ids: plan.ids) }
            facts.append(EntryFact(entryID: entry.id, workoutID: workout.id, classID: exercise.id, date: date,
                                   sets: logged))
        }
        return facts
    }

    /// All sets of one exercise class (via its entries' links), best e1RM. Returns the latest entry too.
    static func records(_ context: ModelContext, _ plan: Plan) throws -> (best: Double, latest: ObjectRecord?) {
        let exerciseField = plan.ids.exercise
        let bench = plan.bench
        var links = FetchDescriptor<ObjectLink>(predicate: #Predicate {
            $0.fieldID == exerciseField && $0.toClass?.id == bench
        })
        links.relationshipKeyPathsForPrefetching = [\.from]
        var best = 0.0
        var latest: ObjectRecord?
        for link in try context.fetch(links) {
            guard let entry = link.from, entry.deletedAt == nil else { continue }
            if latest.map({ $0.createdAt < entry.createdAt }) ?? true { latest = entry }
            for set in entry.children ?? [] where set.deletedAt == nil {
                if let logged = loggedSet(id: set.id, values: set.values, ids: plan.ids) {
                    best = max(best, logged.e1RM)
                }
            }
        }
        return (best, latest)
    }

    static func query(dir: URL) throws {
        let start = clock.now
        let container = try container(dir)
        let context = ModelContext(container)
        let plan = try plan(context)
        result("sd.open", ms(clock.now - start))
        let facts = try measure("sd.read") { try Self.facts(context, plan) }
        result("sd.openAndRead", ms(clock.now - start))
        print("INFO sd entries=\(facts.count) sets=\(facts.reduce(0) { $0 + $1.sets.count })")

        let fresh = ModelContext(container)
        let (best, latest) = try measure("sd.records") { try records(fresh, plan) }
        print("INFO sd bestE1RM=\(best)")
        let (after, _) = try measure("sd.logAndRequery") {
            let set = ObjectRecord(title: "", createdAt: .now)
            fresh.insert(set)
            let setClassID = plan.setClass
            set.classDef = try fresh.fetch(FetchDescriptor<ClassDef>(predicate: #Predicate { $0.id == setClassID })).first
            set.parent = latest
            set.sortIndex = 99
            var values = FieldValues()
            values[plan.ids.weight] = .mass(150)
            values[plan.ids.reps] = .number(5)
            set.valuesData = try Fixture.encoder.encode(values)
            fresh.insert(OpRecord(action: "logSet", summary: "Logged bench 150 × 5", opsData: Data(count: 200),
                                  objectIDs: [set.id]))
            try fresh.save()
            return try records(fresh, plan)
        }
        print("INFO sd bestAfterLog=\(after)")
    }
}
