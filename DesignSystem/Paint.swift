// swiftlint:disable identifier_name
import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

// Plein air (docs/design/materials.md): impressionist washes over paper, paper grain, paint for meaning.
// Precision lives only at the edges (key hairlines, one lit chamfer, the tick dial, the lit process seam).

// MARK: - Ground

/// Soft radial washes over paper, one slow drifting wash and grain. Light on Home, dark in the workout
/// (follows the colour scheme, so the workout's `.preferredColorScheme(.dark)` gets the dark ground).
struct PleinGround: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Wash {
        let color: UInt32
        let opacity: Double
        let center: UnitPoint
        let size: CGSize
    }

    var body: some View {
        let dark = colorScheme == .dark
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                Color(hex: dark ? 0x1C1828 : 0xF2ECE3)
                ForEach(Array(washes(dark: dark).enumerated()), id: \.offset) { _, wash in
                    RadialGradient(
                        colors: [Color(hex: wash.color).opacity(wash.opacity), Color(hex: wash.color).opacity(0)],
                        center: wash.center,
                        startRadius: 0,
                        endRadius: max(size.width * wash.size.width, size.height * wash.size.height) * 0.7
                    )
                }
                drift(size: size, dark: dark)
                PaperGrain()
                    .blendMode(dark ? .softLight : .multiply)
                    .opacity(dark ? 0.35 : 0.3)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func washes(dark: Bool) -> [Wash] {
        dark
            ? [
                Wash(
                    color: 0x3B2D57,
                    opacity: 1,
                    center: UnitPoint(x: 0, y: 0.1),
                    size: CGSize(width: 0.7, height: 0.45)
                ),
                Wash(
                    color: 0x1E3D4A,
                    opacity: 1,
                    center: UnitPoint(x: 1, y: 0.55),
                    size: CGSize(width: 0.7, height: 0.5)
                ),
                Wash(
                    color: 0x45302A,
                    opacity: 1,
                    center: UnitPoint(x: 0.2, y: 1),
                    size: CGSize(width: 0.7, height: 0.4)
                ),
            ]
            : [
                Wash(
                    color: 0xF7E6B8,
                    opacity: 1,
                    center: UnitPoint(x: 0.85, y: 0.06),
                    size: CGSize(width: 0.6, height: 0.4)
                ),
                Wash(
                    color: 0xD8CBE6,
                    opacity: 1,
                    center: UnitPoint(x: 0, y: 0.3),
                    size: CGSize(width: 0.7, height: 0.45)
                ),
                Wash(
                    color: 0xBFD8E2,
                    opacity: 1,
                    center: UnitPoint(x: 1, y: 0.7),
                    size: CGSize(width: 0.8, height: 0.5)
                ),
                Wash(
                    color: 0xC9DDB8,
                    opacity: 1,
                    center: UnitPoint(x: 0.1, y: 1),
                    size: CGSize(width: 0.7, height: 0.4)
                ),
            ]
    }

    /// The only ambient motion on the ground: one wash drifting ±12 pt (14 s light, 16 s dark).
    private func drift(size: CGSize, dark: Bool) -> some View {
        TimelineView(.animation(minimumInterval: 1 / 20, paused: reduceMotion)) { context in
            let period: Double = dark ? 16 : 14
            let phase = sin(context.date.timeIntervalSinceReferenceDate / period * 2 * .pi)
            let tint = dark ? Color(hex: 0x7A5C8E).opacity(0.35) : Color(hex: 0xE9B7A8).opacity(0.5)
            Ellipse()
                .fill(RadialGradient(colors: [tint, tint.opacity(0)], center: .center, startRadius: 0, endRadius: 140))
                .frame(width: dark ? 300 : 260, height: dark ? 240 : 200)
                .scaleEffect(1 + 0.04 * (1 - phase))
                .offset(x: -12 * (1 - phase), y: 8 * (1 - phase))
                .position(x: size.width + (dark ? 70 : 70), y: dark ? 340 : 220)
        }
    }
}

/// Fractal paper grain, generated once and tiled.
struct PaperGrain: View {
    @MainActor private static let tile: Image? = {
        let noise = CIFilter.randomGenerator().outputImage?
            .cropped(to: CGRect(x: 0, y: 0, width: 160, height: 160))
            .applyingFilter("CIColorControls", parameters: [kCIInputSaturationKey: 0, kCIInputContrastKey: 0.6])
        guard let noise, let cg = CIContext().createCGImage(noise, from: noise.extent) else { return nil }
        return Image(decorative: cg, scale: 2)
    }()

    var body: some View {
        if let tile = Self.tile {
            Rectangle().fill(.image(tile, sourceRect: CGRect(x: 0, y: 0, width: 1, height: 1), scale: 1))
        }
    }
}

// MARK: - Paint marks

/// A small marker: an irregular paint dab (≈18×15, uneven radii, rotated a few degrees, slightly blurred). Never a dot.
struct PaintDab: View {
    var color: Color
    var size = CGSize(width: 18, height: 15)
    /// Keeps a dab's shape and tilt stable per item.
    var seed: Int = 0
    var filled = true

    var body: some View {
        let tilt = Double((seed * 37) % 17) - 8
        DabShape(seed: seed)
            .fill(filled ? color : .clear)
            .overlay {
                if !filled {
                    DabShape(seed: seed).stroke(color, lineWidth: 1.5)
                }
            }
            .frame(width: size.width, height: size.height)
            .rotationEffect(.degrees(tilt))
            .blur(radius: 0.5)
            .accessibilityHidden(true)
    }
}

/// An ellipse with four uneven radii, like `55% 45% 60% 40% / 50% 60% 40% 50%`.
struct DabShape: Shape {
    var seed: Int = 0

    func path(in rect: CGRect) -> Path {
        let jitter: [CGFloat] = [0.55, 0.45, 0.6, 0.4, 0.5, 0.6, 0.4, 0.5]
        let shift = seed % 4
        func j(_ i: Int) -> CGFloat {
            jitter[(i + shift * 2) % jitter.count]
        }
        let w = rect.width, h = rect.height
        // Corner radii (horizontal, vertical) for TL, TR, BR, BL.
        let tl = CGSize(width: w * j(0), height: h * j(4))
        let tr = CGSize(width: w * j(1), height: h * j(5))
        let br = CGSize(width: w * j(2), height: h * j(6))
        let bl = CGSize(width: w * j(3), height: h * j(7))
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + tl.width, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + tr.height),
                          control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - br.width, y: rect.maxY),
                          control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - bl.height),
                          control: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX + tl.width, y: rect.minY),
                          control: CGPoint(x: rect.minX, y: rect.minY))
        return path
    }
}

/// One brushstroke (a logged set; the day). `progress` draws it in left to right.
struct Brushstroke: Shape {
    var progress: CGFloat = 1

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        // M4 12 C 18 5, 40 15, 60 7 on a 64 × 20 box.
        let sx = rect.width / 64, sy = rect.height / 20
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy)
        }
        var path = Path()
        path.move(to: p(4, 12))
        path.addCurve(to: p(60, 7), control1: p(18, 5), control2: p(40, 15))
        return path.trimmedPath(from: 0, to: progress)
    }
}

// MARK: - Keys

/// A hold-to-act key: radius 14 (never height/2), a 0.5 pt hairline, one lit top chamfer and a soft drop. While you
/// hold, paint spreads through it as a blurred radial blot growing from the thumb side; letting go drains it.
/// `isTap` keys act on a tap (Skip rest, Next exercise).
struct PaintKey<Label: View>: View {
    enum Finish { case ink, cream }

    var finish: Finish = .ink
    var paint: Color = Theme.Colors.live
    var duration: Double = Theme.Motion.holdDuration
    var isTap = false
    var height: CGFloat = 58
    let action: () -> Void
    /// Receives whether the key is being held (labels turn to "Keep holding").
    @ViewBuilder var label: (Bool) -> Label

    @GestureState private var isPressing = false
    @State private var spread: CGFloat = 0
    @State private var completions = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    private static var radius: CGFloat {
        14
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Self.radius, style: .continuous)
        let dark = colorScheme == .dark
        let ground = finish == .ink ? Theme.Colors.ink : Color(hex: 0xF3ECE0)
        let foreground = finish == .ink ? Theme.Colors.paper : Color(hex: 0x1C1828)
        label(isPressing)
            .foregroundStyle(spread > 0.35 ? Color(hex: 0xF3ECE0) : foreground)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, minHeight: height, alignment: .leading)
            .background {
                ZStack {
                    ground
                    GeometryReader { proxy in
                        // The blot is anchored 12% from the left (the thumb side) and grows past the key's far edge.
                        let diameter = proxy.size.width * 2.3
                        Circle()
                            .fill(RadialGradient(
                                colors: [paint, paint, paint.opacity(0)],
                                center: .center,
                                startRadius: 0,
                                endRadius: diameter / 2
                            ))
                            .frame(width: diameter, height: diameter)
                            .scaleEffect(spread, anchor: .center)
                            .position(x: proxy.size.width * 0.12, y: proxy.size.height / 2)
                            .blur(radius: 4)
                    }
                }
                .clipShape(shape)
            }
            .overlay {
                shape.strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(finish == .ink ? 0.18 : 0.7), location: 0),
                            .init(color: .white.opacity(0), location: 0.08),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
            }
            .overlay { shape.stroke(dark ? Color.black.opacity(0.6) : Theme.Colors.ink.opacity(0.5), lineWidth: 0.5) }
            .shadow(color: dark ? .black.opacity(0.35) : Theme.Colors.ink.opacity(0.14), radius: dark ? 14 : 9,
                    y: dark ? 10 : 6)
            .contentShape(shape)
            .scaleEffect(isPressing && !reduceMotion ? 0.985 : 1)
            .animation(Theme.Motion.snappy, value: isPressing)
            .gesture(isTap ? nil : hold)
            .onTapGesture {
                if isTap {
                    complete()
                }
            }
            .onChange(of: isPressing) { _, pressing in
                if pressing {
                    // Paint fills, it doesn't wipe: the spread eases in as it soaks through.
                    withAnimation(.timingCurve(0.3, 0.1, 0.4, 1, duration: duration)) { spread = 1 }
                } else if spread < 1 {
                    withAnimation(.easeOut(duration: 0.22)) { spread = 0 }
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
        withAnimation(MotionPolicy.resolve(.easeOut(duration: 0.3), reduceMotion: reduceMotion).delay(0.15)) {
            spread = 0
        }
    }
}
