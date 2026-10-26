import XCTest

/// QA rule G13 and the gesture policy (docs/design/gesture-policy.md): in every room a plain tap still reaches its
/// button, and a twitch or a short slow wiggle commits nothing (no page turn, no row action, no Undo). Runs from the
/// TesseraUITests scheme, on the simulator only, like the other UI tests.
@MainActor
final class GestureStabilityUITests: SimulatorOnlyTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// The rooms Home opens by `-openLink`; each has a Close word and a title.
    private static let rooms: [(link: String, title: String)] = [
        ("pantry", "Pantry"), ("recipes", "Recipes"), ("groceries", "Groceries"), ("lists", "Lists"),
        ("notes", "Notes"), ("review", "The week"),
    ]

    private func launch(_ link: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-review.sampleData", "On", "-demoTime", "18:10", "-openLink", link]
        app.launch()
        let ask = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Don’t Allow"]
        if ask.waitForExistence(timeout: 6) {
            ask.tap()
        }
        return app
    }

    private func close(_ app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label ==[c] %@", "Close")).firstMatch
    }

    /// A drag of `dx` by `dy` points at a given speed, from the middle of the screen's content.
    private func wiggle(_ app: XCUIApplication, dx: CGFloat, dy: CGFloat, velocity: XCUIGestureVelocity = .slow) {
        let from = app.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.55))
        from.press(forDuration: 0.05, thenDragTo: from.withOffset(CGVector(dx: dx, dy: dy)),
                   withVelocity: velocity, thenHoldForDuration: 0)
    }

    /// A short slow sideways wiggle (the kind a thumb makes while it scrolls or taps) changes nothing in any room.
    func testAShortSidewaysWiggleCommitsNothingInAnyRoom() {
        for room in Self.rooms {
            let app = launch(room.link)
            XCTAssertTrue(close(app).waitForExistence(timeout: 30), "\(room.link) opened")
            sleep(2)
            wiggle(app, dx: -36, dy: 4)
            wiggle(app, dx: 36, dy: -4)
            sleep(1)
            XCTAssertTrue(close(app).exists, "\(room.link) still open after a wiggle")
            XCTAssertFalse(app.buttons["UNDO"].exists, "a wiggle in \(room.link) committed something")
            app.terminate()
        }
    }

    /// A plain tap reaches the button in every room: Close closes it.
    func testAPlainTapReachesItsButtonInEveryRoom() {
        for room in Self.rooms {
            let app = launch(room.link)
            let close = close(app)
            XCTAssertTrue(close.waitForExistence(timeout: 30), "\(room.link) opened")
            sleep(2)
            // Scroll a little first: a tap right after a scroll must still count once the scroll has settled.
            wiggle(app, dx: 0, dy: -120, velocity: .default)
            sleep(1)
            close.tap()
            let gone = NSPredicate(format: "exists == false")
            expectation(for: gone, evaluatedWith: close)
            waitForExpectations(timeout: 10)
            app.terminate()
        }
    }

    /// A diagonal drag is a scroll, not a swipe: it never turns a Review tab or opens anything.
    func testADiagonalDragIsAScrollNotASwipe() {
        let app = launch("review")
        XCTAssertTrue(close(app).waitForExistence(timeout: 30), "Review opened")
        sleep(2)
        wiggle(app, dx: -80, dy: -70)
        sleep(1)
        XCTAssertTrue(close(app).exists, "Review is still open")
        XCTAssertFalse(app.buttons["UNDO"].exists, "a diagonal drag committed something")
    }
}
