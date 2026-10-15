import Foundation

/// What weights the gym can actually load. All equipment behaviour sits behind this one interface, so whether
/// "Barbell" ends up a class or a trait only changes where the profile comes from, not who uses it.
public protocol LoadProfile: Sendable {
    /// Every loadable weight in kilograms, ascending (the dial's detents).
    func loadable(upTo limit: Double) -> [Double]
    /// The nearest loadable weight.
    func nearest(to weight: Double) -> Double
    /// The smallest loadable weight above `weight`.
    func next(above weight: Double) -> Double?
}

public extension LoadProfile {
    func nearest(to weight: Double) -> Double {
        let options = loadable(upTo: max(weight * 2, weight + 50))
        return options.min { abs($0 - weight) < abs($1 - weight) } ?? weight
    }

    func next(above weight: Double) -> Double? {
        loadable(upTo: weight + 100).first { $0 > weight + 0.001 }
    }
}

/// A bar plus plate pairs: every total reachable with the available plates (per side), plus plate math.
public struct PlateLoad: LoadProfile, Hashable {
    public var bar: Double
    /// Plate sizes available, one pair each unless listed twice.
    public var plates: [Double]

    public init(bar: Double = 20, plates: [Double] = [25, 20, 15, 10, 5, 5, 2.5, 2.5, 1.25, 1.25]) {
        self.bar = bar
        self.plates = plates.sorted(by: >)
    }

    public func loadable(upTo limit: Double) -> [Double] {
        var sides: Set<Double> = [0]
        for plate in plates {
            for side in sides where side + plate <= (limit - bar) / 2 + 0.001 {
                sides.insert(side + plate)
            }
        }
        return sides.map { bar + 2 * $0 }.filter { $0 <= limit + 0.001 }.sorted()
    }

    /// Plates for one side, heaviest first, or nil if the weight isn't loadable.
    public func plates(for weight: Double) -> [Double]? {
        var remaining = (weight - bar) / 2
        guard remaining >= -0.001 else { return nil }
        var used: [Double] = []
        for plate in plates where plate <= remaining + 0.001 {
            used.append(plate)
            remaining -= plate
        }
        return abs(remaining) < 0.001 ? used : nil
    }
}

/// A fixed list of loads: a dumbbell rack, a machine stack, or a constant step.
public struct FixedLoads: LoadProfile, Hashable {
    public var loads: [Double]

    public init(_ loads: [Double]) {
        self.loads = loads.sorted()
    }

    /// Evenly spaced loads, e.g. a machine stack in 5 kg steps.
    public init(step: Double, from start: Double = 0, to end: Double = 300) {
        loads = Array(stride(from: start, through: end, by: step))
    }

    public static let dumbbells = FixedLoads([2, 4, 6, 8, 10, 12, 12.5, 14, 16, 17.5, 20, 22.5, 25, 27.5, 30, 32.5,
                                              35, 37.5, 40, 42.5, 45, 47.5, 50])

    public func loadable(upTo limit: Double) -> [Double] {
        loads.filter { $0 <= limit + 0.001 }
    }
}

public extension ObjectStore {
    /// The load profile for an exercise: its equipment object's bar, plates or loads, else a sensible default
    /// for the equipment kind, else 2.5 kg steps.
    func loadProfile(for exercise: ClassDef) -> any LoadProfile {
        let equipment = linkedObjects("equipment", ofClass: exercise).first
        let kind = equipment.flatMap { value("kind", of: $0)?.stringValue }.flatMap(EquipmentKind.init(rawValue:))
            ?? equipmentKind(of: exercise)
        let parse = { (key: String) -> [Double] in
            guard let equipment, let text = value(key, of: equipment)?.stringValue else { return [] }
            return text.split { $0 == "," || $0 == " " }.compactMap { Double($0) }
        }
        if let equipment, let increment = number("increment", of: equipment), increment > 0 {
            return FixedLoads(step: increment)
        }
        switch kind {
        case .barbell, .ezBar, .smith:
            let bar = equipment.flatMap { number("barWeight", of: $0) } ?? (kind == .ezBar ? 10 : 20)
            let plates = parse("plates")
            return plates.isEmpty ? PlateLoad(bar: bar) : PlateLoad(bar: bar, plates: plates)
        case .dumbbell, .kettlebell:
            let loads = parse("loads")
            return loads.isEmpty ? FixedLoads.dumbbells : FixedLoads(loads)
        case .machine, .cable:
            let loads = parse("loads")
            return loads.isEmpty ? FixedLoads(step: 5) : FixedLoads(loads)
        case .bodyweight, .band, nil:
            return FixedLoads(step: 2.5)
        }
    }
}
