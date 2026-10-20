import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// Kitchen v2 (huddle batches 6 and 10): need against have, the CAN COOK ranking and the week's shop diff.
@MainActor
struct KitchenV2Tests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel
    let saturday = Date(timeIntervalSince1970: 1_792_000_000)

    init() {
        model = AppModel(context: container.mainContext)
    }

    private var ledger: PantryLedger {
        PantryLedger(store: model.store, classes: model.classes)
    }

    private var book: RecipeBook {
        RecipeBook(store: model.store, classes: model.classes)
    }

    private func tacos() throws -> ObjectRecord {
        try model.engine.perform(CreateRecipe(text: """
        Tacos
        1 lb ground beef
        2 limes
        8 corn tortillas
        salt

        Brown the beef.
        Warm the tortillas.
        """), by: .user).output
    }

    private func shop(_ recipe: ObjectRecord, at date: Date) throws {
        try model.engine.perform(AddRecipeToGroceries(recipe: recipe.id), by: .user)
        for item in model.store.object(id: Groceries.listID)?.orderedChildren ?? [] {
            try model.engine.perform(CheckListItem(item: item.id, time: date), by: .user)
        }
        try model.engine.perform(ClearDoneItems(list: Groceries.listID), by: .user)
    }

    private func cook(_ recipe: ObjectRecord, at date: Date) throws {
        let cook = try model.engine.perform(StartCooking(recipe: recipe.id, time: date), by: .user).output
        try model.engine.perform(FinishCooking(cook: cook.id, time: date.addingTimeInterval(1800)), by: .user)
    }

    private func needHave(_ recipe: ObjectRecord) -> NeedHave {
        NeedHave(lines: NeedHave.lines(book.lines(of: recipe), states: ledger.states(), store: model.store))
    }

    // MARK: Need against have

    @Test func needAgainstHaveSkipsStaplesAndCountsLowAsHad() throws {
        let recipe = try tacos()
        // Nothing known yet: no line at all, never "Have 0 of 3.".
        #expect(needHave(recipe).need == 3)
        #expect(needHave(recipe).line == nil)

        try shop(recipe, at: saturday)
        #expect(needHave(recipe).line == "Have 3 of 3.")

        try cook(recipe, at: saturday.addingTimeInterval(86400))
        let after = needHave(recipe)
        // Limes are Produce, so out; beef and tortillas low, still had.
        #expect(after.line == "Have 2 of 3.")
        #expect(after.short == 1)
        let words = zip(book.lines(of: recipe), after.lines).map { "\($0.line.name): \(NeedHave.word(for: $1) ?? "-")" }
        #expect(words == ["ground beef: Low", "limes: Out", "corn tortillas: Low", "salt: -"])
    }

    @Test func needHaveWordsAndLine() {
        let id = UUID()
        let lines = [
            NeedHave.Line(ingredient: id, counts: true, state: .have),
            NeedHave.Line(ingredient: id, counts: true, state: .unknown),
            NeedHave.Line(ingredient: id, counts: false, state: .out),
        ]
        let needHave = NeedHave(lines: lines)
        #expect(needHave.need == 2)
        #expect(needHave.have == 1)
        #expect(needHave.known == 1)
        #expect(needHave.line == "Have 1 of 2.")
        #expect(lines.map(NeedHave.word(for:)) == ["In", nil, nil])
        #expect(PantryLedger.State.allCases.map(\.shownWord) == ["Out", "Low", "In", nil])
    }

    // MARK: Can cook

    private func candidate(_ name: String, need: Int = 5, have: Int, known: Int = 5, cooked: Date? = nil,
                           order: Int = 0, isPrivate: Bool = false) -> CanCook.Candidate
    {
        CanCook.Candidate(id: UUID(), name: name, isPrivate: isPrivate, need: need, have: have, known: known,
                          lastCooked: cooked, order: order)
    }

    @Test func canCookRanksByWhatIsMissingThenNotCookedLately() {
        let shelf = CanCook([
            candidate("Chili", have: 3, cooked: saturday, order: 0),
            candidate("Tacos", have: 5, cooked: saturday, order: 1),
            candidate("Dal", have: 4, cooked: saturday, order: 2),
            candidate("Curry", have: 4, cooked: saturday.addingTimeInterval(-7 * 86400), order: 3),
            candidate("Soup", have: 4, cooked: nil, order: 4),
            candidate("Stew", have: 2, order: 5),
        ])
        // Ready, then 1 short (never cooked, then cooked longest ago), then 2 short; 3 short never shows.
        #expect(shelf.judged.map(\.name) == ["Tacos", "Soup", "Curry", "Dal", "Chili"])
        #expect(shelf.judged.map(\.word) == ["Ready", "1 short", "1 short", "1 short", "2 short"])
        #expect(shelf.toCheck.isEmpty)
    }

    @Test func canCookJudgesOnlyAtSixtyPercentAndThreeLines() {
        #expect(CanCook.isJudged(need: 5, known: 3))
        #expect(!CanCook.isJudged(need: 6, known: 3))
        #expect(!CanCook.isJudged(need: 2, known: 2), "fewer than 3 known is never judged")
        let shelf = CanCook([
            candidate("Pho", need: 8, have: 4, known: 4, order: 1),
            candidate("Ramen", need: 8, have: 0, known: 0, order: 0),
            candidate("Toast", need: 0, have: 0, known: 0, order: 2),
        ])
        #expect(shelf.judged.isEmpty)
        // Below the bar with something known: "to check"; nothing known (or nothing to buy): not listed.
        #expect(shelf.toCheck.map(\.name) == ["Pho"])
        #expect(CanCook.toCheckHeading(2) == "2 to check")
    }

    @Test func aPrivateRecipeNeverRanksByName() {
        let shelf = CanCook([
            candidate(ObjectPrivacy.recipeLabel, have: 5, order: 1, isPrivate: true),
            candidate("Apple pie", have: 5, order: 2),
            candidate("Zucchini bake", have: 5, order: 0),
        ])
        #expect(shelf.judged.map(\.name) == ["Zucchini bake", ObjectPrivacy.recipeLabel, "Apple pie"])
    }

    @Test func canCookReadsThePantry() throws {
        let recipe = try tacos()
        try shop(recipe, at: saturday)
        let shelf = CanCook(store: model.store, classes: model.classes, states: ledger.states())
        #expect(shelf.judged.map(\.name) == ["Tacos"])
        #expect(shelf.judged.first?.word == "Ready")
        try cook(recipe, at: saturday.addingTimeInterval(86400))
        let after = CanCook(store: model.store, classes: model.classes, states: ledger.states())
        #expect(after.judged.first?.word == "1 short")
    }

    // MARK: Meal plan to groceries

    private func need(_ text: String, aisle: String = "Produce", counts: Bool = true,
                      state: PantryLedger.State = .unknown, onList: Bool = false) -> DinnerShop.Need
    {
        DinnerShop.Need(ingredient: UUID(), text: text, aisle: aisle, counts: counts, state: state, onList: onList)
    }

    @Test func mealPlanDiffSkipsStaplesListedAndWithPantryStateInLines() {
        let needs = [
            need("1 lb ground beef", aisle: "Meat", state: .have),
            need("2 limes", state: .low),
            need("8 corn tortillas", aisle: "Bakery", state: .out),
            need("salt", aisle: "Pantry", counts: false),
            need("1 onion", onList: true),
        ]
        // Pantry state off: everything to buy that isn't already on Groceries; the whole recipe goes on.
        #expect(DinnerShop.missing(needs, skipIn: false).map(\.text) == ["1 lb ground beef", "2 limes",
                                                                         "8 corn tortillas"])
        #expect(DinnerShop.add(needs, skipIn: false, isPrivate: false) == .recipe)
        // On: In lines are skipped; Low and Out are bought again, as their own lines.
        #expect(DinnerShop.add(needs, skipIn: true, isPrivate: false) == .lines(["2 limes", "8 corn tortillas"]))
        // A private recipe always goes on whole, so no row lends a name.
        #expect(DinnerShop.add(needs, skipIn: true, isPrivate: true) == .recipe)
        #expect(DinnerShop.add([need("1 onion", onList: true)], skipIn: false, isPrivate: false) == .nothing)
        let aisles = DinnerShop.byAisle(DinnerShop.missing(needs, skipIn: false))
        #expect(Set(aisles.map(\.aisle)) == ["Produce", "Meat", "Bakery"])
        #expect(aisles.allSatisfy { $0.count == 1 })
        #expect(DinnerShop.receipt("Week", added: 5) == "Week, 5 added.")
        #expect(DinnerShop.receipt("Week", added: 0) == "Week, nothing to add.")
    }

    @Test func aPlannedDinnerReachesGroceriesOnlyOnTheTap() throws {
        let recipe = try tacos()
        let house = TesseraDay()
        let thursday = WeekOfDinners.dinnerTime(on: house.day(3, after: house.week(containing: saturday).start))
        try model.engine.perform(CreateTask(title: "Cook tacos", startsAt: thursday, about: [recipe.id]), by: .user)
        let week = WeekOfDinners(store: model.store, classes: model.classes, now: saturday)
        #expect(week.days.map(\.word) == ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"])
        #expect(week.days[3].plan?.name == "Tacos")
        #expect(week.days.compactMap(\.plan).count == 1)
        // Planning wrote no grocery row.
        #expect(Groceries(store: model.store, classes: model.classes).list?.orderedChildren.isEmpty ?? true)
        let needs = DinnerShop.needs(of: recipe, store: model.store, classes: model.classes, states: ledger.states())
        #expect(DinnerShop.missing(needs, skipIn: false).count == 3)
        // Once the recipe is on the list, nothing is missing.
        try model.engine.perform(AddRecipeToGroceries(recipe: recipe.id), by: .user)
        let after = DinnerShop.needs(of: recipe, store: model.store, classes: model.classes, states: ledger.states())
        #expect(DinnerShop.missing(after, skipIn: false).isEmpty)
    }

    // MARK: Usually

    @Test func usuallyIsDueFromPointEightFiveToTwoRhythms() {
        let calendar = Calendar.current
        let day = { (offset: Int) in calendar.date(byAdding: .day, value: offset, to: saturday) ?? saturday }
        let buys = [day(0), day(7), day(14)]
        #expect(!UsuallyDue.isDue(buys: buys, now: day(19)), "5 of 7 days is before 0.85 rhythms")
        #expect(UsuallyDue.isDue(buys: buys, now: day(20)))
        #expect(UsuallyDue.isDue(buys: buys, now: day(28)))
        #expect(!UsuallyDue.isDue(buys: buys, now: day(29)), "past 2 rhythms it is quiet")
        #expect(!UsuallyDue.isDue(buys: [day(0), day(7)], now: day(14)), "two buys is no rhythm")
        // Buys older than 56 days don't count toward the 3.
        #expect(!UsuallyDue.isDue(buys: [day(-60), day(30), day(40)], now: day(48)))
    }

    // MARK: Fix a recipe

    @Test func aFixReceiptNamesTheThingFirstAndMasksAPrivateRecipe() {
        #expect(RecipeCopy.fixed("Sheet-pan chicken with lemon", isPrivate: false) == "Sheet-pan chicken, fixed.")
        #expect(RecipeCopy.fixed("Lexapro stew", isPrivate: true) == "Private recipe, fixed.")
    }

    @Test func aFixRenamesInPlaceWithOneUndo() throws {
        let recipe = try tacos()
        let record = try model.engine.perform(EditRecipe(recipe: recipe.id, title: "Fish tacos"), by: .user).record
        #expect(recipe.title == "Fish tacos")
        #expect(book.lines(of: recipe).count == 4, "the lines stay as they were")
        model.engine.undo(record)
        #expect(recipe.title == "Tacos")
    }

    @Test func switchesReadOffUntilTheirRowsAreLive() {
        // Rows not yet in ReviewChoices, or not live, read nil or the default: every Kitchen v2 surface stays hidden.
        #expect(!KitchenSwitch.weekStrip)
        #expect(!KitchenSwitch.isOn("noSuchRow"))
    }
}
