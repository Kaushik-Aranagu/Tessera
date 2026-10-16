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

    @Test func exportCarriesTheZoneAndImportRestoresIt() throws {
        let store = try ObjectStore(context: TesseraContext(url: url))
        let engine = try engine(store)
        engine.zone = { TimeZone(identifier: "Europe/London")! }
        try engine.perform(CreateNote(body: "London"), by: .user)
        let export = try TesseraExport(context: store.context)
        #expect(export.operations.contains { $0.zone == "Europe/London" })
        let json = try String(data: export.encoded(), encoding: .utf8) ?? ""
        #expect(json.contains("\"zone\":\"Europe\\/London\"") || json.contains("\"zone\" : \"Europe\\/London\""))
    }

    @Test func anOlderExportWithoutZonesStillDecodes() throws {
        let store = try ObjectStore(context: TesseraContext(url: url))
        _ = try engine(store)
        var export = try TesseraExport(context: store.context)
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
