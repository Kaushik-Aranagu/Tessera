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
}
