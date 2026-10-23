import Foundation
@testable import TesseraCore
import Testing

/// Week facts (design sheet 159): next week's sentence per app, forward-looking, no scores, no amounts.
@MainActor
struct WeekFactsTests {
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

    /// October 2026: the 22nd is a Thursday, next week is Monday the 26th to Sunday the 1st.
    func at(_ hour: Int, _ minute: Int = 0, day: Int = 22, month: Int = 10) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
    }

    var now: Date {
        at(19, day: 25)
    }

    func lines(plan: ObjectRecord? = nil, routines: [RoutinesLanding.Item] = [],
               bills: [HomeSentence.MoneyDue] = []) -> [WeekFacts.NextLine]
    {
        WeekFacts.next(engine: engine, plan: plan, routines: routines, bills: bills, now: now, calendar: calendar)
    }

    func line(_ app: AppID, _ all: [WeekFacts.NextLine]) -> WeekFacts.NextLine? {
        all.first { $0.app == app }
    }

    func makePlan(_ names: [String]) throws -> ObjectRecord {
        let routines = try names.map { try engine.perform(CreateRoutine(title: $0), by: .user).output.id }
        return try engine.perform(CreatePlan(title: "Plan", routines: routines), by: .user).output
    }

    // MARK: Each app

    @Test func trainingNamesNextWeeksSessionsInRollingOrder() throws {
        let plan = try makePlan(["Push A", "Pull A", "Legs"])
        let training = try #require(line(.training, lines(plan: plan)))
        #expect(training.text == "Push A, Pull A and Legs next week.")
        #expect(training.opens == .app(.training))
    }

    @Test func kitchenNamesTheDishesAndOnlyCountsWhatIsToGet() throws {
        let tacos = try engine.perform(
            CreateRecipe(text: "Tacos\nIngredients\n1 onion\nMethod\n1. Cook it."),
            by: .user
        )
        .output
        let chili = try engine.perform(
            CreateRecipe(text: "Chili\nIngredients\n1 onion\nMethod\n1. Cook it."),
            by: .user
        )
        .output
        try engine.perform(CreateTask(title: "Cook tacos", startsAt: at(18, day: 27), about: [tacos.id]), by: .user)
        try engine.perform(CreateTask(title: "Cook chili", startsAt: at(18, day: 29), about: [chili.id]), by: .user)
        // This week's dish and one beyond next week say nothing here.
        try engine.perform(CreateTask(title: "Cook now", startsAt: at(18, day: 23), about: [chili.id]), by: .user)
        let kitchen = try #require(line(.kitchen, lines()))
        #expect(kitchen.text.hasPrefix("Tacos and Chili are planned"))
        #expect(kitchen.opens == .app(.kitchen))
        let toGet = KitchenLanding(store: store, classes: engine.classes).toGetCount()
        #expect(kitchen
            .text == (toGet > 0 ? "Tacos and Chili are planned, \(toGet) to get." : "Tacos and Chili are planned."))
        // One dish opens the dish.
        let solo = try engine.perform(CreateRecipe(text: "Soup\nIngredients\n1 onion\nMethod\n1. Cook it."), by: .user)
            .output
        try engine.perform(CreateTask(title: "Cook soup", startsAt: at(18, day: 28), about: [solo.id]), by: .user)
    }

    @Test func moneyGivesNamesAndWeekdaysNeverAnAmount() throws {
        let one = try #require(line(.money, lines(bills: [.init(name: "Rent", at: at(9, day: 30))])))
        #expect(one.text == "Rent is due Friday." && one.opens == .app(.money))
        let two = try #require(line(.money, lines(bills: [
            .init(name: "Phone", at: at(9, day: 31)),
            .init(name: "Rent", at: at(9, day: 30)),
        ])))
        #expect(two.text == "Rent is due Friday and Phone Saturday.")
        // A bill this week or the week after is not next week's.
        #expect(line(.money, lines(bills: [.init(name: "Gym", at: at(9, day: 24))])) == nil)
        #expect(line(.money, lines(bills: [.init(name: "Gym", at: at(9, day: 2, month: 11))])) == nil)
    }

    @Test func notesSayTheirFirstWaitingLineOrNothing() throws {
        #expect(line(.notes, lines()) == nil)
        try engine.perform(CreateNote(body: "Ask @Zebra about it"), by: .user)
        let notes = try #require(line(.notes, lines()))
        #expect(notes.text == "@Zebra is not a thing yet." && notes.opens == .app(.notes))
    }

    @Test func listsSayWhatIsDueNextWeekOrRunning() throws {
        let packing = try engine.perform(CreateList(name: "Packing"), by: .user).output
        try engine.perform(AddListItem(list: packing.id, text: "Passport"), by: .user)
        #expect(line(.lists, lines()) == nil)
        let item = try #require(ListContents(store: store, classes: engine.classes).open(in: packing).first)
        try store.set("notes", to: .richText("due: " + at(9, day: 30).formatted(.iso8601)), on: item.object)
        let lists = try #require(line(.lists, lines()))
        #expect(lists.text == "Packing is due Fri." && lists.opens == .object(packing.id))
        // Due this week: not next week's.
        try store.set("notes", to: .richText("due: " + at(9, day: 24).formatted(.iso8601)), on: item.object)
        #expect(line(.lists, lines()) == nil)
        try engine.perform(StartListRun(list: packing.id), by: .user)
        #expect(line(.lists, lines())?.text == "Packing is running, 1 left.")
    }

    @Test func routinesSayHowOftenTheyRunAsACountOfDays() {
        let runs = (1 ... 28).map { back in
            RoutineRun(start: at(6, 40, day: 25).addingTimeInterval(-86400 * Double(back)),
                       end: at(7, 2, day: 25).addingTimeInterval(-86400 * Double(back)))
        }
        let daily = RoutinesLanding.Item(name: "Morning", count: 6, runs: runs)
        #expect(line(.routines, lines(routines: [daily]))?.text == "Morning runs daily.")
        let some = RoutinesLanding.Item(name: "Stretch", count: 4, runs: Array(runs.filter {
            calendar.component(.weekday, from: $0.start) % 2 == 0
        }))
        let text = line(.routines, lines(routines: [some]))?.text
        #expect(text?.hasPrefix("Stretch runs about ") == true && text?.hasSuffix(" a week.") == true, "\(text ?? "")")
        // Fewer than seven runs: no usual, no line. A workout day belongs to Training.
        let few = RoutinesLanding.Item(name: "Evening", count: 3, runs: Array(runs.prefix(3)))
        let workout = RoutinesLanding.Item(name: "Push A", isWorkout: true, count: 5, runs: runs)
        #expect(line(.routines, lines(routines: [few, workout])) == nil)
    }

    // MARK: Nothing

    @Test func anAppWithNothingGivesNoLineAndAnEmptyWeekGivesNone() throws {
        #expect(lines().isEmpty)
        let plan = try makePlan(["Push A"])
        let all = lines(plan: plan, bills: [.init(name: "Rent", at: at(9, day: 30))])
        #expect(all.map(\.app) == [.training, .money])
    }

    // MARK: Privacy

    @Test func privateThingsReadTheirLabels() throws {
        let plan = try makePlan(["Knee rehab day"])
        #expect(line(.training, lines(plan: plan))?.text == "Private workout next week.")
        let secret = try engine.perform(
            CreateRecipe(text: "Lexapro cake\nIngredients\n1 egg\nMethod\n1. Bake."), by: .user
        ).output
        try engine.perform(CreateTask(title: "Bake it", startsAt: at(17, day: 28), about: [secret.id]), by: .user)
        #expect(line(.kitchen, lines())?.text.hasPrefix("Private recipe is planned") == true)
        let bills = [HomeSentence.MoneyDue(name: "Ozempic dose", at: at(9, day: 30))]
        #expect(line(.money, lines(bills: bills))?.text == "Private bill is due Friday.")
        // A bill name that carries digits or a currency sign could be an amount.
        let amount = [HomeSentence.MoneyDue(name: "Rent 1200", at: at(9, day: 30))]
        #expect(line(.money, lines(bills: amount))?.text == "Private bill is due Friday.")
        let list = try engine.perform(CreateList(name: "Lexapro refills"), by: .user).output
        try engine.perform(AddListItem(list: list.id, text: "Pick up"), by: .user)
        let item = try #require(ListContents(store: store, classes: engine.classes).open(in: list).first)
        try store.set("notes", to: .richText("due: " + at(9, day: 30).formatted(.iso8601)), on: item.object)
        #expect(line(.lists, lines())?.text == "Private list is due Fri.")
        let routine = RoutinesLanding.Item(name: "Ozempic shot", count: 2, isPrivate: true, runs: (1 ... 28).map {
            RoutineRun(start: at(6, 40, day: 25).addingTimeInterval(-86400 * Double($0)),
                       end: at(7, 0, day: 25).addingTimeInterval(-86400 * Double($0)))
        })
        #expect(line(.routines, lines(routines: [routine]))?.text == "Private routine runs daily.")
    }

    @Test func moneyLinesHaveNoCurrencySignAndNoDigits() throws {
        let bills = [
            HomeSentence.MoneyDue(name: "Rent", at: at(9, day: 30)), .init(name: "Phone $40", at: at(9, day: 27)),
            .init(name: "Gym", at: at(9, day: 28)), .init(name: "Water", at: at(9, day: 29)),
            .init(name: "Power", at: at(9, day: 31)),
        ]
        let money = try #require(line(.money, lines(bills: bills)))
        #expect(!money.text.contains(where: { $0.isNumber || $0.isCurrencySymbol }), "\(money.text)")
        #expect(money.text.hasSuffix(" and more."))
    }

    @Test func noLineHasAScoreAMissOrAComparison() throws {
        let plan = try makePlan(["Push A", "Pull A", "Legs"])
        let tacos = try engine.perform(
            CreateRecipe(text: "Tacos\nIngredients\n1 onion\nMethod\n1. Cook it."),
            by: .user
        )
        .output
        try engine.perform(CreateTask(title: "Cook tacos", startsAt: at(18, day: 27), about: [tacos.id]), by: .user)
        try engine.perform(CreateNote(body: "Ask @Zebra about it"), by: .user)
        let list = try engine.perform(CreateList(name: "Packing"), by: .user).output
        try engine.perform(AddListItem(list: list.id, text: "Passport"), by: .user)
        try engine.perform(StartListRun(list: list.id), by: .user)
        let runs = (1 ... 28).map { back in
            RoutineRun(start: at(6, 40, day: 25).addingTimeInterval(-86400 * Double(back)),
                       end: at(7, 2, day: 25).addingTimeInterval(-86400 * Double(back)))
        }
        let all = lines(plan: plan, routines: [.init(name: "Morning", count: 6, runs: runs)],
                        bills: [.init(name: "Rent", at: at(9, day: 30))])
        #expect(all.count == 6)
        let banned: Set = [
            "streak",
            "streaks",
            "missed",
            "miss",
            "misses",
            "behind",
            "late",
            "didn't",
            "didn’t",
            "didnt",
            "skipped",
            "overdue",
            "score",
            "scores",
            "lost",
            "broke",
            "worse",
            "better",
            "than",
            "last",
            "failed",
            "fell",
            "down",
        ]
        for entry in all {
            let words = entry.text.lowercased().split { !($0.isLetter || $0 == "'" || $0 == "’") }.map(String.init)
            #expect(banned.isDisjoint(with: words), "\(entry.text)")
            for health in ["calorie", "kcal", "weight", "body", "kg"] {
                #expect(!entry.text.lowercased().contains(health), "\(entry.text)")
            }
        }
    }

    // MARK: Window

    @Test func nextWeekIsMondayToSundayWithTheFourAMEdge() {
        // From any day of this week, next week starts Monday 04:00 and ends the Monday after, 04:00.
        for start in [at(10, day: 19), at(2, day: 20), at(3, 59, day: 26), at(23, day: 25)] {
            let week = WeekFacts.nextWeek(after: start, calendar: calendar)
            #expect(week.start == at(4, day: 26) && week.end == at(4, day: 2, month: 11), "\(start)")
        }
        // 03:59 on Monday the 26th is still Sunday's: this week; 04:00 is next week's.
        #expect(WeekFacts.nextWeek(after: at(3, 59, day: 26), calendar: calendar).start == at(4, day: 26))
        #expect(WeekFacts.nextWeek(after: at(4, day: 26), calendar: calendar).start == at(4, day: 2, month: 11))
    }

    @Test func aBillAtThreeInTheMorningMondayBelongsToTheWeekBefore() {
        let edge = [HomeSentence.MoneyDue(name: "Rent", at: at(3, 59, day: 26))]
        #expect(line(.money, lines(bills: edge)) == nil)
        let inside = [HomeSentence.MoneyDue(name: "Rent", at: at(4, day: 26))]
        #expect(line(.money, lines(bills: inside))?.text == "Rent is due Monday.")
        let last = [HomeSentence.MoneyDue(name: "Rent", at: at(3, 59, day: 2, month: 11))]
        #expect(line(.money, lines(bills: last))?.text == "Rent is due Sunday.")
        let after = [HomeSentence.MoneyDue(name: "Rent", at: at(4, day: 2, month: 11))]
        #expect(line(.money, lines(bills: after)) == nil)
    }

    // MARK: Nothing is sent

    @Test func tessNeverSeesWeekFacts() throws {
        let tess = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appendingPathComponent("Sources/TesseraTess")
        let files = try FileManager.default.contentsOfDirectory(at: tess, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "swift" }
        #expect(!files.isEmpty)
        for file in files {
            let text = try String(contentsOf: file, encoding: .utf8)
            #expect(!text.contains("WeekFacts"), "\(file.lastPathComponent)")
        }
    }
}
