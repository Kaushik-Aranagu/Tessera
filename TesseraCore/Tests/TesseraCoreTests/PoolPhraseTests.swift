import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Money pools phrases (PR 2b): on the phone, behind the switch, never on a bare "got".
@MainActor
struct PoolPhraseTests {
    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine
    let grammar: TessGrammar
    let on = TessContext(now: TesseraDayTests.at(10, 15, 18, 10), calendar: TesseraDayTests.calendar, moneyPools: true)
    let off = TessContext(now: TesseraDayTests.at(10, 15, 18, 10), calendar: TesseraDayTests.calendar)
    let checking: ObjectRecord
    let india: ObjectRecord

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        grammar = TessGrammar(store: store, classes: engine.classes)
        checking = try engine.perform(CreatePool(name: "US checking"), by: .user).output
        india = try engine.perform(CreatePool(name: "India account", currency: "INR"), by: .user).output
    }

    func read(_ phrase: String, _ context: TessContext? = nil) -> String {
        switch grammar.parse(phrase, context: context ?? on) {
        case nil: "nil"
        case let .inflow(amount, source, pool, note)?:
            "inflow \(amount.amount) \(amount.currency ?? "-") \(source) \(pool == india.id ? "india" : pool == checking.id ? "checking" : "-") [\(note)]"
        case let .poolMove(from, destination, sent, arrived, fee)?:
            "move \(from == checking.id ? "checking" : "other") > \(destination == india.id ? "india" : "other") "
                + "\(sent.amount) \(arrived.amount) \(fee.map { "\($0.amount)" } ?? "-")"
        case let .spend(amount, note, _)?: "spend \(amount.amount) \(amount.currency ?? "-") [\(note)]"
        case let parse?: "other \(parse)".prefix(14).description
        }
    }

    @Test(arguments: [
        ("got 3200 paycheck", "inflow 3200 - paycheck - []"),
        ("got 500 rupees", "inflow 500 INR paycheck - []"),
        ("got 40 gift", "inflow 40 - gift - []"),
        ("received 120 refund", "inflow 120 - refund - []"),
        ("got 1500 freelance", "inflow 1500 - freelance - []"),
        ("got 200 in US checking", "inflow 200 - paycheck checking []"),
        ("got 82650 into India", "inflow 82650 - paycheck india []"),
    ])
    func theInflowPhrases(_ phrase: String, _ expected: String) {
        #expect(read(phrase) == expected)
    }

    @Test func aMoveNeedsAPoolWhatArrivedAndReadsTheFee() throws {
        // The checking pool was used last for dollars.
        try engine.perform(LogInflow(amount: "5000", pool: checking.id), by: .user)
        #expect(read("moved 1000 to India, got 82650, fee 5") == "move checking > india 1000 82650 5")
        #expect(read("moved 1000 to India, got 82650") == "move checking > india 1000 82650 -")
        #expect(read("moved 1000 from US checking to India, got 82650") == "move checking > india 1000 82650 -")
        // No arrival, no destination, a destination that is not a pool, or two pools the same: nothing is read.
        for phrase in ["moved 1000 to India", "moved 1000, got 82650", "moved 1000 to Mars, got 5",
                       "moved 1000 to US checking, got 1000", "moved the car to India"]
        {
            #expect(read(phrase) == "nil", "\(phrase)")
        }
    }

    @Test func spokenSpendsStillReadAsSpends() {
        #expect(read("spent 450 rupees coffee") == "spend 450 INR [coffee]")
    }

    @Test(arguments: [
        "got milk", "got it", "got 20 minutes", "got 5 kg", "got a refund", "got up at 6", "got 3 tickets",
        "got 2 hours of sleep", "got home at 6", "got 100 reps", "got 5 stars", "got 1 day off", "got the paycheck",
        "got 3", "got paid", "earned a gift",
    ])
    func commonNonMoneyGotSentencesLogNothing(_ phrase: String) {
        let parsed = read(phrase)
        #expect(!parsed.hasPrefix("inflow"), "\(phrase) read as \(parsed)")
    }

    @Test func withTheSwitchOffNothingIsRead() {
        for phrase in ["got 3200 paycheck", "got 500 rupees", "moved 1000 to India, got 82650"] {
            let parsed = read(phrase, off)
            #expect(!parsed.hasPrefix("inflow") && !parsed.hasPrefix("move"), "\(phrase) read as \(parsed)")
        }
    }

    @Test func aWalledPoolNameIsNeverMatchedFromSpeech() throws {
        let secret = try engine.perform(CreatePool(name: "Ozempic dose", currency: "EUR"), by: .user).output
        _ = secret
        #expect(!read("got 20 into Ozempic").hasPrefix("inflow"))
    }

    @Test func aLogShowsItsReceiptAndOneUndoAndNeverReachesClaude() async throws {
        try engine.perform(LogInflow(amount: "1", pool: checking.id), by: .user)
        let capture = TessCaptureEngine(engine: engine)
        let result = await capture.capture("got 3200 paycheck", context: on)
        #expect(result.source == .grammar && result.records.count == 1, "\(result.line)")
        #expect(result.line == "Got $3,200.00, paycheck.")
        let record = try #require(result.records.first)
        #expect(PoolBook(store: store, classes: engine.classes).balance(of: checking) == 3201)
        engine.undo(record)
        #expect(PoolBook(store: store, classes: engine.classes).balance(of: checking) == 1)
        let move = await capture.capture("moved 1000 to India, got 82650, fee 5", context: on)
        #expect(move.line == "Moved $1,000.00, got INR 82,650.00." && move.source == .grammar)
        #expect(PoolBook(store: store, classes: engine.classes).balance(of: india) == 82650)
        // A spend lands in the pool used last for its currency while the switch is on.
        let spend = await capture.capture("spent 450 rupees coffee", context: on)
        #expect(spend.records.count == 1)
        #expect(PoolBook(store: store, classes: engine.classes).balance(of: india) == 82200)
    }
}
