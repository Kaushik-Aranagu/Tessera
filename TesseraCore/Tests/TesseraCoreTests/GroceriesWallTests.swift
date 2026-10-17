import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// The wall on the Add line, the Bar, Siri and tools (Product 8:40 AM PT Oct 17; Kitchen specs #759 A1, A2): it lives
/// in AddGroceries, so every caller gets it.
@MainActor
struct GroceriesWallTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine

    init() throws {
        classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
    }

    func rows() -> [String] {
        let groceries = Groceries(store: store, classes: classes)
        return groceries.shoppingOrder().map(\.text)
    }

    nonisolated static let keyLine = ["sk", "ant"].joined(separator: "-") + "-" + "api03-" + "TESTFAKE" + String(
        repeating: "x",
        count: 20
    )

    func everythingShown() -> String {
        engine.history().flatMap { [$0.summary, $0.receipt ?? ""] }.joined(separator: "\n")
    }

    @Test(arguments: [("milk $4", "milk"), ("eggs 3 dollars", "eggs"), ("milk 4.99", "milk")])
    func priceComesOffAndTheThingStays(_ line: String, _ kept: String) throws {
        let record = try engine.perform(AddGroceries(lines: [line]), by: .user).record
        #expect(rows() == [kept])
        #expect(record.receipt == "\(kept.prefix(1).uppercased() + kept.dropFirst()), on Groceries")
        for word in ["$", "4.99", "dollars"] {
            #expect(!everythingShown().contains(word))
        }
    }

    @Test(arguments: ["2 lb chicken", "14 oz can tomatoes", "6 eggs", "1.25 cups flour"])
    func numbersThatAreAmountsStay(_ line: String) throws {
        try engine.perform(AddGroceries(lines: [line]), by: .user)
        #expect(rows().count == 1, "\(line)")
    }

    @Test(arguments: ["$40 at costco", "rent 2100 fri", "$40", "wifi password is tacocat12",
                      "reset the garage code 4471", keyLine])
    func aWalledLineNeverLandsAsARow(_ line: String) {
        #expect(throws: ActionError.self) { try engine.perform(AddGroceries(lines: [line]), by: .user) }
        #expect(rows().isEmpty)
        #expect(engine.history().isEmpty, "\(line)")
    }

    @Test func privateItemRowShowsPrivateItem() throws {
        let record = try engine.perform(AddGroceries(lines: ["lexapro"]), by: .user).record
        #expect(rows() == ["lexapro"])
        #expect(record.receipt == "Private item, on Groceries" && record.summary == "Private item, on Groceries")
    }

    @Test func mixedBatchKeepsTheCleanLinesOnly() throws {
        let record = try engine.perform(AddGroceries(lines: ["milk $4", "wifi password is tacocat12", "eggs"]),
                                        by: .user).record
        #expect(rows().sorted() == ["eggs", "milk"])
        #expect(record.receipt == "Milk and eggs, on Groceries")
        #expect(!everythingShown().contains("tacocat") && !everythingShown().contains("$"))
        engine.undo(record)
        #expect(rows().isEmpty)
    }

    @Test func theWallIsOnTheActionNotTheCaller() async throws {
        // The tool and the Bar land the same row as the action.
        let json = try JSONSerialization.data(withJSONObject: ["list": "Groceries", "items": [["text": "milk $4"]]])
        _ = try TessTools.run("addToList", arguments: json, engine: engine)
        #expect(rows() == ["milk"])
        let other = ObjectStore.open(inMemory: true)
        let otherEngine = try ActionEngine(store: other, classes: other.prepareCatalog())
        let bar = await TessCaptureEngine(engine: otherEngine).capture("buy milk 4.99", context: TessContext())
        #expect(Groceries(store: other, classes: otherEngine.classes).shoppingOrder().map(\.text) == ["milk"])
        #expect(!bar.line.contains("4.99"), "\(bar.line)")
    }

    @Test func withoutPriceTakesABareTwoPlaceDecimal() {
        #expect(EngineWall.withoutPrice("milk 4.99") == "milk")
        #expect(EngineWall.withoutPrice("1.5 kg rice") == "1.5 kg rice")
        #expect(EngineWall.withoutPrice("1.25 cups flour") == "1.25 cups flour")
    }

    // MARK: QA lows on #763

    @Test func aSecondMedicineIsStillAPrivateItem() async {
        let first = await TessCaptureEngine(engine: engine).capture("buy lexapro", context: TessContext())
        let second = await TessCaptureEngine(engine: engine).capture("buy lexapro", context: TessContext())
        #expect(first.line == "Private item, on Groceries.")
        #expect(second.line == "Private item, already on Groceries.", "\(second.line)")
    }

    @Test func aWalledIngredientHeAlreadyHasGoesBackOn() throws {
        // A Pantry swipe on an ingredient he already has, whose name the wall would refuse as a new line: the wall
        // keeps it (nothing new is written by its name) and the receipt says "Private item".
        try store.create(#require(classes[.ingredient]), title: "Wifi password")
        #expect(AddListItem.kept("Wifi password", store: store) == nil)
        #expect(AddGroceries.kept(["Wifi password"], store: store) == ["Wifi password"])
        #expect(AddGroceries(lines: ["Wifi password"]).summary(in: store) == "Private item, on Groceries")
        #expect(AddGroceries.kept(["Wifi password"], store: ObjectStore.open(inMemory: true)).isEmpty)
    }

    @Test(arguments: [
        ("milk 4.99.", "milk"),
        ("1.50 lb apples", "1.50 lb apples"),
        ("2 kg rice", "2 kg rice"),
        ("1.25 lb chicken", "1.25 lb chicken"),
        ("2 for 1 crackers", "2 for 1 crackers"),
    ])
    func moreAmountsLand(_ line: String, _ kept: String) throws {
        try engine.perform(AddGroceries(lines: [line]), by: .user)
        #expect(rows().count == 1, "\(line)")
        #expect(AddListItem.kept(line, store: store) == kept)
    }

    @Test func aWeighInIsStillWalled() {
        #expect(AddListItem.kept("82.4 kg this morning", store: store) == nil)
    }

    @Test func checkingOrMovingAMedicineNeverNamesIt() throws {
        // G41: only the add shows his words.
        let list = try engine.perform(CreateList(name: "Errands"), by: .user).output
        let item = try engine.perform(AddListItem(list: list.id, text: "lexapro"), by: .user).output
        let check = try engine.perform(CheckListItem(item: item.id), by: .user).record
        let move = try engine.perform(MoveListItem(item: item.id, section: "Pharmacy"), by: .user).record
        for record in [check, move] {
            #expect(!record.summary.lowercased().contains("lexapro") && !(record.receipt ?? "").lowercased()
                .contains("lexapro"))
        }
        #expect(check.receipt == "Private item, got")
    }

    @Test func aPantrySwipeOnAWalledIngredientMakesARowNotANote() throws {
        // QA on #770: the swipe adds the row; no note is made and nothing throws.
        try store.create(#require(classes[.ingredient]), title: "Wifi password")
        let notes = try store.objects(of: #require(classes[.note])).count
        let record = try engine.perform(AddGroceries(lines: ["Wifi password"]), by: .user).record
        #expect(rows().count == 1)
        #expect(try store.objects(of: #require(classes[.note])).count == notes)
        #expect(record.receipt == "Private item, on Groceries")
    }

    @Test(arguments: ["82.4 kg fasted", "82.4 kg after run", "82.4 kg lighter", "82.4 kg post workout"])
    func aWeighInWithAnEverydayWordIsNotFood(_ line: String) {
        #expect(AddListItem.kept(line, store: store) == nil, "\(line)")
    }

    @Test func theBarNeverEchoesAWalledListName() async {
        let made = await TessCaptureEngine(engine: engine).capture("new list: lexapro", context: TessContext())
        #expect(!made.line.lowercased().contains("lexapro"), "\(made.line)")
        let again = await TessCaptureEngine(engine: engine).capture("new list: lexapro", context: TessContext())
        #expect(again.line == "Private list, already a list.", "\(again.line)")
    }

    @Test func aPriceBeforeAListUnitIsStillAPrice() {
        // QA on #776: a two-place decimal before a unit with no thing after it is a price.
        #expect(AddListItem.kept("milk 3.49 gallon", store: store) == nil)
        #expect(AddListItem.kept("ice cream 5.99 pint", store: store) == nil)
        #expect(AddListItem.kept("1.25 lb chicken", store: store) == "1.25 lb chicken")
        #expect(AddListItem.kept("2 gallons milk", store: store) == "2 gallons milk")
        #expect(AddListItem.kept("1.25 cups flour", store: store) == "1.25 cups flour")
    }
}
