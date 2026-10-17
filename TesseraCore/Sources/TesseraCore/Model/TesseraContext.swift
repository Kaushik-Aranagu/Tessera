import Foundation
import GRDB

/// The whole object graph in memory, written through to SQLite with GRDB.
///
/// Every class, field, object, link, view and op lives in an identity map keyed by id, with relationships already
/// wired, so engine reads never touch the database. Inserts, edits and deletes mark rows dirty; `save()` writes
/// them in one transaction, and autosave does so on the next turn of the main actor.
@MainActor
public final class TesseraContext {
    public let database: any DatabaseWriter

    public private(set) var classes: [UUID: ClassDef] = [:]
    public private(set) var fields: [UUID: FieldDef] = [:]
    public private(set) var objects: [UUID: ObjectRecord] = [:]
    public private(set) var links: [UUID: ObjectLink] = [:]
    public private(set) var views: [UUID: ViewDef] = [:]
    public private(set) var operations: [UUID: OpRecord] = [:]
    /// Bumped on every insert, change and delete, so a reader can cache what it worked out from the graph.
    public private(set) var revision = 0
    /// His last weight and the revision it was read at (`BodyWeight.lastKg`; QA W2 on 0ai: it runs per list row).
    var lastWeightCache: (revision: Int, kilograms: Double?)?
    /// Private labels and past-private labels at a revision (`PrivateWords`), and decoded ops per record, so the
    /// background backup walks the graph once per change, not once per copy.
    var privateLabelsCache: (revision: Int, labels: [UUID: String])?
    var pastPrivateCache: (revision: Int, labels: [UUID: String])?
    var decodedOps: [UUID: (data: Data, ops: [Op])] = [:]

    /// Saves automatically shortly after a change. Turn off for bulk work, then call `save()`.
    public var autosaveEnabled = true

    private var dirty: [ObjectIdentifier: any TesseraModel] = [:]
    private var deleted: [Table: Set<UUID>] = [:]
    private var autosaveScheduled = false
    private var isLoading = false

    enum Table: String, CaseIterable {
        case classDef, fieldDef, object, link, viewDef
        case operation = "op"
    }

    // MARK: Opening

    /// The database file; nil in memory.
    public let url: URL?

    /// Opens (creating and migrating if needed) the database at `url`, or an in-memory one, and loads the graph.
    public init(url: URL?) throws {
        self.url = url
        if let url {
            var configuration = Configuration()
            configuration.journalMode = .wal
            database = try DatabasePool(path: url.path, configuration: configuration)
        } else {
            database = try DatabaseQueue()
        }
        try TesseraDatabaseSchema.migrator.migrate(database)
        try load()
    }

    public var hasChanges: Bool {
        !dirty.isEmpty || deleted.values.contains { !$0.isEmpty }
    }

    // MARK: Inserting & deleting

    /// Registers a model (and anything it already relates to that isn't registered yet).
    public func insert(_ model: some TesseraModel) {
        guard model.context !== self else { return }
        register(model)
        markDirty(model)
        switch model {
        case let classDef as ClassDef:
            classDef.parent.map(insert)
            classDef.ownFields?.forEach(insert)
        case let field as FieldDef:
            field.owner.map(insert)
        case let object as ObjectRecord:
            object.classDef.map(insert)
            object.parent.map(insert)
        case let link as ObjectLink:
            link.from.map(insert)
            link.toObject.map(insert)
            link.toClass.map(insert)
        case let view as ViewDef:
            view.classDef.map(insert)
        default:
            break
        }
    }

    private func register(_ model: some TesseraModel) {
        guard model.context !== self else { return }
        attach(model, to: self)
        switch model {
        case let classDef as ClassDef: classes[classDef.id] = classDef
        case let field as FieldDef: fields[field.id] = field
        case let object as ObjectRecord: objects[object.id] = object
        case let link as ObjectLink: links[link.id] = link
        case let view as ViewDef: views[view.id] = view
        case let record as OpRecord: operations[record.id] = record
        default: break
        }
    }

    /// Deletes a model, applying the delete rules: a class's fields, views and incoming links go with it, its
    /// subclasses and objects are detached; an object's children and links go with it.
    public func delete(_ model: some TesseraModel) {
        guard model.context === self else { return }
        revision += 1
        switch model {
        case let classDef as ClassDef:
            classDef.ownFields?.forEach(delete)
            classDef.views?.forEach(delete)
            classDef.incomingLinks?.forEach(delete)
            classDef.subclasses?.forEach { $0.parent = nil }
            classDef.objects?.forEach { $0.classDef = nil }
            classDef.parent = nil
            classes[classDef.id] = nil
            forget(classDef, in: .classDef)
        case let field as FieldDef:
            field.owner = nil
            fields[field.id] = nil
            forget(field, in: .fieldDef)
        case let object as ObjectRecord:
            object.children?.forEach(delete)
            object.outgoingLinks?.forEach(delete)
            object.incomingLinks?.forEach(delete)
            object.parent = nil
            object.classDef = nil
            objects[object.id] = nil
            forget(object, in: .object)
        case let link as ObjectLink:
            link.from = nil
            link.toObject = nil
            link.toClass = nil
            links[link.id] = nil
            forget(link, in: .link)
        case let view as ViewDef:
            view.classDef = nil
            views[view.id] = nil
            forget(view, in: .viewDef)
        case let record as OpRecord:
            operations[record.id] = nil
            forget(record, in: .operation)
        default:
            break
        }
    }

    private func forget(_ model: some TesseraModel, in table: Table) {
        dirty[ObjectIdentifier(model)] = nil
        deleted[table, default: []].insert(model.id)
        attach(model, to: nil)
        scheduleAutosave()
    }

    /// Deletes every model of a type (with delete rules).
    public func deleteAll<Model: TesseraModel>(_: Model.Type) {
        for model in all(Model.self) {
            delete(model)
        }
    }

    private func attach(_ model: some TesseraModel, to context: TesseraContext?) {
        guard var attachable = model as? any AttachableModel else { return }
        attachable.context = context
    }

    // MARK: Reading

    public func all<Model: TesseraModel>(_: Model.Type) -> [Model] {
        let values: [any TesseraModel] = switch Model.self {
        case is ClassDef.Type: Array(classes.values)
        case is FieldDef.Type: Array(fields.values)
        case is ObjectRecord.Type: Array(objects.values)
        case is ObjectLink.Type: Array(links.values)
        case is ViewDef.Type: Array(views.values)
        case is OpRecord.Type: Array(operations.values)
        default: []
        }
        return values.compactMap { $0 as? Model }
    }

    public func count(_ type: (some TesseraModel).Type) -> Int {
        all(type).count
    }

    // MARK: Change tracking

    func markDirty(_ model: some TesseraModel) {
        guard !isLoading, model.context === self else { return }
        revision += 1
        dirty[ObjectIdentifier(model)] = model
        scheduleAutosave()
    }

    func rekey(_ model: some TesseraModel, from oldID: UUID) {
        guard model.context === self else { return }
        let table: Table
        switch model {
        case let classDef as ClassDef:
            classes[oldID] = nil
            classes[classDef.id] = classDef
            table = .classDef
        case let field as FieldDef:
            fields[oldID] = nil
            fields[field.id] = field
            table = .fieldDef
        case let object as ObjectRecord:
            objects[oldID] = nil
            objects[object.id] = object
            table = .object
        case let link as ObjectLink:
            links[oldID] = nil
            links[link.id] = link
            table = .link
        case let view as ViewDef:
            views[oldID] = nil
            views[view.id] = view
            table = .viewDef
        case let record as OpRecord:
            operations[oldID] = nil
            operations[record.id] = record
            table = .operation
        default:
            return
        }
        deleted[table, default: []].insert(oldID)
        markDirty(model)
    }

    private func scheduleAutosave() {
        guard autosaveEnabled, !autosaveScheduled, !isLoading else { return }
        autosaveScheduled = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            autosaveScheduled = false
            if autosaveEnabled {
                try? save()
            }
        }
    }

    // MARK: Saving

    /// Writes every change since the last save in one transaction.
    public func save() throws {
        guard hasChanges else { return }
        let rows = dirty.values.map(TesseraDatabaseSchema.Row.init)
        let removals = deleted
        try database.write { db in
            for (table, ids) in removals where !ids.isEmpty {
                for id in ids {
                    try db.execute(sql: "DELETE FROM \"\(table.rawValue)\" WHERE id = ?", arguments: [id.uuidString])
                }
            }
            for row in rows {
                try row.save(db)
            }
        }
        dirty.removeAll()
        deleted.removeAll()
    }

    // MARK: Loading

    private func load() throws {
        isLoading = true
        defer { isLoading = false }
        let snapshot = try database.read(TesseraDatabaseSchema.Snapshot.init)
        snapshot.build(into: self, register: { self.register($0) })
    }
}
