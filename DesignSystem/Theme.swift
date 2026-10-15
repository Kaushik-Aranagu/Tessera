import SwiftUI
import UIKit

// MARK: - Concept

/// Every visual decision lives in a `ThemeConcept`. Views read tokens through `Theme`, so a new concept
/// (palette, fonts, the four type sizes, background, separators, completion effect) drops in without touching views.
/// The current concept is a placeholder ("Workshop") until Kaushik picks one.
struct ThemeConcept: Sendable {
    var name: String
    var palette: Palette
    var fonts: FontPairing
    var scale: TypeScale
    var background: BackgroundStyle
    var separator: SeparatorStyle
    var completion: CompletionEffect
    var thinking: ThinkingStyle
    var workout: WorkoutPalette

    struct Palette: Sendable {
        /// (light, dark) hex pairs.
        var ground: (UInt32, UInt32)
        var ink: (UInt32, UInt32)
        /// Things happening now ("NOW", "BOARDING", the now-marker).
        var live: (UInt32, UInt32)
        /// Training domain.
        var training: (UInt32, UInt32)
        /// Personal records / progress.
        var progress: (UInt32, UInt32)
        /// Time-of-day tints for backgrounds that use them: dawn, day, dusk, night.
        var sky: [[UInt32]]
        /// Tess's words and anything she changed (cobalt).
        var tess: (UInt32, UInt32) = (0x2E6DA4, 0x9DBFE6)
        /// Context lines in the italic voice ("now, until twenty to four").
        var context: (UInt32, UInt32) = (0x7A5C8E, 0xA79FB5)
        /// Now, rest, a possible PR (cadmium).
        var now: (UInt32, UInt32) = (0xE0B341, 0xE8BD4C)
        /// Health, recovery, done days (sage).
        var health: (UInt32, UInt32) = (0x6E9E6A, 0x7FB07A)
        /// Inactive words (sibling rail).
        var muted: (UInt32, UInt32) = (0xA39AAE, 0x6F6880)
    }

    struct WorkoutPalette: Sendable {
        var ground: UInt32
        var groundRaised: UInt32
        var ink: UInt32
        var signal: UInt32
        var rest: UInt32
    }

    struct FontPairing: Sendable {
        var display: String
        var ui: String
        var mono: String
        /// Tess's voice: an italic serif.
        var voice: String = "Fraunces"
    }

    /// Exactly four sizes. 16 pt is the floor.
    struct TypeScale: Sendable {
        var hero: TypeSpec
        var title: TypeSpec
        var body: TypeSpec
        var label: TypeSpec
        /// Weight of numbers set at hero size (workout numbers).
        var heroNumberWeight: Font.Weight
    }

    struct TypeSpec: Sendable {
        enum Family: Sendable { case display, ui, mono }
        var family: Family
        var size: CGFloat
        var weight: Font.Weight
        /// In em (fraction of the size), e.g. −0.03 = −3%.
        var tracking: CGFloat
        var lineHeight: CGFloat
        var condensed: Bool = false
        var uppercase: Bool = false
        var textStyle: Font.TextStyle
    }

    enum BackgroundStyle: Sendable {
        /// Flat ground with a slow time-of-day mesh across the top.
        case groundWithSky
        /// Flat ground only.
        case flat
        /// Plein air: soft radial washes over paper, one drifting wash and paper grain.
        case plein
    }

    enum SeparatorStyle: Sendable {
        case hairline
        case dotted
        /// Rows separated by space alone.
        case none
    }

    /// How "Tess is thinking" looks. Each concept supplies its own; `ThinkingIndicator` renders it.
    enum ThinkingStyle: Sendable {
        /// Tess's soul in its thinking bloom (Kaushik's pick).
        case soul
        /// A spark whose rays breathe and turn, like a thinking glyph.
        case spark
        /// Three mono dots that pulse in sequence.
        case dots
    }

    enum CompletionEffect: Sendable {
        /// A line strikes through, text dims.
        case strike
        /// Text blurs and fades away.
        case dissolve
    }
}

extension ThemeConcept {
    static let workshop = ThemeConcept(
        name: "Workshop",
        palette: Palette(
            ground: (0xF4EEE5, 0x15130F),
            ink: (0x1D1A16, 0xEFE8DC),
            live: (0xC2502A, 0xE8774E),
            training: (0x2F5A45, 0x8CC4A4),
            progress: (0x8A6A12, 0xE2BE5A),
            sky: [
                [0xF2C9A0, 0xEFD9C3, 0xE9C4B4],
                [0xE3E2D2, 0xEDE4D2, 0xD9E0DA],
                [0xF0B98E, 0xE8C7B0, 0xD9A99A],
                [0xC9C3D6, 0xDCD3CB, 0xBFC6CF],
            ]
        ),
        fonts: FontPairing(display: "Bricolage Grotesque", ui: "Instrument Sans", mono: "Martian Mono"),
        scale: TypeScale(
            // Bricolage's optical-size axis follows the point size automatically (≈ opsz 96 / 36 here).
            hero: TypeSpec(
                family: .display,
                size: 64,
                weight: .bold,
                tracking: -0.03,
                lineHeight: 0.94,
                textStyle: .largeTitle
            ),
            title: TypeSpec(
                family: .display,
                size: 34,
                weight: .semibold,
                tracking: -0.015,
                lineHeight: 1.08,
                textStyle: .title
            ),
            body: TypeSpec(family: .ui, size: 21, weight: .regular, tracking: 0, lineHeight: 1.38, textStyle: .body),
            label: TypeSpec(family: .mono, size: 16, weight: .medium, tracking: 0.04, lineHeight: 1.2, condensed: true,
                            uppercase: true, textStyle: .callout),
            heroNumberWeight: .light
        ),
        background: .groundWithSky,
        separator: .hairline,
        completion: .strike,
        thinking: .soul,
        workout: WorkoutPalette(
            ground: 0x0D1411,
            groundRaised: 0x16211C,
            ink: 0xEDEAE0,
            signal: 0xC9F26B,
            rest: 0x7FD1C1
        )
    )

    /// Round 5, "zero tolerance": milled aluminium (Home) and anodised graphite (Workout). docs/design/materials.md.
    /// Schibsted Grotesk falls back to SF Pro at the same weights until the font is bundled.
    static let machined = ThemeConcept(
        name: "Machined",
        palette: Palette(
            ground: (0xE7E3DC, 0x1B1C1E),
            ink: (0x1C1B1A, 0xECE9E3),
            live: (0xC8452F, 0xD9563F),
            training: (0xC8452F, 0xD9563F),
            progress: (0x8A6A1C, 0xE8BD4C),
            sky: Array(repeating: [0xE7E3DC, 0xE7E3DC, 0xE7E3DC], count: 4)
        ),
        fonts: FontPairing(display: "Schibsted Grotesk", ui: "Schibsted Grotesk", mono: "Martian Mono"),
        scale: TypeScale(
            hero: TypeSpec(family: .display, size: 56, weight: .black, tracking: -0.045, lineHeight: 0.92,
                           textStyle: .largeTitle),
            title: TypeSpec(family: .display, size: 40, weight: .black, tracking: -0.04, lineHeight: 1.0,
                            textStyle: .title),
            body: TypeSpec(family: .ui, size: 21, weight: .semibold, tracking: 0, lineHeight: 1.3, textStyle: .body),
            label: TypeSpec(family: .mono, size: 16, weight: .medium, tracking: 0.04, lineHeight: 1.2, condensed: true,
                            uppercase: true, textStyle: .callout),
            heroNumberWeight: .semibold
        ),
        background: .flat,
        separator: .hairline,
        completion: .strike,
        thinking: .spark,
        workout: WorkoutPalette(ground: 0x1B1C1E, groundRaised: 0x25262A, ink: 0xECE9E3, signal: 0xD9563F,
                                rest: 0xE8BD4C)
    )

    /// Round 6, "Plein air": impressionist washes, paper grain, big serif type, very little on screen; precision only
    /// as edge detail (docs/design/materials.md, type-and-motion.md). Fraunces + Hanken Grotesk; until they are
    /// bundled, the display face falls back to the system serif.
    static let plein = ThemeConcept(
        name: "Plein",
        palette: Palette(
            ground: (0xF2ECE3, 0x1C1828),
            ink: (0x2B2440, 0xF3ECE0),
            live: (0xC8452F, 0xD9563F),
            training: (0x6E9E6A, 0x7FB07A),
            progress: (0xE0A35C, 0xE8BD4C),
            sky: Array(repeating: [0xF2ECE3, 0xF2ECE3, 0xF2ECE3], count: 4)
        ),
        fonts: FontPairing(display: "Fraunces", ui: "Hanken Grotesk", mono: "Hanken Grotesk", voice: "Fraunces"),
        scale: TypeScale(
            hero: TypeSpec(family: .display, size: 60, weight: .semibold, tracking: -0.025, lineHeight: 0.95,
                           textStyle: .largeTitle),
            title: TypeSpec(family: .display, size: 48, weight: .semibold, tracking: -0.025, lineHeight: 1.1,
                            textStyle: .title),
            body: TypeSpec(family: .ui, size: 21, weight: .medium, tracking: 0, lineHeight: 1.35, textStyle: .body),
            label: TypeSpec(family: .ui, size: 16, weight: .bold, tracking: 0.08, lineHeight: 1.25, uppercase: true,
                            textStyle: .callout),
            heroNumberWeight: .semibold
        ),
        background: .plein,
        separator: .none,
        completion: .strike,
        thinking: .spark,
        workout: WorkoutPalette(ground: 0x1C1828, groundRaised: 0x3B2D57, ink: 0xF3ECE0, signal: 0xD9563F,
                                rest: 0xE8BD4C)
    )

    static let all: [ThemeConcept] = [.plein, .workshop, .machined]
}

// MARK: - Tokens

enum Theme {
    /// The active concept. Set once at launch (`-theme <name>` in DEBUG).
    nonisolated(unsafe) static var concept: ThemeConcept = .plein

    static func configure(arguments: [String] = ProcessInfo.processInfo.arguments) {
        guard let index = arguments.firstIndex(of: "-theme"), arguments.indices.contains(index + 1) else { return }
        let name = arguments[index + 1].lowercased()
        if let match = ThemeConcept.all.first(where: { $0.name.lowercased() == name }) {
            concept = match
        }
    }

    /// Colors carry meaning. Secondary information uses 60% ink — the only secondary cue.
    enum Colors {
        static var paper: Color {
            Color(light: concept.palette.ground.0, dark: concept.palette.ground.1)
        }

        static var ink: Color {
            Color(light: concept.palette.ink.0, dark: concept.palette.ink.1)
        }

        static var inkSecondary: Color {
            ink.opacity(0.6)
        }

        /// Finished / inert things only.
        static var inkTertiary: Color {
            ink.opacity(0.38)
        }

        static var hairline: Color {
            ink.opacity(0.14)
        }

        static var live: Color {
            Color(light: concept.palette.live.0, dark: concept.palette.live.1)
        }

        static var training: Color {
            Color(light: concept.palette.training.0, dark: concept.palette.training.1)
        }

        static var progress: Color {
            Color(light: concept.palette.progress.0, dark: concept.palette.progress.1)
        }

        static var tess: Color {
            Color(light: concept.palette.tess.0, dark: concept.palette.tess.1)
        }

        static var context: Color {
            Color(light: concept.palette.context.0, dark: concept.palette.context.1)
        }

        static var now: Color {
            Color(light: concept.palette.now.0, dark: concept.palette.now.1)
        }

        static var health: Color {
            Color(light: concept.palette.health.0, dark: concept.palette.health.1)
        }

        static var muted: Color {
            Color(light: concept.palette.muted.0, dark: concept.palette.muted.1)
        }

        static func skyTints(hour: Double) -> [Color] {
            let index = switch hour {
            case 5 ..< 9: 0
            case 9 ..< 16: 1
            case 16 ..< 20: 2
            default: 3
            }
            return concept.palette.sky[index].map(Color.init(hex:))
        }

        /// Workout mode environment.
        enum Workout {
            static var ground: Color {
                Color(hex: concept.workout.ground)
            }

            static var groundRaised: Color {
                Color(hex: concept.workout.groundRaised)
            }

            static var ink: Color {
                Color(hex: concept.workout.ink)
            }

            static var inkSecondary: Color {
                ink.opacity(0.6)
            }

            static var inkTertiary: Color {
                ink.opacity(0.38)
            }

            static var hairline: Color {
                ink.opacity(0.12)
            }

            static var signal: Color {
                Color(hex: concept.workout.signal)
            }

            static var rest: Color {
                Color(hex: concept.workout.rest)
            }
        }

        /// Plate colors by kg — meaningful (the plate's weight), so not part of a concept.
        static func plate(_ kilograms: Double) -> Color {
            switch kilograms {
            case 25: Color(hex: 0xC8402F)
            case 20: Color(hex: 0x2F5FA8)
            case 15: Color(hex: 0xD9A72B)
            case 10: Color(hex: 0x3C8A55)
            case 5: Color(hex: 0xE9E4D8)
            default: Color(hex: 0x8F8A80)
            }
        }
    }

    enum Typography {
        static func font(_ spec: ThemeConcept.TypeSpec, weight: Font.Weight? = nil) -> Font {
            let family = switch spec.family {
            case .display: concept.fonts.display
            case .ui: concept.fonts.ui
            case .mono: concept.fonts.mono
            }
            let font = face(family, size: spec.size, relativeTo: spec.textStyle, serif: spec.family == .display)
                .weight(weight ?? spec.weight)
            return spec.condensed ? font.width(.condensed) : font
        }

        /// The family if it is registered; otherwise the system face (serif for display faces), never a silent
        /// fallback to SF Pro where a serif was designed.
        private static let registeredFamilies = Set(UIFont.familyNames)

        static func face(_ family: String, size: CGFloat, relativeTo style: Font.TextStyle, serif: Bool) -> Font {
            if registeredFamilies.contains(family) {
                return Font.custom(family, size: size, relativeTo: style)
            }
            let scaled = UIFontMetrics(forTextStyle: style.uiKit).scaledValue(for: size)
            return Font.system(size: scaled, design: serif ? .serif : .default)
        }

        /// A number set at a role's size in the mono face.
        static func number(_ spec: ThemeConcept.TypeSpec, weight: Font.Weight) -> Font {
            Font.custom(concept.fonts.mono, size: spec.size, relativeTo: spec.textStyle).weight(weight)
                .width(.condensed)
        }
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 40
        /// Negative space between sections (instead of boxes).
        static let section: CGFloat = 64
        /// Page side margin.
        static let gutter: CGFloat = 22
    }

    enum Radius {
        static let panel: CGFloat = 30
    }

    enum Stroke {
        static let hairline: CGFloat = 0.75
    }

    /// Always applied through `MotionPolicy` (`.tesseraAnimation` / `withTesseraAnimation`).
    enum Motion {
        /// House spring — ~90% of all motion.
        static let house = Animation.spring(Spring(duration: 0.42, bounce: 0.12))
        /// Direct manipulation: drags, swipes, toggles under the finger.
        static let snappy = Animation.snappy(duration: 0.25)
        /// Rare celebrations only.
        static let celebrate = Animation.bouncy(duration: 0.5)
        /// Per-glyph text reveals.
        static let reveal = Animation.smooth(duration: 1.0)
        /// How long a hold-to-confirm takes.
        static let holdDuration: Double = 0.9
        /// Stagger between elements entering in reading order.
        static let stagger: Double = 0.035
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1
            )
        })
    }
}

extension Font.TextStyle {
    var uiKit: UIFont.TextStyle {
        switch self {
        case .largeTitle: .largeTitle
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .callout: .callout
        case .footnote: .footnote
        case .caption: .caption1
        case .caption2: .caption2
        default: .body
        }
    }
}
