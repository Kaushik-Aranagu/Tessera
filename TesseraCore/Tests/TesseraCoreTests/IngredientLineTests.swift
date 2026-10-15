import Foundation
@testable import TesseraCore
import Testing

struct IngredientLineTests {
    @Test(arguments: [
        ("200 g flour", 200.0, nil as Double?, KitchenUnit.gram as KitchenUnit?, "flour", nil as String?, false),
        ("200g flour", 200, nil, .gram, "flour", nil, false),
        ("2 tbsp olive oil", 2, nil, .tablespoon, "olive oil", nil, false),
        ("1 onion, finely diced", 1, nil, nil, "onion", "finely diced", false),
        ("2–3 cloves garlic", 2, 3, .clove, "garlic", nil, false),
        ("2-3 cloves of garlic, crushed", 2, 3, .clove, "garlic", "crushed", false),
        ("½ tsp salt", 0.5, nil, .teaspoon, "salt", nil, false),
        ("1½ cups milk", 1.5, nil, .cup, "milk", nil, false),
        ("1 1/2 kg potatoes (floury)", 1.5, nil, .kilogram, "potatoes", nil, false),
        ("a handful of basil", 1, nil, .handful, "basil", nil, false),
        ("a pinch of chilli flakes", 1, nil, .pinch, "chilli flakes", nil, false),
        ("an onion", 1, nil, nil, "onion", nil, false),
        ("400 ml tin coconut milk", 400, nil, .millilitre, "tin coconut milk", nil, false),
    ])
    // swiftlint:disable:next function_parameter_count
    func readsALine(text: String, amount: Double, max: Double?, unit: KitchenUnit?, name: String, prep: String?,
                    toTaste: Bool) throws
    {
        let line = try #require(IngredientLine.parse(text))
        #expect(line.amount == amount)
        #expect(line.amountMax == max)
        #expect(line.unit == unit)
        #expect(line.name == name)
        #expect(line.prep == prep)
        #expect(line.toTaste == toTaste)
        #expect(line.original == text)
    }

    @Test func toTasteAndMetric() throws {
        let salt = try #require(IngredientLine.parse("salt to taste"))
        #expect(salt.amount == nil && salt.name == "salt" && salt.toTaste)
        let both = try #require(IngredientLine.parse("Salt and pepper, to taste"))
        #expect(both.name == "Salt and pepper" && both.toTaste && both.prep == nil)
        #expect(IngredientLine.parse("2 tbsp olive oil")?.metricText == "30 ml")
        #expect(IngredientLine.parse("1 cup rice")?.metricAmount == 240)
        #expect(IngredientLine.parse("200 g flour")?.metricText == nil) // already metric
        #expect(IngredientLine.parse("   ") == nil)
        #expect(IngredientLine.key(for: "Tomatoes") == "tomato")
        #expect(IngredientLine.key(for: "cherries") == "cherry")
        #expect(IngredientLine.key(for: "Bay leaves") == "bay leaf")
        #expect(IngredientLine.key(for: "couscous") == "couscous")
    }

    @MainActor
    @Test func linesFindOrCreateTheirIngredient() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let book = IngredientBook(store: store, classes: classes)
        var transaction = Transaction(store: store, classes: classes)
        let tomato = try transaction.ingredient(named: "tomatoes")
        #expect(tomato.title == "Tomato")
        #expect(try transaction.ingredient(named: "Tomato").id == tomato.id)
        #expect(book.find("TOMATOES")?.id == tomato.id)
        #expect(book.all().count == 1)
    }
}
