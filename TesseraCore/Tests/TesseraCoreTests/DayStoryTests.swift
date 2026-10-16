import Foundation
@testable import TesseraCore
import Testing

/// The Day log fold (docs/research/day-log-acceptance.md DL1 to DL71; day-log-late-night.md; Design day-log-v1.md).
/// Records are made through the engine, then dated: the fold reads each root's own start and each record's zone.
@MainActor
struct DayStoryTests {
    static let la = TimeZone(identifier: "America/Los_Angeles")!
    static let newYork = TimeZone(identifier: "America/New_York")!

    static func calendar(_ zone: TimeZone = la) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        return calendar
    }

    /// A wall-clock moment in Los Angeles, October 2026 unless said.
    static func at(_ day: Int, _ hour: Int, _ minute: Int = 0, month: Int = 10, second: Int = 0) -> Date {
        calendar().date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute,
                                             second: second))!
    }

    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine

    init() throws {
        classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
        engine.zone = { Self.la }
    }

    /// Performs and dates the record (records are stamped "now" by the engine).
    @discardableResult
    func run<A: EngineAction>(_ action: A, at time: Date,
                              zone: TimeZone = la) throws -> (record: OpRecord, output: A.Output)
    {
        engine.zone = { zone }
        let result = try engine.perform(action, by: .user)
        result.record.createdAt = time
        // Objects made by it are made then too (a past-dated note keeps its own day).
        if let object = result.output as? ObjectRecord, !(action is CreateNote && (action as? CreateNote)?.on != nil) {
            object.createdAt = time
        }
        engine.zone = { Self.la }
        return (result.record, result.output)
    }

    func lines(_ day: Date, in zone: TimeZone = la, now: Date? = nil, rest: Bool = false) -> [String] {
        let calendar = Self.calendar(zone)
        return DayStory.lines(engine: engine, on: day, calendar: calendar, now: now ?? Self.at(30, 12), isRestDay: rest)
            .map { line in line.clock(calendar).map { "\($0)  \(line.text)" } ?? line.text }
    }

    func task(_ title: String, at time: Date) throws -> ObjectRecord {
        try run(CreateTask(title: title), at: time).output
    }

    /// A workout with one exercise: sets at the given times (weight, reps), finished at `end` if given.
    @discardableResult
    func workout(_ title: String, exercise key: SystemCatalog.Key = .benchPress, start: Date,
                 sets: [(Date, Double, Double)], end: Date?, zone: TimeZone = la) throws -> ObjectRecord
    {
        let workout = try store.create(#require(classes[.workout]), title: title)
        try run(StartWorkout(workout: workout.id, time: start), at: start, zone: zone)
        let entry = try run(AddExercise(workout: workout.id, exercise: #require(classes[key]).id), at: start,
                            zone: zone).output
        for (time, weight, reps) in sets {
            try run(LogSet(entry: entry.id, weight: weight, reps: reps, time: time), at: time, zone: zone)
        }
        if let end {
            try run(FinishWorkout(workout: workout.id, time: end), at: end, zone: zone)
        }
        return workout
    }

    // MARK: Late night (DL1 to DL19)

    @Test func setAfterMidnightStaysInWorkoutStartedBefore() throws {
        // DL1, DL2: Push Day B 23:20 Wed to 00:52 Thu is Wednesday's, 92 min.
        try task("pack bag", at: Self.at(21, 19, 5))
        try task("print tickets", at: Self.at(21, 19, 5))
        try workout("Push Day B", start: Self.at(21, 23, 20),
                    sets: [(Self.at(21, 23, 28), 80, 8), (Self.at(22, 0, 40), 85, 8)], end: Self.at(22, 0, 52))
        #expect(lines(Self.at(21, 12)) == ["19:05  Added 2 tasks", "23:20  Push Day B, 92 min. Bench 85 × 8."])
        #expect(lines(Self.at(22, 12)).isEmpty)
    }

    @Test func runningWorkoutAt0045IsUnderToday() throws {
        // DL3, DL58: under way, no minutes and no top set; the line is .running.
        try workout("Push Day B", start: Self.at(21, 23, 20), sets: [(Self.at(21, 23, 30), 80, 8),
                                                                     (Self.at(21, 23, 40), 80, 8)], end: nil)
        let now = Self.at(22, 0, 45)
        #expect(lines(now, now: now) == ["23:20  Push Day B, 2 sets"])
        let story = DayStory.lines(store: store, classes: classes, records: engine.history(limit: 100), on: now,
                                   calendar: Self.calendar(), now: now)
        #expect(story.first?.kind == .running)
    }

    @Test func aLiveWorkoutFromLastNightStaysOnItsDayPast0400() throws {
        // DL70, QA S2 on #318: started 23:00 Wed, still going at 04:30 Thu: on WED, in ink, still counting.
        try workout("Push Day B", start: Self.at(21, 23), sets: [(Self.at(21, 23, 10), 80, 8),
                                                                 (Self.at(22, 4, 20), 80, 8)], end: nil)
        let now = Self.at(22, 4, 30)
        let wednesday = DayStory.lines(engine: engine, on: Self.at(21, 12), calendar: Self.calendar(), now: now)
        #expect(wednesday.map(\.text) == ["Push Day B, 2 sets"] && wednesday.first?.kind == .running)
        #expect(lines(now, now: now).isEmpty)
        // Six hours on, it is the faint row.
        let later = DayStory.lines(engine: engine, on: Self.at(21, 12), calendar: Self.calendar(),
                                   now: Self.at(22, 5, 1))
        #expect(later.first?.kind == .unfinished)
    }

    @Test func ownLinesThatFillTheCapStillLeaveOneAlsoLine() throws {
        // QA L1 on #318: seven lists made in a day and a task: six lines, the last one the tail.
        for index in 0 ..< 7 {
            try run(CreateList(name: "List \(index)"), at: Self.at(9, 10, index))
        }
        try task("call mom", at: Self.at(9, 11))
        let day = lines(Self.at(9, 12))
        #expect(day.count == 6)
        #expect(day.last == "Also: New list: List 5, New list: List 6, 1 task.")
    }

    @Test func doneReopenedAndDoneAgainIsOneDone() throws {
        // QA L2 on #318.
        let bins = try task("take out bins", at: Self.at(9, 7))
        try run(SetTaskDone(task: bins.id, time: Self.at(10, 8)), at: Self.at(10, 8))
        try run(SetTaskDone(task: bins.id, done: false), at: Self.at(10, 8, 5))
        try run(SetTaskDone(task: bins.id, time: Self.at(10, 9)), at: Self.at(10, 9))
        #expect(lines(Self.at(10, 12)) == ["08:00  Done: take out bins"])
    }

    @Test func twoStartsAndOneFinishAreOneShop() throws {
        // QA L3 on #318: the later start closes with the finish; the open one prints nothing.
        let milk = try run(AddGroceries(lines: ["milk"]), at: Self.at(5, 9)).output
        try run(StartShop(time: Self.at(11, 10)), at: Self.at(11, 10))
        try run(StartShop(time: Self.at(11, 10, 5)), at: Self.at(11, 10, 5))
        for item in milk {
            try run(CheckListItem(item: item.id, time: Self.at(11, 10, 10)), at: Self.at(11, 10, 10))
        }
        try run(FinishShop(time: Self.at(11, 10, 20)), at: Self.at(11, 10, 20))
        #expect(lines(Self.at(11, 12)) == ["10:05  Shopped, 1 item"])
    }

    @Test func pastUnfinishedWorkoutIsMarkedUnfinished() throws {
        // K8, DL22, DL60: a past day's workout never finished is the faint row, with no words about it.
        try workout("Pull Day A", exercise: .benchPress, start: Self.at(14, 18),
                    sets: [(Self.at(14, 18, 5), 60, 10), (Self.at(14, 18, 10), 60, 10), (Self.at(14, 18, 15), 55, 10)],
                    end: nil)
        let story = DayStory.lines(store: store, classes: classes, records: engine.history(limit: 100),
                                   on: Self.at(14, 12), calendar: Self.calendar(), now: Self.at(20, 12))
        #expect(story.map(\.text) == ["Pull Day A, 3 sets. Bench 60 × 10."] && story.first?.kind == .unfinished)
    }

    @Test func noteAt0210BelongsToEveningBefore() throws {
        // DL4: a note at 02:10 Friday is Thursday's.
        let bank = try task("call the bank", at: Self.at(20, 9))
        try run(SetTaskDone(task: bank.id, time: Self.at(22, 8, 30)), at: Self.at(22, 8, 30))
        try run(CreateNote(body: "hotel ideas"), at: Self.at(23, 2, 10))
        #expect(lines(Self.at(22, 12)) == ["08:30  Done: call the bank", "02:10  Note: hotel ideas"])
        #expect(lines(Self.at(23, 12)).isEmpty)
    }

    @Test func pastDatedNoteUsesItsOnDateNotRecordTime() throws {
        // DL5, K3: the title is set explicitly; the note lands on the day it's about.
        try run(CreateNote(body: "watered the plants yesterday", title: "watered the plants", on: Self.at(21, 12)),
                at: Self.at(23, 2, 12))
        #expect(lines(Self.at(21, 12)) == ["12:00  Note: watered the plants"])
        #expect(lines(Self.at(22, 12)).isEmpty && lines(Self.at(23, 12)).isEmpty)
    }

    @Test func recordsAt035959And040000FallOnEitherSide() throws {
        // DL7, DL8.
        try task("one", at: Self.at(24, 3, 59, second: 59))
        try task("two", at: Self.at(24, 4))
        #expect(lines(Self.at(23, 12)) == ["03:59  Added 1 task"])
        #expect(lines(Self.at(24, 12)) == ["04:00  Added 1 task"])
    }

    @Test func workoutStarted0350FinishedAfter0400StaysOnStartDay() throws {
        // DL9, DL10: exactly one line, on Saturday, never a Sunday 04:02 line.
        try workout("Pull Day A", start: Self.at(25, 3, 50),
                    sets: [(Self.at(25, 3, 58), 55, 10), (Self.at(25, 4, 2), 60, 10)], end: Self.at(25, 4, 30))
        #expect(lines(Self.at(24, 12)) == ["03:50  Pull Day A, 40 min. Bench 60 × 10."])
        #expect(lines(Self.at(25, 12)).isEmpty)
    }

    @Test func redEyeTimesPrintInCurrentZoneAndDaysKeepTheirLoggedZone() throws {
        // DL11 to DL13, DL19: days from each record's zone, times in the zone he's in now.
        let plants = try task("water the plants", at: Self.at(20, 9))
        try run(SetTaskDone(task: plants.id, time: Self.at(26, 7, 30)), at: Self.at(26, 7, 30))
        try workout("Mobility", start: Self.at(26, 21, 40), sets: [(Self.at(26, 21, 45), 20, 10)],
                    end: Self.at(26, 22, 15))
        try run(CreateNote(body: "seat 14C, no sleep"), at: Self.at(27, 1, 30))
        #expect(lines(Self.at(26, 12)) == ["07:30  Done: water the plants", "21:40  Mobility, 35 min. Bench 20 × 10.",
                                           "01:30  Note: seat 14C, no sleep"])
        let monday = try #require(Self.calendar(Self.newYork).date(from: DateComponents(
            year: 2026,
            month: 10,
            day: 26,
            hour: 12
        )))
        #expect(lines(monday, in: Self.newYork) == ["10:30  Done: water the plants",
                                                    "00:40  Mobility, 35 min. Bench 20 × 10.",
                                                    "04:30  Note: seat 14C, no sleep"])
        // The same store read in LA again: no stale zone cache.
        #expect(lines(Self.at(26, 12)).first == "07:30  Done: water the plants")
    }

    @Test func fallBackNightPrintsTwo0130LinesInInstantOrder() throws {
        // DL14, DL15: 01:30 PDT then 01:30 PST, by instant; minutes absolute across the change.
        let hall = Date(timeIntervalSince1970: 1_793_521_800) // 2026-11-01 08:30Z, 01:30 PDT
        try run(CreateNote(body: "hall light out"), at: hall)
        let bins = try task("bins", at: Self.at(30, 9))
        try run(SetTaskDone(task: bins.id, time: hall.addingTimeInterval(3600)), at: hall.addingTimeInterval(3600))
        // 00:50 PDT to 01:20 PST is 90 minutes.
        try workout("Push Day B", start: hall.addingTimeInterval(-2400), sets: [(hall, 82.5, 8)],
                    end: hall.addingTimeInterval(-2400 + 5400))
        #expect(lines(Self.at(31, 12)) == ["00:50  Push Day B, 90 min. Bench 82.5 × 8.", "01:30  Note: hall light out",
                                           "01:30  Done: bins"])
    }

    @Test func columnAndVoiceOverForms() throws {
        // DL17, DL18.
        try workout("Push Day B", start: Self.at(21, 23, 20), sets: [(Self.at(22, 0, 40), 30, 10)],
                    end: Self.at(22, 0, 52))
        let line = try #require(DayStory.lines(store: store, classes: classes, records: engine.history(limit: 100),
                                               on: Self.at(21, 12), calendar: Self.calendar()).first)
        #expect(line.clock(Self.calendar()) == "23:20")
        #expect(line.spoken(Self.calendar()) == "11:20 pm, Push Day B, 92 minutes. Bench 30 by 10.")
    }

    // MARK: Copy (DL20 to DL60)

    @Test func looseThingsFoldIntoOneLineEach() throws {
        // DL25 to DL29.
        let list = try run(CreateList(name: "Lisbon packing"), at: Self.at(13, 13, 15)).output
        try task("a", at: Self.at(13, 8, 5))
        try task("b", at: Self.at(13, 8, 6))
        try run(AddGroceries(lines: ["milk", "eggs"]), at: Self.at(13, 8, 7))
        let items = try (0 ..< 2).map { index in
            try run(AddListItem(list: list.id, text: "item \(index)"), at: Self.at(13, 13, 20)).output
        }
        for item in items {
            try run(CheckListItem(item: item.id, time: Self.at(13, 18)), at: Self.at(13, 18))
        }
        try run(CreateNote(body: "gate B32, seat 14C"), at: Self.at(13, 14, 55))
        try run(CreateRecipe(text: "dal tadka\nIngredients\n1 cup toor dal\n2 tomatoes\nMethod\n1. Cook it 20 min."),
                at: Self.at(13, 10, 20))
        #expect(lines(Self.at(13, 12)) == [
            "08:05  Added 2 tasks, 2 groceries", "10:20  Saved dal tadka", "13:15  New list: Lisbon packing",
            "14:55  Note: gate B32, seat 14C", "18:00  Ticked 2 on Lisbon packing",
        ])
    }

    @Test func donesCountFromThree() throws {
        let titles = ["water the plants", "call mom", "pay rent", "bins", "post"]
        let tasks = try titles.map { try task($0, at: Self.at(10, 9)) }
        try run(SetTaskDone(task: tasks[0].id, time: Self.at(13, 8)), at: Self.at(13, 8))
        try run(SetTaskDone(task: tasks[1].id, time: Self.at(13, 8, 5)), at: Self.at(13, 8, 5))
        #expect(lines(Self.at(13, 12)) == ["08:00  Done: water the plants, call mom"])
        for task in tasks.dropFirst(2) {
            try run(SetTaskDone(task: task.id, time: Self.at(13, 9)), at: Self.at(13, 9))
        }
        #expect(lines(Self.at(13, 12)) == ["08:00  5 tasks done"])
    }

    @Test func moreThanSixKindsEndInOneAlsoLine() throws {
        // DL30, DL41: groups and own lines stay; the largest counts keep a line; the rest is the tail, no time.
        try workout("Pull Day A", start: Self.at(8, 6, 50), sets: [(Self.at(8, 7), 70, 10)], end: Self.at(8, 7, 51))
        let titles = ["a", "b", "c", "d"]
        let tasks = try titles.map { try task($0, at: Self.at(7, 9)) }
        for task in tasks {
            try run(SetTaskDone(task: task.id, time: Self.at(8, 8, 30)), at: Self.at(8, 8, 30))
        }
        for index in 0 ..< 7 {
            try task("new \(index)", at: Self.at(8, 9))
        }
        try run(AddGroceries(lines: ["milk", "eggs", "bread", "rice", "oats"]), at: Self.at(8, 9, 1))
        let list = try run(CreateList(name: "Lisbon packing"), at: Self.at(8, 13, 15)).output
        // Saved long ago (by the seed, here): only the cook shows.
        let recipe = try engine.perform(
            CreateRecipe(text: "omelette\nIngredients\n2 eggs\n1 tbsp butter\nMethod\n1. Cook 5 min."),
            by: .system
        ).output
        let cook = try run(StartCooking(recipe: recipe.id, time: Self.at(8, 17, 40)), at: Self.at(8, 17, 40)).output
        try run(FinishCooking(cook: cook.id, time: Self.at(8, 17, 50)), at: Self.at(8, 17, 50))
        for index in 0 ..< 3 {
            try run(CreateNote(body: "note \(index)"), at: Self.at(8, 20))
        }
        let items = try (0 ..< 4)
            .map { try run(AddListItem(list: list.id, text: "t\($0)"), at: Self.at(8, 13, 20)).output }
        for item in items {
            try run(CheckListItem(item: item.id, time: Self.at(8, 21)), at: Self.at(8, 21))
        }
        let day = lines(Self.at(8, 12))
        #expect(day.count == 6)
        #expect(day.last == "Also: 3 notes, ticked 4 on Lisbon packing.")
        #expect(day.contains("09:00  Added 7 tasks, 5 groceries") && day.contains("08:30  4 tasks done"))
    }

    @Test func restDayAndEmptyAndZeroSetDays() throws {
        // DL31, DL42 to DL44, DL51.
        #expect(lines(Self.at(11, 12), rest: true) == ["Rest day"])
        try task("a", at: Self.at(11, 9, 15))
        #expect(lines(Self.at(11, 12), rest: true) == ["Rest day", "09:15  Added 1 task"])
        try workout("Push Day A", start: Self.at(14, 18), sets: [], end: Self.at(14, 18, 5))
        #expect(lines(Self.at(14, 12)).isEmpty)
    }

    @Test func madeAndDeletedTheSameDayIsNothing() throws {
        // DL53 and rule 4: a task made and deleted the same day; undone records.
        let gone = try task("oops", at: Self.at(5, 9))
        try run(DeleteObject(object: gone.id), at: Self.at(5, 9, 5))
        let note = try run(CreateNote(body: "kept"), at: Self.at(5, 10)).record
        engine.undo(note)
        #expect(lines(Self.at(5, 12)).isEmpty)
    }

    @Test func everyLinePassesTheVoiceRules() throws {
        // DL40 over this file's busiest day.
        try moreThanSixKindsEndInOneAlsoLine()
        for line in lines(Self.at(8, 12)) {
            let words = line.split(separator: " ").count
            #expect(words < 14 && !line.contains("!") && !line.contains("—"), "\(line)")
            for banned in ["only", "missed", "not finished", "behind", "streak", "should", "again", "late", "great"] {
                #expect(!line.lowercased().contains(" \(banned)"), "\(line)")
            }
        }
    }

    @Test func everyActionHasAFoldRule() {
        // day-log-first.md "done when" 4: a new action without a rule fails here.
        let missing = ActionRegistry.descriptors.map(\.name).filter { !DayStory.hasRule(for: $0) }
        #expect(missing.isEmpty, "\(missing)")
    }
}
