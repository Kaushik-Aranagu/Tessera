import Foundation
@testable import Tessera
import Testing

/// Her eyes (docs/design/motion/tess-motion.md §1).
@MainActor
struct SoulEyesTests {
    /// A blink every 3 to 8 s, about one in five a double, lids down to 0.25 and back in 160 ms.
    @Test func blinkCadenceStaysInRange() {
        let starts = SoulBlink.starts(from: 0, to: 600)
        // Group a double's two closings (250 ms apart) into one event.
        var events: [Double] = []
        var doubles = 0
        for start in starts {
            if let last = events.last, start - last < 0.6 {
                doubles += 1
                continue
            }
            events.append(start)
        }
        let gaps = zip(events.dropFirst(), events).map { $0 - $1 }
        #expect(events.count > 60)
        #expect(gaps.allSatisfy { $0 >= 2.9 && $0 <= 8.7 }, "\(gaps.filter { $0 < 2.9 || $0 > 8.7 })")
        let share = Double(doubles) / Double(events.count)
        #expect(share > 0.1 && share < 0.3, "\(share)")
        #expect(abs(SoulBlink.lid(at: 12.345) - SoulBlink.lid(at: 12.345)) < 0.0001)
        let lowest = stride(from: 0.0, to: 30, by: 0.005).map(SoulBlink.lid(at:)).min() ?? 1
        #expect(lowest >= 0.25 && lowest < 0.3)
    }

    @Test func sheLooksAtHimWhileListeningAndAtHerLineAfterSpeaking() async throws {
        let soul = SoulRouter()
        #expect(soul.gaze == .ahead)
        soul.handle(.tessOpened)
        #expect(soul.gaze == .atHim)
        soul.handle(.closed)
        soul.handle(.lineShown)
        #expect(soul.gaze == .atLine)
        try await Task.sleep(for: .seconds(1.2))
        #expect(soul.gaze == .ahead)
    }

    /// Up to 3 pt sideways and 2.2 pt up or down (soul scale 1).
    @Test func theGlanceStaysSmall() {
        for gaze in [SoulGaze.ahead, .atLine, .atHim] {
            #expect(abs(gaze.offset.width) <= 3 && abs(gaze.offset.height) <= 2.2)
        }
    }
}
