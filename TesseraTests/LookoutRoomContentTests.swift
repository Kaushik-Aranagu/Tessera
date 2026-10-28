import SwiftUI
@testable import Tessera
import Testing

/// Lookout on the standing shell (283 v5): the skypiece stays untouched when a door opens, the landing and the Hours
/// page fill the right places, and no line ever names a place.
@MainActor
struct LookoutRoomContentTests {
    private let facts = LookoutRoomContent.Facts(snapshot: WeatherSample.make(now: Date(), fahrenheit: true))
    private var content: LookoutRoomContent {
        LookoutRoomContent(facts: facts)
    }

    @Test func openingHoursLeavesTheSkypieceTitleCaptionAndFootUntouched() {
        let plan = PlaceMove.plan(from: content.screen(for: .landing("lookout"), state: RoomState()),
                                  to: content.screen(for: .door("lookout", "hours"), state: RoomState()))
        #expect(plan[.keystone] == .untouched)
        #expect(plan[.title] == .untouched)
        #expect(plan[.caption] == .untouched)
        #expect(plan[.actionWord] == .move, "Alert and Ask replace the landing's foot")
        #expect(plan[.navWord] == .move)
        #expect(plan[.doorTitle] == .enter)
        #expect(plan[.page] == .enter)
    }

    @Test func theLandingFillsItsPlaces() {
        let landing = content.screen(for: .landing("lookout"), state: RoomState())
        for place in [Place.title, .navWord, .switcher, .needs, .keystone, .caption, .widget, .glyph, .dial,
                      .doorSummary, .actionWord]
        {
            #expect(landing[place] != nil, "\(place) is filled")
        }
        #expect(landing[.doorTitle] == nil)
        #expect(landing[.page] == nil)
        #expect(landing[.keystone]?.payload == .scene("lookout.sky", label: "The sky now"))
    }

    @Test func theHoursDoorListsTheHours() {
        let door = content.screen(for: .door("lookout", "hours"), state: RoomState())
        #expect(door.layout == .door)
        for place in [Place.switcher, .needs, .widget, .glyph, .dial, .doorSummary] {
            #expect(door[place] == nil)
        }
        guard case let .ranked(data)? = door[.page]?.payload else {
            Issue.record("the Hours door has a ranked page")
            return
        }
        #expect(data.rows.count == facts.snapshot.hours.count)
        #expect(data.rows.allSatisfy { $0.unit == "\u{00B0}" && !$0.value.isEmpty })
    }

    @Test func turningTheDialMovesOnlyTheSummary() {
        var turned = RoomState()
        turned.dialFocus = 1
        let plan = PlaceMove.plan(from: content.screen(for: .landing("lookout"), state: RoomState()),
                                  to: content.screen(for: .landing("lookout"), state: turned))
        #expect(plan[.doorSummary] == .move)
        #expect(plan[.dial] == .untouched)
        #expect(plan[.keystone] == .untouched)
    }

    @Test func noScreenNamesAPlace() {
        let places = ["San Francisco", "Seattle", "London", "New York", "Cupertino", "city", " in "]
        var words: [String] = []
        for route in [ShellRoute.landing("lookout"), .door("lookout", "hours"), .door("lookout", "week"),
                      .door("lookout", "air")]
        {
            for slot in content.screen(for: route, state: RoomState()).slots.values {
                switch slot.payload {
                case let .lines(lines): words += lines
                case let .list(rows): words += rows.map(\.title)
                case let .ranked(data): words += data.rows.flatMap { [$0.title, $0.sub] }
                case let .pageTitle(title): words += [title.name, title.line]
                case let .summary(door): words += door.lines
                case let .doorTitle(name, line, _): words += [name, line]
                case let .action(steps, _): words += steps.map { "\($0.verb) \($0.object)" }
                default: break
                }
            }
        }
        for word in words {
            for place in places {
                #expect(!word.contains(place), "\(word)")
            }
        }
    }

    @Test func doorPagesReadDoorsThisWeekAndTheFootsAlertAndAsk() {
        let door = content.screen(for: .door("lookout", "week"), state: RoomState())
        guard case let .navWord(word)? = door[.navWord]?.payload,
              case let .pageTitle(title)? = door[.doorTitle]?.payload,
              case let .action(steps, _)? = door[.actionWord]?.payload
        else {
            Issue.record("the door page's words")
            return
        }
        #expect(word == "Doors")
        #expect(title.name == "This week")
        #expect(title.next == .door("lookout", "air") && title.previous == .door("lookout", "hours"))
        #expect(steps.map(\.verb) == ["Alert", "Ask"])
        #expect(steps.first?.object == "before rain")
    }

    @Test func anHourOpensTheHoursBodyWithFourRowsAndOneAdviceLine() {
        let screen = content.screen(for: .item("lookout", "hours", "hours.2"), state: RoomState())
        guard case let .item(data)? = screen[.page]?.payload, case let .hours(body) = data.body else {
            Issue.record("an hour draws the hours body")
            return
        }
        #expect(body.lines.count == 4)
        #expect(body.lines.filter(\.isOpen).count == 1)
        #expect(!body.advice.hasSuffix("."), "no full stop")
        #expect(data.facts.count == 3)
        guard case let .navWord(word)? = screen[.navWord]?.payload,
              case let .action(steps, _)? = screen[.actionWord]?.payload
        else { return }
        #expect(word == "Hours")
        #expect(steps.map(\.verb) == ["Alert", "Walk"])
        let week = content.screen(for: .item("lookout", "week", "week.0"), state: RoomState())
        guard case let .item(plain)? = week[.page]?.payload, case .siblings = plain.body else {
            Issue.record("a day draws its siblings until its own page is drawn")
            return
        }
    }

    @Test func noShownLineEndsInAFullStop() {
        for hour in 0 ..< facts.snapshot.hours.count {
            let detail = facts.detail(forRow: "hours.\(hour)")
            #expect(detail?.lines.contains { $0.hasSuffix(".") } == false)
        }
        for day in 0 ..< max(facts.snapshot.week.count - 1, 0) {
            #expect(facts.detail(forRow: "week.\(day)")?.lines.contains { $0.hasSuffix(".") } == false)
        }
    }

    @Test func theFootIsAlertThenHoursAndWalk() {
        #expect(facts.steps.map(\.verb) == ["Alert", "Hours", "Walk"])
    }

    @Test func theRegistryOpensLookout() {
        #expect(ShellRooms.ids.contains("lookout"))
    }
}
