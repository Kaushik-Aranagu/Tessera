import Foundation
@testable import TesseraCore
import Testing

/// QA on #1148: exact queueing, no "pounds" currency, money actions kept from the model.
@MainActor
struct QAFixes1148Tests {
    let store = ObjectStore.open(inMemory: true)

    @Test func queueingDuneAfterDuneMessiahMakesTwoBooks() throws {
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        let messiah = try engine.perform(QueueBook(title: "Dune Messiah"), by: .user).output
        let dune = try engine.perform(QueueBook(title: "dune"), by: .user).output
        #expect(messiah.id != dune.id)
        let again = try engine.perform(QueueBook(title: "DUNE "), by: .user).output
        #expect(again.id == dune.id)
        let shelf = Bookshelf(store: store, classes: engine.classes)
        #expect(shelf.book(exactly: "It") == nil)
    }

    @Test func theLooseLookupMatchesWholeWordsOnly() throws {
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        try engine.perform(QueueBook(title: "Little Women"), by: .user)
        let shelf = Bookshelf(store: store, classes: engine.classes)
        #expect(shelf.book(named: "it") == nil)
        #expect(shelf.book(named: "women")?.title == "Little Women")
    }

    @Test func poundsIsNotACurrencyButQuidIs() {
        #expect(MoneyAmount.parse("3 pounds chicken")?.currency == nil)
        #expect(MoneyAmount.parse("23 quid")?.currency == "GBP")
        #expect(MoneyAmount.parse("£4.50")?.currency == "GBP")
    }

    @Test func theMoneyActionsAreNotInTheModelsToolList() {
        let offered = Set(ActionRegistry.offered.map(\.name))
        for name in ["logSpend", "editSpend", "logShopTotal", "skipShopTotal"] {
            #expect(!offered.contains(name), "\(name)")
            #expect(ActionRegistry.descriptors.contains { $0.name == name })
        }
        #expect(offered.contains("setBookPage") && offered.contains("startReading"))
    }
}
