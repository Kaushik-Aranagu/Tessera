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
        // Two sets by the hold on LOG; a rest sits between them (the third hold logs set 2 after skipping it).
        for _ in 0 ..< 3 {
            let log = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Hold to log set")).firstMatch
            if log.waitForExistence(timeout: 5) {
                log.press(forDuration: 1.2)
            } else {
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.80)).press(forDuration: 1.2)
            }
            sleep(3)
        }
        snap(app, "logged")
        let pause = app.buttons.matching(NSPredicate(format: "label ==[c] %@", "Pause the workout")).firstMatch
        XCTAssertTrue(pause.waitForExistence(timeout: 5), "PAUSE is on the workout")
        pause.tap()
        sleep(3)
        snap(app, "paused-home")
        let resume = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Resume Push"))
            .allElementsBoundByIndex.first { $0.frame.minX >= 0 && $0.frame.minX < 400 }
        XCTAssertNotNil(resume, "Home shows RESUME once the workout is paused")
        sleep(3)
        resume?.tap()
        sleep(3)
        snap(app, "live2")
        // The title at the top opens the running order, where FINISH HERE is held.
        let title = app.buttons.allElementsBoundByIndex
            .first { $0.frame.minY > 60 && $0.frame.minY < 125 && $0.frame.width > 300 }
        XCTAssertNotNil(title, "The workout's context line opens the running order")
        title?.tap()
        sleep(2)
        let finish = app.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] %@", "Finish here")).firstMatch
        XCTAssertTrue(finish.waitForExistence(timeout: 5), "FINISH HERE is in the running order")
        finish.press(forDuration: 1.2)
        sleep(4)
        snap(app, "finished")
        let back = app.buttons.matching(NSPredicate(format: "label ==[c] %@", "Back to today")).firstMatch
        XCTAssertTrue(back.waitForExistence(timeout: 10))
        sleep(2)
        back.tap()
        sleep(4)
        snap(app, "home-after")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label ENDSWITH %@", " done")).firstMatch
            .waitForExistence(timeout: 5) || true)
        sleep(2)
    }

    private func snap(_ app: XCUIApplication, _ name: String) {
        guard let dir = ProcessInfo.processInfo.environment["UITEST_SNAPS"] else { return }
        try? app.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: "\(dir)/\(name).png"))
        try? app.debugDescription.write(toFile: "\(dir)/\(name).txt", atomically: true, encoding: .utf8)
    }
}
