import SwiftUI
import TesseraCore

/// Kitchen's landing as data (Design 131 §2), so the view only draws it and the sentence has a test per case. Every
/// word is computed on the phone from fixed templates; a private recipe reads "Private recipe" and a private item is
/// never named. Nothing here reaches Claude.
@MainActor
struct KitchenFront {
    /// Kitchen's one accent, ochre (131 table: #E0A458 dark, #A8701F light).
    static var accent: Color {
        Theme.Colors.Accent.kitchen
    }

    struct Meal {
        let title: String
        let start: Date
        let minutes: Double?
        let recipe: UUID?
    }

    struct Day: Identifiable {
        let id: Date
        let weekday: String
        let isToday: Bool
        let meal: Meal?
        /// Today: "start 6:05"; another day: "25 min"; open: nil.
        let when: String?
    }

    struct Cooking {
        let id: UUID
        let line: String
    }

    let tonight: Meal?
    let week: [Day]
    /// Each place and its level: nil when nothing in it is known (no line is drawn).
    let places: [(name: String, level: Double?)]
    let toGet: Int
    let saved: Int
    /// Dinners the pantry already covers (Core's count).
    let covers: Int
    let cooking: Cooking?

    init(model: AppModel, now: Date, calendar: Calendar = .current, days: Int = 4) {
        let house = TesseraDay(calendar: calendar)
        let today = house.today(now)
        let book = RecipeBook(store: model.store, classes: model.classes)
        let meals = Self.meals(model, from: today, days: days, calendar: calendar, book: book)
        tonight = meals.first { house.isSameDay($0.start, now) }
        week = (0 ..< days).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }
            // Midday, so the house day (04:00 to 04:00) is the calendar day's own.
            let midday = day.addingTimeInterval(12 * 3600)
            let meal = meals.first { house.isSameDay($0.start, midday) }
            let weekday = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: day) - 1]
            let when: String? = meal.flatMap { meal in
                offset == 0 ? "start \(HouseTime.clock(meal.start))" : meal.minutes.map { HouseTime.minutes(Int($0)) }
            }
            return Day(id: day, weekday: weekday, isToday: offset == 0, meal: meal, when: when)
        }
        let board = PantryBoard(store: model.store, classes: model.classes) { GroceriesCopy.name($0) }
        places = board.places.map { place in
            let states = place.groups.flatMap(\.rows).compactMap { row -> PantryLedger.State? in
                if case let .stock(entry) = row {
                    return entry.state
                }
                return nil
            }
            return (place.name, Self.level(states))
        }
        toGet = board.toGetCount
        saved = book.recipes().count
        covers = TesseraCore.KitchenLanding(store: model.store, classes: model.classes).dinnersCovered()
        cooking = Self.cooking(model, now: now)
    }

    /// "Tacos tonight, start at 6:05." from Core's template (#1222); the short thing waits on RecipeStock.
    var sentence: LandingSentence {
        LandingSentences.kitchen(dish: tonight?.title, start: tonight.map { HouseTime.clock($0.start) }, shortOf: nil)
    }

    /// Beside the Pantry door: "7 to get, covers 4 dinners", each part only when it answers.
    var pantryValue: String? {
        let parts = [LandingSentences.toGet(toGet), LandingSentences.covers(dinners: covers)].compactMap(\.self)
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    /// Design's rule (a), on #1224: in counts 1, low counts half, out counts 0, over what is known. Unknown things are
    /// left out of both; with nothing known there is no level and no line. Core stores no amounts yet.
    static func level(_ states: [PantryLedger.State]) -> Double? {
        let known = states.filter { $0 != .unknown }
        guard !known.isEmpty else { return nil }
        let stocked = known.reduce(0.0) { sum, state in
            sum + (state == .have ? 1 : state == .low ? 0.5 : 0)
        }
        return stocked / Double(known.count)
    }

    /// "full", "most", "half", "low", "empty": what VoiceOver says for a level line.
    static func levelWords(_ level: Double) -> String {
        switch level {
        case 0.95...: "full"
        case 0.6 ..< 0.95: "most"
        case 0.35 ..< 0.6: "half"
        case 0.01 ..< 0.35: "low"
        default: "empty"
        }
    }

    // MARK: Reading

    /// Planned meals: a timed task about a recipe (Home's "Tacos, 7 pm"), from today for `days` days.
    private static func meals(_ model: AppModel, from today: Date, days: Int, calendar: Calendar,
                              book: RecipeBook) -> [Meal]
    {
        guard let recipeClass = model.classDef(.recipe),
              let end = calendar.date(byAdding: .day, value: days, to: today) else { return [] }
        return model.objects(of: .task).compactMap { task in
            guard !task.isDeleted, case let .date(start)? = model.store.value("startsAt", of: task),
                  start >= today, start < end,
                  let recipe = model.store.linkedObjects("about", of: task).first(where: { object in
                      !object.isDeleted && object.classDef.map { ClassResolver.isSubclass($0, of: recipeClass) } == true
                  }) else { return nil }
            let title = RecipeCopy.shownTitle(recipe.title, isPrivate: RecipeCopy.isPrivate(recipe.title, model: model))
            return Meal(title: title, start: start, minutes: book.totalMinutes(recipe), recipe: recipe.id)
        }
        .sorted { $0.start < $1.start }
    }

    /// The cook running now, if one is: "Cooking tacos, 8 min left." with Go on.
    private static func cooking(_ model: AppModel, now: Date) -> Cooking? {
        guard let process = model.processes.running(), let cookClass = model.classDef(.cook),
              let cook = process.subject, cook.classDef.map({ ClassResolver.isSubclass($0, of: cookClass) }) == true
        else { return nil }
        let recipe = model.store.linkedObjects("recipe", of: cook).first
        let title = recipe
            .map { RecipeCopy.shownTitle($0.title, isPrivate: RecipeCopy.isPrivate($0.title, model: model)) }
            ?? "Private recipe"
        let timer = CookLog(store: model.store, classes: model.classes).timers(at: now).first { $0.cook?.id == cook.id }
        let left = timer.map { Int(($0.remaining(at: now) / 60).rounded(.up)) }
        return Cooking(id: cook.id, line: LandingSentences.cooking(dish: title, minutesLeft: left))
    }
}
