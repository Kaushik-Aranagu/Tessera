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
        /// Time-of-day tints for backgrounds that use them: dawn, day, dusk, night.
        var sky: [[UInt32]]
        /// Tess's words and anything she changed (cobalt).
        var tess: (UInt32, UInt32) = (0x2E6DA4, 0x9DBFE6)
        /// Context lines in the voice ("now, until twenty to four"). Upright; there are no italics.
        var context: (UInt32, UInt32) = (0x7A5C8E, 0xA79FB5)
        /// Now, rest, a possible PR (cadmium).
        var now: (UInt32, UInt32) = (0xE0B341, 0xE8BD4C)
        /// Health, recovery, done days (sage).
        var health: (UInt32, UInt32) = (0x6E9E6A, 0x7FB07A)
        /// Inactive words (sibling rail).
        var muted: (UInt32, UInt32) = (0xA39AAE, 0x6F6880)
        /// Veils, held rows, the Write layer.
        var raised: (UInt32, UInt32) = (0xFAF6EF, 0x221A2D)
        /// `live` as text: UNDO and every vermilion word.
        var liveInk: (UInt32, UInt32) = (0xB83C28, 0xFF8466)
        /// Class colour for things with no domain colour.
        var neutral: (UInt32, UInt32) = (0xA39AAE, 0x8E879A)
        /// The morning end of the day stroke.
        var morning: (UInt32, UInt32) = (0x9EC3D6, 0x7CC4F0)
    }

    struct WorkoutPalette: Sendable {
        var ground: UInt32
        var groundRaised: UInt32
        var ink: UInt32
        var signal: UInt32
        var rest: UInt32
        var tess: UInt32 = 0x9DBFE6
        var health: UInt32 = 0x7FB07A
    }

    struct FontPairing: Sendable {
        var display: String
        var ui: String
        var mono: String
        /// Tess's voice: Inter Tight, upright (no italics anywhere).
        var voice: String = "Inter Tight"
    }

    /// Four sizes to read, and one to type in. 16 pt is the floor.
    struct TypeScale: Sendable {
        var hero: TypeSpec
        var title: TypeSpec
        var body: TypeSpec
        var label: TypeSpec
        /// What he types, one step under Tess's voice (calm-capture.md addendum): every field in the app.
        var field = TypeSpec(family: .ui, size: 18, weight: .regular, tracking: 0, lineHeight: 1.33,
                             textStyle: .callout)
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
        /// The looks (themes.md): each look's own field, picked by the appearance.
        case looks
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

    /// Round 6, "Plein air": impressionist washes, paper grain, big type, very little on screen; precision only as
    /// edge detail (docs/design/materials.md, type-and-motion.md). Inter Tight throughout, bundled in Resources/Fonts.
    static let plein = ThemeConcept(
        name: "Plein",
        palette: Palette(
            ground: (0xF2ECE3, 0x1C1828),
            ink: (0x2B2440, 0xF3ECE0),
            live: (0xC8452F, 0xD9563F),
            training: (0x6E9E6A, 0x7FB07A),
            sky: Array(repeating: [0xF2ECE3, 0xF2ECE3, 0xF2ECE3], count: 4)
        ),
        // Inter Tight app-wide (Kaushik, 2026-10-15); no italics. docs/design/type-and-motion.md.
        fonts: FontPairing(display: "Inter Tight", ui: "Inter Tight", mono: "Inter Tight", voice: "Inter Tight"),
        scale: TypeScale(
            hero: TypeSpec(family: .display, size: 56, weight: .medium, tracking: -0.04, lineHeight: 1.0,
                           textStyle: .largeTitle),
            title: TypeSpec(family: .display, size: 44, weight: .medium, tracking: -0.035, lineHeight: 1.05,
                            textStyle: .title),
            body: TypeSpec(family: .ui, size: 21, weight: .medium, tracking: 0, lineHeight: 1.3, textStyle: .body),
            label: TypeSpec(family: .ui, size: 16, weight: .bold, tracking: 0.08, lineHeight: 1.25, uppercase: true,
                            textStyle: .callout),
            heroNumberWeight: .light
        ),
        background: .plein,
        separator: .none,
        completion: .strike,
        thinking: .spark,
        workout: WorkoutPalette(ground: 0x1C1828, groundRaised: 0x3B2D57, ink: 0xF3ECE0, signal: 0xD9563F,
                                rest: 0xE8BD4C)
    )

    /// Retired from the picker (themes.md); `-theme workshop` and `-theme machined` still reach them.
    static let all: [ThemeConcept] = [.plein, .workshop, .machined]

    /// The house concept dressed in the chosen looks: day and night as the two halves of each colour, the workout in
    /// the look on screen.
    static func dressed(day: Look, night: Look, current: Look) -> ThemeConcept {
        var concept = ThemeConcept.plein
        concept.name = day == night ? day.name : "\(day.name) by day, \(night.name) by night"
        concept.background = .looks
        concept.palette = Palette(
            ground: (day.ground, night.ground), ink: (day.ink, night.ink), live: (day.live, night.live),
            training: (day.training, night.training),
            sky: Array(repeating: [day.ground, day.ground, day.ground], count: 4),
            tess: (day.tess, night.tess), context: (day.context, night.context), now: (day.now, night.now),
            health: (day.health, night.health), muted: (day.muted, night.muted), raised: (day.raised, night.raised),
            liveInk: (day.liveInk, night.liveInk), neutral: (day.neutral, night.neutral),
            morning: (day.sky, night.sky)
        )
        // One base across the app (Kaushik, 2026-10-16): the workout stands on the same ground as Home in the look,
        // with its layers matched to it, nothing much brighter or darker than the rest.
        concept.workout = WorkoutPalette(ground: current.ground, groundRaised: current.raised, ink: current.ink,
                                         signal: current.live, rest: current.now, tess: current.tess,
                                         health: current.health)
        return concept
    }
}

// MARK: - Tokens

enum Theme {
    /// A retired concept pinned with `-theme workshop` or `-theme machined`; nil means the looks.
    nonisolated(unsafe) static var retired: ThemeConcept?

    /// The active concept: the chosen looks (ThemeStore), read inside `body` so every view redraws on a switch.
    static var concept: ThemeConcept {
        retired ?? ThemeStore.shared.concept
    }

    /// `-theme <name>` pins a look in memory for demos and recordings, on the simulator only (like the demo data).
    static func configure() {
        // -theme pins a look in memory for demos and recordings, on the simulator only.
        guard let name = LaunchFlags.value(after: "-theme")?.lowercased() else { return }
        if name == "plein-washes" {
            // The retired Plein washes and grain, kept until he's lived with the flat Plein (looks-recut.md).
            var washes = Look.plein
            washes.field = .plein
            ThemeStore.shared.pin(washes)
        } else if let look = Look.named(name) {
            ThemeStore.shared.pin(look)
        } else if let match = ThemeConcept.all.first(where: { $0.name.lowercased() == name }), match.name != "Plein" {
            retired = match
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

        /// 66% on light looks, 72% on dark (themes.md, second addendum: contrast).
        static var inkSecondary: Color {
            Color(light: concept.palette.ink.0, dark: concept.palette.ink.1,
                  lightAlpha: tier(0.66, 0.72).day, darkAlpha: tier(0.66, 0.72).night)
        }

        /// A tier's alpha by each half's own look (a pinned light look stays light-tiered on a dark-mode phone).
        private static func tier(_ light: CGFloat, _ dark: CGFloat) -> (day: CGFloat, night: CGFloat) {
            guard retired == nil else { return (light, dark) }
            let pair = ThemeStore.shared.pair
            return (pair.day.isDark ? dark : light, pair.night.isDark ? dark : light)
        }

        /// Text only at 34 pt and up; below that it's for marks. 51% light, 38% dark.
        static var inkTertiary: Color {
            Color(light: concept.palette.ink.0, dark: concept.palette.ink.1,
                  lightAlpha: tier(0.51, 0.38).day, darkAlpha: tier(0.51, 0.38).night)
        }

        /// Veils, held rows, the Write layer.
        static var raised: Color {
            Color(light: concept.palette.raised.0, dark: concept.palette.raised.1)
        }

        /// UNDO and every vermilion word. Fills and strokes keep `live`.
        static var liveInk: Color {
            Color(light: concept.palette.liveInk.0, dark: concept.palette.liveInk.1)
        }

        /// The class colour for things with no domain colour.
        static var neutral: Color {
            Color(light: concept.palette.neutral.0, dark: concept.palette.neutral.1)
        }

        /// The morning end of the day stroke.
        static var sky: Color {
            Color(light: concept.palette.morning.0, dark: concept.palette.morning.1)
        }

        /// A pigment at rest (docs/design/no-dots.md): low contrast, 45% on light looks and 55% on dark, so colour
        /// only arrives in a moment and then dries back to this.
        static func restTint(_ pigment: Color) -> Color {
            pigment.opacity(ThemeStore.shared.paintLook.isDark ? 0.55 : 0.45)
        }

        /// Morning to evening along the day stroke.
        static var daySpectrum: [Color] {
            [sky, health, context, now, live]
        }

        /// Routine colours, in order (Pull gets violet; Tess's cobalt stays hers).
        static var routines: [Color] {
            [live, health, now, context]
        }

        enum ClassRole {
            case training, planning, health, kitchen, neutral
        }

        static func classColor(_ role: ClassRole) -> Color {
            switch role {
            case .training: training
            case .planning: now
            case .health, .kitchen: health
            case .neutral: neutral
            }
        }

        /// Pigment over ground: multiply on light looks, screen on dark ones (the soul, any pigment overlay).
        static var soulBlend: BlendMode {
            ThemeStore.shared.paintLook.isDark ? .screen : .multiply
        }

        /// The glint: a gold band through the letters on Porcelain and Celadon (now at 60%, normal blend), Plein's
        /// warm light on its pages, and light passing over dark looks (plus-lighter).
        static var sheen: Color {
            let look = ThemeStore.shared.paintLook
            return Color(hex: look.sheen).opacity(look.sheenOnLetters ? 0.6 : 1)
        }

        static var sheenBlend: BlendMode {
            ThemeStore.shared.paintLook.sheenOnLetters ? .normal : .plusLighter
        }

        /// Pigment glows on dark looks (strokes, dabs, the soul, numerals; never text under 34 pt).
        static var halo: Bool {
            ThemeStore.shared.paintLook.isDark
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

            static var raised: Color {
                groundRaised
            }

            /// Tess's words, the swap wash, the cobalt set stroke.
            static var tess: Color {
                Color(hex: concept.workout.tess)
            }

            static var health: Color {
                Color(hex: concept.workout.health)
            }

            /// The glass outline: black 60% on Plein (today's), ink 12% elsewhere (black can't show on #000).
            static var glassEdge: Color {
                ink.opacity(0.12)
            }

            /// Set strokes cycle through these, in order.
            static var setCycle: [Color] {
                [signal, tess, rest, health]
            }

            static var ink: Color {
                Color(hex: concept.workout.ink)
            }

            static var inkSecondary: Color {
                ink.opacity(0.72)
            }

            static var inkTertiary: Color {
                ink.opacity(0.38)
            }

            static var hairline: Color {
                ink.opacity(0.14)
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
            // Change plates (themes.md addendum: plates stay fixed, the change plates move here).
            case 2.5: Color(hex: 0x55534F)
            case 1.25: Color(hex: 0xA8A49C)
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
        /// Ink drying: the colour of a moment fading back to rest, 1.1 s on the house curve after 0.4 s. Nil under
        /// Reduce Motion (the colour simply settles).
        static func dry(reduceMotion: Bool) -> Animation? {
            reduceMotion ? nil : Animation.spring(Spring(duration: 1.1, bounce: 0.12)).delay(0.4)
        }

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

    init(light: UInt32, dark: UInt32, lightAlpha: CGFloat = 1, darkAlpha: CGFloat = 1) {
        self.init(uiColor: UIColor { traits in
            let isDark = traits.userInterfaceStyle == .dark
            let hex = isDark ? dark : light
            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: isDark ? darkAlpha : lightAlpha
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
