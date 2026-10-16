import SwiftUI

/// Paint for the workout's dark ground: colours that mean something, read from the look on screen
/// (`Theme.Colors.Workout`, themes.md addendum), so the workout follows the theme. Names kept for the call sites.
enum WorkoutPaint {
    static var live: Color {
        Theme.Colors.Workout.signal
    }

    /// Tess's words, the swap wash, the cobalt set stroke (one token: `Workout.tess`).
    static var tess: Color {
        Theme.Colors.Workout.tess
    }

    static var tessBar: Color {
        Theme.Colors.Workout.tess
    }

    static var cobalt: Color {
        Theme.Colors.Workout.tess
    }

    static var now: Color {
        Theme.Colors.Workout.rest
    }

    static var health: Color {
        Theme.Colors.Workout.health
    }

    static var secondary: Color {
        Theme.Colors.Workout.inkSecondary
    }

    static var cream: Color {
        Theme.Colors.Workout.ink
    }

    /// The glint over the workout's dark ground (the look's sheen, resolved against the workout's pages).
    static var sheen: Color {
        Theme.Colors.sheen
    }

    /// The glass of sheets and panels: the ground at 82% over the material.
    static var glass: Color {
        Theme.Colors.Workout.ground.opacity(0.82)
    }

    /// Each logged set leaves a stroke; the colour cycles set to set.
    static func set(_ number: Int) -> Color {
        let cycle = Theme.Colors.Workout.setCycle
        return cycle[max(number - 1, 0) % cycle.count]
    }

    /// Black drop shadows only on Plein (a black shadow can't show on #000); other looks lift with `raised`.
    static var dropsShadows: Bool {
        ThemeStore.shared.workoutLook.field == .plein
    }
}

/// Reveals its content left to right (the effort slider sliding out). Reduce Motion uses a fade instead.
struct RevealMask: ViewModifier {
    var progress: CGFloat

    func body(content: Content) -> some View {
        content.mask(alignment: .leading) {
            Rectangle().scaleEffect(x: progress, y: 1, anchor: .leading)
        }
    }
}

extension AnyTransition {
    static func revealLeading(reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? .opacity : .modifier(active: RevealMask(progress: 0), identity: RevealMask(progress: 1))
    }
}

/// Dark glass for a sheet or panel: the house glass colour over a blur, a lit top hairline and a soft drop.
struct WorkoutGlass<S: InsettableShape>: ViewModifier {
    let shape: S

    func body(content: Content) -> some View {
        content
            .background {
                shape.fill(Theme.Colors.Workout.raised)
                    .overlay { shape.fill(WorkoutPaint.glass) }
            }
            .overlay {
                shape.strokeBorder(LinearGradient(stops: [.init(color: Theme.Colors.Workout.hairline, location: 0),
                                                          .init(color: .clear, location: 0.08)],
                                                  startPoint: .top, endPoint: .bottom), lineWidth: 1)
            }
            .overlay { shape.stroke(Theme.Colors.Workout.glassEdge, lineWidth: 0.5) }
            .shadow(color: .black.opacity(WorkoutPaint.dropsShadows ? 0.45 : 0), radius: 30, y: 24)
    }
}

extension View {
    func workoutGlass(_ shape: some InsettableShape) -> some View {
        modifier(WorkoutGlass(shape: shape))
    }
}
