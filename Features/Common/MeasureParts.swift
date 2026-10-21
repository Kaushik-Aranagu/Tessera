import Foundation
import TesseraCore

/// What a measure draws, as plain data (Design sheet 115): the number and the unit are two parts, each drawn in its
/// own role, so a screen never formats a number or a unit by hand. Pure, so it is tested without a view.
enum MeasureParts {
    /// One drawn pair: the number and its small unit. The unit is always drawn when there is one.
    struct Part: Equatable {
        let number: String
        let unit: String
    }

    /// The parts a measure is drawn in. Time past an hour reads "1 hr 35 min" (two pairs); everything else is one.
    static func parts(of measure: Measure) -> [Part] {
        if measure.kind == .time, let hoursAndMinutes = hoursAndMinutes(measure) {
            return [Part(number: "\(hoursAndMinutes.hours)", unit: "hr"),
                    Part(number: "\(hoursAndMinutes.minutes)", unit: "min")]
        }
        if measure.kind == .money {
            // As typed (sign against the number) or, estimated, the bare amount: the view puts "about" before it.
            let amount = measure.isEstimate ? estimate(measure.value) : measure.formatted
            return [Part(number: amount, unit: measure.unit)]
        }
        return [Part(number: MeasureFormat.number(measure.value, unit: measure.unit), unit: measure.unit)]
    }

    /// An estimated amount (Design on Measure): whole units from 10 up, two decimals under 10. A typed amount is
    /// never rounded: it reads as he typed it.
    static func estimate(_ value: Double) -> String {
        String(format: abs(value) >= 10 ? "%.0f" : "%.2f", locale: Locale(identifier: "en_US_POSIX"), value)
    }

    /// 95 min is 1 hr 35 min; under an hour (or whole hours already chosen as hr) is left to the single pair.
    private static func hoursAndMinutes(_ measure: Measure) -> (hours: Int, minutes: Int)? {
        guard measure.unit == "min", measure.value >= 60 else { return nil }
        let total = Int(measure.value.rounded())
        return (total / 60, total % 60)
    }

    // MARK: The unit wheel

    /// The units the wheel steps through for a measure: its kind's units (money: the currencies the rates know), with
    /// the measure's own unit first when it is not in the list. Fewer than two means there is no wheel.
    static func wheel(for measure: Measure, rates: CurrencyRates?) -> [String] {
        let units = measure.kind == .money ? (rates?.currencies ?? []) : measure.kind.units
        guard units.count > 1 else { return [] }
        return units.contains(measure.unit) || measure.unit.isEmpty ? units : [measure.unit] + units
    }

    /// The unit `steps` away from `current` on the wheel; stops at the ends (the wheel does not wrap).
    static func step(_ wheel: [String], from current: String, by steps: Int) -> String {
        guard let index = wheel.firstIndex(of: current) else { return current }
        return wheel[min(max(index + steps, 0), wheel.count - 1)]
    }

    /// A tap under Reduce Motion cycles to the next unit, wrapping.
    static func cycle(_ wheel: [String], from current: String) -> String {
        guard let index = wheel.firstIndex(of: current), !wheel.isEmpty else { return current }
        return wheel[(index + 1) % wheel.count]
    }

    // MARK: Words

    /// How VoiceOver says a unit.
    static func spokenUnit(_ unit: String, plural: Bool = true) -> String {
        let names: [String: (String, String)] = [
            "kg": ("kilogram", "kilograms"), "lb": ("pound", "pounds"), "km": ("kilometre", "kilometres"),
            "mi": ("mile", "miles"), "min": ("minute", "minutes"), "hr": ("hour", "hours"),
            "cm": ("centimetre", "centimetres"), "in": ("inch", "inches"),
            "°C": ("degree Celsius", "degrees Celsius"), "°F": ("degree Fahrenheit", "degrees Fahrenheit"),
        ]
        guard let pair = names[unit] else { return unit }
        return plural ? pair.1 : pair.0
    }

    /// "181.9 pounds", "1 hour 35 minutes", "about 24.80 EUR".
    static func spoken(_ measure: Measure) -> String {
        if measure.kind == .money {
            return measure.formatted
        }
        return parts(of: measure).map { "\($0.number) \(spokenUnit($0.unit, plural: $0.number != "1"))" }
            .joined(separator: " ")
    }
}
