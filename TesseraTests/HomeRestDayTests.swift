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

    /// Core's flags drive the marks: rest where isRest, the miss ring only where wasDue, today rest only when Core
    /// says so, nothing ahead, nothing before first use. At 01:00 Saturday, Friday is still today (R4).
    @Test func reviewMarksFollowCoreFlags() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        let monday = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 12)))
        let days = (0 ..< 7).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
        let thursday = days[3].addingTimeInterval(9 * 3600)
        let week = [
            WeekReview.Slot(day: days[0], sessions: 2),
            WeekReview.Slot(day: days[1], sessions: 0, wasDue: true),
            WeekReview.Slot(day: days[2], sessions: 0, isRest: true),
            WeekReview.Slot(day: days[3], sessions: 0),
            WeekReview.Slot(day: days[4], sessions: 0),
            WeekReview.Slot(day: days[5], sessions: 0, isRest: true),
            WeekReview.Slot(day: days[6], sessions: 0),
        ]
        let marks = WeekReview.marks(week, firstUse: nil, restToday: false, now: thursday, calendar: calendar)
        #expect(marks == [.trained(2), .open, .rest, .planned, .planned, .planned, .planned])
        let resting = WeekReview.marks(week, firstUse: nil, restToday: true, now: thursday, calendar: calendar)
        #expect(resting[3] == .rest)
        // 01:00 Friday is still Thursday: Thursday is today (unmarked), not a miss.
        let lateThursday = days[4].addingTimeInterval(3600)
        let late = WeekReview.marks(week, firstUse: nil, restToday: false, now: lateThursday, calendar: calendar)
        #expect(late[3] == .planned)
        let fresh = WeekReview.marks(week, firstUse: days[2].addingTimeInterval(9 * 3600), restToday: false, now: thursday, calendar: calendar)
        #expect(fresh[0] == .trained(2) && fresh[1] == .none)
    }
}
