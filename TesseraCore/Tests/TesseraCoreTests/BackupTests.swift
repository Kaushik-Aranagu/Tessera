import Foundation
import GRDB
@testable import TesseraCore
import Testing

/// docs/research/free-signing-survival.md section 4: one-file backups and a restore at the next launch.
@MainActor
struct BackupTests {
    func folder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func seededStore(at url: URL) throws -> ObjectStore {
        let store = ObjectStore(context: try TesseraContext(url: url))
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        try engine.perform(CreateNote(body: "Bench felt heavy"), by: .user)
        try engine.perform(AddGroceries(lines: ["milk", "2 lemons"]), by: .user)
        return store
    }

    func json(_ context: TesseraContext) throws -> Data {
        var export = try TesseraExport(context: context, now: Date(timeIntervalSince1970: 0))
        export.exportedAt = Date(timeIntervalSince1970: 0)
        return try export.encoded()
    }

    @Test func backupRoundTripsEverything() throws {
        let dir = try folder()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = try seededStore(at: dir.appendingPathComponent("tessera.sqlite"))
        store.save() // WAL writes not yet checkpointed
        let file = dir.appendingPathComponent("copy.tessera")
        try TesseraBackup.write(from: store.context, to: file)
        let info = try TesseraBackup.inspect(file)
        #expect(info.migrations == ["v1", "v2"])
        // Compared as stored (dates are seconds as a Double on disk).
        let copy = try TesseraContext(url: file)
        let source = try TesseraContext(url: dir.appendingPathComponent("tessera.sqlite"))
        #expect(try json(copy) == json(source))
    }

    @Test func inspectRefusesForeignDamagedAndNewer() throws {
        let dir = try folder()
        defer { try? FileManager.default.removeItem(at: dir) }
        let text = dir.appendingPathComponent("notes.tessera")
        try Data("just some text".utf8).write(to: text)
        #expect(throws: TesseraBackup.BackupError.notABackup) { try TesseraBackup.inspect(text) }

        let store = try seededStore(at: dir.appendingPathComponent("tessera.sqlite"))
        let good = dir.appendingPathComponent("good.tessera")
        try TesseraBackup.write(from: store.context, to: good)
        let bytes = try Data(contentsOf: good)
        let truncated = dir.appendingPathComponent("truncated.tessera")
        try bytes.prefix(bytes.count / 2).write(to: truncated)
        #expect(throws: TesseraBackup.BackupError.self) { try TesseraBackup.inspect(truncated) }

        let newer = dir.appendingPathComponent("newer.tessera")
        try FileManager.default.copyItem(at: good, to: newer)
        let queue = try DatabaseQueue(path: newer.path)
        try queue.write { try $0.execute(sql: "INSERT INTO grdb_migrations VALUES ('v99')") }
        try queue.close()
        #expect(throws: TesseraBackup.BackupError.newerSchema) { try TesseraBackup.inspect(newer) }
    }

    @Test func rollingKeepsOnePerDayAndSeven() throws {
        let dir = try folder()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = try seededStore(at: dir.appendingPathComponent("tessera.sqlite"))
        let backups = dir.appendingPathComponent("Backups")
        let start = Date(timeIntervalSince1970: 1_792_000_000)
        for day in 0 ..< 10 {
            let now = start.addingTimeInterval(Double(day) * 86400)
            #expect(try TesseraBackup.writeRolling(from: store.context, in: backups, now: now) != nil)
            #expect(try TesseraBackup.writeRolling(from: store.context, in: backups, now: now) == nil)
        }
        let files = try FileManager.default.contentsOfDirectory(atPath: backups.path)
        #expect(files.count == 7, "\(files.sorted())")
    }

    @Test func stagedRestoreSwapsAtLaunchAndKeepsOldStore() throws {
        let dir = try folder()
        defer { try? FileManager.default.removeItem(at: dir) }
        let storeURL = dir.appendingPathComponent("tessera.sqlite")
        let source = try seededStore(at: dir.appendingPathComponent("source.sqlite"))
        let file = dir.appendingPathComponent("from-before.tessera")
        try TesseraBackup.write(from: source.context, to: file)
        let expected = try json(TesseraContext(url: dir.appendingPathComponent("source.sqlite")))

        do {
            let current = ObjectStore(context: try TesseraContext(url: storeURL))
            let classes = try current.prepareCatalog()
            try ActionEngine(store: current, classes: classes).perform(CreateNote(body: "Today's note"), by: .user)
            current.save()
        }
        _ = try TesseraBackup.stageRestore(from: file, storeURL: storeURL)
        let container = TesseraSchema.makeContainer(url: storeURL)
        #expect(try json(container.mainContext) == expected)
        let backups = dir.appendingPathComponent("Backups")
        #expect(try !FileManager.default.contentsOfDirectory(atPath: backups.path).isEmpty)
        #expect(!FileManager.default.fileExists(atPath: TesseraBackup.pendingURL(for: storeURL).path))
        TesseraSchema.clearLaunchNote()
    }

    @Test func badRestoreLeavesCurrentStoreUntouched() throws {
        let dir = try folder()
        defer { try? FileManager.default.removeItem(at: dir) }
        let storeURL = dir.appendingPathComponent("tessera.sqlite")
        let current = try seededStore(at: storeURL)
        current.save()
        let before = try json(TesseraContext(url: storeURL))
        try Data("not a database".utf8).write(to: TesseraBackup.pendingURL(for: storeURL))
        TesseraSchema.clearLaunchNote()
        let container = TesseraSchema.makeContainer(url: storeURL)
        #expect(try json(container.mainContext) == before)
        #expect(TesseraSchema.launchNote != nil)
        #expect(!FileManager.default.fileExists(atPath: TesseraBackup.pendingURL(for: storeURL).path))
        TesseraSchema.clearLaunchNote()
    }
}
