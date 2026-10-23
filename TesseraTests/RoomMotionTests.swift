@testable import Tessera
import Testing

/// Room motion (Design 138): the timings are the sheet's, and the switch ships Off.
struct RoomMotionTests {
    @Test func timingsAreTheSheets() {
        #expect(RoomTiming.receipt == 0.42)
        #expect(RoomTiming.titleCrossfade == 0.2)
        #expect(RoomTiming.shift == 0.3)
    }

    @Test func theTitleSaysTheWordUntilItSettlesThenTheApp() {
        #expect(RoomTitleRule.shown(appName: "Kitchen", openedBy: "Tacos", settled: false, switchOn: true) == "Tacos")
        #expect(RoomTitleRule.shown(appName: "Kitchen", openedBy: "Tacos", settled: true, switchOn: true) == "Kitchen")
        // Opened another way, or the switch Off: always the app's name.
        #expect(RoomTitleRule.shown(appName: "Kitchen", openedBy: nil, settled: false, switchOn: true) == "Kitchen")
        #expect(RoomTitleRule
            .shown(appName: "Kitchen", openedBy: "Tacos", settled: false, switchOn: false) == "Kitchen")
    }

    @Test func reduceMotionNeverWaitsForTheWord() {
        #expect(RoomTitleRule.waits(openedBy: "Tacos", switchOn: true, reduceMotion: false))
        #expect(!RoomTitleRule.waits(openedBy: "Tacos", switchOn: true, reduceMotion: true))
        #expect(!RoomTitleRule.waits(openedBy: nil, switchOn: true, reduceMotion: false))
        #expect(!RoomTitleRule.waits(openedBy: "Tacos", switchOn: false, reduceMotion: false))
    }

    @Test func theSwitchShipsOffAndLive() throws {
        let choice = try #require(ReviewChoices.all.first { $0.id == "roomMotion" })
        #expect(choice.defaultValue == "Off")
        #expect(choice.readiness == .live)
    }

    @Test func theShownTabHoldsAtMostSixRows() throws {
        let shown = try #require(ReviewChoices.facets.first { $0.word == "Shown" })
        #expect(shown.ids.count <= 6)
    }
}
