import XCTest

/// Stills of the Deck's door pages and the Bench item page (sheet 284), in paper and black, at the default size and at
/// AX5. Runs only when `TEST_RUNNER_STILLS_DIR` names a folder (the PNGs go there); skipped otherwise, so the gate
/// never
/// pays for it. Simulator only.
@MainActor
final class DeckLevelsStillsUITests: SimulatorOnlyTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private var folder: String? {
        ProcessInfo.processInfo.environment["STILLS_DIR"]
    }

    private func still(_ app: XCUIApplication, _ name: String) {
        guard let folder else { return }
        sleep(2)
        let url = URL(fileURLWithPath: folder).appendingPathComponent("\(name).png")
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? app.screenshot().pngRepresentation.write(to: url)
    }

    private func walk(look: String, large: Bool) throws {
        try XCTSkipIf(folder == nil, "No STILLS_DIR")
        let app = XCUIApplication()
        var arguments = ["-shellRoom", "deck", "-shellProbe", "-demo", "-demoTime", "18:10", "-theme", look]
        if large {
            arguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launchArguments = arguments
        app.launch()
        let tag = "\(look)-\(large ? "ax5" : "default")"
        let door = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Today'")).firstMatch
        XCTAssertTrue(door.waitForExistence(timeout: 30))
        still(app, "\(tag)-0-landing")
        sleep(1)
        door.tap()
        let title = app.descendants(matching: .any)["shell.doorTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        for (index, name) in ["today", "week", "library", "bests", "plan"].enumerated() {
            still(app, "\(tag)-1-\(index)-\(name)")
            guard index < 4 else { break }
            title.swipeLeft()
            sleep(1)
        }
        // Back to Today, then its first row.
        for _ in 0 ..< 4 {
            title.swipeRight()
            sleep(1)
        }
        let row = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'shell.row.'"))
            .firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(app.descendants(matching: .any)["shell.itemTitle"].waitForExistence(timeout: 5))
        still(app, "\(tag)-2-item")
    }

    func testPaperDefault() throws {
        try walk(look: "white", large: false)
    }

    func testBlackDefault() throws {
        try walk(look: "black", large: false)
    }

    func testPaperAX5() throws {
        try walk(look: "white", large: true)
    }

    func testBlackAX5() throws {
        try walk(look: "black", large: true)
    }
}
