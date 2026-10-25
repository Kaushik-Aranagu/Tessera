import XCTest

/// Landing contract §5-§6 on the Notes landing: the word wall's words open their note, the dial turns and opens its
/// door, the action word asks for a note, and the left edge goes back. Simulator only.
@MainActor
final class NotesLandingUITests: SimulatorOnlyTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-notes", "-demoNotes", "-review.landingPages", "On", "-demoTime", "18:10"]
        app.launch()
        return app
    }

    func testTheLandingShowsTitleWallDialAndAction() {
        let app = launch()
        XCTAssertTrue(app.staticTexts["Log"].waitForExistence(timeout: 30), "The room title is on the landing")
        XCTAssertTrue(app.buttons["Opens it"].firstMatch.exists || app.staticTexts["New note"].exists)
        XCTAssertTrue(app.staticTexts["New note"].exists, "The action word sits at the foot")
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'All notes'")).firstMatch.exists,
                      "The doors dial shows All notes")
    }

    func testTappingAWallWordOpensItsNote() {
        let app = launch()
        XCTAssertTrue(app.staticTexts["Log"].waitForExistence(timeout: 30))
        let word = app.buttons.matching(NSPredicate(format: "label == 'Sleep' OR label == 'Ideas'")).firstMatch
        XCTAssertTrue(word.waitForExistence(timeout: 10), "A note word is on the wall")
        word.tap()
        XCTAssertFalse(app.staticTexts["New note"].waitForExistence(timeout: 3), "The landing was left for the note")
    }

    func testTheActionWordAsksForANote() {
        let app = launch()
        let action = app.staticTexts["New note"]
        XCTAssertTrue(action.waitForExistence(timeout: 30))
        action.tap()
        XCTAssertTrue(app.alerts["New note"].waitForExistence(timeout: 5), "A tap on the action word asks for a note")
    }

    func testTappingTheFocusedDoorOpensIt() {
        let app = launch()
        let door = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'All notes'")).firstMatch
        XCTAssertTrue(door.waitForExistence(timeout: 30))
        sleep(1)
        door.tap()
        XCTAssertFalse(app.staticTexts["New note"].waitForExistence(timeout: 3), "The door page replaced the landing")
    }
}
