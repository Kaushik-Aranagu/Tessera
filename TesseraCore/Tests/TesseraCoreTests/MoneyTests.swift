import Foundation
@testable import TesseraCore
import Testing

/// Money slices 1 to 3 (docs/product/ship-list-m5-money.md, with its Oct 17 amendments).
@MainActor
struct MoneyTests {
    let store = ObjectStore.open(inMemory: true)
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar
    }

    func at(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    func engine() throws -> ActionEngine {
        try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    @Test(arguments: [
        ("12.40 lunch", "12.40", nil as String?), ("12,40", "12,40", nil), ("€8", "€8", "EUR"), (
            "£4.50 cab",
            "£4.50",
            "GBP"
        ),
        ("$3", "$3", "USD"), ("20 eur taxi", "20 eur", "EUR"), ("20 euros", "20 euros", "EUR"),
        ("23 quid", "23 quid", "GBP"), ("500 rs", "500 rs", "INR"), ("₹500", "₹500", "INR"),
        ("450 groceries", "450", nil),
    ])
    func theAmountIsKeptAsTypedAndTheCodeOnlyWhenSaid(_ text: String, _ typed: String, _ code: String?) throws {
        let parsed = try #require(MoneyAmount.parse(text))
        #expect(parsed.typed == typed && parsed.currency == code, "\(parsed)")
    }

    @Test func theNoteIsWhatFollowsTheAmount() {
        #expect(MoneyAmount.note(after: "12.40 lunch with sam") == "lunch with sam")
        #expect(MoneyAmount.note(after: "20 eur taxi") == "taxi")
        #expect(MoneyAmount.parse("lunch") == nil)
    }

    @Test func logSpendWritesTheFieldsThingFirstAndUndoRemovesIt() throws {
        let engine = try engine()
        let made = try engine.perform(
            LogSpend(amount: 12.40, typed: "12.40", note: "lunch with sam", spentAt: at(15, 13, 10)), by: .user
        )
        let spend = made.output
        #expect(spend.title == "12.40 lunch with sam" && made.record.summary == "12.40 lunch with sam")
        #expect(made.record.receipt == "Lunch with sam, 12.40")
        #expect(store.value("category", of: spend)?.stringValue == "lunch")
        #expect(store.value("currency", of: spend)?.stringValue == "")
        engine.undo(made.record)
        #expect(spend.isDeleted)
    }

    @Test func aBadAmountIsRefused() throws {
        let engine = try engine()
        #expect(throws: ActionError.self) { try engine.perform(LogSpend(amount: 0), by: .user) }
        #expect(throws: ActionError.self) { try engine.perform(LogSpend(amount: .infinity), by: .user) }
    }

    @Test func editSpendChangesTheTitleToo() throws {
        let engine = try engine()
        let spend = try engine.perform(LogSpend(amount: 12.40, typed: "12.40", note: "lunch"), by: .user).output
        let edited = try engine.perform(EditSpend(spend: spend.id, amount: 13, typed: "13.00", note: "lunch with sam"),
                                        by: .user)
        #expect(spend.title == "13.00 lunch with sam" && edited.record.receipt == "13.00 lunch with sam, changed")
    }

    @Test func aSpendIsPrivateEverywhereButItsOwnPageAndTheExportMasksIt() throws {
        let engine = try engine()
        let spend = try engine.perform(LogSpend(amount: 12.40, typed: "12.40", note: "lunch"), by: .user).output
        #expect(ObjectPrivacy.label(of: spend, in: store, classes: engine.classes) == "Private spend")
        let data = try TesseraExport(context: store.context).encoded()
        #expect(try ExportLeaks.found(["12.40", "lunch"], numbers: [12.4], in: data).isEmpty)
    }

    @Test func aTimestampThatReadsLikeTheAmountIsNotALeak() throws {
        // The export's dates carry fractional seconds, so "...:12.404Z" contains the characters "12.40". That made the
        // masking test above fail about once in a hundred runs although nothing leaked (Oct 22). Pin it.
        let engine = try engine()
        let spend = try engine.perform(LogSpend(amount: 12.40, typed: "12.40", note: "lunch"), by: .user).output
        spend.createdAt = Date(timeIntervalSince1970: 1_792_685_412.405) // 16:10:12.405 UTC
        let data = try TesseraExport(context: store.context).encoded()
        #expect(String(decoding: data, as: UTF8.self).contains("12.40")) // the characters are there, in a date
        #expect(try ExportLeaks.found(["12.40", "lunch"], numbers: [12.4], in: data).isEmpty)
        // And the helper does catch a real leak.
        let leaked = try TesseraExport(context: store.context, maskingPrivate: false).encoded()
        #expect(try !ExportLeaks.found(["12.40"], in: leaked).isEmpty)
    }

    // MARK: Ledger

    @Test func exactCentsNotDoubles() throws {
        let engine = try engine()
        for amount in ["0.10", "0.20"] {
            try engine.perform(
                LogSpend(amount: #require(Double(amount)), typed: amount, note: "coffee", spentAt: at(15, 9)),
                by: .user
            )
        }
        let ledger = SpendLedger(store: store, classes: engine.classes)
        #expect(ledger.monthLine(for: at(20, 12), calendar: calendar) == "October, logged: 2 spends · coffee 0.30")
    }

    @Test func aMixedMonthHasOneLinePerCurrencyAndNeverSumsAcross() throws {
        let engine = try engine()
        try engine.perform(LogSpend(amount: 312.40, typed: "312.40", note: "groceries", spentAt: at(2, 10)), by: .user)
        try engine.perform(LogSpend(amount: 86.10, typed: "86.10", note: "lunch", spentAt: at(3, 10)), by: .user)
        try engine.perform(LogSpend(amount: 5, typed: "5", note: "tea", spentAt: at(4, 10)), by: .user)
        for _ in 0 ..< 3 {
            try engine.perform(LogSpend(amount: 20, typed: "20 eur", currency: "EUR", note: "taxi", spentAt: at(5, 10)),
                               by: .user)
        }
        let line = SpendLedger(store: store, classes: engine.classes).monthLine(for: at(20, 12), calendar: calendar)
        #expect(line == "October, logged: 3 spends · groceries 312.40 · lunch 86.10\n€ 60.00 in 3 spends")
    }

    @Test func anEmptyMonthAndTheMonthsEdges() throws {
        let engine = try engine()
        let ledger = SpendLedger(store: store, classes: engine.classes)
        #expect(ledger.monthLine(for: at(20, 12), calendar: calendar) == "October: nothing logged yet")
        // 00:30 on 1 November is still October (the day turns at 4 am).
        let late = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 1, hour: 0, minute: 30)))
        try engine.perform(LogSpend(amount: 9, typed: "9.00", note: "cab", spentAt: late), by: .user)
        #expect(ledger.entries(inMonthOf: at(20, 12), calendar: calendar).count == 1)
        #expect(ledger.entries(inMonthOf: late.addingTimeInterval(6 * 3600), calendar: calendar).isEmpty)
    }

    // MARK: The groceries total

    func finishedShop(_ engine: ActionEngine, at finish: Date) throws {
        try engine.perform(AddGroceries(lines: ["milk"]), by: .user)
        try engine.perform(StartShop(time: finish.addingTimeInterval(-1800)), by: .user)
        try engine.perform(FinishShop(time: finish), by: .user)
    }

    @Test func theTotalIsAskedOnlyInsideTwoHours() throws {
        let engine = try engine()
        let finish = at(15, 17)
        try finishedShop(engine, at: finish)
        let receipt = ShopReceipt(store: store, classes: engine.classes)
        #expect(receipt.awaiting(at: finish.addingTimeInterval(1 * 3600 + 59 * 60)) != nil)
        #expect(receipt.awaiting(at: finish.addingTimeInterval(2 * 3600 + 60)) == nil)
        #expect(receipt.nowPrompt(at: finish.addingTimeInterval(600), calendar: calendar, somethingRuns: false)
            == "Groceries total?")
        #expect(receipt.nowPrompt(at: finish.addingTimeInterval(600), calendar: calendar, somethingRuns: true) == nil)
    }

    @Test func loggingTheTotalLinksTheShopAndEndsTheQuestion() throws {
        let engine = try engine()
        let finish = at(15, 17)
        try finishedShop(engine, at: finish)
        let logged = try engine.perform(
            LogShopTotal(amount: 38.20, typed: "38.20", time: finish.addingTimeInterval(300)),
            by: .user
        )
        #expect(logged.output.title == "38.20 Groceries" && logged.record.receipt == "Groceries, 38.20")
        #expect(store.value("category", of: logged.output)?.stringValue == "groceries")
        let receipt = ShopReceipt(store: store, classes: engine.classes)
        #expect(receipt.awaiting(at: finish.addingTimeInterval(400)) == nil)
        #expect(throws: ActionError.self) { try engine.perform(
            LogShopTotal(amount: 1, time: finish.addingTimeInterval(500)),
            by: .user
        ) }
    }

    @Test func skippingIsAskedOnceAndUndoBringsItBack() throws {
        let engine = try engine()
        let finish = at(15, 17)
        try finishedShop(engine, at: finish)
        let skipped = try engine.perform(SkipShopTotal(time: finish.addingTimeInterval(300)), by: .user)
        #expect(skipped.record.receipt == "Groceries total, skipped")
        let receipt = ShopReceipt(store: store, classes: engine.classes)
        #expect(receipt.awaiting(at: finish.addingTimeInterval(400)) == nil)
        engine.undo(skipped.record)
        #expect(receipt.awaiting(at: finish.addingTimeInterval(400)) != nil)
    }

    @Test func noQuestionWithoutAFinishedShop() throws {
        let engine = try engine()
        #expect(ShopReceipt(store: store, classes: engine.classes).awaiting(at: at(15, 17)) == nil)
    }
}
