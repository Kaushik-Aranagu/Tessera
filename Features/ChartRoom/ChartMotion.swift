import CoreGraphics
import Foundation

// The small pure timings the room's motion is built from (sheets 364, 372, 385), so they test without a screen.

/// Sheet 372: a restored room replays how it was made. His sentences go by, each setting its places with a short drying
/// line, in about 2.2 s from the door. A sentence that changed nothing is skipped, so the replay is the room's real
/// recipe and not a transcript.
enum ReplayPlan {
    /// The frame sketches in first (sheet 366's start).
    static let frameIn = 0.3
    /// A sentence's drying line, then the pause to the next (at full speed).
    static let dry = 0.24
    static let gap = 0.08
    /// The whole replay, from the door.
    static let total = 2.2

    struct Beat: Equatable {
        /// Which of the replayed steps this is (0 first).
        let index: Int
        /// Seconds after the door that its drying line starts.
        let start: Double
        let dry: Double
    }

    /// The indices of the documents that changed the room: a document equal to the one before it is skipped.
    static func changed(_ documents: [ChartDoc]) -> [Int] {
        var previous: ChartDoc?
        var out: [Int] = []
        for (index, document) in documents.enumerated() {
            if document != previous {
                out.append(index)
            }
            previous = document
        }
        return out
    }

    /// The beats for `count` replayed sentences: 240 ms of line and 80 ms to the next, sped up only as much as it takes
    /// to finish inside 2.2 s. Under Reduce Motion there are none: the room is there whole.
    static func timeline(count: Int, reduceMotion: Bool = false) -> [Beat] {
        guard count > 0, !reduceMotion else { return [] }
        let step = dry + gap
        let scale = min(1, (total - frameIn) / (Double(count) * step))
        return (0 ..< count).map { index in
            Beat(index: index, start: frameIn + Double(index) * step * scale, dry: dry * scale)
        }
    }

    /// When the replay ends (the last drying line done).
    static func end(count: Int, reduceMotion: Bool = false) -> Double {
        guard let last = timeline(count: count, reduceMotion: reduceMotion).last else { return 0 }
        return last.start + last.dry
    }
}

/// Sheet 385: the watered plant drinks. Its new colour climbs through its number and name from the foot like water up a
/// stem: a soft band a quarter of the glyph's height, fast at first, slower near the top (0.76 s). Undo sinks it back
/// in
/// from the top, evenly. Reduce Motion: the colour changes in place.
enum DrinkRun {
    static let seconds = 0.76
    /// The band's height as a share of the text's height.
    static let band: CGFloat = 0.25

    /// The cubic-bezier a run follows: up (0.25, 0.6, 0.3, 1), down (0.45, 0, 0.55, 1).
    static func ease(_ x: Double, up: Bool) -> Double {
        let t = min(max(x, 0), 1)
        let (x1, y1, x2, y2) = up ? (0.25, 0.6, 0.3, 1.0) : (0.45, 0.0, 0.55, 1.0)
        func bez(_ s: Double, _ a: Double, _ b: Double) -> Double {
            3 * (1 - s) * (1 - s) * s * a + 3 * (1 - s) * s * s * b + s * s * s
        }
        var low = 0.0, high = 1.0
        for _ in 0 ..< 30 {
            let mid = (low + high) / 2
            if bez(mid, x1, x2) < t {
                low = mid
            } else {
                high = mid
            }
        }
        return bez((low + high) / 2, y1, y2)
    }

    /// How far the waterline has climbed `time` seconds in (0 at the foot, 1 at the top); a sink counts from the top.
    static func progress(at time: Double, up: Bool, reduceMotion: Bool) -> Double {
        guard !reduceMotion else { return up ? 1 : 0 }
        let p = ease(time / seconds, up: up)
        return up ? p : 1 - p
    }

    /// The gradient's offset in text heights: it slides up by two text heights over the run.
    static func slide(progress: Double, textHeight: CGFloat) -> CGFloat {
        CGFloat(progress) * 2 * textHeight
    }
}

/// Sheet 364: the wine glow is its own state and follows the ranking after the move has settled, so it never travels
/// with the old leader. It hands over in the last 28% of the 520 ms move.
enum GlowFollow {
    static let move = 0.52
    /// The glow waits this long after the ranking changed.
    static let settle = move * 0.72

    /// Who glows `elapsed` seconds after the leader changed: the old owner until the move has settled, then the leader.
    static func owner(current: String?, leader: String?, elapsed: Double, reduceMotion: Bool) -> String? {
        reduceMotion || elapsed >= settle ? leader : current
    }
}
