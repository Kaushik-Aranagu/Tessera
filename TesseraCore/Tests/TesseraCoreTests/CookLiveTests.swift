import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Multi-dish Cook, Part A PR 3: privacy of the objects, the Now line, the Live Activity facts and the model's two
/// tools.
@MainActor
struct CookLiveTests {
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

    func two() throws -> (ObjectRecord, ObjectRecord, ObjectRecord) {
        let chicken = try recipe("Paprika chicken", steps: ["Season it", "Bake for 33 minutes", "Plate it"])
        let pasta = try recipe("Spaghetti", steps: ["Boil the water", "Cook for 10 minutes", "Drain it"])
        let session = try engine.perform(
            StartCookSession(recipes: [chicken.id, pasta.id], serveAt: at(19), time: at(17)),
            by: .user
        ).output
        return (chicken, pasta, session)
    }

    // MARK: Privacy of the objects

    @Test func aDishWhoseRecipeBecomesPrivateAfterwardsReadsPrivateInTheLabelAndTheExport() throws {
        let (chicken, _, session) = try two()
        let dish = try #require(book.dishes(of: session).first)
        #expect(ObjectPrivacy.label(of: dish, in: store, classes: engine.classes) == nil)
        #expect(ObjectPrivacy.label(of: session, in: store, classes: engine.classes) == nil)
        // The recipe is retitled with a private word after the dish exists.
        try engine.perform(RenameObject(object: chicken.id, title: "Lexapro cake"), by: .user)
        #expect(ObjectPrivacy.label(of: dish, in: store, classes: engine.classes) == "Private recipe")
        #expect(ObjectPrivacy.label(of: session, in: store, classes: engine.classes) == "Private cook")
        #expect(book.name(of: dish) == "Private recipe" || book.name(of: dish) == "Paprika chicken")
        // The shared export holds neither the old title the dish copied nor the new one.
        let json = try String(decoding: TesseraExport(context: store.context).encoded(), as: UTF8.self)
        #expect(!json.contains("Lexapro") && !json.contains("Paprika chicken"))
    }

    @Test func aPlainSessionIsPlainAndADeletedDishDoesNotMaskIt() throws {
        let (_, pasta, session) = try two()
        #expect(ObjectPrivacy.label(of: session, in: store, classes: engine.classes) == nil)
        let dish = try #require(book.dishes(of: session).last)
        store.softDelete(dish)
        #expect(book.recipe(of: dish)?.id == pasta.id)
        #expect(ObjectPrivacy.label(of: session, in: store, classes: engine.classes) == nil)
    }

    // MARK: Now and the Live Activity

    @Test func aPlannedSessionIsNotNowButARunningOneIs() throws {
        let (_, _, session) = try two()
        let picker = NowPicker(engine: engine)
        #expect(picker.pick(at: at(17), calendar: calendar).now?.object.id != session.id)
        let dish = try #require(book.dishes(of: session).first)
        try engine.perform(AdvanceDishStep(dish: dish.id, step: 1, time: at(17, 30)), by: .user)
        let now = try #require(picker.pick(at: at(17, 31), calendar: calendar).now)
        #expect(now.object.id == session.id && now.kind == .process)
        #expect(now.title == "Paprika chicken and Spaghetti")
        let line = try #require(now.nextStep)
        #expect(line.hasPrefix("Cooking Paprika chicken and Spaghetti, ") && line.hasSuffix(" left"))
        #expect(now.endsAt == at(17, 30).addingTimeInterval(33 * 60))
    }

    @Test func theLiveFactsHoldOneCookTheSoonestTimerAndThePlusN() throws {
        let (_, _, session) = try two()
        let dishes = book.dishes(of: session)
        try engine.perform(AdvanceDishStep(dish: dishes[0].id, step: 1, time: at(17, 30)), by: .user)
        try engine.perform(AdvanceDishStep(dish: dishes[1].id, step: 1, time: at(17, 31)), by: .user)
        let live = try #require(book.live(of: session, now: at(17, 32), calendar: calendar))
        #expect(live.title == "Paprika chicken and Spaghetti" && live.soonestLabel == "Step 2")
        #expect(live.soonestEndsAt == at(17, 31).addingTimeInterval(10 * 60))
        #expect(live.more == 1 && live.moreWord == "+1")
        // Paused or planned: paused still reads, planned does not.
        try engine.perform(PauseCook(session: session.id, time: at(17, 33)), by: .user)
        #expect(book.live(of: session, now: at(17, 34)) != nil)
    }

    @Test func aPrivateDishNeverShowsItsNameOrItsTimerLabelOnNowOrTheLockScreen() throws {
        let secret = try recipe("Lexapro cake", steps: ["Mix", "Bake for 40 minutes"])
        let pasta = try recipe("Spaghetti", steps: ["Boil", "Cook for 10 minutes"])
        let session = try engine.perform(
            StartCookSession(recipes: [secret.id, pasta.id], serveAt: at(19), time: at(17)),
            by: .user
        ).output
        let dish = try #require(book.dishes(of: session).first)
        try engine.perform(AdvanceDishStep(dish: dish.id, step: 1, time: at(17, 30)), by: .user)
        let live = try #require(book.live(of: session, now: at(17, 31)))
        #expect(live.title == "Private recipe and Spaghetti" && live.soonestLabel == "Timer")
        #expect(!live.line.contains("Lexapro") && !live.line.contains("cake"))
        let now = try #require(NowPicker(engine: engine).pick(at: at(17, 31), calendar: calendar).now)
        #expect(!now.title.contains("Lexapro") && !(now.nextStep ?? "").contains("Lexapro"))
    }

    @Test func nothingRunningMeansNoLiveFacts() throws {
        let (_, _, session) = try two()
        #expect(book.live(of: session, now: at(17)) == nil)
    }

    // MARK: The model's two tools

    func run(_ tool: String, _ json: String) throws -> [OpRecord] {
        try TessTools.run(
            tool,
            arguments: Data(json.utf8),
            engine: engine,
            pending: false,
            now: at(17),
            calendar: calendar
        )
    }

    @Test func theModelNamesRecipesAndGetsNothingBackButASentence() throws {
        _ = try recipe("Paprika chicken", steps: ["Bake for 33 minutes"])
        _ = try recipe("Spaghetti", steps: ["Cook for 10 minutes"])
        let records = try run(
            "cookTogether",
            #"{"recipes":["paprika chicken","spaghetti"],"serveAt":"2026-10-22T19:00:00Z"}"#
        )
        #expect(records.count == 1 && records[0].summary == "Several dishes planned")
        let session = try #require(book.current())
        #expect(store.value("serveAt", of: session)?.dateValue == at(19))
        let moved = try run("setServeTime", #"{"serveAt":"2026-10-22T20:00:00Z"}"#)
        #expect(moved[0].summary == "Serve time set" && store.value("serveAt", of: session)?.dateValue == at(20))
    }

    @Test func thePrivateAndTheUnknownCannotBeNamedAndTwoAreNeeded() throws {
        _ = try recipe("Lexapro cake", steps: ["Bake for 40 minutes"])
        _ = try recipe("Spaghetti", steps: ["Cook for 10 minutes"])
        for json in [
            #"{"recipes":["Lexapro cake","spaghetti"],"serveAt":null}"#,
            #"{"recipes":["spaghetti","Nonesuch"],"serveAt":null}"#,
            #"{"recipes":["spaghetti"],"serveAt":null}"#,
        ] {
            #expect(throws: (any Error).self) { try run("cookTogether", json) }
        }
        #expect(book.sessions().isEmpty)
        #expect(throws: (any Error).self) { try run("setServeTime", #"{"serveAt":"2026-10-22T20:00:00Z"}"#) }
    }

    @Test func theToolDefinitionsOfferTitlesAndATimeOnly() throws {
        let json = try String(decoding: TessTools.definitionsJSON(), as: UTF8.self)
        let cook = try #require(TessTools.tool(named: "cookTogether"))
        let serve = try #require(TessTools.tool(named: "setServeTime"))
        #expect(json.contains("\"cookTogether\"") && json.contains("\"setServeTime\""))
        let described = "\(cook.input.json) \(serve.input.json)"
        #expect(described.contains("recipes") && described.contains("serveAt"))
        for forbidden in ["session", "dish", "uuid", "id\""] {
            #expect(!described.lowercased().contains(forbidden))
        }
    }
}
