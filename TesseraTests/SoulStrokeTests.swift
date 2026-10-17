import Foundation
@testable import Tessera
import Testing

/// Stroke her (docs/design/motion/tess-picks.md idea 3).
@MainActor
struct SoulStrokeTests {
    /// Her dock on the sheet's 393 × 852 frame.
    private let centre = CGPoint(x: 346, y: 779)

    private func pan(_ points: [CGPoint], over seconds: Double) -> (steps: [SoulStrokeTracker.Step], isStroke: Bool) {
        var tracker = SoulStrokeTracker()
        tracker.began(at: points[0], time: 0, centre: centre)
        var steps: [SoulStrokeTracker.Step] = []
        for (index, point) in points.enumerated().dropFirst() {
            let time = seconds * Double(index) / Double(points.count - 1)
            if let step = tracker.moved(to: point, time: time, centre: centre) {
                steps.append(step)
            }
        }
        return (steps, tracker.ended(at: points[points.count - 1], time: seconds, centre: centre))
    }

    private func line(from start: CGFloat, to end: CGFloat, y: CGFloat = 779) -> [CGPoint] {
        (0 ... 20).map { CGPoint(x: start + (end - start) * CGFloat($0) / 20, y: y) }
    }

    @Test func aPanAcrossHerIsAStrokeWithOneEntry() {
        let result = pan(line(from: 280, to: 392), over: 0.35)
        #expect(result.isStroke)
        #expect(result.steps.filter { $0 == .entered }.count == 1)
    }

    @Test func aPanStartingOnHerIsNeverAStroke() {
        let result = pan(line(from: 350, to: 260), over: 0.3)
        #expect(!result.isStroke && result.steps.isEmpty)
    }

    /// The recipe page's peek starts above 736; a band pan that crosses her is hers, either way.
    @Test func aBandPanRightToLeftIsAStrokeAndAPanAboveTheBandIsNot() {
        #expect(pan(line(from: 392, to: 270), over: 0.4).isStroke)
        #expect(!pan(line(from: 392, to: 270, y: 720), over: 0.4).isStroke)
    }

    @Test func tooSlowOrNotThroughIsNotAStroke() {
        #expect(!pan(line(from: 280, to: 392), over: 0.9).isStroke)
        #expect(!pan(line(from: 280, to: 340), over: 0.3).isStroke)
    }

    @Test func oneTickPerRippleAndRefusedWhileSheWorks() {
        let soul = SoulRouter()
        soul.handle(.strokeEntered)
        #expect(soul.strokeTicks == 1 && soul.stroke != nil && soul.gaze == .alongStroke)
        soul.handle(.strokeEnded(isStroke: true))
        #expect(soul.strokeBlink != nil && soul.gaze == .ahead)
        // A second stroke within the ripple restarts it with no second tick.
        soul.handle(.strokeEntered)
        #expect(soul.strokeTicks == 1)
        let working = SoulRouter()
        working.handle(.askClaude)
        working.handle(.strokeEntered)
        #expect(working.strokeTicks == 0 && working.stroke == nil)
    }

    @Test func theRippleDiesAwayInItsSecondAndAHalf() {
        let frame = SoulFrame.sample(.idle, time: 3, elapsed: 0)
        let early = SoulRipple.rippled(frame, elapsed: 0.1, scale: 0.45)
        let late = SoulRipple.rippled(frame, elapsed: 1.7, scale: 0.45)
        #expect(early != frame)
        #expect(late == frame)
    }
}
