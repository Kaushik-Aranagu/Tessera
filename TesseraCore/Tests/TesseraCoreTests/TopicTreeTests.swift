import Foundation
@testable import TesseraTess
import Testing

/// P4 of the memory pyramid (docs/ai/harness/memory-pyramid.md): a topic axis for free text that grows its own shape.
/// Finding is exact, every leaf is filed once, splits and merges keep their hysteresis and their nightly cap, leaves
/// settle where they fit, and the strict tree reads as if walled leaves never happened.
@MainActor
struct TopicTreeTests {
    static let topics: [(name: String, words: [String])] = [
        ("garden", ["tomato", "basil", "soil", "compost", "seedlings", "watering"]),
        ("guitar", ["chord", "strings", "practice", "song", "capo", "tuning"]),
        ("travel", ["flight", "hotel", "passport", "luggage", "airport", "itinerary"]),
    ]
    static let filler = ["said", "really", "think", "going", "still", "again"]
    let now = Date(timeIntervalSince1970: 1_792_000_000)

    func id(_ topic: String, _ index: Int) -> String {
        "\(topic)-\(index < 10 ? "0" : "")\(index)"
    }

    /// Twelve leaves a topic, each three of its words and a filler word; and `walled` private ones.
    func leaves(walled: Int = 0) -> [PyramidLeaf] {
        var out: [PyramidLeaf] = []
        for (topic, words) in Self.topics {
            for index in 0 ..< 12 {
                let text = [words[index % 6], words[(index + 1) % 6], words[(index + 3) % 6], Self.filler[index % 6]]
                out.append(PyramidLeaf(id: id(topic, index), at: now.addingTimeInterval(Double(out.count)),
                                       kind: "told", text: text.joined(separator: " ")))
            }
        }
        for index in 0 ..< walled {
            let topicWord = ["tomato", "chord", "flight"][index % 3]
            out.append(PyramidLeaf(id: "walled-\(index)", at: now.addingTimeInterval(Double(out.count)), kind: "told",
                                   text: "lexapro dose \(topicWord) morning", taint: .deviceOnly))
        }
        return out
    }

    func grown(splitAt: Int = 6, nights: Int = 10)
        -> (tree: TopicTree, words: TopicWords, nights: [[TopicTree.Change]])
    {
        let all = leaves()
        let words = TopicWords(all, policy: .lab)
        var tree = TopicTree()
        tree.splitAt = splitAt
        tree.mergeAt = splitAt / 2
        for leaf in all {
            tree.insert(leaf.id, words: words)
        }
        var history: [[TopicTree.Change]] = []
        for night in 0 ..< nights {
            history.append(tree.night(words: words, now: now.addingTimeInterval(Double(night) * 86400)))
        }
        return (tree, words, history)
    }

    static func structural(_ changes: [TopicTree.Change]) -> Int {
        changes.count(where: { change in
            if case .move = change { false } else { true }
        })
    }

    // MARK: Growing

    @Test func itGrowsUnderTheCapAndFilesEveryLeafOnce() {
        let (tree, _, history) = grown()
        let structural = history.map { Self.structural($0) }
        #expect(structural.allSatisfy { $0 <= tree.changesPerNight })
        #expect(structural.contains(tree.changesPerNight))
        #expect(structural.suffix(3).allSatisfy { $0 == 0 })
        let filed = tree.leaves(under: TopicTree.root)
        #expect(filed.sorted() == leaves().map(\.id).sorted())
        #expect(Set(filed).count == filed.count)
        #expect(tree.nodes.values.allSatisfy { $0.size <= tree.splitAt })
        #expect(tree.nodes.count > 3)
        // Every change is logged with its night.
        #expect(tree.log.count == history.joined().count)
    }

    @Test(arguments: [["tomato", "basil"], ["chord", "capo"], ["flight", "passport", "hotel"], ["soil", "chord"]])
    func findingIsExactAndOpensOnlyWhatMatches(ask: [String]) {
        let (tree, words, _) = grown()
        let (found, opened) = tree.find(ask, words: words)
        let flat = words.of.keys.filter { words.words($0).intersection(ask).count >= 2 }.sorted()
        #expect(found.sorted() == flat)
        #expect(opened.first == TopicTree.root)
        #expect(opened.count < tree.nodes.count)
    }

    // MARK: Settling

    func node(_ id: String, _ parent: String?, children: [String] = [], leaves: [String] = []) -> TopicTree.Node {
        TopicTree.Node(id: id, parent: parent, children: children, leaves: leaves)
    }

    func makeTree(_ nodes: [TopicTree.Node], splitAt: Int = 24) -> TopicTree {
        var tree = TopicTree(nodes: Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) }), made: 9)
        tree.splitAt = splitAt
        return tree
    }

    let root = TopicTree.root
    var a: String {
        root + "/t1"
    }

    var b: String {
        root + "/t2"
    }

    var c: String {
        root + "/t3"
    }

    func garden(_ indices: Int...) -> [String] {
        indices.map { id("garden", $0) }
    }

    func guitar(_ indices: Int...) -> [String] {
        indices.map { id("guitar", $0) }
    }

    @Test func aMisfiledLeafSettlesWhereItFits() {
        let words = TopicWords(leaves(), policy: .lab)
        var tree = makeTree([node(root, nil, children: [a, b]),
                         node(a, root, leaves: garden(0, 1, 2, 3, 4, 5) + guitar(0)),
                         node(b, root, leaves: guitar(1, 2, 3, 4, 5))])
        let first = tree.night(words: words, now: now)
        #expect(first == [.move(leaf: id("guitar", 0), from: a, to: b)])
        #expect(tree.night(words: words, now: now).isEmpty)
    }

    // MARK: Merging

    @Test func siblingsWithTheSameKeyMerge() {
        let words = TopicWords(leaves(), policy: .lab)
        // garden-06 and garden-07 say what garden-00 and garden-01 say.
        var tree = makeTree([node(root, nil, children: [a, b, c]), node(a, root, leaves: garden(0, 1)),
                         node(b, root, leaves: garden(6, 7)), node(c, root, leaves: guitar(0, 1, 2, 3, 4))])
        #expect(tree.night(words: words, now: now) == [.merge(kept: a, removed: b)])
        #expect(tree.nodes[root]?.children == [a, c] && tree.nodes[a]?.leaves.count == 4)
        #expect(tree.night(words: words, now: now).isEmpty)
    }

    @Test func siblingsAsksKeepUsingTogetherMerge() {
        let words = TopicWords(leaves(), policy: .lab)
        let d = root + "/t4"
        var tree = makeTree([node(root, nil, children: [a, d, c]), node(a, root, leaves: garden(0, 1, 2)),
                         node(d, root, leaves: [id("travel", 0), id("travel", 1)]),
                         node(c, root, leaves: guitar(0, 1, 2, 3, 4))])
        #expect(tree.night(words: words, now: now).isEmpty)
        for _ in 0 ..< 3 {
            tree.used(garden(0) + [id("travel", 0)])
        }
        #expect(tree.night(words: words, now: now) == [.merge(kept: a, removed: d)])
    }

    @Test func aMergeNeverMakesWhatTheNextSplitWouldUndo() {
        let words = TopicWords(leaves(), policy: .lab)
        var tree = makeTree([node(root, nil, children: [a, b]), node(a, root, leaves: garden(0, 1, 2, 3, 4, 5)),
                         node(b, root, leaves: garden(6, 7, 8, 9, 10, 11))], splitAt: 10)
        // Alike and used together, but twelve leaves is past half of 10, even with mergeAt set higher.
        tree.mergeAt = 20
        #expect(tree.mergeLimit == 5)
        for _ in 0 ..< 5 {
            tree.used(garden(0, 6))
        }
        #expect(tree.night(words: words, now: now).isEmpty)
    }

    @Test func aNodeWithOneChildCollapses() {
        let words = TopicWords(leaves(), policy: .lab)
        let x = root + "/t5", y = root + "/t6"
        var tree = makeTree([node(root, nil, children: [x, c]), node(x, root, children: [y]),
                         node(y, x, leaves: garden(0, 1, 2)), node(c, root, leaves: guitar(0, 1, 2))])
        #expect(tree.night(words: words, now: now) == [.collapse(x, child: y)])
        #expect(tree.nodes[root]?.children == [y, c] && tree.nodes[y]?.parent == root && tree.nodes[x] == nil)
    }

    // MARK: Pruning

    @Test func aLeafWalledAfterItWasFiledLeavesTheStrictTree() throws {
        let all = leaves()
        var memory = TopicMemory()
        memory.add(all, all: all)
        memory.night(all, now: now)
        let walled = id("garden", 0)
        let holder = try #require(memory.strict.holder(of: walled))
        let later = all.map { leaf in
            var leaf = leaf
            if leaf.id == walled {
                leaf.taint = .deviceOnly
            }
            return leaf
        }
        let changes = memory.night(later, now: now.addingTimeInterval(86400))
        #expect(changes.strict.first == .drop(leaf: walled, from: holder))
        #expect(!changes.lab.contains { if case .drop = $0 { true } else { false } })
        let strict = memory.strict
        #expect(!strict.leaves(under: TopicTree.root).contains(walled) && strict.holder(of: walled) == nil)
        #expect(strict.nodes.values.reduce(0) { $0 + $1.leaves.count } == all.count - 1)
        #expect(strict.nodes[holder]?.leaves.contains(walled) == false)
        #expect(memory.lab.leaves(under: TopicTree.root).contains(walled))
        #expect(strict.log.contains { $0.change == .drop(leaf: walled, from: holder) })
    }

    @Test func aDeletedLeafLeavesBothTrees() {
        let all = leaves()
        var memory = TopicMemory()
        memory.add(all, all: all)
        memory.night(all, now: now)
        let deleted = id("garden", 0)
        let changes = memory.night(all.filter { $0.id != deleted }, now: now.addingTimeInterval(86400))
        for (tree, night) in [(memory.lab, changes.lab), (memory.strict, changes.strict)] {
            #expect(night.contains { if case .drop(deleted, _) = $0 { true } else { false } })
            #expect(!tree.leaves(under: TopicTree.root).contains(deleted))
            #expect(tree.nodes.values.reduce(0) { $0 + $1.leaves.count } == all.count - 1)
        }
    }

    @Test func aHolderLeftEmptyGoesAndItsLoneParentCollapses() {
        let words = TopicWords(leaves().filter { $0.id != id("garden", 0) }, policy: .lab)
        let x = root + "/t5"
        var tree = makeTree([node(root, nil, children: [x, c]), node(x, root, children: [a, b]),
                             node(a, x, leaves: garden(0)), node(b, x, leaves: garden(1, 2, 3)),
                             node(c, root, leaves: guitar(0, 1, 2))])
        let first = tree.night(words: words, now: now)
        #expect(first == [.drop(leaf: id("garden", 0), from: a), .remove(a), .collapse(x, child: b)])
        #expect(tree.nodes[root]?.children == [b, c] && tree.nodes[b]?.parent == root)
        #expect(tree.nodes[a] == nil && tree.nodes[x] == nil)
        #expect(tree.night(words: words, now: now).isEmpty)
    }

    // MARK: Walls

    @Test func strictReadsAsIfTheWalledLeavesNeverHappened() {
        let all = leaves(walled: 6)
        var memory = TopicMemory()
        memory.add(all, all: all)
        var safeOnly = TopicMemory()
        let safe = leaves()
        safeOnly.add(safe, all: safe)
        for night in 0 ..< 5 {
            let at = now.addingTimeInterval(Double(night) * 86400)
            memory.night(all, now: at)
            safeOnly.night(safe, now: at)
        }
        #expect(memory.strict == safeOnly.strict)
        #expect(!memory.strict.leaves(under: TopicTree.root).contains { $0.hasPrefix("walled") })
        let lab = memory.lab.find(["lexapro", "dose"], words: TopicWords(all, policy: .lab)).leaves
        let strict = memory.strict.find(["lexapro", "dose"], words: TopicWords(all, policy: .strict)).leaves
        #expect(lab.count == 6 && strict.isEmpty)
    }

    @Test func itStoresIdsNeverWords() throws {
        let all = leaves(walled: 3)
        var memory = TopicMemory()
        memory.add(all, all: all)
        memory.night(all, now: now)
        let json = try String(decoding: JSONEncoder().encode(memory), as: UTF8.self)
        #expect(!json.contains("tomato") && !json.contains("lexapro"))
        let saved = try JSONDecoder().decode(TopicMemory.self, from: JSONEncoder().encode(memory))
        #expect(saved == memory)
    }

    @Test func twoMeansNeverLeavesAGroupEmpty() {
        let same = [Set(["a", "b"]), Set(["a", "b"]), Set(["a", "b"])]
        let groups = TopicTree.twoMeans(same)
        #expect(groups.count == 2 && groups.allSatisfy { !$0.isEmpty })
        #expect(TopicTree.twoMeans([Set(["a"])]) == [[0]])
    }
}
