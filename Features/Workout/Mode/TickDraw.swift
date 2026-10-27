import SwiftUI

/// The tick drawn on in the set row when a rest ends (sheet 348): the short stroke takes the first third of the path
/// and
/// the long stroke the rest; the whole tick takes 260 ms and starts 380 ms after the rest ends, so it lands as the
/// eraser
/// (338) passes. With Reduce Motion the tick appears without being drawn. This is the pure part.
enum TickDraw {
    static let duration = 0.26
    static let delay = 0.38
    /// The short stroke's share of the path; the long stroke has the rest.
    static let shortShare = 1.0 / 3.0

    /// The tick's drawn fraction (0 to 1, linear) `elapsed` seconds after the rest ended.
    static func progress(elapsed: TimeInterval) -> Double {
        min(max((elapsed - delay) / duration, 0), 1)
    }

    /// How much of the short stroke shows at an overall `progress`.
    static func short(at progress: Double) -> Double {
        min(max(progress / shortShare, 0), 1)
    }

    /// How much of the long stroke shows at an overall `progress`.
    static func long(at progress: Double) -> Double {
        min(max((progress - shortShare) / (1 - shortShare), 0), 1)
    }

    /// The tick's two strokes in a unit square: the short stroke down to the right, then the long stroke up to the
    /// right.
    static let corner = CGPoint(x: 0.36, y: 0.88)
    static let start = CGPoint(x: 0.08, y: 0.56)
    static let end = CGPoint(x: 0.94, y: 0.12)

    /// The short stroke's share of the path's length, which should be about a third.
    static var drawnShortShare: Double {
        let short = hypot(corner.x - start.x, corner.y - start.y)
        let long = hypot(end.x - corner.x, end.y - corner.y)
        return Double(short / (short + long))
    }
}

/// The tick as one continuous path (short stroke then long), so trimming it by a progress draws the short stroke
/// through its first third and the long stroke through the rest.
struct TickShape: Shape {
    func path(in rect: CGRect) -> Path {
        func point(_ unit: CGPoint) -> CGPoint {
            CGPoint(x: rect.minX + unit.x * rect.width, y: rect.minY + unit.y * rect.height)
        }
        var path = Path()
        path.move(to: point(TickDraw.start))
        path.addLine(to: point(TickDraw.corner))
        path.addLine(to: point(TickDraw.end))
        return path
    }
}

/// The tick at a drawn `progress`. The slot is always its full size, so drawing it never moves the set row.
struct DrawnTick: View {
    var progress: Double
    var color: Color = Chalk.white

    var body: some View {
        TickShape()
            .trim(from: 0, to: progress)
            .stroke(color, style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
            .frame(width: 16, height: 14)
            .accessibilityHidden(true)
    }
}
