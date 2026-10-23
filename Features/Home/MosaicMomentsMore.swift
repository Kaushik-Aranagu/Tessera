import Foundation
import TesseraCore

// Three more moments (sheet 201, Design's 7 AM addition): a new best, a reminder that knocks, a parcel at the door.

extension MosaicMomentField {
    /// An app's accent, or ink when the moment has none.
    static func accent(_ app: AppID?, _ context: MosaicMoodContext) -> MosaicTriple {
        app.flatMap { context.accents[$0] } ?? context.ink
    }

    // MARK: A new best

    /// Seven Training steps of 5 x 2 tiles, each 3 rows above the last and 5 columns along, centred in the window.
    static func bestStep(_ step: Int, cols: Int, rows: Int) -> (columns: Range<Int>, rows: ClosedRange<Int>) {
        let left = (cols - 35) / 2 + step * 5
        let bottom = rows - 5 - step * 3
        return (left ..< left + 5, (bottom - 1) ... bottom)
    }

    /// The plus-shaped star above the last step: its centre, and whether a tile is one of its four arms.
    static func bestStarCentre(cols: Int, rows: Int) -> (column: Int, row: Int) {
        let last = bestStep(6, cols: cols, rows: rows)
        return (last.columns.lowerBound + 2, max(last.rows.lowerBound - 4, 2))
    }

    /// How many steps are showing at `elapsed` seconds: one every 120 ms.
    static func bestSteps(at elapsed: TimeInterval) -> Int {
        guard elapsed >= 0 else { return 0 }
        return min(7, Int(elapsed / 0.12) + 1)
    }

    /// Whether the star shows: after the steps, 180 ms on and 180 ms off.
    static func bestStarOn(at elapsed: TimeInterval) -> Bool {
        let after = elapsed - 7 * 0.12
        guard after >= 0 else { return false }
        return after.truncatingRemainder(dividingBy: 0.36) < 0.18
    }

    static func bestLight(
        cols: Int,
        rows: Int,
        start: TimeInterval,
        context: MosaicMoodContext,
        still: Bool
    ) -> MosaicMoodField.Overlay {
        let accent = context.trainingAccent
        let warm: MosaicTriple = (1, 0.97, 0.86)
        let arm = MosaicColour.mix(accent, (1, 1, 1), 0.55)
        let star = bestStarCentre(cols: cols, rows: rows)
        return { column, row, time, colour in
            let elapsed = still ? 99 : time - start
            for step in 0 ..< bestSteps(at: elapsed) {
                let area = bestStep(step, cols: cols, rows: rows)
                if area.columns.contains(column), area.rows.contains(row) {
                    return accent
                }
            }
            guard bestStarOn(at: elapsed) || still else { return colour }
            if column == star.column, row == star.row {
                return warm
            }
            if abs(column - star.column) + abs(row - star.row) == 1 {
                return arm
            }
            return colour
        }
    }

    // MARK: A reminder

    /// The window knocks three times: dx up to 2 pt, 110 ms each at 300, 560 and 820 ms.
    static let knockStarts: [TimeInterval] = [0.30, 0.56, 0.82]

    static func reminderShake(time: TimeInterval) -> Double {
        for knock in knockStarts where time >= knock && time < knock + 0.11 {
            return 2 * sin(Double.pi * (time - knock) / 0.11)
        }
        return 0
    }

    /// The band's strength: full on each knock, then held at 70% once the last has landed.
    static func reminderBand(at elapsed: TimeInterval) -> Double {
        if let last = knockStarts.last, elapsed >= last + 0.11 {
            return 0.7
        }
        for knock in knockStarts where elapsed >= knock && elapsed < knock + 0.11 {
            return 1
        }
        return 0
    }

    /// A 2-column band just inside the right edge lights in the app's accent.
    static func reminderLight(
        cols: Int,
        start: TimeInterval,
        accent: MosaicTriple,
        still: Bool
    ) -> MosaicMoodField.Overlay {
        { column, _, time, colour in
            guard column == cols - 3 || column == cols - 2 else { return colour }
            let strength = still ? 0.7 : reminderBand(at: time - start)
            return strength > 0 ? MosaicColour.mix(colour, accent, strength) : colour
        }
    }

    // MARK: A parcel at the door

    /// The parcel's left column at `elapsed` seconds: it slides in from the right over 900 ms, ease-out.
    static func parcelLeft(at elapsed: TimeInterval, cols: Int) -> Int {
        let rest = cols - 9 - 6
        let progress = min(max(elapsed / 0.9, 0), 1)
        return rest + Int((Double(cols - rest) * pow(1 - progress, 3)).rounded())
    }

    /// One row up for 150 ms as it lands.
    static func parcelBump(at elapsed: TimeInterval) -> Int {
        elapsed >= 0.9 && elapsed < 1.05 ? 1 : 0
    }

    /// A 9 x 7 parcel: an accent outline, a centre tape column, the fill 55% toward the ground; two dust tiles
    /// behind it as it lands.
    static func deliveryLight(
        cols: Int,
        rows: Int,
        start: TimeInterval,
        ground: MosaicTriple,
        accent: MosaicTriple,
        still: Bool
    ) -> MosaicMoodField.Overlay {
        let fill = MosaicColour.mix(accent, ground, 0.55)
        let top = rows - 4 - 7
        return { column, row, time, colour in
            let elapsed = still ? 99 : time - start
            let left = parcelLeft(at: elapsed, cols: cols)
            let local = column - left
            let y = row - (top - (still ? 0 : parcelBump(at: elapsed)))
            if local >= 0, local < 9, y >= 0, y < 7 {
                if local == 0 || local == 8 || y == 0 || y == 6 || local == 4 {
                    return accent
                }
                return fill
            }
            if !still, elapsed >= 0.9, elapsed < 1.7, row == top + 6, local == -1 || local == -3 {
                return MosaicColour.mix(colour, accent, 0.35)
            }
            return colour
        }
    }
}
