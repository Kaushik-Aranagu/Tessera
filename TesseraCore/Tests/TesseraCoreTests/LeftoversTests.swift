import Foundation
@testable import TesseraCore
import Testing

/// Leftovers for the Galley's Tonight and Leftovers doors.
@MainActor
struct LeftoversTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    /// Wednesday, Oct 28, 2026, 18:00 UTC.
    let now = Date(timeIntervalSince1970: 1_793_210_400)

    init() throws {
        classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
        engine.now = { Date(timeIntervalSince1970: 1_793_210_400) }
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        engine.zone = { utc.timeZone }
    }

    var rows: [Leftovers.Row] {
        Leftovers.rows(store: store, now: now, calendar: calendar)
    }

    func day(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now))!
    }

    @Test func nothingKeptMeansNoRowsAndNoLine() {
        #expect(rows.isEmpty && Leftovers.line(store: store, now: now, calendar: calendar) == nil)
        #expect(Leftovers.tonight(store: store, now: now, calendar: calendar) == nil)
    }

    @Test func theSampleIsRiceGoingOutTodayAndDalGoingOutFridayAndReadsAsTheBoardSays() throws {
        try Leftovers.seedSample(store: store, classes: classes, now: now, calendar: calendar)
        #expect(rows.map(\.what) == ["Rice", "Dal"])
        let rice = rows[0], dal = rows[1]
        #expect(rice.state == .today && rice.sub == "Goes out today" && rice.value == "Today")
        #expect(dal.state == .later && dal.sub == "Cooked Tuesday" && dal.value == "Fri")
        #expect(Leftovers.line(store: store, now: now, calendar: calendar) == "Eat the rice today")
        let tonight = Leftovers.tonight(store: store, now: now, calendar: calendar)
        #expect(tonight?.what == "Rice" && tonight?.sub == "Leftover, goes out today" && tonight?.value == "side")
        #expect(try Leftovers.seedSample(store: store, classes: classes, now: now, calendar: calendar).isEmpty, "once")
    }

    @Test func aLeftoverKeptFromACookRemembersItAndNoDayIsGuessed() throws {
        let recipe = try engine.perform(CreateRecipe(text: RecipeParserTests.carbonara), by: .user).output
        let cook = try engine.perform(StartCooking(recipe: recipe.id, serves: 4, time: day(-1)), by: .user).output
        let kept = try engine.perform(AddLeftover(what: "Carbonara", cookedOn: day(-1), cook: cook.id), by: .user)
        let row = try #require(rows.first)
        #expect(row.source == cook.id && row.goesOutOn == nil && row.state == .noDate && row.value.isEmpty)
        #expect(row.sub == "Cooked Tuesday")
        #expect(kept.record.receipt == "Carbonara, kept")
        #expect(Leftovers.line(store: store, now: now, calendar: calendar) == nil, "no day, no line")
        #expect(throws: ActionError.self) { try engine.perform(AddLeftover(what: "  "), by: .user) }
    }

    @Test func overdueGoesFirstAndTheDayAfterOutIsNamed() throws {
        try engine.perform(AddLeftover(what: "Soup", cookedOn: day(-5), goesOutOn: day(-1)), by: .user)
        try engine.perform(AddLeftover(what: "Rice", goesOutOn: day(0)), by: .user)
        try engine.perform(AddLeftover(what: "Dal", goesOutOn: day(2)), by: .user)
        #expect(rows.map(\.what) == ["Soup", "Rice", "Dal"])
        #expect(rows[0].state == .overdue && rows[0].sub == "Went out Tuesday")
        #expect(rows[2].sub == "Goes out Friday", "no cooked day: the day it goes out")
    }

    @Test func eatenOrThrownOutLeavesTheListAndUndoBringsItBack() throws {
        try Leftovers.seedSample(store: store, classes: classes, now: now, calendar: calendar)
        let rice = try #require(rows.first)
        let done = try engine.perform(FinishLeftover(leftover: rice.id), by: .user)
        #expect(rows.map(\.what) == ["Dal"] && done.record.receipt == "Rice, done")
        #expect(Leftovers.line(store: store, now: now, calendar: calendar) == "Eat the dal by Friday")
        engine.undo(done.record)
        #expect(rows.map(\.what) == ["Rice", "Dal"])
    }
}
