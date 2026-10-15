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

    /// The only ambient motion on the ground: one wash drifting ±12 pt (14 s light, 16 s dark). Driven by a
    /// repeating animation, so Core Animation moves it and the view tree isn't re-evaluated every frame.
    private func drift(size: CGSize, dark: Bool) -> some View {
        DriftingWash(dark: dark).position(x: size.width + 70, y: dark ? 340 : 220)
    }
}

private struct DriftingWash: View {
    let dark: Bool
    @State private var away = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let tint = dark ? Color(hex: 0x7A5C8E).opacity(0.35) : Color(hex: 0xE9B7A8).opacity(0.5)
        Ellipse()
            .fill(RadialGradient(colors: [tint, tint.opacity(0)], center: .center, startRadius: 0, endRadius: 140))
            .frame(width: dark ? 300 : 260, height: dark ? 240 : 200)
            .scaleEffect(away ? 1.08 : 1)
            .offset(x: away ? -12 : 0, y: away ? 8 : 0)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: dark ? 8 : 7).repeatForever(autoreverses: true)) { away = true }
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
        // A tiled image is composited by Core Animation; an image fill would be re-rasterised on the CPU every
        // time anything above it animates.
        if let tile = Self.tile {
            tile.resizable(resizingMode: .tile)
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

/// The stroke word (docs/design/no-buttons.md): the one primary action on a screen, shown as a word sitting in a
/// dry brushstroke of the action's paint. No container, no corners, no shadow. Tap actions wet the stroke on touch
/// and fire on release; hold actions empty to a trace, repaint left to right under the thumb over `duration`, then
/// bloom at the tip and fire. `height` is the hit height; the hit area spans the full width.
struct PaintKey<Label: View, Meta: View>: View {
    enum Finish { case ink, cream }

    /// Kept for API compatibility; the word's colour follows the ground (ink on light, cream on dark).
    var finish: Finish = .ink
    var paint: Color = Theme.Colors.live
    var duration: Double = Theme.Motion.holdDuration
    var isTap = false
    var height: CGFloat = 64
    /// How far the finger may wander while holding before the hold cancels.
    var drift: CGFloat = 30
    let action: () -> Void
    /// Receives whether the word is being held. The word itself shouldn't change ("HOLD" lives in the meta).
    @ViewBuilder var label: (Bool) -> Label
    /// On the same baseline to the right, in the label style: "HOLD · 82.5 × 5".
    @ViewBuilder var meta: () -> Meta

    @GestureState private var isPressing = false
    @State private var fill: CGFloat = 1
    @State private var wet = false
    @State private var bloom: CGFloat = 1
    @State private var completions = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        let dark = colorScheme == .dark
        let ink = dark ? Color(hex: 0xF3ECE0) : Theme.Colors.ink
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            label(isPressing)
                .font(InkWordType.font)
                .foregroundStyle(ink.opacity(isEnabled ? 1 : 0.4))
                .offset(y: wet && !reduceMotion ? 1 : 0)
                .background(alignment: .bottom) { stroke }
                .fixedSize()
            meta()
                .textRole(.label)
                .foregroundStyle(ink.opacity(0.6))
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: height, alignment: .leading)
        .contentShape(Rectangle())
        .gesture(isTap ? nil : hold)
        .simultaneousGesture(isTap ? tapPress : nil)
        .onChange(of: isPressing) { _, pressing in
            guard !isTap else { return }
            if pressing {
                // Empty to a dry trace, then repaint left to right under the thumb, easing out.
                fill = 0
                withAnimation(reduceMotion ? .linear(duration: duration) : .timingCurve(0.2, 0.6, 0.35, 1,
                                                                                        duration: duration))
                {
                    fill = 1
                }
            } else if completionsSnapshot == completions {
                // Let go early: the paint drains back.
                withAnimation(.easeIn(duration: 0.22)) { fill = 1 }
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: isPressing) { _, new in new && !isTap }
        .sensoryFeedback(.selection, trigger: completions) { _, _ in isTap }
        .sensoryFeedback(.impact(flexibility: .rigid, intensity: 1), trigger: completions) { _, _ in !isTap }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(isTap ? "" : "Touch and hold")
        .accessibilityAction { complete() }
    }

    @State private var completionsSnapshot = 0

    @ViewBuilder private var stroke: some View {
        if isEnabled {
            let holding = isPressing && !isTap
            ZStack(alignment: .leading) {
                // The dry trace while a hold empties the stroke.
                InkStroke(seed: 3)
                    .fill(paint.opacity(holding ? 0.2 : 0))
                InkStroke(seed: 3)
                    .fill(paint.opacity(wet ? 1 : 0.82))
                    .mask(alignment: .leading) {
                        GeometryReader { proxy in
                            Rectangle().frame(width: proxy.size.width * (holding ? fill : 1))
                        }
                    }
            }
            .frame(height: 19)
            .scaleEffect(x: 1, y: (wet && !reduceMotion ? 1.65 : 1) * bloom, anchor: UnitPoint(x: 0.5, y: 0.7))
            .blur(radius: wet && !reduceMotion ? 1 : 0)
            .padding(.horizontal, -7)
            .offset(y: 3)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    /// Tap words wet on touch-down and fire on release.
    private var tapPress: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                guard !wet else { return }
                withAnimation(MotionPolicy.resolve(.easeOut(duration: 0.12), reduceMotion: reduceMotion)) { wet = true }
            }
            .onEnded { value in
                withAnimation(MotionPolicy.resolve(Theme.Motion.house, reduceMotion: reduceMotion)) { wet = false }
                if abs(value.translation.width) < drift, abs(value.translation.height) < drift {
                    complete()
                }
            }
    }

    private var hold: some Gesture {
        LongPressGesture(minimumDuration: duration, maximumDistance: drift)
            .updating($isPressing) { current, state, _ in state = current }
            .onEnded { _ in complete() }
    }

    private func complete() {
        completions += 1
        completionsSnapshot = completions
        if !isTap, !reduceMotion {
            // The tip blooms, then settles.
            withAnimation(.easeOut(duration: 0.13)) { bloom = 1.9 }
            withAnimation(.easeInOut(duration: 0.13).delay(0.13)) { bloom = 1.2 }
            withAnimation(Theme.Motion.house.delay(0.4)) { bloom = 1 }
        }
        fill = 1
        action()
    }
}

extension PaintKey where Meta == EmptyView {
    init(finish: Finish = .ink, paint: Color = Theme.Colors.live, duration: Double = Theme.Motion.holdDuration,
         isTap: Bool = false, height: CGFloat = 64, drift: CGFloat = 30, action: @escaping () -> Void,
         @ViewBuilder label: @escaping (Bool) -> Label)
    {
        self.init(finish: finish, paint: paint, duration: duration, isTap: isTap, height: height, drift: drift,
                  action: action, label: label, meta: { EmptyView() })
    }
}

private enum InkWordType {
    /// Title 34/500, the stroke word's size.
    static var font: Font {
        Theme.Typography.face(Theme.concept.fonts.display, size: 34, relativeTo: .title, serif: false).weight(.medium)
    }
}
