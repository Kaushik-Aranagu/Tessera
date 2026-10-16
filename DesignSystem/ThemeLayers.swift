import SwiftUI

/// The concept's background layer, shared behind every page (pages themselves are transparent).
struct ThemedBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            switch Theme.concept.background {
            case .groundWithSky: GroundWithSky()
            case .flat: Theme.Colors.paper.ignoresSafeArea()
            case .plein: PleinGround()
            case .looks: LookField(look: look)
            }
        }
        // The workout is always dark, so it learns the appearance here, at the root.
        .onChange(of: colorScheme, initial: true) { _, scheme in
            ThemeStore.shared.systemIsDark = scheme == .dark
        }
    }

    private var look: Look {
        let pair = ThemeStore.shared.pair
        return colorScheme == .dark ? pair.night : pair.day
    }
}

/// Each look's field (themes.md, "The field"): how the material would behave, never a pasted gradient or texture.
struct LookField: View {
    let look: Look

    var body: some View {
        let ground = Color(hex: look.ground)
        switch look.field {
        case .plein:
            PleinGround()
        case .pigmentBloom, .emissive:
            // Porcelain is flat white, Obsidian pixels off; the colour lives behind the action (`actionBloom`).
            ground.ignoresSafeArea()
        case .glaze:
            // The glaze collects at the foot: the bottom 260 pt pools 6% ink-darker.
            ground
                .overlay(alignment: .bottom) {
                    LinearGradient(colors: [.clear, Color(hex: look.ink).opacity(0.06)], startPoint: .top,
                                   endPoint: .bottom)
                        .frame(height: 260)
                }
                .ignoresSafeArea()
        case .lacquer:
            // Plum-black deepening toward the bottom, and one wide specular band across at −24°.
            ground
                .overlay {
                    LinearGradient(stops: [.init(color: .clear, location: 0.55),
                                           .init(color: Color(hex: 0x06030A).opacity(0.75), location: 1)],
                                   startPoint: .top, endPoint: .bottom)
                }
                .overlay {
                    Rectangle()
                        .fill(Color(hex: 0xFFF4E6).opacity(0.05))
                        .frame(height: 150)
                        .blur(radius: 14)
                        .rotationEffect(.degrees(-24))
                        .scaleEffect(x: 2.2)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
    }
}

/// The workout's ground in the look on screen (themes.md addendum): Plein keeps its dark washes and drift, Lacquer
/// its band at 3%, every other look a flat workout ground.
struct WorkoutField: View {
    var body: some View {
        let look = ThemeStore.shared.current
        switch look.field {
        case .plein:
            PleinGround()
        case .lacquer:
            Theme.Colors.Workout.ground
                .overlay {
                    Rectangle()
                        .fill(Color(hex: 0xFFF4E6).opacity(0.03))
                        .frame(height: 150)
                        .blur(radius: 14)
                        .rotationEffect(.degrees(-24))
                        .scaleEffect(x: 2.2)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
        case .pigmentBloom, .emissive, .glaze:
            Theme.Colors.Workout.ground.ignoresSafeArea()
        }
    }
}

extension View {
    /// The colour of the moment, pooled behind the action's row by the look's field: a watercolour bloom on light
    /// looks (5% centre, 10% dried edge), an emitted glow on dark ones (screen, 16%, blur 18). Plein's washes
    /// already carry it.
    func actionBloom(_ pigment: Color) -> some View {
        modifier(ActionBloom(pigment: pigment))
    }
}

private struct ActionBloom: ViewModifier {
    let pigment: Color

    func body(content: Content) -> some View {
        content.background {
            let look = ThemeStore.shared.current
            switch look.field {
            case .plein:
                EmptyView()
            case .pigmentBloom, .glaze:
                Ellipse()
                    .fill(RadialGradient(colors: [pigment.opacity(0.05), pigment.opacity(0.05), pigment.opacity(0.1),
                                                  .clear],
                                         center: .center, startRadius: 0, endRadius: 180))
                    .frame(width: 360, height: 120)
                    .blendMode(.multiply)
                    .allowsHitTesting(false)
            case .emissive, .lacquer:
                Ellipse()
                    .fill(pigment.opacity(look.field == .emissive ? 0.16 : 0.14))
                    .frame(width: 300, height: 90)
                    .blur(radius: 18)
                    .blendMode(.screen)
                    .allowsHitTesting(false)
            }
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
