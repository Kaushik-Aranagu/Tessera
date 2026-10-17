import Foundation
import GRDB
@testable import TesseraCore
import Testing

/// v3: every action records the time zone it was logged in (for a day log across a trip).
@MainActor
struct OpZoneTests {
    let dir: URL
    let url: URL

    init() throws {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        url = dir.appendingPathComponent("tessera.sqlite")
    }

    func engine(_ store: ObjectStore) throws -> ActionEngine {
        try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    @Test func theMigrationAddsANullableColumn() throws {
        let context = try TesseraContext(url: url)
        let columns = try context.database.read { try $0.columns(in: "op").map(\.name) }
        #expect(columns.contains("zone"))
        let applied = try context.database.read { try TesseraDatabaseSchema.migrator.appliedIdentifiers($0) }
        #expect(applied.contains("v3"))
    }

    @Test func performStampsTheCurrentZone() throws {
        let store = try ObjectStore(context: TesseraContext(url: url))
        let engine = try engine(store)
        let record = try engine.perform(CreateNote(body: "Hotel gym"), by: .user).record
        #expect(record.zone == TimeZone.current.identifier)
    }

    @Test func aTripStampsTheZoneInForce() throws {
        let store = try ObjectStore(context: TesseraContext(url: url))
        let engine = try engine(store)
        engine.zone = { TimeZone(identifier: "America/New_York")! }
        let record = try engine.perform(CreateNote(body: "Landed"), by: .user).record
        #expect(record.zone == "America/New_York")
    }

    @Test func theZoneSurvivesSaveAndReload() throws {
        do {
            let store = try ObjectStore(context: TesseraContext(url: url))
            let engine = try engine(store)
            engine.zone = { TimeZone(identifier: "America/New_York")! }
            try engine.perform(CreateNote(body: "Landed"), by: .user)
            try store.context.save()
        }
        let reopened = try TesseraContext(url: url)
        #expect(reopened.all(OpRecord.self).contains { $0.zone == "America/New_York" })
    }

    @Test func oldRowsStayNull() throws {
        let context = try TesseraContext(url: url)
        try context.database.write { db in
            try db.execute(sql: """
            INSERT INTO op(id, action, actor, state, summary, createdAt, updatedAt, ops, objectIDs)
            VALUES ('00000000-0000-0000-0000-000000000001', 'createNote', 'user', 'committed', 'Old', 0, 0, X'5B5D',
                    '[]')
            """)
        }
        let reopened = try TesseraContext(url: url)
        let old = reopened.all(OpRecord.self).first { $0.summary == "Old" }
        #expect(old != nil && old?.zone == nil)
    }

    @Test func aRealV2FileOpensAtV3() throws {
        // QA Z2: a store last written by a v2 build (route and model, no zone) migrates in place, keeps its rows, and
        // the next action records a zone.
        do {
            let queue = try DatabaseQueue(path: url.path)
            try TesseraDatabaseSchema.migrator.migrate(queue, upTo: "v2")
            try queue.write { db in
                try db.execute(sql: """
                INSERT INTO op(id, action, actor, state, summary, createdAt, updatedAt, ops, objectIDs, route, model)
                VALUES ('00000000-0000-0000-0000-000000000002', 'createNote', 'tess', 'committed', 'From v2', 0, 0,
                        X'5B5D', '[]', 'grammar', NULL)
                """)
            }
            try queue.close()
        }
        let store = try ObjectStore(context: TesseraContext(url: url))
        let applied = try store.context.database.read { try TesseraDatabaseSchema.migrator.appliedIdentifiers($0) }
        #expect(applied == ["v1", "v2", "v3"])
        let old = store.context.all(OpRecord.self).first { $0.summary == "From v2" }
        #expect(old?.route == .grammar && old?.zone == nil)
        let engine = try engine(store)
        engine.zone = { TimeZone(identifier: "Asia/Kolkata")! }
        try engine.perform(CreateNote(body: "After the update"), by: .user)
        try store.context.save()
        let reopened = try TesseraContext(url: url)
        #expect(reopened.all(OpRecord.self).contains { $0.zone == "Asia/Kolkata" })
        #expect(reopened.all(OpRecord.self).contains { $0.summary == "From v2" })
    }

    @Test func theDefaultZoneFollowsTheDevice() throws {
        // QA Z1: autoupdating, so a long-lived app sees the new zone after a flight without a relaunch.
        let engine = try engine(ObjectStore(context: TesseraContext(url: url)))
        #expect(engine.zone() == TimeZone.autoupdatingCurrent)
    }

    @Test func exportCarriesTheZoneAndImportRestoresIt() throws {
        let store = try ObjectStore(context: TesseraContext(url: url))
        let engine = try engine(store)
        engine.zone = { TimeZone(identifier: "Europe/London")! }
        try engine.perform(CreateNote(body: "London"), by: .user)
        // Test-only lossless export (maskingPrivate: false); the app never does this.
        let export = try TesseraExport(context: store.context, maskingPrivate: false)
        #expect(export.operations.contains { $0.zone == "Europe/London" })
        let json = try String(data: export.encoded(), encoding: .utf8) ?? ""
        #expect(json.contains("\"zone\":\"Europe\\/London\"") || json.contains("\"zone\" : \"Europe\\/London\""))
    }

    @Test func anOlderExportWithoutZonesStillDecodes() throws {
        let store = try ObjectStore(context: TesseraContext(url: url))
        _ = try engine(store)
        // Test-only lossless export (maskingPrivate: false); the app never does this.
        var export = try TesseraExport(context: store.context, maskingPrivate: false)
        export.operations = export.operations.map { var entry = $0; entry.zone = nil; return entry }
        let decoded = try TesseraExport.decode(export.encoded())
        #expect(decoded.operations.allSatisfy { $0.zone == nil })
    }

    @Test func aBackupFromThisBuildKnowsV3() throws {
        let store = try ObjectStore(context: TesseraContext(url: url))
        _ = try engine(store)
        let copy = dir.appendingPathComponent("b.tessera")
        try TesseraBackup.write(from: store.context, to: copy)
        #expect(try TesseraBackup.inspect(copy).migrations == ["v1", "v2", "v3"])
    }
}
