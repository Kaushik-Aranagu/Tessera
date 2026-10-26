import Foundation
@testable import TesseraCore
import Testing

/// Round 5 Describe: one sentence per class, a short story per object, nothing private or numeric-by-guess.
@MainActor
struct DescribeTests {
    static var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    /// October 2026, UTC. The 20th is a Tuesday.
    static func at(_ day: Int, _ hour: Int = 12) -> Date {
        utc.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour))!
    }

    static let now = at(30)

    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine

    init() throws {
        classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
    }

    @discardableResult
    func run<A: EngineAction>(_ action: A, at time: Date) throws -> A.Output {
        let result = try engine.perform(action, by: .user)
        result.record.createdAt = time
        return result.output
    }

    func sentence(_ object: ObjectRecord) -> String? {
        Describe.sentence(object, in: store, classes: classes, calendar: Self.utc)
    }

    func story(_ object: ObjectRecord) -> [String] {
        Describe.story(object, engine: engine, calendar: Self.utc, now: Self.now).map(\.text)
    }

    func make(_ key: SystemCatalog.Key, _ title: String, parent: ObjectRecord? = nil) throws -> ObjectRecord {
        try store.create(#require(classes[key]), title: title, parent: parent)
    }

    // MARK: Sentences

    @Test func taskSentences() throws {
        let due = try run(CreateTask(title: "Pay rent bill!", due: Self.at(23)), at: Self.at(20))
        #expect(sentence(due) == "Pay rent bill, due Friday")
        let open = try run(CreateTask(title: "Water plants"), at: Self.at(20))
        #expect(sentence(open) == "Water plants, still to do")
        try run(SetTaskDone(task: open.id), at: Self.at(21))
        #expect(sentence(open) == "Water plants, done")
        let planned = try run(CreateTask(title: "Call Sam", startsAt: Self.at(22)), at: Self.at(20))
        #expect(sentence(planned) == "Call Sam, due Thursday")
    }

    @Test func workoutSentences() throws {
        let planned = try make(.workout, "Push Day")
        #expect(sentence(planned) == "Push Day, planned")
        try run(StartWorkout(workout: planned.id, time: Self.at(20, 9)), at: Self.at(20, 9))
        #expect(sentence(planned) == "Push Day, under way")
        let entry = try run(AddExercise(workout: planned.id, exercise: #require(classes[.benchPress]).id),
                            at: Self.at(20, 9))
        for index in 0 ..< 3 {
            try run(LogSet(entry: entry.id, weight: 60, reps: 8, time: Self.at(20, 9 + index)), at: Self.at(20, 9))
        }
        try run(LogSet(entry: entry.id, weight: 20, reps: 10, kind: .warmup, time: Self.at(20, 9)),
                at: Self.at(20, 9))
        try run(FinishWorkout(workout: planned.id, time: Self.at(20, 10)), at: Self.at(20, 10))
        #expect(sentence(planned) == "Push Day, 1 exercise, 3 sets")
    }

    @Test func listItemSentences() throws {
        let list = try make(.list, "Groceries")
        let milk = try run(AddListItem(list: list.id, text: "Milk"), at: Self.at(20))
        #expect(sentence(milk) == "Milk on Groceries")
        try run(CheckListItem(item: milk.id), at: Self.at(21))
        #expect(sentence(milk) == "Milk on Groceries, done")
    }

    @Test func recipeSentences() throws {
        let recipe = try make(.recipe, "Tacos")
        #expect(sentence(recipe) == "Tacos")
        try store.set("serves", to: .number(4), on: recipe)
        #expect(sentence(recipe) == "Tacos, serves 4")
        try store.set("totalMinutes", to: .number(90), on: recipe)
        #expect(sentence(recipe) == "Tacos, serves 4, 1 hr 30 min")
        let quick = try make(.recipe, "Toast")
        try store.set("totalMinutes", to: .number(5), on: quick)
        #expect(sentence(quick) == "Toast, 5 min")
    }

    @Test func noExclamationOrEmDash() throws {
        let task = try make(.task, "Big day! \u{2014} go")
        let text = try #require(sentence(task))
        #expect(!text.contains("!") && !text.contains("\u{2014}"))
    }

    @Test func aWorkoutOfAPrivateRoutineIsPrivateEvenWithAPlainTitle() throws {
        let routine = try make(.routine, "Knee rehab day")
        let workout = try make(.workout, "Session")
        try store.setLinks("routine", on: workout, to: [routine])
        let text = try #require(sentence(workout))
        #expect(text == "Private workout" && !text.contains("Knee"))
        try store.set("endedAt", to: .date(Date()), on: workout)
        #expect(sentence(workout) == "Private workout")
        // Its story is empty and the name never prints.
        #expect(Describe.sentence(routine, in: store, classes: engine.classes) == "Private workout")
    }

    @Test func aWorkoutOfAPrivateRoutineHasNoStoryLinesOnlyACount() throws {
        let routine = try make(.routine, "Knee rehab day")
        let secret = try make(.workout, "Session")
        try store.setLinks("routine", on: secret, to: [routine])
        try engine.perform(RenameObject(object: secret.id, title: "Session two"), by: .user)
        #expect(story(secret).isEmpty)
        #expect(Describe.storyCount(secret, engine: engine) >= 1)
    }

    @Test func otherClassesGiveNil() throws {
        #expect(try sentence(make(.place, "Fridge")) == nil)
        #expect(try sentence(make(.note, "plain note")) == nil)
    }

    @Test func privateObjectsGiveExactlyTheirLabel() throws {
        #expect(try sentence(make(.task, "Lexapro refill")) == "Private task")
        #expect(try sentence(make(.recipe, "Lexapro cake")) == "Private recipe")
        #expect(try sentence(make(.workout, "Lexapro day")) == "Private workout")
        let list = try make(.list, "Therapy list")
        let item = try make(.listItem, "Milk", parent: list)
        #expect(sentence(item) == "Private item")
        let note = try make(.note, "x")
        try store.set("isPrivate", to: .bool(true), on: note)
        #expect(sentence(note) == "Private note")
        #expect(sentence(list) == "Private list")
    }

    @Test func moneyAndBodyGiveNil() throws {
        #expect(try sentence(make(.spend, "Coffee")) == nil)
        #expect(try sentence(make(.meProfile, "Me")) == nil)
        #expect(try sentence(make(.pool, "Savings")) == nil)
        #expect(try story(make(.spend, "Coffee")).isEmpty)
        #expect(try Describe.storyCount(make(.spend, "Coffee"), engine: engine) == 0)
    }

    // MARK: Stories

    @Test func storyLinesForEachKindOfChange() throws {
        let task = try run(CreateTask(title: "Mail forms"), at: Self.at(20))
        try run(RenameObject(object: task.id, title: "Post letters"), at: Self.at(21))
        try run(MoveTask(task: task.id, to: Self.at(23)), at: Self.at(22))
        try run(SetTaskDone(task: task.id), at: Self.at(23))
        try run(DeleteObject(object: task.id), at: Self.at(24))
        let lines = Describe.story(task, engine: engine, calendar: Self.utc, now: Self.now)
        #expect(lines.map(\.text) == ["Deleted", "Done Friday", "Moved to Friday", "Renamed Wednesday",
                                      "Made Tuesday"])
        #expect(lines.first?.time == Self.at(24))
    }

    @Test func checkedOffItemAndSameDayWord() throws {
        let list = try make(.list, "Groceries")
        let milk = try run(AddListItem(list: list.id, text: "Milk"), at: Self.at(30, 9))
        try run(CheckListItem(item: milk.id), at: Self.at(30, 13))
        #expect(story(milk) == ["Checked off today", "Made today"])
    }

    @Test func linkLineNamesTheThingAndMasksPrivate() throws {
        let recipe = try make(.recipe, "Tacos")
        let secret = try make(.recipe, "Lexapro cake")
        let plain = try run(CreateTask(title: "Shop", about: [recipe.id]), at: Self.at(20))
        let hidden = try run(CreateTask(title: "Bake", about: [secret.id]), at: Self.at(20))
        #expect(story(plain) == ["Linked to Tacos", "Made Tuesday"])
        #expect(story(hidden) == ["Linked to something private", "Made Tuesday"])
        #expect(!story(hidden).joined().contains("Lexapro"))
    }

    @Test func storyIsCappedAtEight() throws {
        let task = try run(CreateTask(title: "Move me"), at: Self.at(1))
        for day in 2 ... 14 {
            try run(MoveTask(task: task.id, to: Self.at(day)), at: Self.at(day))
        }
        #expect(story(task).count == 8)
        #expect(Describe.storyCount(task, engine: engine) == 14)
    }

    @Test func privateObjectHasNoLinesButACount() throws {
        let task = try run(CreateTask(title: "Water plants"), at: Self.at(20))
        try run(SetTaskDone(task: task.id), at: Self.at(21))
        try run(RenameObject(object: task.id, title: "Lexapro refill"), at: Self.at(22))
        #expect(story(task).isEmpty)
        #expect(Describe.storyCount(task, engine: engine) == 3)
        #expect(sentence(task) == "Private task")
    }

    @Test func noTextValueIsEchoed() throws {
        let task = try run(CreateTask(title: "Alpha"), at: Self.at(20))
        try run(RenameObject(object: task.id, title: "Bravo"), at: Self.at(21))
        let text = story(task).joined(separator: " ")
        #expect(!text.contains("Alpha") && !text.contains("Bravo"))
        #expect(text.contains("Renamed"))
    }

    // MARK: Claude never sees it

    @Test func tessSourcesDoNotMentionDescribe() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appendingPathComponent("Sources/TesseraTess")
        let files = try #require(FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil))
        var scanned = 0
        for case let url as URL in files where url.pathExtension == "swift" {
            scanned += 1
            let text = try String(contentsOf: url, encoding: .utf8)
            #expect(!text.contains("Describe"), "\(url.lastPathComponent) mentions Describe")
        }
        #expect(scanned > 0)
    }
}
