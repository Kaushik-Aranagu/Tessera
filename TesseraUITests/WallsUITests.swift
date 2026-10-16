import XCTest

/// Product item AU: the walls, typed from docs/research/fixtures/walls-ui-phrases.json (every value made up), so no
/// person and no session ever types a secret-shaped phrase (docs/research/walls-ui-test-spec.md).
@MainActor
final class WallsUITests: SimulatorOnlyTestCase {
    struct WallRow: Decodable {
        let id: String
        let phrase: String?
        let build: String?
        let surface: String
        let expectPrivate: Bool
        let expectNoClaude: Bool
        let expectNotInMissLog: Bool
        let expectLine: String?
        let lineMatch: String?
        let pending: String?
    }

    struct WallFixture: Decodable {
        let rows: [WallRow]
    }

    /// The made-up values no screen may show once a row has dried.
    static let fakeValues = ["hunter2", "tacocat", "4417", "2100"]

    /// The app's own synthetic key (ClaudeSection.fakeKey), built here the same way: nothing key-shaped in a file.
    static var fakeKey: String {
        "sk-" + "ant-" + String(repeating: "x", count: 32)
    }

    override func setUp() {
        continueAfterFailure = true // one row's fail must not hide the rest
    }

    static func rows(_ surface: String) throws -> [WallRow] {
        let bundle = Bundle(for: WallsUITests.self)
        let url = try XCTUnwrap(bundle.url(forResource: "walls-ui-phrases", withExtension: "json"))
        return try JSONDecoder().decode(WallFixture.self, from: Data(contentsOf: url)).rows
            .filter { $0.surface == surface }
    }

    private func text(for row: WallRow) -> String {
        row.build == "KEY" ? Self.fakeKey : row.phrase ?? ""
    }

    private func launch(_ extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-demoTime", "18:10", "-resetDemo", "-wallsSpy"] + extra
        app.launch()
        return app
    }

    /// The probe's counts: Claude calls in the ledger, lines in the miss log.
    private func probe(_ app: XCUIApplication) -> (claude: Int, misses: Int) {
        let label = app.staticTexts["walls.probe"].label
        let numbers = label.split(separator: " ").compactMap { Int($0) }
        return (numbers.first ?? -1, numbers.count > 1 ? numbers[1] : -1)
    }

    /// Runs a row's checks, inside an expected failure while the row is pending.
    private func check(_ row: WallRow, _ body: () -> Void) {
        XCTContext.runActivity(named: "\(row.id) \(row.surface)") { _ in
            if let pending = row.pending {
                let options = XCTExpectedFailure.Options()
                options.isStrict = true
                XCTExpectFailure(pending, options: options, failingBlock: body)
            } else {
                body()
            }
        }
    }

    private func assertLine(_ row: WallRow, in app: XCUIApplication) {
        guard let line = row.expectLine else { return }
        let found = row.lineMatch == "prefix"
            ? app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", line)).firstMatch
            : app.staticTexts[line]
        XCTAssertTrue(found.waitForExistence(timeout: 6), "\(row.id): the line reads \(line)")
    }

    private func assertNoValue(_ row: WallRow, in app: XCUIApplication) {
        for value in Self.fakeValues + [String(repeating: "x", count: 8)] {
            let leak = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS[c] %@", value))
                .firstMatch
            XCTAssertFalse(leak.exists, "\(row.id): \(value) shows on screen")
        }
    }

    private func assertCounts(_ row: WallRow, before: (claude: Int, misses: Int), in app: XCUIApplication) {
        let after = probe(app)
        if row.expectNoClaude {
            XCTAssertEqual(after.claude, before.claude, "\(row.id): went to Claude")
        }
        if row.expectNotInMissLog {
            XCTAssertEqual(after.misses, before.misses, "\(row.id): reached the miss log")
        }
    }

    private func paste(_ value: String, into field: XCUIElement, app: XCUIApplication) {
        UIPasteboard.general.string = value
        field.tap()
        field.press(forDuration: 1.0)
        let paste = app.menuItems["Paste"]
        if paste.waitForExistence(timeout: 3) {
            paste.tap()
        }
        UIPasteboard.general.string = ""
    }

    // MARK: - Surfaces

    func testAskBarWalls() throws {
        let app = launch()
        let soul = app.buttons["Tess"]
        XCTAssertTrue(soul.waitForExistence(timeout: 15))
        sleep(2)
        var spyMoved = false
        for row in try Self.rows("askBar") {
            let before = probe(app)
            soul.tap()
            let write = app.descendants(matching: .any).matching(NSPredicate(format: "label ==[c] %@", "Write"))
                .firstMatch
            XCTAssertTrue(write.waitForExistence(timeout: 5))
            write.tap()
            let field = app.textFields.firstMatch
            XCTAssertTrue(field.waitForExistence(timeout: 5))
            if row.build == "KEY" {
                paste(text(for: row), into: field, app: app)
            } else {
                field.typeText(text(for: row))
                app.typeText("\n")
            }
            check(row) {
                assertLine(row, in: app)
                sleep(3)
                if row.expectPrivate || row.build == "KEY" || ["A06", "A07", "A20", "A21"].contains(row.id) {
                    assertNoValue(row, in: app)
                }
                assertCounts(row, before: before, in: app)
            }
            if probe(app).claude > before.claude {
                spyMoved = true
            }
            sleep(1)
        }
        // The spy's own check: plain phrases nothing on the phone reads reach Claude, or the seam isn't wired.
        XCTAssertTrue(spyMoved, "spy not wired")
    }

    func testNotesPageWalls() throws {
        let app = launch(["-openLink", "notes"])
        let line = app.textFields["New note"]
        XCTAssertTrue(line.waitForExistence(timeout: 15))
        let privateRows = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Private note"))
        for row in try Self.rows("notesPage") {
            let before = probe(app)
            let privateBefore = privateRows.count
            if row.build == "KEY" {
                paste(text(for: row), into: line, app: app)
            } else {
                line.tap()
                app.typeText(text(for: row))
                app.typeText("\n")
            }
            check(row) {
                assertLine(row, in: app)
                sleep(2)
                if row.expectPrivate {
                    // This row's own note: one more "Private note" row than before it.
                    XCTAssertEqual(privateRows.count, privateBefore + 1, "\(row.id): the note is private")
                }
                if row.expectPrivate || row.build == "KEY" {
                    assertNoValue(row, in: app)
                }
                assertCounts(row, before: before, in: app)
            }
        }
    }

    func testPasteWalls() throws {
        for row in try Self.rows("paste") {
            let app = launch(["-openLink", "pasteRecipe"])
            let field = app.textViews["Recipe text"]
            XCTAssertTrue(field.waitForExistence(timeout: 15))
            let before = probe(app)
            paste(text(for: row), into: field, app: app)
            sleep(2)
            check(row) {
                assertLine(row, in: app)
                let save = app.buttons["Save recipe"]
                if save.waitForExistence(timeout: 3) {
                    save.tap()
                    sleep(2)
                }
                assertCounts(row, before: before, in: app)
            }
            app.terminate()
        }
    }

    /// After the three surfaces wrote their rows: the Day log never shows a value.
    func testZDayLogShowsNoValue() {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-demoTime", "18:10", "-wallsSpy", "-homePage", "review"]
        app.launch()
        let today = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Friday")).firstMatch
        if today.waitForExistence(timeout: 15) {
            today.tap()
            sleep(2)
        }
        for value in Self.fakeValues {
            XCTAssertFalse(app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS[c] %@", value))
                .firstMatch.exists, "the Day log shows \(value)")
        }
    }
}
