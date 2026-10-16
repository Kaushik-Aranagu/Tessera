import Foundation
@testable import TesseraCore
import Testing

@MainActor
struct SchemaSafetyTests {
    @Test func aStoreThatCantBeOpenedIsMovedAsideNotLost() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("default.store")
        // Not a SQLite file at all: the worst case.
        try Data("not a database".utf8).write(to: url)

        let container = TesseraSchema.makeContainer(url: url)
        guard case let .recoveredWithBackup(backup) = TesseraSchema.lastOpenOutcome else {
            Issue.record("expected a recovery, got \(TesseraSchema.lastOpenOutcome)")
            return
        }
        #expect(try String(contentsOf: backup.appendingPathComponent("default.store"), encoding: .utf8) ==
            "not a database")
        // The fresh store works.
        let classes = try SystemCatalog.seed(in: container.mainContext)
        #expect(classes.count == SystemCatalog.Key.allCases.count)
    }

    @Test func aHealthyStoreOpensAndKeepsItsData() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("default.store")
        do {
            let container = TesseraSchema.makeContainer(url: url)
            let classes = try SystemCatalog.seed(in: container.mainContext)
            try ObjectStore(context: container.mainContext).create(#require(classes[.note]), title: "Keep me")
            try container.mainContext.save()
        }
        let reopened = TesseraSchema.makeContainer(url: url)
        #expect(TesseraSchema.lastOpenOutcome == .opened)
        let notes = reopened.mainContext.all(ObjectRecord.self).filter { $0.title == "Keep me" }
        #expect(notes.count == 1)
    }
}
