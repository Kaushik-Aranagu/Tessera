import Foundation

/// How much a memory matters on its own, before the ask (spec M2). A correction he made beats what he told her, which
/// beats a surprise, then what the app noticed, then what a model inferred. Plain records (objects, summaries) sit in
/// the middle.
public enum RecallImportance: String, Sendable, CaseIterable {
    case correction, told, surprise, noticed, record, inferred

    public var weight: Double {
        switch self {
        case .correction: 1.0
        case .told: 0.8
        case .surprise: 0.6
        case .noticed: 0.5
        case .record: 0.5
        case .inferred: 0.3
        }
    }
}

/// One memory that could go in a pack: a belief, a summary, an object, a notebook file, a page.
public struct RecallCandidate: Sendable, Equatable {
    public var path: String
    /// When it was used: cited in a reply, opened, or written. The last 50 are enough.
    public var uses: [Date]
    public var importance: RecallImportance
    /// The belief's own confidence; 1 for objects and summaries.
    public var confidence: Double
    /// A keyword or meaning match for free text (notes, recipe steps), 0...1. Typed things leave it 0: links find them.
    public var fit: Double

    public init(path: String, uses: [Date] = [], importance: RecallImportance = .record, confidence: Double = 1,
                fit: Double = 0)
    {
        self.path = path
        self.uses = uses
        self.importance = importance
        self.confidence = confidence
        self.fit = fit
    }
}

/// The link graph as recall sees it: each path's neighbors (both directions of a link).
public struct RecallGraph: Sendable {
    public var neighbors: [String: [String]]

    public init(neighbors: [String: [String]] = [:]) {
        self.neighbors = neighbors
    }

    /// Adds a link both ways.
    public mutating func link(_ one: String, _ other: String) {
        guard one != other else { return }
        if !(neighbors[one] ?? []).contains(other) { neighbors[one, default: []].append(other) }
        if !(neighbors[other] ?? []).contains(one) { neighbors[other, default: []].append(one) }
    }

    /// Nearness: personalized PageRank from the seeds (the objects in the ask and on screen), limited to `hops` links
    /// out, so the answer is spread over what is actually near (HippoRAG's idea, on the graph we already have). Each
    /// round keeps `restart` at the seeds and passes the rest along the links. Results are scaled so the nearest
    /// path reads 1. Paths farther than `hops` read 0.
    public func nearness(from seeds: [String], hops: Int = 3, restart: Double = 0.5,
                         iterations: Int = 10) -> [String: Double]
    {
        let seedSet = Set(seeds)
        guard !seedSet.isEmpty else { return [:] }

        var reach: Set<String> = seedSet
        var frontier = seedSet
        for _ in 0 ..< hops {
            var next: Set<String> = []
            for path in frontier {
                for neighbor in neighbors[path] ?? [] where !reach.contains(neighbor) {
                    next.insert(neighbor)
                }
            }
            reach.formUnion(next)
            frontier = next
        }

        let start = Dictionary(uniqueKeysWithValues: seedSet.map { ($0, 1 / Double(seedSet.count)) })
        var rank = start
        for _ in 0 ..< iterations {
            var next: [String: Double] = start.mapValues { $0 * restart }
            for (path, value) in rank {
                let out = (neighbors[path] ?? []).filter { reach.contains($0) }
                guard !out.isEmpty else { continue }
                let share = value * (1 - restart) / Double(out.count)
                for neighbor in out {
                    next[neighbor, default: 0] += share
                }
            }
            rank = next
        }
        guard let top = rank.values.max(), top > 0 else { return [:] }
        return rank.mapValues { $0 / top }
    }
}

/// One candidate's score and its parts, for the pack and for Developer mode.
public struct RecallScore: Sendable, Equatable {
    public var path: String
    public var nearness: Double
    public var activation: Double
    public var importance: Double
    public var confidence: Double
    public var fit: Double

    /// Equal weights to start (Generative Agents did the same). The mean keeps the score in 0...1, where the floor
    /// lives.
    public var total: Double {
        (nearness + activation + importance + confidence + fit) / 5
    }
}

/// Ranks memories for one ask (spec M2). A candidate counts only when something ties it to the ask: it is near the
/// seeds in the link graph or its words fit. Then each part is put on 0...1 (nearness by the top path, activation by
/// min-max over the candidates, with never-used things in the middle so a new belief isn't buried; importance,
/// confidence and fit already are) and averaged. Below the floor, it stays
/// out; when nothing clears the floor, the pack says "Nothing kept on this." and Tess says she doesn't know.
public struct Recall: Sendable {
    public var graph: RecallGraph
    public var now: Date

    public init(graph: RecallGraph, now: Date = .now) {
        self.graph = graph
        self.now = now
    }

    /// ACT-R base-level activation: ln of the sum of each use's age in days to the power -0.5. Recent and frequent
    /// uses count most, and old ones fade without ever reaching zero. Nil when it was never used.
    public static func activation(uses: [Date], now: Date) -> Double? {
        guard !uses.isEmpty else { return nil }
        let sum = uses.reduce(0.0) { total, use in
            let days = max(now.timeIntervalSince(use) / 86400, 1.0 / 1440)
            return total + pow(days, -0.5)
        }
        return log(sum)
    }

    /// Scores every related candidate, best first (ties by path, so the order is stable).
    public func rank(_ candidates: [RecallCandidate], seeds: [String]) -> [RecallScore] {
        let near = graph.nearness(from: seeds)
        let related = candidates.filter { (near[$0.path] ?? 0) > 0 || $0.fit > 0 }
        let raw = related.map { Self.activation(uses: $0.uses, now: now) }
        let known = raw.compactMap { $0 }
        let low = known.min() ?? 0, high = known.max() ?? 0

        return zip(related, raw).map { candidate, activation in
            let scaled: Double = if let activation {
                high > low ? (activation - low) / (high - low) : 0.5
            } else {
                0.5
            }
            return RecallScore(path: candidate.path, nearness: near[candidate.path] ?? 0, activation: scaled,
                               importance: candidate.importance.weight,
                               confidence: min(max(candidate.confidence, 0), 1), fit: min(max(candidate.fit, 0), 1))
        }
        .sorted { $0.total != $1.total ? $0.total > $1.total : $0.path < $1.path }
    }

    /// The candidates as pack items, ready for the packer's recall section (which applies the floor).
    public func items(_ candidates: [RecallCandidate], seeds: [String], text: (String) -> String) -> [ContextItem] {
        rank(candidates, seeds: seeds).map { ContextItem(path: $0.path, text: text($0.path), score: $0.total) }
    }
}
