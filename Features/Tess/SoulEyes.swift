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

/// The blink: lids close and open over 130 ms (height to 0.25 and back, ease-in-out), one every 2.4 to 6.6 s at random,
/// about one in five (18%) a double (blink, 250 ms, blink). Pure and seeded by the interval, so a frame at any time is
/// the same
/// frame (and testable).
enum SoulBlink {
    static let duration = 0.13
    static let doubleGap = 0.25
    /// The schedule repeats every hour; the last blink ends well before the wrap, so none is cut short.
    static let period = 3600.0

    /// Each blink's start and whether it's a double, over one period (seeded, built once).
    static let schedule: [(start: Double, isDouble: Bool)] = {
        var result: [(Double, Bool)] = []
        var time = 0.0
        var index: UInt64 = 0
        while true {
            time += 2.4 + 4.2 * unit(index)
            let isDouble = unit(index &+ 7919) < 0.18
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

/// Her mouth (sheet 215 rev 19, F5): only three meanings. A smile when she did what he asked, a gentle slant while she
/// waits on his answer, a small "oh" when something new arrives beside her on Home. One fine line in her eye ink; it
/// draws out from its middle, never fades, never while she speaks or listens, and no lip sync.
enum SoulMouth: Equatable {
    case smile, slant, oh

    /// How long it stays: a slant stays until she is answered (nil).
    var seconds: Double? {
        switch self {
        case .smile: 1.1
        case .oh: 0.8
        case .slant: nil
        }
    }

    /// How far it is drawn out (0 ... 1): out from the middle in 150 ms, back in over the last 150 ms.
    func drawn(since: Double) -> Double {
        guard since >= 0 else { return 0 }
        let out = min(since / 0.15, 1)
        guard let seconds else { return out }
        guard since < seconds else { return 0 }
        return min(out, (seconds - since) / 0.15, 1)
    }
}

/// The mouth's line: a smile's arc, a slant's gentle tilt (up to the right, never a frown), an "oh"'s small ring.
struct SoulMouthShape: Shape {
    var kind: SoulMouth
    var drawn: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let mid = CGPoint(x: rect.midX, y: rect.midY)
        // Out from the middle: both ends start at the centre.
        let half = rect.width / 2 * drawn
        switch kind {
        case .smile:
            path.move(to: CGPoint(x: mid.x - half, y: mid.y - 0.3 * drawn))
            path.addQuadCurve(to: CGPoint(x: mid.x + half, y: mid.y - 0.3 * drawn),
                              control: CGPoint(x: mid.x, y: mid.y + 2.4 * drawn))
        case .slant:
            path.move(to: CGPoint(x: mid.x - half * 0.8, y: mid.y + 0.7 * drawn))
            path.addLine(to: CGPoint(x: mid.x + half * 0.8, y: mid.y - 0.5 * drawn))
        case .oh:
            let width = 2.4 * drawn, height = 2.9 * drawn
            path.addEllipse(in: CGRect(x: mid.x - width / 2, y: mid.y - height / 2, width: width, height: height))
        }
        return path
    }
}

/// Two ink dots on the soul (§1): 4.2 × 4.6 pt ovals (1.3x), 8.4 pt apart, 3 pt above the mean of the three main dabs,
/// in the look's dark colour (ink on light looks, ground on dark ones), normal blend, over the soul. Her life (sheet
/// 215 rev 6) moves them: glances, blinks, the lean and float of her body, a finger's pull, a touch's widening and the
/// smile arcs after she has done something.
struct SoulEyes: View {
    let frame: SoulFrame
    let time: Double
    let gaze: SoulGaze
    let color: Color
    /// Reduce Motion: the blink stays, the dots sit still.
    var still = false
    /// A lid from a moment of hers (the wake) in place of the blink schedule.
    var lid: CGFloat?
    /// A finger or drag near her, as a direction (-1 ... 1 each way) the eyes follow.
    var attention: CGPoint?
    /// A reaction and the reference-time second it began.
    var reaction: (kind: SoulLife.Reaction, start: Double)?
    /// Light looks draw the eyes as one solid tone; dark ones keep them a little soft.
    var solid = true
    /// Quiet: her eyes are closed (a soft downward curve each).
    var closed = false
    /// Her mouth, when she has one (never while she speaks or listens: the host leaves it nil then).
    var mouth: (kind: SoulMouth, start: Double)?

    static let size = CGSize(width: 3.2 * 1.3, height: 3.5 * 1.3)
    /// How much the host draws her (0.7 of the board on the phone, sheet 215 rev 21): the eyes stay at least 3 pt
    /// across and
    /// the mouth's line at least 1 pt on screen.
    var displayScale: CGFloat = 0.7

    func eyeSize(unit: CGFloat) -> CGSize {
        let width = max(Self.size.width, 3 / max(unit * displayScale, 0.01))
        return CGSize(width: width, height: width * Self.size.height / Self.size.width)
    }

    func mouthWidth(unit: CGFloat) -> CGFloat {
        max(1.05 * 1.3, 1 / max(unit * displayScale, 0.01))
    }

    /// Where the pair sits, in the canvas's points from its centre: the main dabs' mean, 3 pt above it, both scaled
    /// by the soul's drawn scale (the same transform `SoulRenderer` applies to the dabs).
    static func centre(of frame: SoulFrame) -> CGPoint {
        let mains = frame.dabs.prefix(3)
        let count = CGFloat(max(mains.count, 1))
        let unit = frame.look.scale / SoulCloud.referenceScale
        return CGPoint(x: mains.reduce(0) { $0 + $1.x } / count * unit,
                       y: (mains.reduce(0) { $0 + $1.y } / count - 3) * unit)
    }

    /// The offset of the pair for a scripted gaze, a finger, or her own glances when she looks straight ahead.
    static func glance(gaze: SoulGaze, attention: CGPoint?, time: Double) -> CGSize {
        if let attention {
            return CGSize(width: attention.x * 3, height: attention.y * 2.2)
        }
        return gaze == .ahead ? SoulLife.offset(at: time) : gaze.offset
    }

    var body: some View {
        let centre = Self.centre(of: frame)
        let scale = frame.look.scale / SoulCloud.referenceScale
        let lid = lid ?? (still ? SoulBlink.lid(at: time) : SoulLife.lid(at: time))
        let glance = still ? .zero : Self.glance(gaze: gaze, attention: attention, time: time)
        let body = still ? .zero : SoulLife.lean(at: time)
        let float = still ? 0 : SoulLife.float(at: time)
        let since = reaction.map { time - $0.start }
        let widen = !still && reaction?.kind == .touch ? SoulLife.widen(since: since ?? 99) : 1
        let smile = switch reaction?.kind {
        case .did: SoulLife.smile(since: since ?? 99)
        case .drink: SoulLife.smile(since: since ?? 99, seconds: SoulLife.drinkSmileSeconds)
        default: 0.0
        }
        let eyes = eyeSize(unit: scale)
        let mouthDrawn = mouth.map { $0.kind.drawn(since: still ? 99 : time - $0.start) } ?? 0
        let stillMouth = still ? (mouth != nil ? 1.0 : 0) : mouthDrawn
        ZStack {
            HStack(spacing: 8.4 - eyes.width) {
                eye(lid, widen: widen, smile: smile, size: eyes)
                eye(lid, widen: widen, smile: smile, size: eyes)
            }
            if let mouth, stillMouth > 0.001 {
                // 2.6 pt below her centre (the eyes sit 3 pt above it); 1.05 pt at 1.3x.
                SoulMouthShape(kind: mouth.kind, drawn: stillMouth)
                    .stroke(color, style: StrokeStyle(lineWidth: mouthWidth(unit: scale), lineCap: .round))
                    .frame(width: 8, height: 4)
                    .offset(y: 5.6)
            }
        }
        // Scaled first, then placed: the offset is already in screen points (no second scale).
        .scaleEffect(scale)
        .offset(x: centre.x + (glance.width + body.width) * scale,
                y: centre.y + (glance.height + body.height + float) * scale)
        .opacity(frame.look.opacity)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func eye(_ lid: CGFloat, widen: CGFloat, smile: Double, size: CGSize) -> some View {
        let width = size.width * widen, height = size.height * widen
        let tone = color.opacity(solid ? 1 : 0.82)
        return ZStack {
            if closed {
                SleepArc()
                    .stroke(tone, style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
                    .frame(width: width, height: height * 0.4)
            }
            Ellipse()
                .fill(tone)
                .frame(width: width, height: height * lid * (1 - smile))
                .opacity(closed ? 0 : 1)
            if smile > 0 {
                SmileArc()
                    .stroke(tone, style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
                    .frame(width: width, height: height * 0.5)
                    .opacity(smile)
            }
        }
        .frame(width: size.width * 1.25, height: size.height * 1.25)
    }
}

/// An upward arc, a closed eye smiling.
struct SmileArc: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.minY - rect.height * 0.6)
        )
        return path
    }
}

/// A closed eye: a soft curve, downward in the middle.
struct SleepArc: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY), control: CGPoint(x: rect.midX, y: rect.maxY * 1.6))
        return path
    }
}
