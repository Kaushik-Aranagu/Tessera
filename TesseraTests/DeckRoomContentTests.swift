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
        let board = TrainingBoard(headline: "Push A today", detail: "Bench opens at 80 kg",
                                  week: [BoardDay(id: 0, letter: "M", done: true, isToday: false),
                                         BoardDay(id: 1, letter: "T", done: false, isToday: true)],
                                  bests: [BoardBest(id: exercise, lift: "Bench", number: "82.5 kg")])
        let deck = TrainingDeckFacts(board: board, routineWords: ["Push A", "Private workout"],
                                     needs: [["Push A today", "Bench"], ["2 done", "1 to go"], ["8 this month", ""]],
                                     widget: [WidgetItem(id: "today", header: "Tonight", big: "PUSH A"),
                                              WidgetItem(id: "week", header: "This week", big: "2")])
        var pages = DeckPages()
        let lift = TrainingWallTarget.exercise(exercise).id
        pages.doors["today"] = DeckDoorPage(line: "Push, 4 lifts", rows: [
            LevelRow(id: "\(lift)#t0", title: "Bench Press", value: "80", unit: "kg", sub: "3 sets of 5"),
            LevelRow(id: "page#t1", title: "Row", state: .done),
        ])
        pages.doors["week"] = DeckDoorPage(line: "1 trained", rows: [LevelRow(id: "week#1", title: "Tuesday")])
        pages.doors["library"] = DeckDoorPage(line: "12 exercises", rows: [])
        pages.items[lift] = DeckItem(
            title: "Bench Press", line: "Next: set 2, 80 kg \u{00D7} 5",
            facts: [ItemFact(number: "80", unit: "kg", label: "Today"),
                    ItemFact(number: "100", unit: "kg", label: "Best"),
                    ItemFact(number: "112", unit: "kg", label: "Est. 1 rep")],
            sets: SetsBody(lines: [SetLine(id: "s0", label: "Set 1", weight: "80", unit: "kg", reps: "5", state: .done),
                                   SetLine(
                                       id: "s1",
                                       label: "Set 2",
                                       weight: "80",
                                       unit: "kg",
                                       reps: "5",
                                       state: .next
                                   )],
                           lastTime: "80 kg, 5, 5 and 4"),
            start: "set 1, 80 kg"
        )
        return DeckRoomContent.Facts(wall: wall, deck: deck, rows: DeckRoomContent.Facts.rows(wall: wall, deck: deck),
                                     pages: pages)
    }

    static var benchRoute: ShellRoute {
        .item("deck", "today", "\(TrainingWallTarget.exercise(exercise).id)#t0")
    }

    @Test func openingADoorLeavesTheBoardUntouched() {
        let content = DeckRoomContent(facts: Self.facts())
        let landing = content.screen(for: .landing("deck"), state: RoomState())
        let door = content.screen(for: .door("deck", "today"), state: RoomState())
        let plan = PlaceMove.plan(from: landing, to: door)
        #expect(plan[.keystone] == .untouched)
        #expect(plan[.title] == .untouched)
        #expect(plan[.caption] == .move, "the door's own hint eases over the landing's")
        #expect(plan[.actionWord] == .move, "Add and Ask replace Start, Log and Rest")
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
        guard case let .ranked(data)? = door[.page]?.payload else {
            Issue.record("Today has a ranked page")
            return
        }
        #expect(data.rows.map(\.title) == ["Bench Press", "Row"])
        #expect(door[.page]?.kind == .rows)
        guard case let .navWord(word)? = door[.navWord]?.payload else {
            Issue.record("the nav word")
            return
        }
        #expect(word == "Doors")
        guard case let .pageTitle(title)? = door[.doorTitle]?.payload else {
            Issue.record("the door title")
            return
        }
        #expect(title.name == "Today" && title.line == "Push, 4 lifts" && !title.isItem)
    }

    @Test func acrossOnTheDoorTitleGoesToTheNextDoorAndWraps() {
        let content = DeckRoomContent(facts: Self.facts())
        func title(_ door: String) -> PageTitle? {
            guard case let .pageTitle(title)? = content
                .screen(for: .door("deck", door), state: RoomState())[.doorTitle]?
                .payload else { return nil }
            return title
        }
        #expect(title("today")?.next == .door("deck", "week"))
        #expect(title("today")?.previous == .door("deck", "library"))
        #expect(title("library")?.next == .door("deck", "today"))
        #expect(title("today")?.nextFocus == 1)
        #expect(title("today")?.previousFocus == 2)
    }

    @Test func theBenchItemPageHasFactsAndSets() {
        let content = DeckRoomContent(facts: Self.facts())
        let item = content.screen(for: Self.benchRoute, state: RoomState())
        #expect(item.layout == .door)
        guard case let .item(data)? = item[.page]?.payload, case let .sets(sets) = data.body else {
            Issue.record("Bench draws the sets body")
            return
        }
        #expect(data.facts.map(\.label) == ["Today", "Best", "Est. 1 rep"])
        #expect(sets.lines.map(\.state) == [.done, .next])
        guard case let .pageTitle(title)? = item[.doorTitle]?.payload,
              case let .navWord(word)? = item[.navWord]?.payload
        else {
            Issue.record("the item title")
            return
        }
        #expect(title.name == "Bench Press" && title.isItem)
        #expect(word == "Today", "the Nav word at level 2 is the door's name")
        #expect(title.next == .item("deck", "today", "page#t1"))
        #expect(title.previous == .item("deck", "today", "page#t1"))
    }

    @Test func aRowWithoutItsOwnPageDrawsItsSiblings() {
        let item = DeckRoomContent(facts: Self.facts()).screen(for: .item("deck", "today", "page#t1"),
                                                               state: RoomState())
        guard case let .item(data)? = item[.page]?.payload, case let .siblings(siblings) = data.body else {
            Issue.record("a plain row draws siblings")
            return
        }
        #expect(siblings.current == "page#t1")
        #expect(siblings.rows.count == 2)
    }

    @Test func openingAnItemChangesOnlyWords() {
        let content = DeckRoomContent(facts: Self.facts())
        let door = content.screen(for: .door("deck", "today"), state: RoomState())
        let item = content.screen(for: Self.benchRoute, state: RoomState())
        let plan = PlaceMove.plan(from: door, to: item)
        #expect(plan[.keystone] == .untouched)
        #expect(plan[.title] == .untouched)
        #expect(plan[.caption] == .untouched, "the door's caption stays at level 2")
        #expect(plan[.actionWord] == .move, "the item's own verbs")
        #expect(plan[.navWord] == .move)
        #expect(plan[.doorTitle] == .move)
        #expect(plan[.page] == .move, "the same kind with new words, never a collapse")
        #expect(ShellPlan(from: door, to: item).merging == false)
        #expect(ShellPlan(from: door, to: item).splitting == false)
    }

    @Test func backFromAnItemRestoresTheDoorAndItsState() {
        let navigator = ShellNavigator(root: .landing("deck"))
        var state = RoomState()
        state.dialFocus = 2
        navigator.state = state
        navigator.push(.door("deck", "library"))
        navigator.push(Self.benchRoute)
        #expect(navigator.route.level == 2)
        navigator.replace(.item("deck", "library", "x"))
        #expect(navigator.stack.count == 3, "across replaces the top and does not grow the stack")
        navigator.pop()
        #expect(navigator.route == .door("deck", "library"))
        navigator.pop()
        #expect(navigator.route == .landing("deck"))
        #expect(navigator.state.dialFocus == 2)
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
            guard case let .ranked(data)? = content.screen(for: .door("deck", door), state: RoomState())[.page]?
                .payload else { continue }
            #expect(!data.rows.contains { $0.title.localizedCaseInsensitiveContains("diary") })
        }
        // The plan's page lists only the wall's routines, which hold no private one.
        let plan = Self.facts().rows["plan"] ?? []
        #expect(plan.map(\.title) == ["Push A"])
    }

    @Test func theRegistryOpensDeckAndSettings() {
        #expect(ShellRooms.ids.contains(DeckRoomContent.room))
        #expect(ShellRooms.ids.contains(SettingsRoomContent.room))
        #expect(ShellRooms.host(for: "nowhere") == nil)
    }

    @Test func eachDoorHasItsOwnCaptionAtLevelsOneAndTwo() {
        let content = DeckRoomContent(facts: Self.facts())
        func caption(_ route: ShellRoute) -> String? {
            guard case let .lines(lines)? = content.screen(for: route, state: RoomState())[.caption]?.payload
            else { return nil }
            return lines.first
        }
        #expect(caption(.door("deck", "today")) == "The board keeps what you chalk on it")
        #expect(caption(.door("deck", "bests")) == "Bests are written in gold")
        #expect(caption(.door("deck", "plan")) == "Drag on the board to write")
        #expect(caption(Self.benchRoute) == caption(.door("deck", "today")))
        let door = content.screen(for: .door("deck", "today"), state: RoomState())
        let week = content.screen(for: .door("deck", "week"), state: RoomState())
        #expect(PlaceMove.plan(from: door, to: week)[.caption] == .move, "the caption eases over as the door turns")
        #expect(PlaceMove.plan(from: door, to: content.screen(for: Self.benchRoute, state: RoomState()))[.caption]
            == .untouched)
    }

    @Test func theFootChangesWithTheLevel() {
        let content = DeckRoomContent(facts: Self.facts())
        func steps(_ route: ShellRoute) -> [ShellStep] {
            guard case let .action(steps, _)? = content.screen(for: route, state: RoomState())[.actionWord]?.payload
            else { return [] }
            return steps
        }
        #expect(steps(.door("deck", "today")).map(\.verb) == ["Add", "Ask"])
        #expect(steps(.door("deck", "today")).first?.object == "to Today")
        #expect(steps(.door("deck", "week")).first?.object == "to This week")
        let lift = steps(Self.benchRoute)
        #expect(lift.map(\.verb) == ["Start", "Swap"])
        #expect(lift.first?.hold == true)
        let row = steps(.item("deck", "today", "page#t1"))
        #expect(row.map(\.verb) == ["Open", "Ask"])
        #expect(row.first?.object == "Row")
        let a = content.screen(for: .door("deck", "today"), state: RoomState())
        let b = content.screen(for: .door("deck", "week"), state: RoomState())
        #expect(PlaceMove.plan(from: a, to: b)[.actionWord] == .untouched, "the verb stays put; the object eases over")
    }
}
