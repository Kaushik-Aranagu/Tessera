import SwiftUI

/// Stroke her (tess-picks.md idea 3): a pan that starts outside her 64 pt hit area but inside her band, crosses her
/// and leaves the other side within 700 ms, travelling at least 40 pt. Because it starts off her it is never her
/// tap, hold or drag. Pure: feed it the pan's points and times.
struct SoulStrokeTracker {
    /// Her hit area, centred on her.
    static let hitSize: CGFloat = 64
    /// The band round her centre: 736 to 820 on a 779 dock (the sheet's values).
    static let bandAbove: CGFloat = 43
    static let bandBelow: CGFloat = 41
    static let maxDuration = 0.7
    static let minTravel: CGFloat = 40

    enum Step: Equatable {
        /// The finger has just come onto her (the tick, and her eyes follow it).
        case entered
        /// The finger left her.
        case left
    }

    private var start: (point: CGPoint, time: Double)?
    private var entered = false
    private var inside = false

    static func hitArea(_ centre: CGPoint) -> CGRect {
        CGRect(x: centre.x - hitSize / 2, y: centre.y - hitSize / 2, width: hitSize, height: hitSize)
    }

    static func inBand(_ point: CGPoint, centre: CGPoint) -> Bool {
        point.y >= centre.y - bandAbove && point.y <= centre.y + bandBelow
    }

    /// A pan began: it counts only from outside her, inside the band.
    mutating func began(at point: CGPoint, time: Double, centre: CGPoint) {
        entered = false
        inside = false
        let valid = !Self.hitArea(centre).contains(point) && Self.inBand(point, centre: centre)
        start = valid ? (point, time) : nil
    }

    mutating func moved(to point: CGPoint, time: Double, centre: CGPoint) -> Step? {
        guard let start, time - start.time <= Self.maxDuration else { return nil }
        let now = Self.hitArea(centre).contains(point)
        defer { inside = now }
        if now, !inside, !entered {
            entered = true
            return .entered
        }
        if !now, inside {
            return .left
        }
        return nil
    }

    /// Whether the finished pan was a stroke: in, through, and out the other side in time, far enough.
    mutating func ended(at point: CGPoint, time: Double, centre: CGPoint) -> Bool {
        defer { start = nil }
        guard let start, entered, time - start.time <= Self.maxDuration,
              abs(point.x - start.point.x) >= Self.minTravel,
              !Self.hitArea(centre).contains(point) else { return false }
        // Out the other side: the finger ends past her on the far side from where it began.
        return (start.point.x - centre.x).sign != (point.x - centre.x).sign
    }
}

enum SoulRipple {
    static let duration = 1.6

    /// The ripple through the paint `elapsed` seconds after the stroke: each dab moves by
    /// 4 pt × e^(−2.6 k) × sin(0.25 × its x from her centre − 16 k), and y by 0.6 of that on a cosine. In on-screen
    /// points, brought into dab space by `scale`.
    static func rippled(_ frame: SoulFrame, elapsed: Double, scale: CGFloat) -> SoulFrame {
        guard elapsed >= 0, elapsed <= duration, scale > 0 else { return frame }
        var result = frame
        let amp = 4 * exp(-elapsed * 2.6)
        for index in result.dabs.indices {
            let screenX = Double(frame.dabs[index].x * scale)
            result.dabs[index].x += CGFloat(amp * sin(screenX * 0.25 - elapsed * 16)) / scale
            result.dabs[index].y += CGFloat(amp * 0.6 * cos(screenX * 0.2 - elapsed * 14)) / scale
        }
        return result
    }
}

/// The band-wide pan that strokes her, on the layer that holds her chrome. Simultaneous, so whatever is under the
/// finger still gets it; it only reports to the router (views never set her state).
struct SoulStrokeGesture: ViewModifier {
    let soul: SoulRouter
    /// Only where the band is hers: Home's tab pages (a pushed page may draw rows down into it, QA on #662).
    let isHome: Bool
    @State private var tracker = SoulStrokeTracker()
    /// True from the pan's first change to its end, reset by the gesture itself even when it's cancelled.
    @GestureState private var isPanning = false

    private var drag: some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .global)
            .updating($isPanning) { value, panning, _ in
                guard let centre = soul.dockCentre else { return }
                let time = value.time.timeIntervalSinceReferenceDate
                if !panning {
                    panning = true
                    tracker.began(at: value.startLocation, time: time, centre: centre)
                }
                switch tracker.moved(to: value.location, time: time, centre: centre) {
                case .entered: soul.handle(.strokeEntered)
                case .left: soul.handle(.strokeLeft)
                case nil: break
                }
            }
            .onEnded { value in
                guard let centre = soul.dockCentre else { return }
                let stroke = tracker.ended(at: value.location, time: value.time.timeIntervalSinceReferenceDate,
                                           centre: centre)
                soul.handle(.strokeEnded(isStroke: stroke))
            }
    }

    func body(content: Content) -> some View {
        // Simultaneous on the whole Home container (QA on #662): it never takes a touch from the page (the Home
        // swipe, the foot link, a row's pan); the tracker only counts a pan that starts in her band beside her. Off
        // Home, or when she wouldn't take a stroke, it isn't attached at all.
        content
            .simultaneousGesture(drag, including: isHome && !soul.refusesStroke ? .all : .subviews)
            .tesseraFeedback(.soulStroke, trigger: soul.strokeTicks)
    }
}

extension View {
    /// Lets a pan across her band stroke her (idea 3).
    func soulStroke(_ soul: SoulRouter, isHome: Bool) -> some View {
        modifier(SoulStrokeGesture(soul: soul, isHome: isHome))
    }
}
