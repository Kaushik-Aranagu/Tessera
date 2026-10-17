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

    @Test func aListHeTitledGroceriesIsLeftAloneAndOnlyTheAppMadeStrayFolds() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        // His own list, made by createList and named by him.
        let his = try engine.perform(CreateList(name: "Groceries"), by: .user).output
        try engine.perform(AddListItem(list: his.id, text: "his own row"), by: .user)
        #expect(Groceries.installIfNeeded(store: store, classes: classes) == 0)
        #expect(!his.isDeleted && his.orderedChildren.count == 1)
        // Then the app makes a stray while the built-in is gone: that one folds, his does not.
        store.softDelete(try #require(store.object(id: Groceries.listID)))
        try engine.perform(AddGroceries(lines: ["oatmilk"]), by: .user)
        let before = try groceryLists(store, classes).filter { !$0.isDeleted }.count
        #expect(before == 2) // his and the app's stray (the built-in is deleted)
        #expect(Groceries.installIfNeeded(store: store, classes: classes) == 1)
        let lists = try groceryLists(store, classes).filter { !$0.isDeleted }
        #expect(Set(lists.map(\.id)) == [his.id, Groceries.listID])
        #expect(his.orderedChildren.count == 1)
        #expect(Groceries(store: store, classes: classes).list?.orderedChildren.count == 1)
        #expect(Groceries.mergedReceipt == "Groceries lists, merged.")
    }

    @Test func aCookRunningWhenTheCopyWasMadeIsClosedAfterTheRestore() throws {
        let dir = try folder()
        defer { try? FileManager.default.removeItem(at: dir) }
        let source = try ObjectStore(context: TesseraContext(url: dir.appendingPathComponent("source.sqlite")))
        let classes = try source.prepareCatalog()
        let engine = ActionEngine(store: source, classes: classes)
        let recipe = try engine.perform(CreateRecipe(text: "Tacos\nIngredients\n1 lb beef\n8 tortillas\nMethod\n1. Brown the beef.\n2. Fill."),
                                        by: .user).output
        let tuesday = TesseraDayTests.at(10, 14, 18, 20)
        let cook = try engine.perform(StartCooking(recipe: recipe.id, time: tuesday), by: .user).output
        let timer = try engine.perform(StartKitchenTimer(label: "beef", minutes: 10, cook: cook.id, time: tuesday),
                                       by: .user).output
        let (store, restoredClasses) = try restored(source, in: dir, madeAt: TesseraDayTests.at(10, 14, 19))
        let book = CookLog(store: store, classes: restoredClasses)
        let restoredCook = try #require(store.object(id: cook.id))
        let process = try #require(store.backlinks(to: restoredCook).first { $0.classDef?.id == restoredClasses[.process]?.id })
        #expect(store.value("state", of: process)?.stringValue == ProcessState.closed.rawValue)
        // Not finished: no cookedAt, so no COOKS count and no "cooked" fact.
        #expect(store.value("cookedAt", of: restoredCook) == nil)
        let restoredTimer = try #require(store.object(id: timer.id))
        #expect(book.timers().isEmpty && store.value("isStopped", of: restoredTimer) == .bool(true))
        // The system closed it: nothing in the day log.
        #expect(store.context.all(OpRecord.self).filter { $0.action == "closeStaleCooks" }.allSatisfy { $0.actor == .system })
    }

    @Test func aCookStartedAfterTheRestoreIsLive() throws {
        let dir = try folder()
        defer { try? FileManager.default.removeItem(at: dir) }
        let source = try ObjectStore(context: TesseraContext(url: dir.appendingPathComponent("source.sqlite")))
        let classes = try source.prepareCatalog()
        let engine = ActionEngine(store: source, classes: classes)
        let recipe = try engine.perform(CreateRecipe(text: "Tacos\nIngredients\n1 lb beef\nMethod\n1. Brown the beef."),
                                        by: .user).output
        let (store, restoredClasses) = try restored(source, in: dir, madeAt: TesseraDayTests.at(10, 14, 19))
        let now = ActionEngine(store: store, classes: restoredClasses)
        let cook = try now.perform(StartCooking(recipe: recipe.id), by: .user).output
        // A later launch over the same store leaves the new cook running.
        _ = try store.prepareCatalog(now: .now, calendar: Self.calendar)
        let process = try #require(store.backlinks(to: cook).first { $0.classDef?.id == restoredClasses[.process]?.id })
        #expect(store.value("state", of: process)?.stringValue == ProcessState.running.rawValue)
    }
}

@MainActor
struct RestoreWeightLineTests {
    @Test func theConfirmLineNamesWhatTheKitchenWillLose() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        func store(_ name: String, recipes: Int) throws -> ObjectStore {
            let store = try ObjectStore(context: TesseraContext(url: dir.appendingPathComponent(name)))
            let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
            for index in 0 ..< recipes {
                try engine.perform(CreateRecipe(text: "Dish \(index)\nIngredients\n1 onion\nMethod\n1. Cook it."), by: .user)
            }
            store.save()
            return store
        }
        let tuesday = try store("tuesday.sqlite", recipes: 6)
        let thursday = try store("thursday.sqlite", recipes: 9)
        let copy = dir.appendingPathComponent("tuesday.tessera")
        try TesseraBackup.write(from: tuesday.context, to: copy)
        #expect(TesseraBackup.restoreWeightLine(copyAt: copy, replacing: thursday.context)
            == "That copy has 6 recipes. The 9 you have now are kept in Backups.")
        // Same weight, no line; the line never holds a recipe's name.
        #expect(TesseraBackup.restoreWeightLine(copyAt: copy, replacing: tuesday.context) == nil)
        #expect(TesseraBackup.restoreWeightLine(copyRecipes: 1, nowRecipes: 1)
            == "That copy has 1 recipe. The 1 you have now is kept in Backups.")
    }
}
