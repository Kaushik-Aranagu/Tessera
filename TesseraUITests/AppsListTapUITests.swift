import XCTest

/// QA plan G13: a list with a hold or drag gesture still lets a plain tap reach its button. Home's apps list: a tap
/// on the middle row opens the app, a tap on a side row brings it to the middle.
@MainActor
final class AppsListTapUITests: SimulatorOnlyTestCase {
    private static let names = ["Training", "Kitchen", "Routines", "Tasks", "Notes", "Lists", "Money"]

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        // Not the demo: it skips the feature flags, and the mosaic Home with its apps list ships On.
        app.launchArguments = ["-demoTime", "18:10"]
        app.launch()
        XCTAssertTrue(app.buttons["Tess"].waitForExistence(timeout: 15))
        sleep(2)
        return app
    }

    private func rowQuery(_ app: XCUIApplication) -> XCUIElementQuery {
        let predicate = NSPredicate(format: Self.names.map { _ in "label BEGINSWITH %@" }.joined(separator: " OR "),
                                    argumentArray: Self.names)
        return app.buttons.matching(predicate)
    }

    /// The row buttons of the apps list on screen, top to bottom: three, the middle one second.
    private func rows(_ app: XCUIApplication) -> [XCUIElement] {
        XCTAssertTrue(rowQuery(app).firstMatch.waitForExistence(timeout: 10), "The apps list is on Home")
        return rowQuery(app).allElementsBoundByIndex.filter { $0.exists && $0.isHittable }
            .sorted { $0.frame.minY < $1.frame.minY }
    }

    func testTapOnASideRowBringsItToTheMiddle() {
        let app = launch()
        let before = rows(app)
        XCTAssertGreaterThanOrEqual(before.count, 3, "Three rows are on screen")
        guard before.count >= 3 else { return }
        let middleY = before[1].frame.minY
        let side = before[2]
        let name = side.label
        XCTAssertGreaterThan(abs(side.frame.minY - middleY), 20, "The side row starts away from the middle")
        side.tap()
        sleep(1)
        let moved = rowQuery(app).matching(NSPredicate(format: "label BEGINSWITH %@", name)).firstMatch
        XCTAssertTrue(moved.waitForExistence(timeout: 3))
        XCTAssertLessThan(abs(moved.frame.minY - middleY), 6, "\(name) is now the middle row")
    }

    func testTapOnTheMiddleRowOpensTheApp() {
        let app = launch()
        let before = rows(app)
        XCTAssertGreaterThanOrEqual(before.count, 3, "Three rows are on screen")
        guard before.count >= 3 else { return }
        before[1].tap()
        sleep(2)
        // The app's page covers Home: Tess's corner and the list are no longer both reachable.
        XCTAssertTrue(rowQuery(app).allElementsBoundByIndex.filter(\.isHittable).isEmpty
            || !app.buttons["Tess"].isHittable, "The app's page opened over Home")
    }
}
