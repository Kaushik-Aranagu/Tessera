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

    @Test(arguments: [7, 11]) func writeByWriteLabelsEqualAFreshPass(seed: UInt64) throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let context = store.context
        var rng = Rng(state: seed)
        let kinds: [SystemCatalog.Key] = [.note, .task, .recipe, .ingredient, .routine, .list, .listItem, .recipeLine]
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
            switch Int.random(in: 0 ..< 8, using: &rng) {
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
    }
}
