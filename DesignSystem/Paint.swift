// swiftlint:disable identifier_name
import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

// Plein air (docs/design/materials.md): impressionist washes over paper, paper grain, paint for meaning.
// Precision lives only at the edges (key hairlines, one lit chamfer, the tick dial, the lit process seam).

// MARK: - Ground

/// Plein's field: soft radial washes over paper, one slow drifting wash and grain, by the colour scheme (light on
/// cream; the dark variant is Plein's old night ground, kept for Plein pinned on a dark-mode phone).
struct PleinGround: View {
    /// Plein's dark variant (its old workout plum), named so it isn't a stray literal.
    static let nightGround: UInt32 = 0x1C1828

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
                Color(hex: dark ? PleinGround.nightGround : Look.plein.ground)
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
        let tilt = Double((seed &* 37) % 17) - 8
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
        // Any seed is fine, hash values included: negative ones fold back into range.
        let shift = abs(seed % 4)
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
/// fine ink line of the action's paint (docs/design/ink-line.md). No container, no corners, no shadow. Tap actions
/// wet the line on touch and fire on release; hold actions empty to a trace, repaint left to right under the thumb
/// over `duration`, then a bead swells at the tip and they fire. `height` is the hit height; the hit area spans
/// the full width.
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
    @State private var drawnIn = false
    @State private var dried = false
    /// Each release runs the sheen once (keyframes).
    @State private var releases = 0
    @State private var completions = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.onWorkoutGround) private var onWorkoutGround
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        let ink = onWorkoutGround ? Theme.Colors.Workout.ink : Theme.Colors.ink
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
        .sensoryFeedback(.impact(weight: .medium, intensity: 0.8), trigger: completions) { _, _ in !isTap }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(isTap ? "" : "Touch and hold")
        .accessibilityAction { complete() }
    }

    @State private var completionsSnapshot = 0

    @ViewBuilder private var stroke: some View {
        if isEnabled {
            let holding = isPressing && !isTap
            // docs/design/ink-line.md: a fine tapered swash under the word, never behind the letters. 2.5 pt at rest
            // and 75%; wet 4 pt at 100%; a hold empties it to a 0.9 pt trace and repaints 2.5 to 3.6 pt.
            let thickness: CGFloat = holding ? 0.9 : (wet && !reduceMotion ? 4 : 2.5)
            ZStack(alignment: .leading) {
                InkLine(thickness: thickness)
                    .fill(paint.opacity(holding ? 0.35 : (wet || !dried ? 1 : 0.75)))
                if holding {
                    InkLine(thickness: reduceMotion ? 2.5 : 2.5 + 1.1 * fill)
                        .fill(paint)
                        .mask(alignment: .leading) {
                            GeometryReader { proxy in
                                Rectangle().frame(width: proxy.size.width * fill)
                            }
                        }
                }
                if !reduceMotion {
                    // The release sheen: a band running along the line, left to right.
                    // Keyframes, so the run plays even though its start and end values are set together.
                    GeometryReader { proxy in
                        LinearGradient(colors: [.clear, sheenColor, .clear], startPoint: .leading,
                                       endPoint: .trailing)
                            .frame(width: proxy.size.width * 0.35)
                            .keyframeAnimator(initialValue: Sheen(), trigger: releases) { band, value in
                                band.offset(x: proxy.size.width * (value.travel * 1.35 - 0.35)).opacity(value.alpha)
                            } keyframes: { _ in
                                KeyframeTrack(\.travel) {
                                    LinearKeyframe(0, duration: 0)
                                    LinearKeyframe(1, duration: 0.52, timingCurve: .easeInOut)
                                }
                                KeyframeTrack(\.alpha) {
                                    LinearKeyframe(1, duration: 0.04)
                                    LinearKeyframe(1, duration: 0.4)
                                    LinearKeyframe(0, duration: 0.08)
                                }
                            }
                    }
                    .mask { InkLine(thickness: thickness) }
                    // The completion bead at the tip: r 0 → 5 → 7 as it fades (520 ms).
                    Circle()
                        .fill(paint)
                        .keyframeAnimator(initialValue: Bead(), trigger: completions) { dot, value in
                            dot.frame(width: max(value.radius, 0) * 2, height: max(value.radius, 0) * 2)
                                .opacity(isTap ? 0 : value.alpha)
                                .offset(x: value.radius)
                        } keyframes: { _ in
                            KeyframeTrack(\.radius) {
                                LinearKeyframe(0, duration: 0)
                                LinearKeyframe(5, duration: 0.2, timingCurve: .easeOut)
                                LinearKeyframe(7, duration: 0.32, timingCurve: .easeOut)
                            }
                            KeyframeTrack(\.alpha) {
                                LinearKeyframe(1, duration: 0.2)
                                LinearKeyframe(0, duration: 0.32)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .mask(alignment: .leading) {
                // Arrival: drawn in from the left.
                GeometryReader { proxy in
                    Rectangle().frame(width: proxy.size.width * (drawnIn || reduceMotion ? 1 : 0))
                }
            }
            .frame(height: 12)
            .padding(.leading, -2)
            .padding(.trailing, -4)
            // Centre 7 pt below the baseline (the text frame ends about 8 pt under it at 34 pt).
            .offset(y: 5)
            .tesseraAnimation(.easeOut(duration: 0.12), value: wet)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onAppear(perform: arrive)
        }
    }

    private var sheenColor: Color {
        ThemeStore.shared.paintLook.isDark ? Theme.Colors.sheen : .white.opacity(0.85)
    }

    private func arrive() {
        guard !drawnIn else { return }
        withTesseraAnimation(Theme.Motion.house.speed(0.42 / 0.36), reduceMotion: reduceMotion) { drawnIn = true }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(360))
            if let dry = Theme.Motion.dry(reduceMotion: reduceMotion) {
                withAnimation(dry) { dried = true }
            } else {
                dried = true
            }
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
                runSheen()
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
        fill = 1
        // A hold's bead and haptic land at once, and the action follows 200 ms later so the page doesn't swallow
        // the bead (Design M1). Taps fire straight away.
        guard !isTap, !reduceMotion else { return action() }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            action()
        }
    }

    /// The sheen runs along the line once, then it dries back.
    private func runSheen() {
        guard !reduceMotion else { return }
        releases += 1
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

enum InkWordType {
    /// Title 34/500, the stroke word's size.
    static var font: Font {
        Theme.Typography.face(Theme.concept.fonts.display, size: 34, relativeTo: .title, serif: false).weight(.medium)
    }
}

extension EnvironmentValues {
    /// True on the workout's ground. Ink there is `Theme.Colors.Workout.ink`, which is the look's own ink (one base
    /// across the app), held for as long as the workout is open.
    @Entry var onWorkoutGround = false
}

/// The ink line (docs/design/ink-line.md): a lens, thickest just left of centre and tapering to a hairline at both
/// ends, drawn on a w x 12 box: M0 6 Q .42w (6-t) w 5.6 Q .58w (6+t) 0 6 Z. `thickness` animates.
struct InkLine: Shape {
    var thickness: CGFloat = 2.5

    var animatableData: CGFloat {
        get { thickness }
        set { thickness = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let y = rect.minY + rect.height / 2
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: y))
        path.addQuadCurve(to: CGPoint(x: rect.minX + w, y: y - 0.4),
                          control: CGPoint(x: rect.minX + 0.42 * w, y: y - thickness))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: y),
                          control: CGPoint(x: rect.minX + 0.58 * w, y: y + thickness))
        path.closeSubpath()
        return path
    }
}

/// The release sheen's run along the ink line: hidden at rest.
private struct Sheen {
    var travel: CGFloat = 0
    var alpha: Double = 0
}

/// The hold's completion bead: hidden at rest.
private struct Bead {
    var radius: CGFloat = 0
    var alpha: Double = 0
}
