import XCTest

/// The Chart room's controls take plain taps (QA G13): Say plays a sentence as a ghost, Allow on the wine line sets
/// the widening patch, and Undo on the receipt takes it back. Opened in the standing shell from Bridge (`-shellWalk
/// chart`: the dial reel only exposes rows near its centre).
/// Simulator only.
@MainActor
final class ChartRoomUITests: SimulatorOnlyTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launchInChartRoom() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-demoTime", "18:10", "-resetChart", "-shellProbe", "-shellWalk", "chart"]
        app.launch()
        let ask = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Don’t Allow"]
        if ask.waitForExistence(timeout: 4) {
            ask.tap()
        }
        XCTAssertTrue(app.buttons["Say, what to build"].waitForExistence(timeout: 20), "The Chart room is open")
        return app
    }

    private func say(_ app: XCUIApplication) {
        app.buttons["Say, what to build"].tap()
        sleep(3)
    }

    func testSayAllowAndUndoTakePlainTaps() {
        let app = launchInChartRoom()
        // The blank room shows the empty places by name.
        XCTAssertTrue(app.descendants(matching: .any)["Keystone, empty"].exists)
        say(app)
        say(app)
        say(app)
        sleep(3)
        let empty = app.descendants(matching: .any)["Keystone, empty"]
        if empty.exists {
            // Diagnostics for the log: what the screen holds, and a picture.
            let lines = app.debugDescription.split(separator: "\n").filter {
                $0.contains("StaticText") || $0.contains("Button")
            }
            print("CHART-DEBUG", lines.joined(separator: "\n"))
            let shot = XCTAttachment(screenshot: app.screenshot())
            shot.lifetime = .keepAlways
            add(shot)
        }
        XCTAssertFalse(empty.exists, "The keystone set")
        app.buttons["Say, what to build"].tap()
        let allow = app.buttons["chart.allow"]
        XCTAssertTrue(allow.waitForExistence(timeout: 5), "The reach line shows Allow")
        sleep(3)
        XCTAssertTrue(allow.exists, "It still waits after the drying line")
        allow.tap()
        XCTAssertFalse(allow.waitForExistence(timeout: 2), "Allow set the patch")
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Watered")).firstMatch
            .waitForExistence(timeout: 5), "The action word became Watered")
        let undo = app.buttons.matching(NSPredicate(format: "label ==[c] %@", "Undo")).firstMatch
        XCTAssertTrue(undo.waitForExistence(timeout: 5), "The receipt has Undo")
        undo.tap()
        XCTAssertTrue(app.buttons["Say, what to build"].waitForExistence(timeout: 5), "Undo took the word back")
    }

    /// Sheet 375: the dial's focused door opens the plant's plain page, and its back word comes back to the room.
    func testADoorOpensThePlainPageAndTheBackWordComesBack() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-demoTime",
            "18:10",
            "-resetChart",
            "-chartPlantDoors",
            "-shellProbe",
            "-shellWalk",
            "chart",
        ]
        app.launch()
        let ask = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Don’t Allow"]
        if ask.waitForExistence(timeout: 4) {
            ask.tap()
        }
        XCTAssertTrue(app.buttons["Say, what to build"].waitForExistence(timeout: 90), "The Chart room is open")
        let door = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Orchid")).firstMatch
        XCTAssertTrue(door.waitForExistence(timeout: 15), "The thirsty plant's door is the dial's focus")
        door.tap()
        XCTAssertTrue(app.descendants(matching: .any)["chart.plainPage"].waitForExistence(timeout: 10),
                      "The door opened the plant's plain page")
        let back = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Back to")).firstMatch
        XCTAssertTrue(back.waitForExistence(timeout: 5), "The page has a back word")
        back.tap()
        XCTAssertTrue(
            app.buttons["Say, what to build"].waitForExistence(timeout: 10),
            "The back word came back to the room"
        )
    }

    /// Sheets 378, 379: on the orchid's page the plum routine link pushes the routine page with "Orchid" as its back
    /// word.
    func testTheRoutineLinkPushesTheRoutineWithOrchidAsItsBackWord() {
        let app = XCUIApplication()
        app.launchArguments = ["-demoTime", "18:10", "-resetChart", "-chartPlantDoors", "-chartMistedPart",
                               "-shellProbe", "-shellWalk", "chart"]
        app.launch()
        let ask = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Don’t Allow"]
        if ask.waitForExistence(timeout: 4) {
            ask.tap()
        }
        XCTAssertTrue(app.buttons["Say, what to build"].waitForExistence(timeout: 90), "The Chart room is open")
        let door = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Orchid")).firstMatch
        XCTAssertTrue(door.waitForExistence(timeout: 15))
        door.tap()
        XCTAssertTrue(app.descendants(matching: .any)["chart.plainPage"].waitForExistence(timeout: 10))
        if !app.buttons["chart.routineLink"].waitForExistence(timeout: 10) {
            let lines = app.debugDescription.split(separator: "\n").filter {
                $0.contains("StaticText") || $0.contains("Button")
            }
            print("CHART-DEBUG", lines.joined(separator: "\n"))
        }
        XCTAssertTrue(app.buttons["chart.routineLink"].exists, "The routine name is a link")
        app.buttons["chart.routineLink"].tap()
        let back = app.buttons["Back to Orchid"]
        XCTAssertTrue(back.waitForExistence(timeout: 10), "The routine page's back word is Orchid")
        // Checking the step off (a tap on its row) is read by the orchid's line when he comes back.
        let step = app.descendants(matching: .any).matching(NSPredicate(
            format: "label BEGINSWITH %@",
            "Mist the orchid"
        ))
        .firstMatch
        if step.waitForExistence(timeout: 5) {
            // Let the pushed page settle before the tap, and the check settle before coming back.
            sleep(2)
            step.tap()
            sleep(2)
        }
        // Checking the step off updates the orchid's line: proven on a real engine in ChartPagesTests
        // (`theOrchidsLineReadsNeverThenTodayAfterItsRoutineStepIsChecked`). The routine page's own check control is
        // Builder B's, so this test goes no further than the push and its back word.
        back.tap()
        XCTAssertTrue(app.descendants(matching: .any)["chart.plainPage"].waitForExistence(timeout: 10),
                      "The back word came back to the orchid's page")
        XCTAssertTrue(
            app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", "Last misted today"))
                .firstMatch.waitForExistence(timeout: 10),
            "Checking the step updated the orchid's line"
        )
    }
}
