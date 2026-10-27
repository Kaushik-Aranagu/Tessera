import XCTest

/// QA L2: a workout opened and never logged is wrapped up after 6 hours, and the line beside the soul offers UNDO.
@MainActor
final class WrapUpUndoUITests: SimulatorOnlyTestCase {
    func testEmptyWrapUpLineHasUndo() {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-demoTime", "10:00", "-resetDemo"]
        app.launch()
        let start = app.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] %@", "Start")).firstMatch
        XCTAssertTrue(start.waitForExistence(timeout: 15))
        start.tap()
        sleep(3)
        app.terminate()

        // Eight hours on, nothing logged: Core wraps it up on launch and says so beside the soul.
        app.launchArguments = ["-demo", "-demoTime", "18:10"]
        app.launch()
        let line = app.staticTexts.matching(NSPredicate(format: "label ENDSWITH %@", "no sets, not saved")).firstMatch
        XCTAssertTrue(line.waitForExistence(timeout: 15))
        let undo = app.buttons.matching(NSPredicate(format: "label ==[c] %@", "Undo")).firstMatch
        XCTAssertTrue(undo.waitForExistence(timeout: 2))
        sleep(2)
        undo.tap()
        sleep(3)
    }
}
