import SwiftUI

/// Her beat in a reward (tess-motion.md §6) and the day she wears (tess-picks.md idea 4). Pure, from the seconds
/// since each beat landed.
///
/// The beat is a 940 ms overlay on whatever mode she's in: the satellites pull in to 55% of their offset over
/// 180 ms (ease-out) and release over 320 ms (the house curve), she swells to 1.1 and her saturation lifts +0.25,
/// which dries away; one blink at the landing. Every done of his day also adds +0.10 that stays, capped at +0.40.
enum SoulBeat {
    /// A done row's beat lands as the fleck reaches the day label.
    static let landing = 0.52
    static let duration = 0.94
    static let wearStep: CGFloat = 0.10
    static let wearCap: CGFloat = 0.40
    /// At 04:00 the wear goes back to plain over the first idle minute, never as a visible step.
    static let wearReset = 60.0
    private static let houseCurve = UnitCurve.bezier(startControlPoint: UnitPoint(x: 0.3, y: 0),
                                                     endControlPoint: UnitPoint(x: 0.2, y: 1))

    /// 0…1: the gather `elapsed` seconds after the beat landed.
    static func gather(_ elapsed: Double) -> CGFloat {
        func ramp(_ start: Double, _ duration: Double, _ curve: UnitCurve) -> Double {
            curve.value(at: min(max((elapsed - start) / duration, 0), 1))
        }
        guard elapsed >= 0 else { return 0 }
        return CGFloat(ramp(0, 0.18, .easeOut) * (1 - ramp(0.18, 0.32, houseCurve)))
    }

    /// The wear for `dones` things done today: +0.10 each, up to four.
    static func wear(_ dones: Int) -> CGFloat {
        min(CGFloat(max(dones, 0)) * wearStep, wearCap)
    }

    /// The beat on a frame: the satellites gather toward the mains' centre, she swells, her colour lifts.
    static func beating(_ frame: SoulFrame, gather amount: CGFloat, wear: CGFloat, swells: Bool = true) -> SoulFrame {
        var result = frame
        result.look.saturation += wear + 0.25 * amount
        guard amount > 0 else { return result }
        let centreX = frame.dabs.prefix(3).reduce(0) { $0 + $1.x } / 3
        let centreY = frame.dabs.prefix(3).reduce(0) { $0 + $1.y } / 3
        for index in 3 ..< result.dabs.count {
            let pullX = centreX + (frame.dabs[index].x - centreX) * 0.55
            let pullY = centreY + (frame.dabs[index].y - centreY) * 0.55
            result.dabs[index].x += (pullX - frame.dabs[index].x) * amount
            result.dabs[index].y += (pullY - frame.dabs[index].y) * amount
        }
        // In the quiet hours she doesn't swell (decisions 12:13 PM PT, G7).
        if swells {
            result.look.scale *= 1 + 0.1 * amount
        }
        return result
    }
}
