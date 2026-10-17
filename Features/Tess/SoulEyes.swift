import SwiftUI

/// Where her eyes look (docs/design/motion/tess-motion.md §1).
enum SoulGaze: Equatable {
    /// Straight ahead.
    case ahead
    /// Down-left, at her own line, for a second after she speaks.
    case atLine
    /// Up and centred, at him, while she listens.
    case atHim
    /// Along his finger while it strokes across her (idea 3).
    case alongStroke

    /// The pair's offset at soul scale 1: up to 3 pt sideways and 2.2 pt up or down.
    var offset: CGSize {
        switch self {
        case .ahead: .zero
        case .atLine: CGSize(width: -3, height: 2.2)
        case .atHim: CGSize(width: 0, height: -2.2)
        case .alongStroke: CGSize(width: 3, height: 0)
        }
    }
}

/// The blink: lids close and open over 160 ms (height to 0.25 and back, ease-in-out), one every 3 to 8 s at random,
/// one in five a double (blink, 250 ms, blink). Pure and seeded by the interval, so a frame at any time is the same
/// frame (and testable).
enum SoulBlink {
    static let duration = 0.16
    static let doubleGap = 0.25
    /// The schedule repeats every hour; the last blink ends well before the wrap, so none is cut short.
    static let period = 3600.0

    /// Each blink's start and whether it's a double, over one period (seeded, built once).
    static let schedule: [(start: Double, isDouble: Bool)] = {
        var result: [(Double, Bool)] = []
        var time = 0.0
        var index: UInt64 = 0
        while true {
            time += 3 + 5 * unit(index)
            let isDouble = unit(index &+ 7919) < 0.2
            guard time + duration * 2 + doubleGap < period - 3 else { break }
            result.append((time, isDouble))
            time += isDouble ? duration * 2 + doubleGap : duration
            index &+= 1
        }
        return result
    }()

    /// The lid's height (1 open, 0.25 shut) at `time` seconds.
    static func lid(at time: Double) -> CGFloat {
        let local = time.truncatingRemainder(dividingBy: period)
        let wrapped = local < 0 ? local + period : local
        // The last blink starting at or before `wrapped` (binary search).
        var low = 0, high = schedule.count - 1, found = -1
        while low <= high {
            let mid = (low + high) / 2
            if schedule[mid].start <= wrapped {
                found = mid
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        guard found >= 0 else { return 1 }
        let blink = schedule[found]
        let since = wrapped - blink.start
        if since <= duration {
            return shape(since / duration)
        }
        if blink.isDouble, since >= duration + doubleGap, since <= duration * 2 + doubleGap {
            return shape((since - duration - doubleGap) / duration)
        }
        return 1
    }

    /// The times (in [from, to)) each blink starts, for tests.
    static func starts(from: Double, to: Double, step: Double = 0.01) -> [Double] {
        var result: [Double] = []
        var previous: CGFloat = 1
        var time = from
        while time < to {
            let value = lid(at: time)
            if value < 1, previous >= 1 {
                result.append(time)
            }
            previous = value
            time += step
        }
        return result
    }

    /// One blink `since` seconds after it began (a moment's own blink, outside the schedule); nil when it's over.
    static func once(since: Double) -> CGFloat? {
        guard since >= 0, since <= duration else { return nil }
        return shape(since / duration)
    }

    /// Down to 0.25 and back up, ease-in-out.
    private static func shape(_ phase: Double) -> CGFloat {
        let tri = phase < 0.5 ? phase * 2 : (1 - phase) * 2
        let eased = tri * tri * (3 - 2 * tri)
        return CGFloat(1 - 0.75 * eased)
    }

    /// A stable pseudo-random number in [0, 1) for an index.
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

/// Two ink dots on the soul (§1): 3.2 × 3.5 pt ovals, 8.4 pt apart, 3 pt above the mean of the three main dabs, in
/// the look's dark colour (ink on light looks, ground on dark ones) at 82%, normal blend, over the soul.
struct SoulEyes: View {
    let frame: SoulFrame
    let time: Double
    let gaze: SoulGaze
    let color: Color
    /// Reduce Motion: the blink stays, the dots sit still.
    var still = false
    /// A lid from a moment of hers (the wake) in place of the blink schedule.
    var lid: CGFloat?

    /// Where the pair sits, in the canvas's points from its centre: the main dabs' mean, 3 pt above it, both scaled
    /// by the soul's drawn scale (the same transform `SoulRenderer` applies to the dabs).
    static func centre(of frame: SoulFrame) -> CGPoint {
        let mains = frame.dabs.prefix(3)
        let count = CGFloat(max(mains.count, 1))
        let scale = frame.look.scale
        return CGPoint(x: mains.reduce(0) { $0 + $1.x } / count * scale,
                       y: (mains.reduce(0) { $0 + $1.y } / count - 3) * scale)
    }

    var body: some View {
        let centre = Self.centre(of: frame)
        let scale = frame.look.scale
        let lid = lid ?? SoulBlink.lid(at: time)
        let glance = still ? .zero : gaze.offset
        HStack(spacing: 8.4 - 3.2) {
            eye(lid)
            eye(lid)
        }
        // Scaled first, then placed: the offset is already in screen points (no second scale).
        .scaleEffect(scale)
        .offset(x: centre.x + glance.width * scale, y: centre.y + glance.height * scale)
        .opacity(frame.look.opacity)
        // Reduce Motion: `still` already holds them ahead; the policy also drops the spring.
        .tesseraAnimation(.spring(duration: 0.3, bounce: 0.05), value: gaze)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func eye(_ lid: CGFloat) -> some View {
        Ellipse()
            .fill(color.opacity(0.82))
            .frame(width: 3.2, height: 3.5 * lid)
            .frame(height: 3.5)
    }
}
