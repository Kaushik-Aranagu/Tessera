import Foundation
@testable import TesseraCore
import Testing

/// Why this number (sheet 144): one sentence from the same facts that made the number.
@MainActor
struct ExplainTests {
    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    var now: Date {
        Date(timeIntervalSince1970: 1_792_670_400)
    }

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    func explain(_ id: NumberID, ecb: CurrencyRates? = nil) -> String? {
        Explain.number(id, engine: engine, ecb: ecb, now: now, calendar: calendar)
    }

    @discardableResult
    func session(daysAgo: Double, sets: [(Double, Double)], title: String = "Push A", routine: ObjectRecord? = nil,
                 minutes: Double = 45) throws -> ObjectRecord
    {
        let ended = now.addingTimeInterval(-daysAgo * 86400)
        let workout = try store.create(#require(engine.classes[.workout]), title: title)
        try store.set("endedAt", to: .date(ended), on: workout)
        if let routine {
            try store.setLinks("routine", on: workout, to: [routine])
        }
        let entry = try store.create(#require(engine.classes[.exerciseEntry]), parent: workout)
        try store.setClassLink("exercise", on: entry, to: #require(engine.classes[.benchPress]))
        let ledger = TrainingLedger(store: store, classes: engine.classes)
        for (index, set) in sets.enumerated() {
            let made = try ledger.logSet(weight: set.0, reps: set.1, in: entry)
            let at = ended.addingTimeInterval(-minutes * 60 * Double(sets.count - 1 - index) / Double(max(
                sets.count - 1,
                1
            )))
            try store.set("loggedAt", to: .date(at), on: made)
        }
        return workout
    }

    var bench: UUID {
        engine.classes[.benchPress]!.id
    }

    // MARK: Training

    @Test func theNextWeightSaysWhatItCameFromAndNilWithNothingToSayItFrom() throws {
        #expect(explain(.nextWeight(exercise: bench)) == nil)
        try session(daysAgo: 3, sets: [(80, 12), (80, 12), (80, 12)])
        let text = try #require(explain(.nextWeight(exercise: bench)))
        #expect(text.hasPrefix("82.5: your last Bench Press, 80 for 12, plus one 2.5 step."))
    }

    @Test func aWeightHeldUntilTheRangeTopSaysSo() throws {
        try session(daysAgo: 3, sets: [(80, 6), (80, 6), (80, 6)])
        let text = try #require(explain(.nextWeight(exercise: bench)))
        #expect(text ==
            "80: your last Bench Press, 80 for 6, the same weight until every set reaches the top of the range.")
    }

    @Test func sessionLengthNamesThePlainRoutineAndSaysNothingOfAPrivateOne() throws {
        let routine = try engine.perform(CreateRoutine(title: "Push A"), by: .user).output
        for day in [9.0, 6.0, 3.0] {
            try session(daysAgo: day, sets: [(60, 5), (60, 5)], routine: routine, minutes: 45)
        }
        #expect(explain(.sessionLength(routine: routine.id)) == "about 45 min: your last 3 Push A sessions.")
        let secret = try engine.perform(CreateRoutine(title: "Knee rehab day"), by: .user).output
        for day in [9.0, 6.0] {
            try session(daysAgo: day, sets: [(60, 5), (60, 5)], title: "Knee rehab day", routine: secret, minutes: 30)
        }
        #expect(explain(.sessionLength(routine: secret.id)) == nil)
        #expect(explain(.sessionLength(routine: UUID())) == nil)
    }

    @Test func theBestSetNamesTheSetAndIgnoresPrivateWorkouts() throws {
        #expect(explain(.bestSet(exercise: bench)) == nil)
        try session(daysAgo: 5, sets: [(80, 5)])
        #expect(explain(.bestSet(exercise: bench)) == "93 kg: your best Bench Press, 80 for 5, as a one-rep estimate.")
        try session(daysAgo: 2, sets: [(120, 5)], title: "Knee rehab day")
        // The private 120 changes nothing.
        #expect(explain(.bestSet(exercise: bench)) == "93 kg: your best Bench Press, 80 for 5, as a one-rep estimate.")
    }

    @Test func theRunNeedsAFinishedRunOfThreeOrMoreWeeks() throws {
        #expect(explain(.streak(habit: .training)) == nil)
        for week in 2 ... 6 {
            try session(daysAgo: Double(week * 7 + 1), sets: [(60, 5)])
        }
        let text = try #require(explain(.streak(habit: .training)))
        #expect(text == "5 weeks: the most weeks in a row with a session, counting only runs that have ended.")
        #expect(!text.lowercased().contains("streak"))
    }

    // MARK: Kitchen

    @Test func coveredDinnersAreNamedAndAPrivateOneIsLabelled() throws {
        #expect(explain(.coversDinners) == nil)
        let tacos = try engine.perform(
            CreateRecipe(text: "Tacos\nIngredients\n4 tortillas\nMethod\n1. Cook."),
            by: .user
        ).output
        let soup = try engine.perform(CreateRecipe(text: "Soup\nIngredients\n2 carrots\nMethod\n1. Boil."), by: .user)
            .output
        let secret = try engine.perform(
            CreateRecipe(text: "Lexapro cake\nIngredients\n1 egg\nMethod\n1. Bake."),
            by: .user
        ).output
        PantryPlaces(store: store, classes: engine.classes).ensureDefaults()
        let shelf = try #require(store.object(id: PantryPlaces.defaultID("shelf")))
        for recipe in [tacos, soup, secret] {
            for line in RecipeBook(store: store, classes: engine.classes).lines(of: recipe) {
                if let ingredient = line.ingredient {
                    try engine.perform(SetItemPlace(item: ingredient.id, place: shelf.id), by: .user)
                }
            }
        }
        let text = try #require(explain(.coversDinners))
        #expect(text == "covers 3 dinners: tacos, soup and Private recipe have all they need.")
        #expect(!text.contains("Lexapro"))
    }

    // MARK: Money (phone only)

    @Test func theAboutTotalNamesTheCurrenciesAndTheRateDate() throws {
        #expect(explain(.moneyAboutTotal) == nil)
        try engine.perform(CreatePool(name: "US checking", opening: "1000"), by: .user)
        try engine.perform(CreatePool(name: "India account", currency: "INR", opening: "8300"), by: .user)
        let rateDay = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 18, hour: 12)))
        try engine.perform(RecordRate(pair: "USD/INR", value: "83", at: rateDay), by: .user)
        #expect(explain(.moneyAboutTotal) == "1,100: dollars plus rupees at the Oct 18 rate.")
    }

    @Test func aPoolBalanceUsesTheLabelNeverTheName() throws {
        let pool = try engine.perform(CreatePool(name: "US checking", opening: "250"), by: .user).output
        let text = try #require(explain(.poolBalance(pool: pool.id)))
        #expect(text == "$250.00: what Private pool started with, plus what came in, minus what went out.")
        #expect(!text.contains("checking"))
        #expect(explain(.poolBalance(pool: UUID())) == nil)
    }

    @Test func theMonthSpendIsPerCurrencyAndNilWithNone() throws {
        #expect(explain(.monthSpend(currency: "USD")) == nil)
        try engine.perform(LogSpend(amount: 12.4, typed: "12.40", spentAt: now.addingTimeInterval(-86400)), by: .user)
        #expect(explain(.monthSpend(currency: "USD")) == "12.40: what you logged this month in dollars.")
        #expect(explain(.monthSpend(currency: "INR")) == nil)
    }

    // MARK: Walls

    @Test func nothingHereGoesNearClaudeAndNoSentenceHoldsAWallWord() throws {
        let sources = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appending(path: "Sources/TesseraTess")
        for file in try FileManager.default.contentsOfDirectory(at: sources, includingPropertiesForKeys: nil)
            where file.pathExtension == "swift"
        {
            let text = try String(contentsOf: file, encoding: .utf8)
            #expect(!text.contains("Explain.number") && !text.contains("NumberID"))
        }
    }
}
