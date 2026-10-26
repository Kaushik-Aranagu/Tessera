import Foundation

/// One thing that can go in a pack: a rule block, a belief, a summary, an object's text, a turn. `path` is its address
/// (`/training/exercises/bench-press`), shown to the model so it can open more; it is never a UUID. Rules have none.
/// A private object's path and text use its shown label ("Private workout"), never its walled title: the caller
/// builds items through the walls (`ObjectPrivacy`) before they reach the packer.
public struct ContextItem: Sendable, Equatable {
    public var path: String
    public var text: String
    /// The recall score (spec M2) for recall items. Other sections keep the order they are given in.
    public var score: Double
    /// When it happened, for episodic items: overflow drops the oldest first.
    public var at: Date?

    public init(path: String = "", text: String, score: Double = 1, at: Date? = nil) {
        self.path = path
        self.text = text
        self.score = score
        self.at = at
    }

    var rendered: String {
        path.isEmpty ? text : "\(path)\n\(text)"
    }
}

/// What the packer built: the blocks in send order, where the cache marks go, and what it took, for the meter.
public struct ContextPack: Sendable, Equatable {
    public struct Block: Sendable, Equatable {
        public var section: ContextSection
        public var text: String
    }

    public var blocks: [Block]
    public var cacheMarks: [CacheMark]
    public var sectionTokens: [ContextSection: Int]
    /// The paths of everything that made it in, by section.
    public var included: [ContextSection: [String]]
    /// What overflow left out (lowest-scoring recall first, then the oldest episodic items).
    public var dropped: [String]
    /// Recall was asked and nothing scored above the floor: the pack says so, and Tess says she doesn't know.
    public var nothingKept: Bool
    /// The input, tool definitions included.
    public var inputTokens: Int
    /// Room left under the ceiling for what the agent fetches during the run.
    public var growthTokens: Int
    public var outputTokens: Int

    public func block(_ section: ContextSection) -> String? {
        blocks.first { $0.section == section }?.text
    }
}

/// Lays out one call from memory (spec M3). Pure: the same items and row always give the same bytes, so the prefix
/// caches and a pack can be hashed.
///
/// Wiring (H3 and M4): each block becomes a `PackFragment`, tagged `deviceOnly` when any of its items comes from a
/// money, health, body, calorie or calendar object, so strict policy drops that block instead of refusing the call.
///
/// - Every section takes all of its content. Recall takes every candidate at or above the floor, best first.
/// - Nothing is cut for cost. Only when the input would pass the ceiling (700K, so growth and the answer always fit in
///   the 1M window) does overflow trim: recall's lowest scores down to recall's start, then episodic's oldest down to
///   episodic's start, then recall and episodic below their starts. Rules, expertise, core and working are never
///   trimmed. A trimmed recall section ends with "More is kept; open to see it."
public struct ContextPacker: Sendable {
    public static let inputCeiling = 700_000
    public static let nothingKeptLine = "Nothing kept on this"
    public static let moreKeptLine = "More is kept; open to see it"

    public var row: BudgetRow
    public var ratio: TokenRatio
    public var ceiling: Int

    public init(row: BudgetRow, ratio: TokenRatio = TokenRatio(), ceiling: Int = ContextPacker.inputCeiling) {
        self.row = row
        self.ratio = ratio
        self.ceiling = ceiling
    }

    /// `items` holds each section's candidates. Leave `.recall` out when the call doesn't recall; give it an empty
    /// list when recall ran and found nothing. `toolTokens` is the size of the tool definitions sent with the call.
    public func pack(_ items: [ContextSection: [ContextItem]], toolTokens: Int = 0) -> ContextPack {
        var chosen: [ContextSection: [ContextItem]] = [:]
        for section in ContextSection.allCases {
            guard let list = items[section] else { continue }
            switch section {
            case .recall:
                chosen[section] = list.filter { $0.score >= row.recallFloor }
                    .sorted { $0.score != $1.score ? $0.score > $1.score : $0.path < $1.path }
            case .episodic:
                chosen[section] = list.enumerated().sorted { lhs, rhs in
                    let left = lhs.element.at ?? .distantPast, right = rhs.element.at ?? .distantPast
                    return left != right ? left < right : lhs.offset < rhs.offset
                }.map(\.element)
            default:
                chosen[section] = list
            }
        }

        func tokens(_ section: ContextSection) -> Int {
            (chosen[section] ?? []).reduce(0) { $0 + ratio.tokens($1.rendered, in: section) }
        }
        var total = toolTokens + ContextSection.allCases.reduce(0) { $0 + tokens($1) }
        var dropped: [String] = []

        // Overflow, in the order the type comment gives. Recall loses its last (lowest) item, episodic its first
        // (oldest).
        let steps: [(ContextSection, Bool)] = [(.recall, true), (.episodic, true), (.recall, false), (.episodic, false)]
        for (section, keepStart) in steps {
            while total > ceiling, var list = chosen[section], !list.isEmpty {
                let current = tokens(section)
                if keepStart, current <= row.start(section) {
                    break
                }
                let item = section == .recall ? list.removeLast() : list.removeFirst()
                let size = ratio.tokens(item.rendered, in: section)
                if keepStart, current - size < row.start(section) {
                    break
                }
                chosen[section] = list
                total -= size
                dropped.append(item.path)
            }
        }

        let recallAsked = items[.recall] != nil
        let nothingKept = recallAsked && (items[.recall] ?? []).allSatisfy { $0.score < row.recallFloor }
        let recallTrimmed = dropped.contains { path in (items[.recall] ?? []).contains { $0.path == path } }

        var blocks: [ContextPack.Block] = []
        var sectionTokens: [ContextSection: Int] = [:]
        var included: [ContextSection: [String]] = [:]
        for section in ContextSection.allCases {
            let list = chosen[section] ?? []
            var parts = list.map(\.rendered)
            if section == .recall, nothingKept {
                parts = [Self.nothingKeptLine]
            }
            if section == .recall, recallTrimmed {
                parts.append(Self.moreKeptLine)
            }
            guard !parts.isEmpty else { continue }
            let text = parts.joined(separator: "\n\n")
            blocks.append(.init(section: section, text: text))
            sectionTokens[section] = ratio.tokens(text, in: section)
            included[section] = list.map(\.path).filter { !$0.isEmpty }
        }

        let input = toolTokens + sectionTokens.values.reduce(0, +)
        return ContextPack(
            blocks: blocks,
            cacheMarks: Self.marks(for: blocks),
            sectionTokens: sectionTokens,
            included: included,
            dropped: dropped,
            nothingKept: nothingKept,
            inputTokens: input,
            growthTokens: max(0, ceiling - input),
            outputTokens: row.outputTokens
        )
    }

    /// Breakpoints after the last 1-hour block (expertise, then core) and after recall (5 minutes). The tail of the
    /// messages is cached automatically by the request builder. Longer TTLs come first, as the API requires.
    static func marks(for blocks: [ContextPack.Block]) -> [CacheMark] {
        func index(_ section: ContextSection) -> Int? {
            blocks.firstIndex { $0.section == section }
        }
        var marks: [CacheMark] = []
        if let stable = index(.expertise) ?? index(.rules) {
            marks.append(CacheMark(stable, .oneHour))
        }
        if let core = index(.core) {
            marks.append(CacheMark(core, .oneHour))
        }
        if let recall = index(.recall) {
            marks.append(CacheMark(recall, .fiveMinutes))
        }
        return marks
    }
}
