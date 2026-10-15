import Foundation

/// Quantities are stored in one canonical unit (mass in kilograms, durations in seconds) so records, e1RM and
/// volume never mix units. The unit the person typed is kept beside the value, and display converts back.
public enum MassUnit: String, Codable, Sendable, CaseIterable {
    case kilograms = "kg"
    case pounds = "lb"

    public static let poundsPerKilogram = 2.204_622_621_8

    public var symbol: String {
        rawValue
    }

    /// Converts a value in this unit to kilograms (the stored unit).
    public func toKilograms(_ value: Double) -> Double {
        switch self {
        case .kilograms: value
        case .pounds: value / Self.poundsPerKilogram
        }
    }

    /// Converts stored kilograms to this unit for display, rounded to what a gym can load
    /// (0.25 kg, 0.5 lb), so 80 kg shows as 176.5 lb, not 176.369…
    public func fromKilograms(_ kilograms: Double, rounded: Bool = true) -> Double {
        let value = switch self {
        case .kilograms: kilograms
        case .pounds: kilograms * Self.poundsPerKilogram
        }
        guard rounded else { return value }
        let step = self == .kilograms ? 0.25 : 0.5
        return (value / step).rounded() * step
    }

    /// "80 kg", "176.5 lb".
    public func format(kilograms: Double) -> String {
        let value = fromKilograms(kilograms)
        let number = value.rounded() == value ? String(Int(value)) : String(format: "%g", value)
        return "\(number) \(symbol)"
    }

    /// Reads "kg", "kgs", "kilo", "lb", "lbs", "pound(s)".
    public init?(parsing text: String) {
        switch text.lowercased().trimmingCharacters(in: .punctuationCharacters) {
        case "kg", "kgs", "kilo", "kilos", "kilogram", "kilograms": self = .kilograms
        case "lb", "lbs", "pound", "pounds": self = .pounds
        default: return nil
        }
    }
}
