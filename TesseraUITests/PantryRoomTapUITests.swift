import XCTest

/// QA plan G11 to G13 for the Pantry room: a plain tap on a row flips it low, a swipe commits "used up", and the
/// body gestures never starve the buttons under them. Runs without `-demo` (which skips the feature flags).
@MainActor
final class PantryRoomTapUITests: SimulatorOnlyTestCase {
    /// The room remembers its place between launches, so the test cannot count on where the dial starts: it adds the
    /// thing, then turns the dial until the row is on the page.
    private func launchOnPantry() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-demoTime", "18:10", "-openLink", "pantry"]
        app.launch()
        XCTAssertTrue(app.buttons["Add a thing"].waitForExistence(timeout: 20), "The Pantry room is open")
        XCTAssertTrue(app.descendants(matching: .any)["Place"].waitForExistence(timeout: 5))
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
        var turns = 0
        while !row.waitForExistence(timeout: 3), turns < 4 {
            app.descendants(matching: .any)["Place"].swipeUp(velocity: .fast)
            turns += 1
        }
        XCTAssertTrue(row.exists, "The new thing is a row")
        return row
    }

    func testTapOnARowFlipsItLow() {
        let app = launchOnPantry()
        let row = addEggs(app)
        row.tap()
        let low = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "\(thing), low"))
            .firstMatch
        XCTAssertTrue(low.waitForExistence(timeout: 5), "A plain tap flipped the row to low")
        // Use the row up so the simulator's pantry does not fill with test things.
        let start = low.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 140, dy: 0)))
    }

    func testSwipeRightUsesTheRowUp() {
        let app = launchOnPantry()
        let row = addEggs(app)
        let start = row.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5))
        let end = row.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5)).withOffset(CGVector(dx: 140, dy: 0))
        start.press(forDuration: 0.05, thenDragTo: end)
        let gone = NSPredicate(format: "exists == false")
        expectation(for: gone, evaluatedWith: row)
        waitForExpectations(timeout: 8)
    }
}
