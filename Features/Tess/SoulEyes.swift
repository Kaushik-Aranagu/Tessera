import SwiftUI

/// Where her eyes look (docs/design/motion/tess-motion.md §1).
enum SoulGaze: Equatable {
    /// Straight ahead.
    case ahead
    /// Down-left, at her own line, for a second after she speaks.
    case atLine
    /// Up and centred, at him, while she listens.
    case atHim

    /// The pair's offset at soul scale 1: up to 3 pt sideways and 2.2 pt up or down.
    var offset: CGSize {
        switch self {
        case .ahead: .zero
        case .atLine: CGSize(width: -3, height: 2.2)
        case .atHim: CGSize(width: 0, height: -2.2)
        }
    }
}

/// The blink: lids close and open over 160 ms (height to 0.25 and back, ease-in-out), one every 3 to 8 s at random,
/// one in five a double (blink, 250 ms, blink). Pure and seeded by the interval, so a frame at any time is the same
/// frame (and testable).
enum SoulBlink {
    static let duration = 0.16
    static let doubleGap = 0.25

    /// The lid's height (1 open, 0.25 shut) at `time` seconds.
    static func lid(at time: Double) -> CGFloat {
        var start = 0.0
        var index: UInt64 = 0
        // Walk the schedule to the interval holding `time` (blinks start at the end of each 3–8 s gap).
        let origin = floor(time / 600) * 600
        start = origin
        while true {
            let gap = 3 + 5 * unit(index &+ UInt64(origin))
            let blinkAt = start + gap
            if time < blinkAt {
                return 1
            }
            let isDouble = unit(index &+ UInt64(origin) &+ 7919) < 0.2
            let end = blinkAt + (isDouble ? duration * 2 + doubleGap : duration)
            if time < end {
                let local = time - blinkAt
                let phase = isDouble && local > duration + doubleGap ? local - duration - doubleGap
                    : isDouble && local > duration ? -1 : local
                guard phase >= 0, phase <= duration else { return 1 }
                return shape(phase / duration)
            }
            start = end
            index &+= 1
        }
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

    /// Down to 0.25 and back up, ease-in-out.
    private static func shape(_ phase: Double) -> CGFloat {
        let tri = phase < 0.5 ? phase * 2 : (1 - phase) * 2
        let eased = tri * tri * (3 - 2 * tri)
        return CGFloat(1 - 0.75 * eased)
    }

    /// A stable pseudo-random number in [0, 1) for an index.
    private static func unit(_ seed: UInt64) -> Double {
        var value = seed &* 0x9E37_79B9_7F4A_7C15
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

    var body: some View {
        let mains = frame.dabs.prefix(3)
        let count = CGFloat(max(mains.count, 1))
        let centre = CGPoint(x: mains.reduce(0) { $0 + $1.x } / count,
                             y: mains.reduce(0) { $0 + $1.y } / count - 3)
        let scale = frame.look.scale
        let lid = SoulBlink.lid(at: time)
        let glance = still ? .zero : gaze.offset
        HStack(spacing: 8.4 - 3.2) {
            eye(lid)
            eye(lid)
        }
        .offset(x: (centre.x + glance.width) * scale, y: (centre.y + glance.height) * scale)
        .scaleEffect(scale)
        .animation(still ? nil : .spring(duration: 0.3, bounce: 0.05), value: gaze)
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
