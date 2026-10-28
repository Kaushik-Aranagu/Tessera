import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// G654: the month's spend lives in a file beside the store, outside backup; the higher of the two totals wins.
@MainActor
@Suite(.oldWalls)
struct TessSpendFileTests {
    func folder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test func theFileSitsBesideTheStoreIsOutsideBackupAndCountsTheCall() throws {
        let dir = try folder()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = try ObjectStore(context: TesseraContext(url: dir.appendingPathComponent("tessera.sqlite")))
        let classes = try store.prepareCatalog()
        let ledger = TessUsageLedger(store: store, classes: classes)
        let now = Date.now
        ledger.record(use: .capture, model: ClaudeTessModel.model, input: 1, output: 1, costNano: 2_500_000,
                      latency: 0, outcome: "works", requestID: nil, at: now)
        let file = dir.appendingPathComponent(TessSpendFile.fileName)
        #expect(FileManager.default.fileExists(atPath: file.path))
        let values = try file.resourceValues(forKeys: [.isExcludedFromBackupKey])
        #expect(values.isExcludedFromBackup == true)
        let text = try String(contentsOf: file, encoding: .utf8)
        #expect(!text.contains("sk-") && !text.contains("capture")) // money and a month, nothing else
        #expect(ledger.monthTotal(now: now) == 2_500_000)
    }

    @Test func aResetOrRestoreOfTheRowsNeverLowersTheMonth() throws {
        let dir = try folder()
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("tessera.sqlite")
        let now = Date.now
        do {
            let store = try ObjectStore(context: TesseraContext(url: url))
            let ledger = try TessUsageLedger(store: store, classes: store.prepareCatalog())
            ledger.record(use: .capture, model: ClaudeTessModel.model, input: 0, output: 0,
                          costNano: TessUsageLedger.capNano - 1000, latency: 0, outcome: "works", requestID: nil,
                          at: now)
            store.save()
        }
        // A fresh store at the same place (rows gone, as after a restore from an older copy): the file still counts.
        try FileManager.default.removeItem(at: url)
        for sibling in ["-wal", "-shm"] {
            try? FileManager.default.removeItem(atPath: url.path + sibling)
        }
        let again = try ObjectStore(context: TesseraContext(url: url))
        let ledger = try TessUsageLedger(store: again, classes: again.prepareCatalog())
        #expect(ledger.calls().isEmpty)
        #expect(ledger.monthTotal(now: now) == TessUsageLedger.capNano - 1000)
        #expect(ledger.reserve(100_000, now: now) == nil, "the cap held after the rows were lost")
    }

    @Test func anInMemoryStoreWritesNoFile() throws {
        let store = ObjectStore.open(inMemory: true)
        let ledger = try TessUsageLedger(store: store, classes: store.prepareCatalog())
        ledger.record(use: .capture, model: ClaudeTessModel.model, input: 0, output: 0, costNano: 5, latency: 0,
                      outcome: "works", requestID: nil)
        #expect(TessSpendFile(store: store) == nil)
        #expect(ledger.monthTotal() == 5)
    }

    @Test func aFileFromAnEarlierMonthHoldsNothingForThisOne() throws {
        let dir = try folder()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = try ObjectStore(context: TesseraContext(url: dir.appendingPathComponent("tessera.sqlite")))
        let file = try #require(TessSpendFile(store: store))
        file.add(9999, month: "2026-09")
        #expect(file.total(month: "2026-09") == 9999 && file.total(month: "2026-10") == 0)
        file.add(5, month: "2026-10")
        #expect(file.total(month: "2026-10") == 5 && file.total(month: "2026-09") == 0)
    }

    @Test func theFilesMonthTurnsAtFourAMLikeTheLedger() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        func at(_ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
            calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
        }
        // 00:30 on 1 November is still October's month; 04:00 is November's.
        #expect(TessSpendFile.monthKey(at(11, 1, 0, 30), calendar: calendar) == "2026-10")
        #expect(TessSpendFile.monthKey(at(11, 1, 4, 0), calendar: calendar) == "2026-11")
        #expect(TessSpendFile.monthKey(at(10, 31, 23, 59), calendar: calendar) == "2026-10")
    }
}
