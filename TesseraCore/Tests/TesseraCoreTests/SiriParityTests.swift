import AppIntents
import Foundation
@testable import TesseraCore
@testable import TesseraIntents
@testable import TesseraTess
import Testing

/// Research's Siri privacy parity fixture (docs/research/fixtures/siri-privacy-parity.md, P14 and the 12:30 PM PT
/// rulings): one phrase lands as one kind of object on the Ask bar, Tell Tess and Add a Task, and Siri never speaks a
/// walled phrase. Every value is a made-up placeholder.
@MainActor
struct SiriParityTests {
    static let la = TimeZone(identifier: "America/Los_Angeles")!

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = la
        return calendar
    }

    /// Thu Oct 15 2026, 6:00 pm in Los Angeles.
    static let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 15, hour: 18))!

    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine
    let claude = SecretWordsTests.Spy(route: .claude)

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        engine.zone = { Self.la }
    }

    /// Ask (ghost rows) or Tell (committed at once): the same pipeline.
    func say(_ phrase: String, tell: Bool = false) async -> TessCapture {
        let tess = TessCaptureEngine(engine: engine)
        let router = TessRouter(engine: engine, models: [GrammarTessModel(capture: tess), claude])
        let context = TessContext(now: Self.now, calendar: Self.calendar, commitImmediately: tell)
        return await router.run(TessRequest(text: phrase, context: context, use: .capture))
    }

    func add(_ phrase: String) throws -> String {
        try CreateTaskIntent.add(phrase, startsAt: nil, engine: engine)
    }

    /// No object of his anywhere holds the private words.
    func nothingHolds(_ words: String) -> Bool {
        !store.context.objects.values.contains { $0.title.localizedCaseInsensitiveContains(words) }
    }

    /// S1 to S17, S27 to S30: body facts and secrets are private notes everywhere.
    @Test(arguments: [
        "took advil 400mg", "take advil 400mg at 9 pm", "took advil 400mg yesterday", "bp 128/82", "resting hr 52",
        "slept 6 hours", "slept 6 hours last night", "weigh 82.4 kg", "weighed 82.4 kg this morning", "knee hurts",
        "knee hurts tonight", "wifi password tacocat", "wifi password is tacocat", "PIN 4417", "door code 4417",
        "reset my PIN",
    ])
    func privateEverywhere(_ phrase: String) async throws {
        let ask = await say(phrase)
        let tell = await say(phrase, tell: true)
        let siri = try add(phrase)
        for line in [ask.line, tell.line, siri] {
            #expect(line == "Private note, kept.", "\(phrase): \(line)")
        }
        #expect(ask.records.map(\.action) == ["createNote"] && tell.records.map(\.action) == ["createNote"])
        #expect(claude.heard.isEmpty)
    }

    /// S18 to S21: money never reaches Claude or the miss log; with something to do and a day, a task said back
    /// without its words; without a day, Siri files a private note.
    @Test func money() async throws {
        for phrase in ["pay rent $1,800", "paid 40 for gas"] {
            let ask = await say(phrase)
            #expect(!ask.line.contains("1,800") && !ask.line.contains("40"), "\(phrase): \(ask.line)")
            #expect(try add(phrase) == "Private note, kept.", "\(phrase)")
        }
        let ask = await say("pay rent 1800 friday")
        // Product 8:09 PM PT: named as stored, its amount gone ("Pay rent, Fri.").
        #expect(ask.records.map(\.action) == ["createTask"] && ask.line == "Pay rent, tomorrow 9 am.",
                "\(ask.records.map(\.action)) \(ask.line) \(ask.source)")
        let tell = await say("pay rent 1800 friday", tell: true)
        #expect(tell.line == "Pay rent, tomorrow 9 am.")
        let siri = try add("pay rent 1800 friday")
        #expect(siri.contains("Pay rent") && !siri.contains("1800"), "\(siri)")
        // A stored title that is still private keeps the private line (S18).
        let refill = try add("refill lexapro 40 dollars friday")
        #expect(!refill.lowercased().contains("lexapro") && !refill.contains("40"), "\(refill)")
        #expect(claude.heard.isEmpty)
    }

    @Test func paidWithADayIsAPrivateDatedNoteEverywhere() async throws {
        // Product 1:15 PM PT: "paid rent 2100 fri" is a private note on Friday on the Bar, from Tess and from Siri.
        // Said on Thursday Oct 15 in the past tense, "fri" is last Friday, Oct 9.
        let friday = try #require(Self.calendar.date(from: DateComponents(year: 2026, month: 10, day: 9, hour: 12)))
        for capture in await [say("paid rent 2100 fri"), say("paid rent 2100 fri", tell: true)] {
            #expect(capture.line == "Private note, kept." && capture.records.map(\.action) == ["createNote"])
        }
        #expect(try add("paid rent 2100 fri") == "Private note, kept.")
        let notes = store.context.objects.values.filter { $0.title == SecretWords.title }
        #expect(notes.count == 3 && notes.allSatisfy { store.value("isPrivate", of: $0) == .bool(true) })
        // Dated on that day, on the Bar and for Siri alike.
        let grammar = TessGrammar(store: store, classes: engine.classes)
        let context = TessContext(now: Self.now, calendar: Self.calendar)
        for parse in [grammar.parse("paid rent 2100 fri", context: context),
                      grammar.privateParse("paid rent 2100 fri", context: context)]
        {
            guard case let .privateNote(_, _, on)? = parse, let on else {
                Issue.record("not a dated private note")
                continue
            }
            #expect(TesseraDay(calendar: Self.calendar).isSameDay(on, friday), "\(on.formatted(.iso8601))")
        }
        #expect(nothingHolds("2100") && claude.heard.isEmpty)
    }

    /// S22, S24 to S26, S32 to S33, S35: ordinary things stay as they were; a task with a secret word is said back
    /// without its title.
    @Test func ordinaryAndHiddenTasks() async throws {
        #expect(await say("pay rent friday").records.map(\.action) == ["createTask"])
        #expect(try add("pay rent friday").lowercased().contains("pay rent"))
        #expect(try add("pay rent").lowercased().contains("pay rent"))
        #expect(try add("call mom").lowercased().contains("call mom"))
        #expect(await say("buy milk").records.map(\.action) == ["addGroceries"])
        #expect(try add("buy milk").lowercased().contains("buy milk"))
        let pin = await say("PIN reset friday 3 pm", tell: true)
        #expect(pin.records.map(\.action) == ["createTask"] && pin.line == "Task added for tomorrow.",
                "\(pin.records.map(\.action)) \(pin.line) \(pin.source)")
        #expect(try add("PIN reset friday 3 pm").hasPrefix("Task added"))
        #expect(await say("dentist thu 3 pm").records.map(\.action) == ["createTask"])
        #expect(try add("dentist thu 3 pm").lowercased().contains("dentist"))
    }

    @Test func nothingPrivateIsKeptInHisWords() async throws {
        for phrase in ["took advil 400mg", "wifi password tacocat", "pay rent $1,800"] {
            _ = await say(phrase)
            _ = try add(phrase)
        }
        #expect(nothingHolds("advil") && nothingHolds("tacocat") && nothingHolds("1,800"))
    }

    @Test func theLockScreenSetButtonsNeverAskForFaceID() {
        // Design on #534 (Product 12:26 PM PT): the Live Activity's Done and UNDO work without unlocking.
        for policy in [LogNextSetIntent.authenticationPolicy, UndoLastSetIntent.authenticationPolicy] {
            guard case .alwaysAllowed = policy else {
                Issue.record("a Lock Screen set button asks for Face ID")
                continue
            }
        }
    }
}
