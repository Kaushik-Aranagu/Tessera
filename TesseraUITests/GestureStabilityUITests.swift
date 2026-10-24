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
        launchApp(["-review.sampleData", "On", "-demoTime", "18:10", "-openLink", link])
    }

    /// Launches with `arguments` and turns away the system permission ask if it appears.
    private func launchApp(_ arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = arguments
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

    /// A real swipe still commits: a Done swipe on the Tasks lead finishes it and Tess offers UNDO. The policy only
    /// ever makes swipes steadier, never dead.
    func testATasksDoneSwipeStillCommitsAndOffersUndo() {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-demoTime", "18:10", "-resetDemo",
                               "-review.tasksApp", "On", "-review.landingPages", "On"]
        app.launch()
        let apps = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Tasks"))
        XCTAssertTrue(apps.firstMatch.waitForExistence(timeout: 20), "the apps list has Tasks")
        let doIt = app.buttons.matching(NSPredicate(format: "label ==[c] %@", "Do it")).firstMatch
        // The first tap brings Tasks to the middle of the list; the next opens it.
        for _ in 0 ..< 3 where !doIt.exists {
            apps.firstMatch.tap()
            _ = doIt.waitForExistence(timeout: 4)
        }
        XCTAssertTrue(doIt.exists, "the Tasks landing opened")
        // The lead is the large row above Do it; swipe it right, slowly and well past the arm distance.
        let lead = app.buttons.allElementsBoundByIndex.first {
            $0.frame.minY > 120 && $0.frame.maxY < doIt.frame.minY && $0.frame.width > 250 && $0.frame.height > 40
        }
        XCTAssertNotNil(lead, "the lead row is on the landing")
        guard let lead else { return }
        let grab = lead.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.5))
        grab.press(forDuration: 0.05, thenDragTo: grab.withOffset(CGVector(dx: 220, dy: 0)),
                   withVelocity: .slow, thenHoldForDuration: 0.1)
        XCTAssertTrue(app.buttons["UNDO"].waitForExistence(timeout: 6), "a Done swipe commits and offers UNDO")
    }

    /// Kaushik, Oct 23: swiping across the Home mosaic moved the one-thing list. Each region owns its touches: a swipe
    /// that starts on the mosaic leans it and turns nothing; only a swipe on the one-thing space turns the things.
    func testASwipeAcrossTheMosaicDoesNotMoveTheOneThing() {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-demoTime", "18:10", "-resetDemo", "-review.homeMosaic", "On",
                               "-review.homeMosaicMoods", "On", "-review.homeAppsList", "On"]
        app.launch()
        let one = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", "One thing at a time")).firstMatch
        XCTAssertTrue(one.waitForExistence(timeout: 20), "Home has the one-thing space")
        sleep(2)
        // The space's accessibility value is the current thing ("1 of 3, ...").
        func current() -> String {
            one.value as? String ?? ""
        }
        let before = current()
        // The mosaic sits above the one-thing space, 16 pt clear of it and 160 pt tall, on the right of the page.
        let y = one.frame.minY - 80
        let width = app.frame.width
        for _ in 0 ..< 3 {
            let from = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: width * 0.92, dy: y))
            from.press(forDuration: 0.05, thenDragTo: from.withOffset(CGVector(dx: -width * 0.45, dy: 0)),
                       withVelocity: .default, thenHoldForDuration: 0)
            sleep(1)
            // The return swipe starts at 0.55 of the width, still on the mosaic (it spans about 0.32 to 0.94).
            let back = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: width * 0.55, dy: y))
            back.press(forDuration: 0.05, thenDragTo: back.withOffset(CGVector(dx: width * 0.35, dy: 0)),
                       withVelocity: .default, thenHoldForDuration: 0)
            sleep(1)
        }
        XCTAssertFalse(before.isEmpty, "the one-thing space reports its current thing")
        XCTAssertEqual(current(), before, "a swipe across the mosaic must not turn the one thing")
    }
}
