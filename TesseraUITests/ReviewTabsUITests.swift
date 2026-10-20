import XCTest

/// Design on #1137: the fullest Review tab fits on one screen at the default size, so no tab ever needs a scroll of its
/// own. Since #1167 only switches that ship are drawn; the fullest drawn tab is Workout (Looks and day ties).
@MainActor
final class ReviewTabsUITests: SimulatorOnlyTestCase {
    func testFullestDrawnTabFitsOnOneScreen() {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-demoTime", "18:10", "-openLink", "review"]
        app.launch()
        openSettings(app)

        let tabRow = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", ", tab "))
            .firstMatch
        XCTAssertTrue(tabRow.waitForExistence(timeout: 10), "Review's tab row")
        for _ in 0 ..< 4 where !tabRow.isHittable {
            app.swipeUp()
        }
        // Looks and day, then Workout: one step right.
        tabRow.swipeLeft()
        sleep(1)
        let names = ["Rest timer", "Swap exercise", "Forgot Finish nudge", "Tess names training days"]
        let rows = names.map { app.descendants(matching: .any)[$0] }
        for (name, row) in zip(names, rows) {
            XCTAssertTrue(row.waitForExistence(timeout: 5), "\(name) on the Workout tab")
        }
        // A switch whose feature hasn't shipped is not drawn.
        XCTAssertFalse(app.descendants(matching: .any)["Plan my day, Claude wording"].exists,
                       "a waiting switch is drawn")
        let top = rows.map(\.frame.minY).min() ?? 0
        let bottom = rows.map(\.frame.maxY).max() ?? 0
        XCTAssertLessThan(bottom - top, app.windows.firstMatch.frame.height,
                          "the Workout tab is taller than one screen")
    }
}
