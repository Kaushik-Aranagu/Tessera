import Foundation
import SwiftData

/// Reads and writes objects through their class's resolved fields: defaults, computed values,
/// typed links and backlinks. Views talk to this, not to raw `valuesData`.
@MainActor
struct ObjectStore {
    enum StoreError: Error, Equatable {
        case unknownField(String)
        case wrongKind(field: String, expected: [FieldKind])
        case targetNotAllowed(field: String)
    }

    let context: ModelContext

    // MARK: Creating & deleting

    @discardableResult
    func create(_ classDef: ClassDef, title: String = "", parent: ObjectRecord? = nil) -> ObjectRecord {
        let object = ObjectRecord(title: title, classDef: classDef, parent: parent)
        object.sortIndex = parent?.children?.count ?? 0
        context.insert(object)
        return object
    }

    /// Soft-deletes the object and everything composed inside it.
    func softDelete(_ object: ObjectRecord, at date: Date = .now) {
        object.deletedAt = date
        for child in object.children ?? [] where !child.isDeleted {
            softDelete(child, at: date)
        }
    }

    func restore(_ object: ObjectRecord) {
        object.deletedAt = nil
        for child in object.children ?? [] {
            restore(child)
        }
    }

    // MARK: Values

    /// Stored value, else the (possibly overridden) class default, else the computed result.
    func value(_ key: String, of object: ObjectRecord) -> FieldValue? {
        guard let classDef = object.classDef, let field = ClassResolver.field(key, of: classDef) else { return nil }
        return value(of: field, in: object, classDef: classDef, depth: 0)
    }

    func number(_ key: String, of object: ObjectRecord) -> Double? {
        value(key, of: object)?.numericValue
    }

    func set(_ key: String, to newValue: FieldValue?, on object: ObjectRecord) throws {
        guard let classDef = object.classDef, let field = ClassResolver.field(key, of: classDef) else {
            throw StoreError.unknownField(key)
        }
        guard ![.computed, .ref, .refList, .classRef].contains(field.kind) else {
            throw StoreError.wrongKind(field: key, expected: [field.kind])
        }
        var values = object.values
        values[field.id] = newValue
        object.values = values
    }

    private func value(of field: ResolvedField, in object: ObjectRecord, classDef: ClassDef,
                       depth: Int) -> FieldValue?
    {
        if field.kind == .computed {
            guard depth < 8, let source = field.expression, let expression = try? Expression.parse(source) else {
                return nil
            }
            let fields = ClassResolver.effectiveFields(of: classDef)
            let result = expression.evaluate { name in
                guard let dependency = fields.first(where: { $0.key == name }) else { return nil }
                return value(of: dependency, in: object, classDef: classDef, depth: depth + 1)?.numericValue
            }
            return result.map(FieldValue.number)
        }
        return object.values[field.id] ?? field.defaultValue
    }

    // MARK: Links

    /// Replaces the targets of a `.ref` / `.refList` field.
    func setLinks(_ key: String, on object: ObjectRecord, to targets: [ObjectRecord]) throws {
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
    func setClassLink(_ key: String, on object: ObjectRecord, to target: ClassDef?) throws {
        let field = try linkField(key, of: object, kinds: [.classRef])
        if let target, let targetID = field.targetClassID, !ClassResolver.isSubclass(target, ofClassID: targetID) {
            throw StoreError.targetNotAllowed(field: key)
        }
        removeLinks(fieldID: field.id, from: object)
        if let target {
            context.insert(ObjectLink(from: object, fieldID: field.id, toClass: target))
        }
    }

    func linkedObjects(_ key: String, of object: ObjectRecord) -> [ObjectRecord] {
        guard let field = object.classDef.flatMap({ ClassResolver.field(key, of: $0) }) else { return [] }
        return (object.outgoingLinks ?? [])
            .filter { $0.fieldID == field.id }
            .sorted { $0.sortIndex < $1.sortIndex }
            .compactMap(\.toObject)
            .filter { !$0.isDeleted }
    }

    func linkedClass(_ key: String, of object: ObjectRecord) -> ClassDef? {
        guard let field = object.classDef.flatMap({ ClassResolver.field(key, of: $0) }) else { return nil }
        return (object.outgoingLinks ?? []).first { $0.fieldID == field.id }?.toClass
    }

    /// Live objects that link to `object` ("mentioned in…").
    func backlinks(to object: ObjectRecord) -> [ObjectRecord] {
        uniqueLiveSources(object.incomingLinks ?? [])
    }

    /// Live objects that link to `classDef` or any of its subclasses (e.g. every entry of any barbell lift).
    func backlinks(to classDef: ClassDef, includingSubclasses: Bool = false) -> [ObjectRecord] {
        var links = classDef.incomingLinks ?? []
        if includingSubclasses {
            var stack = classDef.subclasses ?? []
            var seen: Set<UUID> = [classDef.id]
            while let next = stack.popLast(), seen.insert(next.id).inserted {
                links += next.incomingLinks ?? []
                stack += next.subclasses ?? []
            }
        }
        return uniqueLiveSources(links)
    }

    /// Walks up the composition tree to the nearest ancestor of a class (e.g. a set → its workout).
    func ancestor(of object: ObjectRecord, ofClass classDef: ClassDef) -> ObjectRecord? {
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
