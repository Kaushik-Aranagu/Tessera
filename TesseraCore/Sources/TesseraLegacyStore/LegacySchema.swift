import Foundation
import SwiftData
import TesseraCore

/// Reads a store written by builds before GRDB (SwiftData), once, so its data can move into the GRDB store.
/// The models in this module are frozen copies of the SwiftData schema as it last shipped.
public enum LegacyStore {
    /// Where SwiftData kept the store: `Application Support/default.store`.
    public static var defaultURL: URL {
        URL.applicationSupportDirectory.appendingPathComponent("default.store")
    }

    /// The old store as a `TesseraExport` JSON file's contents, or nil if there's no old store.
    @MainActor
    public static func exportData(from url: URL = defaultURL) throws -> Data? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let schema = Schema([ClassDef.self, FieldDef.self, ObjectRecord.self, ObjectLink.self, ViewDef.self,
                             OpRecord.self])
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: url,
                                                                                           cloudKitDatabase: .none))
        let context = container.mainContext
        context.autosaveEnabled = false
        let export = try LegacyExport(context: context)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = ExportDates.encoding
        return try encoder.encode(export)
    }

    /// Writes the old store into a fresh GRDB store, then moves the old files into `Backups/` so this runs once.
    /// Returns true if anything moved.
    @MainActor
    @discardableResult
    public static func migrate(from url: URL = defaultURL, into context: TesseraContext) throws -> Bool {
        guard let data = try exportData(from: url) else { return false }
        do {
            // Pending until it lands, however much the new store has been used meanwhile.
            try TesseraExport.decode(data).restore(into: context, merging: true)
        } catch {
            // Leave the old store where it is so the next launch tries again, and say so.
            TesseraSchema.setLaunchNote("Your older history hasn't moved across yet. It's safe, and I'll try again "
                + "next time the app opens.")
            throw error
        }
        _ = TesseraSchema.moveStoreAsideForLegacy(url)
        TesseraSchema.clearLaunchNote()
        return true
    }
}

/// Mirrors `TesseraExport`'s JSON exactly, built from the legacy models.
private struct LegacyExport: Encodable {
    struct Field: Encodable {
        var id: UUID, key: String, name: String, kind: FieldKind, sortIndex: Int, isRequired: Bool
        var unit: String?, options: [String], targetClassID: UUID?, expression: String?
        var defaultValue: FieldValue?, overridesFieldID: UUID?, isUserModified: Bool?
    }

    struct ClassEntry: Encodable {
        var id: UUID, name: String, parentID: UUID?, systemKey: String?, symbolName: String, colorRole: String
        var traits: [String], sortIndex: Int, createdAt: Date, packageID: String?, packageVersion: Int?
        var isUserModified: Bool?, fields: [Field]
    }

    struct ObjectEntry: Encodable {
        var id: UUID, classID: UUID?, parentID: UUID?, title: String, sortIndex: Int, createdAt: Date
        var updatedAt: Date, deletedAt: Date?, isClassObject: Bool, values: [String: FieldValue]
    }

    struct LinkEntry: Encodable {
        var id: UUID, fieldID: UUID, from: UUID?, toObject: UUID?, toClass: UUID?, sortIndex: Int, createdAt: Date
    }

    struct OpEntry: Encodable {
        var id: UUID, action: String, actor: Actor, state: OpState, summary: String, createdAt: Date
        var updatedAt: Date, ops: [Op]
    }

    var format = TesseraExport.format
    var version = TesseraExport.currentVersion
    var exportedAt = Date.now
    var fieldKeys: [String: String]
    var classes: [ClassEntry]
    var objects: [ObjectEntry]
    var links: [LinkEntry]
    var operations: [OpEntry]

    @MainActor
    init(context: ModelContext) throws {
        let classDefs = try context.fetch(FetchDescriptor<ClassDef>(sortBy: [SortDescriptor(\.createdAt)]))
        classes = classDefs.map { cls in
            ClassEntry(
                id: cls.id, name: cls.name, parentID: cls.parent?.id, systemKey: cls.systemKey,
                symbolName: cls.symbolName,
                colorRole: cls.colorRole, traits: cls.traitsRaw, sortIndex: cls.sortIndex, createdAt: cls.createdAt,
                packageID: cls.packageID, packageVersion: cls.packageVersion, isUserModified: cls.isUserModified,
                fields: (cls.ownFields ?? []).sorted { $0.sortIndex < $1.sortIndex }.map { fld in
                    Field(id: fld.id, key: fld.key, name: fld.name, kind: fld.kind, sortIndex: fld.sortIndex,
                          isRequired: fld.isRequired, unit: fld.unit, options: fld.enumOptions,
                          targetClassID: fld.targetClassID,
                          expression: fld.expression, defaultValue: fld.defaultValue,
                          overridesFieldID: fld.overridesFieldID,
                          isUserModified: fld.isUserModified)
                }
            )
        }
        fieldKeys = Dictionary(classes.flatMap(\.fields).map { ($0.id.uuidString, $0.key) },
                               uniquingKeysWith: { first, _ in first })
        objects = try context.fetch(FetchDescriptor<ObjectRecord>(sortBy: [SortDescriptor(\.createdAt)])).map { obj in
            ObjectEntry(id: obj.id, classID: obj.classDef?.id, parentID: obj.parent?.id, title: obj.title,
                        sortIndex: obj.sortIndex, createdAt: obj.createdAt, updatedAt: obj.updatedAt,
                        deletedAt: obj.deletedAt,
                        isClassObject: obj.isClassObject,
                        values: Dictionary(uniqueKeysWithValues: obj.values.storage
                            .map { ($0.key.uuidString, $0.value) }))
        }
        links = try context.fetch(FetchDescriptor<ObjectLink>(sortBy: [SortDescriptor(\.createdAt)])).map { lnk in
            LinkEntry(
                id: lnk.id,
                fieldID: lnk.fieldID,
                from: lnk.from?.id,
                toObject: lnk.toObject?.id,
                toClass: lnk.toClass?.id,
                sortIndex: lnk.sortIndex,
                createdAt: lnk.createdAt
            )
        }
        operations = try context.fetch(FetchDescriptor<OpRecord>(sortBy: [SortDescriptor(\.createdAt)])).map { rec in
            OpEntry(id: rec.id, action: rec.action, actor: rec.actor, state: rec.state, summary: rec.summary,
                    createdAt: rec.createdAt, updatedAt: rec.updatedAt, ops: rec.ops)
        }
    }
}
