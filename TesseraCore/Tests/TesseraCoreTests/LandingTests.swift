import Foundation
@testable import TesseraCore
import Testing

/// The landing pages' sentences and counts (design/landing-pages-131.md): fixed templates, computed on the phone.
@MainActor
struct LandingTests {
    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar
    }

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    func at(_ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
    }

    // MARK: Templates

    @Test func trainingSentenceHoldsTheOneNumberInsideIt() {
        let full = LandingSentences.training(session: "Push A", minutes: 45, opener: ("Bench", "82.5"))
        #expect(full.text == "Push A today, about 45 min. Bench opens at 82.5." && full.key == "Push A")
        #expect(LandingSentences.training(session: "Push A", minutes: nil, opener: nil).text == "Push A today.")
        #expect(LandingSentences.training(session: "Push A", minutes: 45, opener: nil).text
            == "Push A today, about 45 min.")
        #expect(LandingSentences.training(session: nil, minutes: nil, opener: nil).text == "Nothing planned today.")
    }

    @Test func kitchenSentenceAndTheCookingLine() {
        let full = LandingSentences.kitchen(dish: "Tacos", start: "6:05", shortOf: "Lemon")
        #expect(full.text == "Tacos tonight, start at 6:05. Lemon is short." && full.key == "Tacos")
        #expect(LandingSentences.kitchen(dish: "Tacos", start: nil, shortOf: nil).text == "Tacos tonight.")
        #expect(LandingSentences.kitchen(dish: nil, start: nil, shortOf: nil).text == "Nothing planned for tonight.")
        #expect(LandingSentences.cooking(dish: "Tacos", minutesLeft: 8) == "Cooking tacos, 8 min left.")
        #expect(LandingSentences.cooking(dish: "BLT", minutesLeft: nil) == "Cooking BLT.")
        #expect(LandingSentences.cooking(dish: "Pad Thai", minutesLeft: 0) == "Cooking pad Thai.")
        #expect(LandingSentences.toGet(7) == "7 to get" && LandingSentences.toGet(0) == nil)
        #expect(LandingSentences.covers(dinners: 4) == "covers 4 dinners")
        #expect(LandingSentences.covers(dinners: 1) == "covers 1 dinner" && LandingSentences.covers(dinners: 0) == nil)
    }

    @Test func moneySentenceIsClausesNeverFigures() {
        let full = LandingSentences.money(nothingLate: true, due: ("Rent", "Friday"),
                                          trend: "October is running a little under September")
        #expect(full.text == "Nothing is late. Rent is due Friday, and October is running a little under September.")
        #expect(LandingSentences.money(nothingLate: true, due: ("Rent", "Friday"), trend: nil).text
            == "Nothing is late. Rent is due Friday.")
        #expect(LandingSentences.money(nothingLate: false, due: nil, trend: "October is running well over September")
            .text == "October is running well over September.")
        // A late bill is the waiting band's to say: no sentence about it here.
        #expect(!LandingSentences.money(nothingLate: false, due: ("Rent", "Friday"), trend: nil).text.contains("late"))
        #expect(LandingSentences.money(nothingLate: false, due: nil, trend: nil).text == "Nothing to report.")
    }

    @Test func notesListsAndRoutinesWords() {
        #expect(LandingSentences.notesPrompt.text == "Search or write. @ links a thing.")
        #expect(LandingSentences.leftOf(left: 6, total: 24) == "6 left of 24")
        #expect(LandingSentences.leftOf(left: 25, total: 24) == nil && LandingSentences
            .leftOf(left: 0, total: 0) == nil)
        #expect(LandingSentences.listLine(toGet: 3, newFrom: "Tacos") == "3 to get, new from Tacos")
        #expect(LandingSentences.listLine(toGet: 3, newFrom: nil) == "3 to get")
        #expect(LandingSentences.listLine(toGet: 0, newFrom: "Tacos") == nil)
        #expect(LandingSentences.routineRunning("Morning").text == "Morning is running")
        #expect(LandingSentences.onThisStep(seconds: 250) == "4 min on this step")
        #expect(LandingSentences.onThisStep(seconds: 30) == "Under a minute on this step")
        #expect(LandingSentences.nothingRunning.text == "Nothing is running")
    }

    @Test func theKeyWordIsAlwaysInTheSentence() {
        let sentences = [
            LandingSentences.training(session: "Push A", minutes: 45, opener: ("Bench", "82.5")),
            LandingSentences.kitchen(dish: "Tacos", start: "6:05", shortOf: "Lemon"),
            LandingSentences.money(nothingLate: true, due: ("Rent", "Friday"), trend: nil),
            LandingSentences.money(nothingLate: true, due: nil, trend: nil),
            LandingSentences.notesPrompt, LandingSentences.routineRunning("Morning"),
        ]
        for sentence in sentences {
            #expect(sentence.key.map { sentence.text.contains($0) } ?? true, "\(sentence.text)")
        }
    }

    @Test func aWalledTitleReadsItsLabelOnALanding() throws {
        let routine = try engine.perform(CreateRoutine(title: "Knee rehab day"), by: .user).output
        #expect(LandingNames.shown(routine, in: store, classes: engine.classes) == ObjectPrivacy.routineLabel)
        let plain = try engine.perform(CreateRoutine(title: "Push A"), by: .user).output
        #expect(LandingNames.shown(plain, in: store, classes: engine.classes) == "Push A")
    }

    // MARK: Routines: usual start and length

    func runs(_ days: [Int], hour: Int, minute: Int, length: Int) -> [RoutineRun] {
        days.map { day in
            let start = at(10, day, hour, minute)
            return RoutineRun(start: start, end: start.addingTimeInterval(Double(length) * 60))
        }
    }

    @Test func countsShowAfterSevenRunsAndNotBefore() {
        let six = runs(Array(1 ... 6), hour: 6, minute: 40, length: 22)
        #expect(RoutineUsual.line(name: "Morning", runs: six, calendar: calendar) == nil)
        let seven = runs(Array(1 ... 7), hour: 6, minute: 40, length: 22)
        #expect(RoutineUsual.line(name: "Morning", runs: seven, calendar: calendar)
            == "Morning, 7 days, usually 6:40, 22 min")
    }

    @Test func daysAreDistinctDaysAndTheMedianIgnoresAnOddRun() {
        var all = runs(Array(1 ... 14), hour: 6, minute: 40, length: 22)
        all.append(contentsOf: runs([14], hour: 22, minute: 0, length: 5)) // a second run the same day
        all.append(contentsOf: runs([15], hour: 12, minute: 0, length: 90)) // one odd day
        let line = RoutineUsual.line(name: "Morning", runs: all, calendar: calendar)
        #expect(line == "Morning, 15 days, usually 6:40, 22 min", "\(line ?? "nil")")
    }

    @Test func startsRoundToFiveAndLongRunsReadInHours() {
        let odd = runs(Array(1 ... 7), hour: 6, minute: 43, length: 65)
        #expect(RoutineUsual.line(name: "Evening", runs: odd, calendar: calendar)
            == "Evening, 7 days, usually 6:45, 1 hr 5 min")
        let hour = runs(Array(1 ... 7), hour: 12, minute: 2, length: 60)
        #expect(RoutineUsual.line(name: "Lunch", runs: hour, calendar: calendar)
            == "Lunch, 7 days, usually 12:00, 1 hr")
    }

    @Test func aRunAfterMidnightSitsBesideOneBefore() {
        // 23:50 and 00:20 are within the same evening: the usual start is near midnight, not 12 hours off.
        var late = runs(Array(1 ... 4), hour: 23, minute: 50, length: 30)
        late += runs(Array(5 ... 8), hour: 0, minute: 20, length: 30)
        let counts = RoutineUsual.counts(of: late, calendar: calendar)
        #expect(counts != nil)
        // Day 4's evening and day 5's after-midnight run are the same logical day, so eight runs span seven days.
        let line = RoutineUsual.line(name: "Night", runs: late, calendar: calendar)
        #expect(line == "Night, 7 days, usually 12:05, 30 min", "\(line ?? "nil")")
    }

    @Test func noRunEverCountsAStreakOrAMiss() {
        let line = RoutineUsual.line(name: "Morning", runs: runs(Array(1 ... 9), hour: 7, minute: 0, length: 20),
                                     calendar: calendar) ?? ""
        for word in ["streak", "missed", "best", "record", "fell"] {
            #expect(!line.lowercased().contains(word))
        }
    }

    // MARK: Money: the trend clause

    @discardableResult
    func spend(_ amount: Double, month: Int, day: Int, currency: String? = nil) throws -> ObjectRecord {
        let typed = String(format: "%.2f", amount)
        return try engine.perform(LogSpend(amount: amount, typed: typed, currency: currency, note: "x",
                                           spentAt: at(month, day, 12)), by: .user).output
    }

    func trend(now: Date) -> MoneyTrend.Result? {
        MoneyTrend(store: store, classes: engine.classes).compare(now: now, calendar: calendar)
    }

    @Test func theWordsAreUnderOverAndTheSame() throws {
        try spend(40, month: 9, day: 2)
        try spend(30, month: 9, day: 5)
        try spend(30, month: 9, day: 9)
        let none = trend(now: at(10, 10, 18))
        #expect(none?.direction == .wellUnder) // nothing yet this month against 100 last month
        try spend(90, month: 10, day: 8)
        #expect(trend(now: at(10, 10, 18))?.direction == .littleUnder)
        #expect(trend(now: at(10, 10, 18))?.clause == "October is running a little under September")
        try spend(11, month: 10, day: 9)
        #expect(trend(now: at(10, 10, 18))?.direction == .aboutTheSame)
        try spend(10, month: 10, day: 9)
        #expect(trend(now: at(10, 10, 18))?.direction == .littleOver)
        try spend(40, month: 10, day: 9)
        #expect(trend(now: at(10, 10, 18))?.direction == .wellOver)
        #expect(trend(now: at(10, 10, 18))?.clause == "October is running well over September")
    }

    @Test func itStaysQuietEarlyOnThinOrMixedData() throws {
        try spend(40, month: 9, day: 2)
        try spend(30, month: 9, day: 5)
        // Two spends last month is too few.
        try spend(10, month: 10, day: 3)
        #expect(trend(now: at(10, 10, 18)) == nil)
        try spend(30, month: 9, day: 6)
        // Before the month is a week old, nothing is said.
        #expect(trend(now: at(10, 5, 18)) == nil)
        #expect(trend(now: at(10, 10, 18)) != nil)
        // A second currency anywhere stops it: spends never add up across currencies.
        try spend(5, month: 10, day: 4, currency: "EUR")
        #expect(trend(now: at(10, 10, 18)) == nil)
    }

    @Test func theClauseHoldsNoFigureAndTheSentenceNoMoneyValue() throws {
        try spend(412.50, month: 9, day: 2)
        try spend(130.25, month: 9, day: 5)
        try spend(61.10, month: 9, day: 9)
        try spend(309.99, month: 10, day: 8)
        let clause = try #require(trend(now: at(10, 10, 18))?.clause)
        #expect(clause.allSatisfy { !$0.isNumber })
        let sentence = LandingSentences.money(nothingLate: true, due: ("Rent", "Friday"), trend: clause)
        #expect(sentence.text.allSatisfy { !$0.isNumber })
    }

    // MARK: Kitchen: dinners covered

    func recipe(_ title: String, lines: [String]) throws -> ObjectRecord {
        let text = "\(title)\nIngredients\n\(lines.joined(separator: "\n"))\nMethod\n1. Cook it."
        return try engine.perform(CreateRecipe(text: text), by: .user).output
    }

    func stock(_ names: [String], in key: String = "fridge") throws {
        PantryPlaces(store: store, classes: engine.classes).ensureDefaults()
        let place = try #require(store.object(id: PantryPlaces.defaultID(key)))
        for name in names {
            let ingredient = try #require(IngredientBook(store: store, classes: engine.classes).find(name))
            try engine.perform(SetItemPlace(item: ingredient.id, place: place.id), by: .user)
        }
    }

    @Test func aRecipeIsCoveredWhenEveryNeededIngredientIsInAPlace() throws {
        _ = try recipe("Tacos", lines: ["200 g beef mince", "4 tortillas", "1 lime"])
        _ = try recipe("Omelette", lines: ["3 eggs", "20 g butter"])
        let kitchen = KitchenLanding(store: store, classes: engine.classes)
        #expect(kitchen.dinnersCovered() == 0)
        try stock(["beef mince", "tortillas"])
        #expect(kitchen.dinnersCovered() == 0) // the lime is missing
        try stock(["lime"], in: "counter")
        #expect(kitchen.dinnersCovered() == 1)
        try stock(["eggs", "butter"], in: "shelf")
        #expect(kitchen.dinnersCovered() == 2)
    }

    @Test func tasteOptionalAndStapleLinesNeverBlockACover() throws {
        _ = try recipe("Dal", lines: ["250 g red lentils", "Salt, to taste", "1 onion", "Coriander, optional"])
        try stock(["red lentils", "onion"])
        #expect(KitchenLanding(store: store, classes: engine.classes).dinnersCovered() == 1)
    }

    @Test func toGetCountsTheOpenGroceriesAndNothingElse() throws {
        let kitchen = KitchenLanding(store: store, classes: engine.classes)
        #expect(kitchen.toGetCount() == 0)
        let tacos = try recipe("Tacos", lines: ["200 g beef mince", "4 tortillas"])
        try engine.perform(AddRecipeToGroceries(recipe: tacos.id), by: .user)
        #expect(kitchen.toGetCount() == 2)
    }

    // MARK: Walls

    @Test func nothingAboutALandingIsEverAClaudeJob() throws {
        let sources = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appending(path: "Sources/TesseraTess")
        let files = try FileManager.default.contentsOfDirectory(at: sources, includingPropertiesForKeys: nil)
        let names = ["LandingSentences", "MoneyTrend", "RoutineUsual", "KitchenLanding", "LandingNames", "RoutineRun"]
        for file in files where file.pathExtension == "swift" {
            let text = try String(contentsOf: file, encoding: .utf8)
            for name in names {
                #expect(!text.contains(name), "\(file.lastPathComponent) mentions \(name)")
            }
        }
        #expect(files.count > 3)
    }
}
