import XCTest

/// Page turn ships: picking a style in Settings › Review turns Review's own pages, and a side swipe on a turning page
/// moves a tab without leaving Settings.
@MainActor
final class PageTurnUITests: SimulatorOnlyTestCase {
    func testATurningPageSwipesBetweenTabsAndStaysInSettings() {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-demoTime", "18:10", "-openLink", "review"]
        app.launch()
        openSettings(app)
        let pageTurn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "page turn")).firstMatch
        XCTAssertTrue(pageTurn.waitForExistence(timeout: 10), "the Page turn row")
        for _ in 0 ..< 6 where !pageTurn.isHittable {
            app.swipeUp()
        }
        // Today, then Slide, then Turn.
        pageTurn.tap()
        sleep(2)
        pageTurn.tap()
        sleep(2)
        let tabs = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", ", tab "))
            .firstMatch
        XCTAssertTrue(tabs.waitForExistence(timeout: 5))
        let page = pageTurn.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .withOffset(CGVector(dx: 120, dy: 0))
        page.press(forDuration: 0.05, thenDragTo: page.withOffset(CGVector(dx: -200, dy: 0)))
        sleep(2)
        XCTAssertTrue(tabs.label.hasPrefix("Workout"), "a left swipe on the page moves to Workout: \(tabs.label)")
        let workoutRow = app.descendants(matching: .any)["Rest timer"]
        let back = workoutRow.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        back.press(forDuration: 0.05, thenDragTo: back.withOffset(CGVector(dx: 200, dy: 0)))
        sleep(2)
        XCTAssertTrue(app.staticTexts["Settings"].exists, "a right swipe on a turning page left Settings")
        XCTAssertTrue(tabs.label.hasPrefix("Looks and day"), "a right swipe moves back a tab: \(tabs.label)")
    }
}
