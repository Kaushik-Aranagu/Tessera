import SwiftUI

/// Sheet 300: the tick on a checked list item is drawn. Checking draws its stroke from the short arm to the long arm in
/// 160 ms, easing out, so it lands quickly and slows into the end; a short segment at the start is drawn 0.7 pt heavier
/// and stays, where the pen pressed. Unchecking fades the tick back to its faint mark (18%) in 160 ms and never draws
/// backwards. Reduce Motion: the tick appears and goes at once. The words' strike waits for the stroke (170 ms).
struct TickShape: Shape {
    /// The tick in a unit square: the short arm down to the elbow, then the long arm up to the right.
    static let start = CGPoint(x: 0.16, y: 0.54)
    static let elbow = CGPoint(x: 0.40, y: 0.76)
    static let end = CGPoint(x: 0.86, y: 0.24)

    func path(in rect: CGRect) -> Path {
        func point(_ unit: CGPoint) -> CGPoint {
            CGPoint(x: rect.minX + unit.x * rect.width, y: rect.minY + unit.y * rect.height)
        }
        var path = Path()
        path.move(to: point(Self.start))
        path.addLine(to: point(Self.elbow))
        path.addLine(to: point(Self.end))
        return path
    }

    /// The fraction of the stroke the short arm takes, for the heavier start segment's length.
    static var shortArmShare: CGFloat {
        let short = hypot(elbow.x - start.x, elbow.y - start.y)
        let long = hypot(end.x - elbow.x, end.y - elbow.y)
        return short / (short + long)
    }
}

struct DrawnTick: View {
    let checked: Bool
    var size: CGFloat = 22
    var color: Color = Theme.Colors.ink

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// How much of the stroke is drawn, 0 to 1.
    @State private var progress: CGFloat
    /// The drawn tick's opacity: the faint mark stays under it.
    @State private var drawn: Double

    init(checked: Bool, size: CGFloat = 22, color: Color = Theme.Colors.ink) {
        self.checked = checked
        self.size = size
        self.color = color
        _progress = State(initialValue: checked ? 1 : 0)
        _drawn = State(initialValue: checked ? 1 : 0)
    }

    static let drawSeconds: TimeInterval = 0.16
    static let faint = 0.18
    /// The pen's press: 1.7 pt of heavier stroke at the start, 0.7 pt heavier than the rest.
    static let pressLength: CGFloat = 1.7
    static let pressExtra: CGFloat = 0.7

    var body: some View {
        let width = max(size * 0.09, 1.6)
        ZStack {
            TickShape()
                .stroke(
                    color.opacity(Self.faint),
                    style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
                )
            TickShape()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
                .opacity(drawn)
            // Where the pen pressed: a short heavier segment at the start, which stays.
            TickShape()
                .trim(from: 0, to: min(progress, Self.pressLength / (size * 1.1)))
                .stroke(color, style: StrokeStyle(lineWidth: width + Self.pressExtra, lineCap: .round))
                .opacity(drawn)
        }
        .frame(width: size, height: size)
        .onChange(of: checked) { _, now in
            if reduceMotion {
                progress = now ? 1 : 0
                drawn = now ? 1 : 0
            } else if now {
                progress = 0
                drawn = 1
                withAnimation(.easeOut(duration: Self.drawSeconds)) { progress = 1 }
            } else {
                // Never drawn backwards: the whole tick fades back to the faint mark.
                withAnimation(.linear(duration: Self.drawSeconds)) { drawn = 0 }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(Int(Self.drawSeconds * 1000)))
                    if !checked {
                        progress = 0
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }
}
