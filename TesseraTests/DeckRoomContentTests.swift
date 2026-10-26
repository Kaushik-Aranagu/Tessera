import Foundation
import SwiftUI
@testable import Tessera
import Testing

/// Deck through the standing shell (sheet 283 v5): the board keystone, title, caption and foot keep their ids when a
/// door opens; the landing and door screens fill the right places; private routines never reach a page.
@MainActor
struct DeckRoomContentTests {
    private static let exercise = UUID()
    private static let routine = UUID()

    static func facts(day: TrainingDay = .ready(name: "Push A", minutes: 45, lifts: 4),
                      action: TrainingFoot? = TrainingFoot(verb: "Start", object: "Push A", hold: true),
                      restOption: String? = nil) -> DeckRoomContent.Facts
    {
        let words = [
            WallWord(id: TrainingWallTarget.exercise(exercise).id, text: "Bench", weight: 1),
            WallWord(id: TrainingWallTarget.routine(routine).id, text: "Push A", weight: 0.8),
        ]
        let doors = [
            DialDoor(id: "today", name: "Today", color: .blue, label: "Push, 4 lifts", lines: ["Bench 80 kg", "Row"]),
            DialDoor(id: "week", name: "This week", color: .blue, label: "Monday to Sunday", lines: ["2 done"]),
            DialDoor(id: "library", name: "Library", color: .yellow, lines: ["12 exercises"]),
        ]
        let wall = TrainingWallFacts(day: day, words: words, doors: doors, brief: nil, action: action,
                                     restOption: restOption)
        let board = TrainingBoard(headline: "Push A today", detail: "Bench opens at 80 kg.",
                                  week: [BoardDay(id: 0, letter: "M", done: true, isToday: false),
                                         BoardDay(id: 1, letter: "T", done: false, isToday: true)],
                                  bests: [BoardBest(id: exercise, lift: "Bench", number: "82.5 kg")])
        let deck = TrainingDeckFacts(board: board, routineWords: ["Push A", "Private workout"],
                                     needs: [["Push A today.", "Bench"], ["2 done", "1 to go"], ["8 this month", ""]],
                                     widget: [WidgetItem(id: "today", header: "Tonight", big: "PUSH A"),
                                              WidgetItem(id: "week", header: "This week", big: "2")])
        return DeckRoomContent.Facts(wall: wall, deck: deck, rows: DeckRoomContent.Facts.rows(wall: wall, deck: deck))
    }

    @Test func openingADoorLeavesTheBoardUntouched() {
        let content = DeckRoomContent(facts: Self.facts())
        let landing = content.screen(for: .landing("deck"), state: RoomState())
        let door = content.screen(for: .door("deck", "today"), state: RoomState())
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
        #expect(ShellPlan(from: door, to: landing).oldLayout == .door)
    }

    @Test func theLandingFillsItsPlaces() {
        let landing = DeckRoomContent(facts: Self.facts()).screen(for: .landing("deck"), state: RoomState())
        #expect(landing.layout == .landing)
        for place in [Place.title, .navWord, .switcher, .needs, .keystone, .caption, .widget, .glyph, .dial,
                      .doorSummary, .actionWord]
        {
            #expect(landing[place] != nil, "\(place) is filled")
        }
        for place in [Place.doorTitle, .page, .tess] {
            #expect(landing[place] == nil, "\(place) is empty on the landing")
        }
        guard case let .scene(key, _)? = landing[.keystone]?.payload else {
            Issue.record("the keystone is the board scene")
            return
        }
        #expect(key == DeckRoomContent.boardKey)
    }

    @Test func theDoorPageFillsTitleAndPage() {
        let door = DeckRoomContent(facts: Self.facts()).screen(for: .door("deck", "today"), state: RoomState())
        #expect(door.layout == .door)
        for place in [Place.title, .navWord, .doorTitle, .keystone, .caption, .page, .actionWord] {
            #expect(door[place] != nil, "\(place) is filled")
        }
        for place in [Place.switcher, .needs, .widget, .glyph, .dial, .doorSummary, .tess] {
            #expect(door[place] == nil, "\(place) is empty on a door page")
        }
        guard case let .list(rows)? = door[.page]?.payload else {
            Issue.record("Today has a page")
            return
        }
        #expect(rows.map(\.title) == ["Bench 80 kg", "Row"])
    }

    @Test func turningTheDialMovesOnlyTheSummary() {
        let content = DeckRoomContent(facts: Self.facts())
        var turned = RoomState()
        turned.dialFocus = 1
        let plan = PlaceMove.plan(from: content.screen(for: .landing("deck"), state: RoomState()),
                                  to: content.screen(for: .landing("deck"), state: turned))
        #expect(plan[.doorSummary] == .move)
        #expect(plan[.dial] == .untouched)
        #expect(plan[.keystone] == .untouched)
    }

    @Test func theFootIsVerbOverObjectWithTheScaffoldsSteps() {
        let ready = Self.facts().wall.footSteps
        #expect(ready.map(\.id) == ["start", "log", "rest"])
        #expect(ready.first?.hold == true)
        #expect(ready.first?.verb == "Start")
        #expect(!ready.contains { $0.verb.contains("Push A") }, "never Start Push A as one word")
        let rest = Self.facts(day: .rest(next: "Pull A", nextDay: nil),
                              action: TrainingFoot(verb: "Log", object: "A walk"), restOption: "Pull A").wall.footSteps
        #expect(rest.map(\.id) == ["walk", "startNext", "log"])
        let done = Self.facts(day: .done(name: "Push A", next: nil), action: nil)
        let screen = DeckRoomContent(facts: done).screen(for: .landing("deck"), state: RoomState())
        #expect(screen[.actionWord] == nil)
    }

    @Test func privateRoutinesNeverReachAPage() {
        let content = DeckRoomContent(facts: Self.facts())
        for door in ["today", "week", "library", "bests", "plan"] {
            guard case let .list(rows)? = content.screen(for: .door("deck", door), state: RoomState())[.page]?
                .payload else { continue }
            #expect(!rows.contains { $0.title.localizedCaseInsensitiveContains("diary") })
        }
        // The plan's page lists only the wall's routines, which hold no private one.
        let plan = Self.facts().rows["plan"] ?? []
        #expect(plan.map(\.title) == ["Push A"])
    }

    @Test func theRegistryOpensDeck() {
        #expect(ShellRooms.ids.contains(DeckRoomContent.room))
        #expect(ShellRooms.host(for: "nowhere") == nil)
    }
}
