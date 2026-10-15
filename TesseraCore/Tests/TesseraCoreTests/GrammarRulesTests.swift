import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// docs/research/grammar-collisions.md rules 1-3, and the board's done-when phrases.
@MainActor
struct GrammarRulesTests {
    let store = ObjectStore.open(inMemory: true)

    @Test func doneWhenPhrasesLand() throws {
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let grammar = TessGrammar(store: store, classes: classes)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let thursdayEvening = Date(timeIntervalSince1970: 1_792_094_400) // Thu 15 Oct 2026, 20:00 GMT
        let context = TessContext(now: thursdayEvening, calendar: calendar)

        // "p 42 of 80" is not Dip 42 x 80 (no lift from a 1-letter word).
        if case .lift? = grammar.parse("p 42 of 80", context: context) {
            Issue.record("p 42 of 80 read as a lift")
        }
        // "buy sun cream" is groceries.
        if case let .groceries(lines)? = grammar.parse("buy sun cream", context: context) {
            #expect(lines == ["sun cream"])
        } else {
            Issue.record("buy sun cream")
        }
        // "move dentist to friday" moves the open Dentist task, never a new "Move dentist to" task.
        let dentist = try engine.perform(CreateTask(title: "Dentist", startsAt: thursdayEvening), by: .user).output
        if case let .reschedule(task, date)? = grammar.parse("move dentist to friday", context: context) {
            #expect(task.id == dentist.id && calendar.component(.weekday, from: date) == 6)
        } else {
            Issue.record("move dentist to friday")
        }
        #expect(grammar.parse("move the piano to friday", context: context) == nil
            || { if case .reschedule? = grammar.parse("move the piano to friday", context: context) { false }
                 else { true } }())
        // Questions with dates never become tasks.
        for question in ["what did i weigh monday", "anything due tmrw", "everything from tuesday",
                         "what did i get done today", "how many workouts this week?"]
        {
            #expect(grammar.parse(question, context: context) == nil, "\(question)")
        }
        // Two exercises in one comma phrase.
        if case let .sets(parts)? = grammar.parse("squat 100 5, deadlift 140 3", context: context) {
            let read = parts.compactMap { part -> [Double]? in
                if case let .lift(_, _, reps, weight, _) = part { [weight, reps] } else { nil }
            }
            #expect(read == [[100, 5], [140, 3]])
        } else {
            Issue.record("squat 100 5, deadlift 140 3")
        }
        // "call mum thu" said on a Thursday means today (Product), never in the past.
        if case let .task(_, date?)? = grammar.parse("call mum thu", context: context) {
            #expect(calendar.isDate(date, inSameDayAs: thursdayEvening) && date > thursdayEvening)
        } else {
            Issue.record("call mum thu")
        }
    }

    @Test func theProcessInNowDecidesBareInput() throws {
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let grammar = TessGrammar(store: store, classes: classes)
        try engine.perform(CreateRecipe(text: RecipeParserTests.carbonara), by: .user)
        let recipe = try #require(RecipeBook(store: store, classes: classes).recipes().first)
        let cook = try engine.perform(StartCooking(recipe: recipe.id), by: .user).output
        let cooking = TessContext(process: cook.id)
        if case let .cookStep(_, next)? = grammar.parse("next", context: cooking) {
            #expect(next)
        } else {
            Issue.record("next while cooking")
        }

        let plan = try #require(store.object(id: StarterContent.planID))
        let pushA = try #require(store.linkedObjects("routines", of: plan).first)
        let workout = try engine.perform(StartRoutine(routine: pushA.id), by: .user).output
        let training = TessContext(process: workout.id)
        if case .timer? = grammar.parse("timer 90", context: training) {
            Issue.record("timer 90 in a workout made a kitchen timer")
        }

        try engine.perform(AddGroceries(lines: ["milk"]), by: .user)
        let shopping = TessContext(process: Groceries.listID)
        if case let .groceries(lines)? = grammar.parse("parmesan", context: shopping) {
            #expect(lines == ["parmesan"])
        } else {
            Issue.record("parmesan at the shop")
        }
    }
}
