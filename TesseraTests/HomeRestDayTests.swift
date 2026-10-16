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

    /// A kept plan (six done, one empty day) reads the empty day as rest; a thin week's empty days are open; days
    /// before first use get nothing.
    @Test func reviewMarksRestOpenAndBeforeFirstUse() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        let monday = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 12)))
        let days = (0 ..< 7).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
        let sunday = days[6].addingTimeInterval(20 * 3600)
        func week(trained: Set<Int>) -> [WeekReview.Slot] {
            days.enumerated().map { index, day in WeekReview.Slot(day: day, sessions: trained.contains(index) ? 1 : 0) }
        }
        let kept = WeekReview.marks(week(trained: [0, 1, 2, 3, 4, 5]), perWeek: 6, firstUse: nil, restToday: false,
                                    now: sunday, calendar: calendar)
        #expect(kept.last == .rest)
        let thin = WeekReview.marks(week(trained: [0, 3]), perWeek: 6, firstUse: nil, restToday: false,
                                    now: sunday, calendar: calendar)
        // One rest day in the budget goes to the latest empty past day; the earlier empty days are open.
        #expect(thin[5] == .rest && thin[1] == .open && thin[2] == .open && thin[4] == .open)
        // QA R1: trained Monday, nothing Tuesday or Wednesday, it's Thursday: one of them is the plan's rest.
        let thursday = days[3].addingTimeInterval(9 * 3600)
        let behind = WeekReview.marks(week(trained: [0]), perWeek: 6, firstUse: nil, restToday: false,
                                      now: thursday, calendar: calendar)
        #expect(behind[2] == .rest && behind[1] == .open && behind[4] == .planned)
        // QA R2: a double-session day counts once toward the week.
        let double = days.enumerated().map { index, day in
            WeekReview.Slot(day: day, sessions: index == 0 ? 2 : index < 5 ? 1 : 0)
        }
        let doubled = WeekReview.marks(double, perWeek: 6, firstUse: nil, restToday: false, now: sunday,
                                       calendar: calendar)
        #expect(doubled[6] == .rest && doubled[5] == .open)
        let fresh = WeekReview.marks(week(trained: [4]), perWeek: 6, firstUse: days[3], restToday: false,
                                     now: sunday, calendar: calendar)
        #expect(fresh[0] == .none && fresh[3] == .open && fresh[4] == .trained(1))
    }
}
