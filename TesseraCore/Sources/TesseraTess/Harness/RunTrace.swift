import Foundation

/// One span per brain call and per tool call (harness H1a). A span is numbers and names only: never a request, a
/// header, a prompt, a reply or any part of the key. Kept on the phone in Application Support (harness-trace.json, the
/// last 2,000 spans), excluded from backups, never sent.
public struct TraceSpan: Codable, Sendable, Equatable {
    public enum Kind: String, Codable, Sendable {
        case brain, tool
    }

    public var kind: Kind
    /// The job ("tess-turn", "latency-bench") or tool name. A fixed name, never his words.
    public var name: String
    public var brain: String?
    public var model: String?
    public var at: Date
    public var ttftMs: Int?
    public var totalMs: Int
    public var inTokens: Int
    public var outTokens: Int
    public var cacheReadTokens: Int
    public var cacheWriteTokens: Int
    public var costNano: Int64
    public var outcome: String

    public init(kind: Kind, name: String, brain: String? = nil, model: String? = nil, at: Date = .now,
                ttftMs: Int? = nil, totalMs: Int, usage: BrainUsage = BrainUsage(), outcome: String)
    {
        self.kind = kind
        self.name = name
        self.brain = brain
        self.model = model
        self.at = at
        self.ttftMs = ttftMs
        self.totalMs = totalMs
        inTokens = usage.inTokens
        outTokens = usage.outTokens
        cacheReadTokens = usage.cacheReadTokens
        cacheWriteTokens = usage.cacheWriteTokens
        costNano = usage.costNano
        self.outcome = outcome
    }
}

public actor RunTrace {
    public static let limit = 2000
    public static let fileName = "harness-trace.json"

    private let url: URL?
    private var spans: [TraceSpan]
    /// The latency bench's table, kept beside the spans: plain text for Developer mode.
    private var benchTable: String?

    private struct File: Codable {
        var spans: [TraceSpan]
        var benchTable: String?
    }

    /// `Application Support/Tessera/harness-trace.json`, or nil for an in-memory trace (tests).
    public static var defaultURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appending(path: "Tessera/\(fileName)")
    }

    public init(url: URL? = RunTrace.defaultURL) {
        self.url = url
        if let url, let data = try? Data(contentsOf: url), let file = try? JSONDecoder().decode(File.self, from: data) {
            spans = file.spans
            benchTable = file.benchTable
        } else {
            spans = []
        }
    }

    public func record(_ span: TraceSpan) {
        spans.append(span)
        if spans.count > Self.limit {
            spans.removeFirst(spans.count - Self.limit)
        }
        save()
    }

    public func all() -> [TraceSpan] {
        spans
    }

    public func setBenchTable(_ table: String) {
        benchTable = table
        save()
    }

    public func bench() -> String? {
        benchTable
    }

    public func clear() {
        spans = []
        benchTable = nil
        save()
    }

    private func save() {
        guard let url, let data = try? JSONEncoder().encode(File(spans: spans, benchTable: benchTable)) else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        #if os(iOS)
            try? data.write(to: url, options: [.atomic, .completeFileProtection])
        #else
            try? data.write(to: url, options: [.atomic])
        #endif
        var excluded = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? excluded.setResourceValues(values)
    }
}
