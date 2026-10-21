import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// Money screens (huddle batch 7, row B7): the month line, the receipt line, the page captures, and amounts drawn
/// through MeasureView.
@MainActor
struct MoneyCopyTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel

    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }

    init() {
        model = AppModel(context: container.mainContext)
    }

    func at(_ day: Int, _ hour: Int, _ minute: Int = 0, month: Int = 10) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
    }

    private func spend(_ typed: String, _ note: String, currency: String? = nil, on date: Date) throws {
        let amount = try #require(MoneyAmount.parse(typed))
        try model.engine.perform(LogSpend(amount: NSDecimalNumber(decimal: amount.amount).doubleValue, typed: typed,
                                          currency: currency, note: note, spentAt: date), by: .user)
    }

    private func sentence(on date: Date) -> [String] {
        MoneyCopy.monthSentence(SpendLedger(store: model.store, classes: model.classes)
            .entries(inMonthOf: date, calendar: calendar))
    }

    // MARK: The month line

    @Test func theMonthSentenceNamesTheTopTwoWithTheirTotalsAndOtherCurrenciesAsAlso() throws {
        try spend("12.40", "lunch", on: at(15, 13))
        try spend("12.40", "lunch", on: at(13, 13))
        try spend("4.50", "coffee", on: at(15, 9))
        try spend("4.50", "coffee", on: at(13, 9))
        try spend("6.50", "taxi", on: at(9, 18))
        try spend("$38.20", "groceries", currency: "USD", on: at(14, 17))
        try spend("€8", "museum", currency: "EUR", on: at(3, 11))
        #expect(sentence(on: at(16, 12)) == [
            "5 spends. Most went to lunch, 24.80, and coffee, 9.00.",
            "Also €8.00 in 1 spend.",
            "Also $38.20 in 1 spend.",
        ])
    }

    @Test func exactCentsAndOneWordAndAnEmptyMonth() throws {
        #expect(sentence(on: at(16, 12)) == ["Nothing logged yet."])
        try spend("0.10", "coffee", on: at(2, 9))
        try spend("0.20", "coffee", on: at(3, 9))
        #expect(sentence(on: at(16, 12)) == ["2 spends. Most went to coffee, 0.30."])
        try spend("5", "", on: at(4, 9))
        #expect(sentence(on: at(16, 12)).first == "3 spends. Most went to coffee, 0.30.")
    }

    @Test func theContextLineCountsHisDays() {
        #expect(MoneyCopy.context(now: at(16, 12), calendar: calendar) == "October, 16 days in")
        // 2 am on Nov 1 is still Oct 31 on his day.
        #expect(MoneyCopy.context(now: at(1, 2, month: 11), calendar: calendar) == "October, 31 days in")
        #expect(MoneyCopy.context(now: at(1, 9, month: 11), calendar: calendar) == "November, 1 day in")
    }

    @Test func spokenAmountsAndLedgerLinesNeverReadTheDrawnForm() throws {
        #expect(try MoneyCopy.spoken(#require(Decimal(string: "12.40")), currency: nil) == "12 dollars 40")
        #expect(MoneyCopy.spoken(Decimal(8), currency: "EUR") == "8 euros")
        #expect(try MoneyCopy.spoken(#require(Decimal(string: "1.05")), currency: "GBP") == "1 pound 5")
        #expect(try MoneyCopy.spokenLine(day: at(15, 12), word: "lunch", amount: #require(Decimal(string: "12.40")),
                                         currency: nil, calendar: calendar) == "Oct 15, lunch, 12 dollars 40")
        #expect(MoneyCopy.currencyHeading("USD") == "In dollars")
    }

    @Test func theSpendPageLineUsesTheHouseClockAndUSDates() {
        #expect(MoneyCopy.spendContext(note: "lunch", spentAt: at(15, 13, 10), calendar: calendar)
            == "lunch, Thu Oct 15, 1:10 pm")
        #expect(MoneyCopy.currencyLine(nil) == "In no currency." && MoneyCopy.currencyLine("EUR") == "In euros.")
        #expect(MoneyCopy.deleteName("12.40 lunch") == "Delete 12.40 lunch")
        #expect(AreaUndo.label("12.40 lunch, logged.") == "Undo 12.40 lunch")
    }

    @Test func theMoneyFrontGroupsByCurrencyThenDayAndShowsAmountsAsTyped() throws {
        try spend("12.40", "lunch", on: at(15, 13))
        try spend("€8", "museum", currency: "EUR", on: at(3, 11))
        let front = MoneyFront(store: model.store, classes: model.classes, now: at(16, 12), calendar: calendar)
        #expect(front.groups.map(\.heading) == [nil, "In euros"])
        #expect(front.groups.first?.days.first?.label == "Oct 15")
        #expect(front.groups.last?.days.first?.lines.first?.amount == "€8")
        #expect(front.groups.first?.days.first?.lines.first?.spoken == "Oct 15, lunch, 12 dollars 40")
    }

    // MARK: Captures

    @Test func thePageReadsSpentPhrases() throws {
        let one = try #require(MoneyCapture.spend("spent 12.40 on lunch"))
        #expect(one.typed == "12.40" && one.note == "lunch" && one.currency == nil)
        let two = try #require(MoneyCapture.spend("20 eur taxi"))
        #expect(two.typed == "20 eur" && two.currency == "EUR" && two.note == "taxi")
        #expect(MoneyCapture.spend("450 groceries")?.note == "groceries")
        #expect(MoneyCapture.spend("lunch") == nil && MoneyCapture.spend("spent the day") == nil)
    }

    // MARK: The receipt line

    @Test func theReceiptLineAsksOnceAndSaysWhereItCameFrom() throws {
        #expect(MoneyCopy.totalPrompt == "Groceries total?")
        #expect(MoneyCopy.totalContext(endedAt: at(15, 17, 40), calendar: calendar) == "From the 5:40 pm shop.")
        #expect(MoneyCopy.totalContext(endedAt: at(15, 19), calendar: calendar) == "From the 7 pm shop.")
        #expect(MoneyCopy.skipName == "Skip the Groceries total")
        let total = try #require(MoneyCapture.total("$38.20"))
        #expect(total.typed == "$38.20" && total.currency == "USD")
        #expect(MoneyCapture.total("no") == nil)
    }



    @Test func aSpendInHistoryAndInUndoShowsNoAmountAwayFromMoney() throws {
        let done = try model.engine.perform(LogSpend(amount: 12.40, typed: "12.40", note: "lunch"), by: .user)
        // History, links and backlinks read the object through the mask.
        #expect(ObjectMask.label(of: done.output, in: model.store, classes: model.classes) == "Private spend")
        let away = AreaPrivacy.spendLine(done.record.receipt ?? "", onMoneyPage: false)
        #expect(away == "Private spend, logged." && AreaUndo.label(away) == "Undo Private spend")
        #expect(AreaPrivacy.spendLine("12.40 lunch, deleted.", onMoneyPage: false) == "Private spend, deleted.")
        // On the Month page the amount is the screen's data.
        #expect(AreaPrivacy.spendLine(done.record.receipt ?? "", onMoneyPage: true) == "12.40 lunch, logged.")
        // The groceries total on Groceries and Now carries no amount, and neither does its UNDO key.
        #expect(!AreaPrivacy.shopTotalLogged.contains(where: \.isNumber))
        #expect(AreaUndo.label(AreaPrivacy.shopTotalLogged) == "Undo Groceries total")
    }

    @Test func areasStayHiddenByDefault() {
        #expect(!AreasShown.isOn || LaunchFlags.has("-areasAll"))
    }

    /// Design on Measure: an estimate reads whole units from 10 up and two decimals under 10.
    @Test func anEstimateRoundsByItsSize() {
        #expect(MeasureParts.estimate(24.8) == "25")
        #expect(MeasureParts.estimate(9.456) == "9.46")
        #expect(MeasureParts.estimate(10) == "10")
    }

    /// A spend's line carries its amount as a money measure in its own currency.
    @Test func aSpendLineCarriesItsMeasure() {
        #expect(Measure.money(12.4, currency: "EUR").kind == .money)
        #expect(Measure.money(12.4, currency: nil).unit.isEmpty)
    }
}
