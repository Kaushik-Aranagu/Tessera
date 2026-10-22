import XCTest

/// Kitchen build sheet G1, G3, G4, G5 (Oct 22): every Kitchen page's title starts on the 22 pt gutter, and Close ends
/// 22 pt from the right edge. Sample data on, so every page has something on it.
@MainActor
final class KitchenGutterUITests: SimulatorOnlyTestCase {
    private func open(_ link: String, title: String,
                      extra: [String] = []) -> (title: CGRect, close: CGRect, width: CGFloat)
    {
        let app = XCUIApplication()
        app.launchArguments = ["-review.sampleData", "On", "-demoTime", "18:10", "-openLink", link] + extra
        app.launch()
        let ask = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Don’t Allow"]
        if ask.waitForExistence(timeout: 6) {
            ask.tap()
        }
        let close = app.buttons.matching(NSPredicate(format: "label ==[c] %@", "Close")).firstMatch
        XCTAssertTrue(close.waitForExistence(timeout: 30), "\(link) opened")
        sleep(2)
        let frame = app.staticTexts.matching(NSPredicate(format: "label == %@", title)).allElementsBoundByIndex
            .map(\.frame).filter { $0.minY > 60 }.min { $0.minY < $1.minY } ?? .zero
        return (frame, close.frame, app.windows.firstMatch.frame.width)
    }

    func testEveryKitchenTitleSitsOnTheGutter() {
        let pages = [("pantry", "Pantry"), ("recipes", "Recipes"), ("groceries", "Groceries"), ("lists", "Lists")]
        for (link, title) in pages {
            let measured = open(link, title: title)
            print("GUTTER \(link) titleX=\(measured.title.minX) closeRight=\(measured.width - measured.close.maxX)")
            XCTAssertEqual(measured.title.minX, 22, accuracy: 1.5, "\(title) title off the gutter")
            // Close's frame carries 8 pt of touch padding, so its word ends on the 22 pt gutter.
            XCTAssertEqual(measured.width - measured.close.maxX, 14, accuracy: 1.5, "\(title) Close off the gutter")
        }
    }
}
