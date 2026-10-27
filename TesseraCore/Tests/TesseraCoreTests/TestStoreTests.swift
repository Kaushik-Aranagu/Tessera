import Foundation
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
        #expect(!settings.read().isTestStore && !SettingsStore.isTestStore(in: store))
        try settings.stampAsTestStore()
        #expect(settings.read().isTestStore && SettingsStore.isTestStore(in: store))
        try settings.update { $0.restWeekday = 3 }
        try settings.update(by: .user) { $0.rainAlert = true }
        #expect(settings.read().storeKind == "test" && SettingsStore.isTestStore(in: store))
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
