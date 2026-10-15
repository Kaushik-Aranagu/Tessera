import Foundation
import GRDB

// Row mapping: one straight mapping per table, short names per row; splitting it would only scatter the columns.
// swiftlint:disable identifier_name cyclomatic_complexity function_body_length

/// Tables, migrations, and the mapping between rows and models.
/// UUIDs are stored as text, dates as seconds since 1970, values as the same JSON the export uses.
enum TesseraDatabaseSchema {
    static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1") { db in
            try db.execute(sql: """
            CREATE TABLE classDef(
              id TEXT PRIMARY KEY NOT NULL, name TEXT NOT NULL, symbolName TEXT NOT NULL, colorRole TEXT NOT NULL,
              traits TEXT NOT NULL, systemKey TEXT, sortIndex INTEGER NOT NULL, createdAt REAL NOT NULL,
              packageID TEXT, packageVersion INTEGER NOT NULL, isUserModified INTEGER NOT NULL, parentID TEXT);
            CREATE TABLE fieldDef(
              id TEXT PRIMARY KEY NOT NULL, ownerID TEXT, name TEXT NOT NULL, key TEXT NOT NULL, kind TEXT NOT NULL,
              sortIndex INTEGER NOT NULL, isRequired INTEGER NOT NULL, unit TEXT, options TEXT NOT NULL,
              targetClassID TEXT, expression TEXT, defaultValue BLOB, overridesFieldID TEXT,
              isUserModified INTEGER NOT NULL);
            CREATE TABLE object(
              id TEXT PRIMARY KEY NOT NULL, classID TEXT, parentID TEXT, title TEXT NOT NULL, sortIndex INTEGER NOT NULL,
              createdAt REAL NOT NULL, updatedAt REAL NOT NULL, deletedAt REAL, isClassObject INTEGER NOT NULL,
              "values" BLOB);
            CREATE INDEX object_class ON object(classID);
            CREATE INDEX object_parent ON object(parentID);
            CREATE TABLE link(
              id TEXT PRIMARY KEY NOT NULL, fieldID TEXT NOT NULL, fromID TEXT, toObjectID TEXT, toClassID TEXT,
              sortIndex INTEGER NOT NULL, createdAt REAL NOT NULL);
            CREATE INDEX link_from ON link(fromID);
            CREATE INDEX link_field ON link(fieldID);
            CREATE INDEX link_toObject ON link(toObjectID);
            CREATE INDEX link_toClass ON link(toClassID);
            CREATE TABLE viewDef(
              id TEXT PRIMARY KEY NOT NULL, name TEXT NOT NULL, layout TEXT NOT NULL, sortIndex INTEGER NOT NULL,
              filterData BLOB, classID TEXT);
            CREATE TABLE op(
              id TEXT PRIMARY KEY NOT NULL, action TEXT NOT NULL, actor TEXT NOT NULL, state TEXT NOT NULL,
              summary TEXT NOT NULL, createdAt REAL NOT NULL, updatedAt REAL NOT NULL, ops BLOB, objectIDs TEXT NOT NULL);
            CREATE INDEX op_created ON op(createdAt);
            """)
        }
        // Tess model layer T1: which route and model performed a Tess action.
        migrator.registerMigration("v2") { db in
            try db.execute(sql: """
            ALTER TABLE op ADD COLUMN route TEXT;
            ALTER TABLE op ADD COLUMN model TEXT;
            """)
        }
        return migrator
    }

    static func json(_ strings: [String]) -> String {
        (try? JSONEncoder().encode(strings)).flatMap { String(bytes: $0, encoding: .utf8) } ?? "[]"
    }

    static func strings(_ text: String?) -> [String] {
        text.flatMap { try? JSONDecoder().decode([String].self, from: Data($0.utf8)) } ?? []
    }

    /// One dirty model, captured on the main actor as plain values, written on the database's queue.
    struct Row: Sendable {
        let sql: String
        let arguments: StatementArguments

        @MainActor
        init(_ model: any TesseraModel) {
            switch model {
            case let c as ClassDef:
                sql = """
                INSERT OR REPLACE INTO classDef(id, name, symbolName, colorRole, traits, systemKey, sortIndex, createdAt,
                  packageID, packageVersion, isUserModified, parentID) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)
                """
                arguments = [c.id.uuidString, c.name, c.symbolName, c.colorRole, json(c.traitsRaw), c.systemKey,
                             c.sortIndex, c.createdAt.timeIntervalSince1970, c.packageID, c.packageVersion,
                             c.isUserModified, c.parent?.id.uuidString]
            case let f as FieldDef:
                sql = """
                INSERT OR REPLACE INTO fieldDef(id, ownerID, name, key, kind, sortIndex, isRequired, unit, options,
                  targetClassID, expression, defaultValue, overridesFieldID, isUserModified)
                VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)
                """
                arguments = [f.id.uuidString, f.owner?.id.uuidString, f.name, f.key, f.kindRaw, f.sortIndex,
                             f.isRequired, f.unit, json(f.enumOptions), f.targetClassID?.uuidString, f.expression,
                             f.defaultValueData, f.overridesFieldID?.uuidString, f.isUserModified]
            case let o as ObjectRecord:
                sql = """
                INSERT OR REPLACE INTO object(id, classID, parentID, title, sortIndex, createdAt, updatedAt, deletedAt,
                  isClassObject, "values") VALUES (?,?,?,?,?,?,?,?,?,?)
                """
                arguments = [o.id.uuidString, o.classDef?.id.uuidString, o.parent?.id.uuidString, o.title,
                             o.sortIndex, o.createdAt.timeIntervalSince1970, o.updatedAt.timeIntervalSince1970,
                             o.deletedAt?.timeIntervalSince1970, o.isClassObject, o.valuesData]
            case let l as ObjectLink:
                sql = """
                INSERT OR REPLACE INTO link(id, fieldID, fromID, toObjectID, toClassID, sortIndex, createdAt)
                VALUES (?,?,?,?,?,?,?)
                """
                arguments = [l.id.uuidString, l.fieldID.uuidString, l.from?.id.uuidString, l.toObject?.id.uuidString,
                             l.toClass?.id.uuidString, l.sortIndex, l.createdAt.timeIntervalSince1970]
            case let v as ViewDef:
                sql = "INSERT OR REPLACE INTO viewDef(id, name, layout, sortIndex, filterData, classID) VALUES (?,?,?,?,?,?)"
                arguments = [v.id.uuidString, v.name, v.layoutRaw, v.sortIndex, v.filterData, v.classDef?.id.uuidString]
            case let r as OpRecord:
                sql = """
                INSERT OR REPLACE INTO op(id, action, actor, state, summary, createdAt, updatedAt, ops, objectIDs,
                  route, model)
                VALUES (?,?,?,?,?,?,?,?,?,?,?)
                """
                arguments = [r.id.uuidString, r.action, r.actorRaw, r.stateRaw, r.summary,
                             r.createdAt.timeIntervalSince1970, r.updatedAt.timeIntervalSince1970, r.opsData,
                             json(r.objectIDs.map(\.uuidString)), r.routeRaw, r.model]
            default:
                sql = "SELECT 1"
                arguments = []
            }
        }

        func save(_ db: Database) throws {
            try db.execute(sql: sql, arguments: arguments)
        }
    }

    /// Every row, read in one pass, then turned into wired-up models on the main actor.
    struct Snapshot: @unchecked Sendable { // Rows are copied out of the database; read once, then used on the main
        // actor.
        let classes: [GRDB.Row]
        let fields: [GRDB.Row]
        let objects: [GRDB.Row]
        let links: [GRDB.Row]
        let views: [GRDB.Row]
        let operations: [GRDB.Row]

        init(_ db: Database) throws {
            classes = try GRDB.Row.fetchAll(db, sql: "SELECT * FROM classDef")
            fields = try GRDB.Row.fetchAll(db, sql: "SELECT * FROM fieldDef")
            objects = try GRDB.Row.fetchAll(db, sql: "SELECT * FROM object")
            links = try GRDB.Row.fetchAll(db, sql: "SELECT * FROM link")
            views = try GRDB.Row.fetchAll(db, sql: "SELECT * FROM viewDef")
            operations = try GRDB.Row.fetchAll(db, sql: "SELECT * FROM op")
        }

        @MainActor
        func build(into _: TesseraContext, register: (any TesseraModel) -> Void) {
            func uuid(_ row: GRDB.Row, _ column: String) -> UUID? {
                (row[column] as String?).flatMap(UUID.init(uuidString:))
            }
            func date(_ row: GRDB.Row, _ column: String) -> Date? {
                (row[column] as Double?).map(Date.init(timeIntervalSince1970:))
            }

            var classByID: [UUID: ClassDef] = [:]
            for row in classes {
                guard let id = uuid(row, "id") else { continue }
                let classDef = ClassDef(name: row["name"], symbolName: row["symbolName"], colorRole: row["colorRole"],
                                        systemKey: row["systemKey"])
                classDef.id = id
                classDef.traitsRaw = TesseraDatabaseSchema.strings(row["traits"])
                classDef.sortIndex = row["sortIndex"]
                classDef.createdAt = date(row, "createdAt") ?? .now
                classDef.packageID = row["packageID"]
                classDef.packageVersion = row["packageVersion"]
                classDef.isUserModified = row["isUserModified"]
                classByID[id] = classDef
            }
            for row in classes {
                guard let id = uuid(row, "id"), let parentID = uuid(row, "parentID") else { continue }
                classByID[id]?.parent = classByID[parentID]
            }
            classByID.values.forEach(register)

            for row in fields {
                guard let id = uuid(row, "id") else { continue }
                let field = FieldDef(
                    name: row["name"],
                    key: row["key"],
                    kind: FieldKind(rawValue: row["kind"]) ?? .text,
                    sortIndex: row["sortIndex"],
                    unit: row["unit"]
                )
                field.id = id
                field.isRequired = row["isRequired"]
                field.enumOptions = TesseraDatabaseSchema.strings(row["options"])
                field.targetClassID = uuid(row, "targetClassID")
                field.expression = row["expression"]
                field.defaultValueData = row["defaultValue"]
                field.overridesFieldID = uuid(row, "overridesFieldID")
                field.isUserModified = row["isUserModified"]
                field.owner = uuid(row, "ownerID").flatMap { classByID[$0] }
                register(field)
            }

            var objectByID: [UUID: ObjectRecord] = [:]
            objectByID.reserveCapacity(objects.count)
            for row in objects {
                guard let id = uuid(row, "id") else { continue }
                let object = ObjectRecord(title: row["title"], classDef: nil)
                object.id = id
                object.sortIndex = row["sortIndex"]
                object.createdAt = date(row, "createdAt") ?? .now
                object.updatedAt = date(row, "updatedAt") ?? .now
                object.deletedAt = date(row, "deletedAt")
                object.isClassObject = row["isClassObject"]
                object.valuesData = row["values"]
                object.classDef = uuid(row, "classID").flatMap { classByID[$0] }
                objectByID[id] = object
            }
            for row in objects {
                guard let id = uuid(row, "id"), let parentID = uuid(row, "parentID") else { continue }
                objectByID[id]?.parent = objectByID[parentID]
            }
            objectByID.values.forEach(register)

            for row in links {
                guard let id = uuid(row, "id"), let fieldID = uuid(row, "fieldID") else { continue }
                let link = ObjectLink(fieldID: fieldID, sortIndex: row["sortIndex"])
                link.id = id
                link.createdAt = date(row, "createdAt") ?? .now
                link.from = uuid(row, "fromID").flatMap { objectByID[$0] }
                link.toObject = uuid(row, "toObjectID").flatMap { objectByID[$0] }
                link.toClass = uuid(row, "toClassID").flatMap { classByID[$0] }
                register(link)
            }
            for row in views {
                guard let id = uuid(row, "id") else { continue }
                let view = ViewDef(name: row["name"], layout: ViewDef.Layout(rawValue: row["layout"]) ?? .list)
                view.id = id
                view.sortIndex = row["sortIndex"]
                view.filterData = row["filterData"]
                view.classDef = uuid(row, "classID").flatMap { classByID[$0] }
                register(view)
            }
            for row in operations {
                guard let id = uuid(row, "id") else { continue }
                let record = OpRecord(action: row["action"], actor: Actor(rawValue: row["actor"]) ?? .user,
                                      summary: row["summary"], ops: [],
                                      state: OpState(rawValue: row["state"]) ?? .committed)
                record.id = id
                record.opsData = row["ops"]
                record.objectIDs = TesseraDatabaseSchema.strings(row["objectIDs"]).compactMap(UUID.init(uuidString:))
                record.createdAt = date(row, "createdAt") ?? .now
                record.updatedAt = date(row, "updatedAt") ?? .now
                record.routeRaw = row["route"]
                record.model = row["model"]
                register(record)
            }
        }
    }
}

// swiftlint:enable identifier_name cyclomatic_complexity function_body_length
