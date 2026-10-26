// swiftlint:disable identifier_name
import SwiftUI

/// Layout mode's glass (Design 283 v8, amended 7:41 PM: the glossy look was "too artificial"). A pane is the Lookout's
/// raised glass: clear inside (room tint 3%, black look 7%), no blur and no gloss; light from the top left (a white
/// glow at -4,-4, blur 14, 90%; black look 9%), a shadow to the bottom right (5,8, blur 20, 13%; black look 60%) and an
/// ambient one (2,14, blur 34, 5%); a 1 pt edge running white 70% at the top left through clear to black 8% at the
/// bottom right. Drawn with plain shapes and shadows, never `glassEffect`.
struct LayoutGlassLook {
    let isDark: Bool

    var tintFill: Double {
        isDark ? 0.07 : 0.03
    }

    var glow: Color {
        Color.white.opacity(isDark ? 0.09 : 0.9)
    }

    var drop: Color {
        Color.black.opacity(isDark ? 0.6 : 0.13)
    }

    var ambient: Color {
        Color.black.opacity(0.05)
    }

    var edgeLight: Color {
        Color.white.opacity(0.7)
    }

    var edgeDark: Color {
        Color.black.opacity(0.08)
    }
}

/// Raised glass as a background: the clear face, its three shadows drawn outside the shape only (so the face stays
/// clear), then the edge.
struct RaisedGlass: View {
    let shape: RoundedRectangle
    let tint: Color
    let look: LayoutGlassLook
    /// 1 for a pane, 0.5 for the masthead's low-relief plate, 1.6 for a lifted (selected) pane.
    var relief: Double = 1

    var body: some View {
        ZStack {
            shadowsOutside
            shape.fill(tint.opacity(look.tintFill))
            shape.strokeBorder(
                LinearGradient(stops: [.init(color: look.edgeLight, location: 0), .init(color: .clear, location: 0.5),
                                       .init(color: look.edgeDark, location: 1)],
                               startPoint: .topLeading, endPoint: .bottomTrailing),
                lineWidth: 1
            )
        }
    }

    private var shadowsOutside: some View {
        shape.fill(Color.black)
            .shadow(color: look.glow, radius: 7 * relief, x: -4 * relief, y: -4 * relief)
            .shadow(color: look.drop.opacity(min(1, relief)), radius: 10 * relief, x: 5 * relief, y: 8 * relief)
            .shadow(color: look.ambient, radius: 17 * relief, x: 2 * relief, y: 14 * relief)
            .mask {
                Rectangle().padding(-120)
                    .overlay { shape.fill(Color.black).blendMode(.destinationOut) }
                    .compositingGroup()
            }
            .allowsHitTesting(false)
    }
}

/// A pressed-in place (empty): inset shadows, a dashed edge, a faint hatch.
struct PressedIn: View {
    let shape: RoundedRectangle
    let tint: Color
    let look: LayoutGlassLook

    var body: some View {
        ZStack {
            shape.fill(tint.opacity(look.tintFill * 0.5))
            shape.stroke(Color.black.opacity(look.isDark ? 0.5 : 0.16), lineWidth: 6)
                .blur(radius: 4).offset(x: 2, y: 3).clipShape(shape)
            shape.stroke(Color.white.opacity(look.isDark ? 0.08 : 0.9), lineWidth: 6)
                .blur(radius: 4).offset(x: -2, y: -3).clipShape(shape)
            Hatch(tint: tint).clipShape(shape)
            shape.strokeBorder(tint.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        }
    }

    private struct Hatch: View {
        let tint: Color

        var body: some View {
            Canvas { context, size in
                var path = Path()
                var offset: CGFloat = -size.height
                while offset < size.width {
                    path.move(to: CGPoint(x: offset, y: size.height))
                    path.addLine(to: CGPoint(x: offset + size.height, y: 0))
                    offset += 8
                }
                context.stroke(path, with: .color(tint.opacity(0.1)), lineWidth: 1)
            }
        }
    }
}

/// What a pane's label does when the room changes, by place (the board's `flip`).
enum LayoutLabelMotion {
    case flap, turn, unroll, rise, form, spin, fromRight, stream, none

    init(place: String) {
        switch place {
        case "Title", "Nav word", "Switcher", "Needs", "Door title", "Settings word", "Departure board": self = .flap
        case "Keystone": self = .turn
        case "Caption": self = .unroll
        case "Widget", "Page": self = .rise
        case "Glyph": self = .form
        case "Dial": self = .spin
        case "Door summary": self = .fromRight
        case "Action word": self = .stream
        default: self = .none
        }
    }

    /// Delay and curve of the move, in seconds.
    var delay: Double {
        switch self {
        case .flap: 0.16
        case .turn: 0.10
        case .unroll: 0.48
        case .rise: 0.22
        case .form: 0.33
        case .spin, .none: 0
        case .fromRight: 0.60
        case .stream: 0.40
        }
    }

    var animation: Animation {
        switch self {
        case .flap: .spring(duration: 0.42, bounce: 0.22)
        case .turn: .spring(duration: 0.48, bounce: 0.05)
        case .unroll: .easeOut(duration: 0.32)
        case .rise: .spring(duration: 0.42, bounce: 0.08)
        case .form: .spring(duration: 0.44, bounce: 0.3)
        case .spin: .timingCurve(0.3, 0.05, 0.2, 1, duration: 0.9)
        case .fromRight: .spring(duration: 0.42, bounce: 0.2)
        case .stream: .easeOut(duration: 0.44)
        case .none: .linear(duration: 0.01)
        }
    }
}

/// The label of a pane, moving the way its place does. `progress` runs 0 to 1 (a spring may overshoot).
private struct LabelMotion: ViewModifier, Animatable {
    var progress: Double
    let motion: LayoutLabelMotion
    let direction: Double

    nonisolated var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        let p = progress
        let rest = max(0, 1 - p)
        let opacity = min(1, max(0, p * 1.6))
        switch motion {
        case .flap:
            content
                .rotation3DEffect(.degrees(-88 * rest), axis: (1, 0, 0), perspective: 0.5)
                .opacity(opacity)
        case .turn:
            content
                .rotation3DEffect(.degrees(direction * -70 * rest), axis: (0, 1, 0), perspective: 0.4)
                .opacity(opacity)
        case .unroll:
            content
                .mask(alignment: .top) { Rectangle().scaleEffect(y: max(0.001, min(1, p)), anchor: .top) }
        case .rise:
            content.offset(y: 18 * rest).opacity(opacity)
        case .form:
            content.scaleEffect(max(0.05, 0.1 + 0.9 * p)).rotationEffect(.degrees(60 * rest)).opacity(opacity)
        case .spin:
            content.offset(y: -34 * rest).blur(radius: 3 * rest).opacity(opacity)
        case .fromRight:
            content.offset(x: 40 * rest).opacity(opacity)
        case .stream:
            content.offset(x: -18 * rest).blur(radius: 2 * rest).opacity(opacity)
        case .none:
            content
        }
    }
}

/// A light bar that crosses the pane left to right (0.9 s), clipped to the glass.
private struct SheenSweep: View, Animatable {
    var progress: Double
    let isDark: Bool

    nonisolated var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        GeometryReader { proxy in
            let bar = proxy.size.width * 0.38
            let start = -1.2 * bar
            let end = proxy.size.width * 0.98 + 0.4 * bar
            LinearGradient(colors: [.clear, .white.opacity(isDark ? 0.10 : 0.30), .clear],
                           startPoint: .leading, endPoint: .trailing)
                .frame(width: bar, height: proxy.size.height * 1.2)
                .transformEffect(CGAffineTransform(a: 1, b: 0, c: -0.32, d: 1, tx: 0, ty: 0))
                .offset(x: start + (end - start) * progress, y: -proxy.size.height * 0.1)
        }
        .opacity(progress <= 0 || progress >= 1 ? 0 : 1)
        .allowsHitTesting(false)
    }
}

/// One place of the screen, drawn as glass (or hollow and hatched when it is empty, or a measured gap when it is a
/// breath). Pure drawing: the parent decides what happens when it is tapped.
struct LayoutGlassPane: View {
    let place: LayoutPlace
    let tint: Color
    let look: LayoutGlassLook
    let isEmpty: Bool
    let isSelected: Bool
    let roomName: String
    let positionLine: String
    /// Bumps when the label should move (steady panes only); `direction` is -1 for back, 1 for forward.
    let flipToken: Int
    let direction: Double
    /// Bumps for the sheen sweep.
    let sheenToken: Int
    let hidden: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var flip = 1.0
    @State private var sheen = 0.0

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: place.radius, style: .continuous)
    }

    var body: some View {
        let frame = place.paneFrame
        Group {
            if place.isGap {
                LayoutBreathMark(height: place.frame.height, tint: tint)
            } else if place.isPlate {
                plate
            } else {
                glass
            }
        }
        .frame(width: frame.width, height: frame.height)
        .opacity(hidden ? 0 : 1)
        .blur(radius: hidden ? 6 : 0)
        .scaleEffect(hidden ? 0.985 : 1)
        .position(x: frame.midX, y: frame.midY)
        .onChange(of: flipToken) { _, _ in playFlip() }
        .onChange(of: sheenToken) { _, _ in playSheen() }
    }

    // MARK: Plate and glass

    private var plate: some View {
        ZStack(alignment: .bottomTrailing) {
            RaisedGlass(shape: shape, tint: tint, look: look, relief: 0.5)
            Text("MASTHEAD")
                .font(LayoutFont.label(9.5, relativeTo: .caption2))
                .tracking(1.1)
                .foregroundStyle(tint.mix(with: Theme.Colors.inkSecondary, by: 0.5))
                .padding(.trailing, 14)
                .padding(.bottom, 7)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var glass: some View {
        let content = labels
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: place.name == "Title" ? .leading : .center)
            .padding(.horizontal, 12)
        if isEmpty {
            content
                .background { PressedIn(shape: shape, tint: tint, look: look) }
        } else {
            content
                .background {
                    if reduceTransparency {
                        shape.fill(Theme.Colors.paper)
                    }
                    RaisedGlass(shape: shape, tint: tint, look: look, relief: isSelected ? 1.6 : 1)
                }
                .overlay {
                    if isSelected {
                        shape.strokeBorder(tint.opacity(0.6), lineWidth: 1.5)
                    }
                    SheenSweep(progress: sheen, isDark: look.isDark).clipShape(shape)
                }
                .offset(x: isSelected ? -1 : 0, y: isSelected ? -2 : 0)
        }
    }

    // MARK: Labels

    private var inkTint: Color {
        tint.mix(with: Theme.Colors.ink, by: 0.18)
    }

    private var labels: some View {
        VStack(alignment: place.name == "Title" ? .leading : .center, spacing: 1) {
            if place.name == "Title" {
                Text(roomName)
                    .font(LayoutFont.title)
                    .foregroundStyle(tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(positionLine)
                    .font(LayoutFont.small)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            } else {
                Text(place.name)
                    .font(LayoutFont.label(12.5, relativeTo: .caption))
                    .foregroundStyle(inkTint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                if isEmpty {
                    Text("empty")
                        .font(LayoutFont.small)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                }
            }
        }
        .modifier(LabelMotion(progress: flip, motion: LayoutLabelMotion(place: place.name), direction: direction))
        .accessibilityHidden(true)
    }

    // MARK: Motion

    private func playFlip() {
        guard !reduceMotion, !place.isGap, !place.isPlate else { return }
        let motion = LayoutLabelMotion(place: place.name)
        guard motion != .none else { return }
        var reset = Transaction()
        reset.disablesAnimations = true
        withTransaction(reset) { flip = 0 }
        withTesseraAnimation(motion.animation.delay(motion.delay), reduceMotion: reduceMotion) { flip = 1 }
    }

    private func playSheen() {
        guard !reduceMotion, !place.isGap, !isEmpty else { return }
        var reset = Transaction()
        reset.disablesAnimations = true
        withTransaction(reset) { sheen = 0 }
        let wait = (60 + place.frame.minY * 0.5 + place.frame.minX * 0.2) / 1000
        withTesseraAnimation(.timingCurve(0.4, 0.1, 0.3, 1, duration: 0.9).delay(wait), reduceMotion: reduceMotion) {
            sheen = 1
        }
    }
}

/// A breath: not a pane but a measured gap, with end ticks and its height beside it.
struct LayoutBreathMark: View {
    let height: CGFloat
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            let mid = proxy.size.width / 2
            // The breath's frame is inset by 2 like a pane; the measure spans the true gap, 2 pt either side.
            let top: CGFloat = -2
            let bottom = proxy.size.height + 2
            Path { path in
                path.move(to: CGPoint(x: mid, y: top))
                path.addLine(to: CGPoint(x: mid, y: bottom))
                path.move(to: CGPoint(x: mid - 5, y: top))
                path.addLine(to: CGPoint(x: mid + 5, y: top))
                path.move(to: CGPoint(x: mid - 5, y: bottom))
                path.addLine(to: CGPoint(x: mid + 5, y: bottom))
            }
            .stroke(tint.opacity(0.4), lineWidth: 1)
            Text("\(Int(height))")
                .font(LayoutFont.number(9.5))
                .foregroundStyle(tint.mix(with: Theme.Colors.inkSecondary, by: 0.3))
                .position(x: mid + 14, y: proxy.size.height / 2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Breath, \(Int(height)) points")
    }
}

/// The fonts Layout mode sets, all through the active concept's pairing.
enum LayoutFont {
    static var title: Font {
        Theme.Typography.face(Theme.activeFonts.ui, size: 24, relativeTo: .title2, serif: false).weight(.bold)
    }

    static var small: Font {
        Theme.Typography.face(Theme.activeFonts.ui, size: 10.5, relativeTo: .caption2, serif: false).weight(.medium)
    }

    static func label(_ size: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        Theme.Typography.face(Theme.activeFonts.ui, size: size, relativeTo: style, serif: false).weight(.semibold)
    }

    static func number(_ size: CGFloat) -> Font {
        Theme.Typography.face(Theme.activeFonts.mono, size: size, relativeTo: .caption2, serif: false).weight(.medium)
    }

    static func body(_ size: CGFloat = 13.5) -> Font {
        Theme.Typography.face(Theme.activeFonts.ui, size: size, relativeTo: .footnote, serif: false)
    }
}
