import Foundation

/// Installs the 18 built-in muscles as Muscle objects. Idempotent: existing muscles are matched by name.
@MainActor
public enum MuscleLibrary {
    @discardableResult
    public static func install(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) throws
        -> [MuscleSeed: ObjectRecord]
    {
        guard let muscleClass = classes[.muscle] else { return [:] }
        var existing = Dictionary(store.objects(of: muscleClass).map { ($0.title.lowercased(), $0) },
                                  uniquingKeysWith: { first, _ in first })
        var result: [MuscleSeed: ObjectRecord] = [:]
        for seed in MuscleSeed.allCases {
            let muscle = existing[seed.name.lowercased()] ?? store.create(muscleClass, title: seed.name)
            existing[seed.name.lowercased()] = muscle
            if store.value("group", of: muscle) == nil {
                try store.set("group", to: .text(seed.group), on: muscle)
            }
            result[seed] = muscle
        }
        return result
    }
}
