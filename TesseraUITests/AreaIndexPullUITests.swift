import XCTest

/// Kaushik, release 21: a pull-down from a low start always let go on Kitchen, and dragging back up closed it. QA on
/// #1124: a pull showed no sheet at all. These drive a real finger (down, move, hold, lift) and look at the screen
/// while it is still down.
@MainActor
final class AreaIndexPullUITests: SimulatorOnlyTestCase {
    private func launch() -> XCUIApplication {
        // A fresh simulator asks about notifications on first launch; that must not eat the pull.
        addUIInterruptionMonitor(withDescription: "Notifications") { alert in
            let button = alert.buttons["Don’t Allow"]
            if button.exists {
                button.tap(); return true
            }
            return false
        }
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-demoTime", "18:10", "-resetDemo"]
        app.launch()
        XCTAssertTrue(app.buttons["Today, area"].waitForExistence(timeout: 15))
        sleep(1)
        return app
    }

    /// A finger from `x, startY` that pulls down to `peak`, holds there while `look` runs, comes back up to `end`
    /// (when given) and lifts. Points are in screen points; the finger moves at a steady pace.
    private func pull(_ app: XCUIApplication, startY: CGFloat, peak: CGFloat, end: CGFloat? = nil,
                      look: () -> Void)
    {
        let x = app.windows.firstMatch.frame.midX
        var moves: [(point: CGPoint, at: TimeInterval)] = []
        var time = 0.0
        for y in stride(from: startY, through: startY + peak, by: 10) {
            moves.append((CGPoint(x: x, y: y), time))
            time += 0.02
        }
        time += 1.2 // held at the peak: the sheet must be there
        moves.append((CGPoint(x: x, y: startY + peak), time))
        if let end {
            let down = peak > end
            for y in stride(from: startY + peak, through: startY + end, by: down ? -10 : 10) {
                time += 0.02
                moves.append((CGPoint(x: x, y: y), time))
            }
            time += 0.4
            moves.append((CGPoint(x: x, y: startY + end), time))
        }
        let finish = HeldTouch(moves: moves).start(self)
        sleep(1)
        look()
        finish()
    }

    func testAPullShowsTheSheetWhileTheFingerIsDownAndLandsOnTraining() {
        for startY in [380.0, 520.0] as [CGFloat] {
            let app = launch()
            // 150 pt down is one row on from Today: Training, from a high or a low start alike.
            pull(app, startY: startY, peak: 150) {
                XCTAssertTrue(
                    app.buttons["TRAINING, Push Day A is on"].exists || app.staticTexts["Let go to open"].exists,
                    "No index sheet while pulling from \(startY)"
                )
            }
            XCTAssertTrue(app.buttons["Training, area"].waitForExistence(timeout: 4),
                          "A pull from \(startY) did not land on Training")
            app.terminate()
        }
    }

    func testPullingBackUpPastTheStartLandsOnReview() {
        let app = launch()
        // 120 pt down forms the index; coming back up 120 pt to 0 steps two rows up from Today... that is Review one
        // row up at 60 pt per row: peak 120 then end at 60 above the formation point.
        pull(app, startY: 480, peak: 130, end: 20) {
            XCTAssertTrue(app.staticTexts["Let go to open"].exists, "No index sheet while the finger is down")
        }
        XCTAssertTrue(
            app.buttons["Review, area"].waitForExistence(timeout: 4),
            "Pulling back up did not land on Review"
        )
    }

    func testAShortPullCancelsWithoutChangingTheArea() {
        let app = launch()
        pull(app, startY: 480, peak: 40) {}
        sleep(1)
        XCTAssertTrue(app.buttons["Today, area"].exists, "A short pull changed the area")
    }
}
