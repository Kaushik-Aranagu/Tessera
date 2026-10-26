import XCTest

/// QA plan G11 to G13 for the Pantry room: a plain tap on a row flips it low, a swipe commits "used up", and the
/// body gestures never starve the buttons under them. Runs without `-demo` (which skips the feature flags).
@MainActor
final class PantryRoomTapUITests: SimulatorOnlyTestCase {
    private func launchOnFridge() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-demoTime", "18:10", "-openLink", "pantry"]
        app.launch()
        XCTAssertTrue(app.buttons["Add a thing"].waitForExistence(timeout: 20), "The Pantry room is open")
        // One flick turns the dial one place: To get to Fridge.
        let dial = app.descendants(matching: .any)["Place"]
        XCTAssertTrue(dial.waitForExistence(timeout: 5))
        dial.swipeUp(velocity: .fast)
        sleep(1)
        return app
    }

    /// A name no earlier run has used, so a thing kept from another run never answers for this one.
    private let thing = "Eggs\(Int(Date().timeIntervalSince1970) % 100_000)"

    private func addEggs(_ app: XCUIApplication) -> XCUIElement {
        app.buttons["Add a thing"].tap()
        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText("\(thing)\n")
        let row = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", thing)).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 8), "The new thing is a row")
        return row
    }

    func testTapOnARowFlipsItLow() {
        let app = launchOnFridge()
        let row = addEggs(app)
        row.tap()
        let low = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "\(thing), low")).firstMatch
        XCTAssertTrue(low.waitForExistence(timeout: 5), "A plain tap flipped the row to low")
    }

    func testSwipeRightUsesTheRowUp() {
        let app = launchOnFridge()
        let row = addEggs(app)
        let start = row.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5))
        let end = row.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5)).withOffset(CGVector(dx: 140, dy: 0))
        start.press(forDuration: 0.05, thenDragTo: end)
        let gone = NSPredicate(format: "exists == false")
        expectation(for: gone, evaluatedWith: row)
        waitForExpectations(timeout: 8)
    }
}
