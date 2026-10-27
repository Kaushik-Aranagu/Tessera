import Foundation

/// The words of the leaves a topic tree may see, and in how many leaves each word appears. Built fresh from the
/// leaves each time: the tree itself stores leaf ids only, never a word (docs/ai/harness/memory-pyramid.md, P4).
public struct TopicWords: Sendable {
    public let of: [String: Set<String>]
    public let df: [String: Int]

    /// The words of each leaf the policy can see: lowercased, less the stop words, with at least one letter and two
    /// characters. Under strict a walled leaf is not there at all.
    public init(_ leaves: [PyramidLeaf], policy: DoorPolicy) {
        var of: [String: Set<String>] = [:]
        var df: [String: Int] = [:]
        for leaf in leaves where policy == .lab || leaf.taint == .claudeSafe {
            let words = Set(PyramidAsk.words(leaf.text).filter { word in
                word.count >= 2 && word.contains(where: \.isLetter) && !PyramidAsk.stopWords.contains(word)
            })
            of[leaf.id] = words
            for word in words {
                df[word, default: 0] += 1
            }
        }
        self.of = of
        self.df = df
    }

    func words(_ leaf: String) -> Set<String> {
        of[leaf] ?? []
    }
}

/// A topic axis for free-text leaves (things he told Tess, notes, turns, pages), which have no date to be filed by
/// (P4, docs/ai/harness/memory-pyramid.md; simulated in scripts/ai/pyramid_topic_sim.py). The tree grows its own shape:
///
/// - A new leaf goes down to the node whose key it shares most words with. A key is the words that set a node's
///   leaves apart, counted exactly from them each time it is read.
/// - **Split**: a node past `splitAt` children splits in two by 2-means over its children's words.
/// - **Merge**: two sibling holders the same asks keep using, or whose keys converge, merge when together they hold at
///   most `mergeAt`, never more than half of `splitAt` (hysteresis: a merge can't set off the next split).
/// - **Collapse**: a node left with one child goes, and the child takes its place.
/// - **Settle**: up to `settlePerNight` leaves move to the holder they fit at least one word better.
/// - At most `changesPerNight` splits, merges and collapses a night, and every change is logged.
/// - **Prune**: first each night, a leaf the tree may no longer see goes, and so does a holder it leaves empty. This
///   is the walls, not the shape, so it has no cap.
///
/// Finding is exact: `find` opens every child that holds a matching leaf, best first, so the tree ranks and never
/// hides (in the simulation a reader that trusted shown keys lost half the recall). Walls: each policy keeps its own
/// tree, built from the leaves it may see, so the strict tree reads exactly as if the walled leaves never happened.
/// It stores node ids and leaf ids only; no word of a leaf is in it.
public struct TopicTree: Codable, Sendable, Equatable {
    public static let root = "/topics"

    public struct Node: Codable, Sendable, Equatable {
        public var id: String
        public var parent: String?
        public var children: [String] = []
        public var leaves: [String] = []

        var size: Int {
            leaves.isEmpty ? children.count : leaves.count
        }
    }

    public enum Change: Codable, Sendable, Equatable {
        case split(String, into: [String])
        case merge(kept: String, removed: String)
        case collapse(String, child: String)
        case move(leaf: String, from: String, to: String)
        /// A leaf this tree may no longer see (deleted, or walled since it was filed) left its holder.
        case drop(leaf: String, from: String)
        /// A holder left with nothing went.
        case remove(String)
    }

    public struct Logged: Codable, Sendable, Equatable {
        public var at: Date
        public var change: Change
    }

    public var splitAt = 24
    public var mergeAt = 12
    public var settlePerNight = 20
    public var changesPerNight = 3
    public var keyWords = 12
    /// How many ask words a leaf must share to be found.
    public var minShared = 2
    public static let logLimit = 500

    public private(set) var nodes: [String: Node] = [TopicTree.root: Node(id: TopicTree.root)]
    public private(set) var log: [Logged] = []
    /// How often asks used two holders together, decayed each night.
    public private(set) var coUse: [String: Double] = [:]
    private var made = 0

    public init() {}

    /// A tree as it stands, for tests.
    init(nodes: [String: Node], made: Int) {
        self.nodes = nodes
        self.made = made
    }

    // MARK: Reading

    /// Every leaf under a node.
    public func leaves(under id: String) -> [String] {
        guard let node = nodes[id] else { return [] }
        return node.leaves + node.children.flatMap { leaves(under: $0) }
    }

    /// The node holding a leaf.
    public func holder(of leaf: String) -> String? {
        nodes.values.first { $0.leaves.contains(leaf) }?.id
    }

    /// The words that set a node's leaves apart, best first: how many of its leaves hold the word, weighted by how
    /// rare the word is over all leaves. Exact counts, never a guess.
    public func key(_ id: String, words: TopicWords) -> [String] {
        let leaves = leaves(under: id)
        guard !leaves.isEmpty else { return [] }
        var counts: [String: Int] = [:]
        for leaf in leaves {
            for word in words.words(leaf) {
                counts[word, default: 0] += 1
            }
        }
        let total = Double(max(1, words.of.count))
        let score = counts.mapValues { Double($0) / Double(leaves.count) }
            .map { word, share in (word, share * Foundation.log(1 + total / Double(words.df[word] ?? 1))) }
        return score.sorted { ($0.1, $1.0) > ($1.1, $0.0) }.prefix(keyWords).map(\.0)
    }

    /// The leaves that share `minShared` of the ask's words, and the nodes opened to find them, root first. Every child
    /// that holds such a leaf is opened, the one holding most first.
    public func find(_ terms: [String], words: TopicWords) -> (leaves: [String], opened: [String]) {
        let ask = Set(terms)
        func matches(_ leaf: String) -> Bool {
            words.words(leaf).intersection(ask).count >= minShared
        }
        var found: [String] = []
        var opened: [String] = []
        var frontier = [Self.root]
        while !frontier.isEmpty {
            let id = frontier.removeFirst()
            guard let node = nodes[id] else { continue }
            opened.append(id)
            found += node.leaves.filter(matches)
            let ranked = node.children.map { child in (child, leaves(under: child).count(where: matches)) }
                .filter { $0.1 > 0 }
                .sorted { ($0.1, $1.0) > ($1.1, $0.0) }
            frontier += ranked.map(\.0)
        }
        return (found, opened)
    }

    // MARK: Growing

    /// Files a new leaf under the node whose key it shares most words with. A leaf already filed stays where it is.
    public mutating func insert(_ leaf: String, words: TopicWords) {
        guard holder(of: leaf) == nil else { return }
        let own = words.words(leaf)
        var id = Self.root
        while let node = nodes[id], !node.children.isEmpty {
            id = node.children.max { a, b in
                (own.intersection(key(a, words: words)).count, b) < (own.intersection(key(b, words: words)).count, a)
            } ?? id
        }
        nodes[id]?.leaves.append(leaf)
    }

    /// Asks that found leaves in more than one holder used them together: what a merge listens to.
    public mutating func used(_ found: [String]) {
        let holders = Set(found.compactMap { holder(of: $0) }).sorted()
        for (index, a) in holders.enumerated() {
            for b in holders.dropFirst(index + 1) {
                coUse["\(a)|\(b)", default: 0] += 1
            }
        }
    }

    /// The night's upkeep: the prune, then splits (biggest first), merges and collapses under the cap, then leaves
    /// settle. Returns what changed.
    @discardableResult
    public mutating func night(words: TopicWords, now: Date) -> [Change] {
        let pruned = prune(words: words)
        var changes: [Change] = []
        for node in nodes.values.sorted(by: { ($0.size, $1.id) > ($1.size, $0.id) }) where node.size > splitAt {
            guard changes.count < changesPerNight else { break }
            // An earlier split this night may have replaced it or taken some of its children.
            guard let current = nodes[node.id], current.size > splitAt else { continue }
            changes.append(split(current.id, words: words))
        }
        while changes.count < changesPerNight, let pair = mergeable(words: words) {
            changes.append(merge(pair.0, pair.1))
        }
        while changes.count < changesPerNight, let lone = nodes.values.filter({ node in
            node.id != Self.root && node.leaves.isEmpty && node.children.count == 1
        }).map(\.id).min() {
            guard let change = collapse(lone) else { break }
            changes.append(change)
        }
        changes = pruned + changes + settle(words: words)
        coUse = coUse.mapValues { $0 * 0.8 }.filter { $0.value >= 0.5 }
        log += changes.map { Logged(at: now, change: $0) }
        if log.count > Self.logLimit {
            log.removeFirst(log.count - Self.logLimit)
        }
        return changes
    }

    /// Takes out every leaf the words don't hold: under strict anything walled now, under both anything deleted. A
    /// holder left empty goes, up the tree, and a node that leaves with one child collapses. Without it a stale id
    /// would still count in sizes, splits, merges and settling.
    mutating func prune(words: TopicWords) -> [Change] {
        var changes: [Change] = []
        var touched: Set<String> = []
        for id in nodes.keys.sorted() {
            guard let node = nodes[id] else { continue }
            for leaf in node.leaves where words.of[leaf] == nil {
                changes.append(.drop(leaf: leaf, from: id))
            }
            nodes[id]?.leaves.removeAll { words.of[$0] == nil }
        }
        while let empty = nodes.values.filter({ node in
            node.id != Self.root && node.leaves.isEmpty && node.children.isEmpty
        }).map(\.id).min() {
            if let parent = nodes[empty]?.parent {
                nodes[parent]?.children.removeAll { $0 == empty }
                touched.insert(parent)
            }
            nodes[empty] = nil
            forget(empty)
            touched.remove(empty)
            changes.append(.remove(empty))
        }
        while let lone = touched.filter({ id in
            id != Self.root && nodes[id]?.leaves.isEmpty == true && nodes[id]?.children.count == 1
        }).min() {
            touched.remove(lone)
            if let change = collapse(lone) {
                changes.append(change)
            }
        }
        return changes
    }

    /// Drops the co-use counts of a node that went.
    mutating func forget(_ id: String) {
        coUse = coUse.filter { !$0.key.split(separator: "|").contains(Substring(id)) }
    }

    mutating func newID() -> String {
        made += 1
        return "\(Self.root)/t\(made)"
    }

    mutating func split(_ id: String, words: TopicWords) -> Change {
        guard let node = nodes[id] else { return .split(id, into: []) }
        let holdsLeaves = !node.leaves.isEmpty
        let items = holdsLeaves ? node.leaves : node.children
        let sets = items.map { holdsLeaves ? words.words($0) : Set(key($0, words: words)) }
        let groups = Self.twoMeans(sets)
        var halves: [String] = []
        for group in groups {
            let half = newID()
            var new = Node(id: half, parent: nil)
            if holdsLeaves {
                new.leaves = group.map { items[$0] }
            } else {
                new.children = group.map { items[$0] }
                for child in new.children {
                    nodes[child]?.parent = half
                }
            }
            nodes[half] = new
            halves.append(half)
        }
        if id == Self.root {
            nodes[id]?.leaves = []
            nodes[id]?.children = halves
            for half in halves {
                nodes[half]?.parent = id
            }
        } else if let parent = node.parent {
            nodes[id] = nil
            nodes[parent]?.children.removeAll { $0 == id }
            nodes[parent]?.children += halves
            for half in halves {
                nodes[half]?.parent = parent
            }
        }
        return .split(id, into: halves)
    }

    /// Two groups by word overlap: seeded by the first item and the one least like it, then five rounds of moving
    /// each item to the group whose words it shares most. Never an empty group.
    static func twoMeans(_ sets: [Set<String>]) -> [[Int]] {
        guard sets.count >= 2 else { return [Array(sets.indices)] }
        func alike(_ a: Set<String>, _ b: Set<String>) -> Double {
            Double(a.intersection(b).count) / Double(max(1, a.union(b).count))
        }
        let far = sets.indices.dropFirst().min { (alike(sets[0], sets[$0]), $0) < (alike(sets[0], sets[$1]), $1) } ?? 1
        var centers = [Dictionary(sets[0].map { ($0, 1) }, uniquingKeysWith: +),
                       Dictionary(sets[far].map { ($0, 1) }, uniquingKeysWith: +)]
        var groups: [[Int]] = [[], []]
        for _ in 0 ..< 5 {
            groups = [[], []]
            for (index, set) in sets.enumerated() {
                let score = centers.map { center in
                    Double(set.reduce(0) { $0 + (center[$1] ?? 0) }) / Double(max(1, center.values.reduce(0, +)))
                }
                groups[score[0] >= score[1] ? 0 : 1].append(index)
            }
            if groups[0].isEmpty || groups[1].isEmpty {
                let half = sets.count / 2
                groups = [Array(0 ..< half), Array(half ..< sets.count)]
            }
            centers = groups.map { group in
                var center: [String: Int] = [:]
                for index in group {
                    for word in sets[index] {
                        center[word, default: 0] += 1
                    }
                }
                return center
            }
        }
        return groups
    }

    /// The most a merge may make: `mergeAt`, and never more than half of `splitAt`, so a merged holder can't be split
    /// again by the next leaves it gets.
    var mergeLimit: Int {
        min(mergeAt, splitAt / 2)
    }

    /// The best pair of sibling holders to merge: together at most `mergeLimit`, and used together by asks at least 3
    /// times or with keys at least half the same.
    func mergeable(words: TopicWords) -> (String, String)? {
        var best: (score: (Double, Double), pair: (String, String))?
        for node in nodes.values.sorted(by: { $0.id < $1.id }) {
            let holders = node.children.filter { nodes[$0]?.children.isEmpty == true }.sorted()
            for (index, a) in holders.enumerated() {
                for b in holders.dropFirst(index + 1) {
                    guard leaves(under: a).count + leaves(under: b).count <= mergeLimit else { continue }
                    let keyA = Set(key(a, words: words)), keyB = Set(key(b, words: words))
                    let alike = Double(keyA.intersection(keyB).count) / Double(max(1, keyA.union(keyB).count))
                    let used = coUse["\(a)|\(b)"] ?? 0
                    guard used >= 3 || alike >= 0.5 else { continue }
                    if best.map({ (used, alike) > $0.score }) ?? true {
                        best = ((used, alike), (a, b))
                    }
                }
            }
        }
        return best?.pair
    }

    mutating func merge(_ kept: String, _ removed: String) -> Change {
        nodes[kept]?.leaves += nodes[removed]?.leaves ?? []
        if let parent = nodes[removed]?.parent {
            nodes[parent]?.children.removeAll { $0 == removed }
        }
        nodes[removed] = nil
        forget(removed)
        return .merge(kept: kept, removed: removed)
    }

    mutating func collapse(_ id: String) -> Change? {
        guard let node = nodes[id], node.children.count == 1, let child = node.children.first,
              let parent = node.parent else { return nil }
        nodes[parent]?.children = nodes[parent]?.children.map { $0 == id ? child : $0 } ?? []
        nodes[child]?.parent = parent
        nodes[id] = nil
        forget(id)
        return .collapse(id, child: child)
    }

    /// How well a leaf's words fit a holder: for each word, the share of the holder's other leaves that hold it. A
    /// word every one of them holds counts 1.
    static func fit(_ own: Set<String>, _ leaf: String, holder: Node, counts: [String: Int]) -> Double {
        let inside = holder.leaves.contains(leaf)
        let others = holder.leaves.count - (inside ? 1 : 0)
        guard others > 0 else { return 0 }
        return own.reduce(0) { $0 + Double((counts[$1] ?? 0) - (inside ? 1 : 0)) / Double(others) }
    }

    /// Moves up to `settlePerNight` leaves, each to the holder it fits at least one word better than its own (the
    /// "affinity" settle of the simulation), the biggest gains first. A holder is never emptied. A move changes no
    /// fact, only where a leaf sits.
    mutating func settle(words: TopicWords) -> [Change] {
        let holders = nodes.values.filter { $0.children.isEmpty && !$0.leaves.isEmpty }.sorted { $0.id < $1.id }
        let counts = Dictionary(uniqueKeysWithValues: holders.map { holder in
            (holder.id, holder.leaves.reduce(into: [String: Int]()) { counts, leaf in
                for word in words.words(leaf) {
                    counts[word, default: 0] += 1
                }
            })
        })
        var moves: [(gain: Double, leaf: String, from: String, to: String)] = []
        for from in holders {
            for leaf in from.leaves {
                let own = words.words(leaf)
                let fits = holders.map { holder in
                    (holder.id, Self.fit(own, leaf, holder: holder, counts: counts[holder.id] ?? [:]))
                }
                guard let best = fits.max(by: { ($0.1, $1.0) < ($1.1, $0.0) }) else { continue }
                let here = fits.first { $0.0 == from.id }?.1 ?? 0
                if best.0 != from.id, best.1 - here >= 1 {
                    moves.append((best.1 - here, leaf, from.id, best.0))
                }
            }
        }
        var changes: [Change] = []
        for move in moves.sorted(by: { ($0.gain, $1.leaf) > ($1.gain, $0.leaf) }).prefix(settlePerNight) {
            guard (nodes[move.from]?.leaves.count ?? 0) > 1 else { continue }
            nodes[move.from]?.leaves.removeAll { $0 == move.leaf }
            nodes[move.to]?.leaves.append(move.leaf)
            changes.append(.move(leaf: move.leaf, from: move.from, to: move.to))
        }
        return changes
    }
}

/// The topic axis under the walls: one tree per policy. Lab files every leaf; strict files only claude-safe ones, so
/// its shape, keys and finds read exactly as if the walled leaves never happened. A leaf walled or deleted later
/// leaves at the next night's prune, and one plain again is filed again that night.
public struct TopicMemory: Codable, Sendable, Equatable {
    public private(set) var lab = TopicTree()
    public private(set) var strict = TopicTree()

    public init() {}

    public func tree(_ policy: DoorPolicy) -> TopicTree {
        policy == .lab ? lab : strict
    }

    /// Files new leaves in each tree that may see them, oldest first.
    public mutating func add(_ new: [PyramidLeaf], all: [PyramidLeaf]) {
        let labWords = TopicWords(all, policy: .lab), strictWords = TopicWords(all, policy: .strict)
        for leaf in new.sorted(by: { ($0.at, $0.id) < ($1.at, $1.id) }) {
            lab.insert(leaf.id, words: labWords)
            if leaf.taint == .claudeSafe {
                strict.insert(leaf.id, words: strictWords)
            }
        }
    }

    public mutating func used(_ found: [String], policy: DoorPolicy) {
        if policy == .lab {
            lab.used(found)
        } else {
            strict.used(found)
        }
    }

    /// The night: first any leaf a tree may see but hasn't filed is filed (one missed by `add`, or one walled and
    /// plain again), then each tree's upkeep.
    @discardableResult
    public mutating func night(_ all: [PyramidLeaf], now: Date)
        -> (lab: [TopicTree.Change], strict: [TopicTree.Change])
    {
        let labWords = TopicWords(all, policy: .lab), strictWords = TopicWords(all, policy: .strict)
        let inLab = Set(lab.leaves(under: TopicTree.root)), inStrict = Set(strict.leaves(under: TopicTree.root))
        for leaf in all.sorted(by: { ($0.at, $0.id) < ($1.at, $1.id) }) {
            if !inLab.contains(leaf.id) {
                lab.insert(leaf.id, words: labWords)
            }
            if leaf.taint == .claudeSafe, !inStrict.contains(leaf.id) {
                strict.insert(leaf.id, words: strictWords)
            }
        }
        return (lab.night(words: labWords, now: now), strict.night(words: strictWords, now: now))
    }
}
