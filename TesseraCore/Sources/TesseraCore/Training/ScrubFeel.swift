import Foundation

/// How a number scrubbed in place feels (docs/research/inplace-number.md, docs/design/set-block.md): one detent per
/// load, vertical only, exact for small pushes and faster for big ones, a visible coast after a fling, and a
/// rubber band at the ends. Pure, so the feel is pinned by a table of fixtures; the reel only draws it.
public enum ScrubFeel {
    /// Points per detent at gain 1 (the weight). Reps use 28.
    public static let pitch = 12.0
    public static let repsPitch = 28.0
    /// The axis is decided once, at this much travel.
    public static let axisLock = 10.0
    /// The first stretch of every drag is always gain 1, so a quick small push stays exact.
    public static let exactZone = 48.0
    /// Gain is 1 up to `slow` pt/s, rises linearly to `maxGain` at `fast`, and stays there.
    public static let slow = 250.0
    public static let fast = 1000.0
    public static let maxGain = 2.5
    /// The longest coast after a fling, in detents.
    public static let maxCoast = 24

    public enum Axis: Sendable, Equatable {
        case vertical, horizontal
    }

    /// Nil until `axisLock` of travel; then vertical (the reel) or horizontal (the exercise lane), once.
    public static func axis(dx: Double, dy: Double) -> Axis? {
        guard hypot(dx, dy) >= axisLock else { return nil }
        return abs(dx) > abs(dy) ? .horizontal : .vertical
    }

    /// The gain for a finger speed in pt/s.
    public static func gain(speed: Double) -> Double {
        let speed = abs(speed)
        if speed <= slow {
            return 1
        }
        if speed >= fast {
            return maxGain
        }
        return 1 + (maxGain - 1) * (speed - slow) / (fast - slow)
    }

    /// One drag, accumulated sample by sample (gain can change mid-drag, so a running sum, never
    /// `translation / pitch`, or slowing down would jump the value backwards).
    public struct Drag: Sendable, Equatable {
        /// Path length so far, in points (for the exact zone).
        public private(set) var travelled = 0.0
        /// Fractional detents moved; up (heavier) is positive.
        public private(set) var detents = 0.0
        public let pitch: Double
        public let accelerates: Bool

        public init(pitch: Double = ScrubFeel.pitch, accelerates: Bool = true) {
            self.pitch = pitch
            self.accelerates = accelerates
        }

        /// A sample: `up` points moved up since the last sample (negative is down), at `speed` pt/s.
        public mutating func add(up: Double, speed: Double) {
            var remaining = abs(up)
            let sign: Double = up < 0 ? -1 : 1
            // The part of this sample still inside the exact zone moves at gain 1.
            let exact = min(remaining, max(exactZone - travelled, 0))
            detents += sign * exact / pitch
            remaining -= exact
            if remaining > 0 {
                detents += sign * remaining * (accelerates ? ScrubFeel.gain(speed: speed) : 1) / pitch
            }
            travelled += abs(up)
        }

        /// Whole detents to show (toward zero: nothing moves under one pitch).
        public var steps: Int {
            // A hair of tolerance: twelve 1 pt samples are 0.99999… of a detent in floating point.
            let nudge = detents < 0 ? -1e-9 : 1e-9
            return Int((detents + nudge).rounded(.towardZero))
        }
    }

    /// Detents a fling adds after lift-off, from the predicted extra travel (up positive).
    public static func coast(predictedExtra: Double, pitch: Double = ScrubFeel.pitch) -> Int {
        let raw = (predictedExtra / pitch * 0.5).rounded(.towardZero)
        return Int(min(max(raw, Double(-maxCoast)), Double(maxCoast)))
    }

    /// How long a coast of `steps` detents plays.
    public static func coastDuration(_ steps: Int) -> Double {
        min(0.25 + 0.03 * Double(abs(steps)), 0.8)
    }

    /// When detent `index` (1...steps) shows during a coast: ease-out, fast first and slow last.
    public static func coastTime(_ index: Int, of steps: Int) -> Double {
        let count = abs(steps)
        guard count > 0 else { return 0 }
        let fraction = min(max(Double(index) / Double(count), 0), 1)
        return coastDuration(steps) * (1 - (1 - fraction).squareRoot())
    }

    /// Where `start` lands after `steps` in `0..<count`, and whether the move ran into an end.
    public static func land(start: Int, steps: Int, count: Int) -> (index: Int, hitBound: Bool) {
        guard count > 0 else { return (0, true) }
        let target = start + steps
        let clamped = min(max(target, 0), count - 1)
        return (clamped, clamped != target)
    }

    /// The numeral's rubber band past an end: 0.3 pt per pt dragged, at most 16 pt.
    public static func rubberBand(overflow: Double) -> Double {
        let band = min(abs(overflow) * 0.3, 16)
        return overflow < 0 ? -band : band
    }
}
