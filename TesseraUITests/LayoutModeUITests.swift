import XCTest

/// Design 283 v8: Layout mode's panes take a plain tap (their card opens), across and depth swipes still work over the
/// panes, and a tap outside closes the card. `-openLayoutMode` opens it at launch (simulator only).
@MainActor
final class LayoutModeUITests: SimulatorOnlyTestCase {
    private func openLayoutMode() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-demoTime", "18:10", "-openLayoutMode"]
        app.launch()
        XCTAssertTrue(app.buttons["layout.pane.keystone"].waitForExistence(timeout: 20), "Layout mode opened")
        sleep(1)
        return app
    }

    private func pane(_ app: XCUIApplication, _ slug: String) -> XCUIElement {
        app.buttons["layout.pane.\(slug)"]
    }

    func testTapOpensTheCardAndTapOutsideClosesIt() {
        let app = openLayoutMode()
        pane(app, "keystone").tap()
        let card = app.descendants(matching: .any)["layout.card"]
        XCTAssertTrue(card.waitForExistence(timeout: 3), "The card opens on a plain tap")
        // A tap on the left guide strip is outside every pane.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.5)).tap()
        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: card)
        XCTAssertEqual(XCTWaiter().wait(for: [gone], timeout: 3), .completed, "Tap outside closes the card")
    }

    func testAcrossWalksTheRoomsAndDepthMergesThePanes() {
        let app = openLayoutMode()
        XCTAssertTrue(pane(app, "settings-word").exists, "Bridge starts with the Settings word")
        let win = app.windows.firstMatch
        let right = win.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5))
        let left = win.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.5))
        right.press(forDuration: 0.05, thenDragTo: left)
        let title = pane(app, "title")
        XCTAssertTrue(
            title.waitForExistence(timeout: 5),
            "Across from Bridge: the Title pane takes the Settings word's place"
        )
        XCTAssertTrue(title.label.contains("Log"), "The first room is Log: \(title.label)")

        let low = win.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75))
        let high = win.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25))
        sleep(2)
        low.press(forDuration: 0.05, thenDragTo: high)
        XCTAssertTrue(pane(app, "page").waitForExistence(timeout: 5), "Up: the door page's Page pane")
        XCTAssertTrue(pane(app, "door-title").exists, "Up: the Door title pane")
        sleep(2)
        high.press(forDuration: 0.05, thenDragTo: low)
        XCTAssertTrue(pane(app, "widget").waitForExistence(timeout: 5), "Down: the Widget pane is back")
    }
}
