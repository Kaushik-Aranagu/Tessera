import XCTest

/// Sheet 284 on the Deck (`-shellRoom deck`): plain taps reach a door, a row and back; the Door title goes across to
/// the next door; the Nav word reads Doors on a door page and the door's name on an item page. Simulator only.
@MainActor
final class DeckLevelsUITests: SimulatorOnlyTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launch(_ extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-shellRoom", "deck", "-shellProbe", "-demo", "-demoTime", "18:10"] + extra
        app.launch()
        return app
    }

    private func settled(_ app: XCUIApplication, timeout: TimeInterval = 5) -> String {
        let probe = app.descendants(matching: .any)["shell.state"]
        XCTAssertTrue(probe.waitForExistence(timeout: 20), "The state probe is on screen")
        let rest = NSPredicate(format: "label ENDSWITH 'changing no'")
        let expectation = XCTNSPredicateExpectation(predicate: rest, object: probe)
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: timeout), .completed, "The change ends")
        return probe.label
    }

    private func openDoor(_ app: XCUIApplication, _ name: String) {
        let door = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", name)).firstMatch
        XCTAssertTrue(door.waitForExistence(timeout: 20), "The dial shows \(name)")
        sleep(1)
        door.tap()
        XCTAssertTrue(app.descendants(matching: .any)["shell.doorTitle"].waitForExistence(timeout: 4), "\(name) opened")
    }

    private func firstRow(_ app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'shell.row.'")).firstMatch
    }

    func testTapADoorTapARowAndComeBack() {
        let app = launch()
        openDoor(app, "Library")
        XCTAssertTrue(settled(app).hasPrefix("route deck/1/library"))
        XCTAssertTrue(app.buttons["Back to Doors"].waitForExistence(timeout: 3), "The Nav word reads Doors")
        let row = firstRow(app)
        XCTAssertTrue(row.waitForExistence(timeout: 4), "The door page has rows")
        row.tap()
        XCTAssertTrue(app.descendants(matching: .any)["shell.itemTitle"].waitForExistence(timeout: 4), "A lift page")
        XCTAssertTrue(settled(app).hasPrefix("route deck/2/library/"))
        let nav = app.buttons["Back to Library"]
        XCTAssertTrue(nav.waitForExistence(timeout: 3), "The Nav word at level 2 is the door's name")
        nav.tap()
        XCTAssertTrue(app.descendants(matching: .any)["shell.doorTitle"].waitForExistence(timeout: 4))
        XCTAssertTrue(settled(app).hasPrefix("route deck/1/library"), "Back restored the door")
        XCTAssertTrue(app.descendants(matching: .any)["shell.itemTitle"].exists == false)
        app.buttons["Back to Doors"].tap()
        XCTAssertTrue(app.buttons["Back to Bridge"].waitForExistence(timeout: 4), "Back on the landing")
    }

    func testAcrossOnTheDoorTitleGoesToTheNextDoor() {
        let app = launch()
        openDoor(app, "Today")
        _ = settled(app)
        let title = app.descendants(matching: .any)["shell.doorTitle"]
        title.swipeLeft()
        sleep(1)
        let state = settled(app)
        XCTAssertTrue(state.hasPrefix("route deck/1/week"), state)
        XCTAssertTrue(app.buttons["Back to Doors"].exists, "Across replaces the door; back still goes up one level")
    }

    func testTheReduceMotionPathOpensARow() {
        let app = launch(["-shellReduceMotion"])
        openDoor(app, "Library")
        let row = firstRow(app)
        XCTAssertTrue(row.waitForExistence(timeout: 4))
        row.tap()
        XCTAssertTrue(app.descendants(matching: .any)["shell.itemTitle"].waitForExistence(timeout: 3))
    }
}
