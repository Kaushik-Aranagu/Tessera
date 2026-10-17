import XCTest

/// QA on #662: the stroke strip over Tess's band never swallows a pushed page's taps or scroll starts (rows can sit
/// at y 724 to 784 off Home).
@MainActor
final class SoulStrokeBandUITests: SimulatorOnlyTestCase {
    func testAPushedPageScrollsFromTheBand() {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-demoTime", "18:10", "-resetDemo", "-homePage", "review"]
        app.launch()
        let week = app.buttons["The week"]
        XCTAssertTrue(week.waitForExistence(timeout: 15))
        week.tap()
        let look = app.staticTexts["LOOK"]
        XCTAssertTrue(look.waitForExistence(timeout: 10))
        let before = look.frame.minY
        // A scroll that starts inside the band (y ≈ 760 on the 874 pt phone) moves the page.
        let scale = app.frame.height / 874
        let start = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: 120, dy: 760 * scale))
        let end = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: 120, dy: 460 * scale))
        start.press(forDuration: 0.05, thenDragTo: end)
        sleep(1)
        XCTAssertLessThan(look.frame.minY, before - 50, "The page didn't scroll from a touch in the band")
    }
}
