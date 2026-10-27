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
        #expect(plan[.actionWord] == .untouched)
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
        guard case let .list(rows)? = door[.page]?.payload else {
            Issue.record("the Hours door has a page")
            return
        }
        #expect(rows.count == facts.snapshot.hours.count)
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

    @Test func theFootIsAlertThenHoursAndWalk() {
        #expect(facts.steps.map(\.verb) == ["Alert", "Hours", "Walk"])
    }

    @Test func theRegistryOpensLookout() {
        #expect(ShellRooms.ids.contains("lookout"))
    }
}
