import Foundation
@testable import TesseraCore
import Testing

/// Sheet 205: one plain line per app for Home's apps list. Words only; private things read "Private".
@MainActor
struct AppSummaryLinesTests {
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

    func lines(_ now: Date, plan: ObjectRecord? = nil, due: HomeSentence.MoneyDue? = nil,
               routines: HomeSentence.RoutinesPart? = nil) -> [AppSummaryApp: AppSummaryLine]
    {
        let all = AppSummaryLines.lines(engine: engine, plan: plan, moneyDue: due, routines: routines, now: now,
                                        calendar: calendar)
        return Dictionary(uniqueKeysWithValues: all.map { ($0.app, $0) })
    }

    @Test func everyAppAlwaysHasALineEvenOnAnEmptyPhone() {
        let all = AppSummaryLines.lines(engine: engine, plan: nil, now: at(12), calendar: calendar)
        #expect(all.map(\.app) == AppSummaryApp.allCases)
        #expect(all.allSatisfy { !$0.text.isEmpty && !$0.isPrivate })
        let byApp = lines(at(12))
        #expect(byApp[.training]?.text == "Nothing planned" && byApp[.tasks]?.text == "Nothing left today")
        #expect(byApp[.money]?.text == "Nothing is due" && byApp[.lists]?.text == "No lists yet")
        #expect(byApp[.notes]?.text == "No notes yet" && byApp[.routines]?.text == "Nothing planned")
    }

    @Test func tasksCountWhatIsLeftToday() throws {
        _ = try engine.perform(CreateTask(title: "Mail forms", due: at(15)), by: .user)
        let done = try engine.perform(CreateTask(title: "Call", due: at(16)), by: .user).output
        _ = try engine.perform(CreateTask(title: "Stamps", due: at(17)), by: .user)
        try engine.perform(SetTaskDone(task: done.id), by: .user)
        _ = try engine.perform(CreateTask(title: "Later", due: at(15, day: 25)), by: .user)
        #expect(lines(at(12))[.tasks]?.text == "2 left today")
    }

    @Test func kitchenSaysTheDishAndWhatIsToGet() throws {
        let recipe = try engine.perform(
            CreateRecipe(text: "Tacos\nIngredients\n1 onion\nMethod\n1. Fry it."), by: .user
        ).output
        let task = try engine.perform(CreateTask(title: "Cook tacos", startsAt: at(18)), by: .user).output
        try store.setLinks("about", on: task, to: [recipe])
        let line = try #require(lines(at(12))[.kitchen])
        #expect(line.text.hasPrefix("Tacos tonight") && line.opens == .object(recipe.id))
        let secret = try engine.perform(
            CreateRecipe(text: "Lexapro soup\nIngredients\n1 onion\nMethod\n1. Heat it."), by: .user
        ).output
        let second = try engine.perform(CreateTask(title: "Cook it", startsAt: at(17)), by: .user).output
        try store.setLinks("about", on: second, to: [secret])
        let hidden = try #require(lines(at(12))[.kitchen])
        #expect(hidden.isPrivate && hidden.text.hasPrefix("Private") && !hidden.text.lowercased().contains("lexapro"))
    }

    @Test func notesAndListsNameTheirTopItemOrSayPrivate() throws {
        _ = try engine.perform(CreateNote(body: "Trip packing\nsocks"), by: .user)
        let note = try #require(lines(at(12))[.notes])
        #expect(note.text.hasPrefix("Trip packing, edited at ") && !note.isPrivate)
        _ = try engine.perform(CreateNote(body: "Lexapro dose: 10 mg", isPrivate: true), by: .user)
        let priv = try #require(lines(.now.addingTimeInterval(5))[.notes])
        #expect(priv.text == "Private" && priv.isPrivate)
        let list = try store.create(#require(engine.classes[.list]), title: "Packing")
        for text in ["socks", "charger", "passport"] {
            _ = try engine.perform(AddListItem(list: list.id, text: text), by: .user)
        }
        let item = try #require(ListContents(store: store, classes: engine.classes).open(in: list).first)
        try engine.perform(CheckListItem(item: item.object.id), by: .user)
        let lead = try #require(lines(at(12))[.lists])
        #expect(lead.text == "Packing, 1 of 3 done" && lead.opens == .object(list.id))
    }

    @Test func moneyIsWordsOnlyAndAPrivateBillIsPrivate() {
        let rent = lines(at(12), due: .init(name: "Rent", at: at(9, day: 23)))[.money]
        #expect(rent?.text == "Rent is due Friday")
        #expect(rent?.text.contains(where: \.isNumber) == false)
        let hidden = lines(at(12), due: .init(name: "Lexapro copay", at: at(9, day: 23)))[.money]
        #expect(hidden?.text == "Private bill is due Friday" && hidden?.isPrivate == true)
    }

    @Test func trainingNamesTheRoutineItsTimeAndOpenerOrSaysPrivate() throws {
        let routine = try engine.perform(CreateRoutine(title: "Push A"), by: .user).output
        let plan = try engine.perform(CreatePlan(title: "PPL", routines: [routine.id]), by: .user).output
        let line = try #require(lines(at(9), plan: plan)[.training])
        #expect(line.text.hasPrefix("Push A") && !line.isPrivate)
        let secret = try engine.perform(CreateRoutine(title: "Knee rehab day"), by: .user).output
        let privatePlan = try engine.perform(CreatePlan(title: "Rehab", routines: [secret.id]), by: .user).output
        let hidden = try #require(lines(at(9), plan: privatePlan)[.training])
        #expect(hidden.text == "Private" && hidden.isPrivate)
    }

    @Test func routinesUseTheirOwnWordsAndTheirNextStart() {
        let runs = (1 ... 8).map { day in RoutineRun(start: at(20, day: 22 - day), end: at(20, 20, day: 22 - day)) }
        let facts = RoutinesLanding.facts(items: [.init(name: "Stretch", count: 4, runs: runs)], running: nil,
                                          now: at(12), calendar: calendar)
        let part = HomeSentence.RoutinesPart(facts: facts, nextUsualStart: at(20))
        let line = lines(at(12), routines: part)[.routines]
        #expect(line?.text == "Stretch at 8 pm")
        let privateFacts = RoutinesLanding.facts(
            items: [.init(name: "Knee rehab", count: 4, isPrivate: true, runs: runs)],
            running: nil,
            now: at(12),
            calendar: calendar
        )
        let hidden = lines(at(12), routines: .init(facts: privateFacts, nextUsualStart: at(20)))[.routines]
        #expect(hidden?.isPrivate == true && hidden?.text.hasPrefix("Private") == true)
    }

    @Test func trainingWithHistorySaysItsUsualStart() throws {
        let routine = try engine.perform(CreateRoutine(title: "Push A"), by: .user).output
        let plan = try engine.perform(CreatePlan(title: "PPL", routines: [routine.id]), by: .user).output
        try ExerciseLibraryInstaller.install(shape: ExerciseLibraryInstaller.chosenShape, store: store,
                                             classes: engine.classes)
        let bench = try #require(store.allClasses().first { $0.name == "Bench Press" })
        try engine.perform(AddSlot(routine: routine.id, exercise: bench.id), by: .user)
        for week in 1 ... 3 {
            let workout = try store.create(#require(engine.classes[.workout]), title: "Push A")
            try store.setLinks("routine", on: workout, to: [routine])
            try store.set("endedAt", to: .date(at(19, day: 22 - week)), on: workout)
            let entry = try store.create(#require(engine.classes[.exerciseEntry]), parent: workout)
            try store.setClassLink("exercise", on: entry, to: bench)
            let ledger = TrainingLedger(store: store, classes: engine.classes)
            let first = try ledger.logSet(weight: 80, reps: 5, in: entry)
            let last = try ledger.logSet(weight: 80, reps: 5, in: entry)
            try store.set("loggedAt", to: .date(at(18, 15, day: 22 - week)), on: first)
            try store.set("loggedAt", to: .date(at(19, day: 22 - week)), on: last)
        }
        let line = try #require(lines(at(9), plan: plan)[.training])
        // The opener ("bench press first") joins the line when the landing facts have one (TrainingLanding tests).
        #expect(line.text == "Push A at 6:15 pm", "\(line.text)")
    }
}
