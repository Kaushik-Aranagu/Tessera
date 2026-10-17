import XCTest

/// Design's v9 walk R1: Review's foot line sits above Tess's band (736 to 820 on the 874 pt iPhone).
@MainActor
final class ReviewFootLineUITests: SimulatorOnlyTestCase {
    func testFootLineClearsTessBand() {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-demoTime", "18:10", "-resetDemo", "-homePage", "review"]
        app.launch()
        let notes = app.buttons["Notes"]
        XCTAssertTrue(notes.waitForExistence(timeout: 15))
        sleep(2)
        XCTAssertLessThanOrEqual(notes.frame.maxY, 736 * app.frame.height / 874, "The foot line sits in Tess's band")
    }
}
