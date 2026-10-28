import Foundation

/// Sample data for the Chart room until he says production-ready: a "Plant" class with `lastWatered` (date) and
/// `waterEvery` (number), and four plants, so the fixture room has something real to bind to. Idempotent.
@MainActor
public enum RoomSample {
    @discardableResult
    public static func seedPlants(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef], now: Date = .now,
                                  calendar: Calendar = .current) throws -> ClassDef
    {
        if let existing = store.classDef(named: "Plant") {
            return existing
        }
        let thing = try require(classes[.thing])
        let plant = store.createClass(name: "Plant", parent: thing, symbolName: "leaf")
        for (index, (key, name, kind)) in [("lastWatered", "Last watered", FieldKind.date),
                                           ("waterEvery", "Water every", .number)].enumerated()
        {
            let def = FieldDef(name: name, key: key, kind: kind, sortIndex: index)
            def.owner = plant
            store.context.insert(def)
        }
        store.invalidateCaches()
        for (name, every, daysAgo) in [("Orchid", 7.0, 6), ("Monstera", 7, 4), ("Basil", 3, 1), ("Fern", 5, 2)] {
            let object = store.create(plant, title: name)
            try store.set("waterEvery", to: .number(every), on: object)
            let day = calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: now))
            try store.set("lastWatered", to: day.map { .date($0) }, on: object)
        }
        return plant
    }

    private static func require<T>(_ value: T?) throws -> T {
        guard let value else { throw ObjectStore.StoreError.unknownField("thing") }
        return value
    }
}
