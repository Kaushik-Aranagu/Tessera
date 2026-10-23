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

    @Test func appsReadFromThePhoneAlwaysHaveALineAndMoneyAndRoutinesOnlyWhenTheirSourceWasRead() {
        let all = AppSummaryLines.lines(engine: engine, plan: nil, now: at(12), calendar: calendar)
        // Without a bills source or a routines read, the list says nothing about them: no false "Nothing is due".
        #expect(all.map(\.app) == [.training, .kitchen, .tasks, .notes, .lists])
        #expect(all.allSatisfy { !$0.text.isEmpty && !$0.isPrivate })
        let byApp = lines(at(12))
        #expect(byApp[.training]?.text == "Nothing planned" && byApp[.tasks]?.text == "Nothing left today")
        #expect(byApp[.lists]?.text == "No lists yet" && byApp[.notes]?.text == "No notes yet")
        #expect(byApp[.money] == nil && byApp[.routines] == nil)
    }

    @Test func theLoadersReadRoutinesFromThePhoneAndMoneyHasNoSourceYet() throws {
        #expect(HomeSentence.MoneyDue.next(engine: engine, now: at(12)) == nil)
        // The starter plan's routines are real routines: the line names one, with no start time to promise yet.
        let starter = HomeSentence.RoutinesPart.make(engine: engine, now: at(12), calendar: calendar)
        #expect(starter.nextUsualStart == nil && lines(at(12), routines: starter)[.routines]?.text.isEmpty == false)
        let routine = try engine.perform(CreateRoutine(title: "Stretch"), by: .user).output
        for day in 1 ... 8 {
            let workout = try store.create(#require(engine.classes[.workout]), title: "Stretch")
            try store.setLinks("routine", on: workout, to: [routine])
            try store.set("startedAt", to: .date(at(20, day: 22 - day)), on: workout)
            try store.set("endedAt", to: .date(at(20, 20, day: 22 - day)), on: workout)
        }
        let part = HomeSentence.RoutinesPart.make(engine: engine, now: at(12), calendar: calendar)
        #expect(part.nextUsualStart == at(20))
        #expect(lines(at(12), routines: part)[.routines]?.text == "Stretch at 8 pm")
        // Run this morning: no next start to promise today.
        let workoutClass = try #require(engine.classes[.workout])
        let today = try store.create(workoutClass, title: "Stretch")
        try store.setLinks("routine", on: today, to: [routine])
        try store.set("startedAt", to: .date(at(8)), on: today)
        try store.set("endedAt", to: .date(at(8, 20)), on: today)
        #expect(HomeSentence.RoutinesPart.make(engine: engine, now: at(12), calendar: calendar).nextUsualStart == nil)
        let secret = try engine.perform(CreateRoutine(title: "Lexapro morning"), by: .user).output
        let masked = HomeSentence.RoutinesPart.make(engine: engine, now: at(12), calendar: calendar)
        #expect(!masked.facts.lines.joined().lowercased().contains("lexapro"))
        _ = secret
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

    // MARK: QA on #1323

    @Test func aNoteWithNoTitleIsCheckedWholeBeforeItIsCutAtAWordEdge() throws {
        _ = try engine.perform(
            CreateNote(body: "Remember to pick up the dry cleaning before the weekend starts"),
            by: .user
        )
        let plain = try #require(lines(at(12))[.notes])
        // Cut at 30 characters on a word edge: the word that would be split is dropped.
        #expect(plain.text.hasPrefix("Remember to pick up the dry, edited at "), "\(plain.text)")
        // The private word sits past where a cut would have been: the whole body is checked first.
        _ = try engine.perform(
            CreateNote(body: "Remember to pick up the dry cleaning and the Lexapro refill on Friday"), by: .user
        )
        let hidden = try #require(lines(.now.addingTimeInterval(5))[.notes])
        #expect(hidden.text == "Private" && hidden.isPrivate)
    }

    @Test func aBillWithADigitInItsNameSaysOnlyThatABillIsDue() {
        for name in ["Rent 1850", "Visa ending 4417", "Gym 2"] {
            let line = lines(at(12), due: .init(name: name, at: at(9, day: 23)))[.money]
            #expect(line?.text == "A bill is due Friday", "\(name)")
        }
    }

    @Test func aRoutineNameIsMaskedByTheMaskResultNotAStringTest() {
        let runs = (1 ... 8).map { day in RoutineRun(start: at(20, day: 22 - day), end: at(20, 20, day: 22 - day)) }
        func line(_ name: String, isPrivate: Bool = false) -> AppSummaryLine? {
            let facts = RoutinesLanding.facts(items: [.init(name: name, count: 4, isPrivate: isPrivate, runs: runs)],
                                              running: nil, now: at(12), calendar: calendar)
            return lines(at(12), routines: .init(facts: facts, nextUsualStart: at(20)))[.routines]
        }
        // A real name that merely starts with "Private" is checked like any other (and a plain one passes).
        #expect(line("Private yoga")?.isPrivate == true)
        #expect(line("Lexapro morning")?.isPrivate == true && line("Lexapro morning")?.text == "Private")
        #expect(line("Stretch")?.text == "Stretch at 8 pm" && line("Stretch")?.isPrivate == false)
        #expect(line("Knee rehab", isPrivate: true)?.text == "Private")
    }

    @Test func aListWithAPrivateWordIsPrivate() throws {
        let list = try store.create(#require(engine.classes[.list]), title: "Lexapro refills")
        _ = try engine.perform(AddListItem(list: list.id, text: "pharmacy"), by: .user)
        let line = try #require(lines(at(12))[.lists])
        #expect(line.text == "Private" && line.isPrivate)
    }

    @Test func trainingSaysWhatItOpensWith() throws {
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
        #expect(line.text == "Push A at 6:15 pm, bench press first", "\(line.text)")
    }

    // MARK: Opener and running routines, masked

    /// A plan whose routine opens with `exercise`, with three past sessions of it.
    private func plan(opening exercise: ClassDef) throws -> ObjectRecord {
        let routine = try engine.perform(CreateRoutine(title: "Push A"), by: .user).output
        let plan = try engine.perform(CreatePlan(title: "PPL", routines: [routine.id]), by: .user).output
        try engine.perform(AddSlot(routine: routine.id, exercise: exercise.id), by: .user)
        for week in 1 ... 3 {
            let workout = try store.create(#require(engine.classes[.workout]), title: "Push A")
            try store.setLinks("routine", on: workout, to: [routine])
            try store.set("endedAt", to: .date(at(19, day: 22 - week)), on: workout)
            let entry = try store.create(#require(engine.classes[.exerciseEntry]), parent: workout)
            try store.setClassLink("exercise", on: entry, to: exercise)
            let ledger = TrainingLedger(store: store, classes: engine.classes)
            let first = try ledger.logSet(weight: 80, reps: 5, in: entry)
            let last = try ledger.logSet(weight: 80, reps: 5, in: entry)
            try store.set("loggedAt", to: .date(at(18, 15, day: 22 - week)), on: first)
            try store.set("loggedAt", to: .date(at(19, day: 22 - week)), on: last)
        }
        return plan
    }

    @Test func homesTrainingSentenceNamesAPlainLiftAndLeavesAPrivateOneOut() throws {
        try ExerciseLibraryInstaller.install(shape: ExerciseLibraryInstaller.chosenShape, store: store,
                                             classes: engine.classes)
        let bench = try #require(store.allClasses().first { $0.name == "Bench Press" })
        let plain = try HomeSentence.inputs(engine: engine, plan: plan(opening: bench), now: at(9), calendar: calendar)
        #expect(plain.training?.text.contains("Bench Press opens at") == true, "\(plain.training?.text ?? "-")")
    }

    @Test func aLiftWithAPrivateWordInItsNameNeverReachesTheSentenceOrTheList() throws {
        try ExerciseLibraryInstaller.install(shape: ExerciseLibraryInstaller.chosenShape, store: store,
                                             classes: engine.classes)
        let bench = try #require(store.allClasses().first { $0.name == "Bench Press" })
        let secret = store.createClass(name: "Lexapro press", parent: bench)
        let hiddenPlan = try plan(opening: secret)
        let sentence = HomeSentence.inputs(engine: engine, plan: hiddenPlan, now: at(9), calendar: calendar)
        let text = try #require(sentence.training?.text)
        #expect(text.hasPrefix("Push A") && !text.lowercased().contains("lexapro"), "\(text)")
        let line = try #require(lines(at(9), plan: hiddenPlan)[.training])
        #expect(!line.text.lowercased().contains("lexapro") && line.text.hasPrefix("Push A"), "\(line.text)")
    }

    @Test func aRunningRoutineWithNoKeyWordHasItsWholeSentenceChecked() {
        func line(_ text: String, key: String?) -> AppSummaryLine? {
            let top = RoutinesLanding.Top(sentence: LandingSentence(text: text, key: key), step: "Shoes on",
                                          onThisStep: nil, starts: [])
            let facts = RoutinesLanding.Facts(subtitle: LandingSentence(text: "", key: nil), top: top, lines: [])
            return lines(at(12), routines: .init(facts: facts, nextUsualStart: nil))[.routines]
        }
        #expect(line("Lexapro morning is running", key: nil)?.text == "Private")
        #expect(line("Lexapro morning is running", key: nil)?.isPrivate == true)
        #expect(line("Morning is running", key: "Morning")?.text == "Morning is running")
        #expect(line("Morning is running", key: nil)?.isPrivate == false)
    }
}
