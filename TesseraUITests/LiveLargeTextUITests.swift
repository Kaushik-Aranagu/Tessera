import XCTest

/// Large text (AX5): the live screen scrolls, and the weight dial takes a press first, then a drag turns it.
/// `-openWorkout` (simulator only, LaunchFlags) opens the first routine's workout. The other half, that a plain swipe
/// on the numeral leaves the weight alone, is checked by hand: XCUITest's synthesized drags always begin with a press,
/// so they cannot tell a swipe from a press-and-drag.
@MainActor
final class LiveLargeTextUITests: SimulatorOnlyTestCase {
    private func launch() -> (app: XCUIApplication, weight: XCUIElement) {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-demoTime", "18:10", "-resetDemo", "-openWorkout",
                               "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        let weight = app.descendants(matching: .any)["Weight"]
        XCTAssertTrue(weight.waitForExistence(timeout: 25), "The live screen's weight")
        return (app, weight)
    }

    func testPressingThenDraggingTurnsTheDial() {
        let (_, weight) = launch()
        let before = weight.value as? String
        let start = weight.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = weight.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: -0.4))
        start.press(forDuration: 0.5, thenDragTo: end)
        sleep(1)
        XCTAssertNotEqual(weight.value as? String, before, "Press then drag did not turn the dial")
    }
}
