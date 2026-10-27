import XCTest

/// The whole-blackboard workout mode (sheets 327 to 331): opened by holding Start on the Deck, plain taps reach the
/// controls, and no two slots overlap (the t67 check as a frame test), in paper and black and at the largest type.
@MainActor
final class WorkoutModeUITests: SimulatorOnlyTestCase {
    /// `direct` opens the first routine's workout at launch (`-openWorkout`, in pounds); otherwise the app opens on
    /// the Deck, for the hold on Start.
    private func launch(look: String = "Porcelain", type: String? = nil, direct: Bool = true) -> XCUIApplication {
        let app = XCUIApplication()
        var arguments = ["-demoTime", "18:10", "-workoutChalk", "-theme", look]
        arguments += direct ? ["-openWorkout", "-massUnit", "lb"] : ["-trainingLanding", "-demo", "-resetDemo"]
        if let type {
            arguments += ["-UIPreferredContentSizeCategoryName", type]
        }
        app.launchArguments = arguments
        app.launch()
        let ready = direct ? "mode.verb" : "Deck"
        XCTAssertTrue(app.descendants(matching: .any)[ready].firstMatch.waitForExistence(timeout: 30), "\(ready) is up")
        return app
    }

    /// Holding Start (500 ms) opens the mode.
    private func holdStart(_ app: XCUIApplication) {
        let foot = app.descendants(matching: .any).matching(
            NSPredicate(format: "label BEGINSWITH 'Start, ' OR label BEGINSWITH 'Pick up, '")
        ).firstMatch
        XCTAssertTrue(foot.waitForExistence(timeout: 10), "The foot carries Start")
        // Start needs the 500 ms hold; Pick up (a workout already under way) is a plain tap.
        if foot.label.hasPrefix("Start, ") {
            foot.press(forDuration: 0.9)
        } else {
            foot.tap()
        }
        XCTAssertTrue(app.descendants(matching: .any)["mode.verb"].waitForExistence(timeout: 10), "The mode opened")
    }

    private func element(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any)[id].firstMatch
    }

    /// Every named slot that exists must sit inside the screen and clear of every other.
    private func assertNoOverlap(_ app: XCUIApplication, _ ids: [String], file: StaticString = #filePath,
                                 line: UInt = #line)
    {
        let screen = app.windows.firstMatch.frame
        var frames: [(String, CGRect)] = []
        for id in ids {
            let found = element(app, id)
            guard found.exists else { continue }
            frames.append((id, found.frame))
        }
        XCTAssertGreaterThan(frames.count, 5, "Slots were found", file: file, line: line)
        for (id, frame) in frames {
            XCTAssertTrue(screen.insetBy(dx: -1, dy: -1).contains(frame), "\(id) \(frame) leaves the screen",
                          file: file, line: line)
        }
        for first in frames.indices {
            for second in frames.indices where second > first {
                let overlap = frames[first].1.intersection(frames[second].1)
                XCTAssertTrue(overlap.isNull || overlap.width < 1 || overlap.height < 1,
                              "\(frames[first].0) and \(frames[second].0) overlap at \(overlap)", file: file,
                              line: line)
            }
        }
    }

    private static let setSlots = [
        "mode.title", "mode.hold", "mode.clock", "mode.doneAbout", "mode.lift", "mode.weight", "mode.bar",
        "mode.platesLine", "mode.chips", "mode.lastTime", "mode.estimate", "mode.verb",
    ]
    private static let restSlots = [
        "mode.title", "mode.hold", "mode.clock", "mode.doneAbout", "mode.restTime", "mode.restNext", "mode.loadNext",
        "mode.howFelt", "mode.felt.easy", "mode.felt.right", "mode.felt.hard", "mode.verb",
    ]

    func testHoldStartOpensTheModeAndPlainTapsReachTheControls() {
        let app = launch(direct: false)
        holdStart(app)
        // A plain tap on the verb logs the set; the rest screen asks how it felt.
        element(app, "mode.verb").tap()
        XCTAssertTrue(element(app, "mode.howFelt").waitForExistence(timeout: 5), "The rest asks how it felt")
        element(app, "mode.felt.easy").tap()
        XCTAssertTrue(element(app, "mode.receipt").waitForExistence(timeout: 3), "Easy leaves a receipt")
        XCTAssertTrue(element(app, "mode.receipt").label.hasPrefix("Easy"), "The receipt names the word")
    }

    func testNoSlotOverlapsInPaperAndBlack() {
        for look in ["Porcelain", "Obsidian"] {
            let app = launch(look: look)
            assertNoOverlap(app, Self.setSlots)
            element(app, "mode.verb").tap()
            XCTAssertTrue(element(app, "mode.howFelt").waitForExistence(timeout: 5))
            assertNoOverlap(app, Self.restSlots)
            app.terminate()
        }
    }

    func testNoSlotOverlapsAtTheLargestType() {
        let app = launch(type: "UICTContentSizeCategoryAccessibilityXXXL")
        assertNoOverlap(app, Self.setSlots)
        element(app, "mode.verb").tap()
        XCTAssertTrue(element(app, "mode.howFelt").waitForExistence(timeout: 5))
        assertNoOverlap(app, Self.restSlots)
    }

    func testScreenshotsForReview() {
        for (look, type) in [
            ("Porcelain", nil),
            ("Obsidian", nil),
            ("Porcelain", "UICTContentSizeCategoryAccessibilityXXXL"),
        ] {
            let app = launch(look: look, type: type)
            attach(app, "set \(look) \(type ?? "default")")
            element(app, "mode.verb").tap()
            _ = element(app, "mode.howFelt").waitForExistence(timeout: 5)
            attach(app, "rest \(look) \(type ?? "default")")
            element(app, "mode.felt.easy").tap()
            attach(app, "felt \(look) \(type ?? "default")")
            app.terminate()
        }
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
