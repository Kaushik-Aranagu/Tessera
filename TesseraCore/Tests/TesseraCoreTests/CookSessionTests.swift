import Foundation
@testable import TesseraCore
import Testing

/// Multi-dish Cook, Part A PR 2: the session's objects and actions.
@MainActor
struct CookSessionTests {
    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine
    let book: CookSessionBook
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        book = CookSessionBook(store: store, classes: engine.classes)
    }

    func at(_ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 22, hour: hour, minute: minute))!
    }

    func recipe(_ title: String, steps: [String]) throws -> ObjectRecord {
        let numbered = steps.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
        return try engine.perform(CreateRecipe(text: "\(title)\nIngredients\n1 onion\nMethod\n\(numbered)"), by: .user)
            .output
    }

    func chicken() throws -> ObjectRecord {
        try recipe(
            "Paprika chicken",
            steps: ["Season the chicken.", "Sear it for 4 minutes.", "Bake for 33 minutes.", "Plate it."]
        )
    }

    func pasta() throws -> ObjectRecord {
        try recipe("Spaghetti", steps: ["Boil the water.", "Cook the spaghetti for 10 minutes.", "Drain and toss."])
    }

    func plan(_ recipes: [ObjectRecord], serveAt: Date? = nil, now: Date? = nil) throws -> ObjectRecord {
        try engine.perform(
            StartCookSession(recipes: recipes.map(\.id), serveAt: serveAt, time: now ?? at(17)),
            by: .user
        ).output
    }

    func rows(_ key: SystemCatalog.Key) -> [ObjectRecord] {
        engine.classes[key].map { store.objects(of: $0).filter { !$0.isDeleted } } ?? []
    }

    // MARK: Timeline

    @Test func aStepIsItsTimerTwoMinutesWithNoneAndALongTimerIsAShortWait() {
        #expect(CookTimeline.shape(of: []) == (2, false))
        #expect(CookTimeline.shape(of: [4 ... 4]) == (4, false)) // under five minutes: hands
        #expect(CookTimeline.shape(of: [30 ... 40]) == (40, true)) // the top of a range, a wait
        #expect(CookTimeline.shape(of: [5 ... 5]) == (5, true))
        #expect(CookTimeline.shape(of: [8 * 60 ... 8 * 60]) == (10, true)) // over three hours: a fixed ten-minute wait
        let local = CookTimeline.local(timers: [[], [4 ... 4], [33 ... 33], []])
        #expect(local.map(\.kind) == [.hands, .hands, .wait, .hands])
        #expect(local.map(\.end) == [120, 360, 2340, 2460])
    }

    // MARK: Start

    @Test func startingPlansEachDishWithItsOwnCookAndSaysSo() throws {
        let made = try engine.perform(StartCookSession(recipes: [chicken().id, pasta().id], servings: [4, 2],
                                                       serveAt: at(19), time: at(17)), by: .user)
        #expect(made.record.receipt == "Paprika chicken and Spaghetti, planned.")
        #expect(made.record.summary == "Several dishes planned")
        let session = made.output
        #expect(book.status(of: session) == "planned" && rows(.cookDish).count == 2 && rows(.cook).count == 2)
        #expect(store.value("serveAt", of: session)?.dateValue == at(19))
        let dishes = book.dishes(of: session)
        #expect(dishes.map { store.number("servings", of: $0) } == [4, 2])
        // The plan finishes together at the serve time.
        let plan = book.plan(of: session, now: at(17))
        #expect(plan.placements.allSatisfy { $0.end == at(19) } || plan.placements.contains { $0.end == at(19) })
        #expect(plan.serveAt == at(19) && !plan.isLate)
        // The cached numbers read back.
        #expect(dishes.allSatisfy { store.number("offsetSec", of: $0) != nil })
    }

    @Test func undoRemovesTheSessionItsDishesAndTheirCooks() throws {
        let made = try engine.perform(StartCookSession(recipes: [chicken().id, pasta().id], time: at(17)), by: .user)
        engine.undo(made.record)
        #expect(rows(.cookSession).isEmpty && rows(.cookDish).isEmpty && rows(.cook).isEmpty)
    }

    @Test func badStartsAreRefusedAndWriteNothing() throws {
        let one = try chicken()
        let several = try (0 ..< 7).map { try recipe("Dish \($0)", steps: ["Cook."]) }
        let tries = [StartCookSession(recipes: []), StartCookSession(recipes: [one.id, one.id]),
                     StartCookSession(recipes: several.map(\.id)), StartCookSession(recipes: [UUID()])]
        for action in tries {
            #expect(throws: (any Error).self) { try engine.perform(action, by: .user) }
        }
        #expect(rows(.cookSession).isEmpty && rows(.cookDish).isEmpty)
    }

    @Test func aServeTimeInThePastIsIgnored() throws {
        let session = try plan([chicken()], serveAt: at(16), now: at(17))
        #expect(store.value("serveAt", of: session) == nil)
    }

    // MARK: Serve time, add, drop

    @Test func setServeTimeReplansAndUndoRestoresTheOldOne() throws {
        let session = try plan([chicken(), pasta()], serveAt: at(19))
        let set = try engine.perform(SetServeTime(session: session.id, serveAt: at(20), time: at(17)), by: .user)
        #expect(set.record.receipt == "Serve at \(HouseTime.clock(at(20))).")
        #expect(store.value("serveAt", of: session)?.dateValue == at(20))
        engine.undo(set.record)
        #expect(store.value("serveAt", of: session)?.dateValue == at(19))
        let cleared = try engine.perform(SetServeTime(session: session.id, serveAt: nil, time: at(17)), by: .user)
        #expect(cleared.record.receipt == "Serve time, cleared." && store.value("serveAt", of: session) == nil)
    }

    @Test func addingAndDroppingADishSayItAndUndoBringsItBack() throws {
        let session = try plan([chicken()], serveAt: at(19))
        let added = try engine.perform(AddDish(session: session.id, recipe: pasta().id, time: at(17)), by: .user)
        #expect(added.record.receipt == "Spaghetti, added." && book.dishes(of: session).count == 2)
        // The same recipe twice is refused.
        #expect(throws: (any Error).self) { try engine.perform(
            AddDish(session: session.id, recipe: pasta().id),
            by: .user
        ) }
        let dropped = try engine.perform(DropDish(dish: added.output.id, time: at(17)), by: .user)
        #expect(dropped.record.receipt == "Spaghetti, dropped." && book.dishes(of: session).count == 1)
        engine.undo(dropped.record)
        #expect(book.dishes(of: session).count == 2)
        // Dropping the last dish drops the session.
        for dish in book.dishes(of: session) {
            try engine.perform(DropDish(dish: dish.id, time: at(17)), by: .user)
        }
        #expect(book.status(of: session) == "dropped")
    }

    // MARK: Steps and timers

    @Test func theFirstStepStartsTheSessionAndATimedStepStartsOneTimerWithAStableId() throws {
        let session = try plan([chicken()], serveAt: at(19))
        let dish = try #require(book.dishes(of: session).first)
        try engine.perform(AdvanceDishStep(dish: dish.id, step: 1, time: at(18)), by: .user)
        #expect(book.status(of: session) == "running" && store.value("startedAt", of: dish)?.dateValue == at(18))
        let timers = book.timers(of: session)
        #expect(timers.count == 1 && timers[0].id == AdvanceDishStep.timerID(dish: dish.id, step: 1))
        #expect(timers[0].endsAt == at(18).addingTimeInterval(4 * 60))
        // The next timed step stops the first and starts its own.
        try engine.perform(AdvanceDishStep(dish: dish.id, step: 2, time: at(18, 5)), by: .user)
        let next = book.timers(of: session)
        #expect(next.map(\.id) == [AdvanceDishStep.timerID(dish: dish.id, step: 2)])
        #expect(next[0].endsAt == at(18, 5).addingTimeInterval(33 * 60))
        // Going back reuses the first timer, not a second one.
        try engine.perform(AdvanceDishStep(dish: dish.id, step: 1, time: at(18, 6)), by: .user)
        #expect(rows(.kitchenTimer).count == 2 && book.timers(of: session).map(\.id) == [AdvanceDishStep.timerID(
            dish: dish.id,
            step: 1
        )])
        // An untimed step leaves no timer counting.
        try engine.perform(AdvanceDishStep(dish: dish.id, step: 3, time: at(18, 7)), by: .user)
        #expect(book.timers(of: session).isEmpty)
        #expect(throws: (any Error).self) { try engine.perform(AdvanceDishStep(dish: dish.id, step: 9), by: .user) }
    }

    // MARK: Pause

    @Test func pausingStopsTheTimersAndResumingMovesEverythingByTheGap() throws {
        let session = try plan([chicken(), pasta()], serveAt: at(19))
        let first = try #require(book.dishes(of: session).first)
        try engine.perform(AdvanceDishStep(dish: first.id, step: 2, time: at(18)), by: .user)
        let timerEnd = at(18).addingTimeInterval(33 * 60)
        try engine.perform(PauseCook(session: session.id, time: at(18, 10)), by: .user)
        #expect(book.status(of: session) == "paused" && book.timers(of: session).isEmpty)
        #expect(throws: (any Error).self) { try engine.perform(PauseCook(session: session.id), by: .user) }
        let resumed = try engine.perform(ResumeCook(session: session.id, time: at(18, 15)), by: .user)
        #expect(resumed.record.receipt == "Back on.")
        #expect(book.status(of: session) == "running")
        #expect(store.number("pausedTotalSec", of: session) == 300)
        #expect(store.value("serveAt", of: session)?.dateValue == at(19, 5))
        #expect(store.value("startedAt", of: first)?.dateValue == at(18, 5))
        let timer = try #require(book.timers(of: session).first)
        #expect(timer.endsAt == timerEnd.addingTimeInterval(300))
        #expect(throws: (any Error).self) { try engine.perform(ResumeCook(session: session.id), by: .user) }
    }

    // MARK: Finish

    @Test func finishingStampsEveryDishsCookAndSaysCooked() throws {
        let one = try chicken(), two = try pasta()
        let session = try plan([one, two], serveAt: at(19))
        let done = try engine.perform(FinishCookSession(session: session.id, note: "good", time: at(19)), by: .user)
        #expect(done.record.receipt == "Paprika chicken and Spaghetti, cooked.")
        #expect(book.status(of: session) == "done")
        let log = CookLog(store: store, classes: engine.classes)
        #expect(log.lastCooked(one) == at(19) && log.lastCooked(two) == at(19))
        #expect(throws: (any Error).self) { try engine.perform(FinishCookSession(session: session.id), by: .user) }
        engine.undo(done.record)
        #expect(log.lastCooked(one) == nil && book.status(of: session) == "planned")
    }

    // MARK: Walls

    @Test func aPrivateRecipeReadsPrivateInEveryLine() throws {
        let secret = try recipe("Lexapro cake", steps: ["Bake for 40 minutes."])
        let session = try engine.perform(
            StartCookSession(recipes: [secret.id, pasta().id], serveAt: at(19), time: at(17)),
            by: .user
        )
        #expect(session.record.receipt == "Private recipe and Spaghetti, planned.")
        let plan = book.plan(of: session.output, now: at(17))
        let lines = [
            plan.landing(calendar: calendar),
            plan.running(minutesLeft: 5),
            plan.serveLine(calendar: calendar),
        ] + plan.notes()
        #expect(lines.allSatisfy { !$0.contains("Lexapro") && !$0.contains("cake") })
        let dish = try #require(book.dishes(of: session.output).first)
        #expect(try !store.objects(of: #require(engine.classes[.cookDish])).contains { $0.title.contains("Lexapro") })
        #expect(book.name(of: dish) == "Private recipe")
        let finished = try engine.perform(FinishCookSession(session: session.output.id, time: at(19)), by: .user)
        #expect(!(finished.record.receipt ?? "").contains("Lexapro"))
    }

    @Test func aDeletedRecipeSkipsItsDishInThePlan() throws {
        let one = try chicken(), two = try pasta()
        let session = try plan([one, two], serveAt: at(19))
        store.softDelete(two)
        #expect(book.planDishes(of: session).count == 1)
    }

    @Test func noCookSessionActionIsOfferedToTheModel() {
        for name in ["startCookSession", "setServeTime", "addDish", "dropDish", "advanceDishStep", "pauseCook",
                     "resumeCook", "finishCookSession"]
        {
            #expect(ActionRegistry.descriptors.contains { $0.name == name } && !ActionRegistry.offered
                .contains { $0.name == name })
        }
    }
}
