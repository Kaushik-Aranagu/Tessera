import Foundation
import GRDB

/// Builds the training index's heavy part (decoding every set) off the main thread, straight from SQLite, so a
/// long history never blocks launch. Call `ledger.warmUp()` once after launch; queries before it finishes build
/// synchronously.
@MainActor
public extension TrainingLedger {
    func warmUp() async {
        let store = store
        guard store.derived.trainingIndex == nil || store.derived.needsRebuild,
              let plan = TrainingIndexBuilder.Plan(ledger: self) else { return }
        // The background read sees what's saved, so save pending writes first; anything written from
        // here on is tracked in `touched` and patched in on the next query.
        if store.context.hasChanges {
            try? store.context.save()
        }
        store.derived.touched.removeAll()
        let startRevision = store.revision
        let database = store.context.database
        let facts = await Task.detached { (try? database.read { try TrainingIndexBuilder.facts(plan, db: $0) }) ?? [] }
            .value

        // A synchronous build may have happened meanwhile; keep whichever is current.
        guard store.derived.trainingIndex == nil || store.derived.needsRebuild else { return }
        var index = TrainingIndex()
        let context = store.context
        for fact in facts {
            guard let workout = context.objects[fact.workoutID], let entry = context.objects[fact.entryID],
                  !workout.isDeleted, !entry.isDeleted else { continue }
            index.insert(
                Session(
                    id: fact.entryID,
                    workoutID: fact.workoutID,
                    workout: workout,
                    entry: entry,
                    date: fact.date,
                    sets: fact.sets
                ),
                classID: fact.classID
            )
        }
        // Writes during the build stay in `touched`, so the next query patches them in.
        store.derived.trainingIndex = (startRevision, index)
        store.derived.needsRebuild = false
    }
}

enum TrainingIndexBuilder {
    /// Everything the background pass needs, resolved on the main actor first.
    struct Plan: Sendable {
        let setClassIDs: [UUID]
        let workoutClassIDs: Set<UUID>
        let exerciseField: UUID
        let weight: UUID, reps: UUID, rpe: UUID, kind: UUID, warmup: UUID
        let endedAt: UUID, startedAt: UUID
        let e1rm: Formula

        @MainActor
        init?(ledger: TrainingLedger) {
            let store = ledger.store
            guard let setClass = ledger.classes[.set], let workoutClass = ledger.classes[.workout],
                  let entryClass = ledger.classes[.exerciseEntry],
                  // Class objects up the Set lineage would supply inherited values; use the main-actor path then.
                  store.lineage(of: setClass).allSatisfy({ store.classObject(of: $0) == nil }),
                  let exerciseField = store.field("exercise", of: entryClass)?.id,
                  let weight = store.field("weight", of: setClass), let reps = store.field("reps", of: setClass),
                  let rpe = store.field("rpe", of: setClass), let kind = store.field("kind", of: setClass),
                  let warmup = store.field("isWarmup", of: setClass),
                  let endedAt = store.field("endedAt", of: workoutClass),
                  let startedAt = store.field("startedAt", of: workoutClass),
                  let source = store.field("e1rm", of: setClass)?.expression, let formula = store.formula(source),
                  formula.variables.isSubset(of: ["weight", "reps", "rpe"])
            else { return nil }
            setClassIDs = ClassResolver.descendants(of: setClass).map(\.id)
            workoutClassIDs = Set(ClassResolver.descendants(of: workoutClass).map(\.id))
            self.exerciseField = exerciseField
            self.weight = weight.id
            self.reps = reps.id
            self.rpe = rpe.id
            self.kind = kind.id
            self.warmup = warmup.id
            self.endedAt = endedAt.id
            self.startedAt = startedAt.id
            e1rm = formula
        }
    }

    /// One exercise entry's session, as plain values.
    struct EntryFact: Sendable {
        let entryID: UUID
        let workoutID: UUID
        let classID: UUID
        let date: Date
        let sets: [TrainingLedger.LoggedSet]
    }

    /// Reads sets, entries, exercise links and workouts as rows and turns them into session facts.
    static func facts(_ plan: Plan, db: Database) throws -> [EntryFact] {
        func uuid(_ row: Row, _ column: String) -> UUID? {
            (row[column] as String?).flatMap(UUID.init(uuidString:))
        }
        // Every object's parent and values, and which objects are workouts.
        var parentOf: [UUID: UUID] = [:]
        var valuesOf: [UUID: Data] = [:]
        var setsByEntry: [UUID: [(id: UUID, order: (Int, Double), values: Data?)]] = [:]
        var workouts: Set<UUID> = []
        let setClasses = Set(plan.setClassIDs.map(\.uuidString))
        let workoutClasses = Set(plan.workoutClassIDs.map(\.uuidString))
        let rows = try Row.fetchCursor(db, sql: """
        SELECT id, classID, parentID, sortIndex, createdAt, "values" FROM object WHERE deletedAt IS NULL
        """)
        while let row = try rows.next() {
            guard let id = uuid(row, "id") else { continue }
            let classID: String? = row["classID"]
            if let parent = uuid(row, "parentID") {
                parentOf[id] = parent
            }
            if let classID, setClasses.contains(classID), let entry = uuid(row, "parentID") {
                setsByEntry[entry, default: []].append((id, (row["sortIndex"], row["createdAt"]), row["values"]))
            } else if let classID, workoutClasses.contains(classID) {
                workouts.insert(id)
                valuesOf[id] = row["values"]
            }
        }
        let decoder = JSONDecoder()
        var facts: [EntryFact] = []
        let links = try Row.fetchCursor(db, sql: "SELECT fromID, toClassID FROM link WHERE fieldID = ?",
                                        arguments: [plan.exerciseField.uuidString])
        while let link = try links.next() {
            guard let entry = uuid(link, "fromID"), let exercise = uuid(link, "toClassID"),
                  let sets = setsByEntry[entry] else { continue }
            var ancestor = parentOf[entry]
            var hops = 0
            while let node = ancestor, !workouts.contains(node), hops < 16 {
                ancestor = parentOf[node]
                hops += 1
            }
            guard let workout = ancestor, workouts.contains(workout),
                  let workoutValues = valuesOf[workout].flatMap({ try? decoder.decode(FieldValues.self, from: $0) }),
                  let date = (workoutValues[plan.endedAt] ?? workoutValues[plan.startedAt])?.dateValue else { continue }
            let logged = sets
                .sorted { $0.order < $1.order }
                .compactMap { set in
                    loggedSet(set.id, set.values.flatMap { try? decoder.decode(FieldValues.self, from: $0) }, plan)
                }
            guard !logged.isEmpty else { continue }
            facts.append(EntryFact(entryID: entry, workoutID: workout, classID: exercise, date: date, sets: logged))
        }
        return facts
    }

    private static func loggedSet(_ id: UUID, _ values: FieldValues?, _ plan: Plan) -> TrainingLedger.LoggedSet? {
        guard let values else { return nil }
        if values[plan.warmup] == .bool(true) {
            return nil
        }
        let kind = values[plan.kind]?.stringValue.flatMap(SetKind.init(rawValue:)) ?? .working
        guard kind.counts, let weight = values[plan.weight]?.numericValue,
              let reps = values[plan.reps]?.numericValue else { return nil }
        let rpe = values[plan.rpe]?.numericValue
        let lookup = ["weight": weight, "reps": reps, "rpe": rpe]
        guard let e1RM = plan.e1rm.evaluate({ lookup[$0] ?? nil }) else { return nil }
        return TrainingLedger.LoggedSet(
            id: id, weight: weight, reps: reps, rpe: rpe, kind: kind, e1RM: e1RM,
            isE1RMEligible: TrainingLedger.effectiveReps(reps, rpe: rpe) <= TrainingLedger.e1RMRepLimit
        )
    }
}
