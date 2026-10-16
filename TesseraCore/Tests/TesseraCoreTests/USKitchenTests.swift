import Foundation
@testable import TesseraCore
import Testing

/// US shop (docs/design/kitchen/us-shop.md, us-kitchen-pages.md §6; Research's U1 to U7 and merge rows in
/// fixtures/recipe-paste-corpus.md): US units kept as written, pack sizes, merging, fractions, aisles.
@MainActor
struct USKitchenTests {
    func line(_ text: String) throws -> IngredientLine {
        try #require(IngredientLine.parse(text))
    }

    @Test(arguments: [
        ("U1", "1 bag spinach (6 oz)", 1.0, KitchenUnit.bag, "6 oz", "spinach"),
        ("U2", "1 jar marinara (24 oz)", 1, .jar, "24 oz", "marinara"),
        ("U3", "1 carton chicken broth (32 fl oz)", 1, .carton, "32 fl oz", "chicken broth"),
        ("U4", "2 (15 oz) cans chickpeas", 2, .can, "15 oz", "chickpeas"),
        ("U5", "1 (14.5 oz) can diced tomatoes", 1, .can, "14.5 oz", "diced tomatoes"),
        ("U6", "1 can (14.5 oz) diced tomatoes", 1, .can, "14.5 oz", "diced tomatoes"),
        ("P1", "1 (15-ounce) can black beans", 1, .can, "15 oz", "black beans"),
        ("P2", "1 14.5 oz can fire roasted tomatoes", 1, .can, "14.5 oz", "fire roasted tomatoes"),
        ("P3", "1 (6 oz) bag spinach", 1, .bag, "6 oz", "spinach"),
    ])
    func packSizes(_ id: String, _ text: String, _ amount: Double, _ unit: KitchenUnit, _ size: String,
                   _ name: String) throws
    {
        let parsed = try line(text)
        #expect(parsed.amount == amount && parsed.unit == unit, "\(id)")
        #expect(parsed.packSize == size && parsed.name == name, "\(id)")
    }

    @Test(arguments: [
        ("8 oz spaghetti", 8.0, KitchenUnit.ounce, "spaghetti"),
        ("1 lb ground turkey", 1, .pound, "ground turkey"),
        ("2 lbs chicken thighs", 2, .pound, "chicken thighs"),
        ("4 fl oz heavy cream", 4, .fluidOunce, "heavy cream"),
        ("4 fl. oz heavy cream", 4, .fluidOunce, "heavy cream"),
        ("1 pint cherry tomatoes", 1, .pint, "cherry tomatoes"),
        ("16oz pasta", 16, .ounce, "pasta"),
        ("1 stick butter", 1, .stick, "butter"),
    ])
    func usUnitsParse(_ text: String, _ amount: Double, _ unit: KitchenUnit, _ name: String) throws {
        let parsed = try line(text)
        #expect(parsed.amount == amount && parsed.unit == unit && parsed.name == name, "\(text)")
        #expect(parsed.packSize == nil)
    }

    func groceries(_ lines: [String]) throws -> [ListContents.Item] {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        try ActionEngine(store: store, classes: classes).perform(AddGroceries(lines: lines), by: .user)
        let list = try #require(Groceries(store: store, classes: classes).list)
        return ListContents(store: store, classes: classes).items(of: list)
    }

    @Test func mergeRows() throws {
        // Same unit adds; ounces roll into pounds on a quarter pound; volume never merges with weight; metric never
        // merges with US; fluid ounces never with ounces.
        #expect(try groceries(["8 oz spaghetti", "8 oz spaghetti"]).map(\.quantity) == ["1 lb"])
        #expect(try groceries(["12 oz spaghetti", "12 oz spaghetti"]).map(\.quantity) == ["1½ lb"])
        #expect(try groceries(["9 oz spaghetti", "9 oz spaghetti"]).map(\.quantity) == ["18 oz"])
        #expect(try groceries(["1 lb ground turkey", "1 lb ground turkey"]).map(\.quantity) == ["2 lb"])
        #expect(try groceries(["1 lb spinach", "2 cups spinach"]).map(\.quantity) == ["1 lb + 2 cups"])
        #expect(try groceries(["500 g ground beef", "1 lb ground beef"]).map(\.quantity) == ["500 g + 1 lb"])
        #expect(try groceries(["4 fl oz heavy cream", "4 oz heavy cream"]).map(\.quantity) == ["4 oz + 4 fl oz"])
    }

    @Test func packSizesMergeOnlyWhenTheSizeMatches() throws {
        // U4: same size adds. U5: two sizes stay two rows, never "2". A sized can never joins an unsized one.
        let same = try groceries(["2 (15 oz) cans chickpeas", "1 (15 oz) can chickpeas"])
        #expect(same.map(\.quantity) == ["3 cans"])
        let mixed = try groceries(["1 (14.5 oz) can diced tomatoes", "1 (28 oz) can diced tomatoes"])
        #expect(mixed.count == 2 && mixed.allSatisfy { $0.quantity == "1 can" })
        #expect(try groceries(["1 (13.5 oz) can coconut milk", "1 can coconut milk"]).count == 2)
        // U6, and never Produce.
        let tins = try groceries(["1 can (14.5 oz) diced tomatoes", "1 can (14.5 oz) diced tomatoes"])
        #expect(tins.map(\.quantity) == ["2 cans"] && tins.first?.section == "Cans and jars")
    }

    @Test func fractionsShowAsGlyphs() {
        #expect(IngredientLine.kitchenNumber(1.0 / 3, unit: .cup) == "⅓")
        #expect(IngredientLine.kitchenNumber(2.0 / 3, unit: .cup) == "⅔")
        #expect(IngredientLine.kitchenNumber(1.125, unit: .cup) == "1⅛")
        #expect(IngredientLine.kitchenNumber(1.5, unit: .pound) == "1½")
    }

    @Test func formerAisleNamesReadAsTheNewOnes() {
        #expect(Aisle.shown("Tins and jars") == "Cans and jars" && Aisle.shown("Dry goods") == "Pantry")
        #expect(Aisle.shown("Meat and fish") == "Meat and seafood" && Aisle.shown("Dairy") == "Dairy and eggs")
        #expect(Aisle.order(of: "Tins and jars") == Aisle.order(of: "Cans and jars"))
        #expect(Aisle.allCases.map(\.rawValue) == ["Produce", "Bakery", "Dairy and eggs", "Meat and seafood",
                                                   "Cans and jars", "Pantry", "Spices", "Frozen", "Household",
                                                   "Other"])
    }

    @Test func resizingRoundsTheNewUnitsSensibly() {
        #expect(RecipeMath.round(7.4, unit: .ounce) == 7 && RecipeMath.round(1.3, unit: .pound) == 1.25)
        #expect(RecipeMath.round(1.3, unit: .pint) == 1.5 && RecipeMath.round(2.4, unit: .can) == 2)
    }
}
