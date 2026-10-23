import Foundation
@testable import TesseraCore
import Testing

/// Together round 8, 160 moneyMonthV2: the month as one sentence, a line per pool, a level against last month.
@MainActor
struct MoneyMonthTests {
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

    func at(_ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 12))!
    }

    func report(_ month: Int = 10, _ day: Int = 20) -> PoolReport {
        PoolReport(store: store, classes: engine.classes, now: at(month, day))
    }

    @discardableResult
    func spend(_ amount: Double, _ typed: String, currency: String? = nil, pool: ObjectRecord? = nil, month: Int = 10,
               day: Int = 5) throws -> ObjectRecord
    {
        try engine.perform(
            LogSpend(amount: amount, typed: typed, currency: currency, spentAt: at(month, day), pool: pool?.id),
            by: .user
        ).output
    }

    @Test func nothingSpentSaysSo() {
        #expect(report().monthSentence(calendar: calendar) == "October, nothing spent.")
    }

    @Test func oneCurrencyIsExactAndHasNoAbout() throws {
        try spend(1240, "1240")
        try spend(12.5, "12.50", day: 6)
        #expect(report().monthSentence(calendar: calendar) == "October, spent 1,252.50 US.")
    }

    @Test func twoCurrenciesAreExactAndOneAboutWhenBothHaveARate() throws {
        try spend(1240, "1240")
        try spend(310, "310", currency: "EUR")
        // No rate yet: no "about".
        #expect(report().monthSentence(calendar: calendar) == "October, spent 1,240 US and 310 EUR.")
        let a = try engine.perform(CreatePool(name: "Euro card", currency: "EUR", opening: "100"), by: .user).output
        _ = a
        try engine.perform(RecordRate(pair: "EUR/USD", value: "1.25", at: at(10, 1)), by: .user)
        #expect(report().monthSentence(calendar: calendar)
            == "October, spent 1,240 US and 310 EUR, about 1,628 in all.")
    }

    @Test func aPastMonthKeepsItsYearOnlyWhenItIsAnotherYear() throws {
        try spend(40, "40", month: 9, day: 3)
        #expect(report().monthSentence(monthOf: at(9, 15), calendar: calendar) == "September, spent 40 US.")
        let last = try #require(calendar.date(from: DateComponents(year: 2025, month: 5, day: 12, hour: 12)))
        #expect(report().monthSentence(monthOf: last, calendar: calendar) == "May 2025, nothing spent.")
    }

    @Test func poolLinesShowTheBalanceAndTheMonthAgainstLast() throws {
        let checking = try engine.perform(CreatePool(name: "US checking", opening: "2100"), by: .user).output
        try spend(50, "50", pool: checking, month: 9, day: 4)
        try spend(25, "25", pool: checking, month: 10, day: 4)
        let line = try #require(report().poolLines(calendar: calendar).first)
        #expect(line.text == "US checking, 2,025.")
        #expect(line.spent == 25 && line.lastMonth == 50 && line.fill == 0.5)
        // No spend last month: no level.
        let fresh = try engine.perform(CreatePool(name: "Euro card", currency: "EUR", opening: "540"), by: .user).output
        _ = fresh
        let lines = report().poolLines(calendar: calendar)
        #expect(lines.first { $0.text.hasPrefix("Euro card") }?.fill == nil)
    }

    @Test func aBiggerMonthFillsTheTrackAndNoNamesOrAmountsEscapeToOtherSurfaces() throws {
        let card = try engine.perform(CreatePool(name: "Card", opening: "500"), by: .user).output
        try spend(10, "10", pool: card, month: 9, day: 4)
        try spend(90, "90", pool: card, month: 10, day: 4)
        #expect(report().poolLines(calendar: calendar).first?.fill == 1)
        // The Home sentence never carries an amount for the month.
        #expect(!report().sentence(nothingLate: false).text.contains("90"))
    }

    @Test func theScrubRangeRunsFromTheFirstToTheLastMonthWithASpend() throws {
        #expect(report().monthRange(calendar: calendar) == nil)
        try spend(1, "1", month: 7, day: 9)
        try spend(1, "1", month: 10, day: 9)
        let range = try #require(report().monthRange(calendar: calendar))
        #expect(calendar.component(.month, from: range.lowerBound) == 7)
        #expect(calendar.component(.month, from: range.upperBound) == 10)
    }
}
