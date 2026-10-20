import Foundation
import TesseraCore

/// The week of dinners (sheet 104 section 3, sheet 114 section 1, kitchen-v2 WD) as data: Monday to Sunday by his
/// day (4 AM), each day with the dinner planned for it. A plan is what "cook tacos thu" makes: a task about the
/// recipe, dated by `startsAt` (or a `due` date). Nothing here writes; nothing reaches Groceries until he taps.
///
/// The engine is Core's (B10 ruling). This is the local shape the screens draw: when Core's week of dinners lands
/// (WD-E1, with `groceriesAddedAt` and skipped plans), `WeekOfDinners.init(store:...)` is where its plans plug in,
/// and `DinnerShop.needs` where its add-the-week diff does.
@MainActor
struct WeekOfDinners {
    struct Plan: Equatable {
        let task: UUID
        let recipe: UUID
        /// The title, or "Private recipe".
        let name: String
        let isPrivate: Bool
        let isDone: Bool
    }

    struct Day: Identifiable, Equatable {
        /// The day's midnight key.
        let id: Date
        /// "Mon".
        let word: String
        let plan: Plan?
    }

    let days: [Day]
    /// "week of Oct 19": the Monday.
    let context: String

    /// The plans of the week holding `now`, one per day (the earliest when two share a day).
    init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef], now: Date, calendar: Calendar = .current) {
        let house = TesseraDay(calendar: calendar)
        let monday = house.week(containing: now).start
        let keys = (0 ..< 7).map { house.day($0, after: monday) }
        var plans: [Date: (when: Date, plan: Plan)] = [:]
        if let taskClass = classes[.task], let recipeClass = classes[.recipe] {
            let weight = BodyWeight.lastKg(in: store)
            for task in store.objects(of: taskClass) where !task.isDeleted {
                guard let recipe = store.linkedObjects("about", of: task)
                    .first(where: { $0.classDef?.id == recipeClass.id && !$0.isDeleted }),
                    let when = (store.value("startsAt", of: task) ?? store.value("due", of: task))?.dateValue
                else { continue }
                let key = house.day(of: when)
                guard keys.contains(key), plans[key].map({ when < $0.when }) ?? true else { continue }
                let title = store.displayTitle(of: recipe)
                let isPrivate = ObjectPrivacy.isPrivateRecipeTitle(title, lastWeightKg: weight)
                plans[key] = (when, Plan(task: task.id, recipe: recipe.id,
                                         name: isPrivate ? ObjectPrivacy.recipeLabel : title, isPrivate: isPrivate,
                                         isDone: store.value("isDone", of: task) == .bool(true)))
            }
        }
        days = keys.map { key in
            Day(id: key, word: String(TesseraDay.weekdayName(of: key, calendar: calendar).prefix(3)),
                plan: plans[key]?.plan)
        }
        context = "week of \(Self.monthDay(monday, calendar: calendar))"
    }

    static func monthDay(_ date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    /// When a picked dinner is set: 7 pm on that day ("Tacos, 7 pm" on Kitchen).
    static func dinnerTime(on day: Date, calendar: Calendar = .current) -> Date {
        calendar.date(bySettingHour: 19, minute: 0, second: 0, of: day) ?? day
    }

    /// The plan's task title, as "cook tacos thu" writes it: "Cook tacos"; a private recipe lends no word.
    static func taskTitle(for recipe: ObjectRecord, store: ObjectStore, classes: [SystemCatalog.Key: ClassDef])
        -> String
    {
        ObjectPrivacy.label(of: recipe, in: store, classes: classes) ?? "Cook \(recipe.title.lowercased())"
    }

    /// The choices under an open day: his recent dinners first (last cooked, newest first), then the rest newest
    /// first; at most `limit`.
    static func choices(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef], limit: Int = 4) -> [ObjectRecord] {
        let book = RecipeBook(store: store, classes: classes)
        let log = CookLog(store: store, classes: classes)
        let recipes = book.recipes().filter { !$0.isDeleted }
        let cooked = recipes.compactMap { recipe in log.lastCooked(recipe).map { (recipe, $0) } }
            .sorted { $0.1 > $1.1 }.map(\.0)
        let rest = recipes.filter { recipe in !cooked.contains { $0.id == recipe.id } }
            .sorted { $0.createdAt > $1.createdAt }
        return Array((cooked + rest).prefix(limit))
    }
}

/// A planned dinner against the pantry and Groceries: what is missing goes on, on his tap only (kitchen-v2 WD-S2).
enum DinnerShop {
    /// One line of the recipe as the shop sees it.
    struct Need: Equatable {
        let ingredient: UUID
        /// "1 lb ground beef", the line Groceries reads.
        let text: String
        /// Aisle, as Groceries groups it.
        let aisle: String
        /// A line to buy: not a staple, "to taste" or optional.
        let counts: Bool
        let state: PantryLedger.State
        /// Already on Groceries, open or in the basket.
        let onList: Bool
    }

    /// What the add would put on: lines to buy not already on the list; with Pantry state on, In lines are skipped
    /// ("planning skips in lines", switch 21). Low and Out are bought again.
    static func missing(_ needs: [Need], skipIn: Bool) -> [Need] {
        var seen = Set<UUID>()
        return needs.filter { need in
            need.counts && !need.onList && !(skipIn && need.state == .have) && seen.insert(need.ingredient).inserted
        }
    }

    /// How the add is written. The whole recipe (Core's `AddRecipeToGroceries`, which keeps each row's recipe share)
    /// when nothing was skipped for the pantry, or for a private recipe (its rows never lend a name); only the missing
    /// lines (`AddGroceries`) when the pantry covers some. Nothing when nothing is missing.
    enum Add: Equatable {
        case recipe
        case lines([String])
        case nothing
    }

    static func add(_ needs: [Need], skipIn: Bool, isPrivate: Bool) -> Add {
        let missing = missing(needs, skipIn: skipIn)
        guard !missing.isEmpty else { return .nothing }
        let wouldAdd = Self.missing(needs, skipIn: false)
        return isPrivate || missing.count == wouldAdd.count ? .recipe : .lines(missing.map(\.text))
    }

    /// "Tacos, 3 added." / "Week, 5 added." / "Week, nothing to add." (sheet 114).
    static func receipt(_ name: String, added: Int) -> String {
        added == 0 ? "\(name), nothing to add." : "\(name), \(added) added."
    }

    /// The side's lines, THE WEEK'S SHOP: counts per aisle in walking order, each ingredient once. "Produce, 4".
    static func byAisle(_ needs: [Need]) -> [(aisle: String, count: Int)] {
        var seen = Set<UUID>()
        var counts: [String: Int] = [:]
        for need in needs where seen.insert(need.ingredient).inserted {
            counts[need.aisle, default: 0] += 1
        }
        return counts.map { (aisle: $0.key, count: $0.value) }
            .sorted { Aisle.order(of: $0.aisle) < Aisle.order(of: $1.aisle) }
    }

    /// A recipe's needs, read from the store.
    @MainActor
    static func needs(of recipe: ObjectRecord, store: ObjectStore, classes: [SystemCatalog.Key: ClassDef],
                      states: [UUID: PantryLedger.State]) -> [Need]
    {
        let groceries = Groceries(store: store, classes: classes)
        return RecipeBook(store: store, classes: classes).lines(of: recipe).compactMap { line in
            guard let ingredient = line.ingredient else { return nil }
            let title = store.displayTitle(of: ingredient)
            let aisle = store.value("aisle", of: ingredient)?.stringValue.flatMap { $0.isEmpty ? nil : $0 }
                ?? (AisleGuide.aisle(for: title) ?? .other).rawValue
            return Need(ingredient: ingredient.id,
                        text: [line.line.quantityText, line.line.name].compactMap(\.self).joined(separator: " "),
                        aisle: Aisle.shown(aisle), counts: NeedHave.counts(line, store: store),
                        state: states[ingredient.id] ?? .unknown,
                        onList: PantryFront.listed(ingredient, groceries: groceries, store: store) != .none)
        }
    }
}
