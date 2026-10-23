import Foundation
@testable import TesseraCore
import Testing

/// Money pools, PR 3: totals, month, the about total and its rates, and the sentences (Part B, B4, B5 and B7).
@MainActor
struct PoolReportTests {
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

    func at(_ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
    }

    func report(now: Date? = nil, ecb: CurrencyRates? = nil, lakh: Bool = false) -> PoolReport {
        PoolReport(store: store, classes: engine.classes, ecb: ecb, now: now ?? at(10, 22), lakh: lakh)
    }

    @discardableResult
    func pool(_ name: String, _ currency: String = "USD", opening: String? = nil) throws -> ObjectRecord {
        try engine.perform(CreatePool(name: name, currency: currency, opening: opening), by: .user).output
    }

    // MARK: About total

    @Test func aboutTotalUsesTheMovesRateForRupees() throws {
        let checking = try pool("US checking", opening: "5000")
        let india = try pool("India account", "INR")
        try engine.perform(LogMove(from: checking.id, to: india.id, sent: "1000.00", arrived: "82650.00", fee: "5.00",
                                   at: at(10, 18)), by: .user)
        // Spend 912.60 USD out of checking and 64,250 rupees: leaves USD 5000 - 1005 - 912.60 = 3082.40... set up
        // instead:
        let report = report(now: at(10, 22))
        let totals = report.totals()
        #expect(totals.map(\.currency) == ["USD", "INR"])
        #expect(totals[0].text == "Dollars $3,995.00" && totals[1].text == "Rupees INR 82,650.00")
        // 82650 rupees at 1005/82650 dollars each is 1005 dollars: about 4,000.
        let about = report.about()
        #expect(about.dollars == 5000 && about.leftOut.isEmpty)
        #expect(report.aboutLines(calendar: calendar) == ["In dollars, about $5,000", "Rates from Oct 18."])
    }

    @Test func theSheetsExampleAbout1136() throws {
        // 912.60 in dollars, 18,400 rupees, and a move that set the rate: 1005 dollars left for 82650 rupees.
        let other = try pool("Other", opening: "2000")
        let abroad = try pool("Abroad", "INR")
        try engine.perform(LogMove(from: other.id, to: abroad.id, sent: "1000.00", arrived: "82650.00", fee: "5.00",
                                   at: at(10, 18)), by: .user)
        let rate = try #require(report().rate(to: "INR"))
        let rupees = PoolMath.rounded(rate.dollars * 18400, places: 2)
        #expect(abs(NSDecimalNumber(decimal: rupees).doubleValue - 223.73) < 0.02)
        #expect(try Int(truncating: NSDecimalNumber(decimal: PoolMath.rounded(
            #require(Decimal(string: "912.60")) + rupees,
            places: 0
        ))) == 1136)
    }

    @Test func usdOnlyIsExactAndSaysNoAboutLine() throws {
        try pool("US checking", opening: "912.60")
        let report = report()
        #expect(report.about().dollars == nil)
        #expect(report.aboutLines(calendar: calendar).isEmpty)
        #expect(report.totals().map(\.text) == ["Dollars $912.60"])
    }

    @Test func aCurrencyWithNoRateIsLeftOutAndNamed() throws {
        try pool("US checking", opening: "100")
        try pool("Euro pot", "EUR", opening: "50")
        let lines = report().aboutLines(calendar: calendar)
        #expect(lines == ["Euros are not in the total."])
        #expect(report().about().dollars == nil)
        // A currency with no word reads its code.
        try pool("Swiss", "CHF", opening: "5")
        #expect(report().aboutLines(calendar: calendar).contains("CHF is not in the total."))
    }

    @Test func theECBTableComesFirstThenTheOwnRate() throws {
        try pool("US checking", opening: "100")
        try pool("Euro pot", "EUR", opening: "100")
        try engine.perform(RecordRate(pair: "EUR/USD", value: "1.50", at: at(10, 1)), by: .user)
        // With no ECB table, the typed rate: 1.50 dollars a euro.
        #expect(report().about().dollars == 250)
        // With the ECB table (1 euro = 1.10 dollars) that wins.
        let ecb = CurrencyRates(rates: ["USD": 1.10], date: at(10, 20))
        let withECB = report(ecb: ecb)
        #expect(withECB.about().dollars == 210)
        #expect(withECB.aboutLines(calendar: calendar) == ["In dollars, about $210", "Rates from Oct 20."])
    }

    @Test func ratesOlderThanFourteenDaysSaySo() throws {
        try pool("US checking", opening: "100")
        try pool("India account", "INR", opening: "8300")
        try engine.perform(RecordRate(pair: "USD/INR", value: "83", at: at(9, 8)), by: .user)
        let lines = report(now: at(10, 22)).aboutLines(calendar: calendar)
        // 44 days old.
        #expect(lines == ["In dollars, about $200", "Rates from Sep 8.", "These rates are old."])
        // Fourteen days exactly is fine.
        let fresh = report(now: at(9, 22)).aboutLines(calendar: calendar)
        #expect(!fresh.contains("These rates are old."))
    }

    @Test func nothingIsEverFetchedAndLakhIsOffUnlessAsked() throws {
        try pool("India account", "INR", opening: "826500")
        #expect(report().totals().map(\.text) == ["Rupees INR 826,500.00"])
        #expect(report(lakh: true).totals().map(\.text) == ["Rupees INR 8,26,500.00"])
    }

    // MARK: Month

    @Test func theMonthCountsSpendsPerCurrencyExactly() throws {
        try engine.perform(LogSpend(amount: 0.10, typed: "0.10", spentAt: at(10, 3)), by: .user)
        try engine.perform(LogSpend(amount: 0.20, typed: "0.20", spentAt: at(10, 4)), by: .user)
        try engine.perform(LogSpend(amount: 450, typed: "450", currency: "INR", spentAt: at(10, 5)), by: .user)
        try engine.perform(LogSpend(amount: 9, typed: "9", spentAt: at(9, 30)), by: .user)
        let month = report().monthSpends(calendar: calendar)
        #expect(month["USD"] == Decimal(string: "0.30") && month["INR"] == 450 && month.count == 2)
    }

    @Test func twoAmOnTheFirstStillBelongsToTheMonthBefore() throws {
        try engine.perform(LogSpend(amount: 7, typed: "7", spentAt: at(10, 1, 2)), by: .user)
        try engine.perform(LogSpend(amount: 5, typed: "5", spentAt: at(10, 1, 5)), by: .user)
        #expect(report(now: at(10, 15)).monthSpends(calendar: calendar)["USD"] == 5)
        #expect(report(now: at(9, 15)).monthSpends(calendar: calendar)["USD"] == 7)
    }

    @Test func feesAreAPlainLinePerCurrency() throws {
        let checking = try pool("US checking", opening: "5000")
        let india = try pool("India account", "INR", opening: "100000")
        try engine.perform(
            LogMove(from: checking.id, to: india.id, sent: "1000", arrived: "82650", fee: "5", at: at(10, 18)),
            by: .user
        )
        try engine.perform(
            LogMove(from: india.id, to: checking.id, sent: "8300", arrived: "100", fee: "40", at: at(10, 19)),
            by: .user
        )
        #expect(report().feesLine(calendar: calendar) == "Fees this month: $5.00 and INR 40.00.")
        #expect(report(now: at(9, 15)).feesLine(calendar: calendar) == nil)
    }

    // MARK: Words

    @Test func belowZeroIsSaidOnceWithNoRed() throws {
        let checking = try pool("US checking", opening: "100")
        try engine.perform(LogSpend(amount: 220, typed: "220", pool: checking.id), by: .user)
        #expect(report().belowZero() == ["US checking is below zero by $120.00."])
        try pool("Fine", opening: "5")
        #expect(report().belowZero().count == 1)
    }

    @Test func theSentenceNamesOneOrTwoPoolsAndMasksAPrivateName() throws {
        #expect(report().sentence(nothingLate: true).text == "Nothing is late.")
        let checking = try pool("US checking", opening: "1345")
        #expect(report().sentence(nothingLate: true).text == "Nothing is late. US checking has $1,345.00.")
        try pool("India account", "INR", opening: "82650")
        #expect(report().sentence(nothingLate: true)
            .text == "$1,345.00 in US checking, INR 82,650.00 in India account.")
        let secret = try pool("Ozempic dose", opening: "1")
        _ = (checking, secret)
        let text = report().sentence(nothingLate: false).text
        #expect(!text.contains("Ozempic"))
    }

    @Test func newLinesAndTheMovePageReadAsTheSheetSays() throws {
        let checking = try pool("US checking", opening: "5000")
        let india = try pool("India account", "INR")
        let inflow = try engine.perform(LogInflow(amount: "3200", pool: checking.id), by: .user).output
        let move = try engine.perform(
            LogMove(from: checking.id, to: india.id, sent: "1000.00", arrived: "82650.00", fee: "5.00"),
            by: .user
        ).output
        let spend = try engine.perform(
            LogSpend(amount: 4.5, typed: "4.50", note: "coffee", pool: checking.id),
            by: .user
        ).output
        let report = report()
        #expect(report.newLine(for: inflow) == "US checking got $3,200.00, paycheck.")
        #expect(report.newLine(for: move) == "Moved $1,000.00, got INR 82,650.00.")
        #expect(report.newLine(for: spend) == "Coffee $4.50, US checking.")
        #expect(report.movePage(for: move)
            ==
            "You sent $1,000.00 and paid $5.00 in fees. You got INR 82,650.00. Your rate was 82.24 for a dollar after fees.")
    }

    @Test func aPrivatePoolIsMaskedInEveryLine() throws {
        let secret = try pool("Ozempic dose", opening: "100")
        let inflow = try engine.perform(LogInflow(amount: "50", pool: secret.id), by: .user).output
        let report = report()
        #expect(report.name(of: secret) == "Private pool")
        let line = try #require(report.newLine(for: inflow))
        #expect(line == "Private pool got $50.00, paycheck." && !line.contains("Ozempic"))
        #expect(report.sentence(nothingLate: false).text == "Private pool has $150.00.")
    }

    @Test func aSpendLineMasksWordByWordAndAnArchivedPoolIsSaidToCount() throws {
        let checking = try pool("US checking", opening: "100")
        let spend = try engine.perform(
            LogSpend(amount: 80, typed: "80", note: "ozempic pharmacy run", pool: checking.id),
            by: .user
        ).output
        let line = try #require(report().newLine(for: spend))
        #expect(line == "Private spend $80.00, US checking." && !line.lowercased().contains("ozempic"))
        #expect(report().archivedNote() == nil)
        try engine.perform(ArchivePool(pool: checking.id), by: .user)
        #expect(report().archivedNote() == "Archived pools are still counted.")
        #expect(report().totals().map(\.text) == ["Dollars $20.00"])
    }

    @Test func wholeDollarsAreFormattedDirectly() throws {
        #expect(try PoolFormat.wholeDollars(#require(Decimal(string: "1136.33"))) == "$1,136")
        #expect(try PoolFormat.wholeDollars(#require(Decimal(string: "1136.5"))) == "$1,137")
        #expect(PoolFormat.wholeDollars(-40) == "-$40" && PoolFormat.wholeDollars(0) == "$0")
        #expect(PoolFormat.wholeDollars(826_500, lakh: true) == "$8,26,500")
    }

    @Test func theMonthsMovesAreNewestFirstAndOnlyThisMonths() throws {
        let checking = try pool("US checking", opening: "5000")
        let india = try pool("India account", "INR")
        let first = try engine.perform(
            LogMove(from: checking.id, to: india.id, sent: "100", arrived: "8300", at: at(10, 3)),
            by: .user
        ).output
        let second = try engine.perform(
            LogMove(from: checking.id, to: india.id, sent: "100", arrived: "8300", at: at(10, 9)),
            by: .user
        ).output
        try engine.perform(
            LogMove(from: checking.id, to: india.id, sent: "100", arrived: "8300", at: at(9, 20)),
            by: .user
        )
        #expect(report().monthMoves(calendar: calendar).map(\.id) == [second.id, first.id])
        #expect(report(now: at(9, 25)).monthMoves(calendar: calendar).count == 1)
    }

    // MARK: Walls

    @Test func widgetsAndLiveActivitiesNeverMentionAPool() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        for folder in ["Widgets", "LiveActivity", "Widgets/Fonts"] {
            let directory = root.appending(path: folder)
            guard let files = try? FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil
            )
            else { continue }
            for file in files where file.pathExtension == "swift" {
                let text = try String(contentsOf: file, encoding: .utf8)
                for word in ["PoolBook", "PoolReport", "PoolFormat", "poolMove", "inflow"] {
                    #expect(!text.contains(word), "\(file.lastPathComponent) mentions \(word)")
                }
            }
        }
    }
}
