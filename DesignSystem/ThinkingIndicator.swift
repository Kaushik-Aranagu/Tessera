import SwiftUI

/// "Tess is thinking", drawn per the concept's `ThinkingStyle`. Reduce Motion: a static glyph with a slow fade.
struct ThinkingIndicator: View {
    var color: Color = Theme.Colors.live
    var size: CGFloat = 22
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if Theme.concept.thinking == .soul {
            TessSoul(mode: .thinking)
                .scaleEffect(size / 96)
                .frame(width: size, height: size)
        } else {
            glyph
        }
    }

    private var glyph: some View {
        LiveClock(minimumInterval: 1 / 60) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            switch Theme.concept.thinking {
            case .dots: dots(time: time)
            default: spark(time: time)
            }
        }
        .frame(width: size, height: size)
        .liveRegion(LiveFeatures.thinking)
        .accessibilityLabel("Tess is thinking")
    }

    /// Eight rays around a point; lengths breathe out of phase and the whole glyph turns slowly.
    private func spark(time: Double) -> some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let radius = min(canvasSize.width, canvasSize.height) / 2
            let turn = reduceMotion ? 0 : time * 0.9
            for ray in 0 ..< 8 {
                let phase = Double(ray) * .pi / 4
                let breathe = reduceMotion ? 0.8 : 0.55 + 0.45 * (0.5 + 0.5 * sin(time * 4 + phase * 1.5))
                let length = radius * (ray.isMultiple(of: 2) ? 1 : 0.62) * breathe
                let angle = phase + turn
                var path = Path()
                path.move(to: CGPoint(
                    x: center.x + cos(angle) * radius * 0.12,
                    y: center.y + sin(angle) * radius * 0.12
                ))
                path.addLine(to: CGPoint(x: center.x + cos(angle) * length, y: center.y + sin(angle) * length))
                context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: radius * 0.2, lineCap: .round))
            }
        }
        .opacity(reduceMotion ? 0.6 + 0.4 * (0.5 + 0.5 * sin(time * 2)) : 1)
    }

    private func dots(time: Double) -> some View {
        HStack(spacing: size * 0.12) {
            ForEach(0 ..< 3) { index in
                Circle()
                    .fill(color)
                    .opacity(reduceMotion ? 0.7 : 0.3 + 0.7 * (0.5 + 0.5 * sin(time * 5 - Double(index) * 0.9)))
            }
        }
    }
}
