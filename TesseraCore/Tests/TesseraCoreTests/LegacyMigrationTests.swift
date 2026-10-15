import Foundation
import SwiftData
import TesseraCore
@testable import TesseraLegacyStore
import Testing

/// Data written by the SwiftData builds moves into the GRDB store once, with ids and history intact.
@MainActor
struct LegacyMigrationTests {
    @Test func aSwiftDataStoreMovesAcrossOnce() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let legacyURL = folder.appendingPathComponent("default.store")

        // Write an old-style store with the frozen SwiftData models.
        let noteID = UUID()
        let classID = SystemCatalog.stableID("system.note")
        let fieldID = SystemCatalog.stableID("system.thing.notes")
        do {
            let schema = Schema([TesseraLegacyStore.ClassDef.self, TesseraLegacyStore.FieldDef.self,
                                 TesseraLegacyStore.ObjectRecord.self, TesseraLegacyStore.ObjectLink.self,
                                 TesseraLegacyStore.ViewDef.self, TesseraLegacyStore.OpRecord.self])
            let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema,
                                                                                               url: legacyURL))
            let context = container.mainContext
            let note = TesseraLegacyStore.ClassDef(name: "Note", systemKey: "system.note")
            note.id = classID
            context.insert(note)
            let field = TesseraLegacyStore.FieldDef(name: "Notes", key: "notes", kind: .richText)
            field.id = fieldID
            context.insert(field)
            field.owner = note
            let object = TesseraLegacyStore.ObjectRecord(title: "From SwiftData", classDef: nil)
            object.id = noteID
            context.insert(object)
            object.classDef = note
            var values = object.values
            values[fieldID] = .richText("kept")
            object.values = values
            try context.save()
        }

        let target = TesseraSchema.makeContainer(inMemory: true).mainContext
        #expect(try LegacyStore.migrate(from: legacyURL, into: target))
        let moved = try #require(target.objects[noteID])
        #expect(moved.title == "From SwiftData")
        #expect(moved.classDef?.id == classID)
        #expect(moved.values[fieldID] == .richText("kept"))
        // The old files moved into Backups, so it never runs twice.
        #expect(!FileManager.default.fileExists(atPath: legacyURL.path))
        #expect(try LegacyStore.migrate(from: legacyURL, into: target) == false)
    }
}
