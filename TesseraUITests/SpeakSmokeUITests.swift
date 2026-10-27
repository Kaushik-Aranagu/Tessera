import XCTest

/// QA's first-Speak check (#273): tap Speak with no script. The app must not crash, and the line must not be "The mic
/// is busy with a call." (that meant the audio session refused its category).
@MainActor
final class SpeakSmokeUITests: SimulatorOnlyTestCase {
    func testFirstSpeakNeitherCrashesNorReadsBusy() {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-demoTime", "18:10", "-resetDemo"]
        app.launch()
        let soul = app.descendants(matching: .any)["Tess"].firstMatch
        XCTAssertTrue(soul.waitForExistence(timeout: 15))
        sleep(2)
        soul.press(forDuration: 0.12)
        sleep(2)
        snap(app, "opened")
        let speak = app.descendants(matching: .any).matching(NSPredicate(format: "label ==[c] %@", "Speak")).firstMatch
        XCTAssertTrue(speak.waitForExistence(timeout: 8))
        speak.tap()
        // The mic alert, then the speech alert, come from SpringBoard.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for _ in 0 ..< 2 {
            let allow = springboard.buttons.matching(NSPredicate(format: "label IN %@", ["Allow", "OK"])).firstMatch
            if allow.waitForExistence(timeout: 5) {
                allow.tap()
            }
        }
        sleep(3)
        snap(app, "speak")
        XCTAssertEqual(app.state, .runningForeground, "Speak crashed the app")
        XCTAssertFalse(app.staticTexts["The mic is busy with a call"].exists, "The audio session refused its category")
    }

    private func snap(_ app: XCUIApplication, _ name: String) {
        guard let dir = ProcessInfo.processInfo.environment["UITEST_SNAPS"] else { return }
        try? app.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: "\(dir)/\(name).png"))
        try? app.debugDescription.write(toFile: "\(dir)/\(name).txt", atomically: true, encoding: .utf8)
    }
}
