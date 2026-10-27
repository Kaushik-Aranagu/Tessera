import SwiftUI
@testable import Tessera
import Testing

/// The Purse on the standing shell (283 v5): the chart keeps its id when a door opens, the door page fills the Door
/// title and Page, and the page carries no figure of money and no walled kind.
@MainActor
struct PurseRoomContentTests {
    @Test func theChartStaysWhenADoorOpens() {
        let content = PurseRoomContent(facts: Self.facts)
        let landing = content.screen(for: .landing("purse"), state: RoomState())
        let door = content.screen(for: .door("purse", "this month"), state: RoomState())
        let plan = PlaceMove.plan(from: landing, to: door)
        #expect(plan[.keystone] == .untouched)
        #expect(plan[.title] == .untouched)
        #expect(plan[.caption] == .untouched)
        #expect(plan[.actionWord] == .untouched)
        #expect(plan[.navWord] == .move)
        #expect(plan[.doorTitle] == .enter)
        #expect(plan[.page] == .enter)
    }

    @Test func theLandingFillsItsPlacesAndLeavesTheDoorsOnes() {
        let screen = PurseRoomContent(facts: Self.facts).screen(for: .landing("purse"), state: RoomState())
        for place in [Place.title, .navWord, .switcher, .needs, .keystone, .caption, .widget, .glyph, .dial,
                      .doorSummary, .actionWord]
        {
            #expect(screen[place] != nil, "\(place) is filled")
        }
        for place in [Place.doorTitle, .page, .tess] {
            #expect(screen[place] == nil, "\(place) is empty")
        }
    }

    @Test func theDoorPageFillsTitleAndPage() {
        let screen = PurseRoomContent(facts: Self.facts).screen(for: .door("purse", "this month"), state: RoomState())
        #expect(screen.layout == .door)
        #expect(screen[.doorTitle] != nil)
        #expect(screen[.page] != nil)
        for place in [Place.switcher, .needs, .widget, .glyph, .dial, .doorSummary, .tess] {
            #expect(screen[place] == nil, "\(place) is empty on a door page")
        }
    }

    @Test func thePageHoldsNoFigureAndNoWalledKind() {
        let screen = PurseRoomContent(facts: Self.facts).screen(for: .door("purse", "this month"), state: RoomState())
        guard case let .list(rows)? = screen[.page]?.payload else {
            Issue.record("the This month door has a page")
            return
        }
        #expect(rows.contains { $0.isPrivate && $0.title == "Private spend" })
        for row in rows {
            #expect(!MoneyWall.looksLikeAmount(row.title))
        }
        #expect(!rows.contains { $0.title.contains("Gifts") })
    }

    @Test func turningTheDialMovesTheSummaryNotTheChart() {
        let content = PurseRoomContent(facts: Self.facts)
        var turned = RoomState()
        turned.dialFocus = 1
        let plan = PlaceMove.plan(from: content.screen(for: .landing("purse"), state: RoomState()),
                                  to: content.screen(for: .landing("purse"), state: turned))
        #expect(plan[.doorSummary] == .move)
        #expect(plan[.keystone] == .untouched)
    }

    @Test func theCaptionAndNeedsHoldNoFigure() {
        let screen = PurseRoomContent(facts: Self.facts).screen(for: .landing("purse"), state: RoomState())
        guard case let .lines(caption)? = screen[.caption]?.payload,
              case let .lines(needs)? = screen[.needs]?.payload
        else {
            Issue.record("caption and needs")
            return
        }
        for line in caption + needs {
            #expect(!line.contains("$"))
            #expect(!line.contains { $0.isNumber && line.contains("$") })
        }
    }

    @Test func theRoomIsRegistered() {
        #expect(ShellRooms.ids.contains(PurseRoomContent.room))
    }

    static var facts: PurseRoomContent.Facts {
        var facts = PurseRoomContent.Facts()
        facts.switcher = ["October", "This year", "Since May"]
        facts.firstMonth = "May"
        facts.needs = [["3 spends so far", "Last on lunch"], ["The year view comes next", "Twelve months"],
                       ["Since May comes next", "Every month side by side"]]
        facts.caption = "Nothing yet"
        facts.widget = [WidgetItem(id: "today", header: "Today", big: "12", bigIsNumber: true, strikeable: false)]
        facts.doors = [
            DialDoor(id: "this month", name: "This month", color: .green, label: "Indices", lines: ["2 indices"]),
            DialDoor(id: "kinds", name: "Kinds", color: .green, label: "Indices", lines: ["1 index"]),
        ]
        facts.rows = ["this month": [
            ShellRow(id: "1", title: "Lunch", detail: "Oct 24"),
            ShellRow(id: "2", title: "Private spend", detail: "Oct 23", isPrivate: true),
        ]]
        return facts
    }
}
