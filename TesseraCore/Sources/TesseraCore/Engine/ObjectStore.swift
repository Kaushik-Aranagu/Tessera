import Foundation

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

    public let context: TesseraContext
    let cache = Cache()

    public init(context: TesseraContext) {
        self.context = context
    }

    /// Class-object lookups are cached per store, because every inherited value read walks the lineage.
    /// Writes through this store keep it current; call this after changing objects some other way.
    /// Call after editing classes or fields (the class editor does), so resolved fields are rebuilt.
    public func invalidateCaches() {
        cache.classObjects.removeAll()
        cache.classInfo.removeAll()
        noteChange()
    }

    // MARK: Creating & deleting

    @discardableResult
    public func create(_ classDef: ClassDef, title: String = "", parent: ObjectRecord? = nil,
                       id: UUID? = nil) -> ObjectRecord
    {
        let siblings = parent?.children?.count ?? 0
        // Insert first, then relate: SwiftData maintains a to-many inverse (Bench Press → every object) far
        // faster for an inserted object; relating in the initializer made long histories quadratic.
        let object = ObjectRecord(title: title, classDef: nil)
        if let id {
            object.id = id
        }
        object.sortIndex = siblings
        context.insert(object)
        object.classDef = classDef
        object.parent = parent
        noteChange(object)
        return object
    }

    /// Soft-deletes the object and everything composed inside it.
    public func softDelete(_ object: ObjectRecord, at date: Date = .now) {
        noteChange(object)
        cache.classObjects.removeAll()
        object.deletedAt = date
        for child in object.children ?? [] where !child.isDeleted {
            softDelete(child, at: date)
        }
    }

    /// Brings an object back with the children that went with it; children deleted earlier (a cleared list item)
    /// stay deleted.
    public func restore(_ object: ObjectRecord) {
        noteChange(object)
        cache.classObjects.removeAll()
        let deletedAt = object.deletedAt
        object.deletedAt = nil
        for child in object.children ?? [] where deletedAt == nil || child.deletedAt == deletedAt {
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
            // Ties (same instant) break by id: UUIDv7 ids sort by creation.
            .sorted { ($0.createdAt, $0.sortIndex, $0.id.uuidString) < ($1.createdAt, $1.sortIndex, $1.id.uuidString) }
    }

    public func object(id: UUID) -> ObjectRecord? {
        context.objects[id]
    }

    public func classDef(id: UUID) -> ClassDef? {
        context.classes[id]
    }

    // MARK: Class objects

    /// The object that holds class-level values for `classDef` (Bench Press's muscles, cues, rest).
    /// Only objects flagged `isClassObject` count: matching by title made an ordinary workout titled
    /// "Workout" vanish into the Workout class.
    public func classObject(of classDef: ClassDef) -> ObjectRecord? {
        if let cached = cache.classObjects[classDef.id] {
            return cached
        }
        let found = fetchClassObject(of: classDef)
        cache.classObjects[classDef.id] = .some(found)
        return found
    }

    private func fetchClassObject(of classDef: ClassDef) -> ObjectRecord? {
        (classDef.objects ?? []).filter { $0.isClassObject && !$0.isDeleted }.min { $0.createdAt < $1.createdAt }
    }

    /// Returns the class object, creating it if needed.
    @discardableResult
    public func ensureClassObject(of classDef: ClassDef) -> ObjectRecord {
        if let existing = classObject(of: classDef) {
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
        return lineage(of: classDef).reversed()
            .compactMap(classObject(of:))
            .filter { $0.id != object.id }
    }

    // MARK: Values

    /// A class-level value: the nearest class object up the lineage that sets it, else the field's default.
    /// (Bench Press's rep range, rest or progression, without needing an instance.)
    public func classValue(_ key: String, of classDef: ClassDef) -> FieldValue? {
        guard let field = field(key, of: classDef) else { return nil }
        for node in lineage(of: classDef).reversed() {
            if let object = classObject(of: node), let value = object.values[field.id] {
                return value
            }
        }
        return field.defaultValue
    }

    /// Own value, else inherited from a class object, else the class default, else the computed result.
    public func value(_ key: String, of object: ObjectRecord) -> FieldValue? {
        guard let classDef = object.classDef, let field = field(key, of: classDef) else { return nil }
        let fields = classInfo(classDef).fields
        return value(of: field, in: object, fields: fields, depth: 0)
    }

    public func number(_ key: String, of object: ObjectRecord) -> Double? {
        value(key, of: object)?.numericValue
    }

    /// Whether the object stores its own value (rather than inheriting or defaulting). The object page marks the rest
    /// ↑.
    public func hasOwnValue(_ key: String, on object: ObjectRecord) -> Bool {
        guard let field = object.classDef.flatMap({ field(key, of: $0) }) else { return false }
        if field.kind.isLink {
            return (object.outgoingLinks ?? []).contains { $0.fieldID == field.id }
        }
        return object.values[field.id] != nil
    }

    /// Stores a value; nil clears it so the object inherits again. The value's kind must match the field.
    public func set(_ key: String, to newValue: FieldValue?, on object: ObjectRecord) throws {
        noteChange(object)
        guard let classDef = object.classDef, let field = field(key, of: classDef) else {
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
            guard depth < 8, let source = field.expression, let formula = formula(source) else {
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
        noteChange(object)
        let field = try linkField(key, of: object, kinds: [.ref, .refList])
        if field.kind == .ref, targets.count > 1 {
            throw StoreError.wrongKind(field: key, expected: [.refList])
        }
        if let targetID = field.targetClassID {
            for target in targets {
                guard let targetClass = target.classDef,
                      isSubclass(targetClass, ofClassID: targetID)
                else {
                    throw StoreError.targetNotAllowed(field: key)
                }
            }
        }
        removeLinks(fieldID: field.id, from: object)
        for (index, target) in targets.enumerated() {
            insertLink(from: object, fieldID: field.id, toObject: target, sortIndex: index)
        }
    }

    /// Points a `.classRef` field at a class (e.g. an exercise entry → `BenchPress`).
    public func setClassLink(_ key: String, on object: ObjectRecord, to target: ClassDef?) throws {
        noteChange(object)
        let field = try linkField(key, of: object, kinds: [.classRef])
        if let target, let targetID = field.targetClassID, !isSubclass(target, ofClassID: targetID) {
            throw StoreError.targetNotAllowed(field: key)
        }
        removeLinks(fieldID: field.id, from: object)
        if let target {
            insertLink(from: object, fieldID: field.id, toClass: target)
        }
    }

    /// Linked objects in order: the object's own links, else the nearest class object's.
    public func linkedObjects(_ key: String, of object: ObjectRecord) -> [ObjectRecord] {
        guard let field = object.classDef.flatMap({ field(key, of: $0) }) else { return [] }
        for source in [object] + inheritedClassObjects(for: object) {
            let links = (source.outgoingLinks ?? []).filter { $0.fieldID == field.id }
            if !links.isEmpty {
                return links.sorted { $0.sortIndex < $1.sortIndex }.compactMap(\.toObject).filter { !$0.isDeleted }
            }
        }
        return []
    }

    public func linkedClass(_ key: String, of object: ObjectRecord) -> ClassDef? {
        guard let field = object.classDef.flatMap({ field(key, of: $0) }) else { return nil }
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
        guard let nearest = lineage(of: classDef).reversed().lazy.compactMap(classObject(of:)).first
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
            if let nodeClass = node.classDef, isSubclass(nodeClass, ofClassID: classDef.id) {
                return node
            }
            current = node.parent
        }
        return nil
    }

    // MARK: Raw access for the op log

    /// The object's own link targets for a field, in order (not inherited ones).
    func ownLinkTargets(fieldID: UUID, of object: ObjectRecord) -> [LinkTarget] {
        (object.outgoingLinks ?? [])
            .filter { $0.fieldID == fieldID }
            .sorted { $0.sortIndex < $1.sortIndex }
            .compactMap { link in
                if let target = link.toObject {
                    return .object(target.id)
                }
                if let target = link.toClass {
                    return .classDef(target.id)
                }
                return nil
            }
    }

    /// Writes a stored value by field id, bypassing key lookup and validation (used to replay and revert ops).
    func setRaw(fieldID: UUID, to value: FieldValue?, on object: ObjectRecord) {
        noteChange(object)
        var values = object.values
        values[fieldID] = value
        object.values = values
    }

    /// Replaces a field's links by id (used to replay and revert ops). Targets that no longer exist are skipped.
    func setLinksRaw(fieldID: UUID, on object: ObjectRecord, to targets: [LinkTarget]) {
        noteChange(object)
        removeLinks(fieldID: fieldID, from: object)
        for (index, target) in targets.enumerated() {
            switch target {
            case let .object(id):
                guard let target = self.object(id: id) else { continue }
                insertLink(from: object, fieldID: fieldID, toObject: target, sortIndex: index)
            case let .classDef(id):
                guard let target = classDef(id: id) else { continue }
                insertLink(from: object, fieldID: fieldID, toClass: target, sortIndex: index)
            }
        }
    }

    // MARK: Private

    private func linkField(_ key: String, of object: ObjectRecord, kinds: [FieldKind]) throws -> ResolvedField {
        guard let classDef = object.classDef, let field = field(key, of: classDef) else {
            throw StoreError.unknownField(key)
        }
        guard kinds.contains(field.kind) else { throw StoreError.wrongKind(field: key, expected: kinds) }
        return field
    }

    /// Inserts a link, then relates it (see `create` for why the order matters).
    private func insertLink(from source: ObjectRecord, fieldID: UUID, toObject: ObjectRecord? = nil,
                            toClass: ClassDef? = nil, sortIndex: Int = 0)
    {
        let link = ObjectLink(fieldID: fieldID, sortIndex: sortIndex)
        context.insert(link)
        link.from = source
        link.toObject = toObject
        link.toClass = toClass
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
