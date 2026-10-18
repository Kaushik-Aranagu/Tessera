import XCTest

/// Settings › Claude with a fake, in-memory key (`-fakeClaudeKey`): never the Keychain, never a real key.
@MainActor
final class ClaudeSettingsUITests: SimulatorOnlyTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testRemoveAsksThenGoesAndAddRefusesANonKey() {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-demoTime", "18:10", "-resetDemo", "-openLink", "review", "-fakeClaudeKey"]
        app.launch()

        let keyLine = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Claude key saved"))
            .firstMatch
        XCTAssertTrue(keyLine.waitForExistence(timeout: 15))
        assertNoKeyTail(in: app)
        app.swipeUp()
        app.swipeUp()
        sleep(1)

        // Step one asks, and Keep leaves the key where it was.
        app.buttons["REMOVE"].tap()
        XCTAssertTrue(app.buttons["REMOVE KEY"].waitForExistence(timeout: 3))
        app.buttons["KEEP"].tap()
        XCTAssertTrue(keyLine.waitForExistence(timeout: 3))
        assertNoKeyTail(in: app)
        sleep(1)

        // Step two removes it at once: a plain receipt, no UNDO, nothing held for 10 s.
        app.buttons["REMOVE"].tap()
        app.buttons["REMOVE KEY"].tap()
        XCTAssertTrue(app.staticTexts["Claude key removed. Everything stays on this phone."]
            .waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["UNDO"].exists)
        let add = app.buttons["Add a Claude key"]
        XCTAssertTrue(add.waitForExistence(timeout: 3), "The key is gone right away")
        add.tap()
        sleep(1)
        // Focus can lag the open: tap the line itself before typing.
        let field = app.secureTextFields.firstMatch
        if field.waitForExistence(timeout: 3) {
            field.tap()
            sleep(1)
        }
        app.typeText("not a key")
        app.typeText("\n")
        XCTAssertTrue(app.staticTexts["That doesn't look like a Claude key. Paste it again?"]
            .waitForExistence(timeout: 3))
        sleep(2)
    }

    /// Design 7af4026: one "Tess asks Claude" switch with Tess's inline answer; the month's amount opens Receipts.
    func testSwitchAnswersAndTheAmountOpensReceipts() {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-demoTime", "18:10", "-resetDemo", "-openLink", "review", "-fakeClaudeKey"]
        app.launch()

        let toggle = app.buttons["Tess asks Claude"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 15))
        app.swipeUp()
        sleep(1)
        toggle.tap()
        XCTAssertTrue(app.staticTexts["Tess stays on this phone."].waitForExistence(timeout: 3))
        sleep(2)
        toggle.tap()
        XCTAssertTrue(app.staticTexts["Tess asks Claude when she's unsure, and for Plan my day."]
            .waitForExistence(timeout: 3))
        sleep(2)
        app.buttons["$0.00"].tap()
        let back = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Settings")).firstMatch
        XCTAssertTrue(back.waitForExistence(timeout: 3))
        sleep(2)
        back.tap()
        XCTAssertTrue(toggle.waitForExistence(timeout: 3))
        sleep(1)
    }

    /// Product 9:53: presence is yes or no. No text or label on screen names any part of the key.
    private func assertNoKeyTail(in app: XCUIApplication) {
        for words in ["ends in", "ending in", "..."] {
            let tail = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS[c] %@", words))
            XCTAssertEqual(tail.count, 0, "A label says \"\(words)\" about the key")
        }
        // The fake key's own last characters never show (built here, nothing key-shaped in the file).
        let lastFour = String(repeating: "x", count: 4)
        let shown = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", lastFour))
        XCTAssertEqual(shown.count, 0, "Part of the key shows")
    }
}
