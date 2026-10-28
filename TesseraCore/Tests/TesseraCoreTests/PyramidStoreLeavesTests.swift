import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// The store slice of the memory pyramid: his store as leaves, with every wall the night pass keeps. A private thing is
/// its label and counts for nothing; unfinished, deleted and future rows never become leaves. The suite runs the old
/// walls; what lab reads now is `underLabAPrivateThingIsItsOwnWordsStillDeviceOnly`.
@MainActor
@Suite(.oldWalls)
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

    @Test func underLabAPrivateThingIsItsOwnWordsStillDeviceOnly() throws {
        try ClaudeSees.$everything.withValue(true) {
            let routine = try make(.routine, "Knee rehab day")
            let hidden = try workout("Session", on: at(10, 6), sets: [(40, 12)])
            try store.setLinks("routine", on: hidden, to: [routine])
            let task = try make(.task, "Lexapro refill")
            try store.set("doneAt", to: .date(at(10, 7)), on: task)
            let note = try make(.note, "wifi")
            try store.set("body", to: .text("wifi password is tacocat24"), on: note)
            note.createdAt = at(10, 8)
            let keyed = try make(.note, "key")
            try store.set("body", to: .text("my key " + "sk-" + "ant-" + "made-up-for-a-test-0123456789"), on: keyed)
            keyed.createdAt = at(10, 9)
            // A key past the 280-character cut: the cut could leave a piece that no longer looks like one.
            let long = try make(.note, "Long")
            let key = "sk-" + "ant-" + "made-up-for-a-test-0123456789"
            try store.set("body", to: .text(String(repeating: "a", count: 270) + " " + key), on: long)
            long.createdAt = at(10, 10)
            let all = leaves()
            let texts = all.map(\.text)
            #expect(texts.contains("Session") && texts.contains("Did Lexapro refill"), "\(texts)")
            #expect(texts.contains("wifi password is tacocat24") && texts.contains("Private note"), "\(texts)")
            #expect(!texts.contains { $0.contains("sk-" + "ant-") || $0.contains(String(repeating: "a", count: 50)) })
            #expect(texts.count(where: { $0 == "Private note" }) == 2, "\(texts)")
            // Walled all the same: no total, and strict never reads them.
            #expect(all.allSatisfy { $0.stats.isEmpty && $0.taint == .deviceOnly })
            let pyramid = MemoryPyramid(leaves: all, calendar: calendar)
            #expect(pyramid.zoom("/time/2026/10/07", policy: .strict).isError)
            #expect(pyramid.zoom("/time/2026/10/07", policy: .lab).text.contains("Did Lexapro refill"))
        }
    }

    @Test(arguments: ["ate 600 calories today", "Burned 400 kcal on the bike", "Hurt my knee on the stairs",
                      "Paid $40 at the clinic"])
    func aNoteTheStrictScanWouldRefuseIsItsLabel(body: String) throws {
        let note = try make(.note, "Today")
        try store.set("body", to: .text(body), on: note)
        note.createdAt = at(10, 8)
        let leaf = try #require(leaves().first { $0.kind == "note" })
        #expect(leaf.text == "Private note" && leaf.taint == .deviceOnly && leaf.stats.isEmpty, "\(body)")
        // Every claude-safe leaf passes the Door's own strict scan.
        try workout("Push Day", on: at(10, 6), sets: [(95, 3)])
        for safe in leaves() where safe.taint == .claudeSafe {
            #expect(!PrivateFacts.isWalled(safe.text, lastWeightKg: BodyWeight.lastKg(in: store))
                && !PrivateFacts.isCalorieShaped(safe.text) && !SecretWords.mentions(safe.text), "\(safe.text)")
        }
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

    @discardableResult
    func spend(_ typed: String, currency: String = "", category: String = "", note: String = "", on date: Date) throws
        -> ObjectRecord
    {
        let spend = try make(.spend, "Spend")
        try store.set("typed", to: .text(typed), on: spend)
        try store.set("currency", to: .text(currency), on: spend)
        try store.set("category", to: .text(category), on: spend)
        try store.set("note", to: .text(note), on: spend)
        try store.set("spentAt", to: .date(date), on: spend)
        return spend
    }

    func inflow(_ typed: String, into pool: ObjectRecord, note: String = "", on date: Date) throws {
        let inflow = try make(.inflow, "Paycheck")
        try store.setLinks("pool", on: inflow, to: [pool])
        try store.set("amountTyped", to: .text(typed), on: inflow)
        try store.set("source", to: .choice("paycheck"), on: inflow)
        try store.set("note", to: .text(note), on: inflow)
        try store.set("at", to: .date(date), on: inflow)
    }

    @Test func moneyIsWalledAndAddsToItsCurrencysTotal() throws {
        try workout("Push Day", on: at(10, 6), sets: [(95, 3)])
        try spend("12.40", category: "coffee", note: "with Sam", on: at(10, 6))
        try spend("3.10", on: at(10, 7))
        try spend("8", currency: "EUR", note: "museum", on: at(10, 7))
        try spend("900", currency: "JPY", on: at(10, 8))
        try spend("5", on: now.addingTimeInterval(86400 * 2))
        try store.softDelete(spend("40", on: at(10, 9)))
        let euros = try make(.pool, "Euro account")
        try store.set("currency", to: .text("EUR"), on: euros)
        try inflow("2,400.00", into: euros, on: at(10, 1))
        let all = leaves()
        let money = all.filter { ["spend", "inflow"].contains($0.kind) }
        #expect(money.count == 5 && money.allSatisfy { $0.taint == .deviceOnly }, "\(money)")
        // Under the old walls a spend is its label, as everywhere outside its own page.
        #expect(money.allSatisfy { [ObjectPrivacy.spendLabel, ObjectPrivacy.inflowLabel].contains($0.text) })
        let pyramid = MemoryPyramid(leaves: all, calendar: calendar)
        let month = try #require(pyramid.nodes["/time/2026/10"])
        // The typed digits, by currency; a currency with no total of its own adds to none.
        #expect(abs((month.stats["spentUSD"] ?? 0) - 15.5) < 0.001, "\(month.stats)")
        #expect(month.stats["spentEUR"] == 8 && month.stats["earnedEUR"] == 2400, "\(month.stats)")
        #expect(month.stats.keys.allSatisfy { !$0.contains("JPY") })
        let lab = pyramid.zoom("/time/2026/10", policy: .lab).text
        #expect(lab.contains("dollars spent") && lab.contains("euros in"), "\(lab)")
        // Strict reads as if no money moved: no total, and a day of only money is not there.
        let strict = pyramid.zoom("/time/2026/10", policy: .strict).text
        #expect(!strict.contains("dollars") && !strict.contains("euros"), "\(strict)")
        #expect(pyramid.zoom("/time/2026/10/07", policy: .strict).isError)
        let without = MemoryPyramid(leaves: all.filter { $0.taint == .claudeSafe }, calendar: calendar)
        #expect(strict == without.zoom("/time/2026/10", policy: .strict).text)
    }

    @Test func underLabMoneyIsItsOwnWordsButNeverAKey() throws {
        try ClaudeSees.$everything.withValue(true) {
            try spend("12.40", category: "food", note: "lunch with Sam", on: at(10, 6))
            try spend("3", currency: "EUR", on: at(10, 6, hour: 9))
            try spend("1", note: "key " + "sk-" + "ant-" + "made-up-for-a-test-0123456789", on: at(10, 6, hour: 10))
            let checking = try make(.pool, "Checking")
            try inflow("1200", into: checking, note: "October", on: at(10, 1))
            let texts = leaves().map(\.text)
            #expect(texts.contains("Spent $12.40 on food: lunch with Sam"), "\(texts)")
            #expect(texts.contains("Spent €3.00"), "\(texts)")
            #expect(texts.contains("Got $1,200.00 from paycheck: October"), "\(texts)")
            #expect(texts.contains(ObjectPrivacy.spendLabel) && !texts.contains { $0.contains("sk-" + "ant-") })
            let day = MemoryPyramid(leaves: leaves(), calendar: calendar).zoom("/time/2026/10/06", policy: .lab).text
            #expect(day.contains("lunch with Sam"), "\(day)")
        }
    }

    func healthAndCalendar() throws {
        let sleep = try make(.sleepNight, "Sleep")
        try store.set("date", to: .date(at(10, 6, hour: 7)), on: sleep)
        try store.set("asleepMinutes", to: .number(440), on: sleep)
        let steps = try make(.stepsDay, "Steps")
        try store.set("date", to: .date(at(10, 6, hour: 0)), on: steps)
        try store.set("count", to: .number(8412), on: steps)
        let heart = try make(.restingHeartRate, "Resting heart rate")
        try store.set("date", to: .date(at(10, 7, hour: 0)), on: heart)
        try store.set("bpm", to: .number(58), on: heart)
        for (title, day, cancelled) in [("Dentist", 7, false), ("Lunch with Sam", 8, true)] {
            let event = try make(.event, title)
            try store.set("start", to: .date(at(10, day, hour: 9)), on: event)
            try store.set("cancelled", to: .bool(cancelled), on: event)
        }
        let later = try make(.event, "Flight")
        try store.set("start", to: .date(now.addingTimeInterval(86400 * 3)), on: later)
        let weighIn = try make(.note, "Weigh-in")
        try store.set("body", to: .text("82 kg this morning"), on: weighIn)
        try store.set("isPrivate", to: .bool(true), on: weighIn)
        weighIn.createdAt = at(10, 7, hour: 7)
    }

    @Test func healthBodyAndTheCalendarAreWalledWithTheirOwnTotals() throws {
        try workout("Push Day", on: at(10, 6), sets: [(95, 3)])
        try healthAndCalendar()
        let all = leaves()
        let walled = all.filter { $0.taint == .deviceOnly }
        #expect(Set(walled.map(\.kind)) == ["sleep", "steps", "heart", "event", "note"], "\(walled)")
        // Under the old walls each is a plain name; a cancelled or future event never happened.
        let texts = Set(walled.map(\.text))
        #expect(texts == ["A night's sleep", "Steps", "Resting heart rate", "Calendar event", "Private note"])
        let pyramid = MemoryPyramid(leaves: all, calendar: calendar)
        let month = try #require(pyramid.nodes["/time/2026/10"])
        #expect(month.stats["events"] == 1 && month.stats["steps"] == 8412 && month.stats["weighIns"] == 1)
        #expect(month.stats["weightKg"] == 82 && month.stats["nights"] == 1, "\(month.stats)")
        let lab = pyramid.zoom("/time/2026/10", policy: .lab).text
        for total in ["calendar events", "steps", "hours of sleep", "kg body weight", "bpm resting heart rate"] {
            #expect(lab.contains(total), "\(total): \(lab)")
        }
        // Strict reads as if none of it happened.
        let strict = pyramid.zoom("/time/2026/10", policy: .strict).text
        let without = MemoryPyramid(leaves: all.filter { $0.taint == .claudeSafe }, calendar: calendar)
        #expect(strict == without.zoom("/time/2026/10", policy: .strict).text)
        #expect(pyramid.zoom("/time/2026/10/07", policy: .strict).isError)
    }

    @Test func underLabHealthAndTheCalendarAreTheirOwnWords() throws {
        try ClaudeSees.$everything.withValue(true) {
            try healthAndCalendar()
            let texts = Set(leaves().map(\.text))
            #expect(texts.isSuperset(of: ["Slept 7 h 20 min", "Walked 8,412 steps", "Resting heart rate 58 bpm",
                                          "On the calendar: Dentist", "82 kg this morning"]), "\(texts)")
            #expect(!texts.contains { $0.contains("Sam") || $0.contains("Flight") })
        }
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
