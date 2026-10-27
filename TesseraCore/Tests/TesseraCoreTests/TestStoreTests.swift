import Foundation
import GRDB
@testable import TesseraCore
import Testing

/// The test world's stamp: a test store is marked, stays marked through settings writes, and is never copied.
@MainActor
struct TestStoreTests {
    @Test func theStampSurvivesSettingsWritesAndAPlainStoreHasNone() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let settings = SettingsStore(engine: engine)
        #expect(!SettingsStore.isTestStore(in: store) && !TestStore.allowsClaude(store))
        try settings.stampAsTestStore()
        #expect(SettingsStore.isTestStore(in: store) && TestStore.allowsClaude(store))
        // The stamp is outside the object graph: settings writes, a reset and a deleted settings row leave it alone.
        try settings.update(by: .system) { $0.restWeekday = 3 }
        try settings.update(by: .system) { $0.rainAlert = true }
        if let row = store.object(id: SettingsStore.objectID) {
            store.softDelete(row)
        }
        #expect(SettingsStore.isTestStore(in: store))
        // A copy made for a rehearsal is a test store too (`TestStore.carry`).
        let copy = try DatabaseQueue()
        try TestStore.carry(from: store.context, to: copy)
        #expect(try copy.read { try Int32.fetchOne($0, sql: "PRAGMA application_id") } == TestStore.applicationID)
    }

    @Test func hisStoreAndHisHistoryRefuseTheStamp() throws {
        // A store with something of his in it.
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        try engine.perform(CreateTask(title: "His task"), by: .user)
        #expect(throws: TestStore.Refusal.hasHisHistory) { try SettingsStore(engine: engine).stampAsTestStore() }
        #expect(!SettingsStore.isTestStore(in: store))
        // Tess's own writes count as his too.
        let other = ObjectStore.open(inMemory: true)
        let otherEngine = try ActionEngine(store: other, classes: other.prepareCatalog())
        try otherEngine.perform(CreateTask(title: "Tess task"), by: .tess)
        #expect(throws: TestStore.Refusal.hasHisHistory) { try SettingsStore(engine: otherEngine).stampAsTestStore() }
    }

    @Test func aCopyOfHisDataWithNoOpsByHimIsStillRefused() throws {
        // His rows made by the system (a restored or copied store has no .user ops in it).
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        _ = try engine.perform(CreateTask(title: "Call the bank"), by: .system)
        store.context.operations.values.forEach { store.context.delete($0) }
        #expect(!TestStore.hasHisHistory(store.context))
        #expect(throws: TestStore.Refusal.hasHisRows("Task")) { try SettingsStore(engine: engine).stampAsTestStore() }
        #expect(!SettingsStore.isTestStore(in: store))
        // A store holding only the catalog still stamps.
        let fresh = ObjectStore.open(inMemory: true)
        _ = try fresh.prepareCatalog()
        try TestStore.stamp(fresh)
        #expect(TestStore.isStamped(fresh.context))
    }

    @Test func onlyAFileUnderTheTemporaryFolderOrMemoryIsNotHis() {
        #expect(TestStore.isHisStore(url: TesseraSchema.defaultURL))
        #expect(TestStore.isHisStore(url: URL(fileURLWithPath: "/Users/someone/Documents/tessera.sqlite")))
        #expect(!TestStore.isHisStore(url: FileManager.default.temporaryDirectory.appendingPathComponent("a.sqlite")))
        #expect(!TestStore.isHisStore(url: nil))
    }

    @Test func aTestStoreIsNeverBackedUp() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("test-store-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("tessera.sqlite")
        let context = try TesseraContext(url: url)
        let store = ObjectStore(context: context)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let settings = SettingsStore(engine: engine)
        // The temporary folder is not his, so the stamp may land here.
        // A plain store still backs up.
        let plain = folder.appendingPathComponent("plain.tessera")
        try TesseraBackup.write(from: context, to: plain)
        #expect(FileManager.default.fileExists(atPath: plain.path))
        try settings.stampAsTestStore()
        #expect(throws: TesseraBackup.BackupError.testStore) {
            try TesseraBackup.writeRolling(from: context, in: folder.appendingPathComponent("copies"),
                                           now: Date().addingTimeInterval(2 * 86400))
        }
        #expect(throws: TesseraBackup.BackupError.testStore) {
            try TesseraBackup.write(from: context, to: folder.appendingPathComponent("one.tessera"))
        }
    }

    @Test func aTestStoreKeepsItsOwnFilesBesideItsDatabase() {
        let url = URL(fileURLWithPath: "/tmp/run/tessera.sqlite")
        #expect(TestStoreFiles.sentLog(of: url).path == "/tmp/run/tessera-test-sent-log.json")
        #expect(TestStoreFiles.ledger(of: url).deletingLastPathComponent() == url.deletingLastPathComponent())
        #expect(TestStoreFiles.trace(of: url) != TestStoreFiles.sentLog(of: url))
    }
}
