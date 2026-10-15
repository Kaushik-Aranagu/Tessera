import Foundation
import SwiftData

/// Reads and writes objects through their class's resolved fields: defaults, class objects, computed values,
/// typed links and backlinks. Views talk to this, not to raw `valuesData`.
///
/// Value lookup order for a field on an object:
/// 1. the object's own stored value (or links),
/// 2. the nearest class object up the lineage that sets it (Paused Bench Press → Bench Press → Barbell Lift…),
/// 3. the field default, with subclass overrides applied,
/// 4. for computed fields, the formula over the values above.
@MainActor
public struct ObjectStore {
    public enum StoreError: Error, Equatable {
        case unknownField(String)
        case wrongKind(field: String, expected: [FieldKind])
        case targetNotAllowed(field: String)
        case notAnOption(field: String, value: String)
    }

    public let context: ModelContext
    private let cache = Cache()

    public init(context: ModelContext) {
        self.context = context
    }

    /// Class-object lookups are cached per store, because every inherited value read walks the lineage.
    /// Writes through this store keep it current; call this after changing objects some other way.
    public func invalidateCaches() {
        cache.classObjects.removeAll()
    }

    // MARK: Creating & deleting

    @discardableResult
    public func create(_ classDef: ClassDef, title: String = "", parent: ObjectRecord? = nil) -> ObjectRecord {
        let siblings = parent?.children?.count ?? 0
        let object = ObjectRecord(title: title, classDef: classDef, parent: parent)
        object.sortIndex = siblings
        context.insert(object)
        if parent == nil, title == classDef.name {
            cache.classObjects[classDef.id] = nil
        }
        return object
    }

    /// Soft-deletes the object and everything composed inside it.
    public func softDelete(_ object: ObjectRecord, at date: Date = .now) {
        cache.classObjects.removeAll()
        object.deletedAt = date
        for child in object.children ?? [] where !child.isDeleted {
            softDelete(child, at: date)
        }
    }

    public func restore(_ object: ObjectRecord) {
        cache.classObjects.removeAll()
        object.deletedAt = nil
        for child in object.children ?? [] {
            restore(child)
        }
    }

    // MARK: Queries

    /// Live objects of a class (and by default its subclasses), oldest first. Class objects are excluded.
    public func objects(of classDef: ClassDef, includingSubclasses: Bool = true) -> [ObjectRecord] {
        let classes = includingSubclasses ? ClassResolver.descendants(of: classDef) : [classDef]
        let classObjectIDs = Set(classes.compactMap { classObject(of: $0)?.id })
        return classes
            .flatMap { $0.objects ?? [] }
            .filter { !$0.isDeleted && !$0.isClassObject && !classObjectIDs.contains($0.id) }
            .sorted { ($0.createdAt, $0.sortIndex) < ($1.createdAt, $1.sortIndex) }
    }

    public func object(id: UUID) -> ObjectRecord? {
        try? context.fetch(FetchDescriptor<ObjectRecord>(predicate: #Predicate { $0.id == id })).first
    }

    public func classDef(id: UUID) -> ClassDef? {
        try? context.fetch(FetchDescriptor<ClassDef>(predicate: #Predicate { $0.id == id })).first
    }

    // MARK: Class objects

    /// The object that holds class-level values for `classDef` (Bench Press's muscles, cues, rest).
    /// Also recognises the older convention: a top-level object titled with the class's name.
    public func classObject(of classDef: ClassDef) -> ObjectRecord? {
        if let cached = cache.classObjects[classDef.id] {
            return cached
        }
        let found = fetchClassObject(of: classDef)
        cache.classObjects[classDef.id] = .some(found)
        return found
    }

    private func fetchClassObject(of classDef: ClassDef) -> ObjectRecord? {
        let classID = classDef.id
        var flagged = FetchDescriptor<ObjectRecord>(predicate: #Predicate {
            $0.isClassObject && $0.deletedAt == nil && $0.classDef?.id == classID
        }, sortBy: [SortDescriptor(\.createdAt)])
        flagged.fetchLimit = 1
        if let object = try? context.fetch(flagged).first {
            return object
        }
        let name = classDef.name
        var legacy = FetchDescriptor<ObjectRecord>(predicate: #Predicate {
            $0.parent == nil && $0.title == name && $0.deletedAt == nil && $0.classDef?.id == classID
        }, sortBy: [SortDescriptor(\.createdAt)])
        legacy.fetchLimit = 1
        return try? context.fetch(legacy).first
    }

    /// Returns the class object, creating it if needed.
    @discardableResult
    public func ensureClassObject(of classDef: ClassDef) -> ObjectRecord {
        if let existing = classObject(of: classDef) {
            if !existing.isClassObject {
                existing.isClassObject = true
            }
            return existing
        }
        let object = create(classDef, title: classDef.name)
        object.isClassObject = true
        cache.classObjects[classDef.id] = .some(object)
        return object
    }

    /// Class objects that `object` inherits values from, nearest first. Excludes `object` itself.
    private func inheritedClassObjects(for object: ObjectRecord) -> [ObjectRecord] {
        guard let classDef = object.classDef else { return [] }
        return ClassResolver.lineage(of: classDef).reversed()
            .compactMap(classObject(of:))
            .filter { $0.id != object.id }
    }

    // MARK: Values

    /// Own value, else inherited from a class object, else the class default, else the computed result.
    public func value(_ key: String, of object: ObjectRecord) -> FieldValue? {
        guard let classDef = object.classDef, let field = ClassResolver.field(key, of: classDef) else { return nil }
        let fields = ClassResolver.effectiveFields(of: classDef)
        return value(of: field, in: object, fields: fields, depth: 0)
    }

    public func number(_ key: String, of object: ObjectRecord) -> Double? {
        value(key, of: object)?.numericValue
    }

    /// Whether the object stores its own value (rather than inheriting or defaulting). The object page marks the rest
    /// ↑.
    public func hasOwnValue(_ key: String, on object: ObjectRecord) -> Bool {
        guard let field = object.classDef.flatMap({ ClassResolver.field(key, of: $0) }) else { return false }
        if field.kind.isLink {
            return (object.outgoingLinks ?? []).contains { $0.fieldID == field.id }
        }
        return object.values[field.id] != nil
    }

    /// Stores a value; nil clears it so the object inherits again. The value's kind must match the field.
    public func set(_ key: String, to newValue: FieldValue?, on object: ObjectRecord) throws {
        guard let classDef = object.classDef, let field = ClassResolver.field(key, of: classDef) else {
            throw StoreError.unknownField(key)
        }
        guard field.kind != .computed, !field.kind.isLink else {
            throw StoreError.wrongKind(field: key, expected: [field.kind])
        }
        if let newValue {
            guard newValue.kind == field.kind else { throw StoreError.wrongKind(field: key, expected: [field.kind]) }
            if case let .choice(option) = newValue, !field.enumOptions.isEmpty, !field.enumOptions.contains(option) {
                throw StoreError.notAnOption(field: key, value: option)
            }
        }
        var values = object.values
        values[field.id] = newValue
        object.values = values
    }

    private func value(of field: ResolvedField, in object: ObjectRecord, fields: [ResolvedField],
                       depth: Int) -> FieldValue?
    {
        if field.kind == .computed {
            guard depth < 8, let source = field.expression, let formula = try? Formula.parse(source) else {
                return nil
            }
            let result = formula.evaluate { name in
                guard let dependency = fields.first(where: { $0.key == name }) else { return nil }
                return value(of: dependency, in: object, fields: fields, depth: depth + 1)?.numericValue
            }
            return result.map(FieldValue.number)
        }
        if let own = object.values[field.id] {
            return own
        }
        for classObject in inheritedClassObjects(for: object) {
            if let inherited = classObject.values[field.id] {
                return inherited
            }
        }
        return field.defaultValue
    }

    // MARK: Links

    /// Replaces the targets of a `.ref` / `.refList` field. An empty list clears the object's own links,
    /// so it inherits its class object's links again.
    public func setLinks(_ key: String, on object: ObjectRecord, to targets: [ObjectRecord]) throws {
        let field = try linkField(key, of: object, kinds: [.ref, .refList])
        if field.kind == .ref, targets.count > 1 {
            throw StoreError.wrongKind(field: key, expected: [.refList])
        }
        if let targetID = field.targetClassID {
            for target in targets {
                guard let targetClass = target.classDef,
                      ClassResolver.isSubclass(targetClass, ofClassID: targetID)
                else {
                    throw StoreError.targetNotAllowed(field: key)
                }
            }
        }
        removeLinks(fieldID: field.id, from: object)
        for (index, target) in targets.enumerated() {
            context.insert(ObjectLink(from: object, fieldID: field.id, toObject: target, sortIndex: index))
        }
    }

    /// Points a `.classRef` field at a class (e.g. an exercise entry → `BenchPress`).
    public func setClassLink(_ key: String, on object: ObjectRecord, to target: ClassDef?) throws {
        let field = try linkField(key, of: object, kinds: [.classRef])
        if let target, let targetID = field.targetClassID, !ClassResolver.isSubclass(target, ofClassID: targetID) {
            throw StoreError.targetNotAllowed(field: key)
        }
        removeLinks(fieldID: field.id, from: object)
        if let target {
            context.insert(ObjectLink(from: object, fieldID: field.id, toClass: target))
        }
    }

    /// Linked objects in order: the object's own links, else the nearest class object's.
    public func linkedObjects(_ key: String, of object: ObjectRecord) -> [ObjectRecord] {
        guard let field = object.classDef.flatMap({ ClassResolver.field(key, of: $0) }) else { return [] }
        for source in [object] + inheritedClassObjects(for: object) {
            let links = (source.outgoingLinks ?? []).filter { $0.fieldID == field.id }
            if !links.isEmpty {
                return links.sorted { $0.sortIndex < $1.sortIndex }.compactMap(\.toObject).filter { !$0.isDeleted }
            }
        }
        return []
    }

    public func linkedClass(_ key: String, of object: ObjectRecord) -> ClassDef? {
        guard let field = object.classDef.flatMap({ ClassResolver.field(key, of: $0) }) else { return nil }
        for source in [object] + inheritedClassObjects(for: object) {
            if let target = (source.outgoingLinks ?? []).first(where: { $0.fieldID == field.id })?.toClass {
                return target
            }
        }
        return nil
    }

    /// Objects linked from a class itself, through its class object chain (e.g. Bench Press → its muscles).
    public func linkedObjects(_ key: String, ofClass classDef: ClassDef) -> [ObjectRecord] {
        // The nearest class object up the chain; its own lookup continues further up.
        guard let nearest = ClassResolver.lineage(of: classDef).reversed().lazy.compactMap(classObject(of:)).first
        else { return [] }
        return linkedObjects(key, of: nearest)
    }

    /// Live objects that link to `object` ("mentioned in…").
    public func backlinks(to object: ObjectRecord) -> [ObjectRecord] {
        uniqueLiveSources(object.incomingLinks ?? [])
    }

    /// Live objects that link to `classDef` or any of its subclasses (e.g. every entry of any barbell lift).
    public func backlinks(to classDef: ClassDef, includingSubclasses: Bool = false) -> [ObjectRecord] {
        let classes = includingSubclasses ? ClassResolver.descendants(of: classDef) : [classDef]
        return uniqueLiveSources(classes.flatMap { $0.incomingLinks ?? [] })
    }

    /// Walks up the composition tree to the nearest ancestor of a class (e.g. a set → its workout).
    public func ancestor(of object: ObjectRecord, ofClass classDef: ClassDef) -> ObjectRecord? {
        var current = object.parent
        var seen = Set<UUID>()
        while let node = current, seen.insert(node.id).inserted {
            if let nodeClass = node.classDef, ClassResolver.isSubclass(nodeClass, of: classDef) {
                return node
            }
            current = node.parent
        }
        return nil
    }

    // MARK: Paths

    /// The class path, then the composition chain: `/activity/workout/push-day-a/bench-press/set-2`.
    /// Untitled objects are named after a linked class (an entry → "Bench Press") or their class and position.
    public func path(of object: ObjectRecord) -> ObjectPath {
        var chain: [ObjectRecord] = []
        var seen = Set<UUID>()
        var current: ObjectRecord? = object
        while let node = current, seen.insert(node.id).inserted {
            chain.append(node)
            current = node.parent
        }
        chain.reverse()
        var path = chain.first?.classDef.map(ClassResolver.path(of:)) ?? ObjectPath(segments: [])
        for node in chain where !node.isClassObject {
            path = path.appending(.init(target: .object(node.id), title: displayTitle(of: node)))
        }
        return path
    }

    /// The object's title, or a stand-in for untitled objects such as sets and entries.
    public func displayTitle(of object: ObjectRecord) -> String {
        if !object.title.isEmpty {
            return object.title
        }
        let linkedClass = (object.outgoingLinks ?? []).compactMap(\.toClass).first
        if let linkedClass {
            return linkedClass.name
        }
        let className = object.classDef?.name ?? "Object"
        guard let siblings = object.parent?.orderedChildren,
              let index = siblings.firstIndex(where: { $0.id == object.id }) else { return className }
        return "\(className) \(index + 1)"
    }

    // MARK: Private

    private func linkField(_ key: String, of object: ObjectRecord, kinds: [FieldKind]) throws -> ResolvedField {
        guard let classDef = object.classDef, let field = ClassResolver.field(key, of: classDef) else {
            throw StoreError.unknownField(key)
        }
        guard kinds.contains(field.kind) else { throw StoreError.wrongKind(field: key, expected: kinds) }
        return field
    }

    private func removeLinks(fieldID: UUID, from object: ObjectRecord) {
        for link in object.outgoingLinks ?? [] where link.fieldID == fieldID {
            object.outgoingLinks?.removeAll { $0.id == link.id }
            context.delete(link)
        }
    }

    private func uniqueLiveSources(_ links: [ObjectLink]) -> [ObjectRecord] {
        var seen = Set<UUID>()
        return links.compactMap(\.from)
            .filter { !$0.isDeleted && seen.insert($0.id).inserted }
            .sorted { $0.createdAt < $1.createdAt }
    }
}

/// Per-store lookup cache. `classObjects[id] == .some(nil)` caches "this class has no class object".
@MainActor
private final class Cache {
    var classObjects: [UUID: ObjectRecord?] = [:]
}
