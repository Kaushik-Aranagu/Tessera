import Foundation

/// The unit he last picked for each kind, used everywhere that kind shows (Design sheet 115). A preference in
/// settings: stored values never change when it does, and it is never sent to Claude.
public struct DisplayUnits: Equatable, Codable, Sendable {
    public var chosen: [String: String]

    public init(chosen: [String: String] = [:]) {
        self.chosen = chosen
    }

    /// His pick for a kind, or nil when he has not picked one (then today's behavior stands).
    public func unit(for kind: MeasureKind) -> String? {
        chosen[kind.rawValue].flatMap { kind == .money || kind.units.contains($0) ? $0 : nil }
    }

    public mutating func choose(_ unit: String?, for kind: MeasureKind) {
        if let unit, kind == .money || kind.units.contains(unit) {
            chosen[kind.rawValue] = unit
        } else if unit == nil {
            chosen[kind.rawValue] = nil
        }
    }

    /// "weight=lb;distance=mi", sorted: the one text field in settings.
    public var encoded: String? {
        chosen.isEmpty ? nil : chosen.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: ";")
    }

    public init(encoded: String?) {
        var map: [String: String] = [:]
        for part in (encoded ?? "").split(separator: ";") {
            let pair = part.split(separator: "=", maxSplits: 1).map(String.init)
            if pair.count == 2, MeasureKind(rawValue: pair[0]) != nil {
                map[pair[0]] = pair[1]
            }
        }
        chosen = map
    }

    /// A stored weight in kilograms as the chosen unit shows it, or nil when he has not picked one.
    public func weight(kilograms: Double) -> Measure? {
        unit(for: .weight).flatMap { Measure(kilograms, "kg").converted(to: $0) }
    }

    /// His chosen weight unit as the app's `MassUnit` (kg or lb), or nil when he has not picked one. The app's
    /// weight format (`Format.unit`) reads this, so widgets and the Island say weights in the same unit.
    public var massUnit: MassUnit? {
        unit(for: .weight).flatMap(MassUnit.init(parsing:))
    }

    /// A quantity expressed in his chosen unit for its kind; unchanged when he has not picked one (or for money).
    public func shown(_ measure: Measure) -> Measure {
        guard measure.kind != .money, let unit = unit(for: measure.kind) else { return measure }
        return measure.converted(to: unit) ?? measure
    }
}
