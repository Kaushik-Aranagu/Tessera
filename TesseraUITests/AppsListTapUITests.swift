import XCTest

/// QA plan G13: a list with a hold or drag gesture still lets a plain tap reach its button. Home's apps list: a tap
/// on the middle row opens the app, a tap on a side row brings it to the middle.
@MainActor
final class AppsListTapUITests: SimulatorOnlyTestCase {
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        // The demo skips the feature flags, so the mosaic Home and its apps list are switched on by their own keys.
        app.launchArguments = ["-demo", "-demoTime", "18:10", "-resetDemo", "-review.homeMosaic", "On",
                               "-review.homeMosaicMoods", "On", "-review.homeAppsList", "On"]
        app.launch()
        XCTAssertTrue(app.buttons["Tess"].waitForExistence(timeout: 15))
        sleep(2)
        return app
    }

    private static let names = ["Training", "Kitchen", "Routines", "Tasks", "Notes", "Lists", "Money"]

    /// The row buttons of the apps list, found by app name; the middle one reads its fact after a comma.
    private func rows(_ app: XCUIApplication) -> [XCUIElement] {
        let first = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Training")).firstMatch
        XCTAssertTrue(first.waitForExistence(timeout: 10), "The apps list is on Home")
        let predicate = NSPredicate(format: Self.names.map { _ in "label BEGINSWITH %@" }.joined(separator: " OR "),
                                    argumentArray: Self.names)
        return app.buttons.matching(predicate).allElementsBoundByIndex.filter { $0.exists && $0.isHittable }
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
        XCTAssertTrue(rows(app).isEmpty || !app.buttons["Tess"].isHittable, "The app's page opened over Home")
    }
}
