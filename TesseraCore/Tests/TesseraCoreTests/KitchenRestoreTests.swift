import Foundation
@testable import TesseraCore
import Testing

/// Kitchen gap hunt 5: what a restore must leave true (G27 a stale cook, G29 one Groceries list).
@MainActor
struct KitchenRestoreTests {
    static let calendar = TesseraDayTests.calendar

    func folder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Copies `source` as it stands, stages it over a fresh store and opens that store the way launch does.
    func restored(_ source: ObjectStore, in dir: URL, madeAt: Date) throws -> (ObjectStore, [SystemCatalog.Key: ClassDef]) {
        source.save()
        let file = dir.appendingPathComponent("copy.tessera")
        try TesseraBackup.write(from: source.context, to: file, now: madeAt)
        let storeURL = dir.appendingPathComponent("restored.sqlite")
        _ = try TesseraBackup.stageRestore(from: file, storeURL: storeURL)
        let store = ObjectStore(context: TesseraSchema.makeContainer(url: storeURL).mainContext)
        let classes = try store.prepareCatalog(now: .now, calendar: Self.calendar)
        return (store, classes)
    }

    func groceryLists(_ store: ObjectStore, _ classes: [SystemCatalog.Key: ClassDef]) throws -> [ObjectRecord] {
        try store.objects(of: #require(classes[.list])).filter { $0.title == "Groceries" }
    }

    @Test func aCopyMadeWithGroceriesDeletedRestoresOneListWithItsRows() throws {
        let dir = try folder()
        defer { try? FileManager.default.removeItem(at: dir) }
        let source = try ObjectStore(context: TesseraContext(url: dir.appendingPathComponent("source.sqlite")))
        let classes = try source.prepareCatalog()
        let engine = ActionEngine(store: source, classes: classes)
        try engine.perform(AddGroceries(lines: ["milk", "eggs", "rice", "oats", "salt"]), by: .user)
        source.softDelete(try #require(source.object(id: Groceries.listID)))
        let (store, restoredClasses) = try restored(source, in: dir, madeAt: TesseraDayTests.at(10, 14, 19))
        let lists = try groceryLists(store, restoredClasses)
        #expect(lists.count == 1 && lists.first?.id == Groceries.listID)
        #expect(Groceries(store: store, classes: restoredClasses).list?.orderedChildren.count == 5)
    }

    @Test func aSecondGroceriesMadeWhileItWasGoneFoldsIntoTheBuiltInOne() throws {
        let dir = try folder()
        defer { try? FileManager.default.removeItem(at: dir) }
        let source = try ObjectStore(context: TesseraContext(url: dir.appendingPathComponent("source.sqlite")))
        let classes = try source.prepareCatalog()
        let engine = ActionEngine(store: source, classes: classes)
        try engine.perform(AddGroceries(lines: ["milk", "eggs"]), by: .user)
        source.softDelete(try #require(source.object(id: Groceries.listID)))
        // `groceriesList()` makes a second "Groceries" beside the deleted one.
        try engine.perform(AddGroceries(lines: ["oatmilk"]), by: .user)
        #expect(try groceryLists(source, classes).count == 1)
        let (store, restoredClasses) = try restored(source, in: dir, madeAt: TesseraDayTests.at(10, 14, 19))
        let lists = try groceryLists(store, restoredClasses)
        #expect(lists.count == 1 && lists.first?.id == Groceries.listID)
        #expect(Groceries(store: store, classes: restoredClasses).list?.orderedChildren.count == 3)
    }
}
