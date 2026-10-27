import XCTest

/// Polish batch 1 stills: the one-thing card leaning with the finger and rolling on commit (sheets 294, 295), the
/// switcher word in its margin (298), and a look change with the old page leaving (299). Each test saves screenshots to
/// the folder in `POLISH_SHOTS` (default /tmp/tessera-polish) so a person can look at them; nothing is asserted about
/// pixels. Simulator only.
@MainActor
final class PolishOneUITests: SimulatorOnlyTestCase {
    private let folder = ProcessInfo.processInfo.environment["POLISH_SHOTS"] ?? "/tmp/tessera-polish"

    override func setUp() {
        continueAfterFailure = false
        try? FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
    }

    private func launch(_ extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-review.sampleData", "On", "-demoTime", "18:10", "-shellProbe"] + extra
        app.launch()
        let ask = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Don’t Allow"]
        if ask.waitForExistence(timeout: 4) {
            ask.tap()
        }
        _ = app.buttons["Settings"].firstMatch.waitForExistence(timeout: 60)
        sleep(4)
        return app
    }

    private func shot(_ name: String) {
        let data = XCUIScreen.main.screenshot().pngRepresentation
        try? data.write(to: URL(fileURLWithPath: "\(folder)/\(name).png"))
    }

    func testTheOneThingCardFollowsTheFingerAndRollsOnCommit() {
        _ = launch()
        // Held at 30 pt, then 70 pt left, 500 ms apart: the card leans a little with the finger.
        let hold = HeldTouch(moves: [
            (CGPoint(x: 330, y: 500), 0), (CGPoint(x: 300, y: 500), 0.15), (CGPoint(x: 260, y: 500), 0.3),
            (CGPoint(x: 260, y: 500), 1.6), (CGPoint(x: 120, y: 500), 1.8), (CGPoint(x: 100, y: 500), 1.9),
        ])
        let finish = hold.start(self)
        usleep(900_000)
        shot("follow-mid")
        usleep(1_000_000)
        // Past the commit: the lift happens at 1.9 s; take frames as fast as the screen allows.
        for index in 0 ..< 8 {
            shot("commit-\(index)")
        }
        finish()
        sleep(2)
        shot("after")
    }

    func testTheSwitcherWordOwnsItsMargin() {
        let app = launch(["-shellWalk", "log"])
        let probe = app.descendants(matching: .any)["shell.state"]
        let reached = NSPredicate(format: "label BEGINSWITH %@ AND label ENDSWITH 'changing no'", "route log/0")
        _ = XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: reached, object: probe)], timeout: 90)
        shot("switcher-rest")
        let hold = HeldTouch(moves: [
            (CGPoint(x: 120, y: 150), 0), (CGPoint(x: 90, y: 150), 0.2), (CGPoint(x: 30, y: 150), 0.4),
            (CGPoint(x: 30, y: 150), 2.4), (CGPoint(x: 20, y: 150), 2.5),
        ])
        let finish = hold.start(self)
        usleep(1_300_000)
        shot("switcher-dragged")
        finish()
        for index in 0 ..< 6 {
            shot("switcher-change-\(index)")
        }
        sleep(2)
        shot("switcher-after")
    }

    func testALookChangeLeavesTheOldPageGroundFirst() {
        let app = XCUIApplication()
        app.launchArguments = ["-review.sampleData", "On", "-demoTime", "18:10", "-lookFlip"]
        app.launch()
        // Obsidian is pinned 6 s after launch and Porcelain 8 s after that: frames all the way through.
        for index in 0 ..< 90 {
            shot(String(format: "look-%02d", index))
        }
    }
}
