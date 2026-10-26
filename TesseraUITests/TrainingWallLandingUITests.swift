import XCTest

/// The Training landing (landing contract §12, §14): the foot carries the day's action word, the dial turns to a
/// tapped neighbour, and a best's number on the blackboard opens its lift. Launched straight onto the landing with
/// `-trainingLanding`.
@MainActor
final class TrainingWallLandingUITests: SimulatorOnlyTestCase {
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-trainingLanding", "-demo", "-demoTime", "18:10"]
        app.launch()
        XCTAssertTrue(
            app.descendants(matching: .any)["Deck"].firstMatch.waitForExistence(timeout: 20),
            "The landing is up"
        )
        return app
    }

    func testFootWordAndDialTurnToATappedNeighbour() {
        let app = launch()
        let foot = app.descendants(matching: .any).matching(
            NSPredicate(
                format: "label BEGINSWITH 'Start, ' OR label BEGINSWITH 'Pick up, ' OR label == 'Log, A walk' OR label == 'Pick, A routine'"
            )
        ).firstMatch
        XCTAssertTrue(foot.waitForExistence(timeout: 5), "The foot carries the day's action word")
        let week = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'This week'")).firstMatch
        XCTAssertTrue(week.waitForExistence(timeout: 5), "This week is a neighbour of Today")
        week.tap()
        let selected = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'This week' AND selected == true"))
        XCTAssertTrue(selected.firstMatch.waitForExistence(timeout: 3), "The dial turned to This week")
    }

    func testABestOnTheBoardOpensItsLift() {
        let app = launch()
        let best = app.buttons.matching(NSPredicate(format: "label CONTAINS ' best '")).firstMatch
        XCTAssertTrue(best.waitForExistence(timeout: 5), "The board writes a best")
        best.tap()
        XCTAssertFalse(best.waitForExistence(timeout: 2) && best.isHittable, "The lift's page is open")
    }
}
