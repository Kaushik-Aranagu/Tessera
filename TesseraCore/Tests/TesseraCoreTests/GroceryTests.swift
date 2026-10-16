import Foundation
@testable import TesseraCore
import Testing

@MainActor
struct GroceryTests {
    let store = ObjectStore.open(inMemory: true)

    @Test func recipesMergeIntoAislesAndComeBackOut() throws {
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let groceries = Groceries(store: store, classes: classes)
        let lists = ListContents(store: store, classes: classes)
        let list = try #require(groceries.list)

        let sauce = try engine.perform(CreateRecipe(text: """
        Tomato sauce
        Serves 2
        Ingredients
        400 g tomatoes
        1 onion
        2 tbsp olive oil
        salt to taste
        Method
        Cook it down for 20 min.
        """), by: .user).output
        let salad = try engine.perform(CreateRecipe(text: """
        Salad
        Ingredients
        200 g tomatoes
        1 cucumber
        Method
        Chop and dress.
        """), by: .user).output

        try engine.perform(AddRecipeToGroceries(recipe: sauce.id), by: .user)
        let added = try engine.perform(AddRecipeToGroceries(recipe: salad.id), by: .user)
        // Staples (olive oil) and "to taste" lines are skipped; tomatoes merge.
        #expect(lists.items(of: list).map(\.text) == ["tomatoes", "onion", "cucumber"])
        let tomato = try #require(lists.items(of: list).first)
        #expect(tomato.quantity == "600 g")
        #expect(tomato.section == "Produce")
        #expect(Set(groceries.recipes(for: tomato.object).map(\.title)) == ["Tomato sauce", "Salad"])
        #expect(groceries.aisles().map(\.aisle) == ["Produce"])

        // Added again at 4: the sauce's share becomes 800 g (replaced, not doubled), plus the salad's 200 g.
        try engine.perform(AddRecipeToGroceries(recipe: sauce.id, serves: 4), by: .user)
        #expect(lists.item(tomato.object).quantity == "1 kg")
        try engine.perform(AddRecipeToGroceries(recipe: sauce.id, serves: 4), by: .user)
        #expect(lists.item(tomato.object).quantity == "1 kg")

        // Taking the salad back out leaves the sauce's share; cucumber was only for the salad.
        try engine.perform(RemoveRecipeFromGroceries(recipe: salad.id), by: .user)
        #expect(lists.item(tomato.object).quantity == "800 g")
        #expect(lists.items(of: list).map(\.text) == ["tomatoes", "onion"])
        #expect(added.output.count == 2)
        #expect(groceries.share(of: sauce).count == 2)
        #expect(groceries.share(of: salad).isEmpty)
    }

    @Test func typedLinesFindTheirAisleAndMovesTeachIt() throws {
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let groceries = Groceries(store: store, classes: classes)
        let lists = ListContents(store: store, classes: classes)
        let list = try #require(groceries.list)

        try engine.perform(AddGroceries(lines: ["milk", "2 lemons", "500 g beef mince", "sriracha"]), by: .user)
        let items = lists.items(of: list)
        #expect(items.map(\.section) == ["Dairy and eggs", "Produce", "Meat and seafood", "Other"])
        #expect(items[1].quantity == "2")
        #expect(groceries.aisles().map(\.aisle) == ["Produce", "Dairy and eggs", "Meat and seafood", "Other"])

        // Typing it again merges.
        try engine.perform(AddGroceries(lines: ["1 lemon"]), by: .user)
        #expect(lists.item(items[1].object).quantity == "3")

        // Moving sriracha to Cans and jars teaches it.
        try engine.perform(MoveListItem(item: items[3].id, section: Aisle.cansJars.rawValue), by: .user)
        try engine.perform(CheckListItem(item: items[3].id), by: .user)
        try engine.perform(ClearDoneItems(list: list.id), by: .user)
        try engine.perform(AddGroceries(lines: ["sriracha"]), by: .user)
        #expect(lists.items(of: list).last?.section == "Cans and jars")
        #expect(AisleGuide.aisle(for: "red onions") == .produce)
        #expect(AisleGuide.aisle(for: "smoked paprika") == .spices)
    }

    @Test func anIngredientListedTwiceSumsAndStillReplacesOnReAdd() throws {
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let lists = ListContents(store: store, classes: classes)
        let pie = try engine.perform(CreateRecipe(text: """
        Apple pie
        Serves 4
        Ingredients
        200 g butter
        300 g flour
        50 g butter
        Method
        Make the pastry, then the filling.
        """), by: .user).output
        try engine.perform(AddRecipeToGroceries(recipe: pie.id), by: .user)
        let list = try #require(Groceries(store: store, classes: classes).list)
        let butter = try #require(lists.items(of: list).first { $0.text == "butter" })
        #expect(butter.quantity == "250 g")
        try engine.perform(AddRecipeToGroceries(recipe: pie.id, serves: 8), by: .user)
        let butters = lists.open(in: list).filter { $0.text == "butter" }
        #expect(butters.map(\.quantity) == ["500 g"])
    }
}
