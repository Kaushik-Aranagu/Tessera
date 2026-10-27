import Foundation
import TesseraCore

// When and how the faces turn by themselves (Home 236). Pure rules, so the clock, the bias and the modes test without
// a screen.

/// The board's line clock: when its lines last flipped and how often they do. A face never turns in the same second as
/// a line flip, so two things never change under his eye at once.
struct LineClock: Equatable {
    var anchor: Date?
    var period: TimeInterval

    /// Whether `date` falls in the same whole second as a flip (the anchor plus a whole number of periods).
    func collides(_ date: Date) -> Bool {
        guard let anchor, period > 0 else { return false }
        let steps = ((date.timeIntervalSince(anchor)) / period).rounded()
        for step in [steps - 1, steps, steps + 1] where step >= 0 {
            let flip = anchor.addingTimeInterval(step * period)
            if Int(flip.timeIntervalSince1970.rounded(.down)) == Int(date.timeIntervalSince1970.rounded(.down)) {
                return true
            }
        }
        return false
    }

    /// `date`, moved on by whole seconds until it is clear of every flip.
    func clear(_ date: Date) -> Date {
        var out = date
        for _ in 0 ..< 4 where collides(out) {
            out = out.addingTimeInterval(1)
        }
        return out
    }
}

/// The page's one line clock: the sentence notes each flip, the faces read it.
@MainActor
enum MosaicLineClock {
    private(set) static var shared = LineClock(anchor: nil, period: HomeBoard.rotationSeconds)

    /// The board's rotation begins now, flipping every `period` seconds.
    static func start(at date: Date = AppClock.now, period: TimeInterval = HomeBoard.rotationSeconds) {
        shared = LineClock(anchor: date, period: period)
    }

    static func stop() {
        shared.anchor = nil
    }
}

enum MosaicTurnMode: Equatable {
    /// Faces turn only under his finger.
    case swipeOnly
    /// Faces turn by themselves, a random time inside `seconds` apart. `animated` is false for a plain swap.
    case auto(seconds: ClosedRange<Double>, animated: Bool, quiet: Bool)
}

enum MosaicTurnPolicy {
    /// A touch pauses auto-turn this long.
    static let touchPause: TimeInterval = 30
    static let normal: ClosedRange<Double> = 5 ... 10
    /// The gallery's own scene changes about this often when it is the only face.
    static let galleryScene: TimeInterval = 9
    /// A changeover (sheet 200) plays this long on an auto turn; a swipe slides.
    static let slideSeconds: TimeInterval = 0.26

    /// Reduce Motion: a plain swap every 10 s. Low Power: swipe only. Quiet hours: gallery and weather only, every
    /// 20 s. Low Power wins over the rest; Reduce Motion in quiet hours is a plain swap every 20 s.
    static func mode(reduceMotion: Bool, lowPower: Bool, quiet: Bool) -> MosaicTurnMode {
        if lowPower {
            return .swipeOnly
        }
        if quiet {
            return .auto(seconds: 20 ... 20, animated: !reduceMotion, quiet: true)
        }
        if reduceMotion {
            return .auto(seconds: 10 ... 10, animated: false, quiet: false)
        }
        return .auto(seconds: normal, animated: true, quiet: false)
    }

    /// Whether quiet hours let a face turn in by itself.
    static func allowed(_ face: MosaicFace, in mode: MosaicTurnMode) -> Bool {
        if case let .auto(_, _, quiet) = mode, quiet {
            return face.kind == .gallery || face.kind == .weather
        }
        return true
    }

    static func seconds(_ range: ClosedRange<Double>, using generator: inout some RandomNumberGenerator) -> Double {
        range.lowerBound == range.upperBound ? range.lowerBound : Double.random(in: range, using: &generator)
    }

    /// When the next turn fires: `interval` after `start`, never in the same second as a line flip.
    static func fireTime(after start: Date, interval: TimeInterval, line: LineClock) -> Date {
        line.clear(start.addingTimeInterval(interval))
    }

    /// Which face turns in next: nil with fewer than two to choose from. A live face gets two of every three turns
    /// (`turn` counts from 0: turns 0 and 1 go to a live face, turn 2 to a still one), each group in stack order after
    /// the current face.
    static func next(current: Int, faces: [MosaicFace], turn: Int, mode: MosaicTurnMode) -> Int? {
        let eligible = faces.indices.filter { $0 != current && allowed(faces[$0], in: mode) }
        guard !eligible.isEmpty else { return nil }
        let live = eligible.filter { faces[$0].isLive }
        let still = eligible.filter { !faces[$0].isLive }
        let wantsLive = turn % 3 != 2
        let pool = wantsLive ? (live.isEmpty ? still : live) : (still.isEmpty ? live : still)
        // The first of the pool after the current face, wrapping.
        return pool.first { $0 > current } ?? pool.first
    }

    /// The changeovers a turn plays (sheet 200): the board's flip, a wave, a fall, a gather. Never the same twice.
    static let changeovers: [MosaicChangeoverKind] = [
        .flip, .standard(.wave), .standard(.fall), .standard(.gather),
    ]

    static func changeover(after previous: Int?, using generator: inout some RandomNumberGenerator) -> Int {
        var pick = Int.random(in: 0 ..< changeovers.count, using: &generator)
        if pick == previous {
            pick = (pick + 1) % changeovers.count
        }
        return pick
    }

    // MARK: Swipe

    /// Whether letting go commits a swipe: past 35% of the face's width, or a real flick (GestureTuning.stackCommits).
    static func commits(travel: CGFloat, width: CGFloat, velocity: CGFloat) -> Bool {
        // The direction of the travel is the commit direction: the speed is signed to match.
        let sign: Double = travel < 0 ? -1 : 1
        return GestureTuning.stackCommits(travel: abs(Double(travel)), width: Double(width),
                                          velocity: Double(velocity) * sign)
    }
}
