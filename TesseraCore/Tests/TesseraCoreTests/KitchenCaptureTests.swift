import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

@MainActor
struct KitchenCaptureTests {
    @Test func aMedicineOnGroceriesIsNeverSaidBack() async throws {
        // Product 8:13 and 10:06 PM PT: a medicine on the list is a health fact.
        let store = ObjectStore.open(inMemory: true)
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        let advil = await TessCaptureEngine(engine: engine).capture("buy advil", context: TessContext())
        #expect(!advil.line.lowercased().contains("advil"), "\(advil.line)")
    }

    @Test func cookingFromTheBarWhileAWorkoutRunsSaysSo() async throws {
        // QA on #788 (G56): the Bar's refusal is "Workout running.", not a generic failure, and nothing is written.
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let tess = TessCaptureEngine(engine: engine)
        _ = try engine.perform(CreateRecipe(text: RecipeParserTests.carbonara), by: .user)
        let workout = try store.create(#require(classes[.workout]), title: "Push day")
        try engine.perform(StartWorkout(workout: workout.id), by: .user)
        let ops = engine.history(from: .distantPast, to: .distantFuture).count
        let cooking = await tess.capture("cook carbonara", context: TessContext())
        #expect(cooking.line == "Workout running." && cooking.records.isEmpty, "\(cooking.line)")
        #expect(engine.history(from: .distantPast, to: .distantFuture).count == ops)
        #expect(ProcessTable(engine: engine).running()?.subject?.id == workout.id)
    }

    @Test func kitchenPhrasesFromTheBar() async throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let tess = TessCaptureEngine(engine: engine)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let wednesday = Date(timeIntervalSince1970: 1_791_986_400) // Wed 14 Oct 2026, 14:00 GMT
        let context = TessContext(now: wednesday, calendar: calendar)
        let groceries = Groceries(store: store, classes: classes)

        // Pasted text with an Ingredients heading becomes a recipe ghost.
        let pasted = await tess.capture(RecipeParserTests.carbonara, context: context)
        #expect(pasted.line == "5 ingredients, 4 steps, 2 timers.")
        let recipe = try #require(RecipeBook(store: store, classes: classes).recipes().first)

        let milk = await tess.capture("buy milk", context: context)
        #expect(milk.line == "Milk, on Groceries.")
        let list = await tess.capture("eggs, bread and 2 lemons", context: context)
        #expect(list.line == "3 things on Groceries.")
        #expect(groceries.shoppingOrder().map(\.text) == ["lemons", "bread", "milk", "eggs"])

        let planned = await tess.capture("cook carbonara thu", context: context)
        #expect(planned.line == "Spaghetti carbonara, tomorrow 9 am.")
        let task = try #require(TaskList(store: store, classes: classes).all().first)
        #expect(store.linkedObjects("about", of: task.task).map(\.id) == [recipe.id])
        let bare = await tess.capture("carbonara friday 7pm", context: context)
        #expect(bare.line == "Spaghetti carbonara, Friday 7 pm.")

        let cooking = await tess.capture("cook carbonara", context: context)
        #expect(cooking.line == "Cooking spaghetti carbonara.")
        let timer = await tess.capture("timer pasta 10", context: context)
        #expect(timer.line == "Pasta, 10 min.")
        let other = await tess.capture("5 min timer", context: context)
        #expect(other.line == "Timer, 5 min.")
        let timers = CookLog(store: store, classes: classes).timers()
        #expect(timers.map(\.label) == ["Timer", "Pasta"])
        #expect(timers.allSatisfy { $0.cook != nil }) // they belong to the cook in progress

        let packing = await tess.capture("list: packing", context: context)
        #expect(packing.line == "Packing, new list.")

        // Ordinary phrases still go where they did.
        let call = await tess.capture("call mum thu", context: context)
        #expect(call.line == "Call mum, tomorrow 9 am.")

        let all = [pasted, milk, list, planned, bare, cooking, timer, other, packing, call]
        #expect(all.allSatisfy { $0.records.count == 1 && $0.source == .grammar })
        for line in all.map(\.line) {
            #expect(TessVoice.violations(in: line).isEmpty)
        }
    }
}
