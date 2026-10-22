import Foundation
@testable import TesseraCore
import Testing

/// Money pools, PR 2: the actions (Part B, B3 and B6).
@MainActor
struct PoolActionTests {
    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine
    let book: PoolBook

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        book = PoolBook(store: store, classes: engine.classes)
    }

    @discardableResult
    func pool(_ name: String, _ currency: String = "USD", opening: String? = nil) throws -> ObjectRecord {
        try engine.perform(CreatePool(name: name, currency: currency, opening: opening), by: .user).output
    }

    func rows(_ key: SystemCatalog.Key) -> [ObjectRecord] {
        engine.classes[key].map { store.objects(of: $0).filter { !$0.isDeleted } } ?? []
    }

    @Test func noMoneyActionIsEverOfferedToTheModel() {
        let names = ["createPool", "logInflow", "reassignSpend", "logMove", "recordRate", "archivePool", "logSpend"]
        for name in names {
            #expect(ActionRegistry.descriptors.contains { $0.name == name }, "\(name)")
            #expect(!ActionRegistry.offered.contains { $0.name == name }, "\(name)")
        }
    }

    @Test func createPoolWritesTheFieldsAndSaysStarted() throws {
        let made = try engine.perform(CreatePool(name: "India account", currency: "inr", source: "Acme payroll",
                                                 kind: "saving", opening: "1,200.50"), by: .user)
        let india = made.output
        #expect(store.value("currency", of: india)?.stringValue == "INR" && store.value("poolKind", of: india)?
            .stringValue == "saving")
        #expect(book.balance(of: india) == Decimal(string: "1200.50"))
        #expect(made.record.receipt == "India account, started.")
        // The op log never holds the name, the source or the opening.
        #expect(made.record.summary == "New pool")
        for bad in [
            CreatePool(name: ""),
            CreatePool(name: "my password pool"),
            CreatePool(name: "X", currency: "RUPEES"),
            CreatePool(name: "X", kind: "vault"),
            CreatePool(name: "X", opening: "ten"),
        ] {
            #expect(throws: (any Error).self) { try engine.perform(bad, by: .user) }
        }
        #expect(rows(.pool).count == 1)
    }

    @Test func aWalledPoolNameReadsPrivateInTheReceipt() throws {
        let made = try engine.perform(CreatePool(name: "Ozempic dose"), by: .user)
        #expect(made.record.receipt == "Private pool, started.")
        #expect(!(made.record.receipt ?? "").contains("Ozempic"))
    }

    @Test func logInflowDefaultsToTheLastPoolUsedForTheCurrency() throws {
        let checking = try pool("US checking")
        let cash = try pool("Cash")
        let first = try engine.perform(LogInflow(amount: "3200", pool: checking.id, source: "paycheck"), by: .user)
        #expect(first.record.receipt == "Got $3,200.00, paycheck.")
        // The pool was used last: with none said, the next lands there.
        let second = try engine.perform(LogInflow(amount: "40", source: "gift"), by: .user).output
        #expect(store.linkedObjects("pool", of: second).first?.id == checking.id)
        _ = try engine.perform(LogInflow(amount: "5", pool: cash.id, source: "refund"), by: .user)
        let third = try engine.perform(LogInflow(amount: "6"), by: .user).output
        #expect(store.linkedObjects("pool", of: third).first?.id == cash.id)
        #expect(book.balance(of: checking) == 3240 && book.balance(of: cash) == 11)
    }

    @Test func aNegativeZeroOrJunkInflowIsRefusedAndWritesNothing() throws {
        let checking = try pool("US checking")
        for typed in ["-5", "0", "0.00", "abc", "", "1e3", "12..3"] {
            #expect(throws: (any Error).self, "\(typed)") {
                try engine.perform(LogInflow(amount: typed, pool: checking.id), by: .user)
            }
        }
        #expect(throws: (any Error).self) { try engine.perform(LogInflow(amount: "5", source: "lottery"), by: .user) }
        #expect(rows(.inflow).isEmpty && book.balance(of: checking) == 0)
    }

    @Test func noPoolMakesUnassignedInTheSameOpAndUndoRemovesIt() throws {
        let made = try engine.perform(LogInflow(amount: "10", currency: "INR"), by: .user)
        let unassigned = try #require(store.linkedObjects("pool", of: made.output).first)
        #expect(unassigned.title == "Unassigned INR" && store.value("currency", of: unassigned)?.stringValue == "INR")
        engine.undo(made.record)
        #expect(rows(.inflow).isEmpty && rows(.pool).isEmpty)
        // Done again, it is the same pool each time.
        let one = try engine.perform(LogInflow(amount: "10", currency: "INR"), by: .user).output
        let two = try engine.perform(LogInflow(amount: "11", currency: "INR"), by: .user).output
        #expect(store.linkedObjects("pool", of: one).first?.id == store.linkedObjects("pool", of: two).first?.id)
        #expect(rows(.pool).count == 1)
    }

    @Test func aPoolInAnotherCurrencyIsRefusedWithTheWords() throws {
        let india = try pool("India account", "INR")
        do {
            _ = try engine.perform(LogInflow(amount: "5", pool: india.id, currency: "USD"), by: .user)
            Issue.record("expected a refusal")
        } catch {
            #expect("\(error)".contains("That pool holds INR."))
        }
        #expect(throws: (any Error).self) { try engine.perform(
            LogSpend(amount: 5, currency: "USD", pool: india.id),
            by: .user
        ) }
        let usd = try engine.perform(LogSpend(amount: 5, note: "coffee"), by: .user).output
        do {
            _ = try engine.perform(ReassignSpend(spend: usd.id, pool: india.id), by: .user)
            Issue.record("expected a refusal")
        } catch {
            #expect("\(error)".contains("That pool holds INR."))
        }
        #expect(rows(.inflow).isEmpty && store.linkedObjects("pool", of: usd).isEmpty)
    }

    @Test func oneSpendOnePoolAndReassignMovesIt() throws {
        let checking = try pool("US checking")
        let cash = try pool("Cash")
        let spend = try engine.perform(
            LogSpend(amount: 12.40, typed: "12.40", note: "lunch", pool: checking.id),
            by: .user
        )
        #expect(store.linkedObjects("pool", of: spend.output).map(\.id) == [checking.id])
        #expect(book.balance(of: checking) == Decimal(string: "-12.40"))
        let moved = try engine.perform(ReassignSpend(spend: spend.output.id, pool: cash.id), by: .user)
        #expect(store.linkedObjects("pool", of: spend.output).map(\.id) == [cash.id])
        #expect(book.balance(of: checking) == 0 && book.balance(of: cash) == Decimal(string: "-12.40"))
        engine.undo(moved.record)
        #expect(store.linkedObjects("pool", of: spend.output).map(\.id) == [checking.id])
    }

    @Test func aSpendTakesThePoolsCurrencyWhenNoneIsTyped() throws {
        let india = try pool("India account", "INR", opening: "1000")
        let spend = try engine.perform(LogSpend(amount: 450, typed: "450", note: "coffee", pool: india.id), by: .user)
            .output
        #expect(store.value("currency", of: spend)?.stringValue == "INR")
        #expect(book.balance(of: india) == 550)
    }

    @Test func autoPoolOnlyTouchesPoolsWhenAsked() throws {
        let off = try engine.perform(LogSpend(amount: 5, note: "tea"), by: .user).output
        #expect(store.linkedObjects("pool", of: off).isEmpty && rows(.pool).isEmpty)
        let on = try engine.perform(LogSpend(amount: 5, note: "tea", autoPool: true), by: .user).output
        let landed = try #require(store.linkedObjects("pool", of: on).first)
        #expect(landed.title == "Unassigned USD" && rows(.pool).count == 1)
    }

    @Test func legacySpendsReadAsADerivedBucketAndNothingIsRewritten() throws {
        let old = try engine.perform(LogSpend(amount: 12.40, typed: "12.40", note: "lunch"), by: .user).output
        let oldEuro = try engine.perform(LogSpend(amount: 8, typed: "€8", currency: "EUR", note: "tea"), by: .user)
            .output
        #expect(try book.spendsWithNoPool() == ["USD": #require(Decimal(string: "12.40")), "EUR": 8])
        #expect(store.linkedObjects("pool", of: old).isEmpty && store.linkedObjects("pool", of: oldEuro).isEmpty)
        #expect(rows(.pool).isEmpty)
    }

    @Test func aMoveAcrossCurrenciesNotesItsRateAndUndoTakesBothAway() throws {
        let checking = try pool("US checking", opening: "5000")
        let india = try pool("India account", "INR")
        let made = try engine.perform(
            LogMove(from: checking.id, to: india.id, sent: "1000.00", arrived: "82650.00", fee: "5.00"),
            by: .user
        )
        #expect(made.record.receipt == "Moved $1,000.00, got INR 82,650.00.")
        #expect(made.record.summary == "Money moved")
        #expect(book.balance(of: checking) == 3995 && book.balance(of: india) == 82650)
        let note = try #require(rows(.rateNote).first)
        #expect(store.value("pair", of: note)?.stringValue == "USD/INR" && store.value("origin", of: note)?
            .stringValue == "move")
        #expect(PoolBook.decimal(store.value("valueTyped", of: note)?.stringValue) == Decimal(string: "82.23880597"))
        engine.undo(made.record)
        #expect(rows(.poolMove).isEmpty && rows(.rateNote).isEmpty && book.balance(of: checking) == 5000)
    }

    @Test func movesNeedTwoPoolsPositiveAmountsAndEqualWithinACurrency() throws {
        let one = try pool("One"), two = try pool("Two"), india = try pool("India", "INR")
        let bad: [LogMove] = [
            LogMove(from: one.id, to: one.id, sent: "5", arrived: "5"),
            LogMove(from: one.id, to: two.id, sent: "5", arrived: "6"),
            LogMove(from: one.id, to: india.id, sent: "5", arrived: "0"),
            LogMove(from: one.id, to: india.id, sent: "0", arrived: "10"),
            LogMove(from: one.id, to: india.id, sent: "5", arrived: "-10"),
            LogMove(from: one.id, to: india.id, sent: "5", arrived: "10", fee: "abc"),
        ]
        for move in bad {
            #expect(throws: (any Error).self) { try engine.perform(move, by: .user) }
        }
        #expect(rows(.poolMove).isEmpty && rows(.rateNote).isEmpty)
        // Within one currency, equal amounts are fine and note no rate.
        try engine.perform(LogMove(from: one.id, to: two.id, sent: "5", arrived: "5"), by: .user)
        #expect(rows(.poolMove).count == 1 && rows(.rateNote).isEmpty)
    }

    @Test func recordRateSavesAndRefusesNonsense() throws {
        let made = try engine.perform(RecordRate(pair: "usd/inr", value: "83.10"), by: .user)
        #expect(made.record.receipt == "Rate saved, INR 83.10.")
        #expect(made.record.summary == "Rate noted")
        for bad in [RecordRate(pair: "USD", value: "83"), RecordRate(pair: "USD/USD", value: "1"),
                    RecordRate(pair: "USD/INR", value: "0"), RecordRate(pair: "USD/INR", value: "-3"),
                    RecordRate(pair: "USD/INR", value: "fast")]
        {
            #expect(throws: (any Error).self) { try engine.perform(bad, by: .user) }
        }
        #expect(rows(.rateNote).count == 1)
    }

    @Test func anArchivedPoolStaysInTotalsButIsNotOfferedAndUndoRestoresIt() throws {
        let old = try pool("Old savings", opening: "100")
        let fresh = try pool("Fresh")
        try engine.perform(LogInflow(amount: "7", pool: fresh.id), by: .user)
        let archived = try engine.perform(ArchivePool(pool: old.id), by: .user)
        #expect(archived.record.receipt == "Old savings, archived.")
        #expect(book.balance(of: old) == 100)
        // Nothing new defaults into it.
        let landed = try engine.perform(LogInflow(amount: "1"), by: .user).output
        #expect(store.linkedObjects("pool", of: landed).first?.id == fresh.id)
        engine.undo(archived.record)
        #expect(store.value("archivedAt", of: old)?.dateValue == nil)
    }

    @Test func noSummaryHoldsAPoolNameAnAmountOrARate() throws {
        let checking = try pool("US checking", opening: "123.45")
        let india = try pool("India account", "INR")
        var summaries: [String] = []
        try summaries.append(engine.perform(LogInflow(amount: "3200", pool: checking.id), by: .user).record.summary)
        try summaries.append(engine.perform(
            LogMove(from: checking.id, to: india.id, sent: "1000", arrived: "82650"),
            by: .user
        ).record.summary)
        try summaries.append(engine.perform(RecordRate(pair: "USD/INR", value: "83.10"), by: .user).record.summary)
        try summaries.append(engine.perform(ArchivePool(pool: india.id), by: .user).record.summary)
        for summary in summaries {
            for needle in ["US checking", "India", "3200", "82650", "83.10", "$", "INR", "123"] {
                #expect(!summary.contains(needle), "\(summary)")
            }
        }
    }
}
