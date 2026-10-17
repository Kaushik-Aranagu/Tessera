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
}
