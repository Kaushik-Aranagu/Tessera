import XCTest

/// Positive mutations run against the in-memory sample model on a private lane simulator, never the real store.
@MainActor
final class PantryRoomTapUITests: SimulatorOnlyTestCase {
    private static var motionPrepared = false

    /// System setting on this disposable simulator only. Keep the app's real ten-second Undo window intact.
    private func prepareMotion() {
        continueAfterFailure = false
        guard !Self.motionPrepared else { return }
        let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        settings.launch()
        let reduce = settings.switches["Reduce Motion"]
        if !reduce.exists {
            let motion = settings.staticTexts["Motion"]
            if !motion.exists {
                let accessibility = settings.staticTexts["Accessibility"]
                for _ in 0 ..< 6 where !accessibility.isHittable {
                    settings.swipeUp()
                }
                XCTAssertTrue(accessibility.waitForExistence(timeout: 5))
                accessibility.tap()
            }
            XCTAssertTrue(motion.waitForExistence(timeout: 5))
            motion.tap()
        }
        XCTAssertTrue(reduce.waitForExistence(timeout: 5))
        if reduce.value as? String != "1" {
            // Settings exposes the whole row as the switch; target its trailing toggle, not the row's text.
            reduce.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        }
        wait(NSPredicate(format: "value == %@", "1"), on: reduce, timeout: 5)
        settings.terminate()
        Self.motionPrepared = true
    }

    private func turn(_ dial: XCUIElement, down: Bool = false) {
        let start = dial.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: down ? 30 : -30)))
    }

    private func launchOnFridge(largeType: Bool = false, theme: String? = nil) -> XCUIApplication {
        prepareMotion()
        let app = XCUIApplication()
        app.launchArguments = ["-demoTime", "18:10", "-openLink", "pantry", "-review.sampleData", "On",
                               "-featureFlags.off", "homeMosaic;homeV2"]
        app.launchArguments += ["-UIPreferredContentSizeCategoryName",
                                largeType ? "UICTContentSizeCategoryAccessibilityXXXL" : "UICTContentSizeCategoryL"]
        if let theme {
            app.launchArguments += ["-theme", theme]
        }
        app.launch()
        XCTAssertTrue(app.buttons["pantry.chooseThing"].waitForExistence(timeout: 30), "The compact Pantry is open")
        let dial = app.descendants(matching: .any)["Place"]
        XCTAssertTrue(dial.waitForExistence(timeout: 5))
        turn(dial)
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

    private func fixture(_ name: String, in app: XCUIApplication) -> XCUIElement {
        let result = row(name, in: app)
        XCTAssertTrue(result.waitForExistence(timeout: 8), "The sample fixture has this stock row")
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
        let eggs = fixture("Eggs", in: app)
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
        let eggs = fixture("Eggs", in: app)
        let before = eggs.label
        eggs.press(forDuration: 0.6)
        if app.staticTexts["pantry.itemTitle"].exists {
            expectItem("Eggs", in: app)
            app.buttons["Done"].tap()
        }
        XCTAssertEqual(eggs.label, before, "A compact hold must not mutate or pin")
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
        let receipt = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@",
                                                           "used up. On To get.")).firstMatch
        XCTAssertTrue(receipt.waitForExistence(timeout: 5), "The engine confirmed the used-up mutation")
        wait(NSPredicate(format: "exists == false"), on: eggs)
        XCTAssertTrue(app.buttons["Undo"].waitForExistence(timeout: 5))
        app.buttons["Undo"].tap()
        XCTAssertTrue(eggs.waitForExistence(timeout: 5))
        XCTAssertEqual(eggs.label, before)
    }

    func testTwoPointsInsideEachNeighbourOpensThatItemWithoutMutation() {
        let app = launchOnFridge()
        let eggs = fixture("Eggs", in: app)
        let milk = fixture("Milk", in: app)
        let originals = [eggs.label, milk.label]
        for (element, title) in [(eggs, "Eggs"), (milk, "Milk")] {
            for distance in [CGFloat(2), element.frame.height - 2] {
                element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0))
                    .withOffset(CGVector(dx: 0, dy: distance)).tap()
                expectItem(title, in: app)
                app.buttons["Done"].tap()
            }
        }
        XCTAssertEqual(eggs.label, originals[0])
        XCTAssertEqual(milk.label, originals[1])
    }

    func testFullSizedRowSwipeMutatesAndUndoRestoresIt() {
        let app = launchOnFridge(largeType: true)
        let eggs = fixture("Eggs", in: app)
        let before = eggs.label
        XCTAssertGreaterThanOrEqual(eggs.frame.height, 44)
        eggs.press(forDuration: 0.6)
        wait(NSPredicate(format: "label BEGINSWITH[c] %@", "pinned, Eggs"), on: eggs)
        XCTAssertFalse(eggs.label.contains("low"), "A pin hold must not also toggle stock")
        app.buttons["Undo"].tap()
        wait(NSPredicate(format: "label == %@", before), on: eggs)
        let start = eggs.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 120, dy: 0)))
        let receipt = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@",
                                                           "used up. On To get.")).firstMatch
        XCTAssertTrue(receipt.waitForExistence(timeout: 5), "The engine confirmed the used-up mutation")
        wait(NSPredicate(format: "exists == false"), on: eggs)
        XCTAssertTrue(app.buttons["Undo"].waitForExistence(timeout: 5))
        app.buttons["Undo"].tap()
        XCTAssertTrue(eggs.waitForExistence(timeout: 5))
        XCTAssertEqual(eggs.label, before)
    }

    func testFocusedRecipeTapOpensItsRecipePage() {
        prepareMotion()
        let app = XCUIApplication()
        app.launchArguments = ["-demoTime", "18:10", "-openLink", "recipes", "-review.sampleData", "On",
                               "-featureFlags.off", "homeMosaic;homeV2"]
        app.launch()
        let dial = app.descendants(matching: .any)["Place"]
        XCTAssertTrue(dial.waitForExistence(timeout: 30))
        // Ready now wraps back to All, so the fixture always has the full recipe book available.
        turn(dial, down: true)
        wait(NSPredicate(format: "value BEGINSWITH %@", "All"), on: dial)
        let recipe = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND identifier != %@",
                                                      "kitchen.wheel.", "kitchen.wheel.new")).firstMatch
        XCTAssertTrue(recipe.waitForExistence(timeout: 8))
        recipe.tap()
        XCTAssertTrue(app.buttons["Recipes"].waitForExistence(timeout: 8), "The recipe page opened")
    }

    func testGutterAndColumnClipDoNotSelectOrMutateRows() {
        let app = launchOnFridge()
        let rows = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "pantry.row."))
            .allElementsBoundByIndex.filter(\.isHittable)
        XCTAssertFalse(rows.isEmpty)
        let original = Dictionary(uniqueKeysWithValues: rows.map { ($0.identifier, $0.label) })
        var columns: Set<Int> = []
        for element in rows where columns.insert(Int(element.frame.minX.rounded())).inserted {
            let frame = element.frame
            for x in [frame.minX - 2, frame.maxX + 2] where app.frame.minX < x && x < app.frame.maxX {
                let point = app.coordinate(withNormalizedOffset: .zero)
                    .withOffset(CGVector(dx: x, dy: frame.midY))
                point.tap()
                XCTAssertFalse(app.staticTexts["pantry.itemTitle"].exists, "The clip exterior is not a row")
            }
        }
        let gutter = app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: app.frame.midX, dy: rows[0].frame.midY))
        gutter.press(forDuration: 0.05, thenDragTo: gutter.withOffset(CGVector(dx: 100, dy: 0)))
        XCTAssertFalse(app.staticTexts["pantry.itemTitle"].exists)
        XCTAssertEqual(Dictionary(uniqueKeysWithValues: rows.map { ($0.identifier, $0.label) }), original)
    }

    func testNotNowAndToGetGotItBothUndoTheirMutation() {
        let app = launchOnFridge()
        let eggs = fixture("Eggs", in: app)
        let before = eggs.label
        eggs.tap()
        expectItem("Eggs", in: app)
        app.buttons["pantry.action.notNow"].tap()
        let notNow = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "not now.")).firstMatch
        XCTAssertTrue(notNow.waitForExistence(timeout: 5))
        wait(NSPredicate(format: "exists == false"), on: eggs)
        app.buttons["Undo"].tap()
        XCTAssertTrue(eggs.waitForExistence(timeout: 5))
        XCTAssertEqual(eggs.label, before)
        eggs.tap()
        expectItem("Eggs", in: app)
        app.buttons["pantry.action.usedUp"].tap()
        let used = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "used up.")).firstMatch
        XCTAssertTrue(used.waitForExistence(timeout: 5))
        wait(NSPredicate(format: "exists == false"), on: eggs)
        let toGet = app.buttons.matching(NSPredicate(format: "label MATCHES[c] %@", "([0-9]+|Nothing) to get"))
            .firstMatch
        toGet.tap()
        let dial = app.descendants(matching: .any)["Place"]
        wait(NSPredicate(format: "value BEGINSWITH %@", "To get"), on: dial)
        let shopping = fixture("Eggs", in: app)
        let shoppingBefore = shopping.label
        shopping.tap()
        expectItem("Eggs", in: app)
        XCTAssertEqual(app.buttons["pantry.action.usedUp"].label, "Got it")
        app.buttons["pantry.action.usedUp"].tap()
        let got = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "got it.")).firstMatch
        XCTAssertTrue(got.waitForExistence(timeout: 5))
        wait(NSPredicate(format: "exists == false"), on: shopping)
        app.buttons["Undo"].tap()
        XCTAssertTrue(shopping.waitForExistence(timeout: 5))
        XCTAssertEqual(shopping.label, shoppingBefore)
    }

    func testZPaperAndBlackNormalSizeScreenshots() {
        for theme in ["Plein", "Black"] {
            let app = launchOnFridge(theme: theme)
            XCTAssertTrue(fixture("Eggs", in: app).isHittable)
            let image = XCTAttachment(screenshot: app.screenshot())
            image.name = "Pantry \(theme == "Plein" ? "Paper-Plein" : theme) normal size Reduce Motion"
            image.lifetime = .keepAlways
            add(image)
            app.terminate()
        }
    }
}
