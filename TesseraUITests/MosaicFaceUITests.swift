import XCTest

/// Home 236 and QA rule G13: a plain tap on the mosaic's face reaches the face and opens its room, and a swipe on the
/// face (and only there) turns it. The faces turn by themselves in the app; these tests turn that off and pick the
/// faces by their Settings switches so the face on screen is the one the test expects (sample data, not -demo: the demo
/// run keeps Review picks in memory and would ignore these arguments). Simulator only.
@MainActor
final class MosaicFaceUITests: SimulatorOnlyTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launch(faces: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        var arguments = ["-review.sampleData", "On", "-demoTime", "18:10", "-review.homeMosaic", "On",
                         "-review.homeMosaicMoods", "On", "-review.homeFaceTurn", "Off"]
        for kind in ["now", "gallery", "weather", "workout"] where !faces.contains(kind) {
            arguments += ["-review.homeFace.\(kind)", "Off"]
        }
        app.launchArguments = arguments
        app.launch()
        return app
    }

    private func face(_ app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "mosaicFace").firstMatch
    }

    /// A plain tap on the gallery face reaches it and opens its room, Today.
    func testAPlainTapOnTheFaceOpensItsRoom() {
        let app = launch(faces: ["gallery"])
        let face = face(app)
        XCTAssertTrue(face.waitForExistence(timeout: 30), "The face is on Home")
        XCTAssertTrue(face.label.hasPrefix("Gallery"), "Only the gallery is in the stack")
        sleep(2)
        face.tap()
        let title = app.staticTexts["Today"]
        XCTAssertTrue(title.waitForExistence(timeout: 10), "A tap on the face opened Today")
    }

    /// A short slow wiggle on the face turns nothing and opens nothing.
    func testAWiggleOnTheFaceCommitsNothing() {
        let app = launch(faces: ["gallery", "weather"])
        let face = face(app)
        XCTAssertTrue(face.waitForExistence(timeout: 30))
        sleep(2)
        let from = face.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.5))
        from.press(forDuration: 0.05, thenDragTo: from.withOffset(CGVector(dx: -36, dy: 3)), withVelocity: .slow,
                   thenHoldForDuration: 0)
        sleep(1)
        XCTAssertTrue(face.label.hasPrefix("Gallery"), "A wiggle did not turn the face")
        XCTAssertFalse(app.staticTexts["Today"].exists, "A wiggle did not open the room")
    }

    /// A swipe left on the face past 35% of its width turns it to the next face; a swipe right turns it back.
    func testASwipeOnTheFaceTurnsIt() {
        let app = launch(faces: ["gallery", "weather"])
        let face = face(app)
        XCTAssertTrue(face.waitForExistence(timeout: 30))
        XCTAssertTrue(face.label.hasPrefix("Gallery"))
        sleep(2)
        let from = face.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
        from.press(forDuration: 0.05, thenDragTo: from.withOffset(CGVector(dx: -200, dy: 0)), withVelocity: .default,
                   thenHoldForDuration: 0)
        let weather = NSPredicate(format: "label BEGINSWITH %@", "Weather")
        expectation(for: weather, evaluatedWith: face)
        waitForExpectations(timeout: 10)
        sleep(1)
        let back = face.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.5))
        back.press(forDuration: 0.05, thenDragTo: back.withOffset(CGVector(dx: 200, dy: 0)), withVelocity: .default,
                   thenHoldForDuration: 0)
        let gallery = NSPredicate(format: "label BEGINSWITH %@", "Gallery")
        expectation(for: gallery, evaluatedWith: face)
        waitForExpectations(timeout: 10)
        XCTAssertFalse(app.staticTexts["Today"].exists, "A swipe never opens the room")
    }
}
