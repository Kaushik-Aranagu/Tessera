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

struct ProcessSeam: View {
    var color: Color = Theme.Colors.live
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
                        colors: [color.opacity(0), Theme.Colors.sheen, color.opacity(0)],
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

// MARK: - Type helpers

extension Theme {
    /// The display face with tabular lining numerals: weights, reps, rest. (Fraunces in Plein.)
    static func numeral(_ size: CGFloat, weight: Font.Weight = .light) -> Font {
        Typography.face(concept.fonts.display, size: size, relativeTo: size > 40 ? .largeTitle : .title, serif: true)
            .weight(weight)
            .monospacedDigit()
    }

    /// Tess and context lines speak in the serif voice. Upright: Kaushik ruled out italics everywhere (2026-10-15).
    static func voice(size: CGFloat) -> Font {
        Typography.face(concept.fonts.voice, size: size, relativeTo: .body, serif: false).weight(.regular)
    }

    static var voice: Font {
        voice(size: 21)
    }
}
