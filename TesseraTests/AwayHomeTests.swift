import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// Away (sheet 187): the switch is Off by default and the word reads both ways.
@MainActor
struct AwayHomeTests {
    @Test func theSwitchIsLiveAndStartsOff() throws {
        let row = try #require(ReviewChoices.all.first { $0.id == AwayHome.choiceID })
        #expect(row.defaultValue == "Off" && row.readiness == .live)
        let page = try #require(ReviewChoices.facets.first { $0.ids.contains(AwayHome.choiceID) })
        #expect(page.ids.count <= 6)
    }

    @Test func noTripAwayMeansNoLine() {
        let model = AppModel(context: TesseraSchema.makeContainer(inMemory: true).mainContext,
                             launchDefaults: .testSuite())
        #expect(Away.line(engine: model.engine, now: AppClock.now) == nil)
        #expect(!Away.isAway(engine: model.engine, now: AppClock.now))
    }

    /// SetAway on gives a line on the trip's days; Undo takes it back (QA on #1279).
    @Test func awayOnGivesALineAndUndoClearsIt() throws {
        let model = AppModel(context: TesseraSchema.makeContainer(inMemory: true).mainContext,
                             launchDefaults: .testSuite())
        let now = AppClock.now
        let day = TesseraDay().today(now)
        let end = Calendar.current.date(byAdding: .day, value: 2, to: day) ?? day
        let occasion = try #require(try? model.engine.perform(
            CreateOccasion(title: "Trip", start: day, end: end), by: .user
        ).output)
        #expect(Away.line(engine: model.engine, now: now) == nil)
        let record = try #require(try? model.engine.perform(SetAway(occasion: occasion.id, on: true), by: .user).record)
        #expect(Away.line(engine: model.engine, now: now) != nil)
        #expect(model.engine.undo(record) == .applied)
        #expect(Away.line(engine: model.engine, now: now) == nil)
    }
}
