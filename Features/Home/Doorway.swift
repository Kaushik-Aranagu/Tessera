import Observation
import SwiftUI

// Sheet 206 and 211: the pixel doorway. Opening an app from Home: from the tapped word (or the mosaic's centre) a wave
// spreads over the whole phone at 0.75 ms per point, plus up to 30 pt of hash jitter. Each 4 pt tile turns into the
// app's accent, flips (|cos|, 170 ms, its second half mixed 55% toward the page) and lands as the page's ground. When
// the wave has covered the screen the room opens underneath, and the same wave takes the tiles away. "‹ Home" runs it
// in reverse, back into the mosaic. The door tap's own haptic is the host's; the doorway plays none. Reduce Motion: a
// plain swap, no doorway.

enum DoorwayWave {
    static let step: CGFloat = 4
    static let secondsPerPoint = 0.00075
    static let jitterPoints: CGFloat = 30
    static let flipSeconds = 0.17
    /// The second half of the flip is mixed this far toward the page.
    static let secondHalfMix = 0.55
    /// A beat between the room opening underneath and the tiles going.
    static let settleSeconds = 0.05

    enum Tile: Equatable {
        /// Not reached yet: the screen as it is.
        case clear
        /// Turning into the accent, flipping: its height (|cos|) and how far toward the page it has gone.
        case flipping(scaleY: Double, towardGround: Double)
        /// Landed as the page's ground.
        case ground
        /// Being taken away, squashing to nothing: its height.
        case leaving(scaleY: Double)
    }

    /// A fixed 0 ... 1 for a tile: the same tile every time.
    static func jitter(column: Int, row: Int) -> Double {
        var value = UInt64(truncatingIfNeeded: column &* 73_856_093 ^ row &* 19_349_663)
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value ^= value >> 27
        return Double(value % 1000) / 1000
    }

    /// When the wave reaches a tile, in seconds from the start: its distance from the origin (the far corner first when
    /// `reverse`) at 0.75 ms per point, plus the tile's jitter.
    static func delay(column: Int, row: Int, origin: CGPoint, reach: CGFloat, reverse: Bool) -> Double {
        let centre = CGPoint(x: (CGFloat(column) + 0.5) * step, y: (CGFloat(row) + 0.5) * step)
        let distance = hypot(centre.x - origin.x, centre.y - origin.y)
        let along = reverse ? reach - distance : distance
        return (Double(along) + Double(jitterPoints) * jitter(column: column, row: row)) * secondsPerPoint
    }

    /// The farthest a tile can be from the origin on a screen of this size.
    static func reach(size: CGSize, origin: CGPoint) -> CGFloat {
        let far = CGPoint(
            x: origin.x < size.width / 2 ? size.width : 0,
            y: origin.y < size.height / 2 ? size.height : 0
        )
        return hypot(far.x - origin.x, far.y - origin.y)
    }

    /// When every tile has landed (the room opens then).
    static func coverSeconds(reach: CGFloat) -> Double {
        (Double(reach) + Double(jitterPoints)) * secondsPerPoint + flipSeconds
    }

    /// A tile's state `time` seconds after the start, with the room opening at `coverSeconds + settleSeconds`.
    static func tile(delay: Double, time: Double, openedAt: Double) -> Tile {
        if time < delay {
            return .clear
        }
        let flip = (time - delay) / flipSeconds
        if flip < 1 {
            let scale = abs(cos(Double.pi * flip))
            let toward = flip < 0.5 ? 0 : secondHalfMix + (1 - secondHalfMix) * (flip - 0.5) * 2
            return .flipping(scaleY: scale, towardGround: toward)
        }
        let leaving = (time - openedAt - delay) / flipSeconds
        if time < openedAt + delay {
            return .ground
        }
        if leaving < 1 {
            return .leaving(scaleY: 1 - leaving)
        }
        return .clear
    }

    /// The whole doorway's length: cover, settle, take away.
    static func totalSeconds(reach: CGFloat) -> Double {
        coverSeconds(reach: reach) + settleSeconds + (Double(reach) + Double(jitterPoints)) * secondsPerPoint
            + flipSeconds
    }
}

/// The doorway's controller: one at the root, asked by whatever opens or closes a room.
@MainActor @Observable
final class Doorway {
    struct Run {
        let start: Date
        let origin: CGPoint
        let accent: Color
        let reverse: Bool
        var navigated = false
        let navigate: () -> Void
    }

    private(set) var run: Run?

    var isRunning: Bool {
        run != nil
    }

    /// Plays the doorway from `origin` (global, the tapped word or the mosaic's centre) in `accent`; `navigate` opens
    /// (or
    /// closes) the room once the screen is covered. Under Reduce Motion, or with no room to show, it just navigates.
    func play(from origin: CGPoint, accent: Color, reverse: Bool = false, reduceMotion: Bool,
              navigate: @escaping () -> Void)
    {
        guard !reduceMotion, run == nil else {
            navigate()
            return
        }
        run = Run(start: .now, origin: origin, accent: accent, reverse: reverse, navigate: navigate)
    }

    /// Called by the overlay each frame: opens the room once, at the cover time; ends the run at the end.
    func advance(size: CGSize, now: Date) {
        guard var current = run else { return }
        let reach = DoorwayWave.reach(size: size, origin: current.origin)
        let time = now.timeIntervalSince(current.start)
        if !current.navigated, time >= DoorwayWave.coverSeconds(reach: reach) {
            current.navigated = true
            run = current
            current.navigate()
        }
        if time >= DoorwayWave.totalSeconds(reach: reach) {
            run = nil
        }
    }
}

/// Draws the doorway over the whole phone, one pass over the tiles the wave is crossing; the tiles already landed are
/// one fill. It takes every touch while it runs.
struct DoorwayOverlay: View {
    @Bindable var doorway: Doorway
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            if doorway.run != nil {
                TimelineView(.animation) { context in
                    Canvas { canvas, size in
                        draw(&canvas, size: size, now: context.date)
                    }
                    .onChange(of: context.date) { _, date in doorway.advance(size: geometry.size, now: date) }
                }
                .contentShape(Rectangle())
                .allowsHitTesting(true)
                .accessibilityHidden(true)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(doorway.run != nil)
    }

    private func draw(_ canvas: inout GraphicsContext, size: CGSize, now: Date) {
        guard let run = doorway.run else { return }
        let step = DoorwayWave.step
        let columns = Int((size.width / step).rounded(.up)), rows = Int((size.height / step).rounded(.up))
        let reach = DoorwayWave.reach(size: size, origin: run.origin)
        let time = now.timeIntervalSince(run.start)
        let opened = DoorwayWave.coverSeconds(reach: reach) + DoorwayWave.settleSeconds
        let ground = Theme.Colors.paper
        for column in 0 ..< columns {
            for row in 0 ..< rows {
                let delay = DoorwayWave.delay(column: column, row: row, origin: run.origin, reach: reach,
                                              reverse: run.reverse)
                let state = DoorwayWave.tile(delay: delay, time: time, openedAt: opened)
                let rect = CGRect(x: CGFloat(column) * step, y: CGFloat(row) * step, width: step, height: step)
                switch state {
                case .clear: continue
                case .ground:
                    canvas.fill(Path(rect), with: .color(ground))
                case let .flipping(scale, toward):
                    let height = step * scale
                    let tile = CGRect(x: rect.minX, y: rect.midY - height / 2, width: step, height: height)
                    canvas.fill(Path(tile), with: .color(run.accent.mix(with: ground, by: toward)))
                case let .leaving(scale):
                    let height = step * scale
                    let tile = CGRect(x: rect.minX, y: rect.midY - height / 2, width: step, height: height)
                    canvas.fill(Path(tile), with: .color(ground))
                }
            }
        }
    }
}

extension EnvironmentValues {
    /// Plays the doorway for a screen that opens or closes a room: its accent, whether it runs in reverse (back into
    /// the
    /// mosaic), and what to do once the screen is covered. The default just does it.
    @Entry var playDoorway: (_ accent: Color, _ reverse: Bool, _ navigate: @escaping () -> Void) -> Void = { _, _, go in
        go()
    }
}
