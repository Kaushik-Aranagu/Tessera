import Foundation
@testable import Tessera
import TesseraCore
import Testing

@MainActor
struct HubChoicesTests {
    private func fresh() -> ReviewChoices {
        let name = "hub.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return ReviewChoices(defaults: defaults, writes: true, usesFlags: true)
    }

    @Test func aFreshPhoneReadsTheMosaicHomeAndTodaysPageTurn() {
        let choices = fresh()
        #expect(HubChoices.selected("homeIs", choices: choices)?.id == "mosaic")
        #expect(HubChoices.selected("pagesTurnBy", choices: choices)?.id == "today")
    }

    @Test func choosingHomeV2TurnsTheMosaicOffAndUndoPutsItBack() throws {
        let choices = fresh()
        let undo = HubChoices.choose("homeV2", in: "homeIs", choices: choices)
        #expect(HubChoices.selected("homeIs", choices: choices)?.id == "homeV2")
        let mosaic = try #require(ReviewChoices.all.first { $0.id == "homeMosaic" })
        #expect(choices.value(of: mosaic) == "Off")
        HubChoices.restore(undo, choices: choices)
        #expect(HubChoices.selected("homeIs", choices: choices)?.id == "mosaic")
        #expect(choices.value(of: mosaic) == "On")
    }

    @Test func choosingARotatingPageTurnSetsThePageTurnAndLeavesAWaitingLayoutAlone() throws {
        let choices = fresh()
        HubChoices.choose("rotate", in: "pagesTurnBy", choices: choices)
        let turn = try #require(ReviewChoices.all.first { $0.id == "pageTurn" })
        let layout = try #require(ReviewChoices.all.first { $0.id == "readingLayout" })
        #expect(choices.value(of: turn) == "Rotate")
        // The reading layout waits for the sheet 99 refit, so it keeps reading Today until that lands.
        #expect(choices.value(of: layout) == "Today")
    }

    @Test func developerModeListsOnlyFlagsTheMainPageDoesNotCarry() {
        let ids = FeatureFlags.developerGroups(off: []).flatMap { $0.flags.map(\.flag.id) }
        #expect(ids.contains("twinsV2"))
        #expect(HubChoices.onMainPage.isSubset(of: Set(FeatureFlags.all.map(\.id))))
    }
}
