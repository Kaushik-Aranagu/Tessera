import Foundation
@testable import Tessera
import Testing

/// Tess's life (sheet 215 rev 6): glances, blinks, her body and her reactions.
@MainActor
struct SoulLifeTests {
    @Test func glancesJumpEveryPointSevenToTwoPointEightSecondsInTheStatedMix() {
        let glances = SoulLife.glances
        #expect(glances.count > 1000)
        let holds = glances.map(\.hold)
        #expect(holds.allSatisfy { $0 >= 0.7 && $0 <= 2.8 + 1e-9 || $0 == 2.6 })
        let small = Double(glances.filter { $0.kind == .small }.count) / Double(glances.count)
        let page = Double(glances.filter { $0.kind == .page }.count) / Double(glances.count)
        let him = Double(glances.filter { $0.kind == .atHim }.count) / Double(glances.count)
        #expect(
            abs(small - 0.55) < 0.05 && abs(page - 0.27) < 0.05 && abs(him - 0.18) < 0.05,
            "\(small) \(page) \(him)"
        )
        #expect(glances.filter { $0.kind == .atHim }.allSatisfy { $0.hold == 2.6 })
        let blinking = Double(glances.filter(\.blinks).count) / Double(glances.count)
        #expect(abs(blinking - 0.30) < 0.05, "\(blinking)")
    }

    @Test func herEyesLandOnAFastSpringAndHold() {
        let glance = SoulLife.glances[5]
        let target = glance.target
        let during = SoulLife.offset(at: glance.start + 0.02)
        let landed = SoulLife.offset(at: glance.start + 0.3)
        #expect(abs(landed.width - target.width) < 0.01 && abs(landed.height - target.height) < 0.01)
        let previous = SoulLife.glances[4].target
        #expect(abs(during.width - previous.width) + abs(during.height - previous.height)
            > 0, "it has started to move")
        #expect(SoulLife.glances.allSatisfy { abs($0.target.width) <= 3 && abs($0.target.height) <= 2.2 })
    }

    @Test func shiftsThatBlinkBlinkJustAfterTheJump() throws {
        let glance = try #require(SoulLife.glances.first { $0.blinks })
        let mid = glance.start + SoulLife.shiftBlinkDelay + SoulBlink.duration / 2
        #expect(SoulLife.lid(at: mid) < 0.5)
    }

    @Test func herBreathFloatsAtMostOnePointOneAndIsUneven() throws {
        let values = stride(from: 0.0, to: 60, by: 0.05).map { SoulLife.float(at: $0) }
        #expect(values.allSatisfy { abs($0) <= 1.1 + 1e-9 })
        #expect(try #require(values.max()) > 0.8 && values.min()! < -0.8)
    }

    @Test func sheLeansAfterHerEyesByHalfTheirOffset() {
        let glance = SoulLife.glances[8]
        let later = glance.start + 0.6
        let eyes = SoulLife.offset(at: later - SoulLife.leanDelay)
        let lean = SoulLife.lean(at: later)
        #expect(abs(lean.width - eyes.width * 0.5) < 1e-9 && abs(lean.height - eyes.height * 0.5) < 1e-9)
    }

    @Test func reactionsHaveTheirLengths() {
        #expect(SoulLife.widen(since: 0) == 1 && SoulLife.widen(since: 0.16) > 1.24 && SoulLife.widen(since: 0.32) == 1)
        #expect(SoulLife.breath(.line, since: 0.15) > 1.03 && SoulLife.breath(.line, since: 0.3) == 1)
        #expect(SoulLife.breath(.did, since: 0.1) == 1)
        #expect(SoulLife.smile(since: 0) == 0 && SoulLife.smile(since: 0.5) == 1 && SoulLife.smile(since: 1.1) == 0)
    }

    @Test func glancesAreOnlyForAScriptedGazeOfAheadAndAFingerOverridesThem() {
        #expect(SoulEyes.glance(gaze: .atLine, attention: nil, time: 12) == SoulGaze.atLine.offset)
        let finger = SoulEyes.glance(gaze: .ahead, attention: CGPoint(x: 1, y: -1), time: 12)
        #expect(finger == CGSize(width: 3, height: -2.2))
    }
}
