// swiftlint:disable identifier_name
import CoreGraphics
import SwiftUI

// Sheet 296, things in flight. A move can carry a copy across other places (a word from the Log wall to the widget,
// a ticket off the Galley rail into the glyph). While it flies the copy is on its own layer, and every other place
// its path crosses, with a 48 pt margin, steps back to 28% within the first 4% of the move and returns over the last
// 20%. The place it lands in does not step back: it is arriving there. A copy with its own ground (a paper ticket)
// stays opaque until it is clear of where it came from, then fades.

/// One flight: the path of the copy's centre, its size, where it leaves and where it lands (shell coordinates).
struct FlightRoute: Equatable, Sendable {
    var path: [CGPoint]
    var size: CGSize
    var source: Place
    var landing: Place
    /// A paper ticket carries its own ground; a word does not.
    var hasOwnGround = false
}

enum FlightMove {
    /// How far a place's frame is grown before it counts as crossed.
    static let margin: CGFloat = 48
    /// What a crossed place steps back to.
    static let restOpacity = 0.28
    /// The step back is done by this share of the move; the return starts at `returnStart`.
    static let stepBackEnd = 0.04
    static let returnStart = 0.8
    /// Every move ends within 1 s.
    static let duration = 0.52

    /// Where the copy's centre is at progress `t` (0 to 1), along the polyline by length.
    static func centre(_ route: FlightRoute, at t: Double) -> CGPoint {
        guard let first = route.path.first else { return .zero }
        guard route.path.count > 1 else { return first }
        let lengths = zip(route.path, route.path.dropFirst()).map { hypot($1.x - $0.x, $1.y - $0.y) }
        let total = lengths.reduce(0, +)
        guard total > 0 else { return first }
        var remaining = CGFloat(min(max(t, 0), 1)) * total
        for (index, length) in lengths.enumerated() {
            if remaining <= length || index == lengths.count - 1 {
                let f = length > 0 ? min(remaining / length, 1) : 0
                let a = route.path[index], b = route.path[index + 1]
                return CGPoint(x: a.x + (b.x - a.x) * f, y: a.y + (b.y - a.y) * f)
            }
            remaining -= length
        }
        return route.path[route.path.count - 1]
    }

    static func copyRect(_ route: FlightRoute, at t: Double) -> CGRect {
        let c = centre(route, at: t)
        return CGRect(x: c.x - route.size.width / 2, y: c.y - route.size.height / 2, width: route.size.width,
                      height: route.size.height)
    }

    /// The places whose frame, grown by the margin, the copy's path crosses. The source and the landing never count.
    static func crossed(_ route: FlightRoute, frames: [Place: CGRect]) -> Set<Place> {
        var hit: Set<Place> = []
        for (place, frame) in frames where place != route.source && place != route.landing {
            let zone = frame.insetBy(dx: -(margin + route.size.width / 2), dy: -(margin + route.size.height / 2))
            if zip(route.path, route.path.dropFirst()).contains(where: { segment($0, $1, crosses: zone) })
                || (route.path.count == 1 && zone.contains(route.path[0]))
            {
                hit.insert(place)
            }
        }
        return hit
    }

    /// A crossed place's opacity at progress `t`: 1, down to 28% by 4%, held, back to 1 over the last 20%.
    static func placeOpacity(at t: Double) -> Double {
        let t = min(max(t, 0), 1)
        if t < stepBackEnd {
            return 1 - (1 - restOpacity) * (t / stepBackEnd)
        }
        if t < returnStart {
            return restOpacity
        }
        return restOpacity + (1 - restOpacity) * ((t - returnStart) / (1 - returnStart))
    }

    /// The landing place's own content fades in underneath the copy over the last 20% of the move. The landing never
    /// steps back: its opacity as a place stays 1, and only this content arrives.
    static func landingContentOpacity(at t: Double) -> Double {
        let t = min(max(t, 0), 1)
        return t < returnStart ? 0 : (t - returnStart) / (1 - returnStart)
    }

    /// The copy's opacity: a word is opaque throughout; a copy with its own ground stays opaque until it is clear of
    /// its source, then fades over the rest of the move (the landing takes over from it).
    static func copyOpacity(_ route: FlightRoute, source: CGRect, at t: Double) -> Double {
        guard route.hasOwnGround else { return 1 }
        let clear = clearTime(route, source: source)
        guard t > clear else { return 1 }
        return max(0, 1 - (t - clear) / max(1 - clear, 0.0001))
    }

    /// The first progress at which the copy no longer touches its source.
    static func clearTime(_ route: FlightRoute, source: CGRect) -> Double {
        let steps = 200
        for step in 0 ... steps {
            let t = Double(step) / Double(steps)
            if !copyRect(route, at: t).intersects(source) {
                return t
            }
        }
        return 1
    }

    /// Liang-Barsky: does the segment touch the rectangle?
    private static func segment(_ a: CGPoint, _ b: CGPoint, crosses rect: CGRect) -> Bool {
        var t0: CGFloat = 0, t1: CGFloat = 1
        let dx = b.x - a.x, dy = b.y - a.y
        let edges: [(CGFloat, CGFloat)] = [(-dx, a.x - rect.minX), (dx, rect.maxX - a.x),
                                           (-dy, a.y - rect.minY), (dy, rect.maxY - a.y)]
        for (p, q) in edges {
            if p == 0 {
                if q < 0 {
                    return false
                }
            } else {
                let r = q / p
                if p < 0 {
                    t0 = max(t0, r)
                } else {
                    t1 = min(t1, r)
                }
                if t0 > t1 {
                    return false
                }
            }
        }
        return true
    }

    /// The mid-move rule (`t35.js`): text of two places never crosses while both are above 40%. Given each place's
    /// frame and the copy, returns the places the copy overlaps at `t` while they are still above 40%, which is empty
    /// for every place but its own source and its landing.
    static func collisions(_ route: FlightRoute, frames: [Place: CGRect], at t: Double) -> Set<Place> {
        let rect = copyRect(route, at: t)
        let stepped = crossed(route, frames: frames)
        return Set(frames.compactMap { place, frame in
            guard place != route.source, place != route.landing, rect.intersects(frame) else { return nil }
            let opacity = stepped.contains(place) ? placeOpacity(at: t) : 1
            return opacity > 0.4 ? place : nil
        })
    }
}

/// Drives a flight: `progress` runs 0 to 1 over the move, and the places and the copy read it. Reduce Motion: no
/// flight; the landing simply takes the thing, in the usual 150 ms crossfade.
@MainActor @Observable
final class FlightRunner {
    private(set) var route: FlightRoute?
    private(set) var progress = 0.0
    private(set) var crossed: Set<Place> = []

    func fly(_ route: FlightRoute, frames: [Place: CGRect], reduceMotion: Bool, isShown: Bool = true,
             done: @escaping @MainActor () -> Void = {})
    {
        guard !reduceMotion, isShown else {
            done()
            return
        }
        self.route = route
        crossed = FlightMove.crossed(route, frames: frames)
        progress = 0
        withTesseraAnimation(.linear(duration: FlightMove.duration), reduceMotion: reduceMotion) { progress = 1 }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(FlightMove.duration))
            self.route = nil
            self.crossed = []
            self.progress = 0
            done()
        }
    }
}

/// A place steps back while a copy crosses it. Animatable on the flight's progress, so the 4% and 20% edges of the
/// move are exact whatever the move's own curve.
struct FlightStepBack: ViewModifier, Animatable {
    var progress: Double
    var steps: Bool

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content.opacity(steps ? FlightMove.placeOpacity(at: progress) : 1)
    }
}

/// The copy on its own layer, above every place, moving along its route and fading when it has its own ground.
struct FlightCopy<Content: View>: View, Animatable {
    var progress: Double
    let route: FlightRoute
    let source: CGRect
    @ViewBuilder var content: () -> Content

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        let rect = FlightMove.copyRect(route, at: progress)
        content()
            .frame(width: rect.width, height: rect.height)
            .opacity(FlightMove.copyOpacity(route, source: source, at: progress))
            .position(x: rect.midX, y: rect.midY)
            .allowsHitTesting(false)
            .zIndex(1000)
    }
}

extension View {
    /// The landing place's arriving content: hidden until the last 20% of the flight, then fading in under the copy.
    func flightArrival(_ place: Place, runner: FlightRunner) -> some View {
        opacity(runner.route?.landing == place ? FlightMove.landingContentOpacity(at: runner.progress) : 1)
    }

    /// Steps this place back while the runner's copy crosses it (never the place it lands in).
    func flightStepBack(_ place: Place, runner: FlightRunner) -> some View {
        modifier(FlightStepBack(progress: runner.progress, steps: runner.crossed.contains(place)))
    }
}
