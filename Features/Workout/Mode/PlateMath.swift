import Foundation
import TesseraCore

/// What goes on one side of the bar for a target weight (sheet 325). Pure: no views, no store reads. Core owns
/// TesseraCore, so this lives in the app target behind the `PlateMath` seam until Core moves it (the Live Activity and
/// the watch will share it then).
struct PlateLoad: Equatable, Sendable {
    /// One side's plates, heaviest first ("45 + 25" is [45, 25]).
    var perSide: [Double]
    /// The bar's own weight.
    var bar: Double
    /// What the bar and plates actually weigh. Under the target when the plates cannot make it exactly.
    var achieved: Double
    /// Target minus achieved, never negative: what the plates could not make (0 for an exact load).
    var short: Double

    var isExact: Bool {
        short < 0.001
    }

    var isBarOnly: Bool {
        perSide.isEmpty
    }

    /// "each side 45 + 25", "bar only"; no full stop.
    var line: String {
        guard !perSide.isEmpty else { return "bar only" }
        return "each side " + perSide.map(Self.number).joined(separator: " + ")
    }

    static func number(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0 ... 2)))
    }
}

/// The plates a gym has, per unit. The inventory is the plate sizes; the solver takes as many of each as it needs.
struct PlateInventory: Equatable, Sendable {
    var unit: MassUnit
    /// Plate sizes, in any order.
    var plates: [Double]
    /// The usual bar for the unit (45 lb, 20 kg).
    var bar: Double

    static let pounds = PlateInventory(unit: .pounds, plates: [45, 35, 25, 10, 5, 2.5], bar: 45)
    static let kilograms = PlateInventory(unit: .kilograms, plates: [25, 20, 15, 10, 5, 2.5, 1.25], bar: 20)

    static func standard(for unit: MassUnit) -> PlateInventory {
        unit == .pounds ? .pounds : .kilograms
    }

    /// The weight step the drag and Felt use: 5 lb, 2.5 kg.
    var step: Double {
        unit == .pounds ? 5 : 2.5
    }
}

/// The seam: plates per side for a target total.
protocol PlateMath: Sendable {
    func load(target: Double, bar: Double, inventory: PlateInventory) -> PlateLoad
}

/// Greedy solver: heaviest plate first, as many of each as fit. For gym plate sets greedy is exact whenever an exact
/// load exists; when it does not, the load is the nearest the plates can make without going over.
struct GreedyPlateMath: PlateMath {
    func load(target: Double, bar: Double, inventory: PlateInventory) -> PlateLoad {
        var left = max(target - bar, 0) / 2
        var chosen: [Double] = []
        let epsilon = 0.0005
        for plate in inventory.plates.sorted(by: >) where plate > 0 {
            while left + epsilon >= plate {
                chosen.append(plate)
                left -= plate
            }
        }
        let achieved = bar + chosen.reduce(0, +) * 2
        return PlateLoad(perSide: chosen, bar: bar, achieved: achieved, short: max(target - achieved, 0))
    }
}

extension PlateMath where Self == GreedyPlateMath {
    static var greedy: GreedyPlateMath {
        GreedyPlateMath()
    }
}
