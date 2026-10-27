import SwiftUI
@testable import Tessera
import Testing

/// The Galley on the standing shell (283 v5): the pass keeps its id when a door opens, the door page fills the Door
/// title and Page and leaves the landing's own places, and a walled dish never reaches a page as words.
@MainActor
struct GalleyRoomContentTests {
    @Test func thePassStaysOnTheRailWhenADoorOpens() {
        let content = GalleyRoomContent(facts: Self.facts)
        let landing = content.screen(for: .landing("galley"), state: RoomState())
        let door = content.screen(for: .door("galley", "tonight"), state: RoomState())
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

    @Test func theLandingFillsItsPlacesAndLeavesTheDoorsOnes() {
        let screen = GalleyRoomContent(facts: Self.facts).screen(for: .landing("galley"), state: RoomState())
        #expect(screen.layout == .landing)
        for place in [Place.title, .navWord, .switcher, .needs, .keystone, .caption, .widget, .glyph, .dial,
                      .doorSummary, .actionWord]
        {
            #expect(screen[place] != nil, "\(place) is filled")
        }
        for place in [Place.doorTitle, .page, .tess] {
            #expect(screen[place] == nil, "\(place) is empty")
        }
        guard case let .scene(key, _)? = screen[.keystone]?.payload else {
            Issue.record("the keystone is the pass scene")
            return
        }
        #expect(key == GalleyRoomContent.sceneKey)
    }

    @Test func theDoorPageFillsTitleAndPage() {
        let screen = GalleyRoomContent(facts: Self.facts).screen(for: .door("galley", "tonight"), state: RoomState())
        #expect(screen.layout == .door)
        #expect(screen[.doorTitle] != nil)
        #expect(screen[.page] != nil)
        for place in [Place.switcher, .needs, .widget, .glyph, .dial, .doorSummary, .tess] {
            #expect(screen[place] == nil, "\(place) is empty on a door page")
        }
        guard case let .doorTitle(name, line, _)? = screen[.doorTitle]?.payload else {
            Issue.record("door title")
            return
        }
        #expect(name == "Tonight")
        #expect(line == "2 dinners planned")
    }

    @Test func aWalledDishReadsPrivateRecipeOnThePage() {
        let screen = GalleyRoomContent(facts: Self.facts).screen(for: .door("galley", "tonight"), state: RoomState())
        guard case let .list(rows)? = screen[.page]?.payload else {
            Issue.record("the Tonight door has a page")
            return
        }
        #expect(rows.contains { $0.isPrivate && $0.title.hasSuffix("Private recipe") })
        #expect(!rows.contains { $0.title.contains("Secret") })
    }

    @Test func theSwitcherChangesOnlyTheNeeds() {
        let content = GalleyRoomContent(facts: Self.facts)
        var tomorrow = RoomState()
        tomorrow.switcherIndex = 1
        let plan = PlaceMove.plan(from: content.screen(for: .landing("galley"), state: RoomState()),
                                  to: content.screen(for: .landing("galley"), state: tomorrow))
        #expect(plan[.needs] == .move)
        #expect(plan[.keystone] == .untouched)
        #expect(plan[.dial] == .untouched)
    }

    @Test func cookIsAVerbOverTonightsDish() {
        let screen = GalleyRoomContent(facts: Self.facts).screen(for: .landing("galley"), state: RoomState())
        guard case let .action(steps, _)? = screen[.actionWord]?.payload else {
            Issue.record("action")
            return
        }
        #expect(steps.map(\.verb) == ["Cook", "Get"])
        #expect(steps.first?.object == "Tacos")
    }

    @Test func theDialFocusOnTonightIsOchre() {
        #expect(GalleyRoomContent.tone(door: "tonight", lowEmpty: true) == .ochre)
        #expect(GalleyRoomContent.tone(door: "pantry", lowEmpty: false) == .wine)
    }

    @Test func theRoomIsRegistered() {
        #expect(ShellRooms.ids.contains(GalleyRoomContent.room))
    }

    static var facts: GalleyRoomContent.Facts {
        var facts = GalleyRoomContent.Facts()
        facts.pass = GalleyPass.build(
            dinner: .init(recipe: nil, title: "Tacos", isPrivate: false, start: "6:05 pm", ingredients: ["Tortillas"]),
            toGet: ["Milk"], stock: [.init(name: "Eggs", state: .low, isPrivate: false)], cookable: [], cooking: nil
        )
        facts.doors = [
            DialDoor(id: "tonight", name: "Tonight", color: .orange, label: "Next 7 days", lines: ["Mon Tacos"]),
            DialDoor(id: "pantry", name: "Pantry", count: "1", color: .red, label: "Running low", lines: ["Eggs"]),
        ]
        facts.needs = [["Tacos tonight", "start 6:05 pm"], ["Nothing planned tomorrow", "Plan it from Recipes"],
                       ["2 dinners planned", "1 to get"]]
        facts.caption = "Swipe a ticket up for its next page"
        facts.widget = [WidgetItem(id: "dinner", header: "Dinner", big: "Tacos", strikeable: false)]
        facts.cookObject = "Tacos"
        facts.rows = ["tonight": [
            ShellRow(id: "a", title: "Mon Tacos", detail: "6:05 pm"),
            ShellRow(id: "b", title: "Wed Private recipe", detail: "7 pm", isPrivate: true),
        ]]
        return facts
    }
}
