import Foundation
@testable import Tessera
import Testing

/// Her palette (sheet 215 rev 20): Ember, a close palette from one accent, and a glide that never goes through grey.
struct SoulPaintsTests {
    @Test func emberIsHerBase() {
        #expect(SoulCloud.paintsLight == [0xFF5A26, 0xE5341C, 0xFFA90F])
        #expect(SoulCloud.paintsDark == [0xFF6B3D, 0xFF4A33, 0xFFC23D])
        #expect(SoulPaints.palette(dark: false, pageAccent: nil) == SoulCloud.paintsLight)
    }

    @Test func aScreenWithOneAccentGivesHerAClosePalette() {
        let accent: UInt32 = 0x3561C8
        let light = SoulPaints.close(to: accent, dark: false)
        let dark = SoulPaints.close(to: accent, dark: true)
        #expect(light.count == 3)
        let middle = SoulPaints.lch(light[0]), darkMiddle = SoulPaints.lch(dark[0])
        #expect(abs(middle.lightness - 0.64) < 0.03 && abs(darkMiddle.lightness - 0.74) < 0.03)
        #expect(middle.chroma >= 0.14)
        let side = SoulPaints.lch(light[1])
        var turn = abs(side.hue - middle.hue)
        if turn > Double.pi {
            turn = 2 * Double.pi - turn
        }
        #expect(abs(turn - 18 * Double.pi / 180) < 0.06)
    }

    @Test func theGlideStartsAtOneAndEndsAtTheOtherThroughTheShortWayRound() {
        let from = SoulCloud.paintsLight, to = SoulPaints.close(to: 0x3561C8, dark: false)
        #expect(SoulPaints.glide(from: from, to: to, progress: 0) == from)
        #expect(SoulPaints.glide(from: from, to: to, progress: 1) == to)
        // Never grey on the way: every sample keeps chroma well above grey.
        for step in 1 ..< 20 {
            let mid = SoulPaints.glide(from: from, to: to, progress: Double(step) / 20)
            #expect(mid.allSatisfy { SoulPaints.lch($0).chroma > 0.06 })
        }
        #expect(SoulPaints.glideSeconds == 1.2)
    }

    @Test func theGliderBeginsAGlideFromWhatIsOnScreenWhenTheTargetChanges() {
        let glider = SoulPaletteGlider()
        let ember = SoulCloud.paintsLight, blue = SoulPaints.close(to: 0x3561C8, dark: false)
        #expect(glider.paints(target: ember, at: 0, instant: false) == ember)
        #expect(glider.paints(target: blue, at: 10, instant: false) == ember)
        let half = glider.paints(target: blue, at: 10.6, instant: false)
        #expect(half != ember && half != blue)
        #expect(glider.paints(target: blue, at: 12, instant: false) == blue)
        #expect(glider.paints(target: ember, at: 20, instant: true) == ember)
    }
}
