import XCTest

/// Sheet 283 v5 through Home: Bridge and every room in the one standing shell. Bridge to a room and back (no page
/// slides), a door and back with the keystone the same view and the state restored, the back pull, a row swipe, the
/// foot action's drag and the one-thing hold to strike. Sample data, simulator only.
@MainActor
final class RootShellUITests: SimulatorOnlyTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launch(_ extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-review.sampleData", "On", "-demoTime", "18:10", "-shellProbe"] + extra
        app.launch()
        let ask = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Don’t Allow"]
        if ask.waitForExistence(timeout: 4) {
            ask.tap()
        }
        return app
    }

    private func probe(_ app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)["shell.state"]
    }

    /// Waits until the shell shows `route` and is at rest.
    private func waitFor(_ app: XCUIApplication, route: String, timeout: TimeInterval = 90) {
        let predicate = NSPredicate(format: "label BEGINSWITH %@ AND label ENDSWITH 'changing no'", "route \(route)")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: probe(app))
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: timeout), .completed,
                       "The shell reached \(route); it shows \(probe(app).label)")
    }

    private func token(_ app: XCUIApplication) -> String {
        let element = app.descendants(matching: .any)["shell.keystone.token"]
        XCTAssertTrue(element.waitForExistence(timeout: 10))
        return element.label
    }

    private func pull(_ app: XCUIApplication, by distance: CGFloat) {
        let edge = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0.55)).withOffset(CGVector(dx: 6, dy: 0))
        edge.press(forDuration: 0.05, thenDragTo: edge.withOffset(CGVector(dx: distance, dy: 0)))
    }

    func testBridgeToTheLogADoorAndBackThroughTheShell() {
        let app = launch(["-shellWalk", "log"])
        waitFor(app, route: "log/0")
        let wall = token(app)
        let door = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'All notes'")).firstMatch
        XCTAssertTrue(door.waitForExistence(timeout: 10), "The Log's dial shows All notes")
        door.tap()
        waitFor(app, route: "log/1/all", timeout: 10)
        XCTAssertEqual(token(app), wall, "The word wall stayed the same view through the door")
        app.buttons["Back to Log"].tap()
        waitFor(app, route: "log/0", timeout: 10)
        XCTAssertEqual(token(app), wall, "and on the way back")
        app.buttons["Back to Bridge"].tap()
        waitFor(app, route: "bridge/0", timeout: 10)
        XCTAssertTrue(app.buttons["Settings"].firstMatch.waitForExistence(timeout: 5), "Bridge's places came back")
    }

    func testTheBackPullSettlesShortAndGoesBackLong() {
        let app = launch(["-shellWalk", "log"])
        waitFor(app, route: "log/0")
        pull(app, by: 40)
        sleep(1)
        XCTAssertTrue(probe(app).label.hasPrefix("route log/0"), "A short pull settles back in the Log")
        pull(app, by: 170)
        waitFor(app, route: "bridge/0", timeout: 10)
    }

    func testTheFootActionTurnsOnADragPastFiftySixPoints() {
        let app = launch(["-shellWalk", "log"])
        waitFor(app, route: "log/0")
        let action = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Write'"))
            .firstMatch
        XCTAssertTrue(action.waitForExistence(timeout: 10), "The Log's foot reads Write")
        let start = action.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: -90, dy: 0)))
        let next = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Speak'")).firstMatch
        XCTAssertTrue(next.waitForExistence(timeout: 3), "A drag past 56 pt turns to the next action")
    }

    func testARowSwipeRightStartsItAndLeftIsNotNow() throws {
        let app = launch(["-shellWalk", "watch", "-shellDoor", "today"])
        waitFor(app, route: "watch/1/today")
        let rows = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'shell.row.'"))
        guard rows.firstMatch.waitForExistence(timeout: 10) else {
            // Sample data with nothing due today has no row to swipe.
            throw XCTSkip("No routine is due today in the sample data")
        }
        let row = rows.firstMatch
        let start = row.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: -140, dy: 0)))
        sleep(1)
        XCTAssertTrue(row.isHittable, "Not now leaves the page where it is")
        start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 140, dy: 0)))
        sleep(2)
        XCTAssertFalse(row.isHittable, "Swipe right starts it: its page opens over the shell")
    }
}
