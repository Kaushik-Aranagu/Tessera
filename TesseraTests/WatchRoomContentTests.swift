import SwiftUI
@testable import Tessera
import Testing

/// The Watch on the standing shell (283 v5): the woodland stays untouched when a grove opens, the landing and the
/// door page fill the right places, and a private routine never shows its name.
@MainActor
struct WatchRoomContentTests {
    private static func tree(_ name: String, done: Bool = false, due: Bool = true) -> WoodlandTree {
        WoodlandTree(id: UUID(), name: name, isPrivate: name == "Private routine", days: 12, marks: [],
                     doneToday: done, dueToday: due, cap: 104, species: .oak, steps: 3)
    }

    static var facts: WatchRoomContent.Facts {
        let woodland = RoutinesWoodlandFacts(trees: [
            tree("Walk"),
            tree("Journal", done: true),
            tree("Private routine"),
        ])
        var facts = WatchRoomContent.Facts()
        facts.woodland = woodland
        facts.entries = [WatchWords.Entry(name: "Walk", minute: 1080, done: false)]
        facts.doors = WatchRoomContent.Facts.doors(woodland, scheme: .light)
        facts.widget = WatchWords.widget(woodland, wine: .red)
        facts.rows = WatchRoomContent.Facts.rows(woodland)
        return facts
    }

    private let content = WatchRoomContent(facts: Self.facts)

    @Test func openingAGroveLeavesTheWoodlandTitleCaptionAndFootUntouched() {
        let landing = content.screen(for: .landing("watch"), state: RoomState())
        let door = content.screen(for: .door("watch", "today"), state: RoomState())
        let plan = PlaceMove.plan(from: landing, to: door)
        #expect(plan[.keystone] == .untouched)
        #expect(plan[.title] == .untouched)
        #expect(plan[.caption] == .untouched)
        #expect(plan[.actionWord] == .untouched)
        #expect(plan[.navWord] == .move)
        #expect(plan[.doorTitle] == .enter)
        #expect(plan[.page] == .enter)
        for place in [Place.switcher, .needs, .widget, .glyph, .dial, .doorSummary] {
            #expect(plan[place] == .leave, "\(place) leaves into the merge")
        }
    }

    @Test func theLandingFillsItsPlacesAndTheKeystoneIsTheWoods() {
        let landing = content.screen(for: .landing("watch"), state: RoomState())
        #expect(landing.layout == .landing)
        for place in [Place.title, .navWord, .switcher, .needs, .keystone, .caption, .widget, .glyph, .dial,
                      .doorSummary, .actionWord]
        {
            #expect(landing[place] != nil, "\(place) is filled")
        }
        #expect(landing[.doorTitle] == nil)
        #expect(landing[.page] == nil)
        #expect(landing[.tess] == nil)
        #expect(landing[.keystone]?.payload == .scene("watch.woods", label: "Your woodland"))
    }

    @Test func theTodayDoorIsADoorTitleAndAPage() {
        let door = content.screen(for: .door("watch", "today"), state: RoomState())
        #expect(door.layout == .door)
        #expect(door[.doorTitle] != nil)
        #expect(door[.page] != nil)
        for place in [Place.switcher, .needs, .widget, .glyph, .dial, .doorSummary] {
            #expect(door[place] == nil, "\(place) merged away")
        }
        guard case let .list(rows)? = door[.page]?.payload else {
            Issue.record("the Today door has a page")
            return
        }
        #expect(rows.count == 3)
        #expect(rows.contains { $0.title == "Journal" && $0.detail == "Done today" })
    }

    @Test func aPrivateRoutineIsNeverNamed() {
        let door = content.screen(for: .door("watch", "today"), state: RoomState())
        guard case let .list(rows)? = door[.page]?.payload else { return }
        let hidden = rows.first { $0.isPrivate }
        #expect(hidden?.title == "Private routine")
    }

    @Test func turningTheSwitcherChangesOnlyTheNeeds() {
        var night = RoomState()
        night.switcherIndex = WatchTime.night.rawValue
        let plan = PlaceMove.plan(from: content.screen(for: .landing("watch"), state: RoomState()),
                                  to: content.screen(for: .landing("watch"), state: night))
        #expect(plan[.needs] == .move)
        #expect(plan[.keystone] == .untouched)
        #expect(plan[.dial] == .untouched)
    }

    @Test func theFootIsPlantThenWaterAndPause() {
        guard case let .action(steps, _)? = content.screen(for: .landing("watch"), state: RoomState())[.actionWord]?
            .payload
        else {
            Issue.record("the foot has steps")
            return
        }
        #expect(steps.map(\.verb) == ["Plant", "Water", "Pause"])
    }

    @Test func namingATreeMovesTheCaptionOnly() {
        var named = Self.facts
        named.selected = named.trees.first?.id
        let plan = PlaceMove.plan(from: content.screen(for: .landing("watch"), state: RoomState()),
                                  to: WatchRoomContent(facts: named).screen(for: .landing("watch"), state: RoomState()))
        #expect(plan[.caption] == .move)
        #expect(plan[.keystone] == .untouched)
    }

    @Test func theRegistryOpensTheWatch() {
        #expect(ShellRooms.ids.contains("watch"))
    }
}
