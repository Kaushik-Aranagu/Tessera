import Foundation
@testable import TesseraCore
import Testing

/// Together piece 1: Home's day sentence and the past one (sheets 135 and 139).
@MainActor
struct HomeSentenceTests {
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

    func clause(_ app: AppID, _ text: String, key: String? = nil, time: Date? = nil, since: Date? = nil) -> HomeSentence
        .Clause
    {
        HomeSentence.Clause(
            app: app,
            sentence: LandingSentence(text: text, key: key),
            opens: .app(app),
            time: time,
            since: since
        )
    }

    // MARK: Compose

    @Test func clausesGoByClockTimeAndTheUntimedGoLast() {
        let inputs = HomeSentence.Inputs(
            training: clause(.training, "Push A today.", time: at(18)),
            kitchen: clause(.kitchen, "Tacos tonight.", time: at(17, 30)),
            money: clause(.money, "Rent is due Friday.", time: at(9)),
            notes: clause(.notes, "A new loose note.", since: at(8))
        )
        let clauses = HomeSentence.compose(inputs)
        #expect(clauses.map(\.app) == [.money, .kitchen, .training, .notes])
        #expect(HomeSentence.text(clauses) == "Rent is due Friday. Tacos tonight. Push A today. A new loose note.")
    }

    @Test func atMostFourAndTheOldestUntimedGoFirst() {
        let inputs = HomeSentence.Inputs(
            training: clause(.training, "T.", time: at(18)), kitchen: clause(.kitchen, "K.", time: at(17)),
            notes: clause(.notes, "N.", since: at(7)), lists: clause(.lists, "L.", since: at(8)),
            routines: clause(.routines, "R.", time: at(6))
        )
        let clauses = HomeSentence.compose(inputs)
        #expect(clauses.count == 4)
        // Six... five clauses, one too many: the oldest untimed (the note) goes.
        #expect(clauses.map(\.app) == [.routines, .kitchen, .training, .lists])
    }

    @Test func nothingFromAnyAppIsAQuietDay() {
        #expect(HomeSentence.compose(HomeSentence.Inputs()).isEmpty)
        #expect(HomeSentence.text([]) == "A quiet day.")
    }

    @Test func theKeyWordIsOffsetsIntoTheText() throws {
        let one = clause(.money, "Rent is due Friday.", key: "Rent")
        let range = try #require(one.keyWord)
        #expect(range == 0 ..< 4)
        let late = clause(.kitchen, "Tacos tonight, start at 6:05 pm.", key: "Tacos")
        #expect(late.keyWord == 0 ..< 5)
        #expect(clause(.notes, "Nothing.").keyWord == nil)
    }

    // MARK: Gathering

    @Test func moneySaysDueWordsOnlyAndNeverAnAmount() {
        let inputs = HomeSentence.inputs(engine: engine, plan: nil, moneyDue: .init(name: "Rent", at: at(9, day: 23)),
                                         now: at(8), calendar: calendar)
        let money = inputs.money
        #expect(money?.text == "Rent is due Friday." && money?.time == at(9, day: 23))
        #expect(money?.text.contains(where: \.isNumber) == false)
        let walled = HomeSentence.inputs(
            engine: engine,
            plan: nil,
            moneyDue: .init(name: "Ozempic dose", at: at(9, day: 23)),
            now: at(8),
            calendar: calendar
        )
        #expect(walled.money?.text == "Private bill is due Friday.")
    }

    @Test func aDishPlannedForTonightSaysTacosAndTheStart() throws {
        let tacos = try engine
            .perform(CreateRecipe(text: "Tacos\nIngredients\n1 onion\nMethod\n1. Cook it."), by: .user).output
        try engine.perform(CreateTask(title: "Cook tacos", startsAt: at(18, 5), about: [tacos.id]), by: .user)
        let inputs = HomeSentence.inputs(engine: engine, plan: nil, now: at(12), calendar: calendar)
        let kitchen = try #require(inputs.kitchen)
        #expect(kitchen.text == "Tacos tonight, start at \(HouseTime.clock(at(18, 5), calendar: calendar)).")
        #expect(kitchen.time == at(18, 5) && kitchen.keyWord == 0 ..< 5)
        // A private recipe reads Private recipe, never its words.
        let secret = try engine.perform(
            CreateRecipe(text: "Lexapro cake\nIngredients\n1 egg\nMethod\n1. Bake."),
            by: .user
        ).output
        try engine.perform(CreateTask(title: "Bake it", startsAt: at(17), about: [secret.id]), by: .user)
        let both = HomeSentence.inputs(engine: engine, plan: nil, now: at(12), calendar: calendar)
        #expect(both.kitchen?.text.hasPrefix("Private recipe tonight") == true)
        #expect(both.kitchen?.text.contains("Lexapro") == false)
    }

    @Test func aPlannedCookSessionSaysItsOwnLandingLine() throws {
        let one = try engine.perform(
            CreateRecipe(text: "Chicken\nIngredients\n1 onion\nMethod\n1. Bake for 33 minutes."),
            by: .user
        ).output
        let two = try engine.perform(
            CreateRecipe(text: "Rice\nIngredients\n1 cup rice\nMethod\n1. Boil for 12 minutes."),
            by: .user
        ).output
        try engine.perform(StartCookSession(recipes: [one.id, two.id], serveAt: at(19), time: at(12)), by: .user)
        let kitchen = try #require(HomeSentence.inputs(engine: engine, plan: nil, now: at(12), calendar: calendar)
            .kitchen)
        #expect(kitchen.text.hasPrefix("Chicken and Rice tonight, start at "))
        #expect(kitchen.time != nil)
    }

    @Test func trainingSaysTodaysRoutineAtItsUsualStartAndMasksAPrivateOne() throws {
        let routine = try engine.perform(CreateRoutine(title: "Push A"), by: .user).output
        let plan = try engine.perform(CreatePlan(title: "PPL", routines: [routine.id]), by: .user).output
        // Three past workouts of it, each first set at 18:10.
        for week in 1 ... 3 {
            let workout = try store.create(#require(engine.classes[.workout]), title: "Push A")
            try store.setLinks("routine", on: workout, to: [routine])
            try store.set("endedAt", to: .date(at(19, day: 22 - week)), on: workout)
            let entry = try store.create(#require(engine.classes[.exerciseEntry]), parent: workout)
            try store.setClassLink("exercise", on: entry, to: #require(engine.classes[.benchPress]))
            let set = try TrainingLedger(store: store, classes: engine.classes).logSet(weight: 80, reps: 5, in: entry)
            try store.set("loggedAt", to: .date(at(18, 10, day: 22 - week)), on: set)
        }
        let inputs = HomeSentence.inputs(engine: engine, plan: plan, now: at(9), calendar: calendar)
        let training = try #require(inputs.training)
        #expect(training.text.hasPrefix("Push A today"))
        #expect(training.time == at(18, 10) && training.keyWord == 0 ..< 6)
        // Private: the routine is walled, the clause reads Private workout, with no start learned from it.
        let secret = try engine.perform(CreateRoutine(title: "Knee rehab day"), by: .user).output
        let walled = try engine.perform(CreatePlan(title: "Rehab", routines: [secret.id]), by: .user).output
        let hidden = HomeSentence.inputs(engine: engine, plan: walled, now: at(9), calendar: calendar).training
        #expect(hidden?.text.hasPrefix("Private workout today") == true && hidden?.time == nil)
        #expect(hidden?.text.contains("Knee") == false)
    }

    @Test func notesAndListsSayWhatIsWaitingOrRunningAndStayQuietOtherwise() throws {
        #expect(HomeSentence.inputs(engine: engine, plan: nil, now: at(12), calendar: calendar).notes == nil)
        try engine.perform(CreateNote(body: "Ask @Zebra about it"), by: .user)
        let notes = try #require(HomeSentence.inputs(engine: engine, plan: nil, now: at(12), calendar: calendar).notes)
        #expect(notes.text == "@Zebra is not a thing yet." && notes.time == nil && notes.since != nil)
        let packing = try engine.perform(CreateList(name: "Packing"), by: .user).output
        for item in ["Socks", "Charger"] {
            try engine.perform(AddListItem(list: packing.id, text: item), by: .user)
        }
        // Only touched last: filler, no clause.
        #expect(HomeSentence.inputs(engine: engine, plan: nil, now: at(12), calendar: calendar).lists == nil)
        try engine.perform(StartListRun(list: packing.id), by: .user)
        let lists = try #require(HomeSentence.inputs(engine: engine, plan: nil, now: at(12), calendar: calendar).lists)
        #expect(lists.text == "Packing is running, 2 left." && lists.opens == .object(packing.id))
    }

    @Test func routinesSayWhatIsRunningOrTheFirstLineAtItsUsualStart() {
        let facts = RoutinesLanding.facts(
            items: [.init(name: "Morning", count: 6)],
            running: nil,
            now: at(6),
            calendar: calendar
        )
        let part = HomeSentence.RoutinesPart(facts: facts, nextUsualStart: at(6, 40))
        let quiet = HomeSentence.inputs(engine: engine, plan: nil, routines: part, now: at(6), calendar: calendar)
        #expect(quiet.routines?.text == "Morning, 6 steps." && quiet.routines?.time == at(6, 40))
        let live = RoutinesLanding.facts(items: [.init(name: "Morning", count: 6)],
                                         running: .init(name: "Morning", step: "Shoes on", secondsOnStep: 60), now: at(
                                             6,
                                             41
                                         ), calendar: calendar)
        let running = HomeSentence.inputs(
            engine: engine,
            plan: nil,
            routines: .init(facts: live),
            now: at(6, 41),
            calendar: calendar
        )
        #expect(running.routines?.text == "Morning is running" || running.routines?.text == "Morning is running.")
    }

    // MARK: Past

    @Test func aPastDayIsBuiltFromTheDayLogWithMoneyAsWordsOnly() throws {
        try engine.perform(LogSpend(amount: 1200, typed: "1200", note: "rent", spentAt: at(10, day: 20)), by: .user)
        try engine.perform(CreateNote(body: "Called @Nobody"), by: .user)
        let clauses = HomeSentence.past(engine: engine, on: at(12, day: 20), calendar: calendar, now: at(12))
        let text = HomeSentence.text(clauses)
        #expect(text.contains("Rent paid.") || text == HomeSentence.quietDay, "\(text)")
        #expect(!text.contains("1200") && !text.contains("$"))
        #expect(HomeSentence.past(engine: engine, on: at(12, day: 3), calendar: calendar, now: at(12)).isEmpty)
    }
}
