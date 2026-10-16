import XCTest

/// Design 46: REVIEW is the week on one page; a tap on a day reads that day, a second tap brings the week back.
@MainActor
final class ReviewWeekUITests: SimulatorOnlyTestCase {
    func testTapADayReadsItAndTapAgainReturns() {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-demoTime", "18:10", "-resetDemo", "-homePage", "review"]
        app.launch()
        let training = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", "Training, ")).firstMatch
        XCTAssertTrue(training.waitForExistence(timeout: 15))
        sleep(2)
        snap(app, "week")

        let thursday = app.buttons["Thursday"]
        XCTAssertTrue(thursday.exists)
        thursday.tap()
        XCTAssertTrue(app.staticTexts["Thursday"].waitForExistence(timeout: 3), "The context line names the day")
        sleep(2)
        snap(app, "thursday")

        thursday.tap()
        XCTAssertTrue(app.staticTexts["the week so far"].waitForExistence(timeout: 3), "The week comes back")
        sleep(1)
    }

    private func snap(_ app: XCUIApplication, _ name: String) {
        guard let dir = ProcessInfo.processInfo.environment["UITEST_SNAPS"] else { return }
        try? app.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: "\(dir)/\(name).png"))
        try? app.debugDescription.write(toFile: "\(dir)/\(name).txt", atomically: true, encoding: .utf8)
    }
}
