import Foundation
import TesseraCore

/// The month's spend, kept outside the store (G654): one small file beside it, excluded from backup. A restore, a
/// reset or a reinstall-and-restore brings the Tess Call rows back to an older state, but never this file, so the
/// $50 cap cannot be spent twice. The ledger counts the higher of the two totals. Money only: no phrase, no key.
struct TessSpendFile {
    static let fileName = "claude-spend.json"

    private struct Entry: Codable {
        var month: String
        var nano: Int64
    }

    let url: URL

    /// Beside the database file; nil for an in-memory store.
    @MainActor
    init?(store: ObjectStore) {
        guard let database = store.context.url else { return nil }
        url = database.deletingLastPathComponent().appendingPathComponent(Self.fileName)
    }

    /// "2026-10": the ledger's month a date falls in (the month turns at 4 AM, like the cap), so the file and the
    /// rows always agree on which month a call belongs to.
    static func monthKey(_ date: Date, calendar: Calendar) -> String {
        let start = TessUsageLedger.monthInterval(containing: date, calendar: calendar).start
        let parts = calendar.dateComponents([.year, .month], from: start)
        return String(format: "%04d-%02d", parts.year ?? 0, parts.month ?? 0)
    }

    private func read() -> Entry? {
        (try? Data(contentsOf: url)).flatMap { try? JSONDecoder().decode(Entry.self, from: $0) }
    }

    /// What this file holds for `month`, or 0 (a file from another month holds nothing for this one).
    func total(month: String) -> Int64 {
        guard let entry = read(), entry.month == month else { return 0 }
        return entry.nano
    }

    /// Adds a call's cost to the month, starting the month's count when the file is from an earlier one.
    func add(_ nano: Int64, month: String) {
        guard nano > 0 else { return }
        let held = total(month: month)
        let entry = Entry(month: month, nano: held + nano)
        guard let data = try? JSONEncoder().encode(entry) else { return }
        try? data.write(to: url, options: .atomic)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var excluded = url
        try? excluded.setResourceValues(values)
    }
}
