import XCTest

/// Design on #1137: the fullest Review tab (Connected, six switches with 44 pt value words) fits on one screen at the
/// default size, so no tab ever needs a scroll of its own.
@MainActor
final class ReviewTabsUITests: SimulatorOnlyTestCase {
    func testConnectedTabFitsOnOneScreen() {
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
        // Looks and day, Workout, Kitchen, Connected: three steps right.
        for _ in 0 ..< 3 {
            tabRow.swipeLeft()
            sleep(1)
        }
        let names = ["Plan my day, Claude wording", "Shutdown", "Energy check-in", "Calendar", "Health",
                     "Link reader v2"]
        let rows = names.map { app.descendants(matching: .any)[$0] }
        for (name, row) in zip(names, rows) {
            XCTAssertTrue(row.waitForExistence(timeout: 5), "\(name) on the Connected tab")
        }
        let top = rows.map(\.frame.minY).min() ?? 0
        let bottom = rows.map(\.frame.maxY).max() ?? 0
        XCTAssertLessThan(bottom - top, app.windows.firstMatch.frame.height,
                          "the Connected tab is taller than one screen")
    }
}
