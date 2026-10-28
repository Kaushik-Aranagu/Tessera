import Foundation
import Testing

/// The live runners' one ledger of what they spent on Claude this month (the live runner and the pyramid score):
/// `~/Library/Application Support/TessEval/ledger.json`, not in the repo and not in the app's data. Every write takes
/// `ledger.json.lock` and adds only the positive difference to whatever the file holds, so two runners can never
/// overwrite each other's rows on his money.
enum TessEvalLedger {
    static var url: URL {
        let folder = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/TessEval", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("ledger.json")
    }

    static func read(_ url: URL = TessEvalLedger.url) -> [String: Int64] {
        (try? JSONDecoder().decode([String: Int64].self, from: Data(contentsOf: url))) ?? [:]
    }

    /// Adds what this run has spent beyond what it already recorded, under the lock. Returns the new recorded figure.
    static func add(_ url: URL = TessEvalLedger.url, month: String, spent: Int64, recorded: Int64) throws -> Int64 {
        let delta = max(0, spent - recorded)
        guard delta > 0 else { return recorded }
        let descriptor = open(url.appendingPathExtension("lock").path, O_CREAT | O_RDWR, 0o600)
        guard descriptor >= 0 else { throw CocoaError(.fileWriteUnknown) }
        defer { close(descriptor) }
        guard flock(descriptor, LOCK_EX) == 0 else { throw CocoaError(.fileWriteUnknown) }
        defer { flock(descriptor, LOCK_UN) }
        var months = read(url)
        months[month, default: 0] += delta
        try JSONEncoder().encode(months).write(to: url, options: .atomic)
        return recorded + delta
    }
}

struct TessEvalLedgerTests {
    @Test func theLedgerOnlyEverGainsTheDifferenceAndNeverOverwritesAnotherRunner() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ledger-\(UUID().uuidString).json")
        defer {
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.removeItem(at: url.appendingPathExtension("lock"))
        }
        var mine = try TessEvalLedger.add(url, month: "2026-10", spent: 100, recorded: 0)
        // Another runner adds its own row in between.
        _ = try TessEvalLedger.add(url, month: "2026-10", spent: 40, recorded: 0)
        mine = try TessEvalLedger.add(url, month: "2026-10", spent: 250, recorded: mine)
        // Nothing new adds nothing, and a lower figure never subtracts.
        mine = try TessEvalLedger.add(url, month: "2026-10", spent: 250, recorded: mine)
        _ = try TessEvalLedger.add(url, month: "2026-10", spent: 10, recorded: mine)
        let months = TessEvalLedger.read(url)
        #expect(months == ["2026-10": 290])
    }
}
