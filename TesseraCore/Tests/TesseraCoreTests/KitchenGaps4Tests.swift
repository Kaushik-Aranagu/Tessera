import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Kitchen gap hunt 4 (docs/product/kitchen-gap-hunt-4.md): G20 to G23.
@MainActor
struct KitchenGaps4Tests {
    let store = ObjectStore.open(inMemory: true)

    func engine() throws -> ActionEngine {
        try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    var context: TessContext {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return TessContext(now: Date(timeIntervalSince1970: 1_791_986_400), calendar: calendar)
    }

    // MARK: G21

    @Test func aPrivateRecipeReadsPrivateOnTheReceiptTheTaskAndHome() async throws {
        let engine = try engine()
        let tess = TessCaptureEngine(engine: engine)
        let secret = try engine.perform(CreateRecipe(text: "Wifi code lasagna\nIngredients\n2 onions\nMethod\nBake."),
                                        by: .user).output
        let health = try engine.perform(CreateRecipe(text: "Melatonin lasagna\nIngredients\n2 onions\nMethod\nBake."),
                                        by: .user).output
        let plain = try engine.perform(CreateRecipe(text: "Tacos\nIngredients\n2 onions\nMethod\nFry."),
                                       by: .user).output
        for recipe in [secret, health] {
            #expect(ObjectPrivacy.label(of: recipe, in: store, classes: engine.classes) == "Private recipe")
        }
        #expect(ObjectPrivacy.label(of: plain, in: store, classes: engine.classes) == nil)

        // Neither the capture line nor a stored title carries the name.
        for phrase in ["cook melatonin lasagna friday 7pm", "cook melatonin lasagna"] {
            let line = await tess.capture(phrase, context: context).line
            #expect(!line.lowercased().contains("lasagna"), "\(line)")
        }
        let titles = TaskList(store: store, classes: engine.classes).all().map(\.task.title)
        #expect(titles.allSatisfy { !$0.lowercased().contains("lasagna") }, "\(titles)")

        let open = await tess.capture("cook tacos friday 7pm", context: context)
        #expect(open.line == "Tacos, Friday 7 pm.", "\(open.line)")

        // Home: planned, running and done all say "Private recipe".
        let facts = HomeFacts(engine: engine)
        let task = try engine.perform(CreateTask(title: "x", startsAt: context.now, about: [health.id]), by: .tess).output
        #expect(facts.fact(plannedCook: task, recipe: health).title == "Private recipe")
        let cook = try engine.perform(StartCooking(recipe: health.id), by: .user).output
        try engine.perform(FinishCooking(cook: cook.id), by: .user)
        let done = try #require(facts.cooksFinished(on: .now).first)
        #expect(HomeLines.line(for: facts.fact(doneCook: done)).text == "Private recipe done.")
    }

    // MARK: G22

    @Test func aTimerOverTwentyFourHoursGivesTheLongTimerLine() async throws {
        let engine = try engine()
        let tess = TessCaptureEngine(engine: engine)
        let long = await tess.capture("timer rise 25 hours", context: context)
        #expect(long.line == "Didn't save that. A timer runs up to 24 hours.", "\(long.line)")
        let bare = await tess.capture("timer bread 1500", context: context)
        #expect(bare.line == "Didn't save that. A timer runs up to 24 hours.", "\(bare.line)")
        #expect(CookLog(store: store, classes: engine.classes).timers().isEmpty)
        let ok = await tess.capture("timer rise 24 hours", context: context)
        #expect(ok.line == "Rise, 1440 min." || ok.line.hasPrefix("Rise,"), "\(ok.line)")
    }

    // MARK: G23

    @Test func theMonthTurnsAtFourAm() throws {
        let engine = try engine()
        let log = CookLog(store: store, classes: engine.classes)
        let recipe = try engine.perform(CreateRecipe(text: "Overnight oats\nIngredients\n1 cup oats\nMethod\nSoak."),
                                        by: .user).output
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        func at(_ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
            calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
        }
        func cook(_ time: Date) throws {
            let started = try engine.perform(StartCooking(recipe: recipe.id, time: time), by: .user).output
            try engine.perform(FinishCooking(cook: started.id, time: time), by: .user)
        }
        try cook(at(10, 31, 21, 5))
        #expect(log.finishLine(for: recipe, at: at(10, 31, 21, 5), calendar: calendar)
            == "Overnight oats, first time this month.")
        // 1:30 am on Nov 1 is still his Oct 31: the second time this month.
        try cook(at(11, 1, 1, 30))
        #expect(log.finishLine(for: recipe, at: at(11, 1, 1, 30), calendar: calendar)
            == "Overnight oats, second time this month.")
        // 4:10 am on Nov 1 starts November.
        try cook(at(11, 1, 4, 10))
        #expect(log.finishLine(for: recipe, at: at(11, 1, 4, 10), calendar: calendar)
            == "Overnight oats, first time this month.")
    }

    // MARK: Groceries privacy (#688)

    @Test func aHealthLineOnGroceriesReadsPrivateInSummaryAndReceipt() throws {
        let store = store
        let one = AddGroceries(lines: ["advil"])
        #expect(one.summary(in: store) == "Private item, on Groceries")
        #expect(one.receipt(in: store) == "Private item, on Groceries")
        let two = AddGroceries(lines: ["milk", "advil"])
        #expect(two.receipt(in: store) == "Milk and Private item, on Groceries")
        let three = AddGroceries(lines: ["advil", "milk", "eggs"])
        #expect(three.receipt(in: store) == "Private item, milk and 1 more, on Groceries")
        let plain = AddGroceries(lines: ["milk"])
        #expect(plain.summary(in: store) == "Milk, on Groceries")
        #expect(plain.receipt(in: store) == "Milk, on Groceries")
    }
}
