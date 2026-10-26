import Foundation
@testable import Tessera
import Testing

/// Settings v2 (sheet 154): the switch starts Off, sits on the Rooms page, and the page's new words are fixed.
@MainActor
struct SettingsV2Tests {
    @Test func switchDefaultsOffAndIsLive() throws {
        let choice = try #require(ReviewChoices.all.first { $0.id == SettingsV2.choiceID })
        #expect(choice.defaultValue == "Off")
        #expect(choice.readiness == .live)
        let defaults = try #require(UserDefaults(suiteName: "settings-v2-\(UUID().uuidString)"))
        #expect(ReviewChoices(defaults: defaults, writes: true).value(of: choice) == "Off")
    }

    @Test func sitsOnRoomsWithinSix() throws {
        let rooms = try #require(ReviewChoices.facets.first { $0.word == "Rooms" })
        #expect(rooms.ids.contains(SettingsV2.choiceID))
        #expect(rooms.ids.count <= 6)
    }

    @Test func wordsAreSpecs() {
        #expect(SettingsV2.sentence == "How Tessera works for you")
        #expect(SettingsV2.title == "Settings")
    }
}
