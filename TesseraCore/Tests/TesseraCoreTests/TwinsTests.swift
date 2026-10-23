import Foundation
@testable import TesseraCore
import Testing

/// Together round 13, 183 twinsV2: a quiet offer to join two things that look the same.
@MainActor
struct TwinsTests {
    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    func make(_ key: SystemCatalog.Key, _ title: String) throws -> ObjectRecord {
        try store.create(#require(engine.classes[key]), title: title)
    }

    @Test func twoTasksWithTheSameNameAreOfferedOldestKept() throws {
        let first = try make(.task, "Call the landlord")
        let second = try make(.task, "  call the LANDLORD! ")
        _ = try make(.task, "Buy stamps")
        let offer = try #require(Twins.next(engine: engine))
        #expect(offer.keep == first.id && offer.other == second.id)
        #expect(offer.sentence == "Two tasks called Call the landlord.")
        #expect(Twins.offers(engine: engine).count == 1)
    }

    @Test func joiningMovesLinksFillsGapsAndDeletesTheNewerOneUndoably() throws {
        let older = try make(.list, "Tacos")
        let newer = try make(.list, "Tacos")
        let occasion = try engine.perform(
            CreateOccasion(title: "Dinner", start: .now, end: .now, links: [newer.id]), by: .user
        ).output
        try store.set("notes", to: .richText("for friday"), on: newer)
        let joined = try engine.perform(JoinTwins(keep: older.id, other: newer.id), by: .user)
        #expect(newer.isDeleted && !older.isDeleted)
        #expect(store.linkedObjects("links", of: occasion).map(\.id) == [older.id])
        #expect(store.value("notes", of: older)?.stringValue == "for friday")
        #expect(!joined.record.summary.contains("Tacos") && !(joined.record.receipt ?? "").contains("Tacos"))
        #expect(Twins.next(engine: engine) == nil)
        _ = engine.undo(joined.record)
        #expect(!newer.isDeleted)
        #expect(store.linkedObjects("links", of: occasion).map(\.id) == [newer.id])
        #expect(Twins.next(engine: engine) != nil)
    }

    @Test func notTheSameIsRememberedAndUndoable() throws {
        let one = try make(.recipe, "Soup")
        let two = try make(.recipe, "Soup")
        let apart = try engine.perform(KeepTwinsApart(first: one.id, second: two.id), by: .user)
        #expect(Twins.next(engine: engine) == nil)
        _ = engine.undo(apart.record)
        #expect(Twins.next(engine: engine) != nil)
    }

    @Test func privateMoneyAndBodyThingsAreNeverOffered() throws {
        _ = try make(.task, "Lexapro refill")
        _ = try make(.task, "Lexapro refill")
        _ = try make(.task, "Knee rehab")
        _ = try make(.task, "Knee rehab")
        let pool = try engine.perform(CreatePool(name: "US checking", opening: "10"), by: .user).output
        _ = pool
        _ = try make(.note, "Lexapro")
        _ = try make(.note, "Lexapro")
        #expect(Twins.offers(engine: engine).isEmpty)
        let one = try make(.task, "Lexapro refill")
        let two = try make(.task, "Lexapro refill")
        #expect(throws: (any Error).self) { try engine.perform(JoinTwins(keep: one.id, other: two.id), by: .user) }
    }

    @Test func notesNeedTheSameWordsAndAreNeverNamed() throws {
        let one = try make(.note, "Ideas")
        let two = try make(.note, "Ideas")
        try store.set("body", to: .text("a trip"), on: one)
        try store.set("body", to: .text("a boat"), on: two)
        #expect(Twins.next(engine: engine) == nil)
        try store.set("body", to: .text("a boat"), on: one)
        #expect(Twins.next(engine: engine)?.sentence == "Two notes say the same.")
    }

    @Test func aThingWithChildrenIsNotOffered() throws {
        let one = try make(.list, "Shop")
        _ = try make(.list, "Shop")
        _ = try engine.perform(AddListItem(list: one.id, text: "milk"), by: .user)
        #expect(Twins.next(engine: engine) == nil)
    }
}
