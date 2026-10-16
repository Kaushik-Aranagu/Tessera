import Foundation
import GRDB

/// Same generic schema as SwiftData, as plain tables. UUIDs are 16-byte blobs, dates are
/// timeIntervalSinceReferenceDate doubles (as Core Data stores them), values are JSON text.
enum GRDBBench {
    static let schema = """
    CREATE TABLE classDef(id BLOB PRIMARY KEY NOT NULL, name TEXT NOT NULL, systemKey TEXT, parentId BLOB,
      symbolName TEXT, colorRole TEXT, sortIndex INTEGER NOT NULL DEFAULT 0, createdAt REAL NOT NULL);
    CREATE TABLE fieldDef(id BLOB PRIMARY KEY NOT NULL, ownerId BLOB, key TEXT NOT NULL, name TEXT NOT NULL,
      kind TEXT NOT NULL, sortIndex INTEGER NOT NULL DEFAULT 0, unit TEXT, targetClassId BLOB, expression TEXT);
    CREATE TABLE object(id BLOB PRIMARY KEY NOT NULL, classId BLOB, parentId BLOB, title TEXT NOT NULL DEFAULT '',
      sortIndex INTEGER NOT NULL DEFAULT 0, createdAt REAL NOT NULL, updatedAt REAL NOT NULL, deletedAt REAL,
      isClassObject INTEGER NOT NULL DEFAULT 0, "values" TEXT);
    CREATE INDEX object_class ON object(classId);
    CREATE INDEX object_parent ON object(parentId);
    CREATE TABLE link(id BLOB PRIMARY KEY NOT NULL, fromId BLOB NOT NULL, fieldId BLOB NOT NULL, toObjectId BLOB,
      toClassId BLOB, sortIndex INTEGER NOT NULL DEFAULT 0, createdAt REAL NOT NULL);
    CREATE INDEX link_field_class ON link(fieldId, toClassId);
    CREATE INDEX link_from ON link(fromId);
    CREATE INDEX link_toObject ON link(toObjectId);
    CREATE TABLE op(id BLOB PRIMARY KEY NOT NULL, action TEXT NOT NULL, actor TEXT NOT NULL, state TEXT NOT NULL,
      summary TEXT NOT NULL, createdAt REAL NOT NULL, opsData BLOB, objectIds TEXT);
    """

    static func open(_ dir: URL) throws -> DatabasePool {
        try DatabasePool(path: dir.appending(path: "store.sqlite").path, configuration: Configuration())
    }

    static func json(_ values: FieldValues) throws -> String {
        try String(decoding: Fixture.encoder.encode(values), as: UTF8.self)
    }

    static func build(dir: URL, perWorkout: Bool) throws {
        let pool = try open(dir)
        let catalog: (exercises: [UUID], workout: UUID, entry: UUID, set: UUID, ids: FieldIDs) = try pool.write { db in
            try db.execute(sql: schema)
            func cls(_ name: String, _ key: String, parent: UUID?) throws -> UUID {
                let id = UUID.v7()
                try db.execute(sql: "INSERT INTO classDef(id, name, systemKey, parentId, createdAt) VALUES (?,?,?,?,?)",
                               arguments: [id, name, key, parent, Date.now.timeIntervalSinceReferenceDate])
                return id
            }
            func fld(_ key: String, _ kind: String, _ owner: UUID, _ expression: String? = nil) throws -> UUID {
                let id = UUID.v7()
                try db.execute(sql: "INSERT INTO fieldDef(id, ownerId, key, name, kind, expression) VALUES (?,?,?,?,?,?)",
                               arguments: [id, owner, key, key, kind, expression])
                return id
            }
            let workout = try cls("Workout", "system.workout", parent: nil)
            let entry = try cls("Exercise Entry", "system.exerciseEntry", parent: nil)
            let set = try cls("Set", "system.set", parent: nil)
            let lift = try cls("Barbell Lift", "system.barbellLift", parent: nil)
            let exercises = try [cls("Bench Press", "system.benchPress", parent: lift)]
                + (0 ..< 4).map { try cls("Lift \($0)", "user.lift\($0)", parent: lift) }
            let ids = try FieldIDs(
                weight: fld("weight", "mass", set), reps: fld("reps", "number", set), rpe: fld("rpe", "number", set),
                kind: fld("kind", "choice", set), isWarmup: fld("isWarmup", "bool", set),
                endedAt: fld("endedAt", "date", workout), exercise: fld("exercise", "classRef", entry)
            )
            _ = try fld("e1rm", "computed", set, "weight * (1 + reps / 30)")
            return (exercises, workout, entry, set, ids)
        }

        func insertWorkout(_ db: Database, day: Int) throws {
            let objectSQL = """
            INSERT INTO object(id, classId, parentId, title, sortIndex, createdAt, updatedAt, "values")
            VALUES (?,?,?,?,?,?,?,?)
            """
            let insertObject = try db.cachedStatement(sql: objectSQL)
            let insertLink = try db.cachedStatement(
                sql: "INSERT INTO link(id, fromId, fieldId, toClassId, createdAt) VALUES (?,?,?,?,?)"
            )
            let date = Fixture.workoutDate(day)
            let time = date.timeIntervalSinceReferenceDate
            let workoutID = UUID.v7(at: date)
            var workoutValues = FieldValues()
            workoutValues[catalog.ids.endedAt] = .date(date)
            try insertObject.execute(arguments: [workoutID, catalog.workout, nil, "Day \(day)", 0, time, time,
                                                 json(workoutValues)])
            for (index, exercise) in catalog.exercises.enumerated() {
                let entryID = UUID.v7(at: date)
                try insertObject.execute(arguments: [entryID, catalog.entry, workoutID, "", index, time, time, nil])
                try insertLink.execute(arguments: [UUID.v7(at: date), entryID, catalog.ids.exercise, exercise, time])
                for setIndex in 0 ..< Fixture.setsPerEntry {
                    try insertObject.execute(arguments: [
                        UUID.v7(at: date), catalog.set, entryID, "", setIndex, time, time,
                        json(Fixture.setValues(day: day, set: setIndex, ids: catalog.ids)),
                    ])
                }
            }
        }

        let mode = perWorkout ? "perWorkout" : "oneTx"
        try measure("grdb.insert.\(mode)") {
            if perWorkout {
                for day in 0 ..< Fixture.workouts {
                    try pool.write { try insertWorkout($0, day: day) }
                }
            } else {
                try pool.write { db in
                    for day in 0 ..< Fixture.workouts { try insertWorkout(db, day: day) }
                }
            }
        }
        // Fold the WAL into the main file so the size is comparable.
        try pool.writeWithoutTransaction { try $0.checkpoint(.truncate) }
    }

    struct Plan {
        var setClass: UUID, workoutClass: UUID, bench: UUID
        var ids: FieldIDs
    }

    static func plan(_ db: Database) throws -> Plan {
        func cls(_ key: String) throws -> UUID {
            try UUID.fetchOne(db, sql: "SELECT id FROM classDef WHERE systemKey = ?", arguments: [key])!
        }
        func fld(_ key: String) throws -> UUID {
            try UUID.fetchOne(db, sql: "SELECT id FROM fieldDef WHERE key = ?", arguments: [key])!
        }
        return try Plan(
            setClass: cls("system.set"), workoutClass: cls("system.workout"), bench: cls("system.benchPress"),
            ids: FieldIDs(weight: fld("weight"), reps: fld("reps"), rpe: fld("rpe"), kind: fld("kind"),
                          isWarmup: fld("isWarmup"), endedAt: fld("endedAt"), exercise: fld("exercise"))
        )
    }

    /// Every set with its entry, workout date and exercise, one joined query; values decoded in Swift with the
    /// same FieldValues decoder SwiftData uses.
    static func factsDecoded(_ db: Database, _ plan: Plan) throws -> [EntryFact] {
        let sql = """
        SELECT s.id, s."values", e.id, w.id, w."values", l.toClassId
        FROM link l
        JOIN object e ON e.id = l.fromId AND e.deletedAt IS NULL
        JOIN object w ON w.id = e.parentId AND w.deletedAt IS NULL AND w.classId = ?
        JOIN object s ON s.parentId = e.id AND s.deletedAt IS NULL AND s.classId = ?
        WHERE l.fieldId = ?
        ORDER BY e.id, s.sortIndex, s.createdAt
        """
        let decoder = JSONDecoder()
        var dates: [UUID: Date] = [:]
        var facts: [EntryFact] = []
        var current: (entry: UUID, workout: UUID, cls: UUID, date: Date, sets: [LoggedSet])?
        let rows = try Row.fetchCursor(db, sql: sql, arguments: [plan.workoutClass, plan.setClass, plan.ids.exercise])
        while let row = try rows.next() {
            let entryID: UUID = row[2]
            if current?.entry != entryID {
                if let current { facts.append(EntryFact(entryID: current.entry, workoutID: current.workout,
                                                        classID: current.cls, date: current.date, sets: current.sets)) }
                let workoutID: UUID = row[3]
                let date: Date
                if let cached = dates[workoutID] {
                    date = cached
                } else {
                    let text: String = row[4]
                    date = try decoder.decode(FieldValues.self, from: Data(text.utf8))[plan.ids.endedAt]?.dateValue ?? .distantPast
                    dates[workoutID] = date
                }
                current = (entryID, workoutID, row[5], date, [])
            }
            let text: String = row[1]
            let values = try decoder.decode(FieldValues.self, from: Data(text.utf8))
            if let logged = loggedSet(id: row[0], values: values, ids: plan.ids) { current?.sets.append(logged) }
        }
        if let current { facts.append(EntryFact(entryID: current.entry, workoutID: current.workout,
                                                classID: current.cls, date: current.date, sets: current.sets)) }
        return facts
    }

    static func path(_ field: UUID, _ kind: String) -> String {
        "'$.\"\(field.uuidString)\".\(kind)._0'"
    }

    /// Same result, with SQLite's json_extract pulling the scalars (no JSONDecoder).
    static func factsSQLJSON(_ db: Database, _ plan: Plan) throws -> [EntryFact] {
        let ids = plan.ids
        let sql = """
        SELECT s.id, json_extract(s."values", \(path(ids.weight, "mass"))),
               json_extract(s."values", \(path(ids.reps, "number"))),
               json_extract(s."values", \(path(ids.rpe, "number"))),
               json_extract(s."values", \(path(ids.isWarmup, "bool"))),
               e.id, w.id, json_extract(w."values", \(path(ids.endedAt, "date"))), l.toClassId
        FROM link l
        JOIN object e ON e.id = l.fromId AND e.deletedAt IS NULL
        JOIN object w ON w.id = e.parentId AND w.deletedAt IS NULL AND w.classId = ?
        JOIN object s ON s.parentId = e.id AND s.deletedAt IS NULL AND s.classId = ?
        WHERE l.fieldId = ?
        ORDER BY e.id, s.sortIndex, s.createdAt
        """
        var facts: [EntryFact] = []
        var current: (entry: UUID, workout: UUID, cls: UUID, date: Date, sets: [LoggedSet])?
        let rows = try Row.fetchCursor(db, sql: sql, arguments: [plan.workoutClass, plan.setClass, ids.exercise])
        while let row = try rows.next() {
            let entryID: UUID = row[5]
            if current?.entry != entryID {
                if let current { facts.append(EntryFact(entryID: current.entry, workoutID: current.workout,
                                                        classID: current.cls, date: current.date, sets: current.sets)) }
                let seconds: Double = row[7]
                current = (entryID, row[6], row[8], Date(timeIntervalSinceReferenceDate: seconds), [])
            }
            if (row[4] as Bool?) == true { continue }
            guard let weight: Double = row[1], let reps: Double = row[2] else { continue }
            current?.sets.append(LoggedSet(id: row[0], weight: weight, reps: reps, rpe: row[3],
                                           e1RM: e1RM(weight: weight, reps: reps)))
        }
        if let current { facts.append(EntryFact(entryID: current.entry, workoutID: current.workout,
                                                classID: current.cls, date: current.date, sets: current.sets)) }
        return facts
    }

    /// Best e1RM over all sets of one exercise, aggregated in SQL.
    static func recordsSQL(_ db: Database, _ plan: Plan) throws -> Double {
        let ids = plan.ids
        let sql = """
        SELECT MAX(w * (1 + r / 30.0)) FROM (
          SELECT json_extract(s."values", \(path(ids.weight, "mass"))) AS w,
                 json_extract(s."values", \(path(ids.reps, "number"))) AS r
          FROM link l JOIN object s ON s.parentId = l.fromId
          WHERE l.fieldId = ? AND l.toClassId = ? AND s.deletedAt IS NULL AND s.classId = ?
            AND coalesce(json_extract(s."values", \(path(ids.isWarmup, "bool"))), 0) = 0)
        """
        return try Double.fetchOne(db, sql: sql, arguments: [ids.exercise, plan.bench, plan.setClass]) ?? 0
    }

    /// Same, fetching the JSON and decoding it in Swift.
    static func recordsDecoded(_ db: Database, _ plan: Plan) throws -> Double {
        let sql = """
        SELECT s.id, s."values" FROM link l JOIN object s ON s.parentId = l.fromId
        WHERE l.fieldId = ? AND l.toClassId = ? AND s.deletedAt IS NULL AND s.classId = ?
        """
        let decoder = JSONDecoder()
        var best = 0.0
        let rows = try Row.fetchCursor(db, sql: sql, arguments: [plan.ids.exercise, plan.bench, plan.setClass])
        while let row = try rows.next() {
            let text: String = row[1]
            let values = try decoder.decode(FieldValues.self, from: Data(text.utf8))
            if let logged = loggedSet(id: row[0], values: values, ids: plan.ids) { best = max(best, logged.e1RM) }
        }
        return best
    }

    static func query(dir: URL) throws {
        let start = clock.now
        let pool = try open(dir)
        let plan = try pool.read { try Self.plan($0) }
        result("grdb.open", ms(clock.now - start))
        let facts = try measure("grdb.read") { try pool.read { try factsDecoded($0, plan) } }
        result("grdb.openAndRead", ms(clock.now - start))
        print("INFO grdb entries=\(facts.count) sets=\(facts.reduce(0) { $0 + $1.sets.count })")
        let facts2 = try measure("grdb.readSQLJSON") { try pool.read { try factsSQLJSON($0, plan) } }
        print("INFO grdb(sqljson) entries=\(facts2.count) sets=\(facts2.reduce(0) { $0 + $1.sets.count })")

        let best = try measure("grdb.recordsSQL") { try pool.read { try recordsSQL($0, plan) } }
        let bestDecoded = try measure("grdb.recordsDecoded") { try pool.read { try recordsDecoded($0, plan) } }
        print("INFO grdb bestE1RM=\(best) decoded=\(bestDecoded)")

        let after = try measure("grdb.logAndRequery") {
            try pool.write { db in
                let entry = try UUID.fetchOne(db, sql: """
                SELECT l.fromId FROM link l JOIN object e ON e.id = l.fromId
                WHERE l.fieldId = ? AND l.toClassId = ? ORDER BY e.createdAt DESC LIMIT 1
                """, arguments: [plan.ids.exercise, plan.bench])
                var values = FieldValues()
                values[plan.ids.weight] = .mass(150)
                values[plan.ids.reps] = .number(5)
                let id = UUID.v7()
                let now = Date.now.timeIntervalSinceReferenceDate
                try db.execute(sql: """
                INSERT INTO object(id, classId, parentId, sortIndex, createdAt, updatedAt, "values")
                VALUES (?,?,?,?,?,?,?)
                """, arguments: [id, plan.setClass, entry, 99, now, now, json(values)])
                try db.execute(sql: """
                INSERT INTO op(id, action, actor, state, summary, createdAt, opsData, objectIds)
                VALUES (?,?,?,?,?,?,?,?)
                """, arguments: [UUID.v7(), "logSet", "user", "committed", "Logged bench 150 × 5", now,
                                 Data(count: 200), id.uuidString])
            }
            return try pool.read { try recordsSQL($0, plan) }
        }
        print("INFO grdb bestAfterLog=\(after)")
    }
}
