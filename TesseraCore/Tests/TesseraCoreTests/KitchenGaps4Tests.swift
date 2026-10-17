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
        let task = try engine.perform(CreateTask(title: "x", startsAt: context.now, about: [health.id]), by: .tess)
            .output
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
        let allowed = await tess.capture("timer rise 24 hours", context: context)
        #expect(allowed.line.hasPrefix("Rise,"), "\(allowed.line)")
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

    @Test func aHealthLineOnGroceriesReadsPrivateInSummaryAndReceipt() {
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

    // MARK: Finish closes the plan task (MP-F1 to MP-F7)

    private func noon(plusDays days: Int) -> Date {
        let calendar = Calendar.current
        let base = calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: .now))!
        return calendar.date(byAdding: .hour, value: 12, to: base)!
    }

    private func isDone(_ task: ObjectRecord) -> Bool {
        store.value("isDone", of: task) == .bool(true)
    }

    @Test func finishingACookClosesItsPlanTaskAndUndoReopensBoth() throws {
        let engine = try engine()
        let tacos = try engine.perform(CreateRecipe(text: "Tacos\nIngredients\n2 onions\nMethod\nFry."), by: .user)
            .output
        let when = noon(plusDays: 0)
        let task = try engine.perform(CreateTask(title: "Cook tacos", startsAt: when.addingTimeInterval(7 * 3600),
                                                 about: [tacos.id]), by: .tess).output
        let other = try engine.perform(CreateTask(title: "Cook tacos", startsAt: when.addingTimeInterval(8 * 3600),
                                                  about: [tacos.id]), by: .tess).output
        // MP-F4: two tasks the same day, the earliest open one closes; the other stays open.
        let cook = try engine.perform(StartCooking(recipe: tacos.id, time: when), by: .user).output
        let finish = try engine.perform(FinishCooking(cook: cook.id, time: when.addingTimeInterval(3600)), by: .user)
        #expect(isDone(task) && !isDone(other))
        #expect(finish.record.receipt == "Tacos, done.")
        // MP-F2: one UNDO restores both.
        _ = engine.undo(finish.record)
        #expect(!isDone(other) && !isDone(task))
        #expect(store.value("cookedAt", of: cook) == nil)

        // Started elsewhere (no link): the earliest open one closes.
        let dal = try engine.perform(CreateRecipe(text: "Dal\nIngredients\n1 cup lentils\nMethod\nSimmer."), by: .user)
            .output
        let late = try engine.perform(CreateTask(title: "Cook dal", startsAt: when.addingTimeInterval(9 * 3600),
                                                 about: [dal.id]), by: .tess).output
        let early = try engine.perform(CreateTask(title: "Cook dal", startsAt: when.addingTimeInterval(5 * 3600),
                                                  about: [dal.id]), by: .tess).output
        let again = try engine.perform(StartCooking(recipe: dal.id, time: when), by: .user).output
        try engine.perform(FinishCooking(cook: again.id, time: when.addingTimeInterval(3600)), by: .user)
        #expect(isDone(early) && !isDone(late))
    }

    @Test func aPlanOnAnotherDayOrNoPlanOrADoneTaskIsLeftAlone() throws {
        let engine = try engine()
        let tacos = try engine.perform(CreateRecipe(text: "Tacos\nIngredients\n2 onions\nMethod\nFry."), by: .user)
            .output
        let tomorrow = try engine.perform(
            CreateTask(title: "Cook tacos", startsAt: noon(plusDays: 1), about: [tacos.id]),
            by: .tess
        ).output
        // MP-F7: a task already closed (skipped) is not touched again.
        let skipped = try engine.perform(CreateTask(title: "Cook tacos", startsAt: noon(plusDays: 0),
                                                    about: [tacos.id]), by: .tess).output
        try engine.perform(SetTaskDone(task: skipped.id, time: noon(plusDays: 0)), by: .user)
        let doneAt = store.value("doneAt", of: skipped)
        let cook = try engine.perform(StartCooking(recipe: tacos.id, time: noon(plusDays: 0)), by: .user).output
        try engine.perform(FinishCooking(cook: cook.id, time: noon(plusDays: 0).addingTimeInterval(60)), by: .user)
        #expect(!isDone(tomorrow))
        #expect(store.value("doneAt", of: skipped) == doneAt)
        // MP-F5: no plan task at all, the cook ends alone.
        let chili = try engine.perform(CreateRecipe(text: "Chili\nIngredients\n1 can beans\nMethod\nSimmer."),
                                       by: .user).output
        let chiliCook = try engine.perform(StartCooking(recipe: chili.id), by: .user).output
        let finish = try engine.perform(FinishCooking(cook: chiliCook.id), by: .user)
        #expect(finish.record.receipt == "Chili, done.")
    }

    @Test func aPrivateRecipeReceiptNeverNamesIt() throws {
        let engine = try engine()
        let secret = try engine.perform(CreateRecipe(text: "Melatonin lasagna\nIngredients\n2 onions\nMethod\nBake."),
                                        by: .user).output
        let task = try engine.perform(CreateTask(title: "Private recipe", startsAt: noon(plusDays: 0),
                                                 about: [secret.id]), by: .tess).output
        let cook = try engine.perform(StartCooking(recipe: secret.id, time: noon(plusDays: 0)), by: .user).output
        let finish = try engine.perform(FinishCooking(cook: cook.id, time: noon(plusDays: 0)), by: .user)
        #expect(isDone(task))
        #expect(finish.record.receipt == "Private recipe done.")
    }
}
