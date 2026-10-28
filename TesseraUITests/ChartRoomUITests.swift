import XCTest

/// The Chart room's controls take plain taps (QA G13): Say plays a sentence as a ghost, Allow on the wine line sets
/// the widening patch, and Undo on the receipt takes it back. Opened in the standing shell from Bridge (`-shellWalk chart`: the dial reel only exposes rows near its centre).
/// Simulator only.
@MainActor
final class ChartRoomUITests: SimulatorOnlyTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launchInChartRoom() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-demoTime", "18:10", "-resetChart", "-shellProbe", "-shellWalk", "chart"]
        app.launch()
        let ask = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Don’t Allow"]
        if ask.waitForExistence(timeout: 4) {
            ask.tap()
        }
        XCTAssertTrue(app.buttons["Say, what to build"].waitForExistence(timeout: 20), "The Chart room is open")
        return app
    }

    private func say(_ app: XCUIApplication) {
        app.buttons["Say, what to build"].tap()
        sleep(3)
    }

    func testSayAllowAndUndoTakePlainTaps() {
        let app = launchInChartRoom()
        // The blank room shows the empty places by name.
        XCTAssertTrue(app.descendants(matching: .any)["Keystone, empty"].exists)
        say(app)
        say(app)
        say(app)
        XCTAssertFalse(app.descendants(matching: .any)["Keystone, empty"].exists, "The keystone set")
        app.buttons["Say, what to build"].tap()
        let allow = app.buttons["chart.allow"]
        XCTAssertTrue(allow.waitForExistence(timeout: 5), "The reach line shows Allow")
        sleep(3)
        XCTAssertTrue(allow.exists, "It still waits after the drying line")
        allow.tap()
        XCTAssertFalse(allow.waitForExistence(timeout: 2), "Allow set the patch")
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Watered")).firstMatch
            .waitForExistence(timeout: 5), "The action word became Watered")
        let undo = app.buttons.matching(NSPredicate(format: "label ==[c] %@", "Undo")).firstMatch
        XCTAssertTrue(undo.waitForExistence(timeout: 5), "The receipt has Undo")
        undo.tap()
        XCTAssertTrue(app.buttons["Say, what to build"].waitForExistence(timeout: 5), "Undo took the word back")
    }
}
