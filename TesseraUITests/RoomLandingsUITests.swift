import XCTest

/// The Lists, Money and Kitchen landings on the shared kit (landing contract §14): a wall word opens, the dial turns,
/// the action word acts. Sample data on and "Landing pages" On, so every landing has words on its wall.
@MainActor
final class RoomLandingsUITests: SimulatorOnlyTestCase {
    private func launch(_ extra: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-review.sampleData", "On", "-review.landingPages", "On", "-demoTime", "18:10"] + extra
        app.launch()
        let ask = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Don’t Allow"]
        if ask.waitForExistence(timeout: 6) {
            ask.tap()
        }
        return app
    }

    private func button(_ app: XCUIApplication, _ label: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] %@", label)).firstMatch
    }

    /// The dial's focus is the selected button; a swipe up on the dial moves the focus to the next door.
    private func turnDial(_ app: XCUIApplication) {
        let focus = app.buttons.matching(NSPredicate(format: "selected == true")).firstMatch
        XCTAssertTrue(focus.waitForExistence(timeout: 10), "dial focus")
        let before = focus.label
        let start = focus.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: -60)))
        sleep(1)
        let after = app.buttons.matching(NSPredicate(format: "selected == true")).firstMatch.label
        XCTAssertNotEqual(before, after, "the dial turned")
    }

    private func wallWord(_ app: XCUIApplication, in label: String) -> XCUIElement {
        let wall = app.otherElements[label]
        XCTAssertTrue(wall.waitForExistence(timeout: 20), "\(label) wall")
        return wall.buttons.firstMatch
    }

    func testMoneyLanding() {
        let app = launch(["-money"])
        XCTAssertTrue(app.staticTexts["Purse"].waitForExistence(timeout: 30), "Purse title")
        let money = app.staticTexts.allElementsBoundByIndex.map(\.label)
        XCTAssertFalse(
            money.contains { $0.contains("$") || $0.contains("€") || $0.contains("£") },
            "no amounts: \(money)"
        )
        turnDial(app)
        let add = button(app, "Log")
        XCTAssertTrue(add.exists, "Log")
        add.tap()
        XCTAssertTrue(app.alerts["Log a spend"].waitForExistence(timeout: 5), "Log asks")
        app.alerts["Log a spend"].buttons["Cancel"].tap()
    }

    func testKitchenLanding() {
        let app = launch(["-kitchen"])
        XCTAssertTrue(app.staticTexts["Galley"].waitForExistence(timeout: 30), "Galley title")
        turnDial(app)
        let cook = button(app, "Cook")
        XCTAssertTrue(cook.exists, "Cook")
        let word = wallWord(app, in: "The pass")
        XCTAssertTrue(word.exists, "a word on the wall")
        word.tap()
        sleep(2)
        XCTAssertFalse(cook.exists && cook.isHittable, "the word opened its page over the landing")
    }

    /// Bridge (QA on sheet 283): no "N of M" counter anywhere on Home, and the dial wears ship names.
    func testBridgeHasNoCountersAndShipNames() {
        let app = launch([])
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] %@", "Settings")).firstMatch
            .waitForExistence(timeout: 30), "Bridge is up")
        sleep(3)
        let labels = app.staticTexts.allElementsBoundByIndex.map(\.label)
            + app.buttons.allElementsBoundByIndex.map(\.label)
        let counter = try? NSRegularExpression(pattern: "\\b\\d+ of \\d+\\b")
        let hits = labels.filter { label in
            counter?.firstMatch(in: label, range: NSRange(label.startIndex..., in: label)) != nil
        }
        XCTAssertTrue(hits.isEmpty, "counters on Bridge: \(hits)")
        XCTAssertFalse(labels.contains { $0.hasPrefix("Training") || $0.hasPrefix("Kitchen") }, "old names: \(labels)")
    }
}
