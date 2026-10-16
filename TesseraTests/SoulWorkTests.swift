import Foundation
@testable import Tessera
import Testing

/// Working: fade, split, process, gather (docs/design/motion/tess-motion.md §5, build sheet "Tests").
@MainActor
struct SoulWorkTests {
    private let base = SoulFrame.sample(.working, time: 3, elapsed: 0)
    /// The chrome draws her at 0.72, at idle's 0.62.
    private var scale: CGFloat {
        base.look.scale * 0.72
    }

    @Test func herColourDrainsInHalfASecond() {
        let fade = SoulWork.fade(sinceSplit: 0.5, sinceGather: nil)
        let graded = SoulWork.grade(base, fade: fade)
        #expect(abs(graded.look.saturation - 0.62) <= 0.02)
        #expect(abs(graded.look.contrast - 1) < 0.001)
        #expect(graded.halo.opacity < 0.001)
        #expect(SoulWork.fade(sinceSplit: 0.1, sinceGather: nil) < 0.2)
    }

    @Test func sheSplitsIntoTwelveFaintLights() {
        let lights = SoulWork.lights(base, scale: scale, sinceSplit: 3, sinceGather: nil)
        #expect(lights.count == 12)
        #expect(lights.allSatisfy { abs($0.alpha - 0.55) < 0.001 })
        // On screen they are 11 to 15 pt (±14% breath), round a point 10 pt left and 7 pt up of home.
        #expect(lights.allSatisfy { $0.radiusX * scale >= 11 * 0.86 - 0.01 && $0.radiusX * scale <= 15 * 1.14 + 0.01 })
        // Satellites leave first, the children last.
        let early = SoulWork.lights(base, scale: scale, sinceSplit: 0.5, sinceGather: nil)
        #expect(early[3].alpha > 0 && early[11].alpha < 0.01)
    }

    /// Every light lands on its dab together, at gather + 820 ms (under 1 pt on screen).
    @Test func everyLightIsHomeWhenTheGatherEnds() {
        let lights = SoulWork.lights(base, scale: scale, sinceSplit: 6, sinceGather: SoulWork.gatherDuration)
        for (index, light) in lights.enumerated() {
            let dab = base.dabs[SoulWork.parent[index]]
            #expect(hypot(light.x - dab.x, light.y - dab.y) * scale < 1, "light \(index)")
            if index >= 6 {
                #expect(light.alpha < 0.01, "child \(index) folds into its parent")
            }
        }
        // Halfway home they are still out.
        let mid = SoulWork.lights(base, scale: scale, sinceSplit: 6, sinceGather: 0.4)
        #expect(hypot(mid[0].x - base.dabs[0].x, mid[0].y - base.dabs[0].y) * scale > 1)
    }

    @Test func lowPowerSplitsOnlySixLights() {
        let lights = SoulWork.lights(base, scale: scale, sinceSplit: 3, sinceGather: nil, lowPower: true)
        #expect(lights.count(where: { $0.alpha > 0.01 }) == 6)
    }

    @Test func doneBeginsOnlyWhenTheLightsLand() async throws {
        let soul = SoulRouter()
        soul.handle(.askClaude)
        #expect(soul.mode == .working)
        soul.handle(.closed)
        #expect(soul.mode == .working, "the surface closing doesn't end the work")
        soul.handle(.claudeDone)
        #expect(soul.mode == .gathering)
        try await Task.sleep(for: .seconds(0.6))
        #expect(soul.mode == .gathering && soul.doneCount == 0)
        try await Task.sleep(for: .seconds(0.5))
        #expect(soul.mode == .done && soul.doneCount == 1)
    }

    @Test func aFailureGathersWithoutDone() async throws {
        let soul = SoulRouter(clock: { Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: .now)! })
        soul.handle(.askClaude)
        soul.handle(.claudeFailed)
        #expect(soul.mode == .gathering)
        try await Task.sleep(for: .seconds(1.0))
        #expect(soul.mode == .idle && soul.doneCount == 0)
    }

    @Test func theLiveCornerNeverWorks() {
        let soul = SoulRouter(page: .live)
        soul.handle(.askClaude)
        #expect(soul.mode == .thinking)
    }
}
