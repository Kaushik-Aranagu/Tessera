import Foundation
@testable import TesseraCore
import Testing

/// Together, piece 4: Occasions. The class, the actions, and the one signature fact per linked app. Money shows on
/// the Occasion page only.
@MainActor
struct OccasionTests {
    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    func day(_ day: Int, _ hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour))!
    }

    @discardableResult
    func occasion(_ title: String = "Lisbon trip", links: [ObjectRecord] = [], from: Int = 10, to: Int = 14) throws
        -> ObjectRecord
    {
        try engine.perform(
            CreateOccasion(title: title, start: day(from, 0), end: day(to, 0), links: links.map(\.id)), by: .user
        ).output
    }

    func facts(_ occasion: ObjectRecord, _ surface: OccasionSurface) -> [OccasionFact] {
        OccasionFacts.facts(for: occasion, engine: engine, now: day(12), surface: surface, calendar: calendar)
    }

    func list(_ name: String, items: [String], done: Int = 0) throws -> ObjectRecord {
        let list = try store.create(#require(engine.classes[.list]), title: name)
        var made: [ObjectRecord] = []
        for text in items {
            try made.append(engine.perform(AddListItem(list: list.id, text: text), by: .user).output)
        }
        for item in made.prefix(done) {
            try engine.perform(CheckListItem(item: item.id), by: .user)
        }
        return list
    }

    func workout(_ title: String, on dayNumber: Int) throws {
        let workout = try store.create(#require(engine.classes[.workout]), title: title)
        try store.set("endedAt", to: .date(day(dayNumber)), on: workout)
        let entry = try store.create(#require(engine.classes[.exerciseEntry]), parent: workout)
        try store.setClassLink("exercise", on: entry, to: #require(engine.classes[.benchPress]))
        try TrainingLedger(store: store, classes: engine.classes).logSet(weight: 60, reps: 5, rpe: nil, in: entry)
    }

    func pool(_ name: String = "Savings", opening: String = "1345.00") throws -> ObjectRecord {
        try engine.perform(CreatePool(name: name, opening: opening), by: .user).output
    }

    // MARK: Class and actions

    @Test func theClassSeedsUnderThingWithItsThreeFields() throws {
        let classDef = try #require(engine.classes[.occasion])
        let thing = try #require(engine.classes[.thing])
        #expect(ClassResolver.isSubclass(classDef, of: thing))
        #expect(classDef.name == "Occasion")
        for key in ["start", "end", "links"] {
            #expect(store.field(key, of: classDef) != nil)
        }
        #expect(store.field("links", of: classDef)?.kind == .refList)
    }

    @Test func createWritesTheFieldsAndUndoRemovesIt() throws {
        let trip = try list("Packing", items: ["socks"])
        let made = try engine.perform(
            CreateOccasion(title: "Lisbon trip", start: day(10, 0), end: day(14, 0), links: [trip.id]), by: .user
        )
        #expect(made.output.title == "Lisbon trip")
        #expect(store.value("start", of: made.output)?.dateValue == day(10, 0))
        #expect(store.linkedObjects("links", of: made.output).map(\.id) == [trip.id])
        #expect(made.record.summary == "New occasion")
        _ = engine.undo(made.record)
        #expect(made.output.isDeleted)
    }

    @Test func linkAndUnlinkAreOneOpAndOneUndoEach() throws {
        let one = try list("Packing", items: [])
        let two = try list("Visas", items: [])
        let made = try occasion(links: [one])
        let linked = try engine.perform(LinkToOccasion(occasion: made.id, thing: two.id), by: .user)
        #expect(store.linkedObjects("links", of: made).map(\.id) == [one.id, two.id])
        _ = try engine.perform(LinkToOccasion(occasion: made.id, thing: two.id), by: .user)
        #expect(store.linkedObjects("links", of: made).count == 2)
        let unlinked = try engine.perform(UnlinkFromOccasion(occasion: made.id, thing: one.id), by: .user)
        #expect(store.linkedObjects("links", of: made).map(\.id) == [two.id])
        _ = engine.undo(unlinked.record)
        #expect(store.linkedObjects("links", of: made).map(\.id) == [one.id, two.id])
        _ = engine.undo(linked.record)
        #expect(store.linkedObjects("links", of: made).map(\.id) == [one.id])
    }

    @Test func theActionsAreInTheRegistryAndNotOfferedToTheModel() {
        for name in ["createOccasion", "linkToOccasion", "unlinkFromOccasion"] {
            let descriptor = ActionRegistry.descriptors.first { $0.name == name }
            #expect(descriptor != nil)
            #expect(descriptor?.isOfferedToModel == false)
            #expect(ActionRegistry.offered.contains { $0.name == name } == false)
        }
    }

    @Test func linkRejectsANonOccasionAndEndBeforeStart() throws {
        let some = try list("Packing", items: [])
        #expect(throws: (any Error).self) {
            try engine.perform(LinkToOccasion(occasion: some.id, thing: some.id), by: .user)
        }
        #expect(throws: (any Error).self) {
            try engine.perform(CreateOccasion(title: "Backwards", start: day(14), end: day(10)), by: .user)
        }
    }

    // MARK: Facts

    @Test func aListReadsLeftOfTotal() throws {
        let packing = try list("Packing", items: ["socks", "charger", "passport", "hat"], done: 1)
        let facts = try facts(occasion(links: [packing]), .occasionPage)
        #expect(facts == [OccasionFact(app: .lists, thing: packing.id, text: "3 left of 4")])
    }

    @Test func aRecipeReadsHowManyToGet() throws {
        let recipe = try engine.perform(
            CreateRecipe(text: "Tacos\nServes 2\nIngredients\n3 onions\n200 g mince\nMethod\nCook it."), by: .user
        ).output
        try engine.perform(AddRecipeToGroceries(recipe: recipe.id), by: .user)
        let facts = try facts(occasion(links: [recipe]), .other)
        #expect(facts.map(\.text) == ["2 to get"])
        #expect(facts.first?.app == .kitchen)
    }

    @Test func aRoutineReadsByName() throws {
        let routine = try store.create(#require(engine.classes[.routine]), title: "Push day")
        let facts = try facts(occasion(links: [routine]), .other)
        #expect(facts == [OccasionFact(app: .routines, thing: routine.id, text: "Push day")])
    }

    @Test func trainingCountsSessionsInTheRangeOnly() throws {
        let routine = try store.create(#require(engine.classes[.workout]), title: "Gym day")
        try workout("Push", on: 11)
        try workout("Pull", on: 14)
        try workout("Early", on: 9)
        try workout("Late", on: 15)
        try workout("Therapy session", on: 12)
        let facts = try facts(occasion(links: [routine]), .other)
        #expect(facts == [OccasionFact(app: .training, thing: nil, text: "2 sessions")])
    }

    @Test func moneyShowsOnTheOccasionPageOnly() throws {
        let savings = try pool()
        let made = try occasion(links: [savings])
        #expect(facts(made, .occasionPage).map(\.text) == ["$1,345.00"])
        let other = facts(made, .other)
        #expect(other.isEmpty)
        let printed = String(describing: other)
        #expect(!printed.contains("1,345") && !printed.contains("Savings"))
    }

    @Test func otherSurfaceKeepsTheRestAndDropsOnlyMoney() throws {
        let packing = try list("Packing", items: ["socks"])
        let made = try occasion(links: [packing, pool()])
        #expect(facts(made, .occasionPage).count == 2)
        let other = facts(made, .other)
        #expect(other.map(\.app) == [.lists])
        #expect(!String(describing: other).contains("$"))
    }

    // MARK: Privacy

    @Test func privateThingsAreMaskedAndNeverNamed() throws {
        let secret = try store.create(#require(engine.classes[.list]), title: "Therapy plan")
        let recipe = try store.create(#require(engine.classes[.recipe]), title: "Lexapro cake")
        let privateRoutine = try store.create(#require(engine.classes[.routine]), title: "Rehab")
        let privateWorkout = try store.create(#require(engine.classes[.workout]), title: "Rehab session")
        let made = try occasion(links: [secret, recipe, privateRoutine, privateWorkout])
        let texts = facts(made, .occasionPage).map(\.text)
        #expect(texts == ["Private list", "Private recipe", "Private workout"])
        let printed = String(describing: facts(made, .occasionPage))
        for word in ["Therapy", "Lexapro", "Rehab"] {
            #expect(!printed.contains(word))
        }
    }

    @Test func aDeletedLinkIsSkipped() throws {
        let packing = try list("Packing", items: ["socks"])
        let visas = try list("Visas", items: ["form", "photo"])
        let made = try occasion(links: [packing, visas])
        try engine.perform(DeleteObject(object: packing.id), by: .user)
        #expect(facts(made, .occasionPage).map(\.text) == ["2 left of 2"])
    }

    @Test func theTitleNeverCarriesAPoolNameOrAnAmount() throws {
        _ = try pool("Holiday fund")
        #expect(throws: (any Error).self) {
            try engine.perform(
                CreateOccasion(title: "Lisbon from Holiday fund", start: day(10), end: day(11)), by: .user
            )
        }
        #expect(throws: (any Error).self) {
            try engine.perform(CreateOccasion(title: "Lisbon $1,345.00", start: day(10), end: day(11)), by: .user)
        }
        let made = try occasion(links: [pool("Trip money")])
        #expect(made.title == "Lisbon trip")
        let titles = (facts(made, .occasionPage) + facts(made, .other)).map(\.text)
        #expect(!titles.contains(made.title))
    }
}
