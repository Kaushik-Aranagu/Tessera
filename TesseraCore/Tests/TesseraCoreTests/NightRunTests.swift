import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Memory spec M5 and M6 (accept): a night pass on a small history writes summaries, closes a changed belief, and
/// produces an eval row; a second run the same night does nothing. Merges go through actions, and a forget of the
/// kept belief takes the merged one with it.
@MainActor
struct NightRunTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine

    init() throws {
        classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
    }

    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles") ?? .current
        calendar.firstWeekday = 2
        return calendar
    }

    func at(_ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))
            ?? .distantPast
    }

    /// Saturday Oct 24, 4:05 am: Friday Oct 23 closes.
    var run: NightRun {
        NightRun(engine: engine, calendar: calendar, now: at(10, 24, 4, 5), policy: .strict)
    }

    @discardableResult
    func workout(_ start: Date, kg: Double, from routine: ObjectRecord) throws -> ObjectRecord {
        let workoutClass = try #require(classes[.workout])
        let entryClass = try #require(classes[.exerciseEntry])
        let setClass = try #require(classes[.set])
        let bench = try #require(classes[.benchPress])
        let workout = store.create(workoutClass, title: routine.title)
        try store.setLinks("routine", on: workout, to: [routine])
        try store.set("startedAt", to: .date(start), on: workout)
        try store.set("endedAt", to: .date(start.addingTimeInterval(3600)), on: workout)
        let entry = store.create(entryClass, parent: workout)
        try store.setClassLink("exercise", on: entry, to: bench)
        let set = store.create(setClass, parent: entry)
        try store.set("weight", to: .mass(kg), on: set)
        try store.set("reps", to: .number(5), on: set)
        return workout
    }

    /// A small history: training moved from 6 am to 6:30 pm, and he told her twice that he likes rice.
    func history() throws -> (sixAM: UUID, rice: [UUID]) {
        let workoutClass = try #require(classes[.workout])
        let push = try engine.perform(CreateRoutine(title: "Push Day"), by: .system).output
        let early = try workout(at(10, 10, 6), kg: 80, from: push)
        for day in [14, 16, 20, 23] {
            try workout(at(10, day, 18, 30), kg: 82.5, from: push)
        }
        let six = try engine.perform(RecordBelief(words: "You usually train around 6 am.", key: .usualTime,
                                                  source: .noticed, value: "{\"hour\":6}",
                                                  subjectClass: workoutClass.id, evidence: [early.id],
                                                  validFrom: at(9, 1, 9)), by: .system).output
        var rice: [UUID] = []
        for month in [3, 5] {
            let belief = try engine.perform(RecordBelief(words: "You like rice.", key: .prefers, source: .told,
                                                         value: "{\"text\":\"rice\"}", evidence: [push.id],
                                                         validFrom: at(month, 1, 9)), by: .system).output
            rice.append(belief.id)
        }
        return (six.id, rice)
    }

    @Test func aNightWritesSummariesClosesAChangeAndKeepsAnEvalRow() async throws {
        let (sixAM, rice) = try history()
        var record = NightRecord()
        var eval = MemoryEvalRecord()
        var asked: [String] = []
        let report = try #require(await run.run(record: &record, eval: &eval) { question, model in
            asked.append("\(model.rawValue) \(question.id)")
            return "I don't know yet."
        })

        #expect(report.night == "2026-10-23")
        #expect(report.failed.isEmpty)
        #expect(record.summaries["/summaries/day/2026-10-23"] == "1 workout: Push Day")
        #expect(record.lastNight == "2026-10-23")

        // The usual time changed: the 6 am belief is closed and 6:30 pm replaces it.
        let beliefs = TessBeliefStore(engine: engine)
        let open = beliefs.open()
        #expect(!open.contains { $0.id == sixAM })
        let current = try #require(open.first { $0.key == .usualTime })
        #expect(current.value == "{\"hour\":18.5}" && current.supersedes == sixAM)
        #expect(current.words == "You usually train around 6:30 pm.")

        // The two rice lines merged into the older one; the newer one is closed and is its evidence.
        #expect(open.filter { $0.key == .prefers }.map(\.id) == [rice[0]])
        #expect(open.first { $0.id == rice[0] }?.evidence.contains(rice[1]) == true)

        // The eval ran on both models, and the change is one of its questions.
        #expect(report.eval.map(\.model) == ["haiku", "sonnet"] && eval.nights.count == 2)
        #expect(asked.contains("haiku changed/\(current.id.uuidString)"))
        #expect(report.reflected == ["Tess", "Training"])

        // The same night again does nothing.
        let again = await run.run(record: &record, eval: &eval) { _, _ in "6:30 pm" }
        #expect(again == nil)
        #expect(eval.nights.count == 2)
    }

    @Test func aFailedCallNeverCountsAsRight() async throws {
        _ = try history()
        var record = NightRecord()
        var eval = MemoryEvalRecord()
        let report = try #require(await run.run(record: &record, eval: &eval) { _, model in
            model == .haiku ? "I don't know yet." : nil
        })
        #expect(report.eval.last?.asked.isEmpty == true)
        #expect(eval.kept.isEmpty && eval.streaks.isEmpty)
    }

    @Test func forgettingTheKeptBeliefTakesTheMergedOne() async throws {
        let (_, rice) = try history()
        var record = NightRecord()
        var eval = MemoryEvalRecord()
        _ = await run.run(record: &record, eval: &eval) { _, _ in nil }
        _ = try engine.perform(ForgetBelief(belief: rice[0]), by: .user)
        let left = TessBeliefStore(engine: engine).all().map(\.id)
        #expect(!left.contains(rice[0]) && !left.contains(rice[1]))
    }

    @Test func packsRefreshOnlyWhenTheirHashMoved() async throws {
        var record = NightRecord(packHashes: ["training": "aaa", "kitchen": "bbb"])
        var eval = MemoryEvalRecord()
        let report = try #require(await run.run(record: &record, eval: &eval,
                                                packs: [.training: "aaa", .kitchen: "ccc"]) { _, _ in nil })
        #expect(report.steps.contains(.refresh(.kitchen)) && !report.steps.contains(.refresh(.training)))
        #expect(record.packHashes == ["training": "aaa", "kitchen": "ccc"])
    }

    @Test func theEvalFactsLeaveOutPrivateWorkouts() throws {
        let push = try engine.perform(CreateRoutine(title: "Push Day"), by: .system).output
        let rehab = try engine.perform(CreateRoutine(title: "Shoulder rehab"), by: .system).output
        try workout(at(10, 20, 18), kg: 82.5, from: push)
        try workout(at(10, 21, 18), kg: 120, from: rehab)
        let facts = MemoryEvalFacts.from(store: store, classes: classes, calendar: calendar, now: at(10, 24, 4, 5))
        #expect(facts.sets.map(\.weight) == [82.5])
        #expect(!facts.events.contains { $0.name.contains("rehab") })
        #expect(facts.unknowns.count == MemoryEvalFacts.unknownTopics.count)
    }

    @Test func theRecordKeepsSixtyDaysOfSummaries() {
        var record = NightRecord()
        for day in 1 ... 70 {
            record.summaries[String(format: "/summaries/day/2026-%03d", day)] = "A quiet day."
        }
        record.summaries["/summaries/week/2026-W43"] = "A quiet week."
        record.trim()
        #expect(record.summaries.count == 61)
        #expect(record.summaries["/summaries/day/2026-001"] == nil)
        #expect(record.summaries["/summaries/day/2026-070"] != nil)
    }
}
