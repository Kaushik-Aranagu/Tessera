import Foundation

/// A recipe or grocery amount as the Measure view can draw it. A mass or volume in a unit that has a wheel is a
/// `Measure`; a count ("3 eggs", "2 cloves") or a unit with no wheel (a can, a jar, "to taste") is a plain number
/// and gets no wheel. Volume never converts to mass: a cup of flour is not a number of grams without a density.
public enum KitchenReading: Equatable, Sendable {
    /// A measure, and the top of a range ("2-3 tbsp") when there is one.
    case measure(Measure, upper: Measure?)
    /// A plain number and the word it was said with ("clove"), nil for a bare count. No wheel.
    case plain(amount: Double, upper: Double?, word: String?)

    public var measure: Measure? {
        if case let .measure(measure, _) = self {
            return measure
        }
        return nil
    }

    public var hasWheel: Bool {
        measure != nil
    }
}

public extension KitchenUnit {
    /// The Measure kind and unit symbol this unit swipes through, or nil: counts and packs.
    var measureUnit: (kind: MeasureKind, unit: String)? {
        switch self {
        case .gram: (.kitchenMass, "g")
        case .kilogram: (.kitchenMass, "kg")
        case .ounce: (.kitchenMass, "oz")
        case .pound: (.kitchenMass, "lb")
        case .millilitre: (.kitchenVolume, "ml")
        case .litre: (.kitchenVolume, "l")
        case .teaspoon: (.kitchenVolume, "tsp")
        case .tablespoon: (.kitchenVolume, "tbsp")
        case .cup: (.kitchenVolume, "cup")
        case .fluidOunce: (.kitchenVolume, "fl oz")
        case .pint: (.kitchenVolume, "pt")
        case .quart: (.kitchenVolume, "qt")
        default: nil
        }
    }
}

public extension IngredientLine {
    /// The amount as the Measure view reads it; nil for a line with no amount ("salt to taste").
    var reading: KitchenReading? {
        guard let amount else { return nil }
        guard let mapped = unit?.measureUnit else {
            let word = unit.map(\.rawValue)
            return .plain(amount: amount, upper: amountMax, word: word)
        }
        return .measure(Measure(amount, mapped.unit, kind: mapped.kind),
                        upper: amountMax.map { Measure($0, mapped.unit, kind: mapped.kind) })
    }

    /// The amount exactly as typed or pasted ("1 1/2 cups"), kept on screen until he swipes the unit. Nil when the line
    /// has no amount or the name cannot be found in it.
    var typedAmountText: String? {
        guard amount != nil, !name.isEmpty,
              let found = original.range(of: name, options: [.caseInsensitive, .diacriticInsensitive])
        else {
            return nil
        }
        let text = original[..<found.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-–•*·"))
            .trimmingCharacters(in: .whitespaces)
        return text.isEmpty ? nil : text
    }
}
