import SwiftUI
import TesseraCore

/// Watch's hand-over (283 v3): the keystone gives the widget its item. On arrival a little bird flies down from the
/// woods to the widget's glyph; when the item changes, a few petals drift down to it. Each is under 2.5 s and runs
/// once. Reduce Motion: nothing moves and nothing is drawn. It never takes a touch.
struct WatchHandOver: View {
    enum Kind: Equatable { case bird, petals }

    struct Moment: Equatable {
        let kind: Kind
        let at: Date
    }

    let moment: Moment

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme
    @State private var running = false

    /// Seconds each moment lasts.
    static func duration(_ kind: Kind) -> Double {
        kind == .bird ? 1.6 : 2.2
    }

    var body: some View {
        GeometryReader { proxy in
            let k = max(0.86, min(1.1, proxy.size.height / 874))
            if running, !reduceMotion {
                TimelineView(.animation(minimumInterval: 1 / 60)) { timeline in
                    let elapsed = timeline.date.timeIntervalSince(moment.at)
                    let p = max(0, min(1, elapsed / Self.duration(moment.kind)))
                    Canvas { context, _ in
                        let end = CGPoint(x: 338, y: (400 + 84) * k)
                        switch moment.kind {
                        case .bird: drawBird(&context, p: p, from: CGPoint(x: 150, y: 250 * k), to: end)
                        case .petals: drawPetals(&context, p: p, k: k, to: end)
                        }
                    }
                }
            }
        }
        .ignoresSafeArea(.container, edges: .top)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task(id: moment) {
            guard !reduceMotion else { return }
            running = true
            try? await Task.sleep(for: .seconds(Self.duration(moment.kind)))
            if !Task.isCancelled {
                running = false
            }
        }
    }

    /// Ease out with a little settle, like the house spring, as a pure curve for the drawing.
    static func ease(_ t: Double) -> Double {
        let x = max(0, min(1, t))
        return 1 - pow(1 - x, 3) + sin(x * .pi) * 0.04 * (1 - x)
    }

    /// A point on the bird's arc: up a little out of the woods, then down to the glyph.
    static func birdPoint(_ p: Double, from: CGPoint, to: CGPoint) -> CGPoint {
        let e = CGFloat(ease(p))
        let u: CGFloat = 1 - e
        let controlX: CGFloat = (from.x + to.x) / 2
        let controlY: CGFloat = min(from.y, to.y) - 40
        let a: CGFloat = u * u
        let b: CGFloat = 2 * u * e
        let c: CGFloat = e * e
        let x: CGFloat = a * from.x + b * controlX + c * to.x
        let y: CGFloat = a * from.y + b * controlY + c * to.y
        return CGPoint(x: x, y: y)
    }

    private func drawBird(_ context: inout GraphicsContext, p: Double, from: CGPoint, to: CGPoint) {
        let at = Self.birdPoint(p, from: from, to: to)
        let bird = Color(hex: scheme == .dark ? 0xD59AC4 : 0x8E4A78)
        let flap = sin(p * .pi * 10) * (1 - p) * 6
        var wing = Path()
        wing.move(to: CGPoint(x: at.x - 9, y: at.y - flap))
        wing.addQuadCurve(to: CGPoint(x: at.x, y: at.y), control: CGPoint(x: at.x - 5, y: at.y - 4 - flap))
        wing.addQuadCurve(to: CGPoint(x: at.x + 9, y: at.y - flap), control: CGPoint(x: at.x + 5, y: at.y - 4 - flap))
        context.stroke(wing, with: .color(bird), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
        context.fill(Path(ellipseIn: CGRect(x: at.x - 4, y: at.y - 2, width: 8, height: 6)), with: .color(bird))
    }

    private func drawPetals(_ context: inout GraphicsContext, p: Double, k: CGFloat, to: CGPoint) {
        let petal = Color(hex: scheme == .dark ? 0xF0BED5 : 0xD77FA1)
        for index in 0 ..< 7 {
            let seed = Double(index)
            let row = CGFloat(270 + (index % 3) * 18)
            let start = CGPoint(x: 70 + CGFloat(seed) * 40, y: row * k)
            let delay = seed * 0.06
            let local = max(0, min(1, (p - delay) / (1 - delay)))
            let e = CGFloat(Self.ease(local))
            let sway = CGFloat(sin(local * .pi * 3 + seed) * 8)
            let x: CGFloat = start.x + (to.x - start.x) * e + sway
            let y: CGFloat = start.y + (to.y - start.y) * e
            let fade = local > 0.8 ? (1 - local) / 0.2 : 1
            let rect = CGRect(x: -3.5, y: -2.2, width: 7, height: 4.4)
            let turn = CGAffineTransform(rotationAngle: local * 4 + seed).concatenating(.init(translationX: x, y: y))
            context.fill(Path(ellipseIn: rect).applying(turn), with: .color(petal.opacity(fade)))
        }
    }
}

/// Pause for today (the foot's Pause): kept on this phone only (UserDefaults), never in the op log, a backup or a
/// widget. It marks nothing missed and writes nothing to the routines log.
enum WatchPause {
    static let key = "watch.pausedDay"

    static func dayKey(_ day: Date) -> String {
        day.formatted(.iso8601.year().month().day())
    }

    static func isPaused(on day: Date, defaults: UserDefaults = .standard) -> Bool {
        defaults.string(forKey: key) == dayKey(day)
    }

    static func set(_ on: Bool, on day: Date, defaults: UserDefaults = .standard) {
        if on {
            defaults.set(dayKey(day), forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
}
