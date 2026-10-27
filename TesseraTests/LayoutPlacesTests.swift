import CoreGraphics
@testable import Tessera
import Testing

/// Layout mode's frames come straight from the shell contract and the v4 map: pinned here so a drifting number fails.
struct LayoutPlacesTests {
    private func frame(_ name: String, _ room: LayoutRoom = .log, _ level: LayoutLevel = .landing) -> CGRect? {
        LayoutPlaces.place(named: name, in: room, level)?.frame
    }

    @Test func roomLandingFramesArePinned() {
        #expect(frame("Title") == CGRect(x: 24, y: 50, width: 260, height: 48))
        #expect(frame("Nav word") == CGRect(x: 300, y: 50, width: 94, height: 46))
        #expect(frame("Switcher") == CGRect(x: 24, y: 106, width: 200, height: 76))
        #expect(frame("Needs") == CGRect(x: 228, y: 118, width: 150, height: 58))
        #expect(frame("Keystone") == CGRect(x: 24, y: 196, width: 354, height: 182))
        #expect(frame("Caption") == CGRect(x: 24, y: 378, width: 354, height: 34))
        #expect(frame("Widget") == CGRect(x: 24, y: 412, width: 354, height: 200))
        #expect(frame("Glyph") == CGRect(x: 298, y: 444, width: 80, height: 80))
        #expect(frame("Dial") == CGRect(x: 218, y: 640, width: 160, height: 120))
        #expect(frame("Door summary") == CGRect(x: 24, y: 640, width: 192, height: 120))
        #expect(frame("Action word") == CGRect(x: 24, y: 786, width: 220, height: 62))
        #expect(frame("Tess") == CGRect(x: 306, y: 776, width: 96, height: 96))
        #expect(frame("Masthead") == CGRect(x: 0, y: 44, width: 402, height: 138))
    }

    @Test func breathsAre14And28And16() {
        let breaths = LayoutPlaces.places(.log, .landing).filter(\.isGap)
        #expect(breaths.map(\.frame.minY) == [182, 612, 760])
        #expect(breaths.map(\.frame.height) == [14, 28, 16])
        #expect(breaths.map(\.key) == ["Breath@182", "Breath@612", "Breath@760"])
    }

    @Test func doorPageMergesSwitcherNeedsAndTheLowerPlaces() {
        let door = LayoutPlaces.places(.deck, .door)
        #expect(door.first { $0.name == "Door title" }?.frame == CGRect(x: 24, y: 106, width: 354, height: 70))
        #expect(door.first { $0.name == "Page" }?.frame == CGRect(x: 24, y: 412, width: 354, height: 364))
        #expect(door.filter(\.isGap).map(\.frame.minY) == [182])
        for gone in ["Switcher", "Needs", "Widget", "Glyph", "Dial", "Door summary"] {
            #expect(!door.contains { $0.name == gone })
        }
        // The keystone stays exactly where it was.
        #expect(door.first { $0.name == "Keystone" }?.frame == frame("Keystone"))
    }

    @Test func bridgeHasTheSettingsWordAndTheDepartureBoard() {
        let bridge = LayoutPlaces.places(.bridge, .landing)
        #expect(bridge.first { $0.name == "Settings word" }?.frame == CGRect(x: 24, y: 74, width: 110, height: 44))
        #expect(bridge.first { $0.name == "Departure board" }?.frame == CGRect(x: 140, y: 74, width: 238, height: 104))
        #expect(!bridge.contains { $0.name == "Title" })
        // Bridge has one level.
        #expect(LayoutPlaces.places(.bridge, .door) == bridge)
    }

    @Test func sideMarginsAre24() {
        for room in LayoutRoom.allCases {
            for level in [LayoutLevel.landing, .door] {
                for place in LayoutPlaces.places(room, level) where !place.isPlate {
                    let box = place.frame
                    guard !["Nav word", "Tess"].contains(place.name) else { continue }
                    #expect(box.minX >= 24, "\(place.name) keeps the left margin")
                    #expect(box.maxX <= 378, "\(place.name) keeps the right margin")
                }
            }
        }
    }

    @Test func everySeamIsFourPoints() {
        func pane(_ name: String, _ level: LayoutLevel = .landing) -> CGRect {
            LayoutPlaces.place(named: name, in: .galley, level)!.paneFrame
        }
        // Across: the frames stay as the contract has them and the insets differ (Switcher right 0, Needs left 0,
        // Door summary right 1, Dial left 1: the dial is on the right), so these seams are 4 pt too.
        #expect(pane("Needs").minX - pane("Switcher").maxX == 4)
        #expect(pane("Dial").minX - pane("Door summary").maxX == 4)
        #expect(pane("Switcher").minX == 26 && pane("Switcher").maxX == 224)
        #expect(pane("Needs").minX == 228 && pane("Needs").maxX == 376)
        #expect(pane("Door summary").minX == 26 && pane("Door summary").maxX == 215)
        #expect(pane("Dial").minX == 219 && pane("Dial").maxX == 376)
        // Down: Keystone, Caption, Widget.
        #expect(pane("Caption").minY - pane("Keystone").maxY == 4)
        #expect(pane("Widget").minY - pane("Caption").maxY == 4)
    }

    @Test func paneIsInsetTwoPointsAndRadiusFollowsTheShorterSide() throws {
        let keystone = try #require(LayoutPlaces.place(named: "Keystone", in: .log, .landing))
        #expect(keystone.paneFrame == CGRect(x: 26, y: 198, width: 350, height: 178))
        #expect(keystone.radius == 22)
        #expect(LayoutPlaces.place(named: "Caption", in: .log, .landing)?.radius == 10.2)
        #expect(LayoutPlaces.place(named: "Glyph", in: .log, .landing)?.radius == 22)
    }

    @Test func roomsLoopInTheBoardsOrder() {
        #expect(LayoutRoom.allCases.map(\.name) == ["Bridge", "Log", "Lookout", "Deck", "Galley", "Watch", "Purse"])
        #expect(LayoutRoom.purse.moved(1) == .bridge)
        #expect(LayoutRoom.bridge.moved(-1) == .purse)
        #expect(LayoutRoom.galley.position(.landing) == "the landing, 5 of 7")
        #expect(LayoutRoom.log.position(.door) == "a door page, 2 of 7")
    }

    @Test func goingDeepFlowsSwitcherAndNeedsIntoTheDoorTitle() {
        let plan = LayoutChange.plan(from: LayoutPlaces.places(.log, .landing), to: LayoutPlaces.places(.log, .door))
        let doorTitle = CGRect(x: 24, y: 106, width: 354, height: 70).insetBy(dx: 2, dy: 2)
        let page = CGRect(x: 24, y: 412, width: 354, height: 364).insetBy(dx: 2, dy: 2)
        #expect(plan.tracks.filter { $0.to == doorTitle }.count == 2)
        // Widget, Glyph, the breaths at 612 and 760, Dial and Door summary flow into the Page.
        #expect(plan.tracks.filter { $0.to == page }.count == 6)
        #expect(plan.steady.contains("Keystone"))
        #expect(plan.steady.contains("Tess"))
        #expect(plan.settle.contains("Door title") && plan.settle.contains("Page"))
        #expect(plan.tracks.allSatisfy { $0.delay >= 0 && $0.delay <= 160 + 36 })
        #expect(plan.total <= 720 + 160 + 36)
    }

    @Test func comingBackSplitsThePageAndTheDoorTitle() {
        let plan = LayoutChange.plan(from: LayoutPlaces.places(.log, .door), to: LayoutPlaces.places(.log, .landing))
        let widget = CGRect(x: 24, y: 412, width: 354, height: 200).insetBy(dx: 2, dy: 2)
        let page = CGRect(x: 24, y: 412, width: 354, height: 364).insetBy(dx: 2, dy: 2)
        #expect(plan.tracks.contains { $0.from == page && $0.to == widget })
        #expect(plan.tracks.contains { $0.to == CGRect(x: 26, y: 108, width: 198, height: 72) })
    }

    @Test func bridgeToARoomTurnsTheSettingsWordIntoTheTitle() {
        let plan = LayoutChange.plan(
            from: LayoutPlaces.places(.bridge, .landing),
            to: LayoutPlaces.places(.log, .landing)
        )
        let settings = CGRect(x: 24, y: 74, width: 110, height: 44).insetBy(dx: 2, dy: 2)
        let title = CGRect(x: 24, y: 50, width: 260, height: 48).insetBy(dx: 2, dy: 2)
        #expect(plan.tracks.contains { $0.from == settings && $0.to == title })
        // The Departure board splits into the Switcher, the Needs and the Nav word.
        let board = CGRect(x: 140, y: 74, width: 238, height: 104).insetBy(dx: 2, dy: 2)
        #expect(plan.tracks.filter { $0.from == board }.count == 3)
    }

    @Test func roomToRoomMovesNoPane() {
        let plan = LayoutChange.plan(
            from: LayoutPlaces.places(.log, .landing),
            to: LayoutPlaces.places(.deck, .landing)
        )
        #expect(!plan.isLiquid)
        #expect(plan.settle.isEmpty)
    }

    @Test func theSpringStartsAtZeroOvershootsAndRests() {
        #expect(LayoutChange.spring(0) == 0)
        #expect(LayoutChange.spring(1) == 1)
        #expect((1 ..< 100).map { LayoutChange.spring(Double($0) / 100) }.max()! > 1)
    }
}
