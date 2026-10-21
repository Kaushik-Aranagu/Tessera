import XCTest

/// Kaushik, Oct 20: pulling down out of habit forced him into the index. A pull now only scrolls; the index opens by a
/// tap on the area name and a row picks a page.
@MainActor
final class AreaIndexOpenUITests: SimulatorOnlyTestCase {
    private func launch() -> XCUIApplication {
        addUIInterruptionMonitor(withDescription: "Notifications") { alert in
            let button = alert.buttons["Don’t Allow"]
            if button.exists {
                button.tap(); return true
            }
            return false
        }
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-demoTime", "18:10", "-resetDemo"]
        app.launch()
        XCTAssertTrue(app.buttons["Today, area"].waitForExistence(timeout: 15))
        sleep(1)
        return app
    }

    func testAPullDownDoesNotOpenTheIndex() {
        let app = launch()
        let window = app.windows.firstMatch
        let start = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
        let end = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
        start.press(forDuration: 0.1, thenDragTo: end)
        sleep(1)
        XCTAssertFalse(app.staticTexts["Let go to open"].exists, "A pull-down opened the index")
        XCTAssertFalse(app.buttons["TRAINING, Push Day A is on"].exists, "A pull-down opened the index")
        XCTAssertTrue(app.buttons["Today, area"].exists, "The page is still Today")
    }

    func testTappingTheNameOpensTheIndexAndARowPicksAPage() {
        let app = launch()
        app.buttons["Today, area"].tap()
        let training = app.buttons["TRAINING, Push Day A is on"]
        XCTAssertTrue(training.waitForExistence(timeout: 4), "The name did not open the index")
        training.tap()
        XCTAssertTrue(app.buttons["Training, area"].waitForExistence(timeout: 4), "The row did not open Training")
    }
}
