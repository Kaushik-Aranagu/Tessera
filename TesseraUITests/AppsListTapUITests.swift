import XCTest

/// QA plan G13: a list with a hold or drag gesture still lets a plain tap reach its button. Home's apps list: a tap
/// on the middle row opens the app, a tap on a side row brings it to the middle.
@MainActor
final class AppsListTapUITests: SimulatorOnlyTestCase {
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-demoTime", "18:10", "-resetDemo"]
        app.launch()
        XCTAssertTrue(app.buttons["Tess"].waitForExistence(timeout: 15))
        sleep(2)
        return app
    }

    /// The row buttons of the apps list; the middle one reads its fact after a comma.
    private func rows(_ app: XCUIApplication) -> [XCUIElement] {
        let list = app.otherElements["Apps"]
        XCTAssertTrue(list.waitForExistence(timeout: 10), "The apps list is on Home")
        return list.buttons.allElementsBoundByIndex.filter(\.isHittable)
    }

    func testTapOnASideRowBringsItToTheMiddle() {
        let app = launch()
        let before = rows(app)
        let side = before.first { !$0.label.contains(",") }
        XCTAssertNotNil(side, "A side row is on screen")
        guard let side else { return }
        let name = side.label
        side.tap()
        sleep(1)
        let middle = rows(app).first { $0.label.hasPrefix(name) && $0.label.contains(",") }
        XCTAssertNotNil(middle, "\(name) is now the middle row")
    }

    func testTapOnTheMiddleRowOpensTheApp() {
        let app = launch()
        let middle = rows(app).first { $0.label.contains(",") }
        XCTAssertNotNil(middle, "The middle row is on screen")
        middle?.tap()
        sleep(1)
        // The door page covers Home: the list is no longer reachable.
        XCTAssertFalse(app.otherElements["Apps"].exists && app.otherElements["Apps"].isHittable,
                       "The app's page opened over Home")
    }
}
