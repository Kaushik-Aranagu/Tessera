import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// G40 (docs/product/kitchen-test-specs-wall-g40-g43-g44-oct17.md B1): a name that matches two lists asks which, and a
/// repeat name opens the list that is there.
@MainActor
struct ListLookupTests {
    let store = ObjectStore.open(inMemory: true)

    func engine() throws -> ActionEngine {
        try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    /// A list made the way a Shortcut might, bypassing the repeat rule.
    @discardableResult
    func makeList(_ title: String, in engine: ActionEngine) throws -> ObjectRecord {
        var transaction = Transaction(store: store, classes: engine.classes)
        return try transaction.create(transaction.classDef(.list), title: title)
    }

    /// Runs `addToList` and commits what it wrote; returns the receipts.
    @discardableResult
    func add(_ list: String, _ text: String, engine: ActionEngine) throws -> [String] {
        let json = #"{"list":"\#(list)","items":[{"text":"\#(text)"}]}"#
        let records = try TessTools.run("addToList", arguments: Data(json.utf8), engine: engine)
        for record in records where record.state == .pending {
            try engine.commit(record)
        }
        return records.compactMap(\.receipt)
    }

    func refusal(_ list: String, _ text: String, engine: ActionEngine) -> String? {
        do {
            try add(list, text, engine: engine)
            return nil
        } catch {
            return (error as? TessToolError)?.description
        }
    }

    func items(on title: String, engine: ActionEngine) -> [String] {
        let lists = ListContents(store: store, classes: engine.classes)
        return lists.lists().filter { $0.title == title }.flatMap { lists.items(of: $0).map(\.text) }
    }

    func count(_ engine: ActionEngine) -> (ops: Int, objects: Int) {
        (engine.history(limit: 1000).count, store.context.objects.count)
    }

    @Test func twoListsWithTheSameNameRefuse() throws {
        let engine = try engine()
        try makeList("Packing", in: engine)
        try makeList("Packing", in: engine)
        store.save()
        let before = count(engine)
        #expect(refusal("packing", "sunscreen", engine: engine) == "More than one list like packing")
        #expect(items(on: "Packing", engine: engine).isEmpty)
        #expect(count(engine) == before)
    }

    @Test func twoPrefixMatchesRefuse() throws {
        let engine = try engine()
        try makeList("Trip 2025", in: engine)
        try makeList("Trip to Lisbon", in: engine)
        let before = count(engine)
        #expect(refusal("trip", "adapter", engine: engine) == "More than one list like trip")
        #expect(items(on: "Trip 2025", engine: engine).isEmpty && items(on: "Trip to Lisbon", engine: engine).isEmpty)
        #expect(count(engine) == before)
    }

    @Test func exactNameWinsWhenItIsOneList() throws {
        let engine = try engine()
        for title in ["Trip", "Trip 2025", "Trip to Lisbon"] {
            try makeList(title, in: engine)
        }
        let receipts = try add("trip", "adapter", engine: engine)
        #expect(receipts.contains("Adapter, on Trip"))
        #expect(items(on: "Trip", engine: engine) == ["adapter"] || items(on: "Trip", engine: engine) == ["Adapter"])
        #expect(items(on: "Trip 2025", engine: engine).isEmpty && items(on: "Trip to Lisbon", engine: engine).isEmpty)
    }

    @Test func onePrefixMatchLands() throws {
        let engine = try engine()
        try makeList("Packing", in: engine)
        let receipts = try add("pack", "socks", engine: engine)
        #expect(receipts.contains("Socks, on Packing"))
    }

    @Test func shortPrefixNeverMatches() throws {
        let engine = try engine()
        try makeList("Packing", in: engine)
        #expect(refusal("p", "socks", engine: engine) == "no list called p")
        #expect(refusal("pa", "socks", engine: engine) == "no list called pa")
        #expect(items(on: "Packing", engine: engine).isEmpty)
    }

    @Test func uniqueThreeLetterPrefixStillMatches() throws {
        let engine = try engine()
        try makeList("Packing", in: engine)
        try add("pac", "socks", engine: engine)
        #expect(items(on: "Packing", engine: engine).count == 1)
    }

    @Test func groceriesWordKeepsMeaningBuiltIn() throws {
        let engine = try engine()
        try engine.perform(AddGroceries(lines: ["eggs"]), by: .user)
        try add("groceries", "milk", engine: engine)
        #expect(Groceries(store: store, classes: engine.classes).isOn("milk"))
    }

    @Test(.disabled("G29 vs G40 not ruled"))
    func hisOwnGroceriesList() throws {
        let engine = try engine()
        try engine.perform(AddGroceries(lines: ["eggs"]), by: .user)
        try makeList("Groceries", in: engine)
        #expect(refusal("groceries", "soap", engine: engine) == "More than one list like groceries")
    }

    @Test func refusalNamesNoPrivateWord() throws {
        let engine = try engine()
        try makeList("lexapro", in: engine)
        try makeList("lexapro", in: engine)
        let line = try #require(refusal("lexapro", "refill", engine: engine))
        #expect(line == "More than one list like that")
        #expect(!line.contains("lexapro"))
    }

    // MARK: CreateList repeat name

    @Test func repeatListNameOpensTheExistingList() throws {
        let engine = try engine()
        let list = try engine.perform(CreateList(name: "Packing"), by: .user).output
        try engine.perform(AddListItem(list: list.id, text: "socks"), by: .user)
        try engine.perform(AddListItem(list: list.id, text: "charger"), by: .user)
        let lists = ListContents(store: store, classes: engine.classes)
        let before = lists.lists().count
        let again = try engine.perform(CreateList(name: "packing "), by: .user)
        #expect(again.output.id == list.id)
        #expect(lists.lists().count == before)
        #expect(lists.items(of: list).count == 2)
        #expect(!again.record.ops.contains {
            if case .create = $0 {
                true
            } else {
                false
            }
        })
        #expect(CreateList.wasRepeat(again.record))
    }

    @Test func repeatListReceiptIsNotMade() throws {
        let engine = try engine()
        let first = try engine.perform(CreateList(name: "Packing"), by: .user)
        #expect(first.record.receipt == "Packing, made")
        #expect(!CreateList.wasRepeat(first.record))
        let again = try engine.perform(CreateList(name: "Packing"), by: .tess)
        #expect(again.record.receipt == "Packing, already a list")
    }

    @Test func deletedListNameCanBeMadeAgain() throws {
        let engine = try engine()
        let list = try engine.perform(CreateList(name: "Packing"), by: .user).output
        try engine.perform(DeleteObject(object: list.id), by: .user)
        let again = try engine.perform(CreateList(name: "Packing"), by: .user)
        #expect(again.output.id != list.id)
        #expect(again.record.receipt == "Packing, made")
    }

    @Test func groceriesNameOpensTheBuiltIn() throws {
        let engine = try engine()
        try engine.perform(AddGroceries(lines: ["milk"]), by: .user)
        let again = try engine.perform(CreateList(name: "Groceries"), by: .user)
        #expect(again.output.id == Groceries.listID)
        #expect(again.record.receipt == "Groceries, already a list")
    }

    @Test func barNewListRepeatOpensIt() async throws {
        let engine = try engine()
        try engine.perform(CreateList(name: "Packing"), by: .user)
        let capture = TessCaptureEngine(engine: engine)
        let result = await capture.capture("new list: packing", context: TessContext())
        #expect(result.records.isEmpty)
        #expect(result.line == "Packing, already a list")
        let lists = ListContents(store: store, classes: engine.classes).lists()
        #expect(lists.count { $0.title.lowercased() == "packing" } == 1)
    }

    @Test func barNewListSaysNewList() async throws {
        let engine = try engine()
        let result = await TessCaptureEngine(engine: engine).capture("new list: packing", context: TessContext())
        #expect(result.records.count == 1)
        #expect(result.line.hasSuffix(", new list"))
    }
}
