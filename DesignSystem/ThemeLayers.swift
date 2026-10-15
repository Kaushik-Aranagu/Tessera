import SwiftUI

/// The concept's background layer, shared behind every page (pages themselves are transparent).
struct ThemedBackground: View {
    var body: some View {
        switch Theme.concept.background {
        case .groundWithSky: GroundWithSky()
        case .flat: Theme.Colors.paper.ignoresSafeArea()
        case .plein: PleinGround()
        }
    }
}

/// Flat ground with a slow, time-of-day mesh tint across the top only.
private struct GroundWithSky: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack(alignment: .top) {
            Theme.Colors.paper
            TimelineView(.animation(minimumInterval: 1 / 15, paused: reduceMotion)) { context in
                let time = context.date.timeIntervalSinceReferenceDate
                let hour = Double(Calendar.current.component(.hour, from: AppClock.adjust(context.date)))
                sky(time: reduceMotion ? 0 : time, tints: Theme.Colors.skyTints(hour: hour))
            }
            .frame(height: 360)
            .mask(LinearGradient(colors: [.black, .black.opacity(0.6), .clear], startPoint: .top, endPoint: .bottom))
            .opacity(colorScheme == .dark ? 0.22 : 0.85)
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }

    private func sky(time: Double, tints: [Color]) -> some View {
        let drift = Float(sin(time / 9) * 0.08)
        let sway = Float(cos(time / 13) * 0.06)
        return MeshGradient(
            width: 3,
            height: 2,
            points: [
                [0, 0], [0.5 + sway, 0], [1, 0],
                [0, 1], [0.5 - drift, 1], [1, 1],
            ],
            colors: [
                tints[0], tints[1], tints[2],
                Theme.Colors.paper, Theme.Colors.paper, Theme.Colors.paper,
            ],
            smoothsColors: true
        )
    }
}

/// Between rows, per the concept's separator style.
struct RowSeparator: View {
    var color: Color = Theme.Colors.hairline

    var body: some View {
        switch Theme.concept.separator {
        case .hairline:
            Rectangle().fill(color).frame(height: Theme.Stroke.hairline)
        case .dotted:
            DottedRule(color: color.opacity(3))
        case .none:
            Color.clear.frame(height: Theme.Spacing.xs)
        }
    }
}

/// Animated completion of a line of text, per the concept (strike-through or dissolve).
struct CompletionRenderer: TextRenderer, Animatable {
    var progress: Double
    var color: Color

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        switch Theme.concept.completion {
        case .strike:
            StrikeRenderer(progress: progress, color: color).draw(layout: layout, in: &context)
        case .dissolve:
            var copy = context
            copy.opacity = 1 - 0.7 * progress
            copy.addFilter(.blur(radius: progress * 6))
            for line in layout {
                copy.draw(line)
            }
        }
    }
}
