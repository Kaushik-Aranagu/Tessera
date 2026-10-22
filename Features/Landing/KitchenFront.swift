import SwiftUI
import TesseraCore

/// Kitchen's landing as data (Design 131 §2), so the view only draws it and the sentence has a test per case. Every
/// word is computed on the phone from fixed templates; a private recipe reads "Private recipe" and a private item is
/// never named. Nothing here reaches Claude.
@MainActor
struct KitchenFront {
    /// Kitchen's one accent, ochre (131 table: #E0A458 dark, #A8701F light).
    static let accent = Color(light: 0xA8701F, dark: 0xE0A458)

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
    let places: [(name: String, level: Double)]
    let toGet: Int
    let saved: Int
    /// A thing running low, by name (never a private one).
    let low: String?
    let cooking: Cooking?

    init(model: AppModel, now: Date, calendar: Calendar = .current, days: Int = 4) {
        let house = TesseraDay(calendar: calendar)
        let today = house.today(now)
        let book = RecipeBook(store: model.store, classes: model.classes)
        let meals = Self.meals(model, from: today, days: days, calendar: calendar, book: book)
        tonight = meals.first { house.isSameDay($0.start, now) }
        week = (0 ..< days).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }
            let meal = meals.first { house.isSameDay($0.start, day) }
            let weekday = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: day) - 1]
            let when: String? = meal.flatMap { meal in
                offset == 0 ? "start \(HouseTime.clock(meal.start))" : meal.minutes.map { "\(Int($0)) min" }
            }
            return Day(id: day, weekday: weekday, isToday: offset == 0, meal: meal, when: when)
        }
        let board = PantryBoard(store: model.store, classes: model.classes) { GroceriesCopy.name($0) }
        places = board.places.map { place in
            let rows = place.groups.flatMap(\.rows)
            let have = rows.count { row in
                if case let .stock(entry) = row {
                    return entry.state == .have || entry.state == .unknown
                }
                return false
            }
            return (place.name, rows.isEmpty ? 0 : Double(have) / Double(rows.count))
        }
        toGet = board.toGetCount
        saved = book.recipes().count
        low = board.places.lazy.compactMap(\.low).first
        cooking = Self.cooking(model)
    }

    /// The sentence: tonight's meal and its start, then one more clause (what is low, else how much is to get).
    /// "Tacos tonight, start at 6:05. Lemon is low." / "Nothing planned tonight. 7 to get."
    var sentence: [LandingSentence.Piece] {
        var pieces: [LandingSentence.Piece] = if let tonight {
            [.key(tonight.title), .plain(" tonight, start at \(HouseTime.clock(tonight.start)).")]
        } else {
            [.plain("Nothing planned tonight.")]
        }
        if let low {
            pieces += [.plain(" "), .key(low.prefix(1).uppercased() + low.dropFirst()), .plain(" is low.")]
        } else if toGet > 0 {
            pieces += [.plain(" \(toGet) to get.")]
        }
        return pieces
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

    /// The cook running now, if one is: "Cooking tacos." with Go on.
    private static func cooking(_ model: AppModel) -> Cooking? {
        guard let process = model.processes.running(), let cookClass = model.classDef(.cook),
              let cook = process.subject, cook.classDef.map({ ClassResolver.isSubclass($0, of: cookClass) }) == true
        else { return nil }
        let recipe = model.store.linkedObjects("recipe", of: cook).first
        let title = recipe
            .map { RecipeCopy.shownTitle($0.title, isPrivate: RecipeCopy.isPrivate($0.title, model: model)) }
            ?? "Private recipe"
        let named = title == "Private recipe" ? "a private recipe" : title.lowercased()
        return Cooking(id: cook.id, line: "Cooking \(named).")
    }
}
