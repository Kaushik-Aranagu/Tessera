import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// The store slice of the memory pyramid: his store as leaves, with every wall the night pass keeps. A private thing is
/// its label and counts for nothing; unfinished, deleted and future rows never become leaves.
@MainActor
struct PyramidStoreLeavesTests {
    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine
    let now = Date.now.addingTimeInterval(3600)
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }

    func at(_ month: Int, _ day: Int, hour: Int = 18) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour))!
    }

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    var classes: [SystemCatalog.Key: ClassDef] {
        engine.classes
    }

    func make(_ key: SystemCatalog.Key, _ title: String) throws -> ObjectRecord {
        try store.create(#require(classes[key]), title: title)
    }

    @discardableResult
    func workout(_ title: String, on date: Date, finished: Bool = true, sets: [(Double, Double)]) throws
        -> ObjectRecord
    {
        let workout = try make(.workout, title)
        if finished {
            try store.set("endedAt", to: .date(date), on: workout)
        }
        try store.set("startedAt", to: .date(date.addingTimeInterval(-3600)), on: workout)
        let ledger = TrainingLedger(store: store, classes: classes)
        let entry = try store.create(#require(classes[.exerciseEntry]), parent: workout)
        try store.setClassLink("exercise", on: entry, to: #require(classes[.benchPress]))
        for (weight, reps) in sets {
            let made = try ledger.logSet(weight: weight, reps: reps, in: entry)
            try store.set("loggedAt", to: .date(date), on: made)
        }
        return workout
    }

    func leaves() -> [PyramidLeaf] {
        MemoryPyramid.leaves(store: store, classes: classes, now: now)
    }

    @Test func aFinishedWorkoutIsALeafWithItsSets() throws {
        try workout("Push Day", on: at(10, 6), sets: [(95, 3), (85, 8)])
        try workout("Push Day", on: at(10, 7), finished: false, sets: [(60, 10)])
        try workout("Push Day", on: now.addingTimeInterval(86400 * 2), sets: [(60, 10)])
        let deleted = try workout("Push Day", on: at(10, 8), sets: [(60, 10)])
        store.softDelete(deleted)
        let found = leaves().filter { $0.kind == "workout" }
        #expect(found.count == 1)
        let leaf = try #require(found.first)
        #expect(leaf.text.hasPrefix("Push Day: ") && leaf.text.contains("95 kg x3") && leaf.text.contains("85 kg x8"))
        #expect(leaf.stats["workouts"] == 1 && leaf.stats["sets"] == 2 && leaf.stats["volumeKg"] == 95 * 3 + 85 * 8)
        #expect(leaf.taint == .claudeSafe)
    }

    @Test func aPrivateThingIsItsLabelAndCountsForNothing() throws {
        let routine = try make(.routine, "Knee rehab day")
        let hidden = try workout("Session", on: at(10, 6), sets: [(40, 12)])
        try store.setLinks("routine", on: hidden, to: [routine])
        let task = try make(.task, "Lexapro refill")
        try store.set("doneAt", to: .date(at(10, 7)), on: task)
        let note = try make(.note, "wifi")
        try store.set("body", to: .text("wifi password is tacocat24"), on: note)
        note.createdAt = at(10, 8)
        let all = leaves()
        let texts = all.map { $0.text }
        #expect(texts.contains("Private workout") && texts.contains("Private task") && texts.contains("Private note"))
        for walled in ["Knee", "rehab", "Lexapro", "tacocat24", "password", "40 kg"] {
            #expect(!texts.contains { $0.contains(walled) }, "\(walled)")
        }
        #expect(all.allSatisfy { $0.stats.isEmpty && $0.taint == .deviceOnly })
    }

    @Test func strictReadsAsIfThePrivateRowsNeverHappened() throws {
        try workout("Push Day", on: at(10, 6), sets: [(95, 3)])
        try workout("Pull Day", on: at(10, 20), sets: [(70, 8)])
        // One private workout on a day of its own, one beside a plain one, and a walled task.
        let routine = try make(.routine, "Knee rehab day")
        for day in [13, 6] {
            let hidden = try workout("Session", on: at(10, day), sets: [(40, 12)])
            try store.setLinks("routine", on: hidden, to: [routine])
        }
        let task = try make(.task, "Lexapro refill")
        try store.set("doneAt", to: .date(at(10, 14)), on: task)
        let all = leaves()
        let with = MemoryPyramid(leaves: all, calendar: calendar)
        let without = MemoryPyramid(leaves: all.filter { $0.taint == .claudeSafe }, calendar: calendar)
        #expect(all.count(where: { $0.taint == .deviceOnly }) == 3)
        for path in without.nodes.keys.sorted() where without.nodes[path]?.level != .leaf {
            #expect(with.zoom(path, policy: .strict).text == without.zoom(path, policy: .strict).text, "\(path)")
        }
        #expect(with.zoom("/time/2026/10/13", policy: .strict).isError)
    }

    @Test func everyLiftShownPassesTheBodyWall() throws {
        // His weigh-in is a private note; a set at that weight may read as his body weight.
        let weighIn = try make(.note, "Weigh-in")
        try store.set("body", to: .text("82 kg this morning"), on: weighIn)
        try store.set("isPrivate", to: .bool(true), on: weighIn)
        try workout("Push Day", on: at(10, 6), sets: [(82, 5), (60, 8)])
        let leaf = try #require(leaves().first { $0.kind == "workout" })
        let lifts = leaf.text.split(separator: ": ", maxSplits: 1).last.map {
            $0.components(separatedBy: ", ")
        } ?? []
        let last = BodyWeight.lastKg(in: store)
        // The weigh-in is read, so the wall really runs with his weight. Set notation beside a lift name is the bar,
        // never his body (PrivateFacts, QA on #644), so "82 kg x5" itself may show.
        #expect(last == 82)
        #expect(ObjectPrivacy.isPrivateTitle("weighed 82 kg", lastWeightKg: last))
        #expect(lifts.allSatisfy { !ObjectPrivacy.isPrivateTitle($0, lastWeightKg: last) }, "\(lifts)")
        #expect(leaf.text.contains("60 kg x8"))
        // What isn't shown isn't counted either.
        #expect(leaf.stats["sets"] == Double(lifts.count))
    }

    @Test func cooksTasksAndNotesComeIn() throws {
        let task = try make(.task, "Dentist")
        try store.set("doneAt", to: .date(at(10, 15, hour: 9)), on: task)
        _ = try make(.task, "Bins")
        let note = try make(.note, "Trip")
        try store.set("body", to: .text("Trip packing\nsocks"), on: note)
        note.createdAt = at(10, 9)
        let cook = try make(.cook, "Weeknight dal")
        try store.set("cookedAt", to: .date(at(10, 12)), on: cook)
        let texts = Set(leaves().map { $0.text })
        #expect(texts.isSuperset(of: ["Did Dentist", "Trip packing\nsocks", "Cooked Weeknight dal"]))
        #expect(!texts.contains { $0.contains("Bins") })
    }

    @Test func thePyramidReadsTheSlice() throws {
        try workout("Push Day", on: at(10, 6), sets: [(95, 3), (85, 8)])
        try workout("Pull Day", on: at(10, 8), sets: [(70, 8)])
        let task = try make(.task, "Dentist")
        try store.set("doneAt", to: .date(at(10, 15, hour: 9)), on: task)
        let pyramid = MemoryPyramid(leaves: leaves(), calendar: calendar)
        let month = try #require(pyramid.nodes["/time/2026/10"])
        #expect(month.stats["workouts"] == 2 && month.stats["sets"] == 3 && month.stats["tasks"] == 1)
        #expect(pyramid.zoom("/time/2026/10", policy: .strict).text.contains("tasks done"))
    }
}
