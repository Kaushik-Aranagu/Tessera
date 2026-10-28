import Foundation
@testable import TesseraCore
import Testing

/// The private labels folded in write by write must always equal the labels worked out from scratch.
@MainActor
struct PrivateLabelsIncrementalTests {
    struct Rng: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return state
        }
    }

    static let titles = ["Call the bank", "Push A", "Lexapro refill", "Dr Lin 4 pm", "Groceries", "Rice", "Dal",
                         "Trip packing", "weigh in 82 kg", "Pasta", "Lexapro refill", "Garden", "Rice", "Password list"]

    @Test(arguments: [7, 11, 23]) func writeByWriteLabelsEqualAFreshPass(seed: UInt64) throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let context = store.context
        var rng = Rng(state: seed)
        let kinds: [SystemCatalog.Key] = [.note, .task, .recipe, .ingredient, .routine, .list, .listItem, .recipeLine,
                                          .workout, .cook, .cookDish, .cookSession]
        let engine = ActionEngine(store: store, classes: classes)
        var made: [ObjectRecord] = []
        func pick() -> ObjectRecord? {
            made.isEmpty ? nil : made[Int.random(in: 0 ..< made.count, using: &rng)]
        }
        // Which things are private, and the labels the things private on their own words read as. What an object
        // that is private only by propagation is called depends on the order the pass met it (a child of a private
        // recipe can read as the recipe or by its own class), so the text of those is not compared.
        func fresh() -> [UUID: String] {
            let state = PrivateWords.fullState(in: context, store: store, lastKg: BodyWeight.lastKg(in: store))
            return state.final.reduce(into: [:]) { $0[$1.key] = state.direct[$1.key] ?? "propagated" }
        }
        func settled(_ labels: [UUID: String]) -> [UUID: String] {
            var direct: [UUID: String] = [:]
            let state = PrivateWords.fullState(in: context, store: store, lastKg: BodyWeight.lastKg(in: store))
            for (id, label) in labels {
                direct[id] = state.direct[id] != nil ? label : "propagated"
            }
            return direct
        }
        _ = PrivateWords.labels(in: context)
        for step in 0 ..< 150 {
            switch Int.random(in: 0 ..< 15, using: &rng) {
            case 0, 1, 2:
                let kind = kinds.randomElement(using: &rng) ?? .note
                let title = Self.titles.randomElement(using: &rng) ?? "x"
                let parent = Bool.random(using: &rng) ? pick() : nil
                try made.append(store.create(#require(classes[kind]), title: title, parent: parent))
            case 3:
                if let object = pick() {
                    try? store.set("isPrivate", to: .bool(Bool.random(using: &rng)), on: object)
                }
            case 4:
                if let object = pick() {
                    object.title = Self.titles.randomElement(using: &rng) ?? "y"
                }
            case 5:
                if let object = pick() {
                    store.softDelete(object)
                }
            case 6:
                if let line = made.first(where: { $0.classDef?.systemKey == SystemCatalog.Key.recipeLine.systemKey }),
                   let ingredient = made.first(where: {
                       $0.classDef?.systemKey == SystemCatalog.Key.ingredient.systemKey
                   })
                {
                    try? store.setLinks("ingredient", on: line, to: Bool.random(using: &rng) ? [ingredient] : [])
                }
            case 7:
                // A hard delete: the object and everything under it leave the graph.
                if let object = pick() {
                    made.removeAll { $0 === object }
                    context.delete(object)
                }
            case 8:
                // A link retargeted to another ingredient, and one moved off its first end.
                let lines = made.filter { $0.classDef?.systemKey == SystemCatalog.Key.recipeLine.systemKey }
                let ingredients = made.filter { $0.classDef?.systemKey == SystemCatalog.Key.ingredient.systemKey }
                if let line = lines.randomElement(using: &rng),
                   let ingredient = ingredients.randomElement(using: &rng)
                {
                    try? store.setLinks("ingredient", on: line, to: [ingredient])
                    if let link = line.outgoingLinks?.first, let other = pick() {
                        link.toObject = Bool.random(using: &rng) ? other : link.toObject
                    }
                }
            case 9:
                // A weigh-in that moves the last weight, which moves what counts as a body fact for everything.
                let note = try store.create(#require(classes[.note]), title: "weigh in")
                try? store.set("isPrivate", to: .bool(true), on: note)
                try? store.set("body", to: .text("weigh in \(Int.random(in: 60 ... 95, using: &rng)) kg"), on: note)
                made.append(note)
            case 10:
                // A workout linked to a routine, whose title then changes.
                let workouts = made.filter { $0.classDef?.systemKey == SystemCatalog.Key.workout.systemKey }
                let routines = made.filter { $0.classDef?.systemKey == SystemCatalog.Key.routine.systemKey }
                if let workout = workouts.randomElement(using: &rng),
                   let routine = routines.randomElement(using: &rng)
                {
                    try? store.setLinks("routine", on: workout, to: [routine])
                    routine.title = Self.titles.randomElement(using: &rng) ?? "r"
                }
            case 11:
                // A dish of a cook, with its recipe and its cook, then the recipe is retitled.
                let dishes = made.filter { $0.classDef?.systemKey == SystemCatalog.Key.cookDish.systemKey }
                let recipes = made.filter { $0.classDef?.systemKey == SystemCatalog.Key.recipe.systemKey }
                let cooks = made.filter { $0.classDef?.systemKey == SystemCatalog.Key.cook.systemKey }
                if let dish = dishes.randomElement(using: &rng), let recipe = recipes.randomElement(using: &rng) {
                    try? store.setLinks("recipe", on: dish, to: [recipe])
                    if let cook = cooks.randomElement(using: &rng) {
                        try? store.setLinks("cook", on: dish, to: [cook])
                        try? store.setLinks("recipe", on: cook, to: [recipe])
                    }
                    recipe.title = Self.titles.randomElement(using: &rng) ?? "r"
                }
            case 12:
                // An action and its undo.
                if let record = try? engine.perform(CreateNote(body: Self.titles.randomElement(using: &rng) ?? "n"),
                                                    by: .user).record
                {
                    if Bool.random(using: &rng) {
                        engine.undo(record)
                    }
                }
            case 13:
                if let record = engine.history(limit: 1).first {
                    if Bool.random(using: &rng) {
                        engine.undo(record)
                    } else {
                        engine.redo(record)
                    }
                }
            default:
                if let object = pick(), let other = pick(), object !== other, other.parent !== object {
                    object.parent = Bool.random(using: &rng) ? other : nil
                }
            }
            if step % 4 == 0 {
                let got = settled(PrivateWords.labels(in: context))
                let want = fresh()
                if got != want {
                    let ids = Set(got.keys).union(want.keys).filter { got[$0] != want[$0] }
                    for id in ids.prefix(4) {
                        let object = context.objects[id]
                        print("MISMATCH step \(step): \(object?.title ?? "?") \(object?.classDef?.name ?? "?") "
                            + "deleted \(object?.isDeleted ?? false) parent \(object?.parent?.title ?? "-") "
                            + "got \(got[id] ?? "nil") want \(want[id] ?? "nil")")
                    }
                    #expect(Bool(false), "step \(step)")
                    break
                }
            }
        }
        #expect(settled(PrivateWords.labels(in: context)) == fresh())
        // The sequence did move his last weight, so the full-pass fallback ran too.
        #expect(BodyWeight.lastKg(in: store) != nil)
    }
}
