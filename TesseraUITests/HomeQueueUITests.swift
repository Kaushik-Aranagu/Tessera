import XCTest

/// Real touches on Today's queue (QA Q1): a page swipe over a row pages Home and leaves the task alone; a
/// deliberate press-then-drag finishes it. Runs from the TesseraUITests scheme, not scripts/test.sh.
@MainActor
final class HomeQueueUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// Baseline: a swipe over the hero pages Home.
    func testHeroSwipePages() {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-demoTime", "18:10", "-resetDemo"]
        app.launch()
        let hero = app.staticTexts["Thursday evening"]
        XCTAssertTrue(hero.waitForExistence(timeout: 15))
        let from = app.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.3))
        from.press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.3)),
                   withVelocity: 1500, thenHoldForDuration: 0)
        sleep(1)
        let review = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "the week so far")).firstMatch
        XCTAssertTrue(review.exists && review.frame.minX >= 0, "A swipe over the hero pages Home")
    }

    func testPageSwipeLeavesTaskAndDeliberateDragFinishes() {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-demoTime", "18:10", "-resetDemo"]
        app.launch()

        let row = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@ AND label CONTAINS %@", "Stretch & mobility", ":"))
            .firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 15))

        // A quick page swipe across the row: Home pages to REVIEW, then back, and the task is still there.
        // A real page flick (XCUI's swipeRight is too short to page): from the row's left side across the screen.
        let rowY = row.frame.midY / app.frame.height
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: rowY))
            .press(forDuration: 0.05,
                   thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: rowY)),
                   withVelocity: 1500, thenHoldForDuration: 0)
        sleep(1)
        snap(app, "paged")
        let review = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "the week so far")).firstMatch
        XCTAssertTrue(review.exists && review.frame.minX >= 0, "A swipe over the queue pages Home")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.3))
            .press(forDuration: 0.05,
                   thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.3)),
                   withVelocity: 1500, thenHoldForDuration: 0)
        sleep(2)
        snap(app, "after-page-swipe")
        XCTAssertTrue(row.waitForExistence(timeout: 5), "A page swipe must not finish the task")
        XCTAssertFalse(app.buttons["UNDO"].exists, "A page swipe must not commit anything")

        // A deliberate press, then a slow drag right past the threshold: the task is done and Tess offers Undo.
        let grab = row.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.5))
        grab.press(forDuration: 0.4, thenDragTo: grab.withOffset(CGVector(dx: 200, dy: 0)),
                   withVelocity: .slow, thenHoldForDuration: 0.1)
        sleep(1)
        snap(app, "after-drag")
        XCTAssertTrue(app.buttons["UNDO"].waitForExistence(timeout: 5))
        sleep(2)
        XCTAssertFalse(row.exists, "The finished task leaves the queue")
    }

    /// Debug aid: a screenshot and the element tree into $UITEST_SNAPS (if set).
    private func snap(_ app: XCUIApplication, _ name: String) {
        guard let dir = ProcessInfo.processInfo.environment["UITEST_SNAPS"] else { return }
        try? app.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: "\(dir)/\(name).png"))
        try? app.debugDescription.write(toFile: "\(dir)/\(name).txt", atomically: true, encoding: .utf8)
    }
}
