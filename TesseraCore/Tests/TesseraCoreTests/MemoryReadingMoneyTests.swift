import Foundation
@testable import TesseraCore
import Testing

/// What the day's Spent and Read lines may become in Tess's memory.
@MainActor
struct MemoryReadingMoneyTests {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }()

    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    func recent() -> String? {
        let today = Date()
        let memory = TessMemoryStore(engine: engine, calendar: Self.calendar, forgetLogURL: nil)
        return memory.recentLine(for: TesseraDay(calendar: Self.calendar).day(of: today), now: today)
    }

    @Test func aReadingLineCanBeAMemoryLine() throws {
        let book = try engine.perform(QueueBook(title: "Dune", pages: 600), by: .user).output
        try engine.perform(StartReading(book: book.id), by: .user)
        try engine.perform(SetBookPage(book: book.id, page: 142), by: .user)
        #expect(recent()?.contains("read dune to p 142") == true)
    }

    @Test func aSpendLineNeverBecomesAMemoryLine() throws {
        // Two currencies give "Spent 2 times (lunch, cab)": no amount in it, so only the "Spent" guard stops it.
        try engine.perform(LogSpend(amount: 8, typed: "€8", currency: "EUR", note: "lunch"), by: .user)
        try engine.perform(LogSpend(amount: 4.5, typed: "£4.50", currency: "GBP", note: "cab"), by: .user)
        let today = Date()
        let day = DayStory.lines(engine: engine, on: today, calendar: Self.calendar, now: today).map(\.text)
        #expect(day.contains { $0.hasPrefix("Spent 2 times") })
        // The whole day is money, so nothing is left to remember. (The "Spent" guard backs up the money wall; the
        // two together keep this nil, and a leak of either shows as a line.)
        #expect(recent() == nil)
    }

    @Test func aSpendWithAWalledWordNextToABookWithAWalledTitleLeavesNeitherInMemory() throws {
        try engine.perform(LogSpend(amount: 90, typed: "90", note: "lexapro refill"), by: .user)
        let book = try engine.perform(QueueBook(title: "Therapy workbook", pages: 100), by: .user).output
        try engine.perform(SetBookPage(book: book.id, page: 30), by: .user)
        try engine.perform(QueueBook(title: "Dune", pages: 600), by: .user)
        let today = Date()
        let day = DayStory.lines(engine: engine, on: today, calendar: Self.calendar, now: today).map(\.text)
        #expect(!day.contains { $0.lowercased().contains("lexapro") || $0.lowercased().contains("therapy") })
        let text = recent()?.lowercased() ?? ""
        #expect(!text.contains("lexapro") && !text.contains("therapy") && !text.contains("private book"))
    }
}
