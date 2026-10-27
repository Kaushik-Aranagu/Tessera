import Foundation
import TesseraCore

/// The Recipes front as data (sheet 87): the class page of Recipe, newest first, one plain line per recipe with its
/// day. A private recipe is only ever "Private recipe", in its row, the count, Tess's lines and VoiceOver.
@MainActor
struct RecipesShelf {
    struct Row: Identifiable, Equatable {
        let id: UUID
        /// The name, or "Private recipe".
        let name: String
        let isPrivate: Bool
        /// When it was last cooked, on his day ("Tue", "Oct 3"); nil when never cooked.
        let day: String?
        let cooks: Int
    }

    let rows: [Row]
    /// "38 recipes, 2 private", "1 recipe", "None yet".
    let context: String
    /// Tess's line: "Tacos, cooked 2 times." for one recipe, "Chili is the one you cook most." for many; nil when
    /// nothing has been cooked.
    let tess: String?

    init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef], now: Date, calendar: Calendar = .current) {
        let weight = BodyWeight.lastKg(in: store)
        // Every cook read once, grouped by recipe, rather than once per row (QA on #765).
        var cooked: [UUID: [Date]] = [:]
        if let cookClass = classes[.cook] {
            for cook in store.objects(of: cookClass) where !cook.isDeleted {
                guard let when = store.value("cookedAt", of: cook)?.dateValue,
                      let recipe = store.linkedObjects("recipe", of: cook).first else { continue }
                cooked[recipe.id, default: []].append(when)
            }
        }
        let recipes = RecipeBook(store: store, classes: classes).recipes().filter { !$0.isDeleted }
        rows = recipes.sorted { $0.createdAt > $1.createdAt }.map { recipe in
            let title = store.displayTitle(of: recipe)
            let isPrivate = ObjectPrivacy.isPrivateRecipeTitle(title, lastWeightKg: weight)
            let cooks = cooked[recipe.id] ?? []
            return Row(id: recipe.id, name: isPrivate ? ObjectPrivacy.recipeLabel : title, isPrivate: isPrivate,
                       day: cooks.max().map { Self.day($0, now: now, calendar: calendar) }, cooks: cooks.count)
        }
        context = Self.context(count: rows.count, privateCount: rows.count(where: \.isPrivate))
        tess = Self.tess(rows)
    }

    static func context(count: Int, privateCount: Int) -> String {
        guard count > 0 else { return "None yet" }
        let base = "\(count) recipe\(count == 1 ? "" : "s")"
        return privateCount > 0 ? "\(base), \(privateCount) private" : base
    }

    static func tess(_ rows: [Row]) -> String? {
        // An empty shelf says how one gets in (K30.1, lists-acceptance 13.12).
        if rows.isEmpty {
            return "Paste a link or a page and I'll read it"
        }
        // Names by their short name, so a long title never makes a long line (QA on #765).
        if rows.count == 1, let only = rows.first, only.cooks > 0 {
            return "\(RecipeCopy.shortName(only.name)), cooked \(only.cooks) time\(only.cooks == 1 ? "" : "s")"
        }
        guard let top = rows.max(by: { $0.cooks < $1.cooks }), top.cooks > 1,
              rows.count(where: { $0.cooks == top.cooks }) == 1
        else { return nil }
        return "\(RecipeCopy.shortName(top.name)) is the one you cook most"
    }

    /// His day (4 AM): within the week the short weekday, then "Oct 3" (US month first).
    static func day(_ date: Date, now: Date, calendar: Calendar) -> String {
        let house = TesseraDay(calendar: calendar)
        let then = house.day(of: date)
        let days = calendar.dateComponents([.day], from: then, to: house.day(of: now)).day ?? 0
        if days == 0 {
            return "today"
        }
        if days < 7 {
            return String(TesseraDay.weekdayName(of: then, calendar: calendar).prefix(3))
        }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        // The year only when it isn't this year: "Oct 3", "Oct 3, 2025" (QA on #765).
        let sameYear = calendar.component(.year, from: then) == calendar.component(.year, from: now)
        formatter.dateFormat = sameYear ? "MMM d" : "MMM d, yyyy"
        return formatter.string(from: then)
    }
}
