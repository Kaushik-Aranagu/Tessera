import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Research's misfire sweep (docs/research/fixtures/grammar-misfires.md), the rows this hotfix covers, with Product's
/// calls (2026-10-15): bare hours 1 to 6 are pm and 7 to 11 the next one today; a passed time today lands tomorrow;
/// past-tense logs are notes dated that day; a clearly non-food "buy"/"get" is a task; "is …" asks.
/// Clock: Thu 15 Oct 2026, 18:00 Europe/London.
@MainActor
struct GrammarMisfireTests {
    enum Ctx: Sendable { case idle, workout, shopping }

    struct Row: Sendable, CustomTestStringConvertible {
        let phrase: String
        let ctx: Ctx
        let expect: String
        init(_ phrase: String, _ ctx: Ctx, _ expect: String) {
            self.phrase = phrase
            self.ctx = ctx
            self.expect = expect
        }

        var testDescription: String {
            "\(phrase) (\(ctx))"
        }
    }

    nonisolated static let rows: [Row] = [
        // Bare hours (RC1, RC9)
        .init("coffee with ravi at 7", .idle, "task Coffee with ravi Thu 15 19:00"),
        .init("call mum at 7", .workout, "task Call mum Thu 15 19:00"),
        .init("meet ravi at 6:30", .idle, "task Meet ravi Thu 15 18:30"),
        .init("pick up kids at 3", .idle, "task Pick up kids Fri 16 15:00"),
        .init("dinner tomorrow at 7", .idle, "task Dinner Fri 16 19:00"),
        .init("call mum thu at 8", .idle, "task Call mum Thu 15 20:00"),
        .init("call mum tonight at 9", .idle, "task Call mum Thu 15 21:00"),
        .init("call mum at 9 tonight", .idle, "task Call mum Thu 15 21:00"),
        .init("lunch at 12", .idle, "task Lunch Fri 16 12:00"),
        .init("wake me at 7", .idle, "task Wake me Fri 16 07:00"),
        .init("call mum thu 3pm", .idle, "task Call mum Thu 22 15:00"),
        .init("call mum 7pm", .idle, "task Call mum Thu 15 19:00"),
        .init("remind me to buy milk at 6", .idle, "task Buy milk Fri 16 18:00"),
        // Title leftovers (RC7)
        .init("dentist on friday", .idle, "task Dentist Fri 16 09:00"),
        .init("remind me tomorrow to call mum", .idle, "task Call mum Fri 16 09:00"),
        .init("call mum, thu", .idle, "task Call mum Thu 15 19:00"),
        // Past-tense logs are notes dated that day (RC2, Product)
        .init("watered plants sat", .idle, "note Watered plants Sat 10"),
        .init("called mum thu", .idle, "note Called mum Thu 15"),
        .init("saw mum yesterday", .idle, "note Saw mum Wed 14"),
        .init("made carbonara thu", .idle, "note Made carbonara Thu 15"),
        .init("need to call mum thu", .idle, "task Need to call mum Thu 15 19:00"),
        .init("feed the cat sat", .idle, "task Feed the cat Sat 17 09:00"),
        // Questions (RC5)
        .init("bench 80x8?", .idle, "nil"),
        .init("same?", .workout, "nil"),
        .init("dentist thu?", .idle, "nil"),
        .init("is the gym open sat", .idle, "nil"),
        .init("are we out of milk", .idle, "nil"),
        .init("do laundry thu", .idle, "task Do laundry Thu 15 19:00"),
        // get and buy (RC3 revised, Product)
        .init("get mum a card", .idle, "task Get mum a card later"),
        .init("get a haircut", .idle, "task Get a haircut later"),
        .init("get Olive a present", .idle, "task Get Olive a present later"),
        .init("get haircut", .idle, "task Get haircut later"),
        .init("buy train tickets", .idle, "task Buy train tickets later"),
        .init("get a new phone case", .idle, "task Get a new phone case later"),
        .init("get coffee", .idle, "groceries [coffee]"),
        .init("get squat rack hooks", .idle, "groceries [squat rack hooks]"),
        .init("buy bench scraper", .idle, "groceries [bench scraper]"),
        .init("buy chalk", .idle, "groceries [chalk]"),
        .init("get tonic water", .idle, "groceries [tonic water]"),
        .init("get bananas x6", .idle, "groceries [bananas x6]"),
        .init("buy 3 x 400 g tins chickpeas", .idle, "groceries [3 x 400 g tins chickpeas]"),
        .init("get 6 eggs and butter", .idle, "groceries [6 eggs, butter]"),
        .init("buy sat nav charger", .idle, "groceries [sat nav charger]"),
        .init("buy cake candles wed", .idle, "task Buy cake candles Wed 21 09:00"),
        .init("buy milk", .workout, "groceries [milk]"),
        .init("buy sun cream", .idle, "groceries [sun cream]"),
        // The shop run (RC4)
        .init("call mum", .shopping, "nil"),
        .init("shop", .shopping, "nil"),
        .init("done", .shopping, "nil"),
        .init("thanks", .shopping, "nil"),
        .init("buy milk", .shopping, "groceries [milk]"),
        .init("parmesan", .shopping, "groceries [parmesan]"),
        .init("sun cream", .shopping, "groceries [sun cream]"),
        // Reschedule keeps what wasn't said (RC13)
        .init("move dentist to fri", .idle, "reschedule Dentist Fri 16 10:00"),
        .init("move dentist to 3pm", .idle, "reschedule Dentist Sat 17 15:00"),
        // A hold, not a time (RC11)
        .init("plank 2:30", .idle, "nil"),
    ]

    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine
    let grammar: TessGrammar
    let calendar: Calendar
    let now: Date
    let workout: ObjectRecord

    init() throws {
        classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
        grammar = TessGrammar(store: store, classes: classes)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Europe/London"))
        self.calendar = calendar
        now = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 15, hour: 18)))
        let dentist = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 17, hour: 10)))
        try engine.perform(CreateTask(title: "Dentist", startsAt: dentist), by: .user)
        try engine.perform(CreateTask(title: "Call mum"), by: .user)
        try engine.perform(AddGroceries(lines: ["eggs"]), by: .user)
        let plan = try #require(store.object(id: StarterContent.planID))
        let push = try #require(store.linkedObjects("routines", of: plan).first)
        workout = try engine.perform(StartRoutine(routine: push.id, time: now), by: .user).output
    }

    func context(_ ctx: Ctx) -> TessContext {
        switch ctx {
        case .idle: TessContext(now: now, calendar: calendar)
        case .workout: TessContext(now: now, calendar: calendar, entry: workout.orderedChildren.first?.id,
                                   process: workout.id)
        case .shopping: TessContext(now: now, calendar: calendar, process: Groceries.listID)
        }
    }

    func stamp(_ date: Date, time: Bool = true) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = time ? "EEE d HH:mm" : "EEE d"
        return formatter.string(from: date)
    }

    func kind(_ parse: TessGrammar.Parse?) -> String {
        switch parse {
        case nil: "nil"
        case let .task(title, startsAt)?: "task \(title) \(startsAt.map { stamp($0) } ?? "later")"
        case let .groceries(lines)?: "groceries [\(lines.joined(separator: ", "))]"
        case let .note(body, on)?: "note \(body)\(on.map { " " + stamp($0, time: false) } ?? "")"
        case let .reschedule(task, to)?: "reschedule \(task.title) \(stamp(to))"
        case let other?: "\(other)"
        }
    }

    @Test(arguments: rows) func misfires(_ row: Row) {
        #expect(kind(grammar.parse(row.phrase, context: context(row.ctx))) == row.expect)
    }

    @Test func qaG9G10G11() throws {
        // G9: "a/an" plus something unknown stays Groceries.
        #expect(kind(grammar.parse("buy a cake", context: context(.idle))) == "groceries [a cake]")
        #expect(kind(grammar.parse("get a watermelon", context: context(.idle))) == "groceries [a watermelon]")
        // G10: keeping the dentist's day for "3pm" said at 16:00 on Sat would be past: use the said time instead.
        let saturday = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 17, hour: 16)))
        let late = TessContext(now: saturday, calendar: calendar)
        if case let .reschedule(_, to)? = grammar.parse("move dentist to 3pm", context: late) {
            #expect(to > saturday)
        } else {
            Issue.record("move dentist to 3pm")
        }
        // G11: "tonight" at 21:10 is tonight at 22:00, not tomorrow.
        let night = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 10,
            day: 15,
            hour: 21,
            minute: 10
        )))
        #expect(kind(grammar.parse("call mum tonight", context: TessContext(now: night, calendar: calendar)))
            == "task Call mum Thu 15 22:00")
    }

    @Test func aTypedQuestionMarkStillAsks() {
        // normalize trims the "?", so the guard reads the raw phrase.
        #expect(grammar.parse("dentist thu?", context: context(.idle)) == nil)
    }
}

@MainActor
struct CaptureMissLogTests {
    @Test func missesAreKeptBesideTheDatabaseAndCut() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let store = try ObjectStore(context: TesseraContext(url: dir.appendingPathComponent("tessera.sqlite")))
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let capture = TessCaptureEngine(engine: engine)
        let log = try #require(CaptureMissLog.beside(store))

        let missed = await capture.capture("https://example.com/best-dal", context: TessContext())
        #expect(missed.keptToSort) // kept as a note, and still a miss for the week-one log
        _ = await capture.capture("bench 80x8", context: TessContext())
        log.record(String(repeating: "x", count: 500), route: "none", source: "paste")

        let misses = log.all()
        #expect(misses.map(\.source) == ["ghost row", "paste"])
        #expect(misses.first?.text == "https://example.com/best-dal" && misses.first?.route == "none")
        #expect(misses.last?.text.count == CaptureMissLog.maxText)
        // Not in the op log.
        #expect(!engine.history().contains { $0.summary.contains("example.com") })
        // In memory: nothing written anywhere.
        #expect(CaptureMissLog.beside(ObjectStore.open(inMemory: true)) == nil)
    }

    @Test func aDuplicatePasteSaysSoAndIsNeverLogged() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let store = try ObjectStore(context: TesseraContext(url: dir.appendingPathComponent("tessera.sqlite")))
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        let capture = TessCaptureEngine(engine: engine)
        let log = try #require(CaptureMissLog.beside(store))
        let dal = "Weeknight dal\nIngredients\n1 cup red lentils\n1 onion\nMethod\n1. Simmer 20 minutes."
        let first = await capture.capture(dal, context: TessContext())
        #expect(first.understood)
        let again = await capture.capture(dal, context: TessContext())
        #expect(again.line == "Weeknight dal is already on Recipes." && !again.understood && again.isRefusal)
        // A private title reads "Private recipe", and neither paste lands in the miss log.
        let secret = "Lexapro stew\nIngredients\n1 cup red lentils\n1 onion\nMethod\n1. Simmer 20 minutes."
        _ = await capture.capture(secret, context: TessContext())
        let twice = await capture.capture(secret, context: TessContext())
        #expect(twice.line == "Private recipe is already on Recipes.", "\(twice.line)")
        #expect(log.all().isEmpty, "\(log.all().map(\.text))")
        #expect(RecipeBook(store: store, classes: engine.classes).recipes().count == 2)
    }
}
