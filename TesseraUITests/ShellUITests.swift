import XCTest

/// Sheet 283 v5 on the Log through the standing shell (`-shell`): the keystone is the same view on the way into a
/// door and on the way back (its token, made once per view identity, never changes), back restores the switcher and
/// the dial exactly, and the Reduce Motion path gets there too. Simulator only.
@MainActor
final class ShellUITests: SimulatorOnlyTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launch(_ extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-shell", "-shellProbe", "-demoNotes", "-demoTime", "18:10"] + extra
        app.launch()
        return app
    }

    private func token(_ app: XCUIApplication) -> String {
        let probe = app.descendants(matching: .any)["shell.keystone.token"]
        XCTAssertTrue(probe.waitForExistence(timeout: 30), "The keystone probe is on screen")
        return probe.label
    }

    private func state(_ app: XCUIApplication) -> String {
        let probe = app.descendants(matching: .any)["shell.state"]
        XCTAssertTrue(probe.waitForExistence(timeout: 10), "The state probe is on screen")
        return probe.label
    }

    /// Waits until the shell is at rest (no change in flight) and returns the state line.
    private func settledState(_ app: XCUIApplication, timeout: TimeInterval = 5) -> String {
        let probe = app.descendants(matching: .any)["shell.state"]
        let rest = NSPredicate(format: "label ENDSWITH 'changing no'")
        let expectation = XCTNSPredicateExpectation(predicate: rest, object: probe)
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: timeout), .completed, "The change ends")
        return probe.label
    }

    private func openAllNotes(_ app: XCUIApplication) {
        let door = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'All notes'")).firstMatch
        XCTAssertTrue(door.waitForExistence(timeout: 15), "The dial shows All notes")
        door.tap()
    }

    private func back(_ app: XCUIApplication) {
        let nav = app.buttons["Back to Log"]
        XCTAssertTrue(nav.waitForExistence(timeout: 5), "The nav word reads Log on the door page")
        nav.tap()
    }

    func testTheKeystoneStaysOnEnterAndOnBack() {
        let app = launch()
        XCTAssertTrue(app.staticTexts["Log"].waitForExistence(timeout: 30))
        sleep(1)
        let first = token(app)

        openAllNotes(app)
        let doorTitle = app.descendants(matching: .any)["shell.doorTitle"]
        XCTAssertTrue(doorTitle.waitForExistence(timeout: 3), "The Door title formed from the switcher and needs")
        XCTAssertTrue(state(app).hasPrefix("route log/1/all"))
        XCTAssertEqual(token(app), first, "The keystone was not recreated on the way in")

        _ = settledState(app)
        back(app)
        XCTAssertTrue(app.buttons["Back to Bridge"].waitForExistence(timeout: 3), "Back on the landing")
        _ = settledState(app)
        XCTAssertEqual(token(app), first, "The keystone was not recreated on the way back")
        XCTAssertFalse(doorTitle.exists, "The Door title split back into the switcher and needs")
    }

    func testBackRestoresTheSwitcherAndTheDial() {
        let app = launch()
        XCTAssertTrue(app.staticTexts["Log"].waitForExistence(timeout: 30))
        sleep(1)
        // The switcher: a tap goes to the next word across.
        let switcher = app.descendants(matching: .any)["shell.switcher"]
        XCTAssertTrue(switcher.waitForExistence(timeout: 5))
        switcher.tap()
        XCTAssertTrue(switcher.label == "Due" || app.descendants(matching: .any)["Due"].waitForExistence(timeout: 3))
        // The dial: tap the neighbour to turn to it.
        let neighbour = app.buttons
            .matching(NSPredicate(format: "label BEGINSWITH 'Loose' OR label BEGINSWITH 'Private'"))
            .firstMatch
        XCTAssertTrue(neighbour.waitForExistence(timeout: 5), "The dial has a second door")
        let name = neighbour.label.components(separatedBy: ",").first ?? neighbour.label
        sleep(1)
        neighbour.tap()
        sleep(1)
        let before = settledState(app)
        XCTAssertTrue(before.contains("switcher 1"), before)
        XCTAssertTrue(before.contains("focus 1"), before)

        // Open the focused door, then come back.
        let focused = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", name)).firstMatch
        focused.tap()
        XCTAssertTrue(app.descendants(matching: .any)["shell.doorTitle"].waitForExistence(timeout: 3))
        _ = settledState(app)
        back(app)
        let after = settledState(app)
        XCTAssertEqual(after, before, "Every place's state came back")
        XCTAssertEqual(app.descendants(matching: .any)["shell.switcher"].label, "Due", "The switcher still reads Due")
    }

    func testTheReduceMotionPathEntersAndComesBack() {
        let app = launch(["-shellReduceMotion"])
        XCTAssertTrue(app.staticTexts["Log"].waitForExistence(timeout: 30))
        sleep(1)
        let first = token(app)
        openAllNotes(app)
        // A 150 ms cross-fade: the door is there and at rest well inside half a second's polling.
        XCTAssertTrue(app.descendants(matching: .any)["shell.doorTitle"].waitForExistence(timeout: 2))
        _ = settledState(app, timeout: 2)
        back(app)
        XCTAssertTrue(app.buttons["Back to Bridge"].waitForExistence(timeout: 2))
        _ = settledState(app, timeout: 2)
        XCTAssertEqual(token(app), first, "The keystone stayed under Reduce Motion too")
    }

    /// Sheet 283 v6: the edge pull never drags the page. A short pull settles back on the door page; a pull past
    /// 80 pt changes every place in place (the keystone stays the same view).
    func testAShortPullSettlesBackAndALongPullGoesBack() {
        let app = launch()
        XCTAssertTrue(app.staticTexts["Log"].waitForExistence(timeout: 30))
        sleep(1)
        let first = token(app)
        openAllNotes(app)
        let doorTitle = app.descendants(matching: .any)["shell.doorTitle"]
        XCTAssertTrue(doorTitle.waitForExistence(timeout: 3))
        _ = settledState(app)

        let edge = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0.55)).withOffset(CGVector(dx: 6, dy: 0))
        edge.press(forDuration: 0.05, thenDragTo: edge.withOffset(CGVector(dx: 40, dy: 0)))
        sleep(1)
        XCTAssertTrue(state(app).hasPrefix("route log/1/all"), "A short pull settles back on the door page")
        XCTAssertTrue(doorTitle.exists)

        edge.press(forDuration: 0.05, thenDragTo: edge.withOffset(CGVector(dx: 160, dy: 0)))
        XCTAssertTrue(app.buttons["Back to Bridge"].waitForExistence(timeout: 3), "A long pull goes back")
        let after = settledState(app)
        XCTAssertTrue(after.hasPrefix("route log/0"), after)
        XCTAssertEqual(token(app), first, "The keystone stayed through the pull")
    }
}
