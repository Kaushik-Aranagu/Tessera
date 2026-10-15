// swiftlint:disable identifier_name
import SwiftUI

// MARK: - Material tokens

/// "Zero tolerance" materials (docs/design/materials.md). Parts look milled from one block: boundaries are a cut,
/// a one-step tonal change and a chamfer catching a single light from above. No boxes, gaps, shadows or capsules.
struct MachinedMaterial: Sendable {
    struct Part: Sendable {
        var fill: UInt32
        /// Light (raised) or shade (recess) on the top inner edge.
        var top: (UInt32, Double)
        /// Shade (raised) or lip light (recess) on the bottom inner edge.
        var bottom: (UInt32, Double)
        var outline: (UInt32, Double)
        /// Recesses on dark anodising take a soft inner shadow instead of a hard top line.
        var innerShadow: Double = 0
    }

    var base: UInt32
    var raised: Part
    var recess: Part
    var seamDark: (UInt32, Double)
    var seamLight: (UInt32, Double)
    var ink: UInt32
    var inkSecondary: UInt32
    var inkDim: UInt32
    /// Brushed texture: alternating 1 pt rows (light, dark opacity) and their direction.
    var brush: (light: Double, dark: Double, vertical: Bool)

    // Paint: colour only for meaning.
    var live: UInt32
    var tess: UInt32
    var now: UInt32
    /// Cadmium is too light to read as text on aluminium; this is its text form.
    var nowText: UInt32
    var health: UInt32

    var glass: Glass

    struct Glass: Sendable {
        var radius: CGFloat
        var height: CGFloat
        var topLight: Double
        var bottomShade: Double
        var tint: (top: Double, bottom: Double)
    }

    /// Home: bead-blasted warm aluminium.
    static let aluminium = MachinedMaterial(
        base: 0xE7E3DC,
        raised: Part(fill: 0xECE9E3, top: (0xFFFFFF, 0.95), bottom: (0x000000, 0.07), outline: (0x28241E, 0.22)),
        recess: Part(fill: 0xDCD8D0, top: (0x000000, 0.10), bottom: (0xFFFFFF, 0.85), outline: (0x28241E, 0.16)),
        seamDark: (0x28241E, 0.22),
        seamLight: (0xFFFFFF, 0.8),
        ink: 0x1C1B1A,
        inkSecondary: 0x6E6A63,
        inkDim: 0x9C978E,
        brush: (0.035, 0.018, false),
        live: 0xC8452F,
        tess: 0x2E6DA4,
        now: 0xE0B341,
        nowText: 0x8A6A1C,
        health: 0x5E8C61,
        glass: Glass(radius: 16, height: 64, topLight: 0.95, bottomShade: 0.06, tint: (0.55, 0.25))
    )

    /// Workout: anodised graphite.
    static let graphite = MachinedMaterial(
        base: 0x1B1C1E,
        raised: Part(fill: 0x25262A, top: (0xFFFFFF, 0.10), bottom: (0x000000, 0.55), outline: (0x000000, 0.9)),
        recess: Part(
            fill: 0x131416,
            top: (0x000000, 0),
            bottom: (0xFFFFFF, 0.07),
            outline: (0x000000, 0.9),
            innerShadow: 0.7
        ),
        seamDark: (0x000000, 0.75),
        seamLight: (0xFFFFFF, 0.07),
        ink: 0xECE9E3,
        inkSecondary: 0x8B877F,
        inkDim: 0x5F5C57,
        brush: (0.012, 0.03, true),
        live: 0xD9563F,
        tess: 0x3F7FC0,
        now: 0xE8BD4C,
        nowText: 0xE8BD4C,
        health: 0x5E8C61,
        glass: Glass(radius: 18, height: 70, topLight: 0.18, bottomShade: 0.5, tint: (0.10, 0.03))
    )

    func color(_ hex: UInt32, _ opacity: Double = 1) -> Color {
        Color(hex: hex).opacity(opacity)
    }

    var baseColor: Color {
        color(base)
    }

    var inkColor: Color {
        color(ink)
    }

    var secondaryColor: Color {
        color(inkSecondary)
    }

    var dimColor: Color {
        color(inkDim)
    }

    var liveColor: Color {
        color(live)
    }

    var tessColor: Color {
        color(tess)
    }

    var nowColor: Color {
        color(now)
    }

    var nowTextColor: Color {
        color(nowText)
    }

    var healthColor: Color {
        color(health)
    }
}

extension EnvironmentValues {
    /// Which material the surrounding surface is milled from.
    @Entry var machined: MachinedMaterial = .aluminium
}

// MARK: - Radii (continuous, concentric: inner = outer − inset; never height / 2)

extension Theme {
    enum Machining {
        static let block: CGFloat = 22
        static let key: CGFloat = 16
        static let channelInset: CGFloat = 8
        static let well: CGFloat = 10
        static let inlay: CGFloat = 3
        /// Ruler ticks: 2 pt wide on a 9 pt pitch, 6 → 12 pt long when current.
        static let tickPitch: CGFloat = 9
        static let tickShort: CGFloat = 6
        static let tickLong: CGFloat = 12
        static let tickAnimation = Animation.snappy(duration: 0.22)
        /// The lit seam of a running process glints across about every 4.5 s.
        static let processGlintPeriod: Double = 4.5
    }
}

// MARK: - Surfaces

enum MachinedPart {
    case raised
    case recess
    /// A solid ink key (Start workout): raised geometry, ink fill.
    case ink
}

private struct MachinedSurface: ViewModifier {
    let part: MachinedPart
    let radius: CGFloat
    var fillOverride: Color?
    @Environment(\.machined) private var material

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        let spec = part == .recess ? material.recess : material.raised
        let fill: Color = fillOverride ?? (part == .ink ? material.inkColor : material.color(spec.fill))
        let top = part == .ink ? Color.white.opacity(0.22) : material.color(spec.top.0, spec.top.1)
        let bottom = part == .ink ? Color.black.opacity(0.4) : material.color(spec.bottom.0, spec.bottom.1)
        content
            .background {
                ZStack {
                    if spec.innerShadow > 0 {
                        shape.fill(fill.shadow(.inner(color: .black.opacity(spec.innerShadow), radius: 2, y: 1)))
                    } else {
                        shape.fill(fill)
                    }
                    // One light from above: it catches the top chamfer and leaves a shade (or a lip) at the bottom.
                    shape.strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: top, location: 0),
                                .init(color: top.opacity(0), location: 0.12),
                                .init(color: bottom.opacity(0), location: 0.88),
                                .init(color: bottom, location: 1),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                    shape.stroke(material.color(spec.outline.0, spec.outline.1), lineWidth: 0.5)
                }
            }
    }
}

extension View {
    /// A milled part: raised (lit top chamfer, shade below) or recessed (the reverse). Corners are continuous.
    func machined(_ part: MachinedPart, radius: CGFloat, fill: Color? = nil) -> some View {
        modifier(MachinedSurface(part: part, radius: radius, fillOverride: fill))
    }
}

/// The ground every machined screen sits on, with its optional brushed grain.
struct MachinedGround: View {
    @Environment(\.machined) private var material

    var body: some View {
        Canvas(rendersAsynchronously: true) { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(material.baseColor))
            let step: CGFloat = 2
            let light = GraphicsContext.Shading.color(.white.opacity(material.brush.light))
            let dark = GraphicsContext.Shading.color(.black.opacity(material.brush.dark))
            if material.brush.vertical {
                for x in stride(from: 0, to: size.width, by: step) {
                    context.fill(Path(CGRect(x: x, y: 0, width: 1, height: size.height)), with: light)
                    context.fill(Path(CGRect(x: x + 1, y: 0, width: 1, height: size.height)), with: dark)
                }
            } else {
                for y in stride(from: 0, to: size.height, by: step) {
                    context.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)), with: light)
                    context.fill(Path(CGRect(x: 0, y: y + 1, width: size.width, height: 1)), with: dark)
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// A cut between two surfaces: a dark hairline with a light one directly below, each one device pixel.
struct Seam: View {
    var axis: Axis = .horizontal
    @Environment(\.machined) private var material
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        let pixel = 1 / displayScale
        let dark = material.color(material.seamDark.0, material.seamDark.1)
        let light = material.color(material.seamLight.0, material.seamLight.1)
        Group {
            if axis == .horizontal {
                VStack(spacing: 0) {
                    dark.frame(height: pixel)
                    light.frame(height: pixel)
                }
            } else {
                HStack(spacing: 0) {
                    dark.frame(width: pixel)
                    light.frame(width: pixel)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Position indicators (no dots, no capsules)

/// A ruler of ticks: the current one is long and inked. Horizontal for x (lanes, siblings), vertical inside a well
/// for y. `position` may be fractional while scrolling; the nearest tick is current.
struct Ruler: View {
    let count: Int
    let position: Double
    var axis: Axis = .horizontal
    @Environment(\.machined) private var material
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let current = Int(position.rounded())
        let layout = axis == .horizontal
            ? AnyLayout(HStackLayout(alignment: .top, spacing: Theme.Machining.tickPitch - 2))
            : AnyLayout(VStackLayout(alignment: .trailing, spacing: Theme.Machining.tickPitch - 2))
        layout {
            ForEach(0 ..< count, id: \.self) { index in
                let isCurrent = index == current
                let length = isCurrent ? Theme.Machining.tickLong : Theme.Machining.tickShort
                Rectangle()
                    .fill(isCurrent ? material.inkColor : material.inkColor.opacity(0.3))
                    .frame(width: axis == .horizontal ? 2 : length, height: axis == .horizontal ? length : 2)
            }
        }
        .frame(
            height: axis == .horizontal ? Theme.Machining.tickLong : nil,
            alignment: .top
        )
        .animation(MotionPolicy.resolve(Theme.Machining.tickAnimation, reduceMotion: reduceMotion), value: current)
        .accessibilityElement()
        .accessibilityLabel("\(current + 1) of \(count)")
    }
}

/// Engraved sibling names over a recessed 4 pt track; an ink carriage one-n-th wide follows the scroll continuously,
/// like a part sliding in a track.
struct SiblingRail: View {
    let titles: [String]
    /// 0 … titles.count − 1, fractional while paging.
    let progress: Double
    var onSelect: (Int) -> Void = { _ in }
    @Environment(\.machined) private var material

    var body: some View {
        let current = Int(progress.rounded())
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                ForEach(Array(titles.enumerated()), id: \.offset) { index, title in
                    Button { onSelect(index) } label: {
                        Text(title)
                            .textRole(.labelStrong)
                            .tracking(0.06 * 16)
                            .foregroundStyle(index == current ? material.inkColor : material.dimColor)
                            .frame(maxWidth: .infinity, alignment: alignment(index))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(index == current ? .isSelected : [])
                }
            }
            .animation(.snappy(duration: 0.2), value: current)
            GeometryReader { proxy in
                let width = proxy.size.width / CGFloat(max(titles.count, 1))
                ZStack(alignment: .leading) {
                    Color.clear.machined(.recess, radius: 1)
                    Rectangle()
                        .fill(material.inkColor)
                        .overlay(alignment: .top) { Color.white.opacity(0.25).frame(height: 1) }
                        .clipShape(RoundedRectangle(cornerRadius: 1))
                        .frame(width: width)
                        .offset(x: width * CGFloat(progress))
                }
            }
            .frame(height: 4)
            .accessibilityHidden(true)
        }
    }

    private func alignment(_ index: Int) -> Alignment {
        if index == 0 {
            return .leading
        }
        return index == titles.count - 1 ? .trailing : .center
    }
}

/// A running process: a lit 3 pt seam along the very top edge, with a glint sweeping across. Replaces every pill.
struct ProcessSeam: View {
    var color: Color = MachinedMaterial.aluminium.liveColor
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 60, paused: reduceMotion)) { context in
            let period = Theme.Machining.processGlintPeriod
            let t = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period) / period
            // The glint crosses in the first 30% of each period, then the seam just glows.
            let sweep = reduceMotion ? -1 : min(t / 0.3, 1)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    color
                    LinearGradient(
                        colors: [color.opacity(0), Color(hex: 0xFFE2A8), color.opacity(0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: proxy.size.width * 0.3)
                    .offset(x: proxy.size.width * (1.3 - 1.6 * sweep) - proxy.size.width * 0.3)
                    .opacity(sweep >= 1 || sweep < 0 ? 0 : 1)
                }
            }
            .frame(height: 2)
            .shadow(color: color.opacity(0.6), radius: 7)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Keys

/// A raised key with a recessed channel inset 8 pt. Holding fills the channel left to right; letting go early
/// empties it. Completion fires once, with a firm haptic.
struct HoldKey<Label: View, Meta: View>: View {
    var height: CGFloat = 62
    var radius: CGFloat = Theme.Machining.well
    var duration: Double = Theme.Motion.holdDuration
    var fill: AnyShapeStyle
    /// Tap instead of hold (e.g. "Skip rest").
    var isTap = false
    let action: () -> Void
    @ViewBuilder var label: () -> Label
    @ViewBuilder var meta: () -> Meta

    @GestureState private var isPressing = false
    @State private var progress: CGFloat = 0
    @State private var completions = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.machined) private var material

    var body: some View {
        let inset = Theme.Machining.channelInset
        let channel = RoundedRectangle(cornerRadius: max(radius - inset, 3), style: .continuous)
        ZStack {
            Color.clear
                .machined(.recess, radius: max(radius - inset, 3))
                .overlay(alignment: .leading) {
                    GeometryReader { proxy in
                        Rectangle()
                            .fill(fill)
                            .overlay(alignment: .top) { Color.white.opacity(0.35).frame(height: 1) }
                            .frame(width: proxy.size.width * progress)
                    }
                }
                .clipShape(channel)
                .overlay {
                    HStack {
                        label()
                        Spacer(minLength: Theme.Spacing.s)
                        meta()
                    }
                    .padding(.horizontal, 16)
                }
                .padding(inset)
        }
        .frame(height: height)
        .machined(.raised, radius: radius)
        .scaleEffect(isPressing && !reduceMotion ? 0.995 : 1)
        .contentShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .gesture(isTap ? nil : hold)
        .onTapGesture {
            if isTap {
                complete()
            }
        }
        .onChange(of: isPressing) { _, pressing in
            if pressing {
                // The fill tracks the hold literally, so it is linear in time.
                withAnimation(.linear(duration: duration)) { progress = 1 }
            } else if progress < 1 {
                withAnimation(.easeOut(duration: 0.22)) { progress = 0 }
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: isPressing) { _, new in new }
        .sensoryFeedback(.impact(flexibility: .rigid, intensity: 1), trigger: completions)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { complete() }
    }

    private var hold: some Gesture {
        LongPressGesture(minimumDuration: duration, maximumDistance: 30)
            .updating($isPressing) { current, state, _ in state = current }
            .onEnded { _ in complete() }
    }

    private func complete() {
        completions += 1
        action()
        withAnimation(MotionPolicy.resolve(.easeOut(duration: 0.22), reduceMotion: reduceMotion).delay(0.12)) {
            progress = 0
        }
    }
}

extension HoldKey where Meta == EmptyView {
    init(
        height: CGFloat = 62,
        radius: CGFloat = Theme.Machining.well,
        duration: Double = Theme.Motion.holdDuration,
        fill: AnyShapeStyle,
        isTap: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.init(height: height, radius: radius, duration: duration, fill: fill, isTap: isTap, action: action,
                  label: label, meta: { EmptyView() })
    }
}

// MARK: - Glass lens

/// Floating chrome only: Liquid Glass shaped as a flush machined lens (never a capsule), with its own chamfer.
private struct GlassLens: ViewModifier {
    @Environment(\.machined) private var material

    func body(content: Content) -> some View {
        let glass = material.glass
        let shape = RoundedRectangle(cornerRadius: glass.radius, style: .continuous)
        content
            .frame(height: glass.height)
            .background {
                shape.fill(LinearGradient(
                    colors: [.white.opacity(glass.tint.top), .white.opacity(glass.tint.bottom)],
                    startPoint: .top,
                    endPoint: .bottom
                ))
            }
            .glassEffect(.regular.interactive(), in: shape)
            .overlay {
                shape.strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(glass.topLight), location: 0),
                            .init(color: .white.opacity(0), location: 0.1),
                            .init(color: .black.opacity(0), location: 0.9),
                            .init(color: .black.opacity(glass.bottomShade), location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
                .allowsHitTesting(false)
            }
    }
}

extension View {
    func glassLens() -> some View {
        modifier(GlassLens())
    }
}

// MARK: - Type helpers

extension Theme {
    /// The display face with tabular lining numerals: weights, reps, rest. (Fraunces in Plein.)
    static func numeral(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        Typography.face(concept.fonts.display, size: size, relativeTo: size > 40 ? .largeTitle : .title, serif: true)
            .weight(weight)
            .monospacedDigit()
    }

    /// Tess and context lines speak in the serif voice. Upright: Kaushik ruled out italics everywhere (2026-10-15).
    static func voice(size: CGFloat) -> Font {
        Typography.face(concept.fonts.voice, size: size, relativeTo: .body, serif: true)
    }

    static var voice: Font {
        voice(size: 21)
    }
}
