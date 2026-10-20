import XCTest

/// QA on #1055: while the area index is closed its rows are not in the accessibility tree and a tap there reaches the
/// page underneath; opened, the four rows and the hint are there.
@MainActor
final class AreaIndexClosedUITests: SimulatorOnlyTestCase {
    func testClosedIndexLeavesTheTreeAndOpenIndexJoinsIt() {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-demoTime", "18:10", "-resetDemo"]
        app.launch()
        let bar = app.buttons["Today, area"]
        XCTAssertTrue(bar.waitForExistence(timeout: 15))
        sleep(1)
        XCTAssertFalse(app.buttons["TRAINING, Push Day A is on"].exists, "A closed index row is in the tree")
        XCTAssertFalse(app.staticTexts["Tap one to open"].exists, "The closed index's hint is in the tree")

        bar.tap()
        XCTAssertTrue(app.buttons["TRAINING, Push Day A is on"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Tap one to open"].exists)
        app.buttons["TRAINING, Push Day A is on"].tap()
        XCTAssertTrue(app.buttons["Training, area"].waitForExistence(timeout: 3), "The pick did not change the area")
        sleep(1)
        XCTAssertFalse(app.buttons["KITCHEN, Nothing cooking tonight"].exists, "The index is back in the tree")
    }

    func testATapWhereTheClosedRowsWereReachesThePage() {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-demoTime", "18:10", "-resetDemo"]
        app.launch()
        let hero = app.buttons["Groceries for the week"]
        XCTAssertTrue(hero.waitForExistence(timeout: 15))
        sleep(1)
        hero.tap()
        XCTAssertTrue(app.buttons["BackButton"].waitForExistence(timeout: 3), "The tap did not reach the page")
    }
}
