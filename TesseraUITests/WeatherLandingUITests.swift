import XCTest

/// The Weather landing (243, landing contract §14): the condition word opens the hours, a dial neighbour turns the
/// dial, and the foot carries "Rain alert". Launched straight onto the landing with `-weatherLanding`.
@MainActor
final class WeatherLandingUITests: SimulatorOnlyTestCase {
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-weatherLanding", "-demoTime", "13:10"]
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["Weather"].firstMatch.waitForExistence(timeout: 20),
                      "The landing is up")
        return app
    }

    func testFootAndDialNeighbour() {
        let app = launch()
        XCTAssertTrue(app.descendants(matching: .any)["Rain alert"].firstMatch.exists, "The action word")
        let week = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Week'")).firstMatch
        XCTAssertTrue(week.waitForExistence(timeout: 5), "Week is a neighbour of Hours")
        week.tap()
        let selected = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Week' AND selected == true"))
        XCTAssertTrue(selected.firstMatch.waitForExistence(timeout: 3), "The dial turned to Week")
    }

    func testConditionWordOpensTheHours() {
        let app = launch()
        let word = app.descendants(matching: .any).matching(identifier: "weather.condition").firstMatch
        XCTAssertTrue(word.waitForExistence(timeout: 5), "The keystone shows the condition")
        word.tap()
        XCTAssertTrue(app.staticTexts["Hours"].waitForExistence(timeout: 5), "The hours page opened")
    }
}
