import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Lists 4c: the three starter lists and "copy packing for lisbon".
@MainActor
struct StarterListsTests {
    let store = ObjectStore.open(inMemory: true)

    @Test func theThreeStartersInstallOnceAndStayDeleted() throws {
        let classes = try store.prepareCatalog()
        #expect(try StarterLists.installIfNeeded(store: store, classes: classes) == 3)
        let lists = ListContents(store: store, classes: classes)
        let names = lists.lists().map(\.title)
        #expect(["Gym bag", "Leaving the house", "Packing"].allSatisfy(names.contains))
        let bag = try #require(lists.lists().first { $0.title == "Gym bag" })
        #expect(ListNoteTags.isReusable(bag, in: store))
        let rows = lists.items(of: bag)
        #expect(rows.count == 10 && rows.allSatisfy { !$0.isDone })
        #expect(rows.first?.section == "Clothes" && rows.last?.section == "After" && rows.last?.text == "shower gel")
        let leaving = try #require(lists.lists().first { $0.title == "Leaving the house" })
        #expect(lists.items(of: leaving).count == 6 && lists.items(of: leaving).allSatisfy { $0.section == nil })
        // Once: a second launch adds nothing; a deleted starter is not put back.
        #expect(try StarterLists.installIfNeeded(store: store, classes: classes) == 0)
        let engine = ActionEngine(store: store, classes: classes)
        try engine.perform(DeleteObject(object: bag.id), by: .user)
        #expect(try StarterLists.installIfNeeded(store: store, classes: classes) == 0)
        #expect(!lists.lists().map(\.title).contains("Gym bag"))
    }

    @Test func aTestStoreHasNoStartersUntilItAsks() throws {
        let classes = try store.prepareCatalog()
        #expect(ListContents(store: store, classes: classes).lists().map(\.title) == ["Groceries"])
    }

    @Test func copyPackingForLisbonMakesTheTripList() async throws {
        let classes = try store.prepareCatalog()
        try StarterLists.installIfNeeded(store: store, classes: classes)
        let engine = ActionEngine(store: store, classes: classes)
        let tess = TessCaptureEngine(engine: engine)
        let said = await tess.capture("copy packing for lisbon", context: TessContext())
        #expect(said.line == "Packing, Lisbon, new list", "\(said.line)")
        let lists = ListContents(store: store, classes: classes)
        let lisbon = try #require(lists.lists().first { $0.title == "Packing, Lisbon" })
        #expect(lists.items(of: lisbon).count == 11 && lists.items(of: lisbon).allSatisfy { !$0.isDone })
        // The same phrase again opens that list: nothing new.
        let again = await tess.capture("copy packing for lisbon", context: TessContext())
        #expect(again.line == "Packing, Lisbon, already a list" && lists.lists()
            .filter { $0.title == "Packing, Lisbon" }.count == 1)
    }

    @Test func aSourceThatMatchesTwoListsWritesNothing() async throws {
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        try engine.perform(CreateList(name: "Trip one"), by: .user)
        try engine.perform(CreateList(name: "Trip two"), by: .user)
        let before = ListContents(store: store, classes: classes).lists().count
        let tess = TessCaptureEngine(engine: engine)
        let said = await tess.capture("copy trip for lisbon", context: TessContext())
        #expect(said.line == "More than one list like trip" && said.records.isEmpty, "\(said.line)")
        let none = await tess.capture("copy costco for lisbon", context: TessContext())
        // Not one of his lists: not a list phrase, so it is read as before (never "no list called ...").
        #expect(!none.line.contains("no list called"), "\(none.line)")
        #expect(ListContents(store: store, classes: classes).lists().count == before)
    }

    @Test func aSecretWordIsNeverAListName() throws {
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let packing = try engine.perform(CreateList(name: "Packing"), by: .user).output
        #expect(throws: ActionError.self) {
            try engine.perform(CopyList(list: packing.id, name: "wifi password zebra99"), by: .user)
        }
        let made = try engine.perform(CopyList(list: packing.id, name: "Lisbon"), by: .user)
        #expect(!CopyList.wasRepeat(made.record))
        let repeated = try engine.perform(CopyList(list: packing.id, name: "lisbon"), by: .user)
        #expect(CopyList.wasRepeat(repeated.record))
    }

    @Test func copyingAPrivateListIsMaskedInTheLogAndTheDay() async throws {
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let secret = try engine.perform(CreateList(name: "Lexapro refills"), by: .user).output
        let tess = TessCaptureEngine(engine: engine)
        let said = await tess.capture("copy lexapro for lisbon", context: TessContext())
        #expect(said.line == "Private list, new list", "\(said.line)")
        #expect(!engine.history(limit: 20)
            .contains { $0.summary.lowercased().contains("lexapro") && $0.action == "copyList" })
        let copy = try #require(ListContents(store: store, classes: classes).lists()
            .first { $0.id != secret.id && $0.title.lowercased().contains("lisbon") })
        #expect(PrivateWords.labels(in: store.context)[copy.id] != nil)
    }

    @Test func createListRefusesASecretOrKeyName() throws {
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let key = ["sk", "ant", "api03", ""].joined(separator: "-") + String(repeating: "Ab3x", count: 8)
        for name in ["wifi password zebra99", key] {
            #expect(throws: ActionError.self) { try engine.perform(CreateList(name: name), by: .user) }
        }
        #expect(ListContents(store: store, classes: classes).lists().map(\.title) == ["Groceries"])
    }

    @Test func aListHeAlreadyMadeIsNotDoubledAndIsNotRetried() async throws {
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        try engine.perform(CreateList(name: "packing"), by: .user)
        #expect(try StarterLists.installIfNeeded(store: store, classes: classes) == 2)
        let lists = ListContents(store: store, classes: classes)
        #expect(lists.lists().filter { $0.title.lowercased() == "packing" }.count == 1)
        // Handled for good: even once his own is deleted, the starter does not come back.
        let hers = try #require(lists.lists().first { $0.title == "packing" })
        try engine.perform(DeleteObject(object: hers.id), by: .user)
        #expect(try StarterLists.installIfNeeded(store: store, classes: classes) == 0)
        #expect(!lists.lists().contains { $0.title.lowercased() == "packing" })
        // And his own list copies cleanly, with no "More than one".
        try engine.perform(CreateList(name: "Gym bag"), by: .user)
        let tess = TessCaptureEngine(engine: engine)
        let said = await tess.capture("copy gym bag for away", context: TessContext())
        #expect(said.line == "Gym bag, Away, new list", "\(said.line)")
    }

    @Test func copyIsAListPhraseOnlyWhenItNamesAList() async throws {
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        try StarterLists.installIfNeeded(store: store, classes: classes)
        let tess = TessCaptureEngine(engine: engine)
        // Not a list: it falls through to what it was before (a task or a miss), never "no list called report".
        let task = await tess.capture("copy the report to dad", context: TessContext())
        #expect(!task.line.contains("no list called"), "\(task.line)")
        // Siri and Shortcuts never copy a list.
        let siri = await tess.capture("copy packing for lisbon", context: TessContext(commitImmediately: true))
        #expect(!siri.line.contains("new list"), "\(siri.line)")
        #expect(!ListContents(store: store, classes: classes).lists().contains { $0.title == "Packing, Lisbon" })
    }
}
