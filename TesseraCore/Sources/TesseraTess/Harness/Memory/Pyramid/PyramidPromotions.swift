import Foundation

/// A fact the engine computes exactly for any node above a day: what a reader would otherwise open every day under it
/// to find (P3, docs/ai/harness/memory-pyramid.md). A promoted line is one of these, never a model's words.
public enum PyramidFact: Hashable, Sendable {
    /// The day under the node with the most of a total (a `PyramidStats` key, "sets"), when one day alone has it.
    case busiest(String)
    /// The leaf words of a kind seen most often under the node ("workout": "Push Day"), when one alone leads.
    case top(String)
    /// The newest leaf of a kind under the node.
    case last(String)

    /// How it is stored: "busiest:sets", "top:workout", "last:cook".
    public var key: String {
        switch self {
        case let .busiest(stat): "busiest:\(stat)"
        case let .top(kind): "top:\(kind)"
        case let .last(kind): "last:\(kind)"
        }
    }

    /// The fact a stored key names, or nil. Its name must be a short run of letters (a stat key or a leaf kind), so
    /// words someone typed can never be stored as one.
    public init?(key: String) {
        let parts = key.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2, let name = parts.last, Self.isName(name) else { return nil }
        switch parts[0] {
        case "busiest": self = .busiest(name)
        case "top": self = .top(name)
        case "last": self = .last(name)
        default: return nil
        }
    }

    var name: String {
        switch self {
        case let .busiest(name), let .top(name), let .last(name): name
        }
    }

    static func isName(_ name: String) -> Bool {
        (1 ... 24).contains(name.count) && name.allSatisfy { $0.isASCII && $0.isLetter }
    }
}

public extension MemoryPyramid {
    /// Every day under a node, oldest first.
    func days(under path: String) -> [PyramidNode] {
        guard let node = nodes[path] else { return [] }
        switch node.level {
        case .day: return [node]
        case .leaf: return []
        default: return node.children.sorted().flatMap { days(under: $0) }
        }
    }

    /// A fact's line at a node, computed from the leaves the policy can see, or nil when the fact has no single
    /// answer there. A day lists its leaves already, so a day or a leaf has none. Under strict a walled leaf is not
    /// there at all, so the line reads as if it had never happened; under lab a line that read a walled leaf is
    /// `deviceOnly`.
    func factLine(_ fact: PyramidFact, at path: String, policy: DoorPolicy) -> PyramidLine? {
        guard let node = nodes[path], node.level != .day, node.level != .leaf else { return nil }
        let seen = days(under: path).map { day in
            (day: day, leaves: day.children.compactMap { nodes[$0] }.filter { leaf in
                policy == .lab || leaf.text?.taint == .claudeSafe
            })
        }.filter { !$0.leaves.isEmpty }
        func taint(_ leaves: [PyramidNode]) -> Taint {
            leaves.allSatisfy { $0.text?.taint == .claudeSafe } ? .claudeSafe : .deviceOnly
        }
        switch fact {
        case let .busiest(key):
            guard let shown = PyramidStats.shown.first(where: { $0.key == key }),
                  policy == .lab || shown.taint == .claudeSafe else { return nil }
            let values = seen.compactMap { entry -> (day: PyramidNode, value: Double, read: [PyramidNode])? in
                let counted = entry.leaves.filter { !$0.stats.isEmpty }
                var stats: [String: Double] = [:]
                for leaf in counted {
                    stats.merge(leaf.stats, uniquingKeysWith: +)
                }
                return shown.value(stats).map { (entry.day, $0, counted) }
            }
            guard let best = values.map(\.value).max(), values.count(where: { $0.value == best }) == 1,
                  let top = values.first(where: { $0.value == best }) else { return nil }
            let read = values.flatMap(\.read)
            return PyramidLine(
                text: "Day with the most \(shown.label): \(top.day.title) (\(top.day.path)), "
                    + PyramidStats.format(best),
                taint: shown.taint == .deviceOnly ? .deviceOnly : taint(read)
            )
        case let .top(kind):
            let leaves = seen.flatMap(\.leaves).filter { $0.title == kind }
            var counts: [String: Int] = [:]
            // A private thing's label says nothing about which one it was, so it never leads.
            for case let text? in leaves.map(\.text?.text) where !text.hasPrefix("Private ") {
                counts[String(text.prefix(80)), default: 0] += 1
            }
            guard let best = counts.values.max(), best >= 2, counts.values.count(where: { $0 == best }) == 1,
                  let name = counts.first(where: { $0.value == best })?.key else { return nil }
            return PyramidLine(text: "Most often \(kind): \(name), \(best) times", taint: taint(leaves))
        case let .last(kind):
            for (day, leaves) in seen.reversed() {
                guard let line = leaves.last(where: { $0.title == kind })?.text else { continue }
                return PyramidLine(text: "Last \(kind): \(line.text.prefix(80)), \(day.title) (\(day.path))",
                                   taint: line.taint)
            }
            return nil
        }
    }
}

/// Which facts each level shows, learned from what readers had to dig for (P3, the "shared" arm of
/// scripts/ai/pyramid_sim.py, which cut opens per ask from about 10 to 1). `k` digs for a fact at a level put it on
/// every node of that level, each node's line computed exactly by `factLine`. A fact nobody used for `forgetDays`
/// goes, and each level keeps at most `budget`, freshest first. It holds fact keys and level names only, never a
/// word of an ask or a leaf.
public struct PyramidPromotions: Codable, Sendable, Equatable {
    /// The levels that show promoted lines. A day lists its leaves already.
    public static let levels: [PyramidNode.Level] = [.week, .month, .year, .root]
    /// The most facts a level keeps counting digs for.
    public static let maxCounted = 32

    public var k: Int
    public var budget: Int
    public var forgetDays: Int
    /// Digs since each fact was last promoted, by level then fact key.
    public private(set) var digs: [String: [String: Int]] = [:]
    /// The facts each level shows, with when each was last used.
    public private(set) var shown: [String: [String: Date]] = [:]

    public init(k: Int = 3, budget: Int = 3, forgetDays: Int = 30) {
        self.k = k
        self.budget = budget
        self.forgetDays = forgetDays
    }

    /// The facts a level shows, the most recently used first.
    public func facts(at level: PyramidNode.Level) -> [PyramidFact] {
        (shown[level.rawValue] ?? [:]).sorted { ($0.value, $1.key) > ($1.value, $0.key) }
            .compactMap { PyramidFact(key: $0.key) }
    }

    /// A reader had to open below a node of `level` to find `fact`. Returns true when this dig promoted it. A fact
    /// already shown there had no single answer at that node, so its dig counts for nothing.
    @discardableResult
    public mutating func dug(_ fact: PyramidFact, at level: PyramidNode.Level, now: Date) -> Bool {
        let key = fact.key
        guard Self.levels.contains(level), PyramidFact(key: key) == fact, shown[level.rawValue]?[key] == nil
        else { return false }
        var counted = digs[level.rawValue] ?? [:]
        let count = (counted[key] ?? 0) + 1
        if count >= k {
            counted[key] = nil
            shown[level.rawValue, default: [:]][key] = now
        } else {
            counted[key] = count
            // Past the cap the facts dug least go first.
            while counted.count > Self.maxCounted,
                  let least = counted.min(by: { ($0.value, $1.key) < ($1.value, $0.key) })?.key
            {
                counted[least] = nil
            }
        }
        digs[level.rawValue] = counted.isEmpty ? nil : counted
        return count >= k
    }

    /// A shown line answered an ask: it stays.
    public mutating func used(_ fact: PyramidFact, at level: PyramidNode.Level, now: Date) {
        guard shown[level.rawValue]?[fact.key] != nil else { return }
        shown[level.rawValue]?[fact.key] = now
    }

    /// The night: a line unused for `forgetDays` goes, then each level keeps its `budget`, freshest first. Returns
    /// what went, as "level/fact key".
    @discardableResult
    public mutating func night(now: Date) -> [String] {
        var dropped: [String] = []
        for (level, facts) in shown {
            let fresh = facts.filter { now.timeIntervalSince($0.value) < Double(forgetDays) * 86400 }
            let kept = fresh.sorted { ($0.value, $1.key) > ($1.value, $0.key) }.prefix(max(0, budget))
            let keep = Dictionary(uniqueKeysWithValues: kept.map { ($0.key, $0.value) })
            dropped += facts.keys.filter { keep[$0] == nil }.map { "\(level)/\($0)" }
            shown[level] = keep.isEmpty ? nil : keep
        }
        return dropped.sorted()
    }
}
