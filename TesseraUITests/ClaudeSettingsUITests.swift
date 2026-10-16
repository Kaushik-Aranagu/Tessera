import XCTest

/// Settings › Claude with a fake, in-memory key (`-fakeClaudeKey`): never the Keychain, never a real key.
@MainActor
final class ClaudeSettingsUITests: SimulatorOnlyTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testRemoveUndoThenAddRefusesANonKey() {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-demoTime", "18:10", "-resetDemo", "-openLink", "review", "-fakeClaudeKey"]
        app.launch()

        let keyLine = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Claude key, ends in"))
            .firstMatch
        XCTAssertTrue(keyLine.waitForExistence(timeout: 15))
        app.swipeUp()
        app.swipeUp()
        sleep(1)

        app.buttons["REMOVE"].tap()
        XCTAssertTrue(app.staticTexts["Claude key removed. Everything stays on this phone."]
            .waitForExistence(timeout: 3))
        app.buttons["UNDO"].tap()
        XCTAssertTrue(app.staticTexts["Claude key is back."].waitForExistence(timeout: 3))
        XCTAssertTrue(keyLine.exists)
        sleep(2)

        app.buttons["REMOVE"].tap()
        let add = app.buttons["Add a Claude key"]
        XCTAssertTrue(add.waitForExistence(timeout: 15), "After 10 s the key is gone")
        add.tap()
        sleep(1)
        app.typeText("not a key")
        app.typeText("\n")
        XCTAssertTrue(app.staticTexts["That doesn't look like a Claude key. Paste it again?"]
            .waitForExistence(timeout: 3))
        sleep(2)
    }
}
