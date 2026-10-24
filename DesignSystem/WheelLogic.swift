import CoreGraphics
import Foundation
import TesseraCore

/// The numbers behind every wheel (sheet 230: plan, session, week, library and the number dial): where a row sits for
/// a finger position, what a release does, how many rows show and when the wheel comes home. Pure, so the feel is
/// pinned by tests (`WheelLogicTests`); `DepthWheel` is the SwiftUI side. A touch is judged by `GestureTuning`.
struct WheelStyle: Equatable {
    /// Distance between two rows' centres.
    var pitch: CGFloat
    /// Extra room next to the focused row, so it stands clear of its neighbours (8 pt on the plan wheel).
    var extra: CGFloat
    /// Rows that show at once, focus in the middle (5; 3 at AX3 and up).
    var visibleRows: Int
    /// Point size of a row at distance 0, 1, 2, 3...; the last entry holds for anything farther.
    var sizes: [CGFloat]

    /// The landing's plan wheel (v7): spacing 38 plus 8 next to the focus, 30 / 20 / 17 / 15 pt.
    static let plan = WheelStyle(pitch: 38, extra: 8, visibleRows: 5, sizes: [30, 20, 17, 15])
    /// The wheel inside the workout: five 34 pt rows, 22 / 16 / 14 pt.
    static let session = WheelStyle(pitch: 34, extra: 0, visibleRows: 5, sizes: [22, 16, 14])
    /// This week and the number dial.
    static let week = WheelStyle(pitch: 40, extra: 6, visibleRows: 5, sizes: [28, 20, 17, 15])
    static let dial = WheelStyle(pitch: 48, extra: 10, visibleRows: 7, sizes: [64, 40, 30, 24])

    /// AX3 and up show 3 rows.
    func rows(accessibility: Bool) -> Int {
        accessibility ? min(visibleRows, 3) : visibleRows
    }

    /// The point size at a (fractional) distance from the focus, easing between the table's entries.
    func size(at distance: Double) -> CGFloat {
        let away = min(max(abs(distance), 0), Double(sizes.count - 1))
        let low = Int(away.rounded(.down)), high = min(low + 1, sizes.count - 1)
        let fraction = CGFloat(away - Double(low))
        return sizes[low] + (sizes[high] - sizes[low]) * fraction
    }

    /// 1 at the focus, shrinking to the farthest size's share: what a row at this distance is scaled by when it is
    /// built at the focused size.
    func scale(at distance: Double) -> CGFloat {
        guard let first = sizes.first, first > 0 else { return 1 }
        return size(at: distance) / first
    }

    /// The signed vertical offset of a row at signed `distance` from the focus: `pitch` a row, plus `extra` once past
    /// the focused row, so the focus stands clear.
    func offset(at distance: Double) -> CGFloat {
        let magnitude = min(abs(distance), Double.greatestFiniteMagnitude)
        let travel = CGFloat(magnitude) * pitch + CGFloat(min(magnitude, 1)) * extra
        return distance < 0 ? -travel : travel
    }
}

enum WheelMath {
    /// The row a (fractional) position is nearest to, held inside the range.
    static func nearest(position: Double, in range: ClosedRange<Int>) -> Int {
        guard position.isFinite else { return range.lowerBound }
        return min(max(Int(position.rounded()), range.lowerBound), range.upperBound)
    }

    /// The position under a finger: the drag started on `startPosition`; fingers moving up move the wheel to later
    /// rows 1:1 (`translation` is the drag's vertical travel, negative up). Rubber-bands a little past the ends.
    static func position(start startPosition: Double, translation: CGFloat, pitch: CGFloat,
                         in range: ClosedRange<Int>) -> Double
    {
        guard pitch > 0, translation.isFinite else { return startPosition }
        let raw = startPosition - Double(translation / pitch)
        let low = Double(range.lowerBound), high = Double(range.upperBound)
        if raw < low {
            return low - rubber(low - raw)
        }
        if raw > high {
            return high + rubber(raw - high)
        }
        return raw
    }

    /// Past an end the wheel gives a third as fast, and never more than half a row.
    private static func rubber(_ overshoot: Double) -> Double {
        min(overshoot / 3, 0.5)
    }

    /// Where a release lands. A flick (real speed and real travel, from `GestureTuning`) that did not already carry
    /// the wheel past a row moves it exactly one row; anything else snaps to the nearest row. `velocity` is the
    /// finger's vertical speed (negative up), `translation` its travel.
    static func release(position: Double, translation: CGFloat, velocity: CGFloat, pitch: CGFloat,
                        in range: ClosedRange<Int>) -> Int
    {
        let base = nearest(position: position, in: range)
        let travelled = abs(Double(translation))
        let isFlick = travelled >= GestureTuning.flickTravel && abs(Double(velocity)) >= GestureTuning.flickVelocity
        guard isFlick, travelled < Double(pitch) else { return base }
        // Fingers up (negative velocity) go to the next row.
        let step = velocity < 0 ? 1 : -1
        let started = nearest(position: position + Double(translation / pitch), in: range)
        return min(max(started + step, range.lowerBound), range.upperBound)
    }

    /// How faint a row is: rows past the visible window fade out, the edge row is already softer.
    static func opacity(distance: Double, visibleRows: Int) -> Double {
        let half = Double(max(visibleRows, 1)) / 2
        let away = abs(distance)
        if away <= half - 1 {
            return 1
        }
        return max(0, min(1, half - away))
    }

    /// The rows worth building for a position: just the visible window plus one either side.
    static func window(position: Double, visibleRows: Int, in range: ClosedRange<Int>) -> ClosedRange<Int> {
        let reach = Int((Double(visibleRows) / 2).rounded(.up)) + 1
        let centre = nearest(position: position, in: range)
        return max(range.lowerBound, centre - reach) ... min(range.upperBound, centre + reach)
    }
}

/// The spring-back (sheet 230): the wheel returns to now 6 s after the last touch. Each touch resets the count; it
/// pauses while a finger is down, VoiceOver is on the wheel or an exercise page is open.
struct WheelHome: Equatable {
    static let idle = 6.0

    var lastTouch: Double?

    mutating func touched(at time: Double) {
        lastTouch = time
    }

    /// Whether the wheel should go home at `time`: untouched for `idle` seconds, and nothing is holding it.
    func shouldReturn(at time: Double, fingerDown: Bool, paused: Bool, away: Bool) -> Bool {
        guard away, !fingerDown, !paused, let lastTouch else { return false }
        return time - lastTouch >= Self.idle
    }
}

// MARK: - Scrolling numbers

/// The scrolling number's maths (sheet 230): 16 pt a step, weight by 5 lb or 2.5 kg, a tick per value.
enum NumberScroll {
    static let pointsPerStep: CGFloat = 16
    /// Weight steps by 5 (lb) or 2.5 (kg).
    static func weightStep(poundsUnit: Bool) -> Double {
        poundsUnit ? 5 : 2.5
    }

    /// The value after dragging `translation` points (negative up raises it) from `start`, in whole `step`s, held
    /// inside the range.
    static func value(start: Double, translation: CGFloat, step: Double, in range: ClosedRange<Double>) -> Double {
        guard step > 0, translation.isFinite else { return start }
        let steps = (-translation / pointsPerStep).rounded(.towardZero)
        return clamp(start + Double(steps) * step, step: step, in: range)
    }

    /// One step up or down (the accessibility adjustable action and the arrow keys).
    static func stepped(_ value: Double, by direction: Int, step: Double, in range: ClosedRange<Double>) -> Double {
        clamp(value + Double(direction) * step, step: step, in: range)
    }

    /// Held inside the range and on the step grid anchored at the range's lower bound.
    static func clamp(_ value: Double, step: Double, in range: ClosedRange<Double>) -> Double {
        let bounded = min(max(value, range.lowerBound), range.upperBound)
        guard step > 0 else { return bounded }
        let snapped = ((bounded - range.lowerBound) / step).rounded() * step + range.lowerBound
        return min(max(snapped, range.lowerBound), range.upperBound)
    }

    /// The dial's values: every step of the range.
    static func values(in range: ClosedRange<Double>, step: Double) -> [Double] {
        guard step > 0, range.upperBound >= range.lowerBound else { return [] }
        let count = Int(((range.upperBound - range.lowerBound) / step).rounded(.down))
        return (0 ... count).map { range.lowerBound + Double($0) * step }
    }
}
