import XCTest

/// Kaushik on 16b6d1aa: "Keyboard is blocking what is seen and no way to send too." With the keyboard up, Tess's
/// sheet rides above it: the field and Send are visible and above the keyboard, nothing in the sheet overlaps, and
/// Send (or return) sends.
@MainActor
final class TessTypingUITests: SimulatorOnlyTestCase {
    func testTypingToTessKeepsTheFieldAndSendAboveTheKeyboard() {
        let app = XCUIApplication()
        app.launchArguments = ["-review.sampleData", "On", "-review.landingPages", "On", "-demoTime", "18:10"]
        app.launch()
        let ask = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Don’t Allow"]
        if ask.waitForExistence(timeout: 4) {
            ask.tap()
        }
        let tess = app.buttons["Tess"].firstMatch
        XCTAssertTrue(tess.waitForExistence(timeout: 30), "Tess on Bridge")
        sleep(6)
        let field = app.textFields["Type to Tess"].firstMatch
        let textView = app.textViews["Type to Tess"].firstMatch
        for _ in 0 ..< 3 where !field.exists && !textView.exists {
            tess.tap()
            sleep(2)
        }
        let entry = field.exists ? field : textView
        XCTAssertTrue(entry.waitForExistence(timeout: 10), "Type to Tess field")
        entry.tap()
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForExistence(timeout: 10), "keyboard up")
        entry.typeText("Hello Tess")
        sleep(1)
        // By identifier: the field's label and value change as he types.
        let typed = app.descendants(matching: .any)["tess.field"].firstMatch
        let send = app.descendants(matching: .any)["tess.send"].firstMatch
        XCTAssertTrue(typed.waitForExistence(timeout: 5), "the field is still there")
        XCTAssertTrue(send.waitForExistence(timeout: 5) && send.isHittable, "Send is reachable")
        let input = typed
        XCTAssertLessThanOrEqual(input.frame.maxY, keyboard.frame.minY + 1, "field above the keyboard")
        XCTAssertLessThanOrEqual(send.frame.maxY, keyboard.frame.minY + 1, "Send above the keyboard")
        XCTAssertFalse(send.frame.intersects(input.frame), "Send and the field do not overlap")
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Tess typing, keyboard up"
        shot.lifetime = .keepAlways
        add(shot)
        send.tap()
        sleep(2)
        XCTAssertEqual((input.value as? String)?.contains("Hello Tess"), false, "Send sent it")
    }
}
