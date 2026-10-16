import XCTest

/// The Home walk for Design 41's recording: start the routine, log two sets, come back to Home paused (RESUME with
/// the progress line), resume, finish, and read the done hero. Snapshots name each state.
@MainActor
final class HomeWalkUITests: SimulatorOnlyTestCase {
    func testStartLogPauseResumeFinish() {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-demoTime", "18:10", "-resetDemo"]
        app.launch()
        let starts = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Start Push"))
        XCTAssertTrue(starts.firstMatch.waitForExistence(timeout: 15))
        sleep(2)
        snap(app, "home")
        // The Training page's key sits off screen to the right; Today's is on screen.
        let start = starts.allElementsBoundByIndex.first { $0.frame.minX >= 0 && $0.frame.minX < 400 }
        XCTAssertNotNil(start)
        start?.tap()
        sleep(3)
        snap(app, "live")
        // Two sets, by the hold on Log set (the cover's keys resolve by position: its tree lags the query).
        // Log set 1, skip the rest, log set 2: the same key, held three times.
        for _ in 0 ..< 3 {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.84)).press(forDuration: 1.2)
            sleep(3)
        }
        snap(app, "logged")
        // Minimise: the chevron at the top right.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.89, dy: 0.102)).tap()
        sleep(3)
        snap(app, "running-home")
        let resumes = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Resume Push"))
            .allElementsBoundByIndex.filter { $0.frame.minX >= 0 && $0.frame.minX < 400 }
        XCTAssertFalse(resumes.isEmpty)
        resumes[0].tap()
        sleep(3)
        snap(app, "live2")
        // The title at the top opens the workout's own sheet, where Finish lives.
        let title = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Push Day A,"))
            .allElementsBoundByIndex.first { $0.frame.minY < 120 }
        title?.tap()
        sleep(2)
        snap(app, "menu")
        // Finish here, by the hold.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.61)).press(forDuration: 1.2)
        sleep(4)
        snap(app, "finished")
        let back = app.buttons["Back to today"]
        if back.waitForExistence(timeout: 10) {
            sleep(2)
            back.tap()
        }
        sleep(4)
        snap(app, "home-after")
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label ENDSWITH %@", "…")).firstMatch.exists)
    }

    private func snap(_ app: XCUIApplication, _ name: String) {
        guard let dir = ProcessInfo.processInfo.environment["UITEST_SNAPS"] else { return }
        try? app.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: "\(dir)/\(name).png"))
        try? app.debugDescription.write(toFile: "\(dir)/\(name).txt", atomically: true, encoding: .utf8)
    }
}
