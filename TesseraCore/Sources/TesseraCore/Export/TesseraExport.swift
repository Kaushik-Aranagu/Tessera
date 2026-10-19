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
        /// Tess's route and model (older exports leave them out).
        public var route: String?
        public var model: String?
        /// The zone it was logged in (older exports and rows leave it out).
        public var zone: String?
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
    /// Reads the whole store. With `maskingPrivate` (the shared file, G28) every private note, item, recipe or secret
    /// line reads "Private note", "Private item" or "Private recipe": title and field values both, and the op log's
    /// summaries and values for it. Money and body words count as private. Not lossless then, and there is no opt-in in
    /// v1. It defaults to true, so every export masks. `false` is test-only, for lossless round trips; the app never
    /// does it. Anything the person
    /// can send elsewhere must pass `maskingPrivate: true`.
    init(context: TesseraContext, now: Date = .now, maskingPrivate: Bool = true) throws {
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
                    summary: record.summary, createdAt: record.createdAt, updatedAt: record.updatedAt, ops: record.ops,
                    route: record.routeRaw, model: record.model, zone: record.zone)
        }
        if maskingPrivate {
            let local = PrivateWords.localOnlyIDs(in: context)
            if !local.isEmpty {
                objects.removeAll { local.contains($0.id) }
                links
                    .removeAll { link in
                        link.from.map(local.contains) == true || link.toObject.map(local.contains) == true
                    }
                operations.removeAll { entry in entry.ops.contains { local.contains($0.objectID) } }
            }
            let current = PrivateWords.labels(in: context)
            mask(current, past: PrivateWords.historyLabels(in: context, current: current), context: context)
        }
    }

    /// Replaces what the private objects hold with their label; only done flags and dates stay.
    private mutating func mask(_ labels: [UUID: String], past: [UUID: String], context: TesseraContext) {
        guard !labels.isEmpty || !past.isEmpty || operations.contains(where: { PrivateWords.summaryIsPrivate(
            $0.summary,
            context: context
        ) })
        else { return }
        objects = objects.map { entry in
            guard let label = labels[entry.id] else { return entry }
            var masked = entry
            masked.title = label
            masked.values = entry.values.filter { PrivateWords.structural($0.value) }
            return masked
        }
        // The op log also masks what was private once and is plain now.
        let labels = labels.merging(past) { current, _ in current }
        operations = operations.map { entry in
            let touched = entry.ops.compactMap { labels[$0.objectID] }
            let wordy = PrivateWords.summaryIsPrivate(entry.summary, context: context)
            guard !touched.isEmpty || wordy else { return entry }
            var masked = entry
            masked.summary = touched.first ?? SecretWords.title
            masked.ops = entry.ops.map { op in
                guard let label = labels[op.objectID] else { return op }
                switch op {
                case let .create(object, classID, parent, _): return .create(
                        object: object,
                        classID: classID,
                        parent: parent,
                        title: label
                    )
                case let .setTitle(object, _, _): return .setTitle(object: object, old: label, new: label)
                case let .setValue(object, field, old, new):
                    return .setValue(
                        object: object,
                        field: field,
                        old: old.flatMap { PrivateWords.structural($0) ? $0 : nil },
                        new: new.flatMap { PrivateWords.structural($0) ? $0 : nil }
                    )
                default: return op
                }
            }
            return masked
        }
    }

    /// Pretty, stable JSON (sorted keys, ISO 8601 dates).
    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = ExportDates.encoding
        return try encoder.encode(self)
    }

    static func decode(_ data: Data) throws -> TesseraExport {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = ExportDates.decoding
        guard let export = try? decoder.decode(TesseraExport.self, from: data), export.format == format else {
            throw ExportError.notAnExport
        }
        guard export.version <= currentVersion else { throw ExportError.newerVersion(export.version) }
        return export
    }

    /// Restores into an empty store, keeping every id, so links, history and the op log stay intact.
    /// With `merging`, the store may already hold things (launch seeding, or what was done since a migration first
    /// failed): anything whose id is already there is kept as it is, and everything else from the export is added.
    /// That's how a pending legacy migration still lands after the app has been used.
    func restore(into context: TesseraContext, merging: Bool = false) throws {
        let empty = context.count(ObjectRecord.self) == 0 && context.count(ClassDef.self) == 0
        if !empty, !merging {
            throw ExportError.storeNotEmpty
        }

        var classByID: [UUID: ClassDef] = context.classes
        var newClasses = Set<UUID>()
        for entry in classes where classByID[entry.id] == nil {
            newClasses.insert(entry.id)
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
        for entry in classes where newClasses.contains(entry.id) {
            classByID[entry.id]?.parent = entry.parentID.flatMap { classByID[$0] }
        }

        var objectByID: [UUID: ObjectRecord] = context.objects
        var newObjects = Set<UUID>()
        // Merging: the children of something already here (a seeded routine's slots) are the store's own; the
        // export's copies would double them. Things without a parent (workouts, notes, tasks) still come across.
        let existing = Set(context.objects.keys)
        let skipped = Set(objects.filter { entry in
            merging && entry.parentID.map { existing.contains($0) } == true
        }.map(\.id))
        for entry in objects where objectByID[entry.id] == nil && !skipped.contains(entry.id) {
            newObjects.insert(entry.id)
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
        for entry in objects where newObjects.contains(entry.id) {
            objectByID[entry.id]?.parent = entry.parentID.flatMap { objectByID[$0] }
        }
        // Links from something already here (the seeded plan's routines) are the store's own too.
        for entry in links where context.links[entry.id] == nil
            && !(merging && entry.from.map { existing.contains($0) } == true)
        {
            let link = ObjectLink(fieldID: entry.fieldID, sortIndex: entry.sortIndex)
            link.id = entry.id
            link.createdAt = entry.createdAt
            context.insert(link)
            link.from = entry.from.flatMap { objectByID[$0] }
            link.toObject = entry.toObject.flatMap { objectByID[$0] }
            link.toClass = entry.toClass.flatMap { classByID[$0] }
        }
        for entry in operations where context.operations[entry.id] == nil {
            let record = OpRecord(action: entry.action, actor: entry.actor, summary: entry.summary, ops: entry.ops,
                                  state: entry.state)
            record.id = entry.id
            record.createdAt = entry.createdAt
            record.updatedAt = entry.updatedAt
            record.routeRaw = entry.route
            record.model = entry.model
            record.zone = entry.zone
            context.insert(record)
        }
        try context.save()
    }
}

/// Dates in exports at full precision (ISO 8601 with fractional seconds), so records made within the same second
/// keep their order. Older whole-second exports still read.
public enum ExportDates {
    public static var encoding: JSONEncoder.DateEncodingStrategy {
        .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(date.formatted(.iso8601.year().month().day().time(includingFractionalSeconds: true)
                    .timeZone(separator: .omitted)))
        }
    }

    public static var decoding: JSONDecoder.DateDecodingStrategy {
        .custom { decoder in
            let container = try decoder.singleValueContainer()
            let text = try container.decode(String.self)
            if let date = try? Date(text, strategy: .iso8601.year().month().day()
                .time(includingFractionalSeconds: true).timeZone(separator: .omitted))
            {
                return date
            }
            if let date = try? Date(text, strategy: .iso8601) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Not an ISO 8601 date: \(text)")
        }
    }
}
