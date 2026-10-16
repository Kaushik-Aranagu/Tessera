import SwiftUI

/// She wakes with you (tess-picks.md idea 2): on the first open of his day her eyes are shut for a second, open
/// over 400 ms, she stretches once at 1.5 s, and blinks once at 3.4 s. Pure, from the seconds since the wake.
enum SoulWake {
    /// Everything of the wake is over by here; the router clears it.
    static let duration = 4.0
    private static let stretchStart = 1.5
    private static let stretchOut = 0.6
    private static let stretchBack = 0.7
    private static let houseCurve = UnitCurve.bezier(startControlPoint: UnitPoint(x: 0.3, y: 0),
                                                     endControlPoint: UnitPoint(x: 0.2, y: 1))

    /// The lids (1 open, 0.25 shut): shut for 1.0 s, open over 400 ms ease-out, one blink at 3.4 s, otherwise open
    /// (the usual blink schedule waits until the wake is over). Reduce Motion and Low Power: a 200 ms crossfade.
    static func lid(at elapsed: Double, quiet: Bool = false) -> CGFloat {
        let shut: CGFloat = 0.25
        if elapsed < 1 {
            return shut
        }
        let open = quiet ? 0.2 : 0.4
        if elapsed < 1 + open {
            let phase = (elapsed - 1) / open
            let eased = quiet ? phase : UnitCurve.easeOut.value(at: phase)
            return shut + (1 - shut) * CGFloat(eased)
        }
        let blink = elapsed - 3.4
        if !quiet, blink >= 0, blink <= SoulBlink.duration {
            let phase = blink / SoulBlink.duration
            let tri = phase < 0.5 ? phase * 2 : (1 - phase) * 2
            let eased = tri * tri * (3 - 2 * tri)
            return 1 - (1 - shut) * CGFloat(eased)
        }
        return 1
    }

    /// 0…1 of the stretch: out over 600 ms ease-in-out from 1.5 s, back over 700 ms on the house curve from 2.3 s.
    static func stretch(at elapsed: Double) -> CGFloat {
        func ramp(_ start: Double, _ duration: Double, _ curve: UnitCurve) -> Double {
            curve.value(at: min(max((elapsed - start) / duration, 0), 1))
        }
        return CGFloat(ramp(stretchStart, stretchOut, .easeInOut) * (1 - ramp(2.3, stretchBack, houseCurve)))
    }

    /// She spreads round her centre: x × s and y × (2 − 0.98 s), s from 1 to 1.22, so at the peak she is about 20%
    /// shorter and keeps roughly her area (the lab's formula, which corrects the sheet's "2%"). Taken relative to
    /// s = 1, so at rest nothing moves.
    static func stretched(_ frame: SoulFrame, amount: CGFloat) -> SoulFrame {
        guard amount != 0 else { return frame }
        var result = frame
        let wide = 1 + 0.22 * amount
        let tall = (2 - 0.98 * wide) / (2 - 0.98)
        for index in result.dabs.indices {
            result.dabs[index].x *= wide
            result.dabs[index].y *= tall
        }
        return result
    }
}
