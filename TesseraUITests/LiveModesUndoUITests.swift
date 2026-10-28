import XCTest

/// Design 354: the receipt sits above the page in the whole-screen modes, so Undo takes a tap. Shopping and routine
/// mode both say things with an Undo; cooking mode has no receipt with one.
@MainActor
final class LiveModesUndoUITests: SimulatorOnlyTestCase {
    func testUndoTakesATapInRoutineMode() {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-demoTime", "21:00", "-resetDemo", "-openRoutine"]
        app.launch()
        let notTonight = app.buttons["not tonight"]
        XCTAssertTrue(notTonight.waitForExistence(timeout: 20), "Routine mode is open\n\(app.debugDescription)")
        notTonight.tap()
        let receipt = app.staticTexts["Tidy, tomorrow"]
        XCTAssertTrue(receipt.waitForExistence(timeout: 5), "Not tonight says Tidy, tomorrow")
        let undo = app.buttons.matching(identifier: "Undo").firstMatch
        XCTAssertTrue(undo.waitForExistence(timeout: 3) && undo.isHittable,
                      "Undo can be tapped\n\(app.debugDescription)")
        undo.tap()
        XCTAssertTrue(receipt.waitForNonExistence(timeout: 5), "Undo took the tap and the receipt went")
    }

    func testUndoTakesATapInShoppingMode() {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-demoTime", "18:10", "-resetDemo", "-demoKitchen", "-openShop"]
        app.launch()
        let notHere = app.buttons["Not here"]
        XCTAssertTrue(notHere.waitForExistence(timeout: 20), "Shopping mode is open\n\(app.debugDescription)")
        notHere.tap()
        let undo = app.buttons.matching(identifier: "Undo").firstMatch
        XCTAssertTrue(undo.waitForExistence(timeout: 5) && undo.isHittable,
                      "Undo can be tapped\n\(app.debugDescription)")
        undo.tap()
        XCTAssertTrue(undo.waitForNonExistence(timeout: 5), "Undo took the tap and the receipt went")
    }

    func testUndoTakesATapInCookingMode() {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-demoTime", "18:10", "-resetDemo", "-openCook", "Paprika chicken"]
        app.launch()
        let next = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Next")).firstMatch
        XCTAssertTrue(next.waitForExistence(timeout: 25), "Cooking mode is open\n\(app.debugDescription)")
        next.tap()
        let undo = app.buttons.matching(identifier: "Undo").firstMatch
        XCTAssertTrue(undo.waitForExistence(timeout: 5) && undo.isHittable,
                      "Undo can be tapped\n\(app.debugDescription)")
        undo.tap()
        XCTAssertTrue(undo.waitForNonExistence(timeout: 5), "Undo took the tap and the receipt went")
    }

    /// Sheets 313 and 379: the routine's steps page counts what is left, a tap checks a step with an Undo, and the
    /// back word names the page it came from.
    func testRoutineStepsPageChecksAStepAndUndoes() {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-demoTime", "21:00", "-resetDemo", "-openRoutinePage"]
        app.launch()
        let back = app.buttons["Back to Evening"]
        XCTAssertTrue(
            back.waitForExistence(timeout: 25),
            "The steps page names where it came from\n\(app.debugDescription)"
        )
        let tidy = app.switches.matching(NSPredicate(format: "label BEGINSWITH %@", "Tidy")).firstMatch
        XCTAssertTrue(tidy.waitForExistence(timeout: 5))
        let count = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", "5 steps"))
            .firstMatch
        XCTAssertTrue(count.waitForExistence(timeout: 5), "The line counts five steps\n\(app.debugDescription)")
        tidy.tap()
        let four = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", "4 steps"))
            .firstMatch
        XCTAssertTrue(four.waitForExistence(timeout: 5), "Checking a step counts down")
        let undo = app.buttons.matching(identifier: "Undo").firstMatch
        XCTAssertTrue(undo.waitForExistence(timeout: 5), "A receipt carries Undo")
    }
}
