import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Money slice 4: the phrases, the groceries total, the month answer, and the Now rule. Thu 15 Oct 2026, 18:10 in
/// Los Angeles.
@MainActor
struct MoneyPhrasesTests {
    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine
    let grammar: TessGrammar
    let context = TessContext(now: TesseraDayTests.at(10, 15, 18, 10), calendar: TesseraDayTests.calendar)

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        grammar = TessGrammar(store: store, classes: engine.classes)
    }

    func read(_ phrase: String) -> String {
        switch grammar.parse(phrase, context: context) {
        case nil: "nil"
        case let .spend(amount, note, on)?:
            "spend \(amount.typed)\(amount.currency.map { " " + $0 } ?? "") [\(note)]"
                +
                (on
                    .map {
                        " " + TesseraDayTests.calendar.dateComponents([.month, .day], from: $0).day.map(String.init)!
                    } ??
                    "")
        case let .shopTotal(amount)?: "total \(amount.typed)"
        case .skipShopTotal?: "skip"
        case let .ask(line)?: "ask \(line)"
        case let .task(title, _)?: "task \(title)"
        case .lift?: "lift"
        case .groceries?: "groceries"
        case let parse?: "\(parse)".prefix(12).description
        }
    }

    func finishedShop(at finish: Date) throws {
        try engine.perform(AddGroceries(lines: ["milk"]), by: .user)
        try engine.perform(StartShop(time: finish.addingTimeInterval(-1800)), by: .user)
        try engine.perform(FinishShop(time: finish), by: .user)
    }

    @Test(arguments: [
        ("spent 12.40 lunch", "spend 12.40 [lunch]"), ("spent 4.50 on coffee", "spend 4.50 [coffee]"),
        ("spent 12.40 for lunch", "spend 12.40 [lunch]"), ("12.40 lunch", "spend 12.40 [lunch]"),
        ("spent 20 eur taxi", "spend 20 eur EUR [taxi]"), ("€8 parking yesterday", "spend €8 EUR [parking] 14"),
        ("spent 30 dinner sat", "spend 30 [dinner] 10"), ("spent 8.50 bar", "spend 8.50 [bar]"),
        ("6.50 cab", "spend 6.50 [cab]"), ("paid rent 1200", "spend 1200 [rent]"),
        ("paid rent 1,200", "spend 1,200 [rent]"), ("paid 40 for gas", "spend 40 [gas]"),
        ("spent $23.47 at trader joe's sat", "spend $23.47 USD [trader joe's] 10"),
        ("spent 12.40", "spend 12.40 []"),
    ])
    func theLogPhrases(_ phrase: String, _ expected: String) {
        #expect(read(phrase) == expected)
    }

    @Test(arguments: [
        ("bench 82.50 x 8", "lift"), ("pay rent 650 fri", "task Pay rent 650"), ("milk, eggs, 2 lemons", "groceries"),
        ("spent the day at the beach sat", "task"), ("spent 2 hours on taxes", "nil"), ("38.20", "privateNote"),
        ("450 groceries", "nil"), ("12.40 lunch tomorrow", "task"),
    ])
    func notMoney(_ phrase: String, _ expected: String) {
        let got = read(phrase)
        #expect(got.hasPrefix(expected) || got == expected, "\(phrase): \(got)")
        #expect(!got.hasPrefix("spend") && !got.hasPrefix("total"), "\(phrase): \(got)")
    }

    @Test func aBareAmountIsATotalOnlyWhileOneIsAwaited() throws {
        #expect(read("38.20").hasPrefix("privateNote") && read("shop total 84.10") == "spend 84.10 [groceries]")
        try finishedShop(at: context.now.addingTimeInterval(-3600))
        #expect(read("38.20") == "total 38.20" && read("£38.20") == "total £38.20")
        #expect(read("shop total 84.10") == "total 84.10" && read("total 38.20") == "total 38.20")
        #expect(read("skip") == "skip" && read("no total") == "skip")
        // A spend with a word is still a spend.
        #expect(read("spent 12.40 lunch") == "spend 12.40 [lunch]")
    }

    @Test func receiptsNameTheThingFirstAndTheSignSitsAgainstTheAmount() async {
        let tess = TessCaptureEngine(engine: engine)
        let coffee = await tess.capture("spent 12.40 on coffee", context: context)
        #expect(coffee.line == "Coffee, 12.40." && coffee.records.map(\.action) == ["logSpend"])
        let euro = await tess.capture("€8 parking", context: context)
        #expect(euro.line == "Parking, €8.00.")
        let bare = await tess.capture("spent 12.40", context: context)
        #expect(bare.line == "Spent 12.40.")
        let walled = await tess.capture("spent 90 on lexapro", context: context)
        #expect(walled.line == "Private spend, 90.00." && !walled.line.lowercased().contains("lexapro"))
        // No copy claims that money never goes anywhere.
        #expect(![coffee, euro, bare, walled].contains { $0.line.lowercased().contains("never") })
    }

    @Test func theTotalIsLoggedLinkedAndSkippableOnce() async throws {
        let tess = TessCaptureEngine(engine: engine)
        try finishedShop(at: context.now.addingTimeInterval(-3600))
        let logged = await tess.capture("shop total 84.10", context: context)
        #expect(logged.line == "Groceries, 84.10." && logged.records.map(\.action) == ["logShopTotal"])
        // Asked once: it is not awaited any more.
        #expect(ShopReceipt(store: store, classes: engine.classes).awaiting(at: context.now) == nil)
        try finishedShop(at: context.now.addingTimeInterval(-600))
        let skipped = await tess.capture("skip", context: context)
        #expect(skipped.line == "Groceries total, skipped." && skipped.records.map(\.action) == ["skipShopTotal"])
        #expect(ShopReceipt(store: store, classes: engine.classes).awaiting(at: context.now) == nil)
    }

    @Test func theMonthQuestionIsAnsweredFromTheLogOnThePhone() async throws {
        let tess = TessCaptureEngine(engine: engine)
        for phrase in ["how much this month", "how much did I spend this month", "what have I spent this month"] {
            let empty = await tess.capture(phrase, context: context)
            #expect(empty.line == "October: nothing logged yet", "\(phrase): \(empty.line)")
        }
        try engine.perform(LogSpend(amount: 12.4, typed: "12.40", note: "lunch", spentAt: context.now), by: .user)
        try engine.perform(LogSpend(amount: 3.1, typed: "3.10", note: "coffee", spentAt: context.now), by: .user)
        let line = await tess.capture("how much this month", context: context).line
        #expect(line.hasPrefix("October, logged: 2 spends"), "\(line)")
        // A question about money that is not the month is not answered by this rule.
        #expect(read("how much is a stone in kg") == "nil" || !read("how much is a stone in kg")
            .hasPrefix("ask October"))
    }

    @Test func nowAsksForTheTotalAfterAShopAndTheAskCanBeSkipped() throws {
        let finish = context.now.addingTimeInterval(-1800)
        try finishedShop(at: finish)
        let picker = NowPicker(engine: engine)
        let calendar = TesseraDayTests.calendar
        let now = picker.pick(at: context.now, calendar: calendar).now
        #expect(now?.title == "Groceries total?" && now?.kind == .offer)
        // Skipped: it goes and does not return.
        try engine.perform(SkipShopTotal(time: context.now), by: .user)
        #expect(picker.pick(at: context.now, calendar: calendar).now?.title != "Groceries total?")
        // Outside quiet hours only: at 23:30 it stays quiet.
        let late = TesseraDayTests.at(10, 15, 23, 30)
        try finishedShop(at: late.addingTimeInterval(-600))
        #expect(picker.pick(at: late, calendar: calendar).now?.title != "Groceries total?")
    }

    @Test func thousandsReadAsThousands() {
        #expect(MoneyAmount.parse("1,000")?.amount == 1000 && MoneyAmount.parse("1,234.50")?
            .amount == Decimal(string: "1234.5"))
        #expect(MoneyAmount.parse("12,40")?.amount == Decimal(string: "12.4"))
    }
}
