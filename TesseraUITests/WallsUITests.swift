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
        let mustNotShow: [String]?
        let seed: Seed?
    }

    /// `seed`: a string for objectPage rows (section 11), an object for the body-number rows (section 12).
    enum Seed: Decodable {
        case named(String)
        case weight(Double?)

        private enum Keys: String, CodingKey { case lastWeightKg }

        init(from decoder: Decoder) throws {
            if let name = try? decoder.singleValueContainer().decode(String.self) {
                self = .named(name)
            } else {
                let keys = try decoder.container(keyedBy: Keys.self)
                self = try .weight(keys.decodeIfPresent(Double.self, forKey: .lastWeightKg))
            }
        }
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

    /// `TEST_RUNNER_WALLS_ONLY=A08,A17` runs just those rows (for chasing one row; never set in a gate run).
    static func rows(_ surface: String) throws -> [WallRow] {
        let only = ProcessInfo.processInfo.environment["WALLS_ONLY"]
            .map { Set($0.split(separator: ",").map(String.init)) }
        return try allRows().filter { row in row.surface == surface && only.map { $0.contains(row.id) } ?? true }
    }

    static func allRows() throws -> [WallRow] {
        let bundle = Bundle(for: WallsUITests.self)
        let url = try XCTUnwrap(bundle.url(forResource: "walls-ui-phrases", withExtension: "json"))
        return try JSONDecoder().decode(WallFixture.self, from: Data(contentsOf: url)).rows
    }

    /// The launch flags a row's seed needs: his last weight, "none" for no weight logged, nothing with no seed.
    static func seedFlags(_ row: WallRow) -> [String] {
        guard case let .weight(kg) = row.seed else { return [] }
        return ["-wallsSeedPrivate", kg.map { String($0) } ?? "none"]
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

    private func assertLine(_ row: WallRow, in app: XCUIApplication, tessLine: Bool = false) {
        guard let line = row.expectLine else { return }
        // On the Ask bar, only Tess's own line counts: Home rows ("Private note") can hold the same words.
        let texts = tessLine ? app.staticTexts.matching(identifier: "tess.line") : app.staticTexts
        let found = row.lineMatch == "prefix"
            ? texts.matching(NSPredicate(format: "label BEGINSWITH %@", line)).firstMatch
            : texts.matching(NSPredicate(format: "label == %@", line)).firstMatch
        let shown = app.staticTexts.matching(identifier: "tess.line").firstMatch
        XCTAssertTrue(
            found.waitForExistence(timeout: 6),
            "\(row.id): the line reads \(line) (Tess's line: \(shown.exists ? shown.label : "none"))"
        )
        if !found.exists, let word = line.split(separator: " ").first {
            // Where the words are instead, by identifier and label, for Research.
            let elsewhere = app.descendants(matching: .any).matching(NSPredicate(
                format: "label CONTAINS[c] %@",
                String(word)
            ))
            .allElementsBoundByIndex.prefix(4).map { "[\($0.identifier)] \($0.label)" }
            XCTContext.runActivity(named: "\(row.id) shown: \(elsewhere.joined(separator: " | "))") { _ in }
        }
    }

    private func assertNoValue(_ row: WallRow, in app: XCUIApplication, also: [String] = []) {
        for value in also + Self.fakeValues + [String(repeating: "x", count: 8)] {
            XCTAssertFalse(shows(value, in: app), "\(row.id): \(value) shows on screen (Home leak)")
        }
    }

    /// How many elements in the whole tree hold the text (case-insensitive).
    private func count(_ text: String, in app: XCUIApplication) -> Int {
        app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS[c] %@", text)).count
    }

    /// The whole tree, any element whose label holds the text (case-insensitive).
    private func shows(_ text: String, in app: XCUIApplication) -> Bool {
        app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS[c] %@", text)).firstMatch.exists
    }

    /// Any line the fixture expects, still on screen: a check run now could pass on an earlier row's line.
    private func staleLine(in app: XCUIApplication, lines: [String]) -> String? {
        lines.first { line in
            !app.staticTexts.matching(identifier: "tess.line")
                .matching(NSPredicate(format: "label BEGINSWITH %@", line)).firstMatch
                .waitForNonExistence(timeout: 8)
        }
    }

    /// Closes the Ask, if it's still open, so Home shows.
    private func closeAsk(_ app: XCUIApplication) {
        guard app.textFields.firstMatch.exists else { return }
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.03)).tap()
        _ = app.textFields.firstMatch.waitForNonExistence(timeout: 3)
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

    /// Ask bar rows, one launch per seed group (his last weight, none logged, no seed), in the fixture's order.
    func testAskBarWalls() throws {
        let rows = try Self.rows("askBar")
        let lines = try Array(Set(Self.allRows().compactMap(\.expectLine))).sorted()
        var groups: [[String]: [WallRow]] = [:]
        var order: [[String]] = []
        for row in rows {
            let flags = Self.seedFlags(row)
            if groups[flags] == nil {
                order.append(flags)
            }
            groups[flags, default: []].append(row)
        }
        var spyMoved = false
        var app: XCUIApplication?
        for flags in order {
            app?.terminate()
            let launched = launch(flags)
            app = launched
            spyMoved = askRows(groups[flags] ?? [], lines: lines, in: launched) || spyMoved
        }
        // The spy's own check: plain phrases nothing on the phone reads reach Claude, or the seam isn't wired.
        XCTAssertTrue(spyMoved, "spy not wired")
        // The leak search's own check: an ordinary task holding a number must be found on Home.
        if let app {
            closeAsk(app)
            type("buy milk 82.4", in: app)
            sleep(3)
            closeAsk(app)
            XCTAssertTrue(shows("82.4", in: app), "leak search is blind")
        }
    }

    /// Types each row on the Ask bar; whether any reached the spy.
    private func askRows(_ rows: [WallRow], lines: [String], in app: XCUIApplication) -> Bool {
        XCTAssertTrue(app.buttons["Tess"].waitForExistence(timeout: 15))
        sleep(2)
        var spyMoved = false
        for row in rows {
            closeAsk(app)
            if let stale = staleLine(in: app, lines: lines) {
                check(row) { XCTFail("\(row.id): stale line, row cannot be trusted (\(stale))") }
                continue
            }
            let before = probe(app)
            // An earlier row may already have put the number on Home (a pending row's task): count, don't look.
            let shownBefore = (row.mustNotShow ?? []).map { count($0, in: app) }
            type(text(for: row), in: app, paste: row.build == "KEY")
            check(row) {
                assertLine(row, in: app, tessLine: true)
                sleep(3)
                closeAsk(app)
                let privateRow = row.expectPrivate || row.build == "KEY" || ["A06", "A07", "A20", "A21"]
                    .contains(row.id)
                if privateRow {
                    assertNoValue(row, in: app)
                }
                for (value, was) in zip(row.mustNotShow ?? [], shownBefore) {
                    XCTAssertEqual(count(value, in: app), was, "\(row.id): \(value) shows on screen (Home leak)")
                }
                assertCounts(row, before: before, in: app)
            }
            if probe(app).claude > before.claude {
                spyMoved = true
            }
            sleep(1)
        }
        return spyMoved
    }

    /// Opens Write from the soul and enters the text (pasted for key rows), then Return.
    private func type(_ text: String, in app: XCUIApplication, paste pasted: Bool = false) {
        app.buttons["Tess"].tap()
        let write = app.descendants(matching: .any).matching(NSPredicate(format: "label ==[c] %@", "Write"))
            .firstMatch
        XCTAssertTrue(write.waitForExistence(timeout: 5))
        write.tap()
        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        if pasted {
            paste(text, into: field, app: app)
        } else {
            field.typeText(text)
            app.typeText("\n")
        }
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
