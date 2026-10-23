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

/// The words of a number, pure so they are tested without drawing.
enum HouseNumberText {
    static let noBreakSpace = "\u{00A0}"

    /// "82" and "½" for 82.5; "82.6" and nil when the fraction is not a quarter, half or three quarters.
    static func parts(_ value: Double) -> (whole: String, fraction: String?) {
        let rounded = (value * 100).rounded() / 100
        let sign = rounded < 0 ? "-" : ""
        let magnitude = abs(rounded)
        let whole = magnitude.rounded(.down)
        let rest = magnitude - whole
        let glyph: String? = switch rest {
        case 0.24 ... 0.26: "¼"
        case 0.49 ... 0.51: "½"
        case 0.74 ... 0.76: "¾"
        default: nil
        }
        if let glyph {
            return (sign + String(Int(whole)), glyph)
        }
        let text = magnitude == magnitude.rounded() ? String(Int(magnitude)) : String(format: "%g", magnitude)
        return (sign + text, nil)
    }

    /// The whole number with its unit, joined by a no-break space ("82.5 kg", "12 min").
    static func line(_ value: Double, unit: String?) -> String {
        let parts = parts(value)
        let number = parts.whole + (parts.fraction ?? "")
        guard let unit, !unit.isEmpty else { return number }
        return number + noBreakSpace + unit
    }

    /// The number's weight: an estimate takes the numeral weight, an exact value one step heavier.
    static func weight(estimate: Bool, size: CGFloat) -> Font.Weight {
        let base = Theme.numeralWeight(size: size)
        guard !estimate else { return base }
        return base == .thin ? .light : .regular
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
    /// The value it was, shown for two seconds after a change by hand or a new best (never for money).
    var was: Double?
    var isMoney = false
    var role: TextRole = .titleNumber
    var onUnitTap: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showsWas = false
    @State private var pull: CGFloat = 0

    var body: some View {
        if NumberRulesSwitch.isOn {
            rules
        } else {
            // Off: the number as it was drawn before (plain digits, a space, the unit).
            Text(HouseNumberText.line(value, unit: unit))
                .textRole(role)
                .foregroundStyle(Theme.Colors.ink)
        }
    }

    private var rules: some View {
        let parts = HouseNumberText.parts(value)
        let size = Theme.concept.scale.title.size
        let weight = weight(size: size)
        return HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(parts.whole)
                .textRole(role)
                .fontWeight(weight)
                .foregroundStyle(Theme.Colors.ink)
                .contentTransition(.numericText(value: value))
            if let fraction = parts.fraction {
                Text(fraction)
                    .font(.system(size: size * 0.7))
                    .foregroundStyle(Theme.Colors.inkSecondary)
            }
            if let unit {
                Text(HouseNumberText.noBreakSpace)
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
                    .accessibilityLabel("Unit, \(unit). Turns it.")
                } else {
                    Text(unit)
                        .textRole(.label)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                }
            }
            if showsWas, let text = HouseNumberText.was(was, unit: unit, isMoney: isMoney) {
                Text(HouseNumberText.noBreakSpace + text)
                    .textRole(.label)
                    .foregroundStyle(Theme.Colors.inkTertiary)
                    .transition(.opacity)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { pull = min(abs($0.translation.width) + abs($0.translation.height), 80) }
                .onEnded { _ in pull = 0 }
        )
        .onChange(of: was) { _, new in
            guard new != nil, !isMoney else { return }
            withTesseraAnimation(.easeOut(duration: 0.2), reduceMotion: reduceMotion) { showsWas = true }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                withTesseraAnimation(.easeOut(duration: 0.3), reduceMotion: reduceMotion) { showsWas = false }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(HouseNumberText.line(value, unit: unit).replacingOccurrences(of: "\u{00A0}", with: " "))
    }

    /// A drag adds up to +200 weight (a light 300 can reach regular 400 and medium 500); never under Reduce Motion.
    private func weight(size: CGFloat) -> Font.Weight {
        let base = HouseNumberText.weight(estimate: estimate, size: size)
        guard !reduceMotion, pull > 0 else { return base }
        let steps: [Font.Weight] = [.thin, .ultraLight, .light, .regular, .medium]
        let start = steps.firstIndex(of: base) ?? 2
        let added = Int((pull / 80 * 2).rounded())
        return steps[min(start + added, steps.count - 1)]
    }
}
