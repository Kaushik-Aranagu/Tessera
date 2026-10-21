import Foundation

/// The kinds of number that carry a small unit beside them (Design sheet 115: the data plane is the number and the
/// unit, each its own; the control plane lets the number be edited alone and the unit be swiped alone). A measure is
/// a value with its kind and unit. Converting it never changes what is stored: it only expresses the same quantity
/// in another unit.
public enum MeasureKind: String, Codable, Sendable, CaseIterable {
    case weight, distance, time, length, temperature, money

    /// The units that fit this kind, in the order the unit wheel swipes through them. Money has none of its own: its
    /// wheel is the currencies the rates table knows.
    public var units: [String] {
        switch self {
        case .weight: ["kg", "lb"]
        case .distance: ["km", "mi"]
        case .time: ["min", "hr"]
        case .length: ["cm", "in"]
        case .temperature: ["°C", "°F"]
        case .money: []
        }
    }

    /// The unit a value of this kind is stored in (money: as typed, so there is none).
    public var base: String? {
        units.first
    }

    /// Whether a unit of this kind belongs on a wheel at all without a rates table.
    public var convertsOffline: Bool {
        self != .money
    }

    /// The kind a unit symbol belongs to, for the non-money kinds.
    public static func kind(ofUnit unit: String) -> MeasureKind? {
        allCases.first { $0.units.contains(unit) }
    }
}

/// A value in a unit. Immutable: `converted(to:)` returns a new measure of the same quantity.
public struct Measure: Equatable, Sendable {
    public let kind: MeasureKind
    public let value: Double
    /// "kg", "lb", ... or, for money, the currency code the amount was typed in ("" when none was said).
    public let unit: String
    /// True for a converted amount of money: it reads as an estimate ("about 24.80 EUR").
    public let isEstimate: Bool
    /// The date of the rate used to estimate it.
    public let rateDate: Date?

    public init(_ value: Double, _ unit: String, kind: MeasureKind? = nil, isEstimate: Bool = false,
                rateDate: Date? = nil)
    {
        self.kind = kind ?? MeasureKind.kind(ofUnit: unit) ?? .money
        self.value = value
        self.unit = unit
        self.isEstimate = isEstimate
        self.rateDate = rateDate
    }

    public static func money(_ amount: Double, currency: String?) -> Measure {
        Measure(amount, currency ?? "", kind: .money)
    }

    /// The same quantity in another unit of its kind; nil when it cannot be done (a money wheel with no rates, or
    /// a unit of another kind).
    public func converted(to target: String, rates: CurrencyRates? = nil) -> Measure? {
        if kind == .money {
            guard !unit.isEmpty, let rates, let moved = rates.convert(value, from: unit, to: target) else {
                return unit == target ? self : nil
            }
            return unit == target ? self : Measure(moved, target, kind: .money, isEstimate: true, rateDate: rates.date)
        }
        guard let moved = UnitConverter.convert(value, from: unit, to: target) else { return nil }
        return Measure(moved, target, kind: kind)
    }

    /// "181.9 lb", "5.6 km"; money as typed ("€12.40", "12.40") or, estimated, "about 24.80 EUR".
    public var formatted: String {
        MeasureFormat.string(self)
    }
}

/// Pure conversion between units of one kind. Values are `Double`; display rounding lives in `MeasureFormat`.
public enum UnitConverter {
    static let poundsPerKilogram = 2.204_622_621_8
    static let milesPerKilometre = 0.621_371_192_237_334
    static let inchesPerCentimetre = 1 / 2.54

    /// The value in the target unit, or nil when the two units are not of the same convertible kind.
    public static func convert(_ value: Double, from: String, to: String) -> Double? {
        guard let kind = MeasureKind.kind(ofUnit: from), kind == MeasureKind.kind(ofUnit: to) else { return nil }
        if from == to {
            return value
        }
        return fromBase(toBase(value, unit: from), unit: to)
    }

    private static func toBase(_ value: Double, unit: String) -> Double {
        switch unit {
        case "lb": value / poundsPerKilogram
        case "mi": value / milesPerKilometre
        case "hr": value * 60
        case "in": value / inchesPerCentimetre
        case "°F": (value - 32) * 5 / 9
        default: value
        }
    }

    private static func fromBase(_ value: Double, unit: String) -> Double {
        switch unit {
        case "lb": value * poundsPerKilogram
        case "mi": value * milesPerKilometre
        case "hr": value / 60
        case "in": value * inchesPerCentimetre
        case "°F": value * 9 / 5 + 32
        default: value
        }
    }
}

/// How a measure reads. Sensible digits per unit: 82.5 kg is 181.9 lb; 5 km is 3.11 mi; 90 min is 1.5 hr.
public enum MeasureFormat {
    /// Decimal places shown at most; trailing zeros are dropped.
    static let places: [String: Int] = [
        "kg": 1, "lb": 1, "km": 2, "mi": 2, "min": 0, "hr": 2, "cm": 0, "in": 1, "°C": 1, "°F": 1,
    ]

    public static func number(_ value: Double, unit: String) -> String {
        let digits = places[unit] ?? 2
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = digits
        formatter.usesGroupingSeparator = false
        let rounded = (value * pow(10, Double(digits))).rounded() / pow(10, Double(digits))
        return formatter.string(from: NSNumber(value: rounded == 0 ? 0 : rounded)) ?? String(value)
    }

    static let signs = ["EUR": "€", "GBP": "£", "USD": "$", "INR": "₹"]

    public static func string(_ measure: Measure) -> String {
        if measure.kind == .money {
            let amount = String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), measure.value)
            if measure.isEstimate {
                return "about \(amount) \(measure.unit)"
            }
            // As typed: the sign against the number when the currency has one, the bare number otherwise.
            return signs[measure.unit].map { $0 + amount } ?? amount
        }
        return "\(number(measure.value, unit: measure.unit))\(measure.unit == "°C" || measure.unit == "°F" ? "" : " ")\(measure.unit)"
    }
}
