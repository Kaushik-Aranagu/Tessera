import Foundation

/// Everything the weight dial needs for one exercise: detents at loadable weights and plates per side.
public struct WeightDial: Sendable {
    public let equipment: EquipmentKind?
    /// Loadable weights, ascending: the dial's detents.
    public let detents: [Double]
    /// The empty bar, for barbells.
    public let bar: Double?
    let plateLoad: PlateLoad?

    /// Plates for one side, heaviest first (empty for just the bar), or nil if not a plate-loaded lift or the
    /// weight isn't loadable.
    public func platesPerSide(_ weight: Double) -> [Double]? {
        plateLoad?.plates(for: weight)
    }

    /// "25 + 5 + 1.25", "bar", or nil.
    public func plateLine(_ weight: Double) -> String? {
        guard let plates = platesPerSide(weight) else { return nil }
        guard !plates.isEmpty else { return "bar" }
        return plates.map(WorkoutProgress.format).joined(separator: " + ")
    }

    /// The detent nearest a weight (where the dial settles after a flick).
    public func snap(_ weight: Double) -> Double {
        detents.min { abs($0 - weight) < abs($1 - weight) } ?? weight
    }

    /// The detent `steps` away from `weight` (negative goes down).
    public func step(from weight: Double, by steps: Int) -> Double {
        guard !detents.isEmpty else { return weight }
        let index = detents.firstIndex { $0 >= snap(weight) - 0.001 } ?? 0
        return detents[min(max(index + steps, 0), detents.count - 1)]
    }
}

@MainActor
public extension ObjectStore {
    /// The weight dial for an exercise, from its equipment (the gym kit) up to `limit` kg.
    func weightDial(for exercise: ClassDef, upTo limit: Double = 300) -> WeightDial {
        let profile = loadProfile(for: exercise)
        let plateLoad = profile as? PlateLoad
        return WeightDial(equipment: equipmentKind(of: exercise), detents: profile.loadable(upTo: limit),
                          bar: plateLoad?.bar, plateLoad: plateLoad)
    }
}
