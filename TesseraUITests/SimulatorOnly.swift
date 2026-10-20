import XCTest

/// UI tests drive the real app with demo flags; on his phone they would tap through his real data. They run on the
/// simulator only (docs/research/debug-paths.md).
class SimulatorOnlyTestCase: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        #if !targetEnvironment(simulator)
            throw XCTSkip("UI tests run on the simulator only, never on a phone with real data.")
        #endif
    }

    /// From Review (`-openLink review`), opens Settings by its word at the foot of the week.
    func openSettings(_ app: XCUIApplication) {
        let settings = app.buttons.matching(NSPredicate(format: "label ==[c] %@", "Settings")).firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 15), "Settings word on Review")
        for _ in 0 ..< 4 where !settings.isHittable {
            app.swipeUp()
        }
        settings.tap()
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 5), "Settings page")
    }
}
