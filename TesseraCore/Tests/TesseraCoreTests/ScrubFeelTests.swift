@testable import TesseraCore
import Testing

/// docs/research/inplace-number.md, section 9: barbell on the starter kit, detents 2.5 kg apart, start 80 kg.
struct ScrubFeelTests {
    /// Starter-kit barbell detents, 20 to 177.5.
    private let detents = Array(stride(from: 20.0, through: 177.5, by: 2.5))

    private func weight(after samples: [(up: Double, speed: Double)], from start: Double = 80,
                        predictedExtra: Double = 0) -> Double
    {
        var drag = ScrubFeel.Drag()
        for sample in samples {
            drag.add(up: sample.up, speed: sample.speed)
        }
        let index = detents.firstIndex(of: start) ?? 0
        let steps = drag.steps + ScrubFeel.coast(predictedExtra: predictedExtra)
        return detents[ScrubFeel.land(start: index, steps: steps, count: detents.count).index]
    }

    /// Slow drags of `points`, in 1 pt samples.
    private func slow(_ points: Double) -> [(up: Double, speed: Double)] {
        let step: Double = points < 0 ? -1 : 1
        return Array(repeating: (step, 100), count: Int(abs(points)))
    }

    @Test(arguments: [(11.0, 80.0), (12, 82.5), (36, 87.5), (-24, 75), (100, 100)])
    func slowDrags(points: Double, expected: Double) {
        #expect(weight(after: slow(points)) == expected)
    }

    @Test func upThenBackIsWhereItStarted() {
        #expect(weight(after: slow(30) + slow(-30)) == 80)
    }

    @Test func aFastDragAcceleratesAfterTheExactZone() {
        // 48 pt at ×1 plus 52 pt at ×2.5 = 14.8 detents, shown as 14.
        let fast = Array(repeating: (up: 1.0, speed: 1200.0), count: 100)
        #expect(weight(after: fast) == 115)
    }

    @Test func aFlingCoasts() {
        #expect(ScrubFeel.coast(predictedExtra: 240) == 10)
        #expect(weight(after: slow(24), predictedExtra: 240) == 110)
        #expect(ScrubFeel.coast(predictedExtra: 10000) == 24)
        #expect(ScrubFeel.coast(predictedExtra: -10000) == -24)
    }

    @Test func theEndsHold() throws {
        let top = try ScrubFeel.land(start: #require(detents.firstIndex(of: 170)), steps: 20, count: detents.count)
        #expect(detents[top.index] == 177.5)
        #expect(top.hitBound)
        let bottom = try ScrubFeel.land(start: #require(detents.firstIndex(of: 22.5)), steps: -5, count: detents.count)
        #expect(detents[bottom.index] == 20)
        #expect(bottom.hitBound)
        #expect(ScrubFeel.rubberBand(overflow: 100) == 16)
        #expect(ScrubFeel.rubberBand(overflow: -10) == -3)
    }

    @Test func theAxisLocksOnceAtTenPoints() {
        #expect(ScrubFeel.axis(dx: 5, dy: 5) == nil)
        #expect(ScrubFeel.axis(dx: 40, dy: 15) == .horizontal)
        #expect(ScrubFeel.axis(dx: 3, dy: 12) == .vertical)
    }

    @Test func dumbbellsMoveByTheirOwnDetents() throws {
        let rack = Array(stride(from: 2.0, through: 50, by: 2))
        var drag = ScrubFeel.Drag()
        for _ in 0 ..< 12 {
            drag.add(up: 1, speed: 100)
        }
        #expect(try rack[ScrubFeel.land(start: #require(rack.firstIndex(of: 12)), steps: drag.steps, count: rack.count)
                .index] == 14)
    }

    @Test func repsStepEveryTwentyEightPointsWithoutAcceleration() {
        var drag = ScrubFeel.Drag(pitch: ScrubFeel.repsPitch, accelerates: false)
        for _ in 0 ..< 28 {
            drag.add(up: 1, speed: 2000)
        }
        #expect(drag.steps == 1)
        // Reps 1...50: from 50, one more holds at the end.
        #expect(ScrubFeel.land(start: 49, steps: 1, count: 50) == (49, true))
    }

    @Test func theCoastEasesOut() {
        #expect(ScrubFeel.coastDuration(10) == 0.55)
        #expect(ScrubFeel.coastDuration(24) == 0.8)
        #expect(ScrubFeel.coastTime(0, of: 10) == 0)
        #expect(abs(ScrubFeel.coastTime(10, of: 10) - 0.55) < 0.0001)
        #expect(ScrubFeel.coastTime(5, of: 10) < 0.55 / 2)
    }
}
