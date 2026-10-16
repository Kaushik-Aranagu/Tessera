import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// The kitchen lead's acceptance fixes, QA's K items and kitchen-phrases.md rows that failed before.
@MainActor
struct KitchenHotfixTests {
    let store = ObjectStore.open(inMemory: true)

    func grammar() throws -> (TessGrammar, TessContext, ActionEngine) {
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let wednesday = Date(timeIntervalSince1970: 1_791_986_400) // Wed 14 Oct 2026, 14:00 GMT
        for text in ["Spaghetti carbonara\nIngredients\n200 g spaghetti\nMethod\nBoil it.",
                     "Brunch eggs\nIngredients\n2 eggs\nMethod\nFry them."]
        {
            try engine.perform(CreateRecipe(text: text), by: .user)
        }
        return (TessGrammar(store: store, classes: classes), TessContext(now: wednesday, calendar: calendar), engine)
    }

    @Test func phrasesThatAreNotShopping() throws {
        let (grammar, context, _) = try grammar()
        func isGroceries(_ phrase: String) -> Bool {
            if case .groceries = grammar.parse(phrase, context: context) {
                true
            } else {
                false
            }
        }
        // Rows 9, 10, 50: a dated "buy/get" is a task.
        for phrase in ["buy present for mum fri", "get haircut thu 3pm", "buy milk tomorrow",
                       "get the car serviced friday"]
        {
            guard case let .task(title, startsAt)? = grammar.parse(phrase, context: context) else {
                Issue.record("\(phrase) should be a task")
                continue
            }
            #expect(startsAt != nil && !title.isEmpty)
        }
        // Rows 11, 12 and K1: lifts and errands aren't grocery lists.
        #expect(!isGroceries("call mum, dentist"))
        #expect(!isGroceries("bench 80x8, 82.5x6"))
        #expect(!isGroceries("bench 80, 8"))
        // Still shopping.
        #expect(isGroceries("milk, eggs, 2 lemons"))
        #expect(isGroceries("500 g mince, onions"))
        #expect(isGroceries("buy milk and eggs"))
        // K3: "run 7am" is not a cook of "Brunch eggs".
        if case .cook = grammar.parse("run 7am", context: context) {
            Issue.record("run 7am matched a recipe")
        }
        // K2: "bench 80, 8" is a set of 80 x 8.
        if case let .lift(_, _, reps, weight, _)? = grammar.parse("bench 80, 8", context: context) {
            #expect(weight == 80 && reps == 8)
        } else {
            Issue.record("bench 80, 8 should be a lift")
        }
        // K3: an oven timer reminder is a task.
        if case .task? = grammar.parse("remind me to reset the oven timer at 9 tomorrow", context: context) {} else {
            Issue.record("the oven timer reminder should be a task")
        }
        // Row 18: no such recipe, still something to do.
        if case let .task(title, _)? = grammar.parse("cook lasagne", context: context) {
            #expect(title == "Cook lasagne")
        } else {
            Issue.record("cook lasagne should be a task")
        }
        // Row 27: seconds.
        if case let .timer(label, minutes)? = grammar.parse("timer 90 seconds", context: context) {
            #expect(label == "Timer" && minutes == 1.5)
        } else {
            Issue.record("timer 90 seconds")
        }
    }

    @Test func cookingTheSameRecipeResumes() throws {
        let (_, _, engine) = try grammar()
        let recipe = try #require(RecipeBook(store: store, classes: engine.classes).recipes().first)
        let first = try engine.perform(StartCooking(recipe: recipe.id), by: .user).output
        let again = try engine.perform(StartCooking(recipe: recipe.id, serves: 3), by: .user).output
        #expect(first.id == again.id)
        #expect(CookLog(store: store, classes: engine.classes).serves(of: first) == 3)
        let time = Date(timeIntervalSince1970: 1_792_000_000)
        try engine.perform(GoToCookStep(cook: first.id, step: 0, time: time), by: .user)
        #expect(ProcessTable(engine: engine).running()?.object.updatedAt != nil)
    }

    @Test func parsingFixes() throws {
        // Acceptance 3: a sweet pepper isn't a staple.
        #expect(!AisleGuide.staples.contains("pepper") && AisleGuide.staples.contains("black pepper"))
        // Acceptance 4 and seed notes: size and "cooked" words are prep.
        let onion = try #require(IngredientLine.parse("1 large onion, diced"))
        #expect(onion.name == "onion" && onion.prep == "large, diced")
        #expect(IngredientLine.parse("300 g cooked rice")?.name == "rice")
        #expect(IngredientLine.parse("300 g cooked rice")?.prep == "cooked")
        // Seed notes: stick and head.
        #expect(IngredientLine.parse("2 sticks celery")?.unit == .stick)
        #expect(IngredientLine.parse("1 head broccoli")?.name == "broccoli")
        // K5: a step starting with "Cook" stays a step.
        let recipe = try #require(RecipeParser
            .parse("Pasta\nIngredients\n200 g pasta\nMethod\nCook the pasta for 10 minutes."))
        #expect(recipe.steps.map(\.timers) == [[10 ... 10]])
        #expect(RecipeParser.parse("Pasta\nCook time: 20 min\n200 g pasta")?.totalMinutes == nil)
        // K6: cloves.
        #expect(IngredientLine.key(for: "garlic cloves") == "garlic clove")
        #expect(IngredientLine.key(for: "olives") == "olive")
        // K7: a range ending in a unicode fraction.
        let rice = try #require(IngredientLine.parse("1–1½ cups rice"))
        #expect(rice.amount == 1 && rice.amountMax == 1.5 && rice.unit == .cup && rice.name == "rice")
        // Seed notes: 200C isn't a timer.
        #expect(RecipeParser.durations(in: "Roast at 200C for 12 minutes") == [12 ... 12])
    }

    @Test func planWeightsReadFromThePlanAndStartingWeightsAsFirstTime() throws {
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let ledger = TrainingLedger(store: store, classes: classes)
        let plan = try #require(store.object(id: StarterContent.planID))
        let pushA = try #require(store.linkedObjects("routines", of: plan).first)
        let workout = try engine.perform(StartRoutine(routine: pushA.id), by: .user).output
        let first = try #require(workout.orderedChildren.first)
        #expect(ledger.prefill(for: first).isFirstTime) // the empty bar, no history
        let bench = try #require(classes[.benchPress])
        let planned = try engine.perform(AddExercise(workout: workout.id, exercise: bench.id, targetSets: 3,
                                                     targetReps: 5, targetWeight: 60), by: .user).output
        #expect(!ledger.prefill(for: planned).isFirstTime) // a weight someone set: "From the plan"
    }
}

/// QA K6, K8, K9, K10, K12.
@MainActor
struct KitchenQATests {
    @Test func namesUnitsRestoreShopLineAndReset() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        // K6: titles as typed; cookies stay cookies.
        var transaction = Transaction(store: store, classes: classes)
        #expect(try transaction.ingredient(named: "garlic cloves").title == "Garlic cloves")
        #expect(IngredientLine.key(for: "cookies") == "cookie")
        #expect(IngredientLine.key(for: "bay leaves") == "bay leaf")
        // K8: T is a tablespoon, t a teaspoon.
        #expect(IngredientLine.parse("1 T butter")?.unit == .tablespoon)
        #expect(IngredientLine.parse("1 t salt")?.unit == .teaspoon)

        // K9: undoing a list delete doesn't bring back cleared items.
        let list = try engine.perform(CreateList(name: "Packing"), by: .user).output
        let socks = try engine.perform(AddListItem(list: list.id, text: "Socks"), by: .user).output
        _ = try engine.perform(AddListItem(list: list.id, text: "Charger"), by: .user)
        try engine.perform(CheckListItem(item: socks.id), by: .user)
        try engine.perform(ClearDoneItems(list: list.id), by: .user)
        let delete = try engine.perform(DeleteObject(object: list.id), by: .user)
        engine.undo(delete.record)
        #expect(ListContents(store: store, classes: classes).items(of: list).map(\.text) == ["Charger"])

        // K10: adding mid-shop keeps Now's line current.
        try engine.perform(AddGroceries(lines: ["milk", "bread"]), by: .user)
        try engine.perform(StartShop(), by: .user)
        try engine.perform(AddGroceries(lines: ["eggs"]), by: .user)
        #expect(ProcessTable(engine: engine).running()?.nextStep == "Shopping, 3 left")

        // K12: a reset puts the gym kit back.
        let equipmentBefore = try #require(classes[.equipment]).id
        store.resetUserData()
        let equipmentClass = try #require(store.allClasses().first { $0.id == equipmentBefore })
        #expect(!store.objects(of: equipmentClass).isEmpty)
    }
}

/// docs/qa/grammar-trace.md: non-kitchen phrases the kitchen rules used to take over, and T1–T6.
@MainActor
struct GrammarTraceTests {
    @Test func nonKitchenPhrasesStayOutOfTheKitchen() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        for text in ["Tomato and basil pasta\nIngredients\n200 g pasta\nMethod\nBoil it.",
                     "Protein pancakes\nIngredients\n2 eggs\nMethod\nFry them."]
        {
            try engine.perform(CreateRecipe(text: text), by: .user)
        }
        let grammar = TessGrammar(store: store, classes: classes)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let thursdayEvening = Date(timeIntervalSince1970: 1_792_094_400) // Thu 15 Oct 2026, 20:00 GMT
        let context = TessContext(now: thursdayEvening, calendar: calendar)
        func kind(_ phrase: String) -> String {
            switch grammar.parse(phrase, context: context) {
            case .groceries: "groceries"
            case .cook: "cook"
            case .timer: "timer"
            case .list: "list"
            case .task: "task"
            case .lift, .set, .sets: "lift"
            case .note: "note"
            case .shop: "shop"
            case .reschedule: "reschedule"
            case .cookStep: "cook"
            case .ignoredInWorkout, .ask, .askSetCount, .askDatedLift: "nothing"
            case .recipe: "recipe"
            case nil: "nothing"
            }
        }
        // Each row's intended reading, not just "not kitchen" (H5).
        let expected: [(String, Set<String>)] = [
            ("Squat 100, 5", ["lift"]), ("bench 80, 8", ["lift"]), ("bench 80x8, 82.5x6", ["lift"]),
            ("get 5x5 squats done", ["nothing", "task"]), ("get the car serviced friday", ["task"]),
            ("get up at 6am", ["task"]), ("get bloods done and pick up prescription thu", ["task"]),
            ("todo call mum, book dentist", ["task"]), ("email Sam, Priya and Jo", ["nothing", "task"]),
            ("knee a bit sore, skip lunges", ["nothing", "note"]), ("boiler timer reset at 6", ["task"]),
            ("tom 6pm", ["task"]), ("make a cake sat", ["task"]), ("list the car on ebay sat", ["task"]),
        ]
        for (phrase, allowed) in expected {
            #expect(allowed.contains(kind(phrase)), "\(phrase) → \(kind(phrase))")
        }
        if case let .sets(parts)? = grammar.parse("bench 80x8, 82.5x6", context: context) {
            #expect(parts.count == 2)
            if case let .lift(_, _, reps, weight, _) = parts[1] {
                #expect(weight == 82.5 && reps == 6)
            }
        } else {
            Issue.record("bench 80x8, 82.5x6 should be two sets")
        }
        // T2: rest and plank timers in seconds.
        if case let .timer(_, minutes)? = grammar.parse("rest timer 90", context: context) {
            #expect(minutes == 1.5)
        } else {
            Issue.record("rest timer 90")
        }
        if case let .timer(label, minutes)? = grammar.parse("plank timer 60 sec", context: context) {
            #expect(label == "Plank" && minutes == 1)
        } else {
            Issue.record("plank timer 60 sec")
        }
        // T3: "thu" on a Thursday evening is next Thursday.
        if case let .task(_, startsAt?)? = grammar.parse("call mum thu", context: context) {
            #expect(startsAt > thursdayEvening)
            #expect(calendar.component(.weekday, from: startsAt) == 5)
        } else {
            Issue.record("call mum thu")
        }
        // Still right.
        #expect(kind("call mum friday") == "task")
        #expect(kind("list: packing") == "list" && kind("new list films") == "list")
        #expect(kind("cook tomato and basil pasta") == "cook")
    }
}

/// The kitchen lead's two misses on #70.
@MainActor
struct KitchenAcceptanceFollowUpTests {
    @Test func trailingUnitsAndMixedLists() throws {
        let cloves = try #require(IngredientLine.parse("2 garlic cloves"))
        #expect(cloves.name == "garlic" && cloves.unit == .clove && cloves.amount == 2)
        #expect(AisleGuide.aisle(for: "toothpaste") == .household)
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let grammar = TessGrammar(store: store, classes: classes)
        let context = TessContext(now: .now, calendar: .current)
        if case let .groceries(lines)? = grammar.parse("milk, toothpaste", context: context) {
            #expect(lines == ["milk", "toothpaste"])
        } else {
            Issue.record("milk, toothpaste should be groceries")
        }
        if case .groceries? = grammar.parse("milk, sriracha", context: context) {} else {
            Issue.record("half shopping is enough")
        }
        if case .groceries? = grammar.parse("call mum, dentist", context: context) {
            Issue.record("call mum, dentist isn't shopping")
        }
    }
}

/// QA review of #70 (H1–H5) and the Notes findings N3–N4.
@MainActor
struct Hotfix70Tests {
    @Test func unknownThingsStillGoOnTheList() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        try engine.perform(
            CreateRecipe(text: "Chicken and broccoli stir-fry\nIngredients\n1 head broccoli\nMethod\nFry."),
            by: .user
        )
        try engine.perform(CreateRecipe(text: "Protein pancakes\nIngredients\n2 eggs\nMethod\nFry."), by: .user)
        let grammar = TessGrammar(store: store, classes: classes)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let context = TessContext(now: Date(timeIntervalSince1970: 1_791_986_400), calendar: calendar)
        func groceries(_ phrase: String) -> [String]? {
            if case let .groceries(lines)? = grammar.parse(phrase, context: context) {
                lines
            } else {
                nil
            }
        }
        // H1
        #expect(groceries("milk, coffee, tea") == ["milk", "coffee", "tea"])
        #expect(groceries("eggs, bread, toothpaste")?.count == 3)
        #expect(groceries("get coffee") == ["coffee"])
        #expect(groceries("call mum, dentist") == nil)
        // H2
        #expect(groceries("buy sun cream") == ["sun cream"])
        if case .task? = grammar.parse("buy flowers sun", context: context) {} else {
            Issue.record("buy flowers sun is a Sunday task")
        }
        // H3
        if case let .cook(recipe, _)? = grammar.parse("cook stir-fry", context: context) {
            #expect(recipe.title.hasSuffix("stir-fry"))
        } else {
            Issue.record("cook stir-fry")
        }
        if case let .cook(recipe, _)? = grammar.parse("cook pancake", context: context) {
            #expect(recipe.title == "Protein pancakes")
        } else {
            Issue.record("cook pancake")
        }
        // H4
        if case let .timer(_, minutes)? = grammar.parse("dough rest timer 60", context: context) {
            #expect(minutes == 60)
        } else {
            Issue.record("dough rest timer 60")
        }
        // Fix 6 for real: the step's time is the one given.
        let pancakes = try #require(RecipeBook(store: store, classes: classes).recipes().last)
        let cook = try engine.perform(StartCooking(recipe: pancakes.id), by: .user).output
        let time = Date(timeIntervalSince1970: 1_792_000_000)
        try engine.perform(GoToCookStep(cook: cook.id, step: 0, time: time), by: .user)
        #expect(ProcessTable(engine: engine).running()?.lastTouchedAt == time)
    }

    @Test func mentionsWithAmpersandsAndClassObjectsInTheLog() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let mac = try engine.perform(CreateRecipe(text: "Mac & Cheese\nIngredients\n200 g macaroni\nMethod\nBake."),
                                     by: .user).output
        let note = try engine.perform(CreateNote(body: "@Mac & Cheese was great"), by: .user).output
        #expect(store.linkedObjects("about", of: note).map(\.id) == [mac.id]) // N3
        // N4: the class object a mention needs is made in the note's transaction, so undo removes it.
        let workout = try #require(classes[.workout])
        #expect(store.classObject(of: workout) == nil)
        let result = try engine.perform(CreateNote(body: "@Workout felt long"), by: .user)
        #expect(store.classObject(of: workout) != nil)
        engine.undo(result.record)
        #expect(store.classObject(of: workout).map(\.isDeleted) ?? true)
    }
}
