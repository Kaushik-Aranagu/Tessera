import Foundation

// Per-store caches: resolved classes, parsed formulas, class objects, and the revision that derived caches
// (the training index) key off.

public extension ObjectStore {
    /// Bumped by every write through this store; derived caches (the training index) rebuild when it moves.
    var revision: Int {
        cache.revision
    }

    /// Call after changing an object without going through the store, so derived caches update.
    /// With no object, derived caches rebuild from scratch (after imports, schema edits or sync).
    func noteChange(_ object: ObjectRecord? = nil) {
        cache.revision &+= 1
        if let object {
            cache.derived.touched.insert(object.id)
        } else {
            cache.derived.needsRebuild = true
        }
    }

    internal var derived: DerivedCache {
        cache.derived
    }

    // MARK: Resolved classes (cached)

    internal struct ClassInfo {
        let lineage: [ClassDef]
        let lineageIDs: Set<UUID>
        let fields: [ResolvedField]
        let byKey: [String: ResolvedField]
    }

    internal func classInfo(_ classDef: ClassDef) -> ClassInfo {
        if let cached = cache.classInfo[classDef.id] {
            return cached
        }
        let lineage = ClassResolver.lineage(of: classDef)
        let fields = ClassResolver.effectiveFields(of: classDef)
        let info = ClassInfo(lineage: lineage, lineageIDs: Set(lineage.map(\.id)), fields: fields,
                             byKey: Dictionary(fields.map { ($0.key, $0) }, uniquingKeysWith: { first, _ in first }))
        cache.classInfo[classDef.id] = info
        return info
    }

    /// `ClassResolver.field`, cached per class.
    func field(_ key: String, of classDef: ClassDef) -> ResolvedField? {
        classInfo(classDef).byKey[key]
    }

    /// `ClassResolver.lineage`, cached per class. Root first.
    func lineage(of classDef: ClassDef) -> [ClassDef] {
        classInfo(classDef).lineage
    }

    /// `ClassResolver.isSubclass`, cached per class.
    func isSubclass(_ classDef: ClassDef, ofClassID ancestorID: UUID) -> Bool {
        classInfo(classDef).lineageIDs.contains(ancestorID)
    }

    internal func formula(_ source: String) -> Formula? {
        if let cached = cache.formulas[source] {
            return cached
        }
        let parsed = try? Formula.parse(source)
        cache.formulas[source] = parsed
        return parsed
    }
}

/// Per-store lookup cache. `classObjects[id] == .some(nil)` caches "this class has no class object".
@MainActor
final class Cache {
    var classObjects: [UUID: ObjectRecord?] = [:]
    var classInfo: [UUID: ObjectStore.ClassInfo] = [:]
    var formulas: [String: Formula?] = [:]
    var revision = 0
    /// Kept alive for stores made with `ObjectStore.open`.
    var container: TesseraContainer?
    let derived = DerivedCache()
}

/// Caches computed from the object graph, valid for one store revision.
@MainActor
final class DerivedCache {
    var trainingIndex: (revision: Int, index: TrainingIndex)?
    /// Sorted sessions per exercise class (with subclasses), for the current revision.
    var sessions: [UUID: (revision: Int, sessions: [TrainingLedger.Session])] = [:]
    /// Finished workouts by the start of the day they ended, and summaries already built per day.
    var workoutDays: (revision: Int, days: [Date: [UUID]])?
    /// The time zone `workoutDays` was keyed in.
    var workoutDaysZone: String?
    var daySummaries: [Date: (revision: Int, summaries: [WorkoutSummary])] = [:]
    /// Objects written since derived caches were last brought up to date.
    var touched: Set<UUID> = []
    var needsRebuild = false
}
