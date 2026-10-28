import SwiftUI

// One number, drawn one way everywhere (Design 138, behind the `numberRules` Review switch, default Off):
// - a quarter, half or three quarters hangs as a fraction one role smaller in ink 2 ("82½");
// - "was 80" shows in ink 3 for two seconds after a hand change or a new best, never on money;
// - an estimate is Outfit 200, an exact value one step heavier (300);
// - a tap on the unit turns it (the digits roll, the unit crossfades);
// - a drag adds up to +200 weight, never under Reduce Motion;
// - a no-break space joins the number and its unit, so "82.5 kg" never splits across lines.
// Callers pass the value and the unit word; converting between units stays with `Measure`.

enum NumberRulesSwitch {
    nonisolated static let choiceID = "numberRules"

    @MainActor static var isOn: Bool {
        ReviewChoices.shared.value(of: choiceID) == "On"
    }
}

/// How a fraction is drawn: the decimal part hung ("82" with ".5"), or a vulgar glyph ("½ cup", Kitchen only).
enum FractionStyle {
    case decimal, vulgar
}

/// The words of a number, pure so they are tested without drawing.
enum HouseNumberText {
    static let noBreakSpace = "\u{00A0}"

    /// The whole part and the hung part. Decimal (the default): 82.5 is "82" with ".5", 12.25 is "12" with ".25", 80
    /// has
    /// none. Vulgar (Kitchen's "½ cup"): a quarter, half or three quarters is its glyph, and a bare half is "½".
    /// "82½ kg" never appears for a weight: weights and money are always decimal.
    static func parts(_ value: Double, style: FractionStyle = .decimal) -> (whole: String, fraction: String?) {
        let rounded = (value * 100).rounded() / 100
        let sign = rounded < 0 ? "-" : ""
        let magnitude = abs(rounded)
        let whole = magnitude.rounded(.down)
        let rest = magnitude - whole
        if rest < 0.005 {
            return (sign + String(Int(whole)), nil)
        }
        if style == .vulgar {
            let glyph: String? = switch rest {
            case 0.24 ... 0.26: "¼"
            case 0.49 ... 0.51: "½"
            case 0.74 ... 0.76: "¾"
            default: nil
            }
            if let glyph {
                return (whole == 0 ? sign : sign + String(Int(whole)), glyph)
            }
        }
        // The decimal part without its leading zero, trimmed: ".5", ".25", ".6".
        let digits = String(format: "%.2f", rest).dropFirst()
        let trimmed = digits.hasSuffix("0") ? String(digits.dropLast()) : String(digits)
        return (sign + String(Int(whole)), trimmed)
    }

    /// The whole number with its unit, joined by a no-break space ("82.5 kg", "12 min").
    static func line(_ value: Double, unit: String?, style: FractionStyle = .decimal) -> String {
        let parts = parts(value, style: style)
        let number = parts.whole + (parts.fraction ?? "")
        guard let unit, !unit.isEmpty else { return number }
        return number + noBreakSpace + unit
    }

    /// The number's weight: an estimate is Outfit 200 (thin) from 28 pt up and 300 below; an exact value is one step
    /// heavier (200 to 300, 300 to 400).
    static func weight(estimate: Bool, size: CGFloat) -> Font.Weight {
        if size >= 28 {
            return estimate ? .thin : .light
        }
        return estimate ? .light : .regular
    }

    /// The weight after a pull (0 to 1) adds up to 200: two steps of 100.
    static func weight(_ base: Font.Weight, pressure: CGFloat) -> Font.Weight {
        let steps: [Font.Weight] = [.ultraLight, .thin, .light, .regular, .medium, .semibold]
        let start = steps.firstIndex(of: base) ?? 2
        let added = Int((min(max(pressure, 0), 1) * 2).rounded())
        return steps[min(start + added, steps.count - 1)]
    }

    /// "was 80" (nil for money, and when nothing changed).
    static func was(_ old: Double?, unit: String?, isMoney: Bool) -> String? {
        guard !isMoney, let old else { return nil }
        return "was " + line(old, unit: unit)
    }
}

struct HouseNumber: View {
    let value: Double
    var unit: String?
    var estimate = false
    var fractionStyle: FractionStyle = .decimal
    /// The value it was, shown for two seconds after a change by hand or a new best (never for money).
    var was: Double?
    var isMoney = false
    var role: TextRole = .titleNumber
    /// A pull on the number, 0 to 1, fed by the instrument's own drag (this view takes no gesture of its own).
    var pressure: CGFloat = 0
    var onUnitTap: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var showsWas = false
    /// The one task that hides "was"; a second change cancels it and starts again.
    @State private var hideTask: Task<Void, Never>?

    var body: some View {
        if NumberRulesSwitch.isOn {
            rules
        } else {
            // Off: the number as it was drawn before (plain digits, a space, the unit).
            Text(Self.plain(value, unit: unit))
                .textRole(role)
                .foregroundStyle(Theme.Colors.ink)
        }
    }

    private var rules: some View {
        let parts = HouseNumberText.parts(value, style: fractionStyle)
        let size = Self.spec(role).size
        let base = HouseNumberText.weight(estimate: estimate, size: size)
        let weight = reduceMotion ? base : HouseNumberText.weight(base, pressure: pressure)
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(parts.whole)
                    .textRole(role)
                    .fontWeight(weight)
                    .foregroundStyle(Theme.Colors.ink)
                    .contentTransition(.numericText(value: value))
                    .tesseraAnimation(Theme.Motion.house, value: value)
                if let fraction = parts.fraction {
                    // One role step smaller, Outfit, ink 2.
                    // At accessibility sizes the fraction comes up to the number's own size.
                    Text(fraction)
                        .font(Theme.Typography.number(
                            Self.spec(typeSize.isAccessibilitySize ? role : Self.smaller(role)), weight: weight
                        ))
                        .foregroundStyle(Theme.Colors.inkSecondary)
                }
                if let unit {
                    Text(HouseNumberText.noBreakSpace)
                    unitView(unit)
                }
            }
            if showsWas, let text = HouseNumberText.was(was, unit: unit, isMoney: isMoney) {
                // Under the new value; it slides down 0.6 em as it appears.
                Text(text)
                    .textRole(.label)
                    .foregroundStyle(Theme.Colors.inkTertiary)
                    .transition(.asymmetric(
                        insertion: .offset(y: -size * 0.6).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .onChange(of: was) { _, new in
            hideTask?.cancel()
            guard new != nil, !isMoney else { return }
            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { showsWas = true }
            hideTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { return }
                // The fade-out dries on its own curve; Reduce Motion is the 150 ms fade (MotionPolicy decides).
                withTesseraAnimation(Theme.Motion.dry(reduceMotion: false) ?? .easeOut(duration: 1),
                                     reduceMotion: reduceMotion) { showsWas = false }
            }
        }
        .onDisappear { hideTask?.cancel() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            HouseNumberText.line(value, unit: unit, style: fractionStyle).replacingOccurrences(
                of: "\u{00A0}",
                with: " "
            )
        )
    }

    @ViewBuilder
    private func unitView(_ unit: String) -> some View {
        if let onUnitTap {
            Button(action: onUnitTap) {
                Text(unit)
                    .textRole(.label)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .contentTransition(.opacity)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Unit, \(unit). Turns it")
        } else {
            Text(unit)
                .textRole(.label)
                .foregroundStyle(Theme.Colors.inkSecondary)
        }
    }

    /// The number as it was always drawn (plain digits, a space, the unit); the Off path never uses the new rules.
    static func plain(_ value: Double, unit: String?) -> String {
        let digits = value.formatted(.number.precision(.fractionLength(0 ... 2)))
        guard let unit, !unit.isEmpty else { return digits }
        return digits + " " + unit
    }

    /// The type spec a role draws at.
    static func spec(_ role: TextRole) -> ThemeConcept.TypeSpec {
        let scale = Theme.concept.scale
        switch role {
        case .hero, .heroNumber: return scale.hero
        case .title, .titleNumber: return scale.title
        case .body, .bodyStrong: return scale.body
        case .field: return scale.field
        default: return scale.label
        }
    }

    /// One role step smaller: hero to title, title to body, body to label.
    static func smaller(_ role: TextRole) -> TextRole {
        switch role {
        case .hero, .heroNumber: .titleNumber
        case .title, .titleNumber: .body
        default: .label
        }
    }
}
