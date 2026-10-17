import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// Screen 9's shelf as data: order by last touched, tiers, state words, the context line.
@MainActor
struct ListsShelfTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel

    init() {
        model = AppModel(context: container.mainContext)
    }

    private var shelf: ListsShelf {
        ListsShelf(store: model.store, classes: model.classes, lastWeightKg: nil)
    }

    @Test func stateWords() {
        #expect(ListsShelf.state(open: 4, all: 7, isGroceries: false) == "3 OF 7")
        #expect(ListsShelf.state(open: 0, all: 0, isGroceries: false) == "EMPTY")
        #expect(ListsShelf.state(open: 14, all: 20, isGroceries: true) == "14 TO GET")
        #expect(ListsShelf.state(open: 0, all: 3, isGroceries: true) == "NOTHING TO GET")
    }

    @Test func theNewestTouchedTakesTheHeroAndTheNextTwoTheTitle() throws {
        for name in ["Packing", "Gym bag", "Books", "Gifts"] {
            try model.engine.perform(CreateList(name: name), by: .user)
        }
        let rows = shelf.rows.filter { !$0.isGroceries }
        #expect(rows.count == 4)
        #expect(shelf.rows.first?.tier == .hero)
        #expect(shelf.rows.filter { $0.tier == .title }.count == min(2, shelf.rows.count - 1))
        #expect(shelf.context == "\(shelf.rows.count) lists")
    }

    @Test func aWalledListNameReadsPrivateList() {
        #expect(ListsShelf.shownName("Rent 1200 bills", lastWeightKg: nil) == "Private list")
        #expect(ListsShelf.shownName("Packing", lastWeightKg: nil) == "Packing")
    }
}
