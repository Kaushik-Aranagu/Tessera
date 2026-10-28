import CoreGraphics
import SwiftUI

/// Sheet 358, the scaffolding comes down: when a place sets, its dashed outline drops 6 pt, shrinks to 98.5% and fades
/// out over 380 ms (cubic-bezier .4, 0, .6, 1), places that set together going top to bottom at 1 ms per 4 pt of the
/// place's y. Undo runs it in reverse. Reduce Motion: a 200 ms fade only. Pure, so it tests without a screen.
enum OutlineSetting {
    static let seconds = 0.38
    static let reducedSeconds = 0.2
    static let drop: CGFloat = 6
    static let shrink: CGFloat = 0.985

    struct Frame: Equatable {
        var offset: CGFloat
        var scale: CGFloat
        var opacity: Double
    }

    /// Seconds of delay for a place whose top is at `y` (design points): 1 ms per 4 pt; none under Reduce Motion.
    static func delay(y: CGFloat, reduceMotion: Bool) -> Double {
        reduceMotion ? 0 : Double(max(0, y)) / 4 / 1000
    }

    static func duration(reduceMotion: Bool) -> Double {
        reduceMotion ? reducedSeconds : seconds
    }

    /// The cubic-bezier (.4, 0, .6, 1) at progress `x` of its time, by bisection.
    static func ease(_ x: Double) -> Double {
        let clamped = min(max(x, 0), 1)
        func bez(_ t: Double, _ a: Double, _ b: Double) -> Double {
            3 * (1 - t) * (1 - t) * t * a + 3 * (1 - t) * t * t * b + t * t * t
        }
        var low = 0.0, high = 1.0
        for _ in 0 ..< 30 {
            let mid = (low + high) / 2
            if bez(mid, 0.4, 0.6) < clamped {
                low = mid
            } else {
                high = mid
            }
        }
        return bez((low + high) / 2, 0, 1)
    }

    /// The outline `time` seconds after the change starts. Setting runs rest to gone; undoing runs gone to rest.
    static func frame(at time: Double, y: CGFloat, setting: Bool, reduceMotion: Bool) -> Frame {
        let run = duration(reduceMotion: reduceMotion)
        let p = ease((time - delay(y: y, reduceMotion: reduceMotion)) / run)
        let gone = setting ? p : 1 - p
        return Frame(offset: reduceMotion ? 0 : drop * gone, scale: reduceMotion ? 1 : 1 - (1 - shrink) * gone,
                     opacity: 1 - gone)
    }

    /// The SwiftUI animation for a place at `y`. Reduce Motion is MotionPolicy's own rule with the sheet's 200 ms fade.
    static func animation(y: CGFloat, reduceMotion: Bool) -> Animation {
        guard !reduceMotion else { return .easeOut(duration: reducedSeconds) }
        return MotionPolicy.resolve(.timingCurve(0.4, 0, 0.6, 1, duration: seconds)
            .delay(delay(y: y, reduceMotion: false)), reduceMotion: false)
    }
}
