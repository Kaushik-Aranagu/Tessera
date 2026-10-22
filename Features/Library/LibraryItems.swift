import Foundation
import TesseraCore

/// The words he filters the library by: a muscle group, not the eighteen muscles.
enum MuscleGroupWord: String, CaseIterable {
    case chest = "Chest", back = "Back", shoulders = "Shoulders", arms = "Arms", legs = "Legs", core = "Core"

    var muscles: Set<MuscleSeed> {
        switch self {
        case .chest: [.chest]
        case .back: [.lats, .upperBack, .lowerBack]
        case .shoulders: [.frontDelts, .sideDelts, .rearDelts]
        case .arms: [.biceps, .triceps, .forearms]
        case .legs: [.glutes, .quads, .hamstrings, .adductors, .abductors, .calves]
        case .core: [.abs, .obliques]
        }
    }
}

/// One row of the library: one of the 72 we wrote, or one of the extras (which becomes a real exercise the first
/// time it is opened).
struct LibraryItem: Identifiable {
    let id: String
    let name: String
    let equipment: EquipmentKind
    let muscles: [MuscleSeed]
    let classDef: ClassDef?
    let extra: LibraryExercise?
    /// His heaviest working set in his last session of it, nil when he has never done it.
    let lastWeight: Double?

    var isMine: Bool {
        lastWeight != nil
    }

    func matches(_ group: MuscleGroupWord?) -> Bool {
        guard let group else { return true }
        return !group.muscles.isDisjoint(with: muscles)
    }
}

enum LibraryItems {
    /// All of the library, A to Z inside each kind of equipment.
    @MainActor
    static func all(model: AppModel) -> [LibraryItem] {
        let store = model.store
        var items: [LibraryItem] = []
        var adoptedNames = Set<String>()
        for seed in ExerciseLibrary.seeds {
            let classDef = seed.key == "benchPress"
                ? model.classes[.benchPress]
                : store.classDef(id: SystemCatalog.stableID("library.\(seed.key)"))
            items.append(LibraryItem(id: "seed.\(seed.key)", name: seed.name, equipment: seed.equipment,
                                     muscles: seed.primary, classDef: classDef, extra: nil,
                                     lastWeight: classDef.flatMap { last(of: $0, model: model) }))
            adoptedNames.insert(seed.name.lowercased())
        }
        for extra in LibraryExtras.all where !adoptedNames.contains(extra.name.lowercased()) {
            let adopted = LibraryAdopter.adoptedClass(of: extra, store: store)
            items.append(LibraryItem(id: "extra.\(extra.id)", name: extra.name, equipment: extra.equipment,
                                     muscles: extra.primary, classDef: adopted, extra: extra,
                                     lastWeight: adopted.flatMap { last(of: $0, model: model) }))
        }
        return items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    @MainActor
    private static func last(of classDef: ClassDef, model: AppModel) -> Double? {
        model.ledger.sessions(of: classDef).first.flatMap { $0.sets.map(\.weight).max() }
    }

    /// The items grouped by equipment, in the order a gym is walked, only the kinds that have any.
    static func sections(_ items: [LibraryItem]) -> [(equipment: EquipmentKind, items: [LibraryItem])] {
        let order: [EquipmentKind] = [
            .barbell,
            .dumbbell,
            .ezBar,
            .cable,
            .machine,
            .smith,
            .kettlebell,
            .bodyweight,
            .band,
        ]
        return order.compactMap { kind in
            let rows = items.filter { $0.equipment == kind }
            return rows.isEmpty ? nil : (kind, rows)
        }
    }
}
