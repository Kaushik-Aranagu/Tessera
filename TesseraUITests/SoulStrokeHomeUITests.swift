import XCTest

/// QA on #662: the stroke reads beside Home's own gestures, never instead of them. A sideways swipe that starts in
/// Tess's band (y ≈ 760 on the 874 pt phone) still moves Home, and a link near the band still opens.
@MainActor
final class SoulStrokeHomeUITests: SimulatorOnlyTestCase {
    private func launch(_ page: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-demoTime", "18:10", "-resetDemo", "-homePage", page]
        app.launch()
        return app
    }

    func testASwipeFromTheBandStillMovesHome() {
        let app = launch("today")
        let next = app.staticTexts["Next"]
        XCTAssertTrue(next.waitForExistence(timeout: 15))
        XCTAssertTrue(next.isHittable)
        let scale = app.frame.height / 874
        let origin = app.coordinate(withNormalizedOffset: .zero)
        origin.withOffset(CGVector(dx: 300, dy: 760 * scale))
            .press(forDuration: 0.05, thenDragTo: origin.withOffset(CGVector(dx: 40, dy: 760 * scale)))
        let gone = expectation(for: NSPredicate(format: "isHittable == false"), evaluatedWith: next)
        wait(for: [gone], timeout: 5)
    }

    func testTheFootLinkStillOpens() {
        let app = launch("review")
        let notes = app.buttons["Notes"]
        XCTAssertTrue(notes.waitForExistence(timeout: 15))
        notes.tap()
        XCTAssertTrue(app.staticTexts["Notes"].waitForExistence(timeout: 5), "The foot link didn't open")
    }
}
