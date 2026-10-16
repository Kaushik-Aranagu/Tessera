import XCTest

/// Design 41: Home says one plain line per thing. The day word, the context line, the hero and the Next rows show
/// with nothing cut; a long row title wraps rather than ending in "…".
@MainActor
final class HomeLinesUITests: SimulatorOnlyTestCase {
    func testHomeLinesShowAndNothingIsCut() {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-demoTime", "18:10", "-resetDemo"]
        app.launch()
        let soul = app.buttons["Tess"]
        XCTAssertTrue(soul.waitForExistence(timeout: 15))
        sleep(2)
        snap(app, "today")
        let cut = app.staticTexts.matching(NSPredicate(format: "label ENDSWITH %@", "…")).firstMatch
        XCTAssertFalse(cut.exists, "A line on Home ends in an ellipsis")
        let read = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Read Designing")).firstMatch
        XCTAssertTrue(read.waitForExistence(timeout: 3), "The long row title is on Home")
        XCTAssertTrue(read.frame.height > 40, "The long title wraps to a second line")
    }

    private func snap(_ app: XCUIApplication, _ name: String) {
        guard let dir = ProcessInfo.processInfo.environment["UITEST_SNAPS"] else { return }
        try? app.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: "\(dir)/\(name).png"))
        try? app.debugDescription.write(toFile: "\(dir)/\(name).txt", atomically: true, encoding: .utf8)
    }

    /// Mid-morning: a task is Now, with its time above and the Finish key under it.
    func testTaskHeroReadsOneLine() {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-demoTime", "10:00", "-resetDemo"]
        app.launch()
        let soul = app.buttons["Tess"]
        XCTAssertTrue(soul.waitForExistence(timeout: 15))
        sleep(2)
        snap(app, "morning")
        let cut = app.staticTexts.matching(NSPredicate(format: "label ENDSWITH %@", "…")).firstMatch
        XCTAssertFalse(cut.exists, "A line on Home ends in an ellipsis")
        sleep(1)
    }

    /// Design 53: at 08:10 the plan is Now; a hold on START WITH keeps it and Tess says so with UNDO.
    func testPlanOfferAndHoldKeepsIt() {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-demoTime", "08:10", "-resetDemo", "-planNow"]
        app.launch()
        let plan = app.staticTexts["Plan"]
        XCTAssertTrue(plan.waitForExistence(timeout: 15), "The plan is offered")
        sleep(2)
        snap(app, "plan")
        // Swipe right keeps one row: its words dry into ink and Tess names it with UNDO.
        let row = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", "Proposed: Book physio")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        let from = row.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5))
        from.press(forDuration: 0.5, thenDragTo: row.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)),
                   withVelocity: 600, thenHoldForDuration: 0.1)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Book physio,"))
            .firstMatch.waitForExistence(timeout: 5), "The kept row is said")
        sleep(2)
        snap(app, "row-kept")
        let key = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", "Start with ")).firstMatch
        XCTAssertTrue(key.exists)
        key.press(forDuration: 1.1)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Plan kept."))
            .firstMatch.waitForExistence(timeout: 5), "The hold keeps the plan")
        sleep(2)
        snap(app, "kept")
    }
}
