import SwiftUI

/// Paint for the workout's dark ground: colours that mean something. Shared by the live workout's parts.
/// (A DesignSystem candidate: `Theme.Colors.Workout` could carry these once the Plein concept settles.)
enum WorkoutPaint {
    static let live = Color(hex: 0xD9563F)
    static let tess = Color(hex: 0x9DBFE6)
    static let tessBar = Color(hex: 0xC9D9EE)
    static let now = Color(hex: 0xE8BD4C)
    static let health = Color(hex: 0x7FB07A)
    static let cobalt = Color(hex: 0x3F7FC0)
    static let secondary = Color(hex: 0xA79FB5)
    static let cream = Color(hex: 0xF3ECE0)
    static let sheen = Color(hex: 0xFFE2A8)
    /// The dark glass of sheets and panels over the ground: rgba(28, 24, 40, .82).
    static let glass = Color(hex: 0x1C1828).opacity(0.82)

    /// Each logged set leaves a stroke; the colour cycles set to set.
    static func set(_ number: Int) -> Color {
        [live, cobalt, now, health][max(number - 1, 0) % 4]
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
                shape.fill(.ultraThinMaterial)
                    .overlay { shape.fill(WorkoutPaint.glass) }
            }
            .overlay {
                shape.strokeBorder(LinearGradient(stops: [.init(color: .white.opacity(0.14), location: 0),
                                                          .init(color: .clear, location: 0.08)],
                                                  startPoint: .top, endPoint: .bottom), lineWidth: 1)
            }
            .overlay { shape.stroke(.black.opacity(0.6), lineWidth: 0.5) }
            .shadow(color: .black.opacity(0.45), radius: 30, y: 24)
    }
}

extension View {
    func workoutGlass(_ shape: some InsettableShape) -> some View {
        modifier(WorkoutGlass(shape: shape))
    }
}
