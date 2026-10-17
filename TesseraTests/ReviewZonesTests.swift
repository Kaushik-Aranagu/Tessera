import Foundation
@testable import Tessera
@testable import TesseraCore
import Testing

/// Trip R12 (board 0ae, before Oct 26): Review counts a task done and a cook where they happened, so a 6:30 am
/// Wednesday in New York stays Wednesday's when he reads the week at home in Los Angeles.
@MainActor
struct ReviewZonesTests {
    static let la = TimeZone(identifier: "America/Los_Angeles")!
    static let newYork = TimeZone(identifier: "America/New_York")!

    @Test func aHotelWednesdayCountsOnWednesday() throws {
        let container = TesseraSchema.makeContainer(inMemory: true)
        let model = AppModel(context: container.mainContext)
        var home = Calendar(identifier: .gregorian)
        home.timeZone = Self.la
        var there = home
        there.timeZone = Self.newYork
        let when = try #require(there.date(from: DateComponents(year: 2026, month: 10, day: 21, hour: 6, minute: 30)))
        model.engine.zone = { Self.newYork }
        let task = try model.engine.perform(CreateTask(title: "call the hotel"), by: .user).output
        let done = try model.engine.perform(SetTaskDone(task: task.id, time: when), by: .user)
        done.record.createdAt = when
        model.engine.zone = { Self.la }
        let friday = try #require(home.date(from: DateComponents(year: 2026, month: 10, day: 23, hour: 21)))
        let week = ReviewWeekData.compute(model, now: friday, calendar: home)
        let wednesday = try #require(week.days.firstIndex { home.component(.weekday, from: $0) == 4 })
        #expect(week.tasksDone[wednesday] == 1 && week.tasksDone[wednesday - 1] == 0)
    }
}
