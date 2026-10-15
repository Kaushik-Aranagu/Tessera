import Foundation

/// Plain JSON of everything: the schema (classes and fields), every object with its values, every link, and the
/// operation log. Lossless, so it restores into an empty store; readable, so it's useful outside Tessera too.
public struct TesseraExport: Codable, Sendable {
    public static let format = "tessera-export"
    public static let currentVersion = 1

    public struct Field: Codable, Sendable {
        public var id: UUID
        public var key: String
        public var name: String
        public var kind: FieldKind
        public var sortIndex: Int
        public var isRequired: Bool
        public var unit: String?
        public var options: [String]
        public var targetClassID: UUID?
        public var expression: String?
        public var defaultValue: FieldValue?
        public var overridesFieldID: UUID?
        public var isUserModified: Bool?
    }

    public struct ClassEntry: Codable, Sendable {
        public var id: UUID
        public var name: String
        public var parentID: UUID?
        public var systemKey: String?
        public var symbolName: String
        public var colorRole: String
        public var traits: [String]
        public var sortIndex: Int
        public var createdAt: Date
        public var packageID: String?
        public var packageVersion: Int?
        public var isUserModified: Bool?
        public var fields: [Field]
    }

    public struct ObjectEntry: Codable, Sendable {
        public var id: UUID
        public var classID: UUID?
        public var parentID: UUID?
        public var title: String
        public var sortIndex: Int
        public var createdAt: Date
        public var updatedAt: Date
        public var deletedAt: Date?
        public var isClassObject: Bool
        /// Keyed by field id (stable). `fieldKeys` at the top level names them.
        public var values: [String: FieldValue]
    }

    public struct LinkEntry: Codable, Sendable {
        public var id: UUID
        public var fieldID: UUID
        public var from: UUID?
        public var toObject: UUID?
        public var toClass: UUID?
        public var sortIndex: Int
        public var createdAt: Date
    }

    public struct OpEntry: Codable, Sendable {
        public var id: UUID
        public var action: String
        public var actor: Actor
        public var state: OpState
        public var summary: String
        public var createdAt: Date
        public var updatedAt: Date
        public var ops: [Op]
    }

    public var format = Self.format
    public var version = Self.currentVersion
    public var exportedAt: Date
    /// Field id → key, so `values` can be read without the schema.
    public var fieldKeys: [String: String]
    public var classes: [ClassEntry]
    public var objects: [ObjectEntry]
    public var links: [LinkEntry]
    public var operations: [OpEntry]
}

public enum ExportError: Error, Equatable {
    case notAnExport
    case newerVersion(Int)
    case storeNotEmpty
}

@MainActor
public extension TesseraExport {
    /// Reads the whole store.
    init(context: TesseraContext, now: Date = .now) throws {
        let classDefs = context.all(ClassDef.self).sorted { $0.createdAt < $1.createdAt }
        let records = context.all(ObjectRecord.self).sorted { $0.createdAt < $1.createdAt }
        let objectLinks = context.all(ObjectLink.self).sorted { $0.createdAt < $1.createdAt }
        let opRecords = context.all(OpRecord.self).sorted { $0.createdAt < $1.createdAt }

        exportedAt = now
        classes = classDefs.map { classDef in
            ClassEntry(
                id: classDef.id, name: classDef.name, parentID: classDef.parent?.id, systemKey: classDef.systemKey,
                symbolName: classDef.symbolName, colorRole: classDef.colorRole, traits: classDef.traitsRaw,
                sortIndex: classDef.sortIndex, createdAt: classDef.createdAt, packageID: classDef.packageID,
                packageVersion: classDef.packageVersion, isUserModified: classDef.isUserModified,
                fields: (classDef.ownFields ?? []).sorted { $0.sortIndex < $1.sortIndex }.map { field in
                    Field(id: field.id, key: field.key, name: field.name, kind: field.kind, sortIndex: field.sortIndex,
                          isRequired: field.isRequired, unit: field.unit, options: field.enumOptions,
                          targetClassID: field.targetClassID, expression: field.expression,
                          defaultValue: field.defaultValue, overridesFieldID: field.overridesFieldID,
                          isUserModified: field.isUserModified)
                }
            )
        }
        fieldKeys = Dictionary(classes.flatMap(\.fields).map { ($0.id.uuidString, $0.key) },
                               uniquingKeysWith: { first, _ in first })
        objects = records.map { record in
            ObjectEntry(
                id: record.id, classID: record.classDef?.id, parentID: record.parent?.id, title: record.title,
                sortIndex: record.sortIndex, createdAt: record.createdAt, updatedAt: record.updatedAt,
                deletedAt: record.deletedAt, isClassObject: record.isClassObject,
                values: Dictionary(uniqueKeysWithValues: record.values.storage.map { ($0.key.uuidString, $0.value) })
            )
        }
        links = objectLinks.map { link in
            LinkEntry(id: link.id, fieldID: link.fieldID, from: link.from?.id, toObject: link.toObject?.id,
                      toClass: link.toClass?.id, sortIndex: link.sortIndex, createdAt: link.createdAt)
        }
        operations = opRecords.map { record in
            OpEntry(id: record.id, action: record.action, actor: record.actor, state: record.state,
                    summary: record.summary, createdAt: record.createdAt, updatedAt: record.updatedAt, ops: record.ops)
        }
    }

    /// Pretty, stable JSON (sorted keys, ISO 8601 dates).
    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }

    static func decode(_ data: Data) throws -> TesseraExport {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let export = try? decoder.decode(TesseraExport.self, from: data), export.format == format else {
            throw ExportError.notAnExport
        }
        guard export.version <= currentVersion else { throw ExportError.newerVersion(export.version) }
        return export
    }

    /// Restores into an empty store, keeping every id, so links, history and the op log stay intact.
    func restore(into context: TesseraContext) throws {
        guard context.count(ObjectRecord.self) == 0, context.count(ClassDef.self) == 0 else {
            throw ExportError.storeNotEmpty
        }

        var classByID: [UUID: ClassDef] = [:]
        for entry in classes {
            let classDef = ClassDef(name: entry.name, symbolName: entry.symbolName, colorRole: entry.colorRole,
                                    systemKey: entry.systemKey)
            classDef.id = entry.id
            classDef.traitsRaw = entry.traits
            classDef.sortIndex = entry.sortIndex
            classDef.createdAt = entry.createdAt
            classDef.packageID = entry.packageID
            classDef.packageVersion = entry.packageVersion ?? 0
            classDef.isUserModified = entry.isUserModified ?? false
            context.insert(classDef)
            classByID[entry.id] = classDef
            for spec in entry.fields {
                let field = FieldDef(name: spec.name, key: spec.key, kind: spec.kind, sortIndex: spec.sortIndex,
                                     unit: spec.unit, defaultValue: spec.defaultValue)
                field.id = spec.id
                field.isRequired = spec.isRequired
                field.enumOptions = spec.options
                field.targetClassID = spec.targetClassID
                field.expression = spec.expression
                field.overridesFieldID = spec.overridesFieldID
                field.isUserModified = spec.isUserModified ?? false
                context.insert(field)
                field.owner = classDef
            }
        }
        for entry in classes {
            classByID[entry.id]?.parent = entry.parentID.flatMap { classByID[$0] }
        }

        var objectByID: [UUID: ObjectRecord] = [:]
        for entry in objects {
            let object = ObjectRecord(title: entry.title, classDef: nil)
            object.id = entry.id
            object.sortIndex = entry.sortIndex
            object.isClassObject = entry.isClassObject
            object.deletedAt = entry.deletedAt
            context.insert(object)
            object.classDef = entry.classID.flatMap { classByID[$0] }
            object
                .values = FieldValues(storage: Dictionary(uniqueKeysWithValues: entry.values.compactMap { key, value in
                    UUID(uuidString: key).map { ($0, value) }
                }))
            object.createdAt = entry.createdAt
            object.updatedAt = entry.updatedAt
            objectByID[entry.id] = object
        }
        for entry in objects {
            objectByID[entry.id]?.parent = entry.parentID.flatMap { objectByID[$0] }
        }
        for entry in links {
            let link = ObjectLink(fieldID: entry.fieldID, sortIndex: entry.sortIndex)
            link.id = entry.id
            link.createdAt = entry.createdAt
            context.insert(link)
            link.from = entry.from.flatMap { objectByID[$0] }
            link.toObject = entry.toObject.flatMap { objectByID[$0] }
            link.toClass = entry.toClass.flatMap { classByID[$0] }
        }
        for entry in operations {
            let record = OpRecord(action: entry.action, actor: entry.actor, summary: entry.summary, ops: entry.ops,
                                  state: entry.state)
            record.id = entry.id
            record.createdAt = entry.createdAt
            record.updatedAt = entry.updatedAt
            context.insert(record)
        }
        try context.save()
    }
}
