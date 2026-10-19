import Foundation

/// Kaushik's real starting point, installed once on first launch: his gym kit and a Push / Pull / Legs × 2 plan.
/// Hard-coded on purpose (ship list slice 1); he edits it in the app from here.
@MainActor
public enum StarterContent {
    /// One slot: library exercise key, working sets, rep range.
    struct Slot {
        let exercise: String
        let sets: Double
        let reps: ClosedRange<Int>
    }

    static let routines: [(key: String, title: String, slots: [Slot])] = [
        ("pushA", "Push A", [
            Slot(exercise: "benchPress", sets: 4, reps: 5 ... 8),
            Slot(exercise: "overheadPress", sets: 3, reps: 6 ... 10),
            Slot(exercise: "inclineDbPress", sets: 3, reps: 8 ... 12),
            Slot(exercise: "dbLateralRaise", sets: 3, reps: 12 ... 15),
            Slot(exercise: "ropePushdown", sets: 3, reps: 10 ... 15),
        ]),
        ("pullA", "Pull A", [
            Slot(exercise: "barbellRow", sets: 4, reps: 6 ... 10),
            Slot(exercise: "latPulldown", sets: 3, reps: 8 ... 12),
            Slot(exercise: "seatedCableRow", sets: 3, reps: 10 ... 12),
            Slot(exercise: "facePull", sets: 3, reps: 12 ... 15),
            Slot(exercise: "dbCurl", sets: 3, reps: 10 ... 12),
        ]),
        ("legsA", "Legs A", [
            Slot(exercise: "backSquat", sets: 4, reps: 5 ... 8),
            Slot(exercise: "romanianDeadlift", sets: 3, reps: 6 ... 10),
            Slot(exercise: "legPress", sets: 3, reps: 10 ... 12),
            Slot(exercise: "lyingLegCurl", sets: 3, reps: 10 ... 15),
            Slot(exercise: "standingCalfRaise", sets: 4, reps: 10 ... 15),
        ]),
        ("pushB", "Push B", [
            Slot(exercise: "overheadPress", sets: 4, reps: 5 ... 8),
            Slot(exercise: "dbBenchPress", sets: 3, reps: 8 ... 12),
            Slot(exercise: "dip", sets: 3, reps: 8 ... 12),
            Slot(exercise: "cableLateralRaise", sets: 3, reps: 12 ... 15),
            Slot(exercise: "overheadCableExtension", sets: 3, reps: 10 ... 15),
        ]),
        ("pullB", "Pull B", [
            Slot(exercise: "pullUp", sets: 4, reps: 5 ... 10),
            Slot(exercise: "oneArmDbRow", sets: 3, reps: 8 ... 12),
            Slot(exercise: "chestSupportedRow", sets: 3, reps: 10 ... 12),
            Slot(exercise: "reversePecDeck", sets: 3, reps: 12 ... 15),
            Slot(exercise: "hammerCurl", sets: 3, reps: 10 ... 12),
        ]),
        ("legsB", "Legs B", [
            Slot(exercise: "deadlift", sets: 3, reps: 3 ... 6),
            Slot(exercise: "frontSquat", sets: 3, reps: 6 ... 10),
            Slot(exercise: "bulgarianSplitSquat", sets: 3, reps: 8 ... 12),
            Slot(exercise: "legExtension", sets: 3, reps: 12 ... 15),
            Slot(exercise: "seatedCalfRaise", sets: 4, reps: 12 ... 15),
        ]),
    ]

    /// push, pull or legs, from a starter routine's key ("pushA" gives push).
    static func kind(forKey key: String) -> String? {
        ["push", "pull", "legs"].first { key.hasPrefix($0) }
    }

    /// The additive migration: each seeded routine that has no kind gets one, whatever its title is now (he may have
    /// renamed "Push A" to "Bench day"). Never overwrites a kind he or a later rule set. Run at every launch.
    public static func backfillKinds(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) {
        guard classes[.routine] != nil else { return }
        for (key, _, _) in routines {
            guard let kind = kind(forKey: key),
                  let object = store.object(id: SystemCatalog.stableID("starter.routine.\(key)")),
                  !object.isDeleted, store.value("kind", of: object) == nil else { continue }
            try? store.set("kind", to: .choice(kind), on: object)
        }
    }

    /// Gym kit: a 20 kg bar, plates down to 1.25 kg (pairs), dumbbells in 2 kg steps.
    static let plates = "25, 20, 15, 10, 5, 2.5, 1.25"
    static let dumbbells = stride(from: 2.0, through: 50, by: 2).map { "\(Int($0))" }.joined(separator: ", ")

    public static var planID: UUID {
        SystemCatalog.stableID("starter.plan.ppl2")
    }

    /// Installs the gym kit and the plan once. The library must be installed first.
    @discardableResult
    public static func installIfNeeded(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) throws -> Bool {
        guard store.object(id: planID) == nil, let routineClass = classes[.routine], let slotClass = classes[.slot],
              let planClass = classes[.plan] else { return false }
        try configureEquipment(store: store, classes: classes)

        var routines: [ObjectRecord] = []
        for routine in self.routines {
            let object = store.create(routineClass, title: routine.title)
            object.id = SystemCatalog.stableID("starter.routine.\(routine.key)")
            if let kind = Self.kind(forKey: routine.key) {
                try store.set("kind", to: .choice(kind), on: object)
            }
            for (index, slot) in routine.slots.enumerated() {
                guard let exercise = store.classDef(id: SystemCatalog.stableID("library.\(slot.exercise)"))
                    ?? (slot.exercise == "benchPress" ? classes[.benchPress] : nil) else { continue }
                let slotObject = store.create(slotClass, parent: object)
                slotObject.sortIndex = index
                try store.setClassLink("exercise", on: slotObject, to: exercise)
                try store.set("sets", to: .number(slot.sets), on: slotObject)
                try store.set("repMin", to: .number(Double(slot.reps.lowerBound)), on: slotObject)
                try store.set("repMax", to: .number(Double(slot.reps.upperBound)), on: slotObject)
            }
            routines.append(object)
        }
        let plan = store.create(planClass, title: "Push Pull Legs")
        plan.id = planID
        try store.setLinks("routines", on: plan, to: routines)
        return true
    }

    /// The bar, plates and dumbbells, on the library's Equipment objects (so plate math and dial detents use them).
    static func configureEquipment(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) throws {
        guard let equipmentClass = classes[.equipment] else { return }
        for object in store.objects(of: equipmentClass) {
            switch store.value("kind", of: object)?.stringValue.flatMap(EquipmentKind.init(rawValue:)) {
            case .barbell, .smith:
                try store.set("barWeight", to: .mass(20), on: object)
                try store.set("plates", to: .text(plates), on: object)
            case .ezBar:
                try store.set("barWeight", to: .mass(10), on: object)
                try store.set("plates", to: .text(plates), on: object)
            case .dumbbell:
                try store.set("loads", to: .text(dumbbells), on: object)
            default:
                break
            }
        }
        store.invalidateCaches()
    }
}
