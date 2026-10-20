import Foundation
@testable import TesseraCore
import Testing

/// The Day log lines for spends and books (ship-list-m5-money.md, ship-list-m5-reading.md: "the Day log line").
extension DayStoryTests {
    @Test func oneSpendReadsAmountThenWord() throws {
        try run(LogSpend(amount: 12.4, typed: "12.40", note: "lunch"), at: Self.at(14, 12))
        #expect(lines(Self.at(14, 12)) == ["12:00  Spent 12.40, lunch"])
    }

    @Test func severalSpendsAreOneLineWithTheExactTotal() throws {
        try run(LogSpend(amount: 12.4, typed: "12.40", note: "lunch"), at: Self.at(14, 12))
        try run(LogSpend(amount: 3.1, typed: "3.10", note: "coffee"), at: Self.at(14, 15))
        try run(LogSpend(amount: 11.4, typed: "11.40", note: "taxi home"), at: Self.at(14, 19))
        #expect(lines(Self.at(14, 20)) == ["12:00  Spent 3 times, 26.90 (lunch, coffee, taxi)"])
    }

    @Test func mixedCurrenciesHaveNoTotalAndNothingIsConverted() throws {
        try run(LogSpend(amount: 8, typed: "€8", currency: "EUR", note: "lunch"), at: Self.at(14, 12))
        try run(LogSpend(amount: 4.5, typed: "£4.50", currency: "GBP", note: "cab"), at: Self.at(14, 15))
        #expect(lines(Self.at(14, 20)) == ["12:00  Spent 2 times (lunch, cab)"])
    }

    @Test func aSpendOnAnotherDayIsNotThisDays() throws {
        try run(LogSpend(amount: 5, typed: "5", note: "tea"), at: Self.at(13, 12))
        #expect(lines(Self.at(14, 12)).isEmpty)
    }

    @Test func aWalledWordNeverReachesTheLine() throws {
        try run(LogSpend(amount: 90, typed: "90", note: "therapy"), at: Self.at(14, 12))
        let text = try #require(lines(Self.at(14, 12)).first)
        #expect(!text.contains("therapy"))
        #expect(text.contains("Spent 90"))
    }

    @Test func pagesReadAreOneLinePerBook() throws {
        let book = try run(QueueBook(title: "Dune", pages: 600), at: Self.at(14, 8)).output
        try run(StartReading(book: book.id, time: Self.at(14, 8)), at: Self.at(14, 8))
        try run(SetBookPage(book: book.id, page: 120, time: Self.at(14, 21)), at: Self.at(14, 21))
        try run(SetBookPage(book: book.id, page: 142, time: Self.at(14, 22)), at: Self.at(14, 22))
        #expect(lines(Self.at(14, 23)) == ["21:00  Read Dune to p 142"])
    }

    @Test func aFinishTakesTheBooksLineForTheDay() throws {
        let book = try run(QueueBook(title: "Dune", pages: 600), at: Self.at(14, 8)).output
        try run(StartReading(book: book.id, time: Self.at(14, 8)), at: Self.at(14, 8))
        try run(SetBookPage(book: book.id, page: 600, time: Self.at(14, 21)), at: Self.at(14, 21))
        try run(FinishBook(book: book.id, time: Self.at(14, 22)), at: Self.at(14, 22))
        #expect(lines(Self.at(14, 23)) == ["22:00  Finished Dune"])
    }

    @Test func aPrivateBookReadsPrivate() throws {
        let book = try run(QueueBook(title: "Dune", pages: 600), at: Self.at(14, 8)).output
        try run(EditBook(book: book.id, isPrivate: true), at: Self.at(14, 8, 5))
        try run(SetBookPage(book: book.id, page: 50, time: Self.at(14, 21)), at: Self.at(14, 21))
        #expect(lines(Self.at(14, 23)) == ["21:00  Read Private book to p 50"])
    }

    @Test func aRealStartPageKeepsTheFromTo() throws {
        let book = try run(QueueBook(title: "Dune", pages: 600), at: Self.at(14, 8)).output
        try run(StartReading(book: book.id, time: Self.at(14, 8)), at: Self.at(14, 8))
        try run(SetBookPage(book: book.id, page: 120, time: Self.at(13, 21)), at: Self.at(13, 21))
        try run(SetBookPage(book: book.id, page: 142, time: Self.at(14, 21)), at: Self.at(14, 21))
        #expect(lines(Self.at(14, 23)) == ["21:00  Read Dune, p 120 to 142"])
    }

    @Test func aCurrencySignSitsAgainstTheAmountAndNoCodeIsAdded() throws {
        try run(LogSpend(amount: 8, typed: "€8", currency: "EUR", note: "lunch"), at: Self.at(14, 12))
        try run(LogSpend(amount: 18.9, typed: "€18.90", currency: "EUR", note: "dinner"), at: Self.at(14, 19))
        #expect(lines(Self.at(14, 20)) == ["12:00  Spent 2 times, €26.90 (lunch, dinner)"])
        let other = try run(LogSpend(amount: 5, typed: "5 chf", currency: "CHF", note: "tea"), at: Self.at(15, 12))
        _ = other
        let text = try #require(lines(Self.at(15, 12)).first)
        #expect(!text.contains("CHF") && text.contains("Spent 5"))
    }

    @Test func anUnflaggedBookWithAWalledWordReadsPrivate() throws {
        let book = try run(QueueBook(title: "Therapy workbook", pages: 100), at: Self.at(14, 8)).output
        try run(SetBookPage(book: book.id, page: 30, time: Self.at(14, 21)), at: Self.at(14, 21))
        let text = try #require(lines(Self.at(14, 23)).first)
        #expect(text == "21:00  Read Private book to p 30" && !text.contains("Therapy"))
    }
}
