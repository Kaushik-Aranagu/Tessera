import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// The engine wall (board 0ai): the BN and BM rows of Research's walls fixture, run against the engine. Every writer
/// that titles something from words it was handed (the on-device model, Claude's tools, RememberFact, the memory
/// turnover, Plan my day's pack) keeps money, secrets and his weight off titles, logs and packs.
@MainActor
struct WallsBypassTests {
    struct Row: Decodable {
        struct Seed: Decodable {
            let lastWeightKg: Double?
            let focus: Focus?

            struct Focus: Decodable {
                let exercise: String
            }
        }

        let id: String
        let phrase: String?
        let surface: String
        let expectPrivate: Bool
        let expectNoClaude: Bool
        let expectLine: String?
        let seed: Seed?
        let mustNotShow: [String]?
    }

    struct Fixture: Decodable {
        /// Other rows (the UI suite's) seed with a string; only this suite's rows are read.
        struct Lenient: Decodable {
            let row: Row?

            init(from decoder: any Decoder) throws {
                row = try? Row(from: decoder)
            }
        }

        let rows: [Lenient]
    }

    nonisolated static let rows: [Row] = {
        let url = URL(filePath: #filePath).deletingLastPathComponent().appending(
            path: "../../../docs/research/fixtures/walls-ui-phrases.json"
        )
        guard let data = try? Data(contentsOf: url),
              let fixture = try? JSONDecoder().decode(Fixture.self, from: data) else { return [] }
        return fixture.rows.compactMap(\.row).filter { $0.id.hasPrefix("BN") || $0.id.hasPrefix("BM") }
    }()

    nonisolated static func rows(_ surfaces: String...) -> [String] {
        rows.filter { surfaces.contains($0.surface) }.map(\.id)
    }

    nonisolated static func row(_ id: String) throws -> Row {
        try #require(rows.first { $0.id == id })
    }

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }

    static func at(_ day: Int, _ hour: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour))!
    }

    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine

    init() throws {
        classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
        engine.zone = { Self.calendar.timeZone }
    }

    /// His last weight, logged the way he logs it: a private note.
    func weigh(_ kilograms: Double?, at time: Date = Self.at(14, 7)) throws {
        guard let kilograms else { return }
        let result = try engine.perform(CreateNote(body: "\(kilograms) kg", isPrivate: true), by: .user)
        result.record.createdAt = time
        result.output.createdAt = time
        #expect(BodyWeight.lastKg(in: store) == kilograms)
    }

    /// Every title, summary and receipt the engine holds.
    func everythingShown() -> String {
        let titles = classes.values.flatMap { store.objects(of: $0) }.map(\.title)
        let ops = engine.history().flatMap { [$0.summary, $0.receipt ?? ""] }
        return (titles + ops).joined(separator: "\n")
    }

    func expectNothingShows(_ row: Row) {
        let shown = everythingShown()
        for word in row.mustNotShow ?? [] {
            #expect(!shown.contains(word), "\(row.id): \(word) shows in \(shown)")
        }
    }

    @Test func theFixtureIsRead() {
        #expect(Self.rows.count >= 42)
    }

    // MARK: The bare-number wall (BN, and the ask rows of BM)

    @Test(arguments: rows("askBar", "liveWorkoutAsk"))
    func aBareNumberNearHisWeightIsWalled(_ id: String) throws {
        let row = try Self.row(id)
        let phrase = try #require(row.phrase)
        // With a set in focus the number is the bar (decisions 4:46 pm (3)), so no weight is read.
        let last = row.seed?.focus == nil ? row.seed?.lastWeightKg : nil
        #expect(PrivateFacts.isWalled(phrase, lastWeightKg: last) == row.expectNoClaude, "\(id): \(phrase)")
    }

    // MARK: Model and tool writes

    @Test(arguments: rows("modelWrite", "toolWrite"))
    func aWrittenTaskGoesThroughTheWall(_ id: String) throws {
        let row = try Self.row(id)
        let phrase = try #require(row.phrase)
        try weigh(row.seed?.lastWeightKg)
        let noteClass = try #require(classes[.note])
        let notesBefore = store.objects(of: noteClass).count
        let json = try JSONSerialization.data(withJSONObject: ["title": phrase])
        _ = try TessTools.run("createTask", arguments: json, engine: engine)
        let tasks = try store.objects(of: #require(classes[.task]))
        if row.expectPrivate {
            #expect(tasks.isEmpty, "\(id): \(tasks.map(\.title))")
            #expect(store.objects(of: noteClass).count == notesBefore + 1, "\(id)")
        } else {
            #expect(tasks.count == 1, "\(id): \(tasks.map(\.title))")
        }
        expectNothingShows(row)
    }

    @Test func moneyToDoKeepsTheTaskWithoutTheAmount() throws {
        let json = try JSONSerialization.data(withJSONObject: ["title": "pay rent 2100 fri"])
        _ = try TessTools.run("createTask", arguments: json, engine: engine)
        #expect(try store.objects(of: #require(classes[.task])).map(\.title) == ["Pay rent fri"])
    }

    // MARK: RememberFact

    @Test(arguments: rows("rememberFact"))
    func rememberFactNeverKeepsAWalledLine(_ id: String) throws {
        let row = try Self.row(id)
        let phrase = try #require(row.phrase)
        try weigh(row.seed?.lastWeightKg)
        let arguments = try JSONSerialization
            .data(withJSONObject: ["text": phrase, "evidence": [String]()] as [String: Any])
        let kept: Bool
        do {
            _ = try engine.perform(named: "rememberFact", arguments: arguments, by: .tess, pending: true)
            kept = true
        } catch {
            kept = false
            if let line = row.expectLine {
                #expect(RememberFact.refusalLine(error) == line, "\(id): \(error)")
            }
            #expect(row.mustNotShow != nil, "\(id): \(error)")
        }
        #expect(kept == (row.mustNotShow == nil), "\(id): \(phrase)")
        expectNothingShows(row)
    }

    // MARK: The memory turnover

    @Test(arguments: rows("memoryTurnover"))
    func theTurnoverSkipsAWalledDayLine(_ id: String) throws {
        let row = try Self.row(id)
        let phrase = try #require(row.phrase)
        try weigh(row.seed?.lastWeightKg, at: Self.at(10, 7))
        // A task titled before the wall: made plain, then renamed (his own words in his own place are exempt).
        let yesterday = Self.at(15, 15)
        let made = try engine.perform(CreateTask(title: "Errand"), by: .user)
        made.record.createdAt = yesterday
        made.output.createdAt = yesterday
        try engine.perform(RenameObject(object: made.output.id, title: phrase), by: .user).record.createdAt = yesterday
        #expect(made.output.title == phrase)
        try engine.perform(SetTaskDone(task: made.output.id, time: yesterday), by: .user).record.createdAt = yesterday
        let memory = TessMemoryStore(engine: engine, calendar: Self.calendar, forgetLogURL: FileManager.default
            .temporaryDirectory.appendingPathComponent("walls-\(UUID().uuidString).json"))
        memory.turnover(now: Self.at(16, 5))
        let recent = memory.lines(of: .recent).map(\.text).joined(separator: "\n")
        for word in row.mustNotShow ?? [] {
            #expect(!recent.contains(word), "\(id): \(recent)")
        }
        if row.mustNotShow == nil {
            #expect(recent.contains(phrase.lowercased()), "\(id): \(recent)")
        }
    }

    // MARK: Plan my day

    @Test(arguments: rows("planMyDay"))
    func planMyDaysPackNeverHoldsAWalledTitle(_ id: String) throws {
        let row = try Self.row(id)
        let phrase = try #require(row.phrase)
        let now = Self.at(16, 7)
        var input = PlanInput(now: now, calendar: Self.calendar)
        input.later = [PlanInput.Task(title: phrase, minutes: 20, updatedAt: now)]
        let pack = try #require(PlanPack(plan: DayPlanner.plan(input), now: now, calendar: Self.calendar,
                                         calendarKnown: true, restDay: false,
                                         lastWeightKg: row.seed?.lastWeightKg))
        for word in row.mustNotShow ?? [] {
            #expect(!pack.json.contains(word), "\(id): \(pack.json)")
        }
        #expect(pack.json.contains(phrase) == !row.expectPrivate, "\(id)")
    }

    // MARK: Lists and notes

    @Test func aPriceComesOffAListItem() throws {
        let list = try engine.perform(CreateList(name: "Errands"), by: .user).output
        try engine.perform(AddListItem(list: list.id, text: "milk $4"), by: .user)
        let paid = try engine.perform(AddListItem(list: list.id, text: "$212.37"), by: .user)
        #expect(list.orderedChildren.map(\.title) == ["milk"])
        #expect(paid.record.summary == SecretWords.title && paid.record.receipt == "\(SecretWords.title), kept")
        #expect(!everythingShown().contains("212") && !everythingShown().contains("$4"))
    }

    @Test func aNoteOfHisWeightIsPrivate() throws {
        try weigh(82)
        let note = try engine.perform(CreateNote(body: "81.6 this morning"), by: .user)
        #expect(note.record.summary == SecretWords.title)
        #expect(!everythingShown().contains("81.6"))
    }

    // MARK: Pieces

    @Test func bodyWeightReadsTheNewestPrivateWeight() throws {
        #expect(BodyWeight.lastKg(in: store) == nil)
        try weigh(82, at: Self.at(10, 7))
        try weigh(80.5, at: Self.at(12, 7))
        #expect(BodyWeight.lastKg(in: store) == 80.5)
        #expect(BodyWeight.kilograms(in: "180 lb").map { ($0 * 10).rounded() / 10 } == 81.6)
        #expect(BodyWeight.kilograms(in: "bench 3 sets") == nil)
        #expect(BodyWeight.kilograms(in: "weighed 900 kg") == nil)
    }

    @Test(arguments: ["log my weight 82.4", "weight 82.4", "my weight 182 lb"])
    func hisWeightSaidAsWeightIsWalled(_ phrase: String) {
        // Research: Siri's Add a Task would speak "Log my weight 82.4." back; with no weight logged it is still his.
        #expect(PrivateFacts.isWalled(phrase, lastWeightKg: nil), "\(phrase)")
    }

    @Test func theWallSortsTaskTitles() {
        func outcome(_ title: String, _ startsAt: Date? = nil) -> EngineWall.TaskOutcome {
            EngineWall.task(title, startsAt: startsAt, store: store)
        }
        #expect(outcome("call the gym about chalk") == .keep("call the gym about chalk"))
        #expect(outcome("pay rent 2100 fri") == .withoutAmount("pay rent fri"))
        #expect(outcome("paid rent 2100") == .privateNote)
        #expect(outcome("wifi password is hunter2") == .privateNote)
        #expect(outcome(ObjectPrivacy.taskLabel) == .privateTask)
        #expect(EngineWall.withoutPrice("2 lemons £1.20") == "2 lemons")
        #expect(EngineWall.withoutPrice("500 g flour") == "500 g flour")
        #expect(EngineWall.withoutPrice("eggs for 4 dollars") == "eggs")
    }
}
