import Foundation

/// Captures and pastes that ended with nothing written ("Didn't catch that.", a link pasted as a recipe), kept so
/// week one can be read from data (docs/product/kitchen-week-one.md). One JSON line each, beside the database, never
/// in the op log, never in a backup or export, and excluded from the device backup: it never leaves the phone.
public struct CaptureMissLog: Sendable {
    public struct Miss: Codable, Equatable, Sendable {
        /// What was said or pasted, cut to 200 characters.
        public let text: String
        public let at: Date
        /// The last route that tried ("grammar", "model"), or "none".
        public let route: String
        /// Where it came from: "ghost row", "paste".
        public let source: String
    }

    public static let maxText = 200
    /// The newest this many are kept.
    public static let keep = 2000

    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    /// The log beside a store's database; nil for an in-memory store (tests, previews).
    @MainActor
    public static func beside(_ store: ObjectStore) -> CaptureMissLog? {
        store.context.url.map {
            CaptureMissLog(url: $0.deletingLastPathComponent().appendingPathComponent("capture-misses.jsonl"))
        }
    }

    /// Records one miss. Never throws: a log that can't be written is skipped.
    public func record(_ text: String, at date: Date = .now, route: String, source: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // A Claude key never goes in a file (the paste screen too).
        guard !trimmed.isEmpty, !looksLikeClaudeKey(trimmed) else { return }
        let miss = Miss(text: String(trimmed.prefix(Self.maxText)), at: date, route: route, source: source)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard var line = try? encoder.encode(miss) else { return }
        line.append(0x0A)
        let manager = FileManager.default
        if !manager.fileExists(atPath: url.path) {
            try? manager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            manager.createFile(atPath: url.path, contents: nil)
            var excluded = URLResourceValues()
            excluded.isExcludedFromBackup = true
            var target = url
            try? target.setResourceValues(excluded)
        }
        guard let handle = try? FileHandle(forWritingTo: url) else { return }
        defer { try? handle.close() }
        _ = try? handle.seekToEnd()
        try? handle.write(contentsOf: line)
        trimIfNeeded()
    }

    /// Every miss, oldest first.
    public func all() -> [Miss] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return data.split(separator: 0x0A).compactMap { try? decoder.decode(Miss.self, from: Data($0)) }
    }

    private func trimIfNeeded() {
        guard let data = try? Data(contentsOf: url) else { return }
        let lines = data.split(separator: 0x0A)
        guard lines.count > Self.keep + Self.keep / 10 else { return }
        let kept = lines.suffix(Self.keep).map { Data($0) + Data([0x0A]) }.reduce(Data(), +)
        try? kept.write(to: url, options: .atomic)
    }
}
