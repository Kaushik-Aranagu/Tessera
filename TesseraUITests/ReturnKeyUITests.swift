import XCTest

/// Kaushik, install 1: Return must finish what's typed. Ask Tess sends; the Notes line writes the note.
@MainActor
final class ReturnKeyUITests: SimulatorOnlyTestCase {
    func testReturnSendsACaptureToTess() {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-demoTime", "18:10", "-resetDemo"]
        app.launch()
        let soul = app.buttons["Tess"]
        XCTAssertTrue(soul.waitForExistence(timeout: 15))
        sleep(2)
        soul.tap()
        let write = app.descendants(matching: .any).matching(NSPredicate(format: "label ==[c] %@", "Write")).firstMatch
        XCTAssertTrue(write.waitForExistence(timeout: 8))
        write.tap()
        sleep(1)
        app.typeText("Call the bank at 4")
        app.typeText("\n")
        // The words dry as a ghost, then land as a row: either way they're a static text, not the field.
        let landed = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Call the bank")).firstMatch
        XCTAssertTrue(landed.waitForExistence(timeout: 8), "Return didn't send the capture")
        sleep(3)
    }

    func testReturnWritesTheNote() {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-demoTime", "18:10", "-resetDemo", "-openLink", "notes"]
        app.launch()
        let line = app.textFields["New note"]
        XCTAssertTrue(line.waitForExistence(timeout: 15))
        line.tap()
        sleep(1)
        app.typeText("Return writes this")
        app.typeText("\n")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Return writes this"))
            .firstMatch.waitForExistence(timeout: 5), "Return didn't write the note")
        // An empty line shows its prompt as the value.
        XCTAssertEqual(line.value as? String ?? "", "Write something. @ links a thing", "The line didn't clear")
        sleep(2)
    }
}
