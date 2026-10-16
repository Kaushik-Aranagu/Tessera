import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// The seeded starter plan (PPL x2) stores no weekly count; Home's rhythm fallback must still leave rest days, or
/// Now never says "Rest day" on real data (QA E5).
@MainActor
struct HomeRestDayTests {
    let container = TesseraSchema.makeContainer(inMemory: true)

    @Test func seededPlanHasARestDayEveryWeek() throws {
        let model = AppModel(context: container.mainContext)
        let plan = try #require(model.plan)
        let perWeek = try #require(NowPage.sessionsPerWeek(model: model, plan: plan))
        #expect(perWeek < 7)
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        let monday = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 12, hour: 8)))
        let week = model.ledger.week(containing: monday, plan: plan, now: monday, sessionsPerWeek: perWeek,
                                     calendar: calendar)
        #expect(week.contains { $0.isRest })
    }
}
