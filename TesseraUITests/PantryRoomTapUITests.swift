import XCTest

/// Positive mutations run against the in-memory sample model on a private lane simulator, never the real store.
@MainActor
final class PantryRoomTapUITests: SimulatorOnlyTestCase {
    private func launchOnFridge(largeType: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-demoTime", "18:10", "-openLink", "pantry", "-review.sampleData", "On",
                               "-featureFlags.off", "homeMosaic;homeV2"]
        if largeType {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launch()
        XCTAssertTrue(app.buttons["pantry.chooseThing"].waitForExistence(timeout: 30), "The compact Pantry is open")
        let dial = app.descendants(matching: .any)["Place"]
        XCTAssertTrue(dial.waitForExistence(timeout: 5))
        dial.swipeUp(velocity: .fast)
        wait(NSPredicate(format: "value BEGINSWITH %@", "Fridge"), on: dial)
        return app
    }

    private func wait(_ predicate: NSPredicate, on element: XCUIElement, timeout: TimeInterval = 8) {
        let expected = XCTNSPredicateExpectation(predicate: predicate, object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [expected], timeout: timeout), .completed)
    }

    private func row(_ name: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS[cd] %@",
                                         "pantry.row.", name)).firstMatch
    }

    private func add(_ name: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons["Add a thing"].tap()
        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText(name + "\n")
        let result = row(name, in: app)
        XCTAssertTrue(result.waitForExistence(timeout: 8))
        return result
    }

    private func expectItem(_ name: String, in app: XCUIApplication) {
        let title = app.staticTexts["pantry.itemTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertEqual(title.label.lowercased(), name.lowercased())
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = "Pantry item actions"
        image.lifetime = .keepAlways
        add(image)
    }

    func testCompactRowTapOpensItsActionsAndLowCanBeUndone() {
        let app = launchOnFridge()
        let eggs = add("Eggs", in: app)
        let before = eggs.label
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = "Pantry compact columns"
        image.lifetime = .keepAlways
        add(image)
        eggs.tap()
        expectItem("Eggs", in: app)
        app.buttons["pantry.action.toggle"].tap()
        wait(NSPredicate(format: "label CONTAINS %@", "low"), on: eggs)
        XCTAssertTrue(app.buttons["Undo"].waitForExistence(timeout: 5))
        app.buttons["Undo"].tap()
        wait(NSPredicate(format: "label == %@", before), on: eggs)
    }

    func testCompactSwipeCannotMutateAndChooserUsedUpCanBeUndone() {
        let app = launchOnFridge()
        let eggs = add("Eggs", in: app)
        let before = eggs.label
        let start = eggs.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 120, dy: 0)))
        XCTAssertTrue(eggs.exists)
        XCTAssertEqual(eggs.label, before)
        XCTAssertFalse(app.staticTexts["pantry.itemTitle"].exists)
        let chooser = app.buttons["pantry.chooseThing"]
        XCTAssertGreaterThanOrEqual(chooser.frame.height, 44)
        chooser.tap()
        let choice = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS[cd] %@",
                                                      "pantry.choose.", "Eggs")).firstMatch
        XCTAssertTrue(choice.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(choice.frame.height, 44)
        choice.tap()
        expectItem("Eggs", in: app)
        let usedUp = app.buttons["pantry.action.usedUp"]
        XCTAssertGreaterThanOrEqual(usedUp.frame.height, 44)
        usedUp.tap()
        wait(NSPredicate(format: "exists == false"), on: eggs)
        XCTAssertTrue(app.buttons["Undo"].waitForExistence(timeout: 5))
        app.buttons["Undo"].tap()
        XCTAssertTrue(eggs.waitForExistence(timeout: 5))
        XCTAssertEqual(eggs.label, before)
    }

    func testTwoPointsInsideEachNeighbourOpensThatItemWithoutMutation() {
        let app = launchOnFridge()
        let eggs = add("Eggs", in: app)
        let milk = add("Milk", in: app)
        let originals = [eggs.label, milk.label]
        for (element, title) in [(eggs, "Eggs"), (milk, "Milk")] {
            element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0))
                .withOffset(CGVector(dx: 0, dy: 2)).tap()
            expectItem(title, in: app)
            app.buttons["Done"].tap()
        }
        XCTAssertEqual(eggs.label, originals[0])
        XCTAssertEqual(milk.label, originals[1])
    }

    func testFullSizedRowSwipeMutatesAndUndoRestoresIt() {
        let app = launchOnFridge(largeType: true)
        let eggs = add("Eggs", in: app)
        let before = eggs.label
        XCTAssertGreaterThanOrEqual(eggs.frame.height, 44)
        eggs.press(forDuration: 0.6)
        wait(NSPredicate(format: "label BEGINSWITH[c] %@", "pinned, Eggs"), on: eggs)
        XCTAssertFalse(eggs.label.contains("low"), "A pin hold must not also toggle stock")
        app.buttons["Undo"].tap()
        wait(NSPredicate(format: "label == %@", before), on: eggs)
        let start = eggs.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 120, dy: 0)))
        wait(NSPredicate(format: "exists == false"), on: eggs)
        XCTAssertTrue(app.buttons["Undo"].waitForExistence(timeout: 5))
        app.buttons["Undo"].tap()
        XCTAssertTrue(eggs.waitForExistence(timeout: 5))
        XCTAssertEqual(eggs.label, before)
    }

    func testFocusedRecipeTapOpensItsRecipePage() {
        let app = XCUIApplication()
        app.launchArguments = ["-demoTime", "18:10", "-openLink", "recipes", "-review.sampleData", "On",
                               "-featureFlags.off", "homeMosaic;homeV2"]
        app.launch()
        let dial = app.descendants(matching: .any)["Place"]
        XCTAssertTrue(dial.waitForExistence(timeout: 30))
        // Ready now wraps back to All, so the fixture always has the full recipe book available.
        dial.swipeDown(velocity: .fast)
        wait(NSPredicate(format: "value BEGINSWITH %@", "All"), on: dial)
        let recipe = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND identifier != %@",
                                                      "kitchen.wheel.", "kitchen.wheel.new")).firstMatch
        XCTAssertTrue(recipe.waitForExistence(timeout: 8))
        recipe.tap()
        XCTAssertTrue(app.buttons["Recipes"].waitForExistence(timeout: 8), "The recipe page opened")
    }
}
