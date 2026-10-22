import Foundation
import TesseraCore

/// Where he trains (Design 128): the Gym has everything; Home has what a home gym has. Remembered across launches.
/// The Plan is never rewritten by it: a workout that needs what the place lacks stays in the library, drawn at 30%.
enum TrainingPlace: String, CaseIterable {
    case gym = "Gym", home = "Home"

    private static let key = "training.place"

    static func current(_ defaults: UserDefaults = .standard) -> TrainingPlace {
        defaults.string(forKey: key).flatMap(TrainingPlace.init(rawValue:)) ?? .gym
    }

    static func set(_ place: TrainingPlace, defaults: UserDefaults = .standard) {
        defaults.set(place.rawValue, forKey: key)
    }

    /// What is on hand here.
    var equipment: Set<EquipmentKind> {
        switch self {
        case .gym: Set(EquipmentKind.allCases)
        case .home: [.bodyweight, .band, .dumbbell, .kettlebell]
        }
    }

    /// What a workout needs that this place does not have, in a steady order.
    func lacking(_ workout: ReadyWorkout) -> [EquipmentKind] {
        workout.equipment.subtracting(equipment).sorted { $0.rawValue < $1.rawValue }
    }

    /// "needs a cable; Home has none", or nil when the place has all of it.
    func reason(for workout: ReadyWorkout) -> String? {
        let missing = lacking(workout)
        guard !missing.isEmpty else { return nil }
        let words = missing.map(Self.need)
        let list = words.count > 2 ? words.prefix(2).joined(separator: ", ") + " and more"
            : words.joined(separator: " and ")
        return "needs \(list); \(rawValue) has none"
    }

    /// "a cable", "dumbbells": the thing, as it reads after "needs".
    static func need(_ kind: EquipmentKind) -> String {
        switch kind {
        case .barbell: "a barbell"
        case .dumbbell: "dumbbells"
        case .ezBar: "an EZ bar"
        case .cable: "a cable"
        case .machine: "a machine"
        case .smith: "a Smith machine"
        case .kettlebell: "a kettlebell"
        case .bodyweight: "your body"
        case .band: "a band"
        }
    }

    /// The equipment as a section word.
    static func word(_ kind: EquipmentKind) -> String {
        switch kind {
        case .barbell: "Barbell"
        case .dumbbell: "Dumbbell"
        case .ezBar: "EZ bar"
        case .cable: "Cable"
        case .machine: "Machine"
        case .smith: "Smith"
        case .kettlebell: "Kettlebell"
        case .bodyweight: "Body"
        case .band: "Band"
        }
    }
}
