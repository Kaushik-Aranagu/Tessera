import Foundation

/// Settings > Units, once (Together round 15, 189, switch unitsV2): one Measure everywhere. Three plain rows, each with
/// the other choice one tap away and a sample line that shows the change. Changing a row only changes `DisplayUnits`;
/// stored values never change, and every shown number reads through Measure. Money currency stays per pool and
/// temperature follows the phone, so neither has a row.
public enum UnitsPage {
    public struct Row: Equatable, Sendable {
        public let kind: MeasureKind
        /// "Weight", "Distance", "Food".
        public let label: String
        /// The unit in use now, as a symbol: "kg".
        public let unit: String
        /// "Weight, kg": the row as the page says it.
        public let text: String
        /// The other choice, one tap away, as a symbol: "lb".
        public let other: String
        /// "Bench 82.5 kg is 181.9 lb."
        public let sample: String
    }

    public static let kinds: [MeasureKind] = [.weight, .distance, .kitchenMass]

    /// What the page can offer for a kind: weight kg or lb, distance km or mi, food g or oz.
    static func choices(for kind: MeasureKind) -> [String] {
        switch kind {
        case .weight: ["kg", "lb"]
        case .distance: ["km", "mi"]
        case .kitchenMass: ["g", "oz"]
        default: []
        }
    }

    private static func label(_ kind: MeasureKind) -> String {
        switch kind {
        case .weight: "Weight"
        case .distance: "Distance"
        default: "Food"
        }
    }

    /// Food reads "grams" and "ounces" in the row; the others read their symbol.
    private static func word(_ unit: String, kind: MeasureKind) -> String {
        guard kind == .kitchenMass else { return unit }
        return unit == "g" ? "grams" : "ounces"
    }

    public static func rows(_ units: DisplayUnits) -> [Row] {
        kinds.map { kind in
            let options = choices(for: kind)
            let current = units.unit(for: kind).flatMap { options.contains($0) ? $0 : nil } ?? options[0]
            let other = options.first { $0 != current } ?? options[0]
            return Row(kind: kind, label: label(kind), unit: current,
                       text: "\(label(kind)), \(word(current, kind: kind))", other: other,
                       sample: sample(kind: kind, from: options[0], to: options[1]))
        }
    }

    /// "Bench 82.5 kg is 181.9 lb." The same quantity in both units, through Measure, so the page and the screens
    /// agree.
    static func sample(kind: MeasureKind, from: String, to: String) -> String {
        let (name, value): (String, Double) = switch kind {
        case .weight: ("Bench", 82.5)
        case .distance: ("A run of", 5)
        default: ("Rice", 500)
        }
        let start = Measure(value, from, kind: kind)
        guard let end = start.converted(to: to) else { return "" }
        return "\(name) \(start.formatted) is \(end.formatted)."
    }

    /// Picks a unit for a row. Anything the page does not offer for that kind is refused (false) and nothing changes.
    @discardableResult
    public static func choose(_ unit: String, for kind: MeasureKind, in units: inout DisplayUnits) -> Bool {
        guard choices(for: kind).contains(unit) else { return false }
        units.choose(unit, for: kind)
        return true
    }
}
