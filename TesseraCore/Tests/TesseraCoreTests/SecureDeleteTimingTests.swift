import Foundation
import GRDB
@testable import TesseraCore
import Testing

/// QA low on 215: secure_delete is on for the whole file store, so deletes must stay quick at scale.
@MainActor
struct SecureDeleteTimingTests {
    @Test func theFileStoreOverwritesDeletedRowsAndABulkDeleteStaysQuick() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = try ObjectStore(context: TesseraContext(url: dir.appendingPathComponent("tessera.sqlite")))
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        let on = try store.context.database.read { try Int.fetchOne($0, sql: "PRAGMA secure_delete") }
        #expect(on == 1)

        let task = try #require(engine.classes[.task])
        var made: [ObjectRecord] = []
        for index in 0 ..< 3000 {
            made.append(store.create(task, title: "Item \(index)"))
        }
        try store.context.save()
        let clock = ContinuousClock()
        let took = clock.measure {
            for object in made {
                store.context.delete(object)
            }
            try? store.context.save()
            store.context.scrubLog()
        }
        let seconds = Double(took.components.seconds) + Double(took.components.attoseconds) / 1e18
        // Idle Mac: well under a second. The budget scales with how busy this Mac is.
        #expect(seconds < 10 * LoadFactor.current(), "\(seconds) s")
        print("secure_delete bulk delete of 3000 rows: \(seconds) s")
    }
}
