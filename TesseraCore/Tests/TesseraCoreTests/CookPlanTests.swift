import Foundation
@testable import TesseraCore
import Testing

/// Multi-dish Cook, Part A: the pure plan. D1 is paprika chicken (43 min, hands 0-4 and 37-43), D2 spaghetti (14 min,
/// hands 0-4 and 10-14).
struct CookPlanTests {
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    func at(_ hour: Int, _ minute: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 22, hour: hour, minute: minute))!
    }

    func m(_ minutes: Double) -> TimeInterval {
        minutes * 60
    }

    func chicken(finish: CookPlan.Finish = .standard, startedAt: Date? = nil, extra: Double = 0) -> CookPlan.Dish {
        CookPlan.Dish(name: "Chicken", order: 0, local: [
            .init(step: 0, start: 0, end: m(4), kind: .hands),
            .init(step: 1, start: m(4), end: m(37 + extra), kind: .wait),
            .init(step: 2, start: m(37 + extra), end: m(43 + extra), kind: .hands),
        ], finish: finish, startedAt: startedAt)
    }

    func spaghetti(finish: CookPlan.Finish = .standard, skipped: Int = 0, plural: Bool? = nil) -> CookPlan.Dish {
        CookPlan.Dish(name: "Spaghetti", order: 1, local: [
            .init(step: 0, start: 0, end: m(4), kind: .hands),
            .init(step: 1, start: m(4), end: m(10), kind: .wait),
            .init(step: 2, start: m(10), end: m(14), kind: .hands),
        ], finish: finish, skippedFits: skipped, isPlural: plural)
    }

    func start(of name: String, in plan: CookPlan) -> Date? {
        plan.placements.first { $0.dish.name == name }?.start
    }

    @Test func multiAnchorsBackwardFromServe() {
        // Hands clear: spaghetti with a 4 minute wait only (no collision).
        let quick = CookPlan.Dish(name: "Salad", order: 1, local: [
            .init(step: 0, start: 0, end: m(5), kind: .hands), .init(step: 1, start: m(5), end: m(15), kind: .wait),
        ])
        let plan = CookPlan.make(dishes: [chicken(), quick], serveAt: at(19, 0), now: at(17, 0))
        #expect(start(of: "Chicken", in: plan) == at(18, 17))
        #expect(start(of: "Salad", in: plan) == at(18, 45))
        #expect(plan.projectedServe == nil)
    }

    @Test func handsConflictShiftsShorterDish() {
        let plan = CookPlan.make(dishes: [chicken(), spaghetti()], serveAt: at(19, 0), now: at(17, 0))
        #expect(start(of: "Chicken", in: plan) == at(18, 17))
        #expect(start(of: "Spaghetti", in: plan) == at(18, 40))
        let spaghettiPlace = plan.placements[1]
        #expect(spaghettiPlace.heldSec == m(6) && !spaghettiPlace.overHold)
        #expect(plan.notes() == ["Spaghetti will wait 6 min.", "Spaghetti starts 6 min early so your hands are free."])
        // No two hands stretches overlap.
        let hands = plan.segs.filter { $0.kind == .hands }
        for (index, lhs) in hands.enumerated() {
            for rhs in hands[(index + 1)...] {
                #expect(lhs.end <= rhs.start || rhs.end <= lhs.start)
            }
        }
    }

    @Test func serveTimeWithNoneIsNowPlusLongest() {
        let plan = CookPlan.make(dishes: [chicken(), spaghetti()], serveAt: nil, now: at(17, 0))
        #expect(plan.serveAt == at(17, 43) && start(of: "Chicken", in: plan) == at(17, 0))
        // A serve time in the past is ignored.
        let past = CookPlan.make(dishes: [chicken()], serveAt: at(16, 0), now: at(17, 0))
        #expect(past.serveAt == at(17, 43) && !past.isLate)
    }

    @Test func overHoldKeepsPlan() {
        // Rice: hands 0-2 and 20-22; chicken hands at the same two ends makes a 22 min fit.
        let rice = CookPlan.Dish(name: "Rice", order: 1, local: [
            .init(step: 0, start: 0, end: m(2), kind: .hands), .init(step: 1, start: m(2), end: m(20), kind: .wait),
            .init(step: 2, start: m(20), end: m(22), kind: .hands),
        ])
        let blocker = CookPlan.Dish(name: "Stew", order: 0, local: [
            .init(step: 0, start: 0, end: m(1), kind: .hands), .init(step: 1, start: m(1), end: m(40), kind: .wait),
            .init(step: 2, start: m(40), end: m(60), kind: .hands),
        ])
        let plan = CookPlan.make(dishes: [blocker, rice], serveAt: at(19, 0), now: at(17, 0))
        // Rice's last hands (18:58-19:00) overlap Stew's last (18:40-19:00): it moves 20 min earlier to clear.
        let place = plan.placements[1]
        #expect(place.heldSec == m(20) && place.overHold)
        #expect(plan.notes() == ["Rice would wait 20 min."])
        #expect(start(of: "Rice", in: plan) == at(18, 18))
    }

    @Test func startLaterTriesTheNextFit() {
        let first = CookPlan.make(dishes: [chicken(), spaghetti()], serveAt: at(19, 0), now: at(17, 0))
        let later = CookPlan.make(dishes: [chicken(), spaghetti(skipped: 1)], serveAt: at(19, 0), now: at(17, 0))
        let delta = { (plan: CookPlan) in plan.placements[1].heldSec }
        #expect(delta(later) > delta(first))
    }

    @Test func projectedLateOnSlowStep() {
        // Chicken started at 6:17 and its wait runs 2 min long: it ends at 7:02.
        let plan = CookPlan.make(dishes: [chicken(startedAt: at(18, 17), extra: 2), spaghetti()],
                                 serveAt: at(19, 0), now: at(18, 30))
        #expect(plan.projectedServe == at(19, 2))
        #expect(plan.lateLine(calendar: calendar) == "Serving about 7:02.")
        // Running timers never move.
        #expect(start(of: "Chicken", in: plan) == at(18, 17))
    }

    @Test func nothingStartsInThePast() {
        let plan = CookPlan.make(dishes: [chicken()], serveAt: at(18, 30), now: at(18, 0))
        #expect(start(of: "Chicken", in: plan) == at(18, 0))
        #expect(plan.projectedServe == at(18, 43))
    }

    @Test func pauseShiftsBothDishes() {
        let plan = CookPlan.make(dishes: [chicken(), spaghetti()], serveAt: at(19, 0), now: at(17, 0))
        let paused = plan.shifted(by: m(5))
        #expect(start(of: "Chicken", in: paused) == at(18, 22) && start(of: "Spaghetti", in: paused) == at(18, 45))
        #expect(paused.serveAt == at(19, 5))
    }

    @Test func addDishMidCookPlacesAgainstHandsFromNow() {
        let running = CookPlan.make(dishes: [chicken(startedAt: at(18, 17))], serveAt: at(19, 0), now: at(18, 20))
        let added = CookPlan.make(dishes: [chicken(startedAt: at(18, 17)), spaghetti()], serveAt: at(19, 0),
                                  now: at(18, 20))
        #expect(running.placements.count == 1 && added.placements.count == 2)
        #expect(start(of: "Chicken", in: added) == at(18, 17))
        #expect(start(of: "Spaghetti", in: added) == at(18, 40))
        // Late enough that nothing fits before now: it starts now and the plan runs over.
        let tooLate = CookPlan.make(dishes: [chicken(startedAt: at(18, 17)), spaghetti()], serveAt: at(19, 0),
                                    now: at(18, 55))
        #expect((start(of: "Spaghetti", in: tooLate) ?? .distantPast) >= at(18, 55) && tooLate.isLate)
    }

    @Test func oneDishEqualsTodaysClock() {
        let plan = CookPlan.make(dishes: [chicken()], serveAt: nil, now: at(17, 0))
        #expect(plan.placements.count == 1 && plan.notes().isEmpty && !plan.isLate)
        let seg = plan.segs.map { ($0.start.timeIntervalSince(at(17, 0)), $0.end.timeIntervalSince(at(17, 0))) }
        #expect(seg.map(\.0) == [0, m(4), m(37)] && seg.map(\.1) == [m(4), m(37), m(43)])
    }

    @Test func allWaitDishesNeverConflict() {
        let stock = CookPlan.Dish(name: "Stock", order: 0, local: [.init(step: 0, start: 0, end: m(60), kind: .wait)])
        let beans = CookPlan.Dish(name: "Beans", order: 1, local: [.init(step: 0, start: 0, end: m(30), kind: .wait)])
        let plan = CookPlan.make(dishes: [stock, beans], serveAt: at(19, 0), now: at(17, 0))
        #expect(plan.placements.allSatisfy { $0.heldSec == 0 })
    }

    // MARK: Finish options

    @Test func holdsWarmRaisesTheLimit() {
        let plan = CookPlan.make(dishes: [chicken(), spaghetti(finish: .holdsWarm(minutes: 5))], serveAt: at(19, 0),
                                 now: at(17, 0))
        #expect(plan.placements[1].heldSec == m(6) && plan.placements[1].overHold)
        let roomy = CookPlan.make(dishes: [chicken(), spaghetti(finish: .holdsWarm(minutes: 30))],
                                  serveAt: at(19, 0), now: at(17, 0))
        #expect(!roomy.placements[1].overHold)
    }

    @Test func lastNoWaitingIsNeverMoved() {
        // Spaghetti is "last": it is placed first at its anchor and the chicken, the longer dish, fits around it.
        let plan = CookPlan.make(dishes: [chicken(), spaghetti(finish: .last)], serveAt: at(19, 0), now: at(17, 0))
        #expect(start(of: "Spaghetti", in: plan) == at(18, 46) && plan.placements[1].heldSec == 0)
        #expect(plan.placements[0].heldSec > 0)
    }

    // MARK: Words

    @Test func pluralAgreement() {
        let beans = CookPlan.Dish(name: "Beans", order: 0, local: [])
        let rice = CookPlan.Dish(name: "Rice", order: 0, local: [])
        let hummus = CookPlan.Dish(name: "Hummus", order: 0, local: [])
        let mashed = CookPlan.Dish(name: "Mashed potatoes", order: 0, local: [])
        let grass = CookPlan.Dish(name: "Watercress", order: 0, local: [])
        #expect(CookPlan.isPlural(beans) && CookPlan.isPlural(mashed))
        #expect(!CookPlan.isPlural(rice) && !CookPlan.isPlural(hummus) && !CookPlan.isPlural(grass))
        let flagged = CookPlan.Dish(name: "Couscous", order: 0, local: [], isPlural: true)
        #expect(CookPlan.isPlural(flagged))
        let plan = CookPlan.make(dishes: [chicken(), spaghetti(plural: true)], serveAt: at(19, 0), now: at(17, 0))
        #expect(plan.notes().last == "Spaghetti start 6 min early so your hands are free.")
    }

    @Test func landingAndRunningSentences() {
        let plan = CookPlan.make(dishes: [chicken(), spaghetti()], serveAt: at(19, 0), now: at(17, 0))
        #expect(plan.landing(calendar: calendar) == "Chicken and Spaghetti tonight, start at 6:17.")
        #expect(plan.running(minutesLeft: 12) == "Cooking Chicken and Spaghetti, 12 min left.")
        #expect(plan.serveLine(calendar: calendar) == "Serve at 7:00. Start Chicken at 6:17.")
        #expect(CookPlan.names(["A", "B", "C"]) == "A, B and C")
        #expect(CookPlan.names(["A", "B", "C", "D", "E"]) == "A, B and 3 more")
        #expect(CookPlan.names(["A", "B", "C", "D"]) == "A, B and 2 more")
        #expect(plan.lateLine(calendar: calendar) == nil)
    }

    @Test func privateNamesStayMaskedEverywhere() {
        let secret = CookPlan.Dish(name: "Private recipe", order: 0, local: [.init(step: 0, start: 0, end: m(10),
                                                                                   kind: .hands)])
        let plan = CookPlan.make(dishes: [secret, spaghetti()], serveAt: at(19, 0), now: at(17, 0))
        let lines = [plan.landing(calendar: calendar), plan.running(minutesLeft: 5), plan.serveLine(calendar: calendar)]
            + plan.notes()
        #expect(lines.allSatisfy { !$0.contains("Knee") })
        #expect(lines.contains { $0.contains("Private recipe") })
    }

    @Test func noRealNameIsEverAClaudeJob() throws {
        let sources = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appending(path: "Sources/TesseraTess")
        for file in try FileManager.default.contentsOfDirectory(at: sources, includingPropertiesForKeys: nil)
            where file.pathExtension == "swift"
        {
            #expect(try !String(contentsOf: file, encoding: .utf8).contains("CookPlan"), "\(file.lastPathComponent)")
        }
    }
}
