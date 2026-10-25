import XCTest

/// The Settings landing (landing contract §12, §14): the six doors turn on the dial, the focus opens its page, and
/// there is no action word. Launched straight onto the landing with `-settingsLanding`.
@MainActor
final class SettingsLandingUITests: SimulatorOnlyTestCase {
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-settingsLanding", "-demo"]
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["Settings"].firstMatch.waitForExistence(timeout: 20),
                      "The landing is up")
        return app
    }

    func testDialTurnsToPrivacyAndOpensIt() {
        let app = launch()
        let privacy = app.buttons.matching(NSPredicate(format: "label == 'Privacy'")).firstMatch
        XCTAssertTrue(privacy.waitForExistence(timeout: 5), "Privacy is a neighbour of Tess")
        privacy.tap()
        let selected = app.buttons.matching(NSPredicate(format: "label == 'Privacy' AND selected == true"))
        XCTAssertTrue(selected.firstMatch.waitForExistence(timeout: 3), "The dial turned to Privacy")
        sleep(1)
        selected.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["kept on this phone"].waitForExistence(timeout: 5), "Privacy opened")
    }

    func testWallWordOpensItsArea() {
        let app = launch()
        let units = app.buttons["Units, setting"].firstMatch
        XCTAssertTrue(units.waitForExistence(timeout: 5), "Units is on the wall")
        units.tap()
        XCTAssertTrue(app.staticTexts["Units"].waitForExistence(timeout: 5), "Units opened")
    }
}
