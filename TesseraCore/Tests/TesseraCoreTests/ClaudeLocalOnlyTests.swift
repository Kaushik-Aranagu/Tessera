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

    @Test func sentLogNeverInBackupOrExport() throws {
        let dir = try base.folder()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = try storeWithClaudeRows(at: dir.appendingPathComponent("tessera.sqlite"))
        let classes = try store.prepareCatalog()
        let sent = try store.create(#require(classes[.tessSent]), title: "capture request")
        try store.set("words", to: .text("zebrasentwords"), on: sent)
        // A subclass of Tess Call is in the family, and a link from a Claude row goes with it.
        let sub = store.createClass(name: "Tess Call Extra", parent: classes[.tessCall])
        let extra = store.create(sub, title: "extra quokkasub")
        let noteClass = try #require(classes[.note])
        let note = try #require(store.objects(of: noteClass).first)
        store.context.insert(ObjectLink(from: sent, fieldID: UUID(), toObject: note))
        store.context.insert(OpRecord(action: "x", actor: .system, summary: "quokkaop",
                                      ops: [.setTitle(object: extra.id, old: "a", new: "quokkaop")], state: .committed))
        store.save()
        let json = try base.text(of: TesseraExport(context: store.context).encoded())
        #expect(!json.contains("zebrasentwords") && !json.contains("quokka"))
        let icloud = dir.appendingPathComponent("icloud.sqlite")
        try TesseraBackup.write(from: store.context, to: icloud, leavingOutPrivate: true)
        let queue = try DatabaseQueue(path: icloud.path)
        let ids = [sent.id, extra.id].map(\.uuidString)
        let counts: [Int] = try queue.read { db in
            try ids.flatMap { id -> [Int] in
                [
                    try Int.fetchOne(db, sql: "SELECT count(*) FROM object WHERE id = ?", arguments: [id]) ?? -1,
                    try Int.fetchOne(db, sql: "SELECT count(*) FROM link WHERE fromID = ?", arguments: [id]) ?? -1,
                    try Int.fetchOne(db, sql: "SELECT count(*) FROM op WHERE instr(objectIDs, ?) > 0",
                                     arguments: [id]) ?? -1,
                ]
            }
        }
        #expect(counts == Array(repeating: 0, count: 6), "\(counts)")
        // The local copy keeps them.
        let local = dir.appendingPathComponent("local.sqlite")
        try TesseraBackup.write(from: store.context, to: local)
        let titles = try DatabaseQueue(path: local.path)
            .read { try String.fetchAll($0, sql: "SELECT title FROM object") }
        #expect(titles.contains("capture request"))
    }
}
