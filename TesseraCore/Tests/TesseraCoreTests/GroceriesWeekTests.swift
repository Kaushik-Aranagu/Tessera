import Foundation
@testable import TesseraCore
import Testing

/// Research 123's week (docs/research/fixtures/groceries-recipes.md): five real meals on the groceries list, with the
/// Kitchen lead's and Design 47's rulings. The list reads as it should, not as master did.
@MainActor
struct GroceriesWeekTests {
    static let tacos = """
    Sheet-pan chicken fajita tacos
    Serves 4
    1 1/2 lb boneless skinless chicken thighs, sliced
    2 bell peppers, sliced
    1 large yellow onion, sliced
    2 tbsp olive oil
    1 tbsp chili powder
    1 tsp ground cumin
    1 tsp kosher salt
    15 oz black beans, rinsed
    8 small flour tortillas
    1/2 cup chopped fresh cilantro
    1 lime, cut into wedges
    1/2 cup sour cream
    Hot sauce, to taste
    Method
    1. Roast everything 20 min.
    """

    static let chili = """
    Weeknight turkey chili
    Serves 6
    1 tbsp vegetable oil
    1 lb ground turkey
    1 medium onion, diced
    4 garlic cloves, minced
    1 bell pepper, diced
    3 tbsp chili powder
    2 tsp ground cumin
    1 (28 oz) can diced tomatoes
    1 (15 oz) can kidney beans, drained and rinsed
    1 (15 oz) can black beans, drained and rinsed
    1 cup chicken broth
    Salt and pepper, to taste
    Shredded cheddar, for serving (optional)
    Method
    1. Simmer 30 min.
    """

    static let curry = """
    Chickpea coconut curry
    Serves 4
    2 tbsp coconut oil
    1 onion, chopped
    3 cloves garlic, minced
    1 tbsp grated ginger
    2 tbsp Thai red curry paste
    1 tsp garam masala
    1 (15 oz) can chickpeas, drained
    1 (13.5 oz) can coconut milk
    1 (14.5 oz) can diced tomatoes
    4 cups baby spinach
    1 cup jasmine rice
    1 lime, juiced
    2 tbsp cilantro, chopped
    Method
    1. Simmer 20 min.
    """

    static let pasta = """
    Sausage, white bean and spinach pasta
    Serves 4
    12 oz orecchiette
    1 lb sweet Italian sausage, casings removed
    1 tbsp extra-virgin olive oil
    1 head garlic, cloves thinly sliced
    1/4 tsp red pepper flakes
    1 (15 oz) can cannellini beans, rinsed
    1 bag baby spinach (6 oz)
    1/2 cup heavy cream
    1/2 cup grated parmesan, plus more to serve
    Kosher salt and black pepper
    Method
    1. Boil 10 min.
    """

    static let frittata = """
    Spinach and feta frittata
    Serves 4
    8 large eggs
    1/4 cup whole milk
    1 tbsp butter
    2 cups baby spinach
    4 green onions, thinly sliced
    1/2 cup crumbled feta (2 oz)
    1/2 tsp salt
    1/4 tsp black pepper
    Everything bagel seasoning, optional
    Method
    1. Bake 20 min.
    """

    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine
    let groceries: Groceries

    init() throws {
        classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
        groceries = Groceries(store: store, classes: classes)
    }

    func rows() -> [(aisle: String, text: String, quantity: String?)] {
        groceries.aisles().flatMap { aisle in aisle.items.map { (aisle.aisle, $0.text, $0.quantity) } }
    }

    func row(_ text: String) -> (aisle: String, text: String, quantity: String?)? {
        rows().first { $0.text == text }
    }

    @Test func theLinesReadAsResearchExpects() throws {
        // G-R4: optional lines; G-R5: prep words; G-R6: aliases; G-R1: the pack size rides the line.
        let serving = try #require(IngredientLine.parse("Shredded cheddar, for serving (optional)"))
        #expect(serving.optional && serving.name == "cheddar")
        #expect(IngredientLine.parse("Everything bagel seasoning, optional")?.optional == true)
        #expect(IngredientLine.parse("1/2 cup chopped fresh cilantro")?.name == "cilantro")
        #expect(IngredientLine.parse("1 tbsp grated ginger")?.name == "ginger")
        #expect(IngredientLine.parse("1/2 cup crumbled feta (2 oz)")?.name == "feta")
        // QA F1 on #380: "plus more to serve" still adds; QA F2: "extra virgin olive oil" keeps its "extra".
        let parmesan = try #require(IngredientLine.parse("1/2 cup grated parmesan, plus more to serve"))
        #expect(parmesan.name == "parmesan" && !parmesan.optional && parmesan.amount == 0.5)
        #expect(IngredientLine.parse("1 tbsp extra virgin olive oil")?.name == "extra virgin olive oil")
        #expect(IngredientLine.parse("2 extra large eggs")?.name == "eggs")
        #expect(AisleGuide.isStaple(IngredientLine.key(for: "extra virgin olive oil")))
        #expect(IngredientLine.key(for: "whole milk") == "milk" && IngredientLine.key(for: "yellow onion") == "onion")
        #expect(IngredientLine.key(for: "red onion") == "red onion")
        #expect(AisleGuide.isStaple("kosher salt and black pepper") && AisleGuide.isStaple("extra-virgin olive oil"))
        #expect(!AisleGuide.isStaple("coconut oil"))
        #expect(AisleGuide.aisle(for: "chili powder") == .spices && AisleGuide
            .aisle(for: "red pepper flakes") == .spices)
        #expect(AisleGuide.aisle(for: "chicken broth") == .cansJars && AisleGuide.aisle(for: "orecchiette") == .pantry)
        #expect(AisleGuide.aisle(for: "green onions") == .produce)
        // G-R16: teaspoons floor at an eighth.
        #expect(RecipeMath.round(0.125, unit: .teaspoon) == 0.125 && RecipeMath.round(0.3, unit: .teaspoon) == 0.25)
        let recipe = try engine.perform(CreateRecipe(text: Self.chili), by: .user).output
        let lines = RecipeBook(store: store, classes: classes).lines(of: recipe)
        #expect(lines.first { $0.line.name == "diced tomatoes" }?.line.packSize == "28 oz")
        #expect(lines.first { $0.line.name == "cheddar" }?.line.optional == true)
    }

    @Test func theWeekOnTheList() throws {
        // Typed before planning: four bare rows.
        try engine.perform(AddGroceries(lines: ["eggs", "milk", "scallions", "bananas"]), by: .user)
        let tacos = try engine.perform(CreateRecipe(text: Self.tacos), by: .user).output
        let chili = try engine.perform(CreateRecipe(text: Self.chili), by: .user).output
        let curry = try engine.perform(CreateRecipe(text: Self.curry), by: .user).output
        let frittata = try engine.perform(CreateRecipe(text: Self.frittata), by: .user).output

        let addedTacos = try engine.perform(AddRecipeToGroceries(recipe: tacos.id), by: .user)
        // Kosher salt, olive oil and hot sauce stay off; everything else is new: 10 rows (G-R3, G-R14).
        #expect(addedTacos.output.count == 10, "\(addedTacos.output.map(\.title))")
        #expect(addedTacos.record.summary == "Tacos, 10 added.") // the short name (Kitchen lead, #389)
        #expect(RecipeBook.shortName(ofTitle: "Sausage, white bean and spinach pasta") == "Pasta")
        #expect(RecipeBook.shortName(ofTitle: "Weeknight turkey chili") == "Chili")
        #expect(RecipeBook.shortName(ofTitle: "Dal tadka (quick)") == "Tadka")
        #expect(row("kosher salt") == nil && row("olive oil") == nil)
        #expect(row("chili powder")?.aisle == "Spices" && row("cilantro") != nil)

        try engine.perform(AddRecipeToGroceries(recipe: chili.id), by: .user)
        // Black beans: the chili's can and the tacos' 15 oz join, pack first (G-R8); the optional cheddar is absent.
        #expect(row("black beans")?.quantity == "1 can + 15 oz", "\(row("black beans")?.quantity ?? "nil")")
        #expect(row("cheddar") == nil && row("shredded cheddar") == nil)
        #expect(row("chili powder")?.quantity == "4 tbsp" && row("chicken broth")?.aisle == "Cans and jars")
        #expect(row("onion")?.quantity == "2", "\(rows().map(\.text))") // the tacos' yellow onion joined (G-R6)

        try engine.perform(AddRecipeToGroceries(recipe: curry.id), by: .user)
        // Two can sizes of diced tomatoes are two rows, never "2 cans" (G-R1, U5).
        let tomatoes = rows().filter { $0.text == "diced tomatoes" }
        #expect(tomatoes.count == 2 && tomatoes.allSatisfy { $0.quantity == "1 can" }, "\(tomatoes)")
        let items = try #require(groceries.list).orderedChildren
            .filter { store.object(id: $0.id)?.title == "diced tomatoes" }
        #expect(Set(items.compactMap(groceries.packSize(of:))) == ["28 oz", "14.5 oz"])
        #expect(row("limes")?.quantity == "2" || row("lime")?.quantity == "2")

        // r4 at serves 4, then 2 from the recipe page: a smaller size adds nothing and the list never shrinks on its
        // own (Kitchen K34.8, ruling A over r4's old halving); a bigger size replaces the share, nothing doubles.
        let pasta = try engine.perform(CreateRecipe(text: Self.pasta), by: .user).output
        try engine.perform(AddRecipeToGroceries(recipe: pasta.id), by: .user)
        let smaller = try engine.perform(AddRecipeToGroceries(recipe: pasta.id, serves: 2), by: .user)
        #expect(smaller.output.isEmpty && smaller.record.summary == "Pasta, nothing to add.")
        #expect(smaller.record.ops.isEmpty) // no write, so no UNDO
        #expect(row("orecchiette")?.quantity == "12 oz" && row("orecchiette")?.aisle == "Pantry",
                "\(row("orecchiette")?.quantity ?? "nil")")
        #expect(row("sweet italian sausage")?.quantity == "1 lb", "\(row("sweet italian sausage")?.quantity ?? "nil")")
        #expect(row("garlic")?.quantity == "7 cloves + 1 head", "\(row("garlic")?.quantity ?? "nil")")
        #expect(row("red pepper flakes")?.quantity == "¼ tsp" || row("red pepper flakes")?.quantity == "1/4 tsp",
                "\(row("red pepper flakes")?.quantity ?? "nil")")
        #expect(row("cannellini beans")?.quantity == "1 can")
        #expect(row("baby spinach")?.quantity == "1 bag + 4 cups", "\(row("baby spinach")?.quantity ?? "nil")")
        #expect(row("parmesan")?.quantity == "½ cup" || row("parmesan")?.quantity == "1/2 cup",
                "\(row("parmesan")?.quantity ?? "nil")")
        // The same size again: nothing to add too.
        #expect(try engine.perform(AddRecipeToGroceries(recipe: pasta.id), by: .user).output.isEmpty)
        #expect(row("extra virgin olive oil") == nil && row("kosher salt and black pepper") == nil)

        let addedFrittata = try engine.perform(AddRecipeToGroceries(recipe: frittata.id), by: .user)
        // Eggs, milk and spinach join rows already there: 3 new (butter, green onions, feta); G-R2 the bare eggs row
        // shows the recipe's amount.
        #expect(addedFrittata.output.count == 3, "\(addedFrittata.output.map(\.title))")
        #expect(addedFrittata.record.summary == "Frittata, 3 added.")
        #expect(row("eggs")?.quantity == "8")
        #expect(
            row("milk")?.quantity == "¼ cup" || row("milk")?.quantity == "1/4 cup",
            "\(row("milk")?.quantity ?? "nil")"
        )
        #expect(row("everything bagel seasoning") == nil && row("salt") == nil)
        #expect(row("baby spinach")?.quantity == "1 bag + 6 cups", "\(row("baby spinach")?.quantity ?? "nil")")
        // The week: Research's 36 rows plus one, "green onions" beside his typed "scallions", until the AI-12 ask
        // (KEEP folds them) lands; bananas, scallions and milk come from his typed rows.
        #expect(rows().count == 37, "\(rows().count): \(rows().map(\.text))")
        #expect(row("green onions") != nil && row("scallions") != nil)

        // A checked same-key row covers the line: a checked "butter" means the frittata adds no butter (G-R2).
        try engine.perform(RemoveRecipeFromGroceries(recipe: frittata.id), by: .user)
        let butter = try #require(groceries.list).orderedChildren.first { store.object(id: $0.id)?.title == "butter" }
        if let butter {
            try engine.perform(CheckListItem(item: butter.id), by: .user)
        } else {
            try engine.perform(AddGroceries(lines: ["butter"]), by: .user)
            let fresh = try #require(groceries.list?.orderedChildren.first { $0.title == "butter" })
            try engine.perform(CheckListItem(item: fresh.id), by: .user)
        }
        try engine.perform(AddRecipeToGroceries(recipe: frittata.id), by: .user)
        #expect(row("butter") == nil)
    }

    @Test func hisTypedAmountStandsAndNothingToAddWritesNothing() throws {
        // Kitchen lead on G-R2: "1 dozen eggs" keeps its amount; the frittata's 8 eggs lands under it as a line.
        try engine.perform(AddGroceries(lines: ["1 dozen eggs"]), by: .user)
        let frittata = try engine.perform(CreateRecipe(text: Self.frittata), by: .user).output
        try engine.perform(AddRecipeToGroceries(recipe: frittata.id), by: .user)
        let eggs = try #require(groceries.list?.orderedChildren.first { $0.title == "eggs" })
        #expect(row("eggs")?.quantity == "1 dozen",
                "\(row("eggs")?.quantity ?? "nil") shares=\(store.value("shares", of: eggs)?.stringValue ?? "") parse=\(String(describing: IngredientLine.parse("1 dozen eggs")))")
        #expect(groceries.recipes(for: eggs).map(\.id) == [frittata.id])
        // Every line covered or a staple: nothing to add, no write, so no UNDO (Product e1981a39).
        for item in try #require(groceries.list).orderedChildren where store.value("isDone", of: item) != .bool(true) {
            try engine.perform(CheckListItem(item: item.id), by: .user)
        }
        try engine.perform(RemoveRecipeFromGroceries(recipe: frittata.id), by: .user)
        let nothing = try engine.perform(AddRecipeToGroceries(recipe: frittata.id), by: .user)
        #expect(nothing.output.isEmpty && nothing.record.ops.isEmpty)
        #expect(nothing.record.summary == "Frittata, nothing to add.")
    }

    @Test func aBiggerSizeReplacesTheShare() throws {
        // Kitchen K34.8, ruling A: serves 4, then 8, replaces the share (24 oz, never 36 oz); back to 4 adds nothing.
        let pasta = try engine.perform(CreateRecipe(text: Self.pasta), by: .user).output
        try engine.perform(AddRecipeToGroceries(recipe: pasta.id), by: .user)
        let bigger = try engine.perform(AddRecipeToGroceries(recipe: pasta.id, serves: 8), by: .user)
        #expect(!bigger.record.ops.isEmpty)
        let quantity = row("orecchiette")?.quantity
        #expect(quantity == "24 oz" || quantity == "1.5 lb" || quantity == "1½ lb", "\(quantity ?? "nil")")
        #expect(try engine.perform(AddRecipeToGroceries(recipe: pasta.id), by: .user).record.ops.isEmpty)
        #expect(row("orecchiette")?.quantity == quantity)
    }

    @Test func aPrivateRecipeIsNeverNamedInItsAddLine() throws {
        // QA: the short name is the title's last word, so a private recipe would leak part of it.
        let text = Self.pasta.replacingOccurrences(of: "Sausage, white bean and spinach pasta", with: "Lexapro pasta")
        let pasta = try engine.perform(CreateRecipe(text: text), by: .user).output
        let added = try engine.perform(AddRecipeToGroceries(recipe: pasta.id), by: .user)
        #expect(added.record.summary.hasPrefix("Private recipe, ") && added.record.summary.hasSuffix(" added."),
                "\(added.record.summary)")
        let again = try engine.perform(AddRecipeToGroceries(recipe: pasta.id), by: .user)
        #expect(again.record.summary == "Private recipe, nothing to add.")
        #expect(!added.record.summary.lowercased().contains("pasta"))
    }
}
