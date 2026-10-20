import SwiftUI

// Paint and motion pieces shared by the Exercise page and Plans.

// MARK: - Type

/// Sizes these specs call for between the four tiers, set in the concept's faces (so a font swap is a Theme change).
enum PageType {
    /// 18 pt UI face: history dates, notes under a grid, roles, keys.
    static var small: Font {
        Theme.Typography.face(Theme.concept.fonts.ui, size: 18, relativeTo: .subheadline, serif: false)
            .weight(.medium)
    }

    /// 16 pt UI face, case kept: routine names under the week's dabs, day numerals.
    static var caption: Font {
        Theme.Typography.face(Theme.concept.fonts.ui, size: 16, relativeTo: .callout, serif: false)
            .weight(.medium)
    }

    /// The concept's voice (context lines and Tess), upright.
    static var voice: Font {
        Theme.voice(size: 21)
    }
}

// MARK: - The painted trend

/// A 90-day e1RM line painted as one cobalt brushstroke (4 pt, round caps) over a hairline baseline. It draws in
/// once on arrival (1.1 s); a wet tip breathes at the newest session. No axes, gridlines or box.
struct PaintedTrend: View {
    /// Unit-space points (see `TrendGeometry`).
    let points: [CGPoint]
    var animate = true

    @State private var drawn: CGFloat = 0
    @State private var wet = false
    @Environment(\.motionReduced) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let mapped = Self.map(points, in: size)
            ZStack(alignment: .topLeading) {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: size.height - 6))
                    path.addLine(to: CGPoint(x: size.width, y: size.height - 6))
                }
                .stroke(Theme.Colors.ink.opacity(0.18), lineWidth: 1)

                if mapped.count > 1 {
                    Self.curve(through: mapped)
                        .trim(from: 0, to: drawn)
                        .stroke(Theme.Colors.tess, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                        .blur(radius: 0.4)
                }
                if let tip = mapped.last {
                    Circle()
                        .fill(Theme.Colors.tess)
                        .frame(width: 18, height: 18)
                        .scaleEffect(wet ? 1.35 : 1)
                        .opacity((wet ? 0.4 : 0.75) * (drawn > 0.95 || mapped.count == 1 ? 1 : 0))
                        .blur(radius: wet ? 6 : 3)
                        .position(tip)
                }
            }
        }
        .accessibilityHidden(true)
        .onAppear(perform: paint)
    }

    private func paint() {
        if !animate || reduceMotion {
            drawn = 1
        } else {
            withTesseraAnimation(.timingCurve(0.3, 0.7, 0.2, 1, duration: 1.1).delay(0.12),
                                 reduceMotion: reduceMotion) { drawn = 1 }
        }
        guard !reduceMotion else { return }
        withTesseraAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                             reduceMotion: reduceMotion) { wet = true }
    }

    /// Unit space (y up) to the frame (y down), inset so the round caps and the tip stay inside.
    static func map(_ points: [CGPoint], in size: CGSize) -> [CGPoint] {
        let inset: CGFloat = 6
        let width = max(size.width - inset * 2, 1), height = max(size.height - inset * 2 - 6, 1)
        return points.map { CGPoint(x: inset + $0.x * width, y: inset + (1 - $0.y) * height) }
    }

    /// A soft curve through the points: horizontal tangents at each point, like a brush following them.
    static func curve(through points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for (previous, point) in zip(points, points.dropFirst()) {
            let dx = (point.x - previous.x) / 2
            path.addCurve(to: point, control1: CGPoint(x: previous.x + dx, y: previous.y),
                          control2: CGPoint(x: point.x - dx, y: point.y))
        }
        return path
    }
}

// MARK: - Rows rising in

/// Rows rise in (10 pt, 300 ms) with a stagger on arrival, and again whenever `token` changes (a view switched to).
/// Never blocks taps. Reduce Motion: opacity only.
private struct RiseIn: ViewModifier {
    let index: Int
    let token: Int
    var stagger: Double = 0.03
    @State private var shown = false
    @Environment(\.motionReduced) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 10)
            .task(id: token) {
                var reset = Transaction()
                reset.disablesAnimations = true
                withTransaction(reset) { shown = false }
                try? await Task.sleep(for: .milliseconds(16))
                withTesseraAnimation(.easeOut(duration: 0.3).delay(Double(min(index, 12)) * stagger),
                                     reduceMotion: reduceMotion) { shown = true }
            }
    }
}

extension View {
    func riseIn(_ index: Int, token: Int, stagger: Double = 0.03) -> some View {
        modifier(RiseIn(index: index, token: token, stagger: stagger))
    }
}

// MARK: - Hero arriving from the right

/// The object's name comes in from the right (18 pt, blur 4 → 0, 340 ms) on the first visit. Reduce Motion: a fade.
private struct ArriveFromRight: ViewModifier {
    @Environment(\.animateEntrance) private var animate
    @Environment(\.motionReduced) private var reduceMotion
    @State private var shown = false

    func body(content: Content) -> some View {
        let hidden = animate && !shown
        content
            .opacity(hidden ? 0 : 1)
            .offset(x: hidden && !reduceMotion ? 18 : 0)
            .blur(radius: hidden && !reduceMotion ? 4 : 0)
            .task {
                guard animate else { return }
                try? await Task.sleep(for: .milliseconds(60))
                withTesseraAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.34),
                                     reduceMotion: reduceMotion) { shown = true }
            }
    }
}

extension View {
    func arrivesFromRight() -> some View {
        modifier(ArriveFromRight())
    }
}

// MARK: - One glint

/// The glint motif, once: a warm sheen crosses the content a single time on arrival. Reduce Motion: nothing.
private struct GlintOnce: ViewModifier {
    @State private var sweep: CGFloat = -0.6
    @Environment(\.motionReduced) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay {
                if !reduceMotion {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: Theme.Colors.sheen, location: 0.5),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: UnitPoint(x: sweep - 0.25, y: 0.2),
                        endPoint: UnitPoint(x: sweep + 0.25, y: 0.8)
                    )
                    .mask(content)
                    .blendMode(Theme.Colors.sheenBlend)
                    .allowsHitTesting(false)
                }
            }
            .task {
                guard !reduceMotion else { return }
                try? await Task.sleep(for: .milliseconds(450))
                withTesseraAnimation(.easeInOut(duration: 1.1), reduceMotion: reduceMotion) { sweep = 1.6 }
            }
    }
}

extension View {
    func glintOnce(_ active: Bool) -> some View {
        Group {
            if active {
                modifier(GlintOnce())
            } else {
                self
            }
        }
    }
}

// MARK: - Fades at a window's edge

extension View {
    /// A bounded window fades out at the bottom (from `from` of its height) instead of ending in a hard edge.
    func fadesAtBottom(from start: CGFloat = 0.78) -> some View {
        mask {
            LinearGradient(stops: [.init(color: .black, location: 0), .init(color: .black, location: start),
                                   .init(color: .clear, location: 1)],
                           startPoint: .top, endPoint: .bottom)
        }
    }
}
