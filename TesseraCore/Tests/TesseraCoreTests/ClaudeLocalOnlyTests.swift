import Foundation
import GRDB
@testable import TesseraCore
import Testing

/// Claude's receipts and the phrases waiting for Claude stay in the local copy on the phone: never in the iCloud copy
/// or the shared export.
@MainActor
struct ClaudeLocalOnlyTests {
    let base = PrivateWordsTests()

    func storeWithClaudeRows(at url: URL) throws -> ObjectStore {
        let store = try base.storeWithEverything(at: url)
        let classes = try store.prepareCatalog()
        let call = try store.create(#require(classes[.tessCall]), title: "Capture quokkaphrase")
        try store.set("costNano", to: .number(1234), on: call)
        try store.create(#require(classes[.tessWaiting]), title: "ring the quokkaplumber on tuesday")
        store.save()
        return store
    }

    @Test func theSharedExportLeavesClaudeReceiptsAndWaitingPhrasesOut() throws {
        let dir = try base.folder()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = try storeWithClaudeRows(at: dir.appendingPathComponent("tessera.sqlite"))
        let json = try base.text(of: TesseraExport(context: store.context).encoded())
        #expect(!json.contains("quokka"), "a Claude row leaked into the export")
        #expect(json.contains("Buy lemons"))
        // The test-only lossless export still has them, so the rows are really there.
        #expect(try base.text(of: TesseraExport(context: store.context, maskingPrivate: false).encoded())
            .contains("quokkaphrase"))
    }

    @Test func theICloudCopyLeavesThemOutAndTheLocalBackupKeepsThem() throws {
        let dir = try base.folder()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = try storeWithClaudeRows(at: dir.appendingPathComponent("tessera.sqlite"))
        let icloud = dir.appendingPathComponent("icloud.sqlite")
        let local = dir.appendingPathComponent("local.sqlite")
        try TesseraBackup.write(from: store.context, to: icloud, leavingOutPrivate: true)
        try TesseraBackup.write(from: store.context, to: local)
        func titles(_ url: URL) throws -> [String] {
            try DatabaseQueue(path: url.path).read { try String.fetchAll($0, sql: "SELECT title FROM object") }
        }
        #expect(try !titles(icloud).contains { $0.contains("quokka") })
        #expect(try titles(icloud).contains("Buy lemons"))
        #expect(try titles(local).contains("Capture quokkaphrase"))
        #expect(try titles(local).contains("ring the quokkaplumber on tuesday"))
    }
}
