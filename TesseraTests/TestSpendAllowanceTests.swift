import Foundation
@testable import Tessera
import TesseraCore
import TesseraTess
import Testing

/// The test world may spend $20 a month in all, across launches: one file at a fixed path remembers it.
@MainActor
struct TestSpendAllowanceTests {
    private let file = FileManager.default.temporaryDirectory
        .appendingPathComponent("allowance-\(UUID().uuidString)", isDirectory: true)
        .appendingPathComponent("spend.json")

    init() throws {
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
    }

    private func cleanUp() {
        try? FileManager.default.removeItem(at: file.deletingLastPathComponent())
    }

    /// A launch: a stamped store, the app on it, and the allowance begun against `file`.
    private func launch(stamped: Bool = true) throws -> (AppModel, TessUsageLedger, TestSpendAllowance?) {
        let container = TesseraSchema.makeContainer(inMemory: true)
        if stamped {
            let first = ObjectStore(context: container.mainContext)
            _ = try first.prepareCatalog()
            try TestStore.stamp(first)
        }
        let app = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        let ledger = TessUsageLedger(store: app.store, classes: app.classes)
        return (app, ledger, TestSpendAllowance.begin(store: app.store, classes: app.classes, url: file))
    }

    private func left(_ ledger: TessUsageLedger) -> Int64 {
        TessUsageLedger.capNano - ledger.monthTotal()
    }

    private func spend(_ nano: Int64, on ledger: TessUsageLedger) {
        ledger.record(use: .capture, model: "claude-haiku-5-5", input: 1, output: 1, costNano: nano, latency: 0,
                      outcome: "ok", requestID: nil)
    }

    @Test func twoLaunchesShareTheFileAndTheSecondStartsWhereTheFirstLeftOff() throws {
        defer { cleanUp() }
        let (_, one, first) = try launch()
        let allowance = try #require(first)
        #expect(left(one) == TestSpendAllowance.allowanceNano)
        spend(3_000_000_000, on: one)
        #expect(left(one) == TestSpendAllowance.allowanceNano - 3_000_000_000)
        allowance.commit()
        let (_, two, second) = try launch()
        #expect(second != nil)
        #expect(left(two) == TestSpendAllowance.allowanceNano - 3_000_000_000)
        spend(2_000_000_000, on: two)
        second?.commit()
        let (_, three, _) = try launch()
        #expect(left(three) == TestSpendAllowance.allowanceNano - 5_000_000_000)
    }

    @Test func aRealStoreNeverTouchesTheFile() throws {
        defer { cleanUp() }
        let (_, ledger, made) = try launch(stamped: false)
        #expect(made == nil)
        spend(1_000_000_000, on: ledger)
        #expect(!FileManager.default.fileExists(atPath: file.path))
        #expect(left(ledger) == TessUsageLedger.capNano - 1_000_000_000)
    }

    @Test func aCorruptFileCountsAsFullySpent() throws {
        defer { cleanUp() }
        try Data("not json".utf8).write(to: file)
        let (_, ledger, made) = try launch()
        #expect(made != nil)
        #expect(left(ledger) == 0)
        #expect(ledger.reserve(1) == nil)
    }

    @Test func anotherMonthsFileHoldsNothing() throws {
        defer { cleanUp() }
        try Data(#"{"month":"1999-01","nano":19000000000}"#.utf8).write(to: file)
        let (_, ledger, _) = try launch()
        #expect(left(ledger) == TestSpendAllowance.allowanceNano)
    }
}
