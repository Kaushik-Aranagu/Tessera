import Foundation
@testable import TesseraCore
import Testing

/// What the sink knows (Design sheet 388).
@MainActor
struct SinkTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    /// Thursday, Oct 22, 2026, 18:00 UTC.
    let now = Date(timeIntervalSince1970: 1_792_692_000)

    init() throws {
        classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
        engine.now = { Date(timeIntervalSince1970: 1_792_692_000) }
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        engine.zone = { utc.timeZone }
    }

    func at(_ hour: Int, _ minute: Int = 0, daysAgo: Int = 0) -> Date {
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: now))!
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)!
    }

    var facts: Sink.Facts {
        Sink.facts(store: store, now: now)
    }

    func recipe(_ cookware: Double? = nil, text: String = RecipeParserTests.carbonara) throws -> ObjectRecord {
        let recipe = try engine.perform(CreateRecipe(text: text), by: .user).output
        if let cookware {
            try store.set("cookware", to: .number(cookware), on: recipe)
        }
        return recipe
    }

    @Test func minutesAreAMinuteAndAHalfADishRoundedToFiveAndAtLeastFive() {
        #expect([1, 2, 3, 7, 10, 20].map(Sink.minutes(forDishes:)) == [5, 5, 5, 10, 15, 30])
    }

    @Test func theSampleIsOneOpenLoadOfSevenLabeledLunchAtTwelveForty() throws {
        let load = try #require(try Sink.seedSample(store: store, classes: classes, now: now, calendar: calendar))
        #expect(store.number("count", of: load) == 7 && store.value("at", of: load)?.dateValue == at(12, 40))
        #expect(facts == Sink.Facts(waiting: 7, since: at(12, 40), minutes: 10, lastWashed: nil))
        #expect(Sink.ticket(facts, now: now, calendar: calendar) == ["Dishes", "7 waiting", "since lunch"])
        let card = try #require(Sink.card(facts, now: now, calendar: calendar))
        #expect(card.header == "Since lunch" && card.number == 7 && card.unit == "dishes")
        #expect(card.line == "Waiting in the sink" && card.about == "About 10 minutes")
        #expect(Sink.washObject(facts) == "7 dishes")
        #expect(try Sink.seedSample(store: store, classes: classes, now: now, calendar: calendar) == nil, "once")
    }

    @Test func theSinceWordIsMealYesterdayWeekdayOrDate() {
        #expect(Sink.when(at(9), now: now, calendar: calendar) == "breakfast")
        #expect(Sink.when(at(11), now: now, calendar: calendar) == "lunch")
        #expect(Sink.when(at(15, 59), now: now, calendar: calendar) == "lunch")
        #expect(Sink.when(at(16), now: now, calendar: calendar) == "dinner")
        #expect(Sink.when(at(20, daysAgo: 1), now: now, calendar: calendar) == "yesterday")
        #expect(Sink.when(at(20, daysAgo: 3), now: now, calendar: calendar) == "Monday")
        #expect(Sink.when(at(20, daysAgo: 8), now: now, calendar: calendar) == "October 14")
    }

    @Test func aClearSinkHasNoTicketNoCardAndASaysItIsClear() {
        #expect(facts.waiting == 0 && Sink.ticket(facts, now: now) == nil && Sink.card(facts, now: now) == nil)
        #expect(Sink.washObject(facts) == "the sink is clear")
    }

    @Test func finishingACookAddsOneLoadOfPlatesPansAndABoardAndUndoTakesItBack() throws {
        let recipe = try recipe()
        let cook = try engine.perform(StartCooking(recipe: recipe.id, serves: 2, time: at(17)), by: .user).output
        let done = try engine.perform(FinishCooking(cook: cook.id, time: at(18)), by: .user)
        #expect(facts.waiting == 4, "tacos for 2, alone: 2 plates, 1 pan, 1 board")
        let load = try #require(Sink.openLoads(in: store).first)
        #expect(load.title == recipe.title && store.value("at", of: load)?.dateValue == at(18))
        #expect(store.linkedObjects("source", of: load).first?.id == cook.id)
        engine.undo(done.record)
        #expect(facts.waiting == 0, "undoing the finish takes the load with it")
    }

    @Test func aRecipesOwnCookwareCountsAndUnknownServesAddNoPlates() throws {
        let heavy = try recipe(3)
        let cook = try engine.perform(StartCooking(recipe: heavy.id, serves: 4, time: at(17)), by: .user).output
        try engine.perform(FinishCooking(cook: cook.id, time: at(18)), by: .user)
        #expect(facts.waiting == 4 + 3 + 1)
        // No serves anywhere: no plates are guessed, only the pan and the board.
        let bare = try engine.perform(CreateRecipe(text: "Toast\n\n1. Toast the bread."), by: .user).output
        let second = try engine.perform(StartCooking(recipe: bare.id, time: at(19)), by: .user).output
        try engine.perform(FinishCooking(cook: second.id, time: at(19, 30)), by: .user)
        #expect(facts.waiting == 8 + 2)
    }

    @Test func aSessionAddsOneLoadWithTheLargestServesAPanEachAndOneBoard() throws {
        let one = try recipe(), two = try recipe(2, text: "Toast\n\n1. Toast the bread.")
        try store.set("serves", to: .number(2), on: one)
        try store.set("serves", to: .number(6), on: two)
        let session = try engine.perform(StartCookSession(recipes: [one.id, two.id], serveAt: at(19), time: at(17)),
                                         by: .user).output
        let done = try engine.perform(FinishCookSession(session: session.id, time: at(19)), by: .user)
        #expect(Sink.openLoads(in: store).count == 1, "one load, not one per dish")
        #expect(facts.waiting == 6 + (1 + 2) + 1)
        #expect(Sink.openLoads(in: store).first?.title == one.title, "the first dish's name")
        engine.undo(done.record)
        #expect(facts.waiting == 0)
    }

    @Test func dishesAddedByHandNeedNoGuessing() throws {
        try engine.perform(AddDishes(count: 3, label: "Lunch", at: at(13)), by: .tess)
        #expect(facts.waiting == 3 && facts.since == at(13))
        #expect(throws: ActionError.self) { try engine.perform(AddDishes(count: 0), by: .user) }
        try engine.perform(AddDishes(count: 2), by: .user)
        #expect(facts.waiting == 5)
    }

    @Test func washWritesOneGroupOnEveryOpenLoadAndUndoOpensThemAgainWithTheSameSince() throws {
        try engine.perform(AddDishes(count: 7, label: "Lunch", at: at(12, 40)), by: .user)
        try engine.perform(AddDishes(count: 3, label: "Snack", at: at(15)), by: .user)
        let before = facts
        let wash = try engine.perform(WashDishes(at: at(17)), by: .user)
        #expect(wash.output == 2 && wash.record.receipt == "Dishes, done")
        #expect(WashDishes().receipt(in: store, output: 2) == "Dishes, done")
        #expect(facts.waiting == 0 && facts.lastWashed == at(17))
        engine.undo(wash.record)
        #expect(facts == Sink.Facts(waiting: 10, since: before.since, minutes: 15, lastWashed: nil))
        // New dishes after a wash start a new count with a new since.
        try engine.perform(WashDishes(at: at(17)), by: .user)
        try engine.perform(AddDishes(count: 2, label: "Dinner", at: at(18)), by: .user)
        #expect(facts.waiting == 2 && facts.since == at(18))
    }

    @Test func washingAClearSinkWritesNothingAndNothingResetsOnItsOwn() throws {
        let ops = engine.history(from: .distantPast, to: .distantFuture).count
        let result = try engine.perform(WashDishes(), by: .user)
        #expect(result.output == 0 && WashDishes().receipt(in: store, output: 0) == "The sink is clear")
        #expect(engine.history(from: .distantPast, to: .distantFuture).count == ops, "no op group")
        try engine.perform(AddDishes(count: 4, at: at(12)), by: .user)
        // Days pass: the load is still open.
        #expect(Sink.facts(store: store, now: now.addingTimeInterval(5 * 86400)).waiting == 4)
    }

    @Test func aPrivateRecipeNeverLendsItsNameToTheLabel() throws {
        let secret = try engine.perform(CreateRecipe(text: "Lexapro cake\n\n1. Bake it."), by: .user).output
        let cook = try engine.perform(StartCooking(recipe: secret.id, serves: 2, time: at(17)), by: .user).output
        try engine.perform(FinishCooking(cook: cook.id, time: at(18)), by: .user)
        let load = try #require(Sink.openLoads(in: store).first)
        #expect(!load.title.contains("Lexapro") && store.value("label", of: load)?.stringValue?
            .contains("Lexapro") != true)
    }
}
