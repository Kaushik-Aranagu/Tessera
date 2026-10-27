import Foundation
import SwiftUI
@testable import Tessera
import Testing

/// Settings through the standing shell: the wall, title and caption keep their ids when a door opens; no action word
/// anywhere; nothing key-shaped on any place.
@MainActor
struct SettingsRoomContentTests {
    static var facts: SettingsRoomContent.Facts {
        SettingsRoomContent.Facts(
            settings: SettingsLandingFacts(remembers: "12 things", asksClaude: true, units: ["kg", "km", "°F"],
                                           backupLine: "Last backup this afternoon, 1:11 pm", build: "1.0 (100)",
                                           privacyLines: ["3 notes are private"]),
            seen: [:],
            colors: SettingsLandingWords.Colors(ink: .black, slate: .blue, green: .green, gold: .yellow)
        )
    }

    @Test func openingADoorLeavesTheWallUntouched() {
        let content = SettingsRoomContent(facts: Self.facts)
        let landing = content.screen(for: .landing("settings"), state: RoomState())
        let door = content.screen(for: .door("settings", "tess"), state: RoomState())
        let plan = PlaceMove.plan(from: landing, to: door)
        #expect(plan[.keystone] == .untouched)
        #expect(plan[.title] == .untouched)
        #expect(plan[.caption] == .untouched)
        #expect(plan[.navWord] == .move)
        #expect(plan[.doorTitle] == .enter)
        #expect(plan[.page] == .enter)
        #expect(plan[.actionWord] == Optional(PlaceMove.none), "Settings has no action word")
    }

    @Test func theLandingAndDoorFillTheRightPlaces() {
        let content = SettingsRoomContent(facts: Self.facts)
        let landing = content.screen(for: .landing("settings"), state: RoomState())
        for place in [Place.title, .navWord, .switcher, .needs, .keystone, .caption, .widget, .glyph, .dial,
                      .doorSummary]
        {
            #expect(landing[place] != nil, "\(place) is filled")
        }
        for place in [Place.doorTitle, .page, .actionWord, .tess] {
            #expect(landing[place] == nil, "\(place) is empty")
        }
        let door = content.screen(for: .door("settings", "tess"), state: RoomState())
        for place in [Place.switcher, .needs, .widget, .glyph, .dial, .doorSummary, .actionWord] {
            #expect(door[place] == nil, "\(place) is empty on a door page")
        }
        guard case let .list(rows)? = door[.page]?.payload else {
            Issue.record("Tess has a page")
            return
        }
        #expect(rows.last?.id == "open:tess")
        #expect(SettingsRoomContent.area(for: "open:tess") == .tess)
        #expect(SettingsRoomContent.area(for: "line#0") == nil)
    }

    @Test func theSixDoorsAreTheScaffolds() {
        let doors = SettingsRoomContent(facts: Self.facts).doors.map(\.id)
        #expect(doors == SettingsArea.doors.map(\.rawValue))
    }

    @Test func nothingKeyShapedReachesAPlace() {
        let content = SettingsRoomContent(facts: Self.facts)
        let screens = [content.screen(for: .landing("settings"), state: RoomState())]
            + SettingsArea.doors.map { content.screen(for: .door("settings", $0.rawValue), state: RoomState()) }
        for screen in screens {
            let text = "\(screen.slots.values.map(\.payload))"
            #expect(!text.contains("sk-ant"))
        }
    }
}
