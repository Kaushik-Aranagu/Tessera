import SwiftUI
import UIKit

/// Tokens the Training rebuild (sheet 230) adds on top of the look: the go green, the two faces at the sizes the
/// sheet names, and the one switch every wheel reads. Colours that already exist (the cobalt accent, ink 2 and ink 3)
/// are read from `Theme.Colors`, so a swapped `ThemeConcept` restyles all of it.
extension Theme.Colors {
    /// Go green: 25803D light (2FA24D failed contrast at 3.02:1), 8FC9A0 dark (the Soft palette). Large text and
    /// strokes only (warm-up, rest countdown, the set strike, "Done warming up", "Skip rest"), and never the only
    /// signal: a word always says the same thing.
    enum Go {
        static var green: Color {
            Color(light: 0x25803D, dark: 0x8FC9A0)
        }
    }

    /// Gold (241): 7E6A1E light, D9C27A dark. Best, new, starred; the streak; the Library's Exercises.
    enum Gold {
        static var label: Color {
            Color(light: 0x7E6A1E, dark: 0xD9C27A)
        }
    }

    /// Wine (241): late, due, overdue, expiring, warnings.
    enum Wine {
        static var label: Color {
            Color(light: 0x9A2541, dark: 0xEE8E9C)
        }
    }

    /// Teal (241): a kind with no room of its own; Pull.
    enum Teal {
        static var label: Color {
            Color(light: 0x1E6E77, dark: 0x84C3C9)
        }
    }

    /// Clay (241): a kind with no room of its own; Push.
    enum Clay {
        static var label: Color {
            Color(light: 0x9C4B2C, dark: 0xE2A07F)
        }
    }

    /// Plum (v20): Legs.
    enum Plum {
        static var label: Color {
            Color(light: 0x8A4570, dark: 0xD69CC0)
        }
    }

    /// The colour a split or kind wears (v20): Push clay, Pull teal, Legs plum; anything else the Training blue.
    enum Split {
        static func color(forKind kind: String) -> Color {
            switch kind {
            case "Push": Clay.label
            case "Pull": Teal.label
            case "Legs": Plum.label
            default: Accent.training
            }
        }

        /// By a routine's or an exercise's name ("Push A" is clay).
        static func color(forName name: String) -> Color {
            color(forKind: LibraryKinds.kind(ofName: name))
        }
    }
}

extension Theme.Colors {
    /// Slate (v3.2): 34506F light, A7BCD6 dark. Small-caps labels and the streak number. Training's four colour roles
    /// are blue (titles, today, actions), green (gains and new things), slate (labels) and ink (everything else).
    enum Slate {
        static var label: Color {
            Color(light: 0x34506F, dark: 0xA7BCD6)
        }
    }
}

extension Theme {
    /// The sheet's type: Figtree for words, Outfit for numbers, scaling with Dynamic Type. Falls back to the system
    /// face when a family is not registered (a unit-test host).
    enum Training {
        static func words(_ size: CGFloat, weight: Font.Weight = .regular, relativeTo style: Font.TextStyle = .body)
            -> Font
        {
            Typography.face("Figtree", size: size, relativeTo: style, serif: false).weight(weight)
        }

        /// Outfit 200 from 28 pt up; 300 below (the sheet's "Outfit 300 26 pt"), tabular.
        static func number(_ size: CGFloat, weight: Font.Weight? = nil, relativeTo style: Font.TextStyle = .title)
            -> Font
        {
            Typography.face("Outfit", size: size, relativeTo: style, serif: false)
                .weight(weight ?? numeralWeight(size: size))
                .monospacedDigit()
        }
    }
}

/// The Training rebuild's master switch (Review > Wheels), On by default.
enum TrainingV3 {
    nonisolated static let choiceID = "trainingV3"

    @MainActor static var isOn: Bool {
        ReviewChoices.shared.value(of: choiceID) != "Off"
    }
}

/// Settings > Look > "Depth on wheels" (default On). The blur itself also needs Reduce Motion, Reduce Transparency and
/// Low Power all off; `WheelDepth.blur` is the one place that reads all four.
enum WheelDepth {
    nonisolated static let choiceID = "depthOnWheels"

    @MainActor static var settingIsOn: Bool {
        ReviewChoices.shared.value(of: choiceID) != "Off"
    }

    /// The blur in points for a row `away` rows from the focus: 0.65 one away, 1.0 two or more, never more than 1.
    nonisolated static func radius(away: Int) -> CGFloat {
        switch abs(away) {
        case 0: 0
        case 1: 0.65
        default: 1.0
        }
    }

    /// The rendered blur: zero whenever depth is off or the system asks for less.
    nonisolated static func blur(away: Int, enabled: Bool, reduceMotion: Bool, reduceTransparency: Bool,
                                 lowPower: Bool) -> CGFloat
    {
        guard enabled, !reduceMotion, !reduceTransparency, !lowPower else { return 0 }
        return radius(away: away)
    }
}

// MARK: - Title fit

/// "Big fixed titles shrink 1 pt at a time until they fit, down to 0.75x" (sheet 230). Measured with the real face, so
/// a name is never wrapped, never pushed and never ends in "...".
enum TitleFit {
    /// The largest whole point size from `size` down to `size * floor` at which `text` fits `width` on one line, or
    /// nil when even the floor does not fit (the caller then uses a short form).
    @MainActor
    static func size(for text: String, width: CGFloat, from size: CGFloat, weight: UIFont.Weight = .semibold,
                     floor: CGFloat = 0.75, family: String = "Figtree",
                     style: UIFont.TextStyle = .title1) -> CGFloat?
    {
        guard width > 0, size > 0 else { return nil }
        let lowest = (size * floor).rounded(.up)
        var point = size
        while point >= lowest {
            if measure(text, point: point, weight: weight, family: family, style: style) <= width {
                return point
            }
            point -= 1
        }
        return nil
    }

    /// The width of `text` on one line at `point` (scaled the way Dynamic Type scales the displayed font).
    @MainActor
    static func measure(_ text: String, point: CGFloat, weight: UIFont.Weight, family: String = "Figtree",
                        style: UIFont.TextStyle = .title1) -> CGFloat
    {
        let scaled = UIFontMetrics(forTextStyle: style).scaledValue(for: point)
        let descriptor = UIFontDescriptor(fontAttributes: [
            .family: family,
            .traits: [UIFontDescriptor.TraitKey.weight: weight],
        ])
        let font = UIFont(descriptor: descriptor, size: scaled)
        // A hair of slack: SwiftUI lays out a touch wider than a bare string measure.
        return ceil((text as NSString).size(withAttributes: [.font: font]).width * 1.02)
    }
}
