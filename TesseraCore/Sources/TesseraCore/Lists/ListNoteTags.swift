import Foundation

/// Small flags that live on a list's or an item's existing `notes` line (the catalog is frozen at v9, so no new
/// field): a whole line such as `#reusable` is a flag, a line such as `picked: 2026-10-17T18:00:00Z` is a stamp.
/// Every other line of the notes is left exactly as it was.
enum ListNoteTags {
    static let reusable = "#reusable"
    static let pickOne = "#pick-one"
    static let pickedPrefix = "picked: "

    @MainActor static func isReusable(_ list: ObjectRecord, in store: ObjectStore) -> Bool {
        has(reusable, in: store.value("notes", of: list)?.stringValue)
    }

    static func lines(_ text: String?) -> [String] {
        (text ?? "").split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
    }

    static func has(_ tag: String, in text: String?) -> Bool {
        // Exact whole lines only (Product 9:45 AM PT, ruling 1): " #reusable" or "#reusable!" is his note.
        lines(text).contains { $0 == tag }
    }

    /// `text` with the flag line added or removed; nil when nothing is left.
    static func setting(_ tag: String, to isOn: Bool, in text: String?) -> String? {
        var kept = lines(text).filter { $0 != tag }
        if isOn {
            kept.append(tag)
        }
        return kept.isEmpty ? nil : kept.joined(separator: "\n")
    }

    /// The date after a `prefix` line, if there is one.
    static func stamp(_ prefix: String, in text: String?) -> Date? {
        guard let line = lines(text).last(where: { $0.hasPrefix(prefix) }) else { return nil }
        return try? Date(String(line.dropFirst(prefix.count)), strategy: .iso8601)
    }

    /// `text` with the `prefix` line set to `date` (or dropped for nil); nil when nothing is left.
    static func setting(stamp prefix: String, to date: Date?, in text: String?) -> String? {
        var kept = lines(text).filter { !$0.hasPrefix(prefix) }
        if let date {
            kept.append(prefix + date.formatted(.iso8601))
        }
        return kept.isEmpty ? nil : kept.joined(separator: "\n")
    }
}
