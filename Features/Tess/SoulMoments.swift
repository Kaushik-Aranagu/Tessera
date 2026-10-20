import CoreMotion
import SwiftUI

/// The house curve (tess-motion.md): the same one the beat and the wake come back on.
enum SoulCurves {
    static let house = UnitCurve.bezier(startControlPoint: UnitPoint(x: 0.3, y: 0),
                                        endControlPoint: UnitPoint(x: 0.2, y: 1))

    /// 0...1 of `curve` over `duration` starting at `start`, for a time `elapsed` since the moment began.
    static func ramp(_ elapsed: Double, from start: Double, over duration: Double, _ curve: UnitCurve) -> Double {
        curve.value(at: min(max((elapsed - start) / duration, 0), 1))
    }
}

/// A move of the whole body that goes out, holds and comes back: the nudge's 4 pt lean (idea 7: out 400 ms ease-out,
/// held 1.3 s, back 500 ms on the house curve) and the peek's 5 pt rise (idea 9: 350 ms, 1.6 s, 500 ms). Pure.
struct SoulMove: Equatable {
    let out: Double
    let hold: Double
    let back: Double
    let distance: CGFloat

    static let lean = SoulMove(out: 0.4, hold: 1.3, back: 0.5, distance: 4)
    static let peek = SoulMove(out: 0.35, hold: 1.6, back: 0.5, distance: 5)

    var duration: Double {
        out + hold + back
    }

    /// 0...1: how far out she is `elapsed` seconds into the move.
    func amount(at elapsed: Double) -> CGFloat {
        guard elapsed >= 0, elapsed < duration else { return 0 }
        let going = SoulCurves.ramp(elapsed, from: 0, over: out, .easeOut)
        let returning = SoulCurves.ramp(elapsed, from: out + hold, over: back, SoulCurves.house)
        return CGFloat(going * (1 - returning))
    }
}

/// She hears him type (idea 8): one pulse, scale +0.06 over 80 ms and back over 250 ms. Pure.
enum SoulPulse {
    static let rise = 0.08
    static let fall = 0.25
    static let swell: CGFloat = 0.06
    /// At most one pulse per 180 ms (faster typing merges); Low Power at most every 400 ms.
    static let gap = 0.18
    static let lowPowerGap = 0.4

    static func amount(at elapsed: Double) -> CGFloat {
        guard elapsed >= 0, elapsed < rise + fall else { return 0 }
        let up = SoulCurves.ramp(elapsed, from: 0, over: rise, .easeOut)
        let down = SoulCurves.ramp(elapsed, from: rise, over: fall, .easeOut)
        return CGFloat(up * (1 - down))
    }
}

/// She sleeps at night (idea 5). Asleep: lids at 0.25 and no blink. When he opens the app the right eye opens first
/// (250 ms after the page arrives, over 350 ms, glancing 0.4 left and 0.3 up) and the left follows 2.4 s later over
/// 400 ms. Left alone for 60 s she drifts back to sleep over 3 s. Pure, from the seconds since each began.
enum SoulSleep {
    static let shut: CGFloat = 0.25
    static let rightStart = 0.25
    static let rightOver = 0.35
    static let leftGap = 2.4
    static let leftOver = 0.4
    static let idleBeforeSleep = 60.0
    static let driftOver = 3.0
    /// The saturation she loses, and the scale she keeps, while asleep (the resting look carries them).
    static let saturation: CGFloat = -0.35
    static let scale: CGFloat = 0.92
    /// Opening the eyes takes this long in all.
    static var opening: Double {
        rightStart + leftGap + leftOver
    }

    /// Lids (1 open, 0.25 shut) `elapsed` seconds after he opened the app. `quiet` (Reduce Motion, Low Power): the
    /// same moments as 200 ms crossfades instead of eye opens.
    static func lids(opening elapsed: Double, quiet: Bool = false) -> (left: CGFloat, right: CGFloat) {
        func lid(start: Double, over: Double) -> CGFloat {
            let duration = quiet ? 0.2 : over
            let phase = SoulCurves.ramp(elapsed, from: start, over: duration, quiet ? .linear : .easeInOut)
            return shut + (1 - shut) * CGFloat(phase)
        }
        return (lid(start: rightStart + leftGap, over: leftOver), lid(start: rightStart, over: rightOver))
    }

    /// Back to sleep: both lids close over 3 s.
    static func lids(drifting elapsed: Double) -> (left: CGFloat, right: CGFloat) {
        let lid = 1 - (1 - shut) * CGFloat(SoulCurves.ramp(elapsed, from: 0, over: driftOver, .easeInOut))
        return (lid, lid)
    }

    /// The glance while the right eye is open alone: 0.4 left, 0.3 up; ahead again once the left opens.
    static func glance(opening elapsed: Double) -> SoulGaze {
        elapsed >= rightStart && elapsed < rightStart + leftGap ? .look(x: -0.4, y: -0.3) : .ahead
    }
}

/// Lights that follow the page (idea 1): the three readers go to the words the ask touches, in the job's order. A hop
/// of 340 ms on the house curve with a 10 pt arc up, then a dwell of 380 ms that sweeps +-45% of the word's width.
/// They never visit the same word twice in a row, and start over at the first after the last. Pure.
enum SoulReaders {
    static let hop = 0.34
    static let dwell = 0.38
    static let arc: CGFloat = 10
    static let sweep: CGFloat = 0.45
    static var step: Double {
        hop + dwell
    }

    /// Which of `count` words reader `reader` is on during step `step` (the readers start on different words).
    static func word(step: Int, reader: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return ((step + reader) % count + count) % count
    }

    /// The step a time falls in, and where in it (hopping, then dwelling).
    static func phase(at time: Double) -> (step: Int, local: Double) {
        let index = max(Int(time / step), 0)
        return (index, time - Double(index) * step)
    }

    /// Where reader `reader` is at `time` seconds after the working state began, on the page's word rects (in the
    /// soul's own points, from her centre). With fewer than two words there is nothing to follow: nil, and she falls
    /// back to the sweep of the rows she reads.
    static func position(words: [CGRect], reader: Int, time: Double) -> CGPoint? {
        guard words.count >= 2 else { return nil }
        let (index, local) = phase(at: time)
        let target = words[word(step: index, reader: reader, count: words.count)]
        let start = CGPoint(x: target.midX - sweep * target.width, y: target.midY)
        if local >= hop {
            let along = CGFloat((local - hop) / dwell)
            return CGPoint(x: start.x + 2 * sweep * target.width * along, y: target.midY)
        }
        let previous = words[word(step: index - 1, reader: reader, count: words.count)]
        let from = CGPoint(x: previous.midX + sweep * previous.width, y: previous.midY)
        let phase = CGFloat(SoulCurves.ramp(local, from: 0, over: hop, SoulCurves.house))
        let lift = arc * CGFloat(sin(Double.pi * Double(phase)))
        return CGPoint(x: from.x + (start.x - from.x) * phase, y: from.y + (start.y - from.y) * phase - lift)
    }

    /// The word reader `reader` rests on at `time`, for tests and for the dwell's rect.
    static func dwellingWord(reader: Int, time: Double, count: Int) -> Int {
        word(step: phase(at: time).step, reader: reader, count: count)
    }
}

/// The dock lights' seeded drift (idea 1): three summed sines per axis per light, periods 3.5 to 9.5 s, about +-1 pt
/// in all, seeded per working state so no two runs match. Low Power holds them still.
enum SoulNoise {
    static func offset(light: Int, time: Double, seed: UInt64) -> CGPoint {
        func axis(_ axis: UInt64) -> CGFloat {
            var total = 0.0
            for part in 0 ..< 3 {
                let key = seed &* 0x9E37_79B9_7F4A_7C15 &+ UInt64(light) &* 7919 &+ axis &* 104_729 &+ UInt64(part) &*
                    31
                let period = 3.5 + 6 * unit(key)
                let phase = 2 * Double.pi * unit(key &+ 1)
                total += sin(2 * Double.pi * time / period + phase) / 3
            }
            return CGFloat(total)
        }
        return CGPoint(x: axis(1), y: axis(2))
    }

    static func unit(_ seed: UInt64) -> Double {
        var value = seed &+ 0x1234_5678
        value ^= value >> 30
        value &*= 0xBF58_476D_1CE4_E5B9
        value ^= value >> 27
        value &*= 0x94D0_49BB_1331_11EB
        value ^= value >> 31
        return Double(value % 1_000_000) / 1_000_000
    }
}

/// She sits under the glass (idea 11): the phone's attitude moves her a little, like paint under a pane. 30 Hz,
/// low-passed at 0.15, only while the app is in front and her page is on screen, and never while Reduce Motion or Low
/// Power is on. The numbers are pure so they can be tested; `SoulTilt` is only the plumbing around Core Motion.
enum SoulTiltMath {
    static let hertz = 30.0
    static let smoothing: CGFloat = 0.15
    /// The mains shift up to 2 pt across and 1.4 pt down or up, the satellites 1.7 times that, the eyes look 0.6 / 0.4.
    static let mainsX: CGFloat = 2
    static let mainsY: CGFloat = 1.4
    static let satelliteShare: CGFloat = 1.7
    static let eyesX: CGFloat = 0.6
    static let eyesY: CGFloat = 0.4
    /// Flat on a table: within 3 degrees of flat for 2 s, there is nothing to look under.
    static let flatDegrees = 3.0
    static let flatSeconds = 2.0
    /// Held upright and a little back, gravity runs 0.7 down the screen.
    static let neutralDown: CGFloat = 0.7

    /// The look vector (-1...1 each way) for a gravity reading in the device's frame.
    static func vector(gravityX: Double, gravityY: Double) -> CGSize {
        let across = min(max(CGFloat(gravityX) * 2.5, -1), 1)
        let down = min(max((CGFloat(-gravityY) - neutralDown) * 3.3, -1), 1)
        return CGSize(width: across, height: down)
    }

    static func lowPassed(_ previous: CGSize, toward sample: CGSize) -> CGSize {
        CGSize(width: previous.width + (sample.width - previous.width) * smoothing,
               height: previous.height + (sample.height - previous.height) * smoothing)
    }

    /// Whether a gravity reading is within 3 degrees of flat (face up or down).
    static func isFlat(gravityZ: Double) -> Bool {
        abs(gravityZ) >= cos(flatDegrees * .pi / 180)
    }

    static func mainsShift(_ vector: CGSize) -> CGPoint {
        CGPoint(x: vector.width * mainsX, y: vector.height * mainsY)
    }

    static func eyesLook(_ vector: CGSize) -> CGSize {
        CGSize(width: vector.width * eyesX, height: vector.height * eyesY)
    }

    /// Applies the tilt to a frame's dabs: the mains by `mainsShift`, the satellites 1.7 times that. `hostScale` is
    /// how much the host draws her smaller, so the shift is in screen points.
    static func shifted(_ frame: SoulFrame, vector: CGSize, hostScale: CGFloat) -> SoulFrame {
        guard vector != .zero, hostScale > 0 else { return frame }
        let shift = mainsShift(vector)
        var result = frame
        for index in result.dabs.indices {
            let share = index < 3 ? 1 : satelliteShare
            result.dabs[index].x += shift.x * share / hostScale
            result.dabs[index].y += shift.y * share / hostScale
        }
        return result
    }
}

/// Core Motion plumbing for the tilt: one instance, read each frame by the soul (never observed, so 30 updates a
/// second don't re-render the chrome). It runs only when `shouldRun` says so.
@MainActor
final class SoulTilt {
    static let shared = SoulTilt()

    /// The low-passed look vector; zero when nothing is running or she is on a table.
    private(set) var vector = CGSize.zero
    private let manager = CMMotionManager()
    private var flatSince: Date?
    private var demoStart: Date?
    private(set) var isRunning = false

    /// Reduce Motion and Low Power never run it (Product).
    static func shouldRun(reduceMotion: Bool, lowPower: Bool, inForeground: Bool) -> Bool {
        !reduceMotion && !lowPower && inForeground
    }

    func update(reduceMotion: Bool, lowPower: Bool, inForeground: Bool) {
        if Self.shouldRun(reduceMotion: reduceMotion, lowPower: lowPower, inForeground: inForeground) {
            start()
        } else {
            stop()
        }
    }

    func start() {
        guard !isRunning else { return }
        // The simulator has no motion: `-tiltDemo` feeds a slow synthetic roll so a recording can show it.
        if LaunchFlags.has("-tiltDemo") {
            isRunning = true
            demoStart = .now
            Task { @MainActor [weak self] in
                while let self, isRunning, let demoStart {
                    let time = Date.now.timeIntervalSince(demoStart)
                    vector = SoulTiltMath.lowPassed(vector, toward: CGSize(width: sin(time / 1.1),
                                                                           height: 0.7 * cos(time / 1.6)))
                    try? await Task.sleep(for: .seconds(1 / SoulTiltMath.hertz))
                }
            }
            return
        }
        guard manager.isDeviceMotionAvailable else { return }
        isRunning = true
        manager.deviceMotionUpdateInterval = 1 / SoulTiltMath.hertz
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let motion else { return }
            let gravity = motion.gravity
            MainActor.assumeIsolated { self?.consume(gravityX: gravity.x, gravityY: gravity.y, gravityZ: gravity.z) }
        }
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        manager.stopDeviceMotionUpdates()
        demoStart = nil
        flatSince = nil
        vector = .zero
    }

    private func consume(gravityX: Double, gravityY: Double, gravityZ: Double) {
        let now = Date.now
        var target = SoulTiltMath.vector(gravityX: gravityX, gravityY: gravityY)
        if SoulTiltMath.isFlat(gravityZ: gravityZ) {
            flatSince = flatSince ?? now
            if now.timeIntervalSince(flatSince ?? now) >= SoulTiltMath.flatSeconds {
                target = .zero
            }
        } else {
            flatSince = nil
        }
        vector = SoulTiltMath.lowPassed(vector, toward: target)
    }
}

/// Starts and stops the tilt with the app in front, and never under Reduce Motion or Low Power (Product).
private struct SoulTiltDriver: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var lowPower = PowerState.isLowPower

    func body(content: Content) -> some View {
        content
            .onChange(of: reduceMotion, initial: true) { apply() }
            .onChange(of: scenePhase) { apply() }
            .onChange(of: lowPower) { apply() }
            .onReceive(PowerState.changes) { _ in lowPower = PowerState.isLowPower }
            .onDisappear { SoulTilt.shared.stop() }
    }

    private func apply() {
        SoulTilt.shared.update(reduceMotion: reduceMotion, lowPower: lowPower, inForeground: scenePhase == .active)
    }
}

extension View {
    func soulTiltDriver() -> some View {
        modifier(SoulTiltDriver())
    }
}

/// Emits `reachedEnd` once the page's scroll gets within 8 pt of its last row (idea 9), and `pageLeft` when the page
/// goes, so coming back gives another peek. Vertical scrolling only; a page that fits its screen never peeks.
private struct SoulReachesEnd: ViewModifier {
    let page: String
    @Environment(AppModel.self) private var model

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: Bool.self) { geometry in
                let end = geometry.contentSize.height + geometry.contentInsets.bottom
                let seen = geometry.contentOffset.y + geometry.containerSize.height
                return end > geometry.containerSize.height + 8 && seen >= end - 8
            } action: { _, atEnd in
                if atEnd {
                    model.soul.handle(.reachedEnd(page: page))
                }
            }
            .onDisappear { model.soul.handle(.pageLeft(page: page)) }
    }
}

/// Emits `rowLifted` / `rowMoved` / `rowDropped` for a row of a reorderable list while it is held (idea 6).
private struct SoulHeldRow: ViewModifier {
    let isHeld: Bool
    @Environment(AppModel.self) private var model
    @State private var y: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).midY } action: { newValue in
                y = newValue
                if isHeld {
                    model.soul.handle(.rowMoved(y: newValue))
                }
            }
            .onChange(of: isHeld) { _, held in
                model.soul.handle(held ? .rowLifted(y: y) : .rowDropped)
            }
    }
}

extension View {
    /// A scrolling page that gives Tess her peek at the end of its list.
    func soulReachesEnd(_ page: String) -> some View {
        modifier(SoulReachesEnd(page: page))
    }

    /// A row of a reorderable list: while `isHeld` Tess's eyes follow it.
    func soulHeldRow(isHeld: Bool) -> some View {
        modifier(SoulHeldRow(isHeld: isHeld))
    }
}
