import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Input hygiene H8 (docs/ai/harness/input-hygiene.md): forgetting is exact. Each night summary cites the objects
/// it was built from; deleting one rebuilds every summary that cites it, so a deleted name never stays in memory.
@MainActor
struct NightForgetTests {
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

    func at(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))
            ?? .distantPast
    }

    func night(_ day: Int) -> NightRun {
        NightRun(engine: engine, calendar: calendar, now: at(day, 4, 5), policy: .strict)
    }

    @discardableResult
    func workout(_ title: String, at date: Date) throws -> ObjectRecord {
        let workout = try store.create(#require(classes[.workout]), title: title)
        try store.set("startedAt", to: .date(date), on: workout)
        return workout
    }

    @discardableResult
    func run(_ day: Int, _ record: inout NightRecord) async -> NightRun.Report? {
        var eval = MemoryEvalRecord()
        return await night(day).run(record: &record, eval: &eval) { _, _ in nil }
    }

    @Test func aSummaryCitesWhatItWasBuiltFrom() async throws {
        let push = try workout("Push Day", at: at(23, 18))
        let pull = try workout("Pull Day", at: at(23, 7))
        var record = NightRecord()
        await run(24, &record)
        #expect(record.summaries["/summaries/day/2026-10-23"] == "2 workouts: Pull Day, Push Day")
        #expect(Set(record.cites?["/summaries/day/2026-10-23"] ?? []) == [push.id, pull.id])
    }

    @Test func deletingAThingRebuildsEverySummaryThatCitesIt() async throws {
        let push = try workout("Push Day", at: at(23, 18))
        try workout("Pull Day", at: at(23, 7))
        var record = NightRecord()
        await run(24, &record)
        store.softDelete(push)
        let report = try #require(await run(25, &record))
        #expect(report.rebuilt == ["/summaries/day/2026-10-23"])
        #expect(record.summaries["/summaries/day/2026-10-23"] == "1 workout: Pull Day")
        #expect(record.cites?["/summaries/day/2026-10-23"]?.contains(push.id) == false)
        // Nothing else was touched: the night's own summary is written as usual.
        #expect(record.summaries["/summaries/day/2026-10-24"] == "A quiet day.")
    }

    @Test func aWeekForgetsToo() async throws {
        // Sunday Oct 25 closes ISO week 43 (Mon Oct 19 to Sun Oct 25).
        let tempo = try workout("Tempo Run", at: at(21, 7))
        try workout("Push Day", at: at(25, 9))
        var record = NightRecord()
        await run(26, &record)
        let week = "/summaries/week/2026-W43"
        #expect(record.summaries[week] == "2 workouts: Tempo Run, Push Day")
        store.softDelete(tempo)
        let report = try #require(await run(27, &record))
        #expect(report.rebuilt == [week])
        #expect(record.summaries[week] == "1 workout: Push Day")
        #expect(record.summaries["/summaries/day/2026-10-25"] == "1 workout: Push Day")
    }

    @Test func aDayWithNothingLeftReadsQuietAndAnOldSummaryIsLeftAlone() async throws {
        let only = try workout("Leg Day", at: at(23, 18))
        var record = NightRecord(summaries: ["/summaries/day/2026-10-01": "1 workout: Old Day"])
        await run(24, &record)
        store.softDelete(only)
        await run(25, &record)
        #expect(record.summaries["/summaries/day/2026-10-23"] == "A quiet day.")
        #expect(record.cites?["/summaries/day/2026-10-23"] == [])
        // A summary written before the cite index has no cites, so nothing says it is stale.
        #expect(record.summaries["/summaries/day/2026-10-01"] == "1 workout: Old Day")
    }

    @Test func aPathItCannotReadIsDroppedNotKept() async throws {
        let gone = try workout("Leg Day", at: at(23, 18))
        store.softDelete(gone)
        var record = NightRecord(summaries: ["/summaries/day/someday": "1 workout: Leg Day"],
                                 cites: ["/summaries/day/someday": [gone.id]])
        let report = try #require(await run(24, &record))
        #expect(report.rebuilt == ["/summaries/day/someday"])
        #expect(record.summaries["/summaries/day/someday"] == nil && record.cites?["/summaries/day/someday"] == nil)
    }

    @Test func theCiteIndexSurvivesTheFileAndTrimsWithTheSummaries() throws {
        var record = NightRecord(summaries: ["/summaries/day/2026-01-01": "x"],
                                 cites: ["/summaries/day/2026-01-01": [UUID()]])
        for day in 2 ... NightRecord.keepDays + 1 {
            let path = String(format: "/summaries/day/2026-03-%02d", day % 28 + 1) + "-\(day)"
            record.summaries[path] = "y"
        }
        record.trim()
        #expect(record.summaries["/summaries/day/2026-01-01"] == nil)
        #expect(record.cites?["/summaries/day/2026-01-01"] == nil)
        let saved = try JSONDecoder().decode(NightRecord.self, from: JSONEncoder().encode(record))
        #expect(saved == record)
    }
}
