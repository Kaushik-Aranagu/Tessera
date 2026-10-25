import CoreGraphics
import SwiftUI
@testable import Tessera
import Testing

/// Sheet 283 v5, the standing shell: the navigator keeps every route's state, the diff decides each place's move,
/// and the merge table turns the landing's places into the door's.
@MainActor
struct ShellNavigatorTests {
    private let landing = ShellRoute.landing("log")
    private let all = ShellRoute.door("log", "all")

    @Test func pushThenPopRestoresTheLandingStateExactly() {
        let navigator = ShellNavigator(root: landing)
        navigator.state.switcherIndex = 2
        navigator.state.switcherVerticalIndex = 1
        navigator.state.widgetIndex = 3
        navigator.state.dialFocus = 1
        navigator.state.keystonePage = 2
        navigator.state.scrollOffset = 40
        let before = navigator.state

        navigator.push(all)
        #expect(navigator.route == all)
        #expect(navigator.state == RoomState(), "a door starts with its own fresh state")
        navigator.state.scrollOffset = 300

        navigator.pop()
        #expect(navigator.route == landing)
        #expect(navigator.state == before, "back restores every field of the landing's state")
    }

    @Test func aDoorsOwnStateGoesWithItOnPop() {
        let navigator = ShellNavigator(root: landing)
        navigator.push(all)
        navigator.state.scrollOffset = 120
        navigator.pop()
        navigator.push(all)
        #expect(navigator.state.scrollOffset == 0)
    }

    @Test func popAtTheRootDoesNothing() {
        let navigator = ShellNavigator(root: landing)
        navigator.pop()
        #expect(navigator.stack == [landing])
        #expect(navigator.change == nil)
    }

    @Test func aChangeIsInFlightUntilTheShellFinishesIt() throws {
        let navigator = ShellNavigator(root: landing)
        navigator.push(all)
        let change = try #require(navigator.change)
        #expect(change.from == landing)
        #expect(change.to == all)
        #expect(!change.retargeted)
        navigator.finish(change.id)
        #expect(navigator.change == nil)
    }

    @Test func aNewRouteMidChangeRetargetsAndDoesNotQueue() throws {
        let navigator = ShellNavigator(root: landing)
        navigator.push(all)
        let first = try #require(navigator.change)
        // Back before the door has finished arriving.
        navigator.pop()
        let second = try #require(navigator.change)
        #expect(second.id != first.id)
        #expect(second.retargeted)
        #expect(second.from == all, "it starts from what the shell was heading to")
        #expect(second.to == landing)
        // The first change's end is stale and ignored; only one change is ever in flight.
        navigator.finish(first.id)
        #expect(navigator.change == second)
        navigator.finish(second.id)
        #expect(navigator.change == nil)
    }

    @Test func pushingTheCurrentRouteIsIgnored() {
        let navigator = ShellNavigator(root: landing)
        navigator.push(landing)
        #expect(navigator.stack.count == 1)
        #expect(navigator.change == nil)
    }
}

struct ShellDiffTests {
    private func slot(_ id: String, _ kind: SlotKind = .text) -> SlotContent {
        SlotContent(id: ContentID(id), kind: kind, payload: .lines([id]))
    }

    @Test func sameIDIsUntouched() {
        #expect(PlaceMove.diff(slot("log.wall", .wall), slot("log.wall", .wall)) == .untouched)
    }

    @Test func sameIDWithAFreshPayloadIsStillUntouched() {
        let old = SlotContent(id: "log.caption", kind: .text, payload: .lines(["One"]))
        let new = SlotContent(id: "log.caption", kind: .text, payload: .lines(["Two"]))
        #expect(PlaceMove.diff(old, new) == .untouched)
    }

    @Test func sameKindNewIDPlaysThePlacesMove() {
        #expect(PlaceMove.diff(slot("log.nav.bridge"), slot("log.nav.log")) == .move)
    }

    @Test func differentKindCollapsesAndForms() {
        #expect(PlaceMove.diff(slot("a", .wall), slot("b", .list)) == .collapseAndForm)
        #expect(PlaceMove.diff(slot("a", .wall), slot("a", .list)) == .untouched, "identity wins over kind")
    }

    @Test func nilPlaysOnlyOneHalf() {
        #expect(PlaceMove.diff(nil, slot("a")) == .enter)
        #expect(PlaceMove.diff(slot("a"), nil) == .leave)
        #expect(PlaceMove.diff(nil, nil) == .none)
    }

    @Test func theLogKeepsItsKeystoneTitleCaptionAndActionWhenADoorOpens() {
        let content = NotesRoomContent(facts: Self.facts)
        let landing = content.screen(for: .landing("log"), state: RoomState())
        let door = content.screen(for: .door("log", "all"), state: RoomState())
        let plan = PlaceMove.plan(from: landing, to: door)
        #expect(plan[.keystone] == .untouched)
        #expect(plan[.title] == .untouched)
        #expect(plan[.caption] == .untouched)
        #expect(plan[.actionWord] == .untouched)
        #expect(plan[.navWord] == .move, "Bridge becomes Log by the masthead flap")
        #expect(plan[.doorTitle] == .enter)
        #expect(plan[.page] == .enter)
        for place in [Place.switcher, .needs, .widget, .glyph, .dial, .doorSummary] {
            #expect(plan[place] == .leave, "\(place) leaves into the merge")
        }
        #expect(plan[.tess] == Optional(PlaceMove.none), "Tess stays an empty, kept place")
    }

    @Test func turningTheDialMovesOnlyTheSummary() {
        let content = NotesRoomContent(facts: Self.facts)
        let first = content.screen(for: .landing("log"), state: RoomState())
        var turned = RoomState()
        turned.dialFocus = 1
        let plan = PlaceMove.plan(from: first, to: content.screen(for: .landing("log"), state: turned))
        #expect(plan[.doorSummary] == .move)
        #expect(plan[.dial] == .untouched)
        #expect(plan[.keystone] == .untouched)
    }

    @Test func privateNotesNeverReachThePageAsWords() {
        let content = NotesRoomContent(facts: Self.facts)
        let door = content.screen(for: .door("log", "all"), state: RoomState())
        guard case let .list(rows)? = door[.page]?.payload else {
            Issue.record("the All notes door has a page")
            return
        }
        #expect(rows.contains { $0.isPrivate && $0.title == "Private note" })
        #expect(!rows.contains { $0.title.contains("Diary") })
    }

    static var facts: NotesRoomContent.Facts {
        var facts = NotesRoomContent.Facts()
        facts.words = [WallWord(id: "1", text: "Sleep", weight: 1), WallWord(id: "2", text: "Ideas", weight: 0.5)]
        facts.doors = [
            DialDoor(id: "all", name: "All notes", count: "2", color: .black, label: "Newest now", lines: ["Sleep"]),
            DialDoor(id: "loose", name: "Loose", color: .orange, label: "Not about a thing"),
        ]
        facts.sentence = "Your notes are on their own."
        facts.widget = [
            WidgetItem(id: "1", header: "Newest", big: "SLEEP"),
            WidgetItem(id: "2", header: "Newest", big: "IDEAS"),
        ]
        facts.rows = ["all": [
            ShellRow(id: "1", title: "Sleep"),
            ShellRow(id: "3", title: "Private note", isPrivate: true),
        ]]
        return facts
    }
}

struct ShellMergeTests {
    @Test func theMergeTableIsTheSheets() {
        #expect(ShellLayout.merges[.doorTitle] == [.switcher, .needs])
        #expect(ShellLayout.merges[.page] == [.widget, .glyph, .dial, .doorSummary])
    }

    @Test func mergedRectsAreTheUnionOfTheirSources() {
        #expect(ShellLayout.mergedFrame(.doorTitle) == CGRect(x: 24, y: 106, width: 354, height: 76))
        // Widget top 412 down through the breath at 760 (it ends at 776, where the foot starts).
        #expect(ShellLayout.mergedFrame(.page) == CGRect(x: 24, y: 412, width: 354, height: 364))
    }

    @Test func goingThroughADoorMergesAndBackSplits() {
        #expect(ShellLayout.travel(.switcher, from: .landing, to: .door) == .merge(into: .doorTitle))
        #expect(ShellLayout.travel(.needs, from: .landing, to: .door) == .merge(into: .doorTitle))
        for source in [Place.widget, .glyph, .dial, .doorSummary] {
            #expect(ShellLayout.travel(source, from: .landing, to: .door) == .merge(into: .page))
            #expect(ShellLayout.travel(source, from: .door, to: .landing) == .split(from: .page))
        }
        #expect(ShellLayout.travel(.page, from: .landing, to: .door) == .form)
        #expect(ShellLayout.travel(.doorTitle, from: .door, to: .landing) == .form)
    }

    @Test func placesInBothLayoutsGlide() {
        for place in [Place.title, .navWord, .keystone, .caption, .actionWord, .tess] {
            #expect(ShellLayout.travel(place, from: .landing, to: .door) == .glide)
        }
    }

    @Test func aMergedSourceWaitsInItsTargetsRectSoASplitSpreadsFromIt() {
        #expect(ShellLayout.frame(.dial, in: .door) == ShellLayout.mergedFrame(.page))
        #expect(ShellLayout.frame(.switcher, in: .door) == ShellLayout.mergedFrame(.doorTitle))
        #expect(ShellLayout.frame(.dial, in: .landing) == LandingPlace.Doors.dial)
    }

    @Test func everyPlaceExistsInSomeLayout() {
        for place in Place.allCases {
            #expect(ShellLayout.exists(place, in: .landing) || ShellLayout.exists(place, in: .door), "\(place)")
        }
    }

    @Test func theWholeChangeEndsWithinASecond() {
        for place in Place.allCases {
            for move in [PlaceMove.move, .collapseAndForm, .enter, .leave] {
                for (merging, splitting) in [(false, false), (true, false), (false, true)] {
                    let end = ShellTiming.entryEnd(place, move: move, merging: merging, splitting: splitting)
                    #expect(end < 1, "\(place) \(move) ends at \(end)")
                }
            }
        }
    }
}
