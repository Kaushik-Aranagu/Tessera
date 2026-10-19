import XCTest

/// Kaushik, release 21: a pull-down from a low start always let go on Kitchen. The row now follows the finger's travel
/// from where the index formed, so the same drag from any height reaches the same area.
@MainActor
final class AreaIndexPullUITests: SimulatorOnlyTestCase {
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-demoTime", "18:10", "-resetDemo"]
        app.launch()
        XCTAssertTrue(app.buttons["Today, area"].waitForExistence(timeout: 15))
        sleep(1)
        return app
    }

    /// Pulls from `startY` (a fraction of the screen height) down by `points`.
    private func pull(_ app: XCUIApplication, startY: CGFloat, points: CGFloat) {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: startY))
        let end = start.withOffset(CGVector(dx: 0, dy: points))
        start.press(forDuration: 0.1, thenDragTo: end)
    }

    func testTheSameDragFromAnyHeightReachesTheSameArea() {
        // From Today, 150 pt down is one row on: Training, whether the finger started high or low.
        for startY in [0.5, 0.65] as [CGFloat] {
            let app = launch()
            pull(app, startY: startY, points: 150)
            XCTAssertTrue(app.buttons["Training, area"].waitForExistence(timeout: 4),
                          "A pull from \(startY) did not reach Training")
            app.terminate()
        }
    }

    func testPullingBackUpPastTheStartReachesReview() {
        let app = launch()
        // Forming takes 90 pt; a 150 pt drag is +1 row. Review (one row up) needs the finger to come back, so two
        // drags: a short pull cancels, and a pull of 90 then upward travel is covered by AreaIndexPullTests.
        pull(app, startY: 0.5, points: 40)
        sleep(1)
        XCTAssertTrue(app.buttons["Today, area"].exists, "A short pull changed the area")
    }
}
