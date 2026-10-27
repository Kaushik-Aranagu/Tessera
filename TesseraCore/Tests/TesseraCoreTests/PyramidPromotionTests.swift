import Foundation
@testable import TesseraTess
import Testing

/// P3 of the memory pyramid (docs/ai/harness/memory-pyramid.md), shared per level: a fact readers keep digging for
/// is promoted onto every node of its level, each line computed exactly from the leaves, under the walls, and
/// forgotten when nobody uses it.
@MainActor
struct PyramidPromotionTests {
    let calendar = EvalWorld.calendar

    func date(_ month: Int, _ day: Int, _ hour: Int = 18) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour)) ?? .distantPast
    }

    var leaves: [PyramidLeaf] {
        [
            PyramidLeaf(id: "w1", at: date(10, 20), kind: "workout", text: "Push Day", stats: ["sets": 10]),
            PyramidLeaf(id: "w2", at: date(10, 21), kind: "workout", text: "Pull Day", stats: ["sets": 12]),
            PyramidLeaf(id: "c1", at: date(10, 21, 19), kind: "cook", text: "Dal", stats: ["cooks": 1]),
            PyramidLeaf(id: "w3", at: date(10, 22), kind: "workout", text: "Push Day", stats: ["sets": 14]),
            PyramidLeaf(id: "b1", at: date(10, 22, 7), kind: "body", text: "Weighed in", taint: .deviceOnly,
                        stats: ["weightKg": 80, "weighIns": 1]),
            PyramidLeaf(id: "p1", at: date(10, 23, 7), kind: "workout", text: "Private workout"),
            PyramidLeaf(id: "w4", at: date(10, 23), kind: "workout", text: "Push Day", stats: ["sets": 9]),
            PyramidLeaf(id: "b2", at: date(10, 24, 7), kind: "body", text: "Weighed in", taint: .deviceOnly,
                        stats: ["weightKg": 81, "weighIns": 1]),
            PyramidLeaf(id: "s1", at: date(10, 24, 9), kind: "spend", text: "Coffee", taint: .deviceOnly,
                        stats: ["spentUSD": 40]),
            PyramidLeaf(id: "w5", at: date(9, 10), kind: "workout", text: "Pull Day", stats: ["sets": 14]),
            PyramidLeaf(id: "w6", at: date(9, 11), kind: "workout", text: "Pull Day", stats: ["sets": 8]),
        ]
    }

    func makePyramid() -> MemoryPyramid {
        MemoryPyramid(leaves: leaves, calendar: calendar)
    }

    // MARK: Facts

    @Test func aFactIsStoredByItsKeyAndOnlyANameIsAKey() {
        for fact in [PyramidFact.busiest("sets"), .top("workout"), .last("cook")] {
            #expect(PyramidFact(key: fact.key) == fact)
        }
        #expect(PyramidFact(key: "top:Lexapro cake") == nil)
        #expect(PyramidFact(key: "top:") == nil && PyramidFact(key: "next:workout") == nil)
        #expect(PyramidFact(key: "last:" + String(repeating: "x", count: 25)) == nil)
    }

    @Test func theBusiestDayIsTheOneDayWithTheMost() {
        let pyramid = makePyramid()
        let october = pyramid.factLine(.busiest("sets"), at: "/time/2026/10", policy: .strict)
        #expect(october == PyramidLine(text: "Day with the most sets: Thu, Oct 22, 2026 (/time/2026/10/22), 14",
                                       taint: .claudeSafe))
        // Oct 22 and Sep 10 both have 14: no single answer, so no line.
        #expect(pyramid.factLine(.busiest("sets"), at: "/time/2026", policy: .strict) == nil)
        #expect(pyramid.factLine(.busiest("nothing"), at: "/time/2026/10", policy: .lab) == nil)
    }

    @Test func theTopThingLeadsAloneAndAPrivateLabelNeverLeads() {
        let pyramid = makePyramid()
        #expect(pyramid.factLine(.top("workout"), at: "/time/2026/10", policy: .strict)?.text
            == "Most often workout: Push Day, 3 times")
        // Push Day and Pull Day tie over the year; one cook is no habit.
        #expect(pyramid.factLine(.top("workout"), at: "/time/2026", policy: .strict) == nil)
        #expect(pyramid.factLine(.top("cook"), at: "/time/2026/10", policy: .strict) == nil)
    }

    @Test func theLastOneIsTheNewest() {
        let line = makePyramid().factLine(.last("workout"), at: MemoryPyramid.root, policy: .strict)
        #expect(line?.text == "Last workout: Push Day, Fri, Oct 23, 2026 (/time/2026/10/23)")
    }

    @Test func aDayOrALeafHasNoFactLine() throws {
        let pyramid = makePyramid()
        #expect(pyramid.factLine(.last("workout"), at: "/time/2026/10/22", policy: .lab) == nil)
        let leaf = try #require(pyramid.nodes["/time/2026/10/22"]?.children.first)
        #expect(pyramid.factLine(.last("workout"), at: leaf, policy: .lab) == nil)
        #expect(pyramid.factLine(.last("workout"), at: "/time/1999", policy: .lab) == nil)
    }

    // MARK: Walls

    @Test func strictNeverComputesFromAWalledLeaf() {
        let pyramid = makePyramid()
        #expect(pyramid.factLine(.busiest("weight"), at: "/time/2026/10", policy: .strict) == nil)
        #expect(pyramid.factLine(.last("body"), at: "/time/2026/10", policy: .strict) == nil)
        #expect(pyramid.factLine(.last("spend"), at: "/time/2026", policy: .strict) == nil)
        // Lab reads them, and says so.
        let weight = pyramid.factLine(.busiest("weight"), at: "/time/2026/10", policy: .lab)
        #expect(weight?.taint == .deviceOnly && weight?.text.contains("Oct 24") == true)
        let body = pyramid.factLine(.last("body"), at: "/time/2026/10", policy: .lab)
        #expect(body == PyramidLine(text: "Last body: Weighed in, Sat, Oct 24, 2026 (/time/2026/10/24)",
                                    taint: .deviceOnly))
    }

    @Test func strictReadsAsIfTheWalledLeavesNeverHappened() {
        let full = makePyramid()
        let safe = MemoryPyramid(leaves: leaves.filter { $0.taint == .claudeSafe }, calendar: calendar)
        let facts: [PyramidFact] = [.busiest("sets"), .busiest("weight"), .busiest("spentUSD"), .top("workout"),
                                    .top("body"), .last("workout"), .last("body"), .last("spend"), .last("cook")]
        for path in full.nodes.keys {
            for fact in facts {
                let walled = full.factLine(fact, at: path, policy: .strict)
                #expect(walled == safe.factLine(fact, at: path, policy: .strict), "\(fact.key) at \(path)")
            }
        }
    }

    // MARK: Promotion

    @Test func kDigsPromoteAFactOntoTheLevel() {
        var promotions = PyramidPromotions()
        let now = date(10, 25)
        let first = promotions.dug(.busiest("sets"), at: .month, now: now)
        let second = promotions.dug(.busiest("sets"), at: .month, now: now)
        #expect(!first && !second && promotions.facts(at: .month).isEmpty)
        let third = promotions.dug(.busiest("sets"), at: .month, now: now)
        #expect(third)
        #expect(promotions.facts(at: .month) == [.busiest("sets")])
        #expect(promotions.facts(at: .year).isEmpty)
        // Its count starts again, and a dig for a fact already shown counts for nothing.
        #expect(promotions.digs["month"] == nil)
        let again = promotions.dug(.busiest("sets"), at: .month, now: now)
        #expect(!again && promotions.digs["month"] == nil)
    }

    @Test func aDayAndAnUnnamedFactAreNeverPromoted() {
        var promotions = PyramidPromotions(k: 1)
        let day = promotions.dug(.last("workout"), at: .day, now: date(10, 25))
        let typed = promotions.dug(.top("Lexapro cake"), at: .month, now: date(10, 25))
        #expect(!day && !typed)
        #expect(promotions.shown.isEmpty && promotions.digs.isEmpty)
    }

    @Test func theDigCountsStayUnderTheCap() {
        var promotions = PyramidPromotions(k: 3)
        let letters = Array("abcdefghijklmnopqrstuvwxyz")
        for index in 0 ..< 40 {
            promotions.dug(.top("f\(letters[index % 26])\(letters[index / 26])"), at: .month, now: date(10, 25))
        }
        #expect((promotions.digs["month"]?.count ?? 0) == PyramidPromotions.maxCounted)
    }

    @Test func aZoomShowsThePromotedLinesAfterItsTotals() {
        let pyramid = makePyramid()
        var promotions = PyramidPromotions(k: 1)
        promotions.dug(.busiest("sets"), at: .month, now: date(10, 25))
        promotions.dug(.busiest("weight"), at: .month, now: date(10, 25, 19))
        let strict = pyramid.zoom("/time/2026/10", policy: .strict, promotions: promotions).text
        let lines = strict.split(separator: "\n").map(String.init)
        #expect(lines.count > 2 && lines[1].hasPrefix("Totals:"))
        #expect(lines[2] == "Day with the most sets: Thu, Oct 22, 2026 (/time/2026/10/22), 14")
        #expect(!strict.contains("body weight"))
        let lab = pyramid.zoom("/time/2026/10", policy: .lab, promotions: promotions).text
        #expect(lab.contains("Day with the most kg body weight on average: Sat, Oct 24, 2026"))
        // Without promotions a zoom reads as it always did.
        #expect(pyramid.zoom("/time/2026/10", policy: .strict).text == pyramid.zoom("/time/2026/10", policy: .strict,
                                                                                      promotions: nil).text)
        #expect(!pyramid.zoom("/time/2026/10", policy: .strict).text.contains("Day with the most"))
    }

    // MARK: Forgetting

    @Test func aLineNobodyUsesIsForgotten() {
        var promotions = PyramidPromotions(k: 1)
        promotions.dug(.busiest("sets"), at: .month, now: date(9, 1))
        promotions.dug(.top("workout"), at: .month, now: date(9, 1))
        promotions.used(.busiest("sets"), at: .month, now: date(9, 20))
        // Using a line that isn't shown changes nothing.
        promotions.used(.last("cook"), at: .month, now: date(9, 20))
        let dropped = promotions.night(now: date(10, 5))
        #expect(dropped == ["month/top:workout"])
        #expect(promotions.facts(at: .month) == [.busiest("sets")])
    }

    @Test func aLevelKeepsItsBudgetFreshestFirst() {
        var promotions = PyramidPromotions(k: 1, budget: 3)
        let facts: [PyramidFact] = [.busiest("sets"), .top("workout"), .last("workout"), .last("cook")]
        for (index, fact) in facts.enumerated() {
            promotions.dug(fact, at: .year, now: date(10, 1 + index))
        }
        #expect(promotions.facts(at: .year).count == 4)
        let dropped = promotions.night(now: date(10, 6))
        #expect(dropped == ["year/busiest:sets"])
        #expect(promotions.facts(at: .year) == [.last("cook"), .last("workout"), .top("workout")])
    }

    @Test func thePromotionsSurviveTheFile() throws {
        var promotions = PyramidPromotions(k: 2, budget: 4, forgetDays: 14)
        promotions.dug(.busiest("sets"), at: .week, now: date(10, 25))
        promotions.dug(.top("workout"), at: .month, now: date(10, 25))
        promotions.dug(.top("workout"), at: .month, now: date(10, 25))
        let saved = try JSONDecoder().decode(PyramidPromotions.self, from: JSONEncoder().encode(promotions))
        #expect(saved == promotions)
    }
}
