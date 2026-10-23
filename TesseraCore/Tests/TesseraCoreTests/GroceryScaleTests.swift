import Foundation
@testable import TesseraCore
import Testing

/// G48 (Kitchen gap hunt 7): five years of two shops a week at about 14 rows each leave about 7,000 soft-deleted rows
/// under Groceries. Open it, add a line, check a row and read what Pantry reads, inside the budget the other 5-year
/// screens hold. Runs about 70 shops by default; TESSERA_SCALE=1500 runs the full 520 (`scripts/test.sh --scale`).
@MainActor
struct GroceryScaleTests {
    static let shops = max(20, ScaleTests.workouts * 520 / 1500)

    @Test func groceriesAndPantryReadsStayFast() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let groceries = Groceries(store: store, classes: classes)
        let names = (0 ..< 60).map { "item\($0)" }
        let clock = ContinuousClock()
        let start = Date(timeIntervalSinceReferenceDate: 700_000_000)
        let build = try clock.measure {
            for shop in 0 ..< Self.shops {
                let day = start + Double(shop) * 3.5 * 86400
                try engine.perform(AddGroceries(lines: (0 ..< 14).map { names[(shop * 7 + $0) % names.count] }),
                                   by: .user)
                for row in groceries.shoppingOrder() {
                    try engine.perform(CheckListItem(item: row.id, time: day), by: .user)
                }
                try engine.perform(ClearDoneItems(list: Groceries.listID), by: .user)
            }
        }
        try engine.perform(AddGroceries(lines: ["milk", "eggs", "rice"]), by: .user)
        let list = try #require(groceries.list)
        let tombstones = (list.children ?? []).count { $0.isDeleted }

        func ms(_ work: () throws -> Void) rethrows -> Double {
            let duration = try clock.measure(work)
            return Double(duration.components.seconds) * 1000 + Double(duration.components.attoseconds) / 1e15
        }
        let loadBefore = LoadFactor.current()
        let open = ms { _ = groceries.aisles() }
        let order = ms { _ = groceries.shoppingOrder() }
        // Best of three, each on a fresh line: a loaded Mac delays one run, never all of them.
        var adds = [Double](), checks = [Double]()
        for index in 0 ..< 3 {
            try adds.append(ms { try engine.perform(AddGroceries(lines: ["butter\(index)"]), by: .user) })
            let row = try #require(groceries.shoppingOrder().first)
            try checks.append(ms { try engine.perform(CheckListItem(item: row.id, time: start), by: .user) })
        }
        let add = adds.min() ?? 0, check = checks.min() ?? 0
        // The worse of the load before and after the reads: either end busy gives the reads more room.
        let load = max(loadBefore, LoadFactor.current())
        let clears = ms { _ = groceries.shopClears() }
        let again = ms { _ = groceries.shopClears() } // the cached read
        print("GROCERY SCALE load x\(load) \(Self.shops) shops, \(tombstones) tombstones: build=\(ms {})ms open=\(open)ms "
            + "order=\(order)ms add=\(add)ms check=\(check)ms shopClears=\(clears)ms cached=\(again)ms "
            + "buildTotal=\(build)")
        let budget: Double = (Self.shops > 200 ? 200 : 100) * load
        #expect(open < budget && order < budget, "open \(open) order \(order)")
        #expect(add < budget * 2 && check < budget, "add \(add) check \(check)")
        #expect(clears < budget * 2, "shopClears \(clears)")
        // The cached read must be the cheap one: not slower than the first, and a tenth of the budget at most.
        #expect(again <= max(clears, 1) && again < budget / 10, "cached shopClears \(again) vs first \(clears)")
    }
}
