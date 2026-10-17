import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// After #451 (Product on QA L1 and L3, the v9 pin script's W rows, decisions 12:04 PM PT Oct 16): health with no
/// number stays on the phone as a private note, "paid" or "spent" with an amount is always money, a bare spend verb
/// is a task or a note again, and a secret word in a shopping shape stays on Groceries.
@MainActor
struct PrivacyFollowupTests {
    static let la = TimeZone(identifier: "America/Los_Angeles")!

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = la
        return calendar
    }

    static let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 15, hour: 18))!

    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine
    let claude = SecretWordsTests.Spy(route: .claude)

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        engine.zone = { Self.la }
    }

    func run(_ phrase: String) async -> TessCapture {
        let tess = TessCaptureEngine(engine: engine)
        let router = TessRouter(engine: engine, models: [GrammarTessModel(capture: tess), claude])
        return await router.run(TessRequest(text: phrase, context: TessContext(now: Self.now, calendar: Self.calendar),
                                            use: .capture))
    }

    @Test(arguments: ["slept badly", "knee hurts", "headache", "body fat 18%", "resting heart rate 58", "feeling sick",
                      "feeling sick, no gym", "sick today", "i'm sick, skip push", "feeling unwell"])
    func healthWithNoNumberIsAPrivateNote(_ phrase: String) async {
        #expect(PrivateFacts.isWalled(phrase), "\(phrase)")
        let result = await run(phrase)
        #expect(result.line == "Private note, kept.", "\(phrase): \(result.line)")
        #expect(claude.heard.isEmpty)
    }

    @Test(arguments: [
        "bench 80 x 8",
        "knee day at the gym",
        "sick of meetings",
        "that set was sick",
        "sick set on bench",
        "that workout was sick",
        "sick of rice, buy pasta",
        "sick of this",
        "sick beat",
        "weigh the flour 500 g",
        "Costco run saturday",
        "budget meeting 3pm",
        "pay rent fri 7:30"
    ])
    func nearMissesStayUnwalled(_ phrase: String) {
        #expect(!PrivateFacts.isWalled(phrase), "\(phrase)")
    }

    @Test(arguments: ["paid 20 for 2 tickets", "spent 40 for 2 of us", "$212.37 at Costco", "paid rent 2100",
                      "venmo sam 25 for pizza", "checking is at 3,412", "182.4 lb this morning",
                      "weighed in at 83 kg", "bp 128/82", "slept 5 hours", "took 2 advil"])
    func theV9WallRowsNeverReachClaude(_ phrase: String) async {
        #expect(PrivateFacts.isWalled(phrase), "\(phrase)")
        _ = await run(phrase)
        #expect(claude.heard.isEmpty)
    }

    @Test func rememberingASumOfMoneyIsRefusedOnThePhone() async {
        // v9 W10.
        let result = await run("remember my rent is 2100")
        #expect(result.line == "I don't keep sums of money." && result.records.isEmpty && claude.heard.isEmpty)
    }

    @Test func aBareSpendVerbIsATaskOrANoteAgain() async {
        // #298 regression (Product, decisions 12:04 PM PT Oct 16).
        #expect(!TessGrammar.isMoney("pay rent fri") && TessGrammar.isMoney("pay rent 2100 fri"))
        #expect(await run("pay rent fri").records.map(\.action) == ["createTask"])
        #expect(await run("paid rent fri").records.map(\.action) == ["createNote"])
        #expect(await run("bought milk sat").records.map(\.action) == ["createNote"])
        #expect(claude.heard.isEmpty)
    }

    @Test func aSecretWordInAShoppingShapeStaysOnGroceries() async {
        // Research 139: no value, so the list shape wins; still grammar only.
        #expect(await run("buy pins").records.map(\.action) == ["addGroceries"])
        #expect(await run("get a combination lock").records.map(\.action) == ["addGroceries"])
        #expect(claude.heard.isEmpty)
        #expect(await run("door code 4417").line == "Private note, kept.")
    }

    @Test func aClaudeKeyNeverBecomesANote() throws {
        // QA B1 (backups review): the key would ride in every backup and iCloud copy.
        #expect(throws: ActionError.self) {
            try engine.perform(CreateNote(body: "sk-ant-api03-TEST-notes"), by: .user)
        }
        #expect(throws: ActionError.self) {
            try engine.perform(CreateNote(body: "my key\nsk-ant-api03-TEST-notes"), by: .user)
        }
        let note = try engine.perform(CreateNote(body: "router in the hall"), by: .user).output
        #expect(throws: ActionError.self) {
            try engine.perform(EditNote(note: note.id, body: "router in the hall sk-ant-api03-TEST", title: nil),
                               by: .user)
        }
        #expect(store.value("body", of: note)?.stringValue == "router in the hall")
        #expect(!store.context.objects.values.contains { $0.title.contains("sk-ant") })
        #expect(withoutClaudeKeys("key: sk-ant-api03-TEST done") == "key:  done")
        #expect(TessRouter.keyLine == claudeKeyLine)
    }

    @Test func pastTenseWithNoAmountIsAnOrdinaryDatedNote() async throws {
        // Product, 12:21 PM PT Oct 16 (board 0j): the past-tense log wins over W4; not a task, not private.
        for phrase in ["paid rent fri", "bought milk sat"] {
            let result = await run(phrase)
            #expect(result.records.map(\.action) == ["createNote"], "\(phrase)")
            let id = try #require(result.records.first?.objectIDs.first)
            let note = try #require(store.object(id: id))
            #expect(store.value("isPrivate", of: note) == nil && note.title != SecretWords.title, "\(phrase)")
        }
    }

    @Test func aDatedBodyFactIsAPrivateNoteUnlessItIsSomethingToDo() async {
        // QA R1 on #471.
        #expect(await run("headache since tuesday").line == "Private note, kept.")
        #expect(await run("call the doctor about my knee thu 3pm").records.map(\.action) == ["createTask"])
        #expect(claude.heard.isEmpty)
    }

    @Test func boughtWithACountIsNotMoney() {
        // QA R2 on #471: "bought" is shopping said after the fact; only paid or spent with an amount is money.
        #expect(!PrivateFacts.isWalled("bought 2 lemons") && !TessGrammar.isMoney("bought 2 lemons"))
        #expect(PrivateFacts.isWalled("bought lemons for $4"))
    }

    @Test func boughtSomethingForAnAmountIsMoney() async {
        // QA F2 on #534: "bought … for N" is a spend; with a day it is a private note on that day.
        #expect(PrivateFacts.isWalled("bought a tv for 800"))
        let dated = await run("bought a tv for 800 sat")
        #expect(dated.line == "Private note, kept." && dated.records.map(\.action) == ["createNote"], "\(dated.line)")
        #expect(claude.heard.isEmpty)
    }

    @Test func aKeySplitAcrossLinesComesOutWhole() {
        // QA R4 on #471. Built at run time and plainly fake, so nothing key-shaped is committed (#487).
        let prefix = ["sk", "ant", "TEST"].joined(separator: "-")
        let cleaned = withoutClaudeKeys("my key \(prefix)-FAKE1\nFAKEFAKE2 then the rest")
        #expect(!cleaned.contains(prefix) && !cleaned.contains("FAKEFAKE2") && cleaned.contains("then the rest"))
        #expect(withoutClaudeKeys("key: sk-ant-api03-TEST done") == "key:  done")
    }

    @Test func pullUpsIsAnAlias() {
        #expect(TessGrammar.aliases["pull-ups"] == "pull-up")
    }
}
