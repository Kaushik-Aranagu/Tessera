import Foundation
@testable import TesseraTess
import Testing

/// P1 of the memory pyramid (docs/ai/harness/memory-pyramid.md), on the test world: exact totals at every level,
/// residuals that are true, a zoom that costs a fraction of its leaves, staleness that touches only one chain, and the
/// walls.
@MainActor
struct MemoryPyramidTests {
    let world = EvalWorld.make()
    let calendar = EvalWorld.calendar

    func build(_ leaves: [PyramidLeaf]? = nil) -> MemoryPyramid {
        MemoryPyramid(leaves: leaves ?? world.pyramidLeaves(), calendar: calendar)
    }

    func inOctober(_ date: Date) -> Bool {
        calendar.component(.year, from: date) == 2026 && calendar.component(.month, from: date) == 10
    }

    // MARK: Exact

    @Test func totalsAreExactAtEveryLevel() throws {
        let pyramid = build()
        // Private workouts add nothing: they never reach Claude, so they can't sit in a claude-safe total.
        let october = world.workouts.filter { !$0.isDeleted && !$0.isPrivate && inOctober($0.start) }
        let node = try #require(pyramid.nodes["/time/2026/10"])
        #expect(node.stats["sets"] == Double(october.reduce(0) { $0 + $1.sets.count }))
        // Every level is the sum of its children, all the way up.
        for node in pyramid.nodes.values where node.level != .leaf {
            let sum = node.children.compactMap { pyramid.nodes[$0]?.stats["sets"] }.reduce(0, +)
            #expect(sum == (node.stats["sets"] ?? 0), "\(node.path)")
        }
        #expect(pyramid.nodes[MemoryPyramid.root]?.stats["sets"]
            == Double(world.workouts.filter { !$0.isDeleted && !$0.isPrivate }.reduce(0) { $0 + $1.sets.count }))
    }

    @Test func whatMustNeverCountNeverBecomesALeaf() throws {
        let leaves = world.pyramidLeaves()
        let deleted = try #require(world.workouts.firstIndex { $0.isDeleted })
        let reversed = try #require(world.spends.firstIndex { $0.isReversed })
        #expect(!leaves.contains { $0.id == "workout-\(deleted)" || $0.id == "spend-\(reversed)" })
        // A forgotten line never comes back; a private thing is only its label.
        #expect(!leaves.contains { $0.text.contains("locker") })
        #expect(!leaves.contains { $0.text.contains("Shoulder rehab") || $0.text.contains("Session notes") })
        #expect(leaves.contains { $0.text == "Private workout" } && leaves.contains { $0.text == "Private note" })
        let privateWorkouts = leaves.filter { $0.text == "Private workout" }
        #expect(privateWorkouts.allSatisfy { $0.stats.isEmpty })
        // A leaf's path never says what kind of thing it is.
        let pyramid = build()
        for node in pyramid.nodes.values where node.level == .leaf {
            #expect(node.path.split(separator: "/").last?.hasPrefix("leaf-") == true, "\(node.path)")
        }
    }

    @Test(arguments: [DoorPolicy.lab, .strict])
    func everyResidualIsTrueOfItsSiblings(policy: DoorPolicy) {
        let pyramid = build()
        var checked = 0
        for node in pyramid.nodes.values {
            // Under strict, only the siblings strict can see.
            let kids = node.children.compactMap { pyramid.nodes[$0] }.filter { policy == .lab || $0.safeLeaves > 0 }
            let residuals = node.residualsSeen(by: policy)
            #expect(Set(residuals.ranked) == Set(residuals.lines.keys))
            for (child, lines) in residuals.lines {
                guard let kid = kids.first(where: { $0.path == child }) else {
                    Issue.record("\(node.path) has a residual for \(child), which is not a child it shows")
                    continue
                }
                for line in lines {
                    let shown = PyramidStats.shown.first { line.text.hasPrefix("most \($0.label) (")
                        || line.text.hasPrefix("fewest \($0.label) (") }
                    guard let shown, policy == .lab || shown.taint == .claudeSafe else {
                        Issue.record("\(line.text) names no total \(policy) may read")
                        continue
                    }
                    // A total a child lacks counts as 0, the same as when the residual was made.
                    let value = shown.value(kid.stats) ?? 0
                    let values = kids.map { shown.value($0.stats) ?? 0 }
                    let best = line.text.hasPrefix("most") ? values.max() : values.min()
                    #expect(value == best && values.count(where: { $0 == value }) == 1, "\(node.path): \(line.text)")
                    #expect(line.text.hasSuffix("(\(PyramidStats.format(value)))"))
                    checked += 1
                }
            }
        }
        #expect(checked > 20)
        #expect(!(pyramid.nodes["/time/2026"]?.residualsSeen(by: policy).ranked.isEmpty ?? true))
    }

    // MARK: Cheap to read

    @Test func aZoomCostsAFractionOfItsLeaves() throws {
        let pyramid = build()
        let node = try #require(pyramid.nodes["/time/2026/10"])
        let zoom = pyramid.zoom("/time/2026/10", policy: .lab)
        #expect(!zoom.isError && zoom.text.count <= MemoryPyramid.maxCharacters)
        #expect(zoom.text.contains("sets \(PyramidStats.format(node.stats["sets"] ?? 0))"))
        let raw = pyramid.leaves(under: "/time/2026/10").compactMap { $0.text?.text }.joined(separator: "\n")
        #expect(zoom.text.count * 3 < raw.count, "zoom \(zoom.text.count), leaves \(raw.count)")
        // A day reads its leaves word for word; a path that isn't one is nothing.
        let day = try #require(node.children.first)
        let leaf = try #require(pyramid.nodes[day]?.children.first)
        #expect(pyramid.zoom(day, policy: .lab).text.contains(pyramid.nodes[leaf]?.text?.text ?? "-"))
        #expect(pyramid.zoom("/time/1999", policy: .lab).isError)
        #expect(pyramid.zoom("/time/2026/10/", policy: .lab).text == zoom.text)
    }

    // MARK: Stale

    @Test func oneEditStalesOnlyItsChain() throws {
        var leaves = world.pyramidLeaves()
        let index = try #require(leaves.firstIndex { $0.kind == "workout" && inOctober($0.at) })
        let before = build(leaves)
        leaves[index].stats["sets", default: 0] += 1
        leaves[index].text += ", Plank 0 kg x1"
        let after = build(leaves)
        let stale = after.stale(since: before)
        // The leaf, its day, its week, its month, its year and the root: nothing else.
        #expect(stale.count == 6, "\(stale)")
        #expect(stale.contains(MemoryPyramid.root) && stale.contains("/time/2026/10") && stale.contains("/time/2026"))
        #expect(stale.contains { $0.contains("/w") })
        #expect(build(leaves).stale(since: after).isEmpty)
    }

    // MARK: Walls

    @Test func strictKeepsMoneyBodyAndCalendarOnThePhone() throws {
        let pyramid = build()
        let lab = pyramid.zoom("/time/2026/10", policy: .lab).text
        let strict = pyramid.zoom("/time/2026/10", policy: .strict).text
        #expect(lab.contains("dollars spent") && lab.contains("hours of sleep"))
        #expect(!strict.contains("dollars spent") && !strict.contains("sleep") && !strict.contains("calendar"))
        #expect(strict.contains("sets"))
        // A day lists only its claude-safe leaves: a walled one has no line, no path and no count.
        let spendDay = try #require(pyramid.nodes.values.first { node in
            node.level == .day && node.children.contains { pyramid.nodes[$0]?.text?.text.hasPrefix("Spent") == true }
                && node.safeLeaves > 0
        })
        let day = pyramid.zoom(spendDay.path, policy: .strict).text
        #expect(!day.contains("Spent") && !day.contains("on this phone"))
        #expect(day.components(separatedBy: "/leaf-").count - 1 == spendDay.safeLeaves, "\(day)")
        for child in spendDay.children where pyramid.nodes[child]?.text?.taint == .deviceOnly {
            #expect(!day.contains(child + ":") && pyramid.zoom(child, policy: .strict).isError)
            #expect(!pyramid.zoom(child, policy: .lab).isError)
        }
    }

    @Test func strictCannotTellAWalledLeafWasEverThere() {
        // Strict reads the pyramid exactly as if the walled leaves had never happened: no gap in a path, no shifted
        // "most" or "fewest", no different count. A node only walled leaves made is not there at all.
        let leaves = world.pyramidLeaves()
        let full = build(leaves)
        let without = build(leaves.filter { $0.taint == .claudeSafe })
        #expect(leaves.contains { $0.taint == .deviceOnly })
        for path in full.nodes.keys {
            let seen = full.zoom(path, policy: .strict)
            if without.nodes[path] == nil {
                #expect(seen.isError, "\(path)")
            } else {
                #expect(seen.text == without.zoom(path, policy: .strict).text, "\(path)")
            }
        }
        // A leaf's name is a fingerprint, never a count.
        for node in full.nodes.values where node.level == .leaf {
            let name = node.path.split(separator: "/").last.map(String.init) ?? ""
            #expect(name.count == 13 && UInt64(name.dropFirst(5), radix: 16) != nil, "\(name)")
        }
    }

    @Test func aDayWithOnlyWalledThingsIsNotThereUnderStrict() {
        func day(_ number: Int, _ kind: String, _ sets: Double = 0) -> PyramidLeaf {
            let at = EvalWorld.at(2026, 10, number, 18)
            return kind == "workout"
                ? PyramidLeaf(id: "w\(number)", at: at, kind: kind, text: "Push A",
                              stats: ["workouts": 1, "sets": sets])
                : PyramidLeaf(id: "s\(number)", at: at, kind: kind, text: "Spent $12.00 on food: lunch",
                              taint: .deviceOnly, stats: ["spentUSD": 12])
        }
        let pyramid = build([day(1, "workout", 3), day(2, "workout", 9), day(3, "workout", 4), day(4, "spend")])
        #expect(pyramid.zoom("/time/2026/10/04", policy: .strict).isError)
        #expect(!pyramid.zoom("/time/2026/10/04", policy: .lab).isError)
        let strict = pyramid.zoom("/time/2026/10", policy: .strict).text
        #expect(!strict.contains("/time/2026/10/04") && !strict.contains("dollars"), "\(strict)")
        #expect(strict.contains("most sets (9)"))
        #expect(pyramid.zoom("/time/2026/10", policy: .lab).text.contains("dollars spent 12"))
    }
}
