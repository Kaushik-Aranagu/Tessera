import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// P1b of the memory pyramid (docs/ai/harness/memory-pyramid.md), with a scripted brain and no paid call: a gist
/// keeps only the sentences its children back, strict never sends a walled line, the night writes gists bottom up,
/// and an edit stales only its own chain's gists.
@MainActor
struct PyramidGistTests {
    let calendar = EvalWorld.calendar
    let month = "/time/2026/10"

    /// Three training days and, unless `walled` is false, a day that holds only a spend.
    func small(walled: Bool = true) -> MemoryPyramid {
        func lift(_ day: Int, _ sets: Double, _ text: String) -> PyramidLeaf {
            PyramidLeaf(id: "w\(day)", at: EvalWorld.at(2026, 10, day, 18), kind: "workout", text: text,
                        stats: ["workouts": 1, "sets": sets])
        }
        let spend = PyramidLeaf(id: "s5", at: EvalWorld.at(2026, 10, 5, 12), kind: "spend",
                                text: "Spent $12.00 on food: lunch", taint: .deviceOnly, stats: ["spentUSD": 12])
        let lifts = [lift(1, 3, "Push A: Bench 80 kg x5"), lift(2, 9, "Pull A: Row 70 kg x8"),
                     lift(3, 4, "Legs: Squat 100 kg x5")]
        return MemoryPyramid(leaves: walled ? lifts + [spend] : lifts, calendar: calendar)
    }

    func day(_ number: Int) -> String {
        "\(month)/0\(number)"
    }

    func gist(_ sentences: [(String, [String])]) -> Data {
        let items = sentences.map { ["text": $0.0, "cites": $0.1] as [String: Any] }
        return (try? JSONSerialization.data(withJSONObject: ["sentences": items])) ?? Data()
    }

    func reply(_ sentences: [(String, [String])]) -> [BrainEvent] {
        [.toolUse(id: "t1", name: PyramidDistiller.toolName, input: gist(sentences))]
    }

    // MARK: The check

    @Test func theCheckKeepsOnlyWhatTheChildrenBack() throws {
        let pyramid = small()
        let material = try #require(PyramidDistiller.material(month, in: pyramid, gists: PyramidGists(),
                                                              policy: .lab))
        let long = Array(repeating: "steady", count: PyramidDistiller.budget(.month) + 1).joined(separator: " ")
        let input = gist([
            ("The busiest day held 9 sets.", [day(2)]),
            ("He lifted 9999 kg.", [day(1)]),
            // 4 is a real total, but of a day this sentence doesn't cite.
            ("Pull day had 4 sets.", [day(2)]),
            ("Quiet weeks.", []),
            ("Something else.", ["/time/2026/11/01"]),
            ("  ", [day(1)]),
            (long, [day(1)]),
        ])
        let checked = PyramidDistiller.check(input, material: material, level: .month)
        #expect(checked.sentences.map(\.text) == ["The busiest day held 9 sets."])
        #expect(checked.dropped == [.unsupportedNumber, .unsupportedNumber, .noCite, .unknownCite, .empty,
                                    .overBudget])
        // Under lab the month's own totals hold money, so what rests on them is walled.
        #expect(checked.sentences.first?.taint == .deviceOnly)
        #expect(PyramidDistiller.check(Data("not a gist".utf8), material: material, level: .month).dropped
            == [.unreadable])
        #expect(PyramidDistiller.numbers("1,200 kg on Oct 3, then 62.5.") == ["1200", "3", "62.5"])
    }

    // MARK: Walls

    @Test func strictNeverSendsAWalledLine() async throws {
        let pyramid = small()
        let brain = ScriptedBrain(.haiku, rounds: [reply([("Sets peaked at 9 on Oct 2.", [day(2)])])])
        let rig = try DoorRig(brains: [.haiku: brain], policy: .strict)
        let written = await PyramidDistiller(door: rig.door).distill(month, in: pyramid, gists: PyramidGists())
        let request = try #require(brain.requestsSeen.first)
        let words = Door.words(request)
        let schema = String(decoding: request.tools.first?.schema ?? Data(), as: UTF8.self)
        for walled in ["Spent", "dollars", "lunch", day(5)] {
            #expect(!words.contains(walled) && !schema.contains(walled), "\(walled)")
        }
        #expect(words.contains("most sets (9)") && schema.contains(day(2)))
        let kept = try #require(written)
        #expect(kept.policy == .strict && kept.sentences.allSatisfy { $0.taint == .claudeSafe })
        // Strict reads the month exactly as if the spend had never happened.
        let without = PyramidDistiller.material(month, in: small(walled: false), gists: PyramidGists(),
                                                policy: .strict)
        #expect(PyramidDistiller.material(month, in: pyramid, gists: PyramidGists(), policy: .strict)?.fragments
            == without?.fragments)
        // Lab sends it, and a day of only walled things has no strict gist to write.
        #expect(PyramidDistiller.material(month, in: pyramid, gists: PyramidGists(), policy: .lab)?.fragments
            .contains { $0.text.contains("dollars spent 12") } == true)
        #expect(PyramidDistiller.material(day(5), in: pyramid, gists: PyramidGists(), policy: .strict) == nil)
    }

    @Test func strictReadsOnlyStrictGists() throws {
        let pyramid = small()
        let node = try #require(pyramid.nodes[month])
        var gists = PyramidGists()
        gists[month, .lab] = PyramidGist(path: month, hash: node.hash, policy: .lab, sentences: [
            PyramidSentence(text: "Lunch out once.", cites: [day(5)], taint: .deviceOnly),
        ], dropped: [])
        #expect(pyramid.zoom(month, policy: .lab, gists: gists).text.contains("In short: Lunch out once."))
        #expect(!pyramid.zoom(month, policy: .strict, gists: gists).text.contains("In short"))
        gists[month, .strict] = PyramidGist(path: month, hash: node.hash, policy: .strict, sentences: [
            PyramidSentence(text: "Pull day led.", cites: [day(2)], taint: .claudeSafe),
        ], dropped: [])
        #expect(pyramid.zoom(month, policy: .strict, gists: gists).text.contains("In short: Pull day led."))
    }

    // MARK: The night

    @Test func aScriptedNightWritesEveryGistBottomUp() async throws {
        let pyramid = small(walled: false)
        let order = PyramidGists().stale(in: pyramid, policy: .lab)
        // Days first, the root last.
        #expect(order.first.flatMap { pyramid.nodes[$0]?.level } == .day && order.last == MemoryPyramid.root)
        let rounds = try order.map { path -> [BrainEvent] in
            let material = try #require(PyramidDistiller.material(path, in: pyramid, gists: PyramidGists(),
                                                                  policy: .lab))
            let first = try #require(material.children.first?.path)
            return reply([("Steady work.", [first])])
        }
        let brain = ScriptedBrain(.haiku, rounds: rounds)
        let rig = try DoorRig(brains: [.haiku: brain])
        let gists = await PyramidDistiller(door: rig.door).refresh(pyramid, gists: PyramidGists())
        #expect(brain.requestsSeen.count == order.count)
        #expect(gists.stale(in: pyramid, policy: .lab).isEmpty)
        // The month was written after its days, from their new gists.
        let monthAsk = try #require(brain.requestsSeen.first { Door.words($0).contains("(\(month)).") })
        #expect(Door.words(monthAsk).contains("in short: Steady work."))
        #expect(pyramid.zoom(month, policy: .lab, gists: gists).text.contains("In short: Steady work."))
        #expect(!pyramid.zoom(month, policy: .strict, gists: gists).text.contains("In short"))

        // One edit stales its own chain's gists and nothing else, and a stale gist is never read.
        // The same three days, with one more set on the first.
        let leaves = [
            PyramidLeaf(id: "w1", at: EvalWorld.at(2026, 10, 1, 18), kind: "workout", text: "Push A: Bench 80 kg x5",
                        stats: ["workouts": 1, "sets": 4]),
            PyramidLeaf(id: "w2", at: EvalWorld.at(2026, 10, 2, 18), kind: "workout", text: "Pull A: Row 70 kg x8",
                        stats: ["workouts": 1, "sets": 9]),
            PyramidLeaf(id: "w3", at: EvalWorld.at(2026, 10, 3, 18), kind: "workout", text: "Legs: Squat 100 kg x5",
                        stats: ["workouts": 1, "sets": 4]),
        ]
        let edited = MemoryPyramid(leaves: leaves, calendar: calendar)
        let stale = gists.stale(in: edited, policy: .lab)
        #expect(Set(stale) == Set(edited.stale(since: pyramid).filter { edited.nodes[$0]?.level != .leaf }))
        #expect(stale.count == 5 && stale.first == day(1), "\(stale)")
        #expect(!edited.zoom(month, policy: .lab, gists: gists).text.contains("In short"))
        #expect(edited.zoom(day(2), policy: .lab, gists: gists).text.contains("In short: Steady work."))
    }
}
