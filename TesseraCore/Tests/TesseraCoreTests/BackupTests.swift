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
        let store = try ObjectStore(context: TesseraContext(url: url))
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
        #expect(info.migrations == ["v1", "v2", "v3"])
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
        // A fixed LA calendar and midday instants (never Calendar.current: after midnight a second call replaces).
        let calendar = TesseraDayTests.calendar
        for day in 0 ..< 10 {
            let now = TesseraDayTests.at(10, 10 + day, 12)
            #expect(try TesseraBackup.writeRolling(from: store.context, in: backups, now: now, calendar: calendar)
                != nil)
            #expect(try TesseraBackup.writeRolling(from: store.context, in: backups, now: now, calendar: calendar)
                == nil)
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
            let current = try ObjectStore(context: TesseraContext(url: storeURL))
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
        // QA B1: what was here is kept as a stamped backup that can be restored again (the undo).
        let kept = try FileManager.default.contentsOfDirectory(at: dir.appendingPathComponent("Kept"),
                                                               includingPropertiesForKeys: nil)
        #expect(kept.count == 1)
        let info = try TesseraBackup.inspect(#require(kept.first))
        #expect(info.migrations == ["v1", "v2", "v3"])
        TesseraSchema.clearLaunchNote()
    }

    @Test func aStoreThatWontMoveAsideIsNotRestoredOver() throws {
        // QA B2: the store is there but can't be moved (a read-only folder), so the restore stops.
        let dir = try folder()
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: dir.path)
            try? FileManager.default.removeItem(at: dir)
        }
        let storeURL = dir.appendingPathComponent("tessera.sqlite")
        let current = try seededStore(at: storeURL)
        current.save()
        let source = try seededStore(at: dir.appendingPathComponent("source.sqlite"))
        let file = dir.appendingPathComponent("b.tessera")
        try TesseraBackup.write(from: source.context, to: file)
        _ = try TesseraBackup.stageRestore(from: file, storeURL: storeURL)
        let kept = dir.appendingPathComponent("Kept")
        try FileManager.default.createDirectory(at: kept, withIntermediateDirectories: true)
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: dir.path)
        #expect(!TesseraBackup.applyPendingRestore(to: storeURL, keepIn: kept))
        #expect(FileManager.default.fileExists(atPath: storeURL.path))
        TesseraSchema.clearLaunchNote()
    }

    @Test func aStagedRestoreCanBeSeenAndCancelled() throws {
        // QA R1: a waiting restore is visible, and cancelling it leaves the store as it is at the next launch.
        let dir = try folder()
        defer { try? FileManager.default.removeItem(at: dir) }
        let storeURL = dir.appendingPathComponent("tessera.sqlite")
        try seededStore(at: storeURL).save()
        #expect(TesseraBackup.pendingRestore(storeURL: storeURL) == nil)
        let source = try seededStore(at: dir.appendingPathComponent("source.sqlite"))
        let file = dir.appendingPathComponent("b.tessera")
        try TesseraBackup.write(from: source.context, to: file)
        let info = try TesseraBackup.stageRestore(from: file, storeURL: storeURL)
        #expect(TesseraBackup.pendingRestore(storeURL: storeURL) == info)
        TesseraBackup.cancelRestore(storeURL: storeURL)
        #expect(TesseraBackup.pendingRestore(storeURL: storeURL) == nil)
        #expect(!TesseraBackup.applyPendingRestore(to: storeURL, keepIn: dir.appendingPathComponent("Kept")))
    }

    @Test func rollingWritesLeaveNoPartialFiles() throws {
        // QA B3: written under a temporary name, then renamed.
        let dir = try folder()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = try seededStore(at: dir.appendingPathComponent("tessera.sqlite"))
        let backups = dir.appendingPathComponent("Backups")
        try TesseraBackup.writeRolling(from: store.context, in: backups)
        let names = try FileManager.default.contentsOfDirectory(atPath: backups.path)
        #expect(names.count == 1 && !names[0].hasSuffix(".partial"))
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
