import Foundation
@testable import TesseraCore
import Testing

/// Plan my day (design sheet 157): the proposal of the day, engine only.
@MainActor
struct DayPlanTestsProposal {
    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    func at(_ hour: Int, _ minute: Int = 0, day: Int = 22) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    func plan(title: String = "Push A", startHour: Int = 18) throws -> ObjectRecord {
        let routine = try engine.perform(CreateRoutine(title: title), by: .user).output
        let plan = try engine.perform(CreatePlan(title: "PPL", routines: [routine.id]), by: .user).output
        for week in 1 ... 3 {
            let workout = try store.create(#require(engine.classes[.workout]), title: title)
            try store.setLinks("routine", on: workout, to: [routine])
            try store.set("endedAt", to: .date(at(startHour + 1, day: 22 - week)), on: workout)
            let entry = try store.create(#require(engine.classes[.exerciseEntry]), parent: workout)
            try store.setClassLink("exercise", on: entry, to: #require(engine.classes[.benchPress]))
            let ledger = TrainingLedger(store: store, classes: engine.classes)
            let first = try ledger.logSet(weight: 80, reps: 5, in: entry)
            let last = try ledger.logSet(weight: 80, reps: 5, in: entry)
            try store.set("loggedAt", to: .date(at(startHour, day: 22 - week)), on: first)
            try store.set("loggedAt", to: .date(at(startHour + 1, day: 22 - week)), on: last)
        }
        return plan
    }

    func meeting(_ title: String, _ from: Date, _ to: Date, location: String? = nil) throws {
        try engine.perform(SyncCalendar(
            inputs: [CalendarEventInput(externalID: title, title: title, start: from, end: to,
                                        calendarName: "Work", selfStatus: .accepted, location: location)],
            windowStart: at(0), windowEnd: at(23, 59)
        ), by: .system)
    }

    func task(_ title: String, _ when: Date?) throws {
        let record = try store.create(#require(engine.classes[.task]), title: title)
        if let when {
            try store.set("startsAt", to: .date(when), on: record)
        }
    }

    func propose(_ plan: ObjectRecord? = nil, routines: [RoutinesLanding.Item] = []) -> [DayProposal.Clause] {
        DayProposal.propose(engine: engine, plan: plan, routines: routines, now: at(9), calendar: calendar)
    }

    @Test func emptyDayIsEmpty() {
        #expect(propose().isEmpty)
    }

    @Test func orderedByTimeWithUntimedLast() throws {
        try task("Call Sam", at(15))
        try task("Email Joy", at(11))
        try meeting("Standup", at(13), at(13, 30))
        let texts = propose().map(\.text)
        #expect(texts == ["Email Joy.", "Standup at 1 pm.", "Call Sam."])
    }

    @Test func calendarIsFixedAndAWorkoutIsPushedAfterIt() throws {
        let plan = try plan()
        try meeting("Planning", at(17, 30), at(19))
        let clauses = propose(plan)
        let event = try #require(clauses.first { $0.kind == .fixed })
        let workout = try #require(clauses.first { $0.app == .training })
        #expect(event.time == at(17, 30))
        #expect(workout.time == at(19))
        #expect(workout.wasPushed)
        #expect(clauses.map(\.kind) == [.fixed, .proposed])
    }

    @Test func aWorkoutBeforeAnEventStaysPut() throws {
        let plan = try plan()
        try meeting("Late call", at(20), at(21))
        let workout = try #require(propose(plan).first { $0.app == .training })
        #expect(workout.time == at(18))
        #expect(!workout.wasPushed)
    }

    @Test func runningProcessLeadsAsNow() throws {
        try task("Email Joy", at(10))
        let workout = try store.create(#require(engine.classes[.workout]), title: "Pull B")
        try engine.perform(StartProcess(subject: workout.id, ownerApp: "training"), by: .user)
        let clauses = propose()
        #expect(clauses.first?.text == "Now: Pull B.")
    }

    @Test func privateThingsAreMasked() throws {
        let workout = try store.create(#require(engine.classes[.workout]), title: "Dr Patel")
        try engine.perform(StartProcess(subject: workout.id, ownerApp: "training"), by: .user)
        try meeting("Dr Patel", at(14), at(15))
        let recipe = try engine.perform(CreateRecipe(text: "Dr Patel stew\nIngredients\n1 onion\nMethod\n1. Stir."),
                                        by: .user).output
        let planned = try store.create(#require(engine.classes[.task]), title: "Dr Patel stew")
        try store.set("startsAt", to: .date(at(18)), on: planned)
        try store.setLinks("about", on: planned, to: [recipe])
        let texts = propose().map(\.text)
        #expect(texts.contains("Now: Private workout."))
        #expect(texts.contains { $0.contains("Private recipe") })
        #expect(texts.contains("Busy at 2 pm."))
        #expect(!texts.joined().contains("Patel"))
    }

    @Test func proposeWritesNothing() throws {
        let plan = try plan()
        try task("Email Joy", at(10))
        try meeting("Standup", at(13), at(14))
        let before = store.revision
        _ = propose(plan)
        #expect(store.revision == before)
    }

    @Test func atMostEight() throws {
        for index in 0 ..< 12 {
            try task("Task \(index)", at(10 + index % 10, index))
        }
        #expect(propose().count == DayProposal.maxClauses)
    }

    @Test func noPlaceOrAttendeesInText() throws {
        try meeting("Review", at(10), at(11), location: "Room 12 Secret Street")
        let text = propose().map(\.text).joined()
        #expect(text == "Review at 10 am.")
        #expect(!text.contains("Secret"))
    }

    @Test func tessNeverSeesTheProposal() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appendingPathComponent("Sources/TesseraTess")
        let files = try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "swift" }
        #expect(!files.isEmpty)
        for file in files {
            let source = try String(contentsOf: file, encoding: .utf8)
            #expect(!source.contains("DayProposal"), "\(file.lastPathComponent) must not read the day proposal")
        }
    }
}
