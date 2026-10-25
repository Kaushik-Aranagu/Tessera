import XCTest

/// The Training landing (landing contract §12, §14): the foot carries the day's action word, the dial turns to a
/// tapped neighbour, and a wall word opens its page. Launched straight onto the landing with `-trainingLanding`.
@MainActor
final class TrainingWallLandingUITests: SimulatorOnlyTestCase {
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-trainingLanding", "-demo", "-demoTime", "18:10"]
        app.launch()
        XCTAssertTrue(
            app.descendants(matching: .any)["Training"].firstMatch.waitForExistence(timeout: 20),
            "The landing is up"
        )
        return app
    }

    func testFootWordAndDialTurnToATappedNeighbour() {
        let app = launch()
        let foot = app.descendants(matching: .any).matching(
            NSPredicate(format: "label BEGINSWITH 'Start' OR label BEGINSWITH 'Pick up' OR label == 'Log a walk'")
        ).firstMatch
        XCTAssertTrue(foot.waitForExistence(timeout: 5), "The foot carries the day's action word")
        let routines = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Routines'")).firstMatch
        XCTAssertTrue(routines.waitForExistence(timeout: 5), "Routines is a neighbour of This week")
        routines.tap()
        let selected = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Routines' AND selected == true"))
        XCTAssertTrue(selected.firstMatch.waitForExistence(timeout: 3), "The dial turned to Routines")
    }

    func testAWallWordOpensItsPage() {
        let app = launch()
        let word = app.buttons.matching(NSPredicate(format: "label ENDSWITH ', exercise'")).firstMatch
        XCTAssertTrue(word.waitForExistence(timeout: 5), "The wall shows a lift")
        word.tap()
        XCTAssertFalse(word.waitForExistence(timeout: 2) && word.isHittable, "The lift's page is open")
    }
}
