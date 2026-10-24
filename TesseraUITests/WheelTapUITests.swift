import XCTest

/// Sheet 230: a plain tap must reach a wheel's row buttons (the apps list lost its taps to a high-priority drag).
/// `-wheelLab` puts one wheel alone on a page; its focus and the row it opened are read back.
@MainActor
final class WheelTapUITests: SimulatorOnlyTestCase {
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-wheelLab"]
        app.launch()
        XCTAssertTrue(app.staticTexts["wheel-focus"].waitForExistence(timeout: 60))
        return app
    }

    func testATapOnAnotherRowCentresIt() {
        let app = launch()
        XCTAssertEqual(app.staticTexts["wheel-focus"].label, "Focused 3")
        let row = app.buttons["wheel-row-5"]
        XCTAssertTrue(row.waitForExistence(timeout: 3))
        row.tap()
        expectation(for: NSPredicate(format: "label == %@", "Focused 5"), evaluatedWith: app.staticTexts["wheel-focus"])
        waitForExpectations(timeout: 3)
    }

    func testATapOnTheFocusedRowOpensIt() {
        let app = launch()
        XCTAssertEqual(app.staticTexts["wheel-opened"].label, "Opened none")
        app.buttons["wheel-row-3"].tap()
        expectation(for: NSPredicate(format: "label == %@", "Opened 3"), evaluatedWith: app.staticTexts["wheel-opened"])
        waitForExpectations(timeout: 3)
    }

    func testADragOnTheNumberNeverMovesTheWheel() {
        let app = launch()
        let number = app.descendants(matching: .any)["wheel-number"]
        XCTAssertTrue(number.waitForExistence(timeout: 3))
        let from = number.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        from.press(forDuration: 0.05, thenDragTo: number.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: -1.5)))
        XCTAssertEqual(app.staticTexts["wheel-focus"].label, "Focused 3")
    }
}
