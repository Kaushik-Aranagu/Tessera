import Foundation
@testable import Tessera
import Testing

/// The event contract (docs/design/motion/tess-motion.md §14): each event maps to its state, the precedence holds
/// pairwise, and no view sets her mode.
@MainActor
struct SoulRouterTests {
    private func router(hour: Int = 12) -> SoulRouter {
        var calendar = Calendar.current
        calendar.timeZone = .current
        let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: .now) ?? .now
        return SoulRouter(clock: { date })
    }

    @Test func eventsMapToTheirStates() {
        let soul = router()
        soul.handle(.tessOpened)
        #expect(soul.mode == .listening && soul.isSurfaceOpen)
        soul.handle(.draft(isEmpty: true))
        #expect(soul.mode == .idle)
        soul.handle(.draft(isEmpty: false))
        #expect(soul.mode == .listening)
        soul.handle(.sent)
        #expect(soul.mode == .thinking)
        soul.handle(.dryCancelled)
        #expect(soul.mode == .listening)
        soul.handle(.committed)
        #expect(soul.mode == .idle && soul.isBright && !soul.isSurfaceOpen)
        soul.handle(.claudeDone)
        #expect(soul.mode == .done && soul.doneCount == 1)
    }

    @Test func atNightRestIsResting() {
        let soul = router(hour: 23)
        soul.handle(.appeared)
        #expect(soul.mode == .resting)
        soul.handle(.committed)
        #expect(soul.mode == .resting)
    }

    @Test func hisTouchCutsDone() {
        let soul = router()
        soul.handle(.setLogged)
        #expect(soul.mode == .done)
        soul.handle(.speak(hold: true))
        #expect(soul.mode == .listening)
    }

    @Test func aDraftNeverInterruptsThinking() {
        let soul = router()
        soul.handle(.sent)
        soul.handle(.draft(isEmpty: true))
        #expect(soul.mode == .thinking)
    }

    @Test func doneReturnsToRestAfterItsOneShot() async throws {
        let soul = router()
        soul.handle(.setLogged)
        try await Task.sleep(for: .seconds(2.0))
        #expect(soul.mode == .idle)
    }

    @Test func aNewBestThinksThenPlaysDone() async throws {
        let soul = SoulRouter(page: .live)
        soul.handle(.newBest)
        #expect(soul.mode == .thinking)
        try await Task.sleep(for: .seconds(1.4))
        #expect(soul.mode == .done)
    }

    @Test func anAskInsideDoneWaitsForItToEnd() async throws {
        let soul = router()
        soul.handle(.claudeDone)
        soul.handle(.askClaude)
        #expect(soul.mode == .done)
        try await Task.sleep(for: .seconds(2.0))
        #expect(soul.mode == .thinking)
    }

    @Test func theLensPinsHerAndChangesNothingElse() {
        let soul = router()
        soul.handle(.sent)
        soul.handle(.lensHeld)
        #expect(soul.isPinned && soul.mode == .thinking)
        soul.handle(.lensReleased)
        #expect(!soul.isPinned && soul.mode == .thinking)
    }

    /// The one-wire gate: no view sets her mode (`tessMode =` only inside the router).
    @Test func noViewSetsHerMode() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        var offenders: [String] = []
        for folder in ["App", "Features", "DesignSystem"] {
            let enumerator = FileManager.default.enumerator(at: root.appendingPathComponent(folder),
                                                            includingPropertiesForKeys: nil)
            while let url = enumerator?.nextObject() as? URL {
                guard url.pathExtension == "swift", url.lastPathComponent != "SoulRouter.swift" else { continue }
                let text = try String(contentsOf: url, encoding: .utf8)
                if text.range(of: #"tessMode\s*="#, options: .regularExpression) != nil {
                    offenders.append(url.lastPathComponent)
                }
            }
        }
        #expect(offenders.isEmpty, "\(offenders)")
    }
}
