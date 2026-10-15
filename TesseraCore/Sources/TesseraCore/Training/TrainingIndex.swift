import Foundation
import SwiftData

/// Every exercise session, built in a few batched fetches instead of walking relationships set by set,
/// then patched entry by entry as sets are logged or edited.
@MainActor
struct TrainingIndex {
    /// Keyed by the entry's exercise class id.
    private(set) var sessionsByClass: [UUID: [TrainingLedger.Session]] = [:]

    /// Every session of every exercise.
    var allSessions: some Sequence<(classID: UUID, session: TrainingLedger.Session)> {
        sessionsByClass.lazy.flatMap { classID, sessions in sessions.lazy.map { (classID, $0) } }
    }

    /// Which class each indexed entry sits under, for patching.
    private var classOfEntry: [UUID: UUID] = [:]

    /// A full build: every set and every entry → exercise link in one fetch each.
    init(ledger: TrainingLedger) {
        let store = ledger.store
        guard let entryClass = ledger.classes[.exerciseEntry], let setClass = ledger.classes[.set],
              let exerciseField = store.field("exercise", of: entryClass)?.id else { return }
        let reader = SetReader(ledger: ledger)

        var setsByEntry: [UUID: [ObjectRecord]] = [:]
        for classID in ClassResolver.descendants(of: setClass).map(\.id) {
            var descriptor = FetchDescriptor<ObjectRecord>(predicate: #Predicate {
                $0.deletedAt == nil && $0.classDef?.id == classID
            })
            descriptor.relationshipKeyPathsForPrefetching = [\.parent]
            for set in (try? store.context.fetch(descriptor)) ?? [] {
                guard let entryID = set.parent?.id else { continue }
                setsByEntry[entryID, default: []].append(set)
            }
        }

        var links = FetchDescriptor<ObjectLink>(predicate: #Predicate { $0.fieldID == exerciseField })
        links.relationshipKeyPathsForPrefetching = [\.from, \.toClass]
        for link in (try? store.context.fetch(links)) ?? [] {
            guard let entry = link.from, let exercise = link.toClass,
                  let session = reader.session(entry: entry, sets: setsByEntry[entry.id] ?? []) else { continue }
            insert(session, classID: exercise.id)
        }
    }

    /// Re-reads the entries behind the touched objects (sets, entries or workouts). Returns false when a full
    /// rebuild is the better option.
    mutating func patch(touched: Set<UUID>, ledger: TrainingLedger) -> Bool {
        guard touched.count <= 200 else { return false }
        let store = ledger.store
        let reader = SetReader(ledger: ledger)
        var entries: [UUID: ObjectRecord] = [:]
        for id in touched {
            guard let object = store.object(id: id) else {
                // Gone entirely: drop it if it was an indexed entry.
                remove(entryID: id)
                continue
            }
            for entry in reader.entries(affectedBy: object) {
                entries[entry.id] = entry
            }
        }
        for entry in entries.values {
            remove(entryID: entry.id)
            guard let exercise = store.linkedClass("exercise", of: entry),
                  let session = reader.session(entry: entry, sets: entry.children ?? []) else { continue }
            insert(session, classID: exercise.id)
        }
        return true
    }

    private mutating func insert(_ session: TrainingLedger.Session, classID: UUID) {
        sessionsByClass[classID, default: []].append(session)
        classOfEntry[session.id] = classID
    }

    private mutating func remove(entryID: UUID) {
        guard let classID = classOfEntry.removeValue(forKey: entryID) else { return }
        sessionsByClass[classID]?.removeAll { $0.id == entryID }
    }
}

/// Reads sets quickly: one decode per set, field ids resolved once.
@MainActor
private struct SetReader {
    enum Role { case set, entry, workout, other }

    let ledger: TrainingLedger
    let setClassID: UUID?
    let entryClassID: UUID?
    let workoutClass: ClassDef?
    /// Field ids and the e1RM formula, when sets can be read straight from their own values
    /// (no class object up the Set lineage supplies inherited values).
    let fast: FastFields?

    struct FastFields {
        let weight: UUID, reps: UUID, rpe: UUID, kind: UUID, warmup: UUID
        let e1rm: Formula
    }

    init(ledger: TrainingLedger) {
        self.ledger = ledger
        let store = ledger.store
        setClassID = ledger.classes[.set]?.id
        entryClassID = ledger.classes[.exerciseEntry]?.id
        workoutClass = ledger.classes[.workout]
        if let setClass = ledger.classes[.set],
           store.lineage(of: setClass).allSatisfy({ store.classObject(of: $0) == nil }),
           let weight = store.field("weight", of: setClass), let reps = store.field("reps", of: setClass),
           let rpe = store.field("rpe", of: setClass), let kind = store.field("kind", of: setClass),
           let warmup = store.field("isWarmup", of: setClass),
           let source = store.field("e1rm", of: setClass)?.expression, let formula = store.formula(source),
           formula.variables.isSubset(of: ["weight", "reps", "rpe"])
        {
            fast = FastFields(weight: weight.id, reps: reps.id, rpe: rpe.id, kind: kind.id, warmup: warmup.id,
                              e1rm: formula)
        } else {
            fast = nil
        }
    }

    /// One decode per set; falls back to the general path for anything unusual.
    func loggedSet(_ set: ObjectRecord) -> TrainingLedger.LoggedSet? {
        guard let fast, set.classDef?.id == setClassID else { return ledger.loggedSet(set) }
        let values = set.values
        if values[fast.warmup] == .bool(true) {
            return nil
        }
        let kind = values[fast.kind]?.stringValue.flatMap(SetKind.init(rawValue:)) ?? .working
        guard kind.counts, let weight = values[fast.weight]?.numericValue,
              let reps = values[fast.reps]?.numericValue else { return nil }
        let rpe = values[fast.rpe]?.numericValue
        let lookup = ["weight": weight, "reps": reps, "rpe": rpe]
        guard let e1RM = fast.e1rm.evaluate({ lookup[$0] ?? nil }) else { return nil }
        return TrainingLedger.LoggedSet(
            id: set.id, weight: weight, reps: reps, rpe: rpe, kind: kind, e1RM: e1RM,
            isE1RMEligible: TrainingLedger.effectiveReps(reps, rpe: rpe) <= TrainingLedger.e1RMRepLimit
        )
    }

    func role(of classDef: ClassDef) -> Role {
        let store = ledger.store
        if let setClassID, store.isSubclass(classDef, ofClassID: setClassID) {
            return .set
        }
        if let entryClassID, store.isSubclass(classDef, ofClassID: entryClassID) {
            return .entry
        }
        if let workoutClass, store.isSubclass(classDef, ofClassID: workoutClass.id) {
            return .workout
        }
        return .other
    }

    /// The exercise entries whose sessions change when `object` changes.
    func entries(affectedBy object: ObjectRecord) -> [ObjectRecord] {
        guard let classDef = object.classDef else { return [] }
        switch role(of: classDef) {
        case .set: return object.parent.map { [$0] } ?? []
        case .entry: return [object]
        case .workout: return object.children ?? []
        case .other: return []
        }
    }

    func session(entry: ObjectRecord, sets: [ObjectRecord]) -> TrainingLedger.Session? {
        guard !entry.isDeleted, let workoutClass,
              let workout = ledger.store.ancestor(of: entry, ofClass: workoutClass), !workout.isDeleted,
              let date = ledger.workoutDate(workout) else { return nil }
        let logged = sets
            .filter { !$0.isDeleted }
            .sorted { ($0.sortIndex, $0.createdAt) < ($1.sortIndex, $1.createdAt) }
            .compactMap(loggedSet)
        guard !logged.isEmpty else { return nil }
        return TrainingLedger.Session(id: entry.id, workout: workout, entry: entry, date: date, sets: logged)
    }
}

extension TrainingLedger {
    /// The index for the store's current revision: patched for a few writes, rebuilt after many or after
    /// a change the store couldn't attribute to an object.
    var index: TrainingIndex {
        let store = store
        let derived = store.derived
        let revision = store.revision
        if var cached = derived.trainingIndex?.index, !derived.needsRebuild {
            if derived.trainingIndex?.revision == revision {
                return cached
            }
            if cached.patch(touched: derived.touched, ledger: self) {
                derived.trainingIndex = (revision, cached)
                derived.touched.removeAll()
                return cached
            }
        }
        let index = TrainingIndex(ledger: self)
        derived.trainingIndex = (revision, index)
        derived.touched.removeAll()
        derived.needsRebuild = false
        return index
    }
}
