import XCTest

/// Sheet 283 v7, Layout mode (`-layoutMode`): across walks the rooms with every bubble kept, up merges into the door
/// page and down splits it, a tap reads a bubble, and the Nav word twice leaves. Simulator only.
@MainActor
final class LayoutModeUITests: SimulatorOnlyTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testWalkTheRoomsAndTheDoorPage() {
        let app = XCUIApplication()
        app.launchArguments = ["-layoutMode", "-demoTime", "18:10"]
        app.launch()
        let title = app.descendants(matching: .any)["layout.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 30))
        XCTAssertTrue(title.label.hasPrefix("Settings word"), title.label)
        let keystone = app.descendants(matching: .any)["layout.keystone"]

        app.swipeLeft()
        XCTAssertTrue(
            app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Log,'")).firstMatch
                .waitForExistence(timeout: 3),
            "Across goes to Log"
        )
        XCTAssertTrue(keystone.exists, "The keystone bubble stays")

        app.swipeUp()
        let page = app.descendants(matching: .any)["layout.page"]
        XCTAssertTrue(page.waitForExistence(timeout: 3), "Up merges into the Page")
        XCTAssertTrue(app.descendants(matching: .any)["layout.doorTitle"].exists)

        app.swipeLeft()
        XCTAssertTrue(
            app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Lookout,'")).firstMatch
                .waitForExistence(timeout: 3),
            "Across keeps the door level"
        )
        XCTAssertTrue(page.exists)

        app.swipeDown()
        XCTAssertTrue(page.waitForNonExistence(timeout: 3), "Down splits the Page")
        XCTAssertTrue(app.descendants(matching: .any)["layout.dial"].exists)

        app.descendants(matching: .any)["layout.widget"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["layout.panel"].waitForExistence(timeout: 3), "A tap reads it")

        let nav = app.descendants(matching: .any)["layout.navWord"]
        nav.tap()
        nav.tap()
        XCTAssertTrue(title.waitForNonExistence(timeout: 5), "The Nav word twice leaves")
    }
}
