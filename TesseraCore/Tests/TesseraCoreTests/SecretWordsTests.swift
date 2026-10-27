import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Research 134 (docs/research/fixtures/secret-words.md): a line with a secret word becomes a private note on the
/// phone and never reaches the model, Claude, memory or the miss log. Every value below is a made-up placeholder.
@MainActor
@Suite(.oldWalls)
struct SecretWordsTests {
    static let la = TimeZone(identifier: "America/Los_Angeles")!

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = la
        return calendar
    }

    static let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 15, hour: 18))!

    /// A model that records every phrase it is asked about: nothing secret may ever reach it.
    final class Spy: TessModel {
        var heard: [String] = []
        let route: OpRoute

        init(route: OpRoute) {
            self.route = route
        }

        var modelName: String? {
            "spy"
        }

        func isAvailable(for _: TessUse) -> Bool {
            true
        }

        func run(_ request: TessRequest, engine _: ActionEngine) async -> TessResult {
            heard.append(request.text)
            return .missed
        }
    }

    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine

    init() throws {
        let classes = try store.prepareCatalog()
        self.classes = classes
        engine = ActionEngine(store: store, classes: classes)
        engine.zone = { Self.la }
    }

    var context: TessContext {
        TessContext(now: Self.now, calendar: Self.calendar)
    }

    /// The grammar first, then two spies standing in for the on-device model and Claude.
    func run(_ phrase: String, spies: [Spy]) async -> TessCapture {
        let tess = TessCaptureEngine(engine: engine)
        let router = TessRouter(engine: engine, models: [GrammarTessModel(capture: tess)] + spies)
        return await router.run(TessRequest(text: phrase, context: context, use: .capture))
    }

    func notes() -> [ObjectRecord] {
        store.objects(of: classes[.note]!) // swiftlint:disable:this force_unwrapping
    }

    @Test(arguments: [
        "wifi password is tacocat", "wifi: TacoNet / tacocat24", "door code 4417", "the gate code is 2580",
        "my PIN is 0420", "my passcode is one two three four", "note: wifi password is tacocat",
        "netflix password hunter2", "alarm code 9 9 1 2", "call mom about the wifi password", "zip code 94110",
        "promo code SAVE20 for target",
    ])
    func secretLinesBecomePrivateNotesAndNeverLeave(_ phrase: String) async throws {
        let device = Spy(route: .onDevice), claude = Spy(route: .claude)
        let result = await run(phrase, spies: [device, claude])
        #expect(result.line == "Private note, kept.")
        let note = try #require(notes().first)
        #expect(note.title == SecretWords.title && store.value("isPrivate", of: note) == .bool(true))
        // The words stay only in the body; no op summary, title or Day log line carries them.
        #expect(store.value("body", of: note)?.stringValue?.isEmpty == false)
        #expect(result.records.allSatisfy { $0.summary == SecretWords.title })
        #expect(device.heard.isEmpty && claude.heard.isEmpty)
    }

    @Test func rememberAPasswordIsAPrivateNoteNotAMemory() async throws {
        let result = await run("remember the wifi password is tacocat", spies: [Spy(route: .claude)])
        #expect(result.line == "Private note, kept. I don't keep passwords.")
        #expect(TessMemoryStore(engine: engine, calendar: Self.calendar, forgetLogURL: nil).all().isEmpty)
        #expect(TessMemoryScreen.refusal(for: "the wifi password is tacocat") == .secret)
        #expect(TessMemoryScreen.Refusal.secret.line == "I don't keep passwords.")
        #expect(throws: ActionError.self) {
            try engine.perform(RememberFact(text: "my PIN is 0420"), by: .user)
        }
    }

    @Test func nearMissesStayTasksAndQuestionsStayOnThePhone() async {
        let claude = Spy(route: .claude)
        let reset = await run("password reset email friday", spies: [claude])
        // A task with a secret word is said back without its title (Product P14, 12:30 PM PT).
        #expect(
            reset.records.map(\.action) == ["createTask"] && reset.line == "Task added for tomorrow.",
            "\(reset.line)"
        )
        let review = await run("code review friday 3pm", spies: [claude])
        #expect(review.records.map(\.action) == ["createTask"] && review.line == "Task added for tomorrow.")
        let todo = await run("todo: reset my PIN", spies: [claude])
        #expect(todo.records.map(\.action) == ["createTask"] && todo.line == "Task added.", "\(todo.line)")
        let ask = await run("what's the wifi password?", spies: [claude])
        #expect(ask.line == "It's in your private notes." && ask.records.isEmpty)
        #expect(claude.heard.isEmpty && notes().isEmpty)
        // Whole words only: a pinch of salt is not a PIN.
        #expect(!SecretWords.mentions("pinch of salt") && !SecretWords.mentions("spinach and feta"))
        #expect(!SecretWords.mentions("garage 4417"))
    }

    @Test func editingKeepsAPrivateNotePrivateAndAddingACodeMakesItPrivate() throws {
        // QA F1 on #422: the editor retitles from the first line; a private note's words must never become its title.
        let secret = try engine.perform(CreateNote(body: "wifi password is tacocat", isPrivate: true), by: .user).output
        let edit = try engine.perform(
            EditNote(note: secret.id, body: "wifi password is tacocat2", title: "wifi password is tacocat2"),
            by: .user
        )
        #expect(secret.title == SecretWords.title && edit.record.summary == SecretWords.title)
        #expect(store.value("body", of: secret)?.stringValue == "wifi password is tacocat2")
        // A plain note gains a code: it becomes private, loses its title and its links.
        let plain = try engine.perform(CreateNote(body: "router in the hall"), by: .user).output
        #expect(store.value("isPrivate", of: plain) == nil && plain.title == "router in the hall")
        try engine.perform(
            EditNote(note: plain.id, body: "router in the hall, door code 4417", title: "router in the hall"),
            by: .user
        )
        #expect(plain.title == SecretWords.title && store.value("isPrivate", of: plain) == .bool(true))
        #expect(store.linkedObjects("about", of: plain).isEmpty)
        // A plain edit stays a plain note.
        let shopping = try engine.perform(CreateNote(body: "buy bulbs"), by: .user).output
        try engine.perform(
            EditNote(note: shopping.id, body: "buy bulbs and tape", title: "buy bulbs and tape"),
            by: .user
        )
        #expect(shopping.title == "buy bulbs and tape" && store.value("isPrivate", of: shopping) == nil)
    }

    @Test func theDayLogAndMemoryNeverCarryTheWords() async throws {
        // Committed (a ghost row commits after its grace; Siri commits at once), so the Day log reads it.
        let tess = TessCaptureEngine(engine: engine)
        _ = await TessRouter(engine: engine, models: [GrammarTessModel(capture: tess)]).run(TessRequest(
            text: "note: wifi password is tacocat",
            context: TessContext(now: Date(), calendar: Self.calendar, commitImmediately: true), use: .capture
        ))
        // The engine stamps records with the real clock, so the Day log is read for the real today.
        let today = Date()
        let lines = DayStory.lines(engine: engine, on: today, calendar: Self.calendar, now: today)
        #expect(lines.map(\.text).contains(SecretWords.title))
        #expect(!lines.contains { $0.text.contains("tacocat") || $0.text.contains("password") })
        // An older note written before the rule, titled with the words, never reaches a memory line either.
        try engine.perform(CreateNote(body: "plain note"), by: .user)
        let memory = TessMemoryStore(engine: engine, calendar: Self.calendar, forgetLogURL: nil)
        let recent = memory.recentLine(for: TesseraDay(calendar: Self.calendar).day(of: today), now: today)
        #expect(recent?.contains("tacocat") != true && recent?.contains("password") != true)
        #expect(memory.pack(.init(told: true, noticed: true, recent: true))
            .allSatisfy { !SecretWords.mentions($0.text) })
    }

    @Test func aPrivateNoteIsNeverAMentionTarget() throws {
        // Board 0ad (PN-MENTION): "@Private note" in another note links nothing.
        let secret = try engine.perform(CreateNote(body: "door code 4417", isPrivate: true), by: .user).output
        let other = try engine.perform(CreateNote(body: "see @[Private note] for the door"), by: .user).output
        #expect(!store.linkedObjects("about", of: other).contains { $0.id == secret.id })
        #expect(NoteList(store: store, classes: classes).mentions(in: "@[Private note]").isEmpty)
    }
}
