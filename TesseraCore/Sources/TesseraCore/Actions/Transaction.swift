import Foundation

/// The write surface inside one action. Every change goes through here, applies to the store immediately and
/// is recorded as an `Op`, so the whole action can be undone, redone or rolled back if it throws halfway.
@MainActor
public struct Transaction {
    public let store: ObjectStore
    public let classes: [SystemCatalog.Key: ClassDef]
    public private(set) var ops: [Op] = []
    /// The engine's clock and calendar when this action started (not `Date.now`: the app and the test world set
    /// theirs).
    public let now: Date
    public let calendar: Calendar

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef], now: Date = .now,
                calendar: Calendar = .current)
    {
        self.store = store
        self.classes = classes
        self.now = now
        self.calendar = calendar
    }

    // MARK: Lookup

    public func object(_ id: UUID) throws -> ObjectRecord {
        guard let object = store.object(id: id), !object.isDeleted else { throw ActionError.objectNotFound(id) }
        return object
    }

    public func object(_ id: UUID, is key: SystemCatalog.Key) throws -> ObjectRecord {
        let object = try object(id)
        guard let expected = classes[key], let classDef = object.classDef,
              store.isSubclass(classDef, ofClassID: expected.id)
        else { throw ActionError.wrongClass(id, expected: key.rawValue) }
        return object
    }

    public func classDef(_ key: SystemCatalog.Key) throws -> ClassDef {
        guard let classDef = classes[key] else { throw ActionError.missingSystemClass(key.rawValue) }
        return classDef
    }

    // MARK: Writes

    @discardableResult
    public mutating func create(_ classDef: ClassDef, title: String = "", parent: ObjectRecord? = nil,
                                id: UUID? = nil) -> ObjectRecord
    {
        let object = store.create(classDef, title: title, parent: parent, id: id)
        ops.append(.create(object: object.id, classID: classDef.id, parent: parent?.id, title: title))
        return object
    }

    public mutating func set(_ key: String, to value: FieldValue?, on object: ObjectRecord) throws {
        guard let field = object.classDef.flatMap({ store.field(key, of: $0) }) else {
            throw ObjectStore.StoreError.unknownField(key)
        }
        let old = object.values[field.id]
        guard old != value else { return }
        try store.set(key, to: value, on: object)
        ops.append(.setValue(object: object.id, field: field.id, old: old, new: value))
    }

    public mutating func setLinks(_ key: String, on object: ObjectRecord, to targets: [ObjectRecord]) throws {
        let fieldID = try linkFieldID(key, of: object)
        let old = store.ownLinkTargets(fieldID: fieldID, of: object)
        let new = targets.map { LinkTarget.object($0.id) }
        guard old != new else { return }
        try store.setLinks(key, on: object, to: targets)
        ops.append(.setLinks(object: object.id, field: fieldID, old: old, new: new))
    }

    public mutating func setClassLink(_ key: String, on object: ObjectRecord, to target: ClassDef?) throws {
        let fieldID = try linkFieldID(key, of: object)
        let old = store.ownLinkTargets(fieldID: fieldID, of: object)
        let new = target.map { [LinkTarget.classDef($0.id)] } ?? []
        guard old != new else { return }
        try store.setClassLink(key, on: object, to: target)
        ops.append(.setLinks(object: object.id, field: fieldID, old: old, new: new))
    }

    public mutating func setSortIndex(_ index: Int, on object: ObjectRecord) {
        guard object.sortIndex != index else { return }
        ops.append(.setSortIndex(object: object.id, old: object.sortIndex, new: index))
        object.sortIndex = index
        store.noteChange(object)
    }

    public mutating func setTitle(_ title: String, on object: ObjectRecord) {
        guard object.title != title else { return }
        ops.append(.setTitle(object: object.id, old: object.title, new: title))
        object.title = title
        object.updatedAt = .now
        store.noteChange(object)
    }

    /// Creates a user class and logs it; undo removes it while nothing uses it.
    @discardableResult
    public mutating func createClass(name: String, parent: ClassDef?, symbolName: String = "circle",
                                     colorRole: String = "neutral") -> ClassDef
    {
        let classDef = store.createClass(name: name, parent: parent, symbolName: symbolName, colorRole: colorRole)
        ops.append(.createClass(classID: classDef.id, parent: parent?.id, name: name, symbolName: symbolName,
                                colorRole: colorRole))
        return classDef
    }

    /// Soft-deletes the object and its children; undo restores them.
    public mutating func delete(_ object: ObjectRecord) {
        guard !object.isDeleted else { return }
        store.softDelete(object)
        ops.append(.softDelete(object: object.id))
    }

    private func linkFieldID(_ key: String, of object: ObjectRecord) throws -> UUID {
        guard let field = object.classDef.flatMap({ store.field(key, of: $0) }) else {
            throw ObjectStore.StoreError.unknownField(key)
        }
        return field.id
    }
}

public enum ActionError: Error, Equatable {
    case unknownAction(String)
    case invalidArguments(action: String, reason: String)
    case objectNotFound(UUID)
    case wrongClass(UUID, expected: String)
    case missingSystemClass(String)
    case notPending(UUID)
}
