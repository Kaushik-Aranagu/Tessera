import Foundation

/// Learned weights and confidence for the memory pyramid (P3b, docs/ai/harness/memory-pyramid.md; "Learned weights"
/// in the design doc). Each child of the node being read is scored by weights on (ask word, child feature) pairs;
/// a softmax over the children says how strongly each fires. The features are the child's title words, its recency
/// rank among its siblings (per level, so "newest month" and "newest day" are learned apart) and its level. Asks
/// come in as `PyramidAsk.terms`: dates resolved, stop words gone. "same" (an ask word that is also a title word)
/// starts at 1, so before any learning it routes by words alone; every other pair starts at 0.
///
/// The backward pass is hindsight: an answer that cites a node gives the true path to it, and one cross-entropy step
/// trains the weights along that path (real gradients on a linear model). Only the residual is learned: a step the
/// words-only route already gets right and sure trains nothing, so early updates can't move weights that didn't need
/// moving. Confidence is two counts per node, right and wrong, updated online after every checked answer.
///
/// Walls: under strict only nodes with a claude-safe leaf are options, and a cite through a node strict can't see
/// trains nothing, so no weight is learned from a walled read. The router never hides a node from a plain search:
/// weights rank, they don't remove. It lives on the phone and never goes in a pack.
public struct PyramidRouter: Codable, Sendable, Equatable {
    /// Ranks past this read as this: "6 or more back".
    public static let maxRank = 6
    /// The most pairs kept; past it the ones nearest their start go first.
    public static let maxPairs = 20000

    public struct Counts: Codable, Sendable, Equatable {
        public var right = 0
        public var wrong = 0
    }

    /// A child as the router sees it.
    public struct Option: Sendable, Equatable {
        public var path: String
        public var features: [String]
    }

    /// One step of a walk: the child taken and how strongly it fired.
    public struct Step: Sendable, Equatable {
        public var path: String
        public var probability: Double
    }

    public private(set) var weights: [String: Double] = [:]
    public private(set) var counts: [String: Counts] = [:]
    /// The learning rate: one cross-entropy step's size.
    public var rate: Double
    /// How sure every step of a guess must be to open its end directly instead of walking.
    public var sure: Double

    public init(rate: Double = 0.1, sure: Double = 0.9) {
        self.rate = rate
        self.sure = sure
    }

    // MARK: Firing

    /// A node's children the policy can see, newest first, with their features.
    public static func options(of path: String, in pyramid: MemoryPyramid, policy: DoorPolicy) -> [Option] {
        guard let node = pyramid.nodes[path] else { return [] }
        let kids = node.children.compactMap { pyramid.nodes[$0] }
            .filter { policy == .lab || $0.safeLeaves > 0 }
            .sorted { $0.path > $1.path }
        return kids.enumerated().map { rank, kid in
            Option(path: kid.path, features: PyramidAsk.words(kid.title)
                + ["rank\(min(rank, maxRank))@\(kid.level.rawValue)", "level:\(kid.level.rawValue)"])
        }
    }

    static func pairs(_ ask: [String], _ features: [String]) -> [String] {
        ask.flatMap { word in features.map { word == $0 ? "same" : "\(word)|\($0)" } }
    }

    static func start(_ pair: String) -> Double {
        pair == "same" ? 1 : 0
    }

    func score(_ ask: [String], _ features: [String]) -> Double {
        Self.pairs(ask, features).reduce(0) { $0 + (weights[$1] ?? Self.start($1)) }
    }

    /// How strongly each option fires for the ask: a softmax over their scores.
    public func probabilities(_ ask: [String], _ options: [Option]) -> [Double] {
        let scores = options.map { score(ask, $0.features) }
        guard let top = scores.max() else { return [] }
        let exps = scores.map { exp($0 - top) }
        let total = exps.reduce(0, +)
        return exps.map { $0 / total }
    }

    /// The children of a node, the one that fires most first; on a tie the newest first.
    public func ranked(_ ask: [String], at path: String, in pyramid: MemoryPyramid, policy: DoorPolicy) -> [Step] {
        let options = Self.options(of: path, in: pyramid, policy: policy)
        return zip(options, probabilities(ask, options)).map { Step(path: $0.path, probability: $1) }
            .sorted { ($0.probability, $0.path) > ($1.probability, $1.path) }
    }

    /// The path the router would take from the root down to `level`, greedily, with how strongly each step fired.
    public func guess(_ ask: [String], to level: PyramidNode.Level, in pyramid: MemoryPyramid,
                      policy: DoorPolicy) -> [Step]
    {
        var steps: [Step] = []
        var path = MemoryPyramid.root
        while pyramid.nodes[path]?.level != level {
            guard let best = ranked(ask, at: path, in: pyramid, policy: policy).first else { break }
            steps.append(best)
            path = best.path
        }
        return pyramid.nodes[path]?.level == level ? steps : []
    }

    /// Whether every step of a guess fired at least `sure`: the reader may open its end directly. A wrong jump costs
    /// one open, never a wrong answer, because the walk still runs.
    public func isSure(_ steps: [Step]) -> Bool {
        !steps.isEmpty && steps.allSatisfy { $0.probability >= sure }
    }

    // MARK: Learning

    /// The nodes from the root's child down to `path`: the true path to a cited node.
    public static func truePath(to path: String) -> [String] {
        guard path.hasPrefix(MemoryPyramid.root + "/") else { return [] }
        let parts = path.dropFirst(MemoryPyramid.root.count + 1).split(separator: "/")
        return parts.indices.map { MemoryPyramid.root + "/" + parts[...$0].joined(separator: "/") }
    }

    /// The backward pass for one answer that cited `cited`: one cross-entropy step at each node along the true path
    /// where the words-only route was wrong or the router wasn't sure. Returns the steps trained. A cite strict can't
    /// see, or one off the tree, trains nothing.
    @discardableResult
    public mutating func learn(_ ask: [String], cited: String, in pyramid: MemoryPyramid, policy: DoorPolicy) -> Int {
        let path = Self.truePath(to: cited)
        var node = MemoryPyramid.root
        var steps: [(options: [Option], target: Int)] = []
        for step in path {
            let options = Self.options(of: node, in: pyramid, policy: policy)
            guard let target = options.firstIndex(where: { $0.path == step }) else { return 0 }
            steps.append((options, target))
            node = step
        }
        let wordsOnly = PyramidRouter(rate: rate, sure: sure)
        var trained = 0
        for (options, target) in steps where options.count > 1 {
            let prior = wordsOnly.probabilities(ask, options)
            let now = probabilities(ask, options)
            let priorRight = prior.indices.max { prior[$0] < prior[$1] } == target
            guard !priorRight || now[target] < sure else { continue }
            for (index, option) in options.enumerated() {
                let gradient = now[index] - (index == target ? 1 : 0)
                for pair in Self.pairs(ask, option.features) {
                    weights[pair] = (weights[pair] ?? Self.start(pair)) - rate * gradient
                }
            }
            trained += 1
        }
        if weights.count > Self.maxPairs {
            prune(to: Self.maxPairs)
        }
        return trained
    }

    /// One checked answer read from a node: right or wrong.
    public mutating func record(_ path: String, right: Bool) {
        if right {
            counts[path, default: Counts()].right += 1
        } else {
            counts[path, default: Counts()].wrong += 1
        }
    }

    /// How often reading this node alone gave a right answer, with one of each added so a new node reads 0.5.
    public func confidence(_ path: String) -> Double {
        let count = counts[path] ?? Counts()
        return Double(count.right + 1) / Double(count.right + count.wrong + 2)
    }

    // MARK: Night

    /// The night's upkeep: a weight tied to a year ("nov|2025") fades a little, because what "Nov" means moves every
    /// January; counts of nodes no longer in the pyramid go; and the pairs are kept under the cap.
    public mutating func night(in pyramid: MemoryPyramid, yearDecay: Double = 0.98, cap: Int = PyramidRouter.maxPairs) {
        for (pair, weight) in weights where Self.isYearPair(pair) {
            weights[pair] = weight * yearDecay
        }
        counts = counts.filter { pyramid.nodes[$0.key] != nil }
        if weights.count > cap {
            prune(to: cap)
        }
    }

    /// A pair whose feature is a year ("nov|2025").
    static func isYearPair(_ pair: String) -> Bool {
        guard let feature = pair.split(separator: "|").last, pair.contains("|") else { return false }
        return feature.count == 4 && Int(feature) != nil
    }

    /// Keeps the `cap` pairs that moved furthest from where they started.
    mutating func prune(to cap: Int) {
        func moved(_ entry: (key: String, value: Double)) -> Double {
            abs(entry.value - Self.start(entry.key))
        }
        let kept = weights.sorted { (moved($0), $1.key) > (moved($1), $0.key) }.prefix(cap)
        weights = Dictionary(uniqueKeysWithValues: kept.map { ($0.key, $0.value) })
    }
}
