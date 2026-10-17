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

    @Test func addingToAnOlderListMakesItTheHero() throws {
        let packing = try model.engine.perform(CreateList(name: "Packing"), by: .user).output
        try model.engine.perform(CreateList(name: "Books"), by: .user)
        try model.engine.perform(AddListItem(list: packing.id, text: "charger"), by: .user)
        #expect(shelf.rows.first?.name == "Packing")
    }

    /// The Add line speaks the engine's receipt: a secret or money-only line went to a private note, a price was
    /// stripped, a medicine is "Private item" (QA on #760).
    @Test func theAddReceiptIsTheEnginesAndNeverEchoesAWalledLine() throws {
        let packing = try model.engine.perform(CreateList(name: "Packing"), by: .user).output
        func spoken(_ text: String) throws -> String {
            let record = try model.engine.perform(AddListItem(list: packing.id, text: text), by: .user).record
            return ListsCopy.spoken(receipt: record.receipt ?? "", listTitle: "Packing", shownList: "Packing")
        }
        #expect(try spoken("rice") == "Rice, on Packing.")
        #expect(try spoken("advil") == "Private item, on Packing.")
        let secret = try spoken("wifi password hunter2")
        #expect(!secret.contains("hunter2") && !secret.contains("on Packing"))
        let money = try spoken("rent $1200")
        #expect(!money.contains("$") && !money.contains("1200"))
        let price = try spoken("milk $4")
        #expect(!price.contains("$") && price.hasPrefix("Milk"))
    }

    @Test func aPrivateListNameIsMaskedInTheReceiptAndAnEmptyPageSaysSo() {
        #expect(ListsCopy.spoken(receipt: "Rice, on Rent 1200 bills", listTitle: "Rent 1200 bills",
                                 shownList: "Private list") == "Rice, on Private list.")
        #expect(ListsCopy.pageContext(open: 0, all: 0) == "nothing on it yet")
        #expect(ListsCopy.pageContext(open: 4, all: 7) == "3 of 7")
    }

    /// 9.2, 9.3, 13.3: a run is first, reads RUNNING, N LEFT, counts in the context line, and is Tess's line.
    @Test func aRunningListLeadsTheShelf() throws {
        let packing = try model.engine.perform(CreateList(name: "Packing"), by: .user).output
        try model.engine.perform(AddListItem(list: packing.id, text: "socks"), by: .user)
        try model.engine.perform(CreateList(name: "Books"), by: .user)
        try model.engine.perform(StartListRun(list: packing.id), by: .user)
        let shelf = ListsShelf(store: model.store, classes: model.classes, lastWeightKg: nil, engine: model.engine)
        let first = try #require(shelf.rows.first)
        #expect(first.name == "Packing" && first.isRunning && first.state == "RUNNING, 1 LEFT")
        #expect(shelf.context.hasSuffix(", 1 running"))
        #expect(shelf.tess == "Packing has 1 left.")
    }

    @Test func aReusableListReadsReusable() throws {
        let gym = try model.engine.perform(CreateList(name: "Gym bag"), by: .user).output
        try model.engine.perform(SetListReusable(list: gym.id), by: .user)
        #expect(shelf.rows.first { $0.id == gym.id }?.state == "REUSABLE")
    }

    /// QA on #814: a set-aside run of a walled list shows on Now's ledger as Private list, never its title.
    @Test func aPausedPrivateRunNeverShowsItsName() throws {
        let title = "Rent 1200 stuff"
        let list = try model.engine.perform(CreateList(name: title), by: .user).output
        try model.engine.perform(AddListItem(list: list.id, text: "boxes"), by: .user)
        try model.engine.perform(StartListRun(list: list.id), by: .user)
        let table = ProcessTable(engine: model.engine)
        let run = try #require(table.all().first { $0.subject?.id == list.id })
        try model.engine.perform(SuspendProcess(process: run.id), by: .user)
        let paused = try #require(table.all().first { $0.id == run.id })
        let shown = LedgerRow.shown(paused, store: model.store, classes: model.classes, lastWeightKg: nil)
        #expect(shown.title == "Private list" && shown.nextStep == "1 left")
        #expect(!shown.title.contains("Rent") && !(shown.nextStep ?? "").contains("Rent"))
    }

    /// G9: a finished trip list leaves the shelf for the foot's Put away.
    @Test func aFinishedTripListIsPutAway() throws {
        let trip = try model.engine.perform(CreateList(name: "Lisbon"), by: .user).output
        try model.engine.perform(AddListItem(list: trip.id, text: "passport"), by: .user)
        try model.engine.perform(StartListRun(list: trip.id), by: .user)
        let contents = ListContents(store: model.store, classes: model.classes)
        for item in contents.open(in: trip) {
            try model.engine.perform(CheckListItem(item: item.id), by: .user)
        }
        let done = try model.engine.perform(FinishListRun(list: trip.id), by: .user).output
        #expect(done.putAway)
        let shelf = ListsShelf(store: model.store, classes: model.classes, lastWeightKg: nil, engine: model.engine)
        #expect(!shelf.rows.contains { $0.id == trip.id } && shelf.awayCount == 1)
    }
}
