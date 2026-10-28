import CoreGraphics
import Foundation

/// Tess's life (sheet 215 rev 6): glances in place of a sine wander, uneven breath, a lean that follows her eyes, and
/// her small reactions. Pure functions of time, seeded, so any frame is the same frame and every number is testable.
enum SoulLife {
    // MARK: Glances

    struct Glance: Equatable {
        enum Kind: Equatable { case small, page, atHim }
        let start: Double
        let kind: Kind
        let hold: Double
        let target: CGSize
        /// 30% of gaze shifts also blink.
        let blinks: Bool
    }

    /// The schedule repeats every hour, as the blink's does.
    static let period = SoulBlink.period
    /// A fast spring: it lands in about 0.12 s.
    static let omega = 45.0
    /// Held while she looks back at him.
    static let atHimHold = 2.6
    /// The lean follows her eyes by this long and moves this much of their offset.
    static let leanDelay = 0.12
    static let leanShare = 0.5
    /// A blink caused by a gaze shift starts this long after the shift.
    static let shiftBlinkDelay = 0.05

    private static let pageTargets = [
        CGSize(width: -3, height: 1.8), CGSize(width: 3, height: 1.8), CGSize(width: 2.4, height: 0.8),
        CGSize(width: -2.4, height: 0.8), CGSize(width: 0, height: 2.2),
    ]

    /// Every 0.7 to 2.8 s her eyes jump and hold: 55% small looks, 27% at things on the page, 18% back at him (held
    /// 2.6 s). Built once.
    static let glances: [Glance] = {
        var result: [Glance] = []
        var time = 0.5
        var index: UInt64 = 100
        while true {
            let pick = unit(index)
            let kind: Glance.Kind = pick < 0.55 ? .small : pick < 0.82 ? .page : .atHim
            let hold = kind == .atHim ? atHimHold : 0.7 + 2.1 * unit(index &+ 31)
            let target: CGSize = switch kind {
            case .small: CGSize(width: (unit(index &+ 5) - 0.5) * 2.8, height: (unit(index &+ 9) - 0.5) * 1.8)
            case .page: pageTargets[Int(unit(index &+ 13) * Double(pageTargets.count)) % pageTargets.count]
            case .atHim: CGSize(width: 0, height: -2.2)
            }
            guard time + hold < period - 3 else { break }
            result.append(Glance(start: time, kind: kind, hold: hold, target: target,
                                 blinks: unit(index &+ 17) < 0.3))
            time += hold
            index &+= 1
        }
        return result
    }()

    /// The glance in force at `time`, and the offset it began from.
    private static func current(at time: Double) -> (glance: Glance, from: CGSize)? {
        let wrapped = wrap(time)
        var low = 0, high = glances.count - 1, found = -1
        while low <= high {
            let mid = (low + high) / 2
            if glances[mid].start <= wrapped {
                found = mid
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        guard found >= 0 else { return nil }
        return (glances[found], found > 0 ? glances[found - 1].target : .zero)
    }

    /// Where her eyes are at `time`, in points at soul scale 1: a jump on a fast spring, then a hold.
    static func offset(at time: Double) -> CGSize {
        guard let (glance, from) = current(at: time) else { return .zero }
        let since = max(wrap(time) - glance.start, 0)
        let settle = 1 - (1 + omega * since) * exp(-omega * since)
        return CGSize(width: from.width + (glance.target.width - from.width) * settle,
                      height: from.height + (glance.target.height - from.height) * settle)
    }

    /// The lid at `time`: the blink schedule, and the blinks that go with 30% of the gaze shifts.
    static func lid(at time: Double) -> CGFloat {
        var lid = SoulBlink.lid(at: time)
        if let (glance, _) = current(at: time), glance.blinks,
           let shift = SoulBlink.once(since: wrap(time) - glance.start - shiftBlinkDelay)
        {
            lid = min(lid, shift)
        }
        return lid
    }

    // MARK: Body

    /// Her breath is uneven, floating at most 1.1 pt.
    static func float(at time: Double) -> CGFloat {
        CGFloat(1.1 * (0.6 * sin(2 * Double.pi * time / 4.1) + 0.4 * sin(2 * Double.pi * time / 2.3 + 1.3)))
    }

    /// She leans after her eyes: half their offset, a moment late.
    static func lean(at time: Double) -> CGSize {
        let eyes = offset(at: time - leanDelay)
        return CGSize(width: eyes.width * leanShare, height: eyes.height * leanShare)
    }

    // MARK: Reactions

    enum Reaction: Equatable {
        /// His touch: her eyes widen for 320 ms and she takes a small breath.
        case touch
        /// She inhales before each line.
        case line
        /// After she does something for him: smile arcs for 1.1 s.
        case did
        /// Sheet 387, "everyone's had a drink": her eyes close into two small arcs for 1.6 s, once.
        case drink
    }

    static let widenSeconds = 0.32
    static let inhaleSeconds = 0.3
    static let smileSeconds = 1.1
    /// The long smile of sheet 387.
    static let drinkSmileSeconds = 1.6

    /// Eye scale: 1 to 1.25 and back over 320 ms after a touch.
    static func widen(since: Double) -> CGFloat {
        guard since >= 0, since < widenSeconds else { return 1 }
        return 1 + 0.25 * CGFloat(sin(Double.pi * since / widenSeconds))
    }

    /// Body scale: a small breath (1 to 1.04) after a touch, an inhale before a line.
    static func breath(_ reaction: Reaction, since: Double) -> CGFloat {
        let length = reaction == .touch ? 0.5 : inhaleSeconds
        guard reaction != .did, reaction != .drink, since >= 0, since < length else { return 1 }
        return 1 + 0.04 * CGFloat(sin(Double.pi * since / length))
    }

    /// 0 open eyes, 1 smile arcs: rises in 120 ms, holds, falls over the last 200 ms of 1.1 s.
    static func smile(since: Double, seconds: Double = smileSeconds) -> Double {
        guard since >= 0, since < seconds else { return 0 }
        return min(since / 0.12, 1, (seconds - since) / 0.2)
    }

    // MARK: Seeds

    private static func wrap(_ time: Double) -> Double {
        let local = time.truncatingRemainder(dividingBy: period)
        return local < 0 ? local + period : local
    }

    private static func unit(_ seed: UInt64) -> Double {
        var value = seed &* 0x9E37_79B9_7F4A_7C15 &+ 0x1234_5678
        value ^= value >> 30
        value &*= 0xBF58_476D_1CE4_E5B9
        value ^= value >> 27
        value &*= 0x94D0_49BB_1331_11EB
        value ^= value >> 31
        return Double(value % 1_000_000) / 1_000_000
    }
}
