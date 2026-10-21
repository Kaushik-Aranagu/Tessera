import XCTest

/// Page turn ships: picking a style in Settings › Review turns Review's own pages, and a side swipe on a turning page
/// moves a tab without leaving Settings.
@MainActor
final class PageTurnUITests: SimulatorOnlyTestCase {
    func testATurningPageSwipesBetweenTabsAndStaysInSettings() {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-demoTime", "18:10", "-openLink", "review"]
        app.launch()
        dismissNotificationAsk()
        // A cold first launch after an install can take a while to draw.
        _ = app.descendants(matching: .any)["Settings"].waitForExistence(timeout: 30)
        openSettings(app)
        let pageTurn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "page turn")).firstMatch
        XCTAssertTrue(pageTurn.waitForExistence(timeout: 10), "the Page turn row")
        for _ in 0 ..< 6 where !pageTurn.isHittable {
            app.swipeUp()
        }
        pickTurn(app)
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

    /// Design on #1184: with Turn picked, a vertical drag that starts on a Review row still scrolls Settings.
    func testAVerticalDragFromARowStillScrolls() {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-demoTime", "18:10", "-openLink", "review"]
        app.launch()
        dismissNotificationAsk()
        // A cold first launch after an install can take a while to draw.
        _ = app.descendants(matching: .any)["Settings"].waitForExistence(timeout: 30)
        openSettings(app)
        let pageTurn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "page turn")).firstMatch
        XCTAssertTrue(pageTurn.waitForExistence(timeout: 10))
        for _ in 0 ..< 6 where !pageTurn.isHittable {
            app.swipeUp()
        }
        pickTurn(app)
        let before = pageTurn.frame.minY
        let start = pageTurn.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        // Settings is already scrolled to its end here, so drag down: the page scrolls back toward the top.
        start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: 260)))
        sleep(1)
        XCTAssertGreaterThan(pageTurn.frame.minY, before + 100, "a vertical drag from a row didn't scroll Settings")
    }

    /// A fresh simulator asks once about notifications; the ask would cover Settings.
    private func dismissNotificationAsk() {
        let ask = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Don’t Allow"]
        if ask.waitForExistence(timeout: 4) {
            ask.tap()
        }
    }

    /// The row's value word cycles Today, then Slide, then Turn.
    private func pickTurn(_ app: XCUIApplication) {
        for (now, next) in [("Today", "Slide"), ("Slide", "Turn")] {
            let word = app.buttons.matching(NSPredicate(format: "label == %@", now)).firstMatch
            XCTAssertTrue(word.waitForExistence(timeout: 5), "the Page turn value \(now)")
            word.tap()
            XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label == %@", next)).firstMatch
                .waitForExistence(timeout: 5), "Page turn didn't move on to \(next)")
            sleep(2)
        }
    }
}
