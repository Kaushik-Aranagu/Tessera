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
}
