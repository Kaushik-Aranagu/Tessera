import Foundation
import TesseraCore
import TesseraTess

/// The test world's own money limit: $20 a month in total, across every `-testStore` launch. Each launch's store is a
/// fresh temp folder, so the ledger there starts at $0; this keeps ONE small file at a fixed path in the app sandbox
/// (outside any per-launch folder) that remembers what earlier launches spent, and starts each launch's ledger already
/// holding the rest of the $100 cap, so only the $20 allowance minus that remains. Money only, in nano-dollars.
/// It is only ever made for a stamped store that is not his; a real store never reads or writes the file.
@MainActor
final class TestSpendAllowance {
    /// $20 a month, in nano-dollars (the ledger's unit; `TessUsageLedger.capNano` is $100).
    static let allowanceNano: Int64 = 20_000_000_000

    private struct Entry: Codable {
        var month: String
        var nano: Int64
    }

    /// `Application Support/TesseraTest/spend.json`, in the app sandbox. It survives launches (the temp store does
    /// not).
    static var defaultURL: URL {
        let folder = URL.applicationSupportDirectory.appendingPathComponent("TesseraTest", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("spend.json")
    }

    let url: URL
    private let ledger: TessUsageLedger
    private var committed: Int64
    /// The ledger month this launch is counting in, and the last moment it looked (to close a month it has left).
    private var month: String
    private var lastSeen: Date
    private var loop: Task<Void, Never>?

    private init(url: URL, ledger: TessUsageLedger, committed: Int64, month: String, now: Date) {
        self.url = url
        self.ledger = ledger
        self.committed = committed
        self.month = month
        lastSeen = now
    }

    static func monthKey(_ date: Date, calendar: Calendar = .current) -> String {
        let start = TessUsageLedger.monthInterval(containing: date, calendar: calendar).start
        let parts = calendar.dateComponents([.year, .month], from: start)
        return String(format: "%04d-%02d", parts.year ?? 0, parts.month ?? 0)
    }

    /// What the file says the test world has spent this month. No file is none; a file from another month is none; a
    /// file that is there but cannot be read counts as fully spent (it is never trusted to be empty).
    static func spent(at url: URL, month: String) -> Int64 {
        guard FileManager.default.fileExists(atPath: url.path) else { return 0 }
        guard let data = try? Data(contentsOf: url), let entry = try? JSONDecoder().decode(Entry.self, from: data)
        else { return allowanceNano }
        return entry.month == month ? max(0, entry.nano) : 0
    }

    /// What is left of the $20 this month for a store on this file.
    static func remaining(at url: URL, month: String) -> Int64 {
        allowanceNano - spent(at: url, month: month)
    }

    /// Starts a flagged launch's ledger at `capNano - allowance + (what the file already shows)`, as one ledger row, so
    /// the ledger's own cap leaves exactly the rest of the allowance. Nil, and nothing read or written, unless the
    /// store is a stamped test store that is not his.
    static func begin(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef], url: URL = defaultURL,
                      now: Date = .now) -> TestSpendAllowance?
    {
        guard TestStore.allowsClaude(store) else { return nil }
        let ledger = TessUsageLedger(store: store, classes: classes)
        let month = monthKey(now)
        seedRow(ledger, url: url, month: month, now: now)
        let made = TestSpendAllowance(url: url, ledger: ledger, committed: ledger.monthTotal(now: now), month: month,
                                      now: now)
        made.startLoop()
        return made
    }

    /// The ledger row that leaves only the rest of the allowance in the month `now` falls in.
    private static func seedRow(_ ledger: TessUsageLedger, url: URL, month: String, now: Date) {
        let seed = TessUsageLedger.capNano - allowanceNano + spent(at: url, month: month)
        ledger.record(use: .keyCheck, model: "test-world-allowance", input: 0, output: 0, costNano: seed, latency: 0,
                      outcome: "allowance", requestID: nil, at: now)
    }

    /// Adds what this launch spent since the last commit to the file, atomically. Safe to call often. When the ledger
    /// month has turned since the last call (the 04:00 edge), the old month's spend is closed into the file under its
    /// own key and the new month gets a fresh seed row (what the file shows for it, 0 unless another launch spent).
    func commit(now: Date = .now) {
        if Self.monthKey(now) != month {
            roll(now: now)
            return
        }
        write(total: ledger.monthTotal(now: now), now: now)
        lastSeen = now
    }

    private func roll(now: Date) {
        write(total: ledger.monthTotal(now: lastSeen), now: lastSeen)
        month = Self.monthKey(now)
        Self.seedRow(ledger, url: url, month: month, now: now)
        committed = ledger.monthTotal(now: now)
        lastSeen = now
    }

    private func write(total: Int64, now: Date) {
        let delta = total - committed
        guard delta > 0 else { return }
        let month = Self.monthKey(now)
        let entry = Entry(month: month, nano: Self.spent(at: url, month: month) + delta)
        guard let data = try? JSONEncoder().encode(entry) else { return }
        do {
            try data.write(to: url, options: .atomic)
            committed = total
        } catch {
            // Kept in memory; the next commit tries again.
        }
    }

    /// A crash loses at most half a minute of spend.
    private func startLoop() {
        loop = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                self?.commit()
            }
        }
    }

    deinit {
        loop?.cancel()
    }
}
