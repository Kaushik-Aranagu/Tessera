import Foundation
import GRDB
@testable import TesseraCore
import Testing

/// QA low on 215: secure_delete is on for the whole file store, so deletes must stay quick at scale.
@MainActor
struct SecureDeleteTimingTests {
    /// Makes a file store with 3000 tasks and times deleting them all, with secure_delete as the store set it or
    /// switched off.
    func bulkDelete(secure: Bool) throws -> Double {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = try ObjectStore(context: TesseraContext(url: dir.appendingPathComponent("tessera.sqlite")))
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        let on = try store.context.database.read { try Int.fetchOne($0, sql: "PRAGMA secure_delete") }
        #expect(on == 1, "the store opens with secure_delete on")
        if !secure {
            try store.context.database.writeWithoutTransaction { try $0.execute(sql: "PRAGMA secure_delete = OFF") }
        }
        let task = try #require(engine.classes[.task])
        let made = (0 ..< 3000).map { store.create(task, title: "Item \($0)") }
        try store.context.save()
        let took = ContinuousClock().measure {
            for object in made {
                store.context.delete(object)
            }
            try? store.context.save()
            store.context.scrubLog()
        }
        return Double(took.components.seconds) + Double(took.components.attoseconds) / 1e18
    }

    /// 2 s on an idle Mac; under load the same work with secure_delete off sets the pace, so a busy Mac cannot fail
    /// this and a real slowdown from secure_delete (several times slower than off) still does.
    @Test func theFileStoreOverwritesDeletedRowsAndABulkDeleteStaysQuick() throws {
        let secure = try bulkDelete(secure: true)
        let plain = try bulkDelete(secure: false)
        print("bulk delete of 3000 rows: secure \(secure) s, plain \(plain) s")
        #expect(secure < 2 || secure < 4 * plain, "secure \(secure) s against \(plain) s without")
    }
}
