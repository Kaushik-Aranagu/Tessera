import CoreGraphics
import SwiftUI

/// Sheet 366: when a blank Chart room opens, each empty place's dashed outline unrolls from its top-left corner, one
/// place after the next down the screen, 70 ms apart, starting 300 ms in (after the move in). Each place's name slides
/// in once its corner is drawn. No haptic. Under Reduce Motion the outlines are simply there. Pure, so it tests
/// without a screen.
enum OutlineUnroll {
    static let start = 0.3
    static let apart = 0.07
    /// How long one outline takes to draw all the way round.
    static let seconds = 0.45
    /// The name slides in once the corner is drawn.
    static let nameAfter = 0.12

    /// Places in the order they unroll: by y, then x.
    static func order(_ frames: [CGRect]) -> [Int] {
        frames.indices.sorted {
            (frames[$0].minY, frames[$0].minX) < (frames[$1].minY, frames[$1].minX)
        }
    }

    /// Seconds after opening that the place at `rank` (0 first) starts to draw; zero under Reduce Motion.
    static func delay(rank: Int, reduceMotion: Bool) -> Double {
        reduceMotion ? 0 : start + apart * Double(rank)
    }

    /// How much of the outline is drawn `time` seconds after opening (0 to 1, eased out); whole under Reduce Motion.
    static func trim(at time: Double, rank: Int, reduceMotion: Bool) -> Double {
        guard !reduceMotion else { return 1 }
        let p = min(max((time - delay(rank: rank, reduceMotion: false)) / seconds, 0), 1)
        return 1 - pow(1 - p, 3)
    }

    /// Whether the place's name has come in (its corner is drawn).
    static func nameShown(at time: Double, rank: Int, reduceMotion: Bool) -> Bool {
        reduceMotion || time >= delay(rank: rank, reduceMotion: false) + nameAfter
    }

    // MARK: Taking the room down (sheet 371): the unroll backwards

    /// When the outlines have all come back up (doors first) and the fold begins.
    static let foldStart = 0.4
    /// The whole take-down, for a room of `count` outlined places.
    static func downSeconds(count: Int) -> Double {
        foldStart + apart * Double(max(0, count - 1)) + seconds
    }

    /// Seconds after the take-down starts that the place at `rank` (0 the first down the screen, the title) starts to
    /// fold: the last place first, the title last. Zero under Reduce Motion (no fold at all).
    static func foldDelay(rank: Int, count: Int, reduceMotion: Bool) -> Double {
        reduceMotion ? 0 : foldStart + apart * Double(max(0, count - 1 - rank))
    }

    /// How much of the outline is still drawn `time` seconds into the take-down: the trim run from 1 back to 0.
    static func foldTrim(at time: Double, rank: Int, count: Int, reduceMotion: Bool) -> Double {
        guard !reduceMotion else { return 1 }
        let p = min(max((time - foldDelay(rank: rank, count: count, reduceMotion: false)) / seconds, 0), 1)
        return pow(1 - p, 3)
    }

    /// The SwiftUI animation of one place's unroll (the place's own delay inside it); the caller wraps it in
    /// MotionPolicy, which turns it into the short fade under Reduce Motion.
    static func animation(rank: Int) -> Animation {
        .timingCurve(0.2, 0.8, 0.2, 1, duration: seconds).delay(delay(rank: rank, reduceMotion: false))
    }
}

/// A rounded outline that starts at its top-left corner and runs clockwise, so `trim(from:to:)` unrolls it from there.
struct UnrollShape: Shape {
    var radius: CGFloat = 12

    func path(in rect: CGRect) -> Path {
        let r = min(radius, rect.width / 2, rect.height / 2)
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + r))
        path.addArc(center: CGPoint(x: rect.minX + r, y: rect.minY + r), radius: r, startAngle: .degrees(180),
                    endAngle: .degrees(270), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - r, y: rect.minY + r), radius: r, startAngle: .degrees(270),
                    endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        path.addArc(center: CGPoint(x: rect.maxX - r, y: rect.maxY - r), radius: r, startAngle: .degrees(0),
                    endAngle: .degrees(90), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.minX + r, y: rect.maxY - r), radius: r, startAngle: .degrees(90),
                    endAngle: .degrees(180), clockwise: false)
        path.closeSubpath()
        return path
    }
}
