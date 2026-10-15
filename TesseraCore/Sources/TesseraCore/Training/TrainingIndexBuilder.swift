import Foundation
import SwiftData

/// Builds the training index's heavy part on a background context, so a long history never blocks the main
/// thread at launch. Call `ledger.warmUp()` once after launch; queries before it finishes build synchronously.
@MainActor
public extension TrainingLedger {
    func warmUp() async {
        let store = store
        guard store.derived.trainingIndex == nil || store.derived.needsRebuild,
              let plan = TrainingIndexBuilder.Plan(ledger: self) else { return }
        // The background context reads what's saved, so save pending writes first; anything written from
        // here on is tracked in `touched` and patched in on the next query.
        if store.context.hasChanges {
            try? store.context.save()
        }
        store.derived.touched.removeAll()
        let startRevision = store.revision
        let builder = TrainingIndexBuilder(modelContainer: store.context.container)
        let facts = await builder.facts(plan)

        // A synchronous build may have happened meanwhile; keep whichever is current.
        guard store.derived.trainingIndex == nil || store.derived.needsRebuild else { return }
        var index = TrainingIndex()
        let context = store.context
        for fact in facts {
            guard let workout = context.model(for: fact.workout) as? ObjectRecord,
                  let entry = context.model(for: fact.entry) as? ObjectRecord else { continue }
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

@ModelActor
actor TrainingIndexBuilder {
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
        let entry: PersistentIdentifier
        let workout: PersistentIdentifier
        let entryID: UUID
        let workoutID: UUID
        let classID: UUID
        let date: Date
        let sets: [TrainingLedger.LoggedSet]
    }

    func facts(_ plan: Plan) -> [EntryFact] {
        var setsByEntry: [UUID: [ObjectRecord]] = [:]
        for classID in plan.setClassIDs {
            var descriptor = FetchDescriptor<ObjectRecord>(predicate: #Predicate {
                $0.deletedAt == nil && $0.classDef?.id == classID
            })
            descriptor.relationshipKeyPathsForPrefetching = [\.parent]
            for set in (try? modelContext.fetch(descriptor)) ?? [] {
                guard let entryID = set.parent?.id else { continue }
                setsByEntry[entryID, default: []].append(set)
            }
        }
        let exerciseField = plan.exerciseField
        var links = FetchDescriptor<ObjectLink>(predicate: #Predicate { $0.fieldID == exerciseField })
        links.relationshipKeyPathsForPrefetching = [\.from, \.toClass]
        var facts: [EntryFact] = []
        for link in (try? modelContext.fetch(links)) ?? [] {
            guard let entry = link.from, !entry.isDeleted, let exercise = link.toClass,
                  let sets = setsByEntry[entry.id], let workout = workout(of: entry, plan), !workout.isDeleted
            else { continue }
            let values = workout.values
            guard let date = (values[plan.endedAt] ?? values[plan.startedAt])?.dateValue else { continue }
            let logged = sets
                .filter { !$0.isDeleted }
                .sorted { ($0.sortIndex, $0.createdAt) < ($1.sortIndex, $1.createdAt) }
                .compactMap { loggedSet($0, plan) }
            guard !logged.isEmpty else { continue }
            facts.append(EntryFact(entry: entry.persistentModelID, workout: workout.persistentModelID,
                                   entryID: entry.id, workoutID: workout.id, classID: exercise.id, date: date,
                                   sets: logged))
        }
        return facts
    }

    private func workout(of entry: ObjectRecord, _ plan: Plan) -> ObjectRecord? {
        var current = entry.parent
        var seen = Set<UUID>()
        while let node = current, seen.insert(node.id).inserted {
            if let classID = node.classDef?.id, plan.workoutClassIDs.contains(classID) {
                return node
            }
            current = node.parent
        }
        return nil
    }

    private func loggedSet(_ set: ObjectRecord, _ plan: Plan) -> TrainingLedger.LoggedSet? {
        let values = set.values
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
            id: set.id, weight: weight, reps: reps, rpe: rpe, kind: kind, e1RM: e1RM,
            isE1RMEligible: TrainingLedger.effectiveReps(reps, rpe: rpe) <= TrainingLedger.e1RMRepLimit
        )
    }
}
