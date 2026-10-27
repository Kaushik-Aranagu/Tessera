import XCTest

/// Kaushik, Oct 26: "no text may overlap between two elements, and every element keeps inside its own boundary."
/// Launches Bridge and each landing at default size and at AX5, reads one accessibility snapshot (deterministic: no
/// element-by-element reads while things move), and checks every text-bearing element:
///   1. no two of them intersect (an element and its own container excepted),
///   2. each lies inside one place of sheet 283 v4 (`LandingPlace`, copied below) or, failing that, the screen.
/// Every violation is printed with the screen, size, both labels and frames, and a screenshot is attached on failure.
/// Bridge is this lane's and must be clean; the rooms' violations are recorded for their lanes (expected failures).
@MainActor
final class LandingBoundsUITests: SimulatorOnlyTestCase {
    /// Sheet 283 v4 places (Features/Landing/Kit/LandingPlaces.swift), in 402 x 874 design points.
    static let places: [(name: String, frame: CGRect)] = [
        ("status bar", CGRect(x: 0, y: 0, width: 402, height: 44)),
        ("masthead", CGRect(x: 0, y: 44, width: 402, height: 138)),
        ("keystone", CGRect(x: 0, y: 182, width: 402, height: 196)),
        ("caption", CGRect(x: 24, y: 378, width: 354, height: 34)),
        ("widget", CGRect(x: 24, y: 412, width: 354, height: 200)),
        ("doors", CGRect(x: 24, y: 640, width: 354, height: 120)),
        ("foot", CGRect(x: 0, y: 776, width: 402, height: 98)),
    ]

    /// The declared exception: Tess's corner and what she opens layer over the page by design.
    static let tessCorner = CGRect(x: 306, y: 776, width: 96, height: 96)
    static let layeredLabels: Set<String> = ["Tess", "Close"]

    static let ax5 = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]

    struct Element {
        let label: String
        let frame: CGRect
        let path: [Int]
    }

    struct Violation: CustomStringConvertible {
        let text: String
        var description: String {
            text
        }
    }

    // MARK: Screens

    func testBridgeBounds() throws {
        try check(screen: "Bridge", flags: [], owned: true)
    }

    func testRoomLandingBounds() throws {
        let rooms: [(String, [String])] = [
            ("Log", ["-notes", "-demoNotes"]),
            ("Galley", ["-kitchen"]),
            ("Purse", ["-money"]),
            ("Deck", ["-trainingLanding"]),
            ("Watch", ["-routinesLanding"]),
            ("Lookout", ["-weatherLanding"]),
            ("Settings", ["-settingsLanding"]),
        ]
        for (name, flags) in rooms {
            try check(screen: name, flags: flags, owned: false)
        }
    }

    func testShellRoomBounds() throws {
        for room in ["log", "deck", "settings", "watch", "lookout", "galley", "purse"] {
            try check(screen: "Shell \(room)", flags: ["-shellRoom", room], owned: false)
        }
    }

    // MARK: The check

    private func check(screen: String, flags: [String], owned: Bool) throws {
        for (size, extra) in [("default", [String]()), ("AX5", Self.ax5)] {
            let app = XCUIApplication()
            app.launchArguments = ["-review.sampleData", "On", "-review.landingPages", "On", "-demoTime", "18:10"]
                + flags + extra
            app.launch()
            let ask = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Don’t Allow"]
            if ask.waitForExistence(timeout: 4) {
                ask.tap()
            }
            _ = app.staticTexts.firstMatch.waitForExistence(timeout: 30)
            // Arrival, flips and the first board roll are all over well inside this.
            sleep(12)
            let violations = try Self.violations(in: app, screen: screen, size: size)
            for violation in violations {
                print("BOUNDS \(violation)")
            }
            if !violations.isEmpty {
                let shot = XCTAttachment(screenshot: app.screenshot())
                shot.name = "\(screen) \(size)"
                shot.lifetime = .keepAlways
                add(shot)
            }
            if owned {
                XCTAssertTrue(violations.isEmpty, "\(screen) \(size): \(violations.count) violations")
            } else if !violations.isEmpty {
                XCTExpectFailure("\(screen) belongs to another lane; its violations are listed for them", strict: false)
                XCTFail("\(screen) \(size): \(violations.count) violations")
            }
            app.terminate()
        }
    }

    /// One snapshot of the tree, every text-bearing element with its path, then the two rules.
    static func violations(in app: XCUIApplication, screen: String, size: String) throws -> [Violation] {
        let root = try app.snapshot()
        let screenFrame = root.frame
        let scale = screenFrame.height / 874
        var elements: [Element] = []
        func walk(_ node: XCUIElementSnapshot, path: [Int]) {
            let types: [XCUIElement.ElementType] = [.staticText, .button]
            if types.contains(node.elementType), !node.label.trimmingCharacters(in: .whitespaces).isEmpty,
               node.frame.width > 1, node.frame.height > 1, node.frame.intersects(screenFrame)
            {
                elements.append(Element(label: node.label, frame: node.frame, path: path))
            }
            for (index, child) in node.children.enumerated() {
                walk(child, path: path + [index])
            }
        }
        walk(root, path: [])
        let tess = Self.scaled(Self.tessCorner, scale)
        let shown = elements.filter { !Self.layeredLabels.contains($0.label) && !$0.frame.intersects(tess) }
        var out: [Violation] = []
        func isAncestor(_ a: [Int], of b: [Int]) -> Bool {
            a.count < b.count && Array(b.prefix(a.count)) == a
        }
        for i in shown.indices {
            for j in shown.indices where j > i {
                let a = shown[i], b = shown[j]
                if isAncestor(a.path, of: b.path) || isAncestor(b.path, of: a.path) {
                    continue
                }
                let overlap = a.frame.intersection(b.frame)
                if !overlap.isNull, overlap.width * overlap.height > 1 {
                    out
                        .append(
                            Violation(
                                text: "\(screen) [\(size)] overlap: \"\(a.label)\" \(a.frame) and \"\(b.label)\" \(b.frame)"
                            )
                        )
                }
            }
        }
        for element in shown {
            let inside = places
                .contains { Self.scaled($0.frame, scale).insetBy(dx: -1, dy: -1).contains(element.frame) }
            if !inside {
                let fits = screenFrame.contains(element.frame)
                out
                    .append(
                        Violation(
                            text: "\(screen) [\(size)] \(fits ? "crosses places" : "off screen"): \"\(element.label)\" \(element.frame)"
                        )
                    )
            }
        }
        return out
    }

    static func scaled(_ rect: CGRect, _ scale: CGFloat) -> CGRect {
        CGRect(x: rect.minX, y: rect.minY * scale, width: rect.width, height: rect.height * scale)
    }
}
