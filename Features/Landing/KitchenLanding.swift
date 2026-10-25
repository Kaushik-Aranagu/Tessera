import SwiftUI
import TesseraCore

// MARK: - The wall (landing contract §12: pantry and recipes, low and cookable first)

/// Kitchen's landing words as data, so the wall, the state line and the brief have tests. Walled recipes and items
/// never reach the wall; they are counted for the Private door.
struct KitchenWall: Equatable {
    enum Kind: Equatable {
        case pantry
        case recipe(UUID)
    }

    struct Stock: Equatable {
        let name: String
        let state: PantryLedger.State
        let isPrivate: Bool
    }

    struct Dish: Equatable {
        let id: UUID
        let title: String
        let isPrivate: Bool
        /// Everything for it is in the pantry.
        let cookable: Bool
    }

    var words: [WallWord] = []
    var opens: [String: Kind] = [:]
    var stateLine: [String] = []
    var hidden = 0
    /// Out or low, open names only, out first.
    var low: [String] = []
    var cookable: [String] = []

    static let maxWords = 14

    /// `tonight` is the planned dish's shown title (already "Private recipe" when walled), nil when nothing is planned.
    static func build(stock: [Stock], dishes: [Dish], tonight: String?, start: String?,
                      cooking: String?) -> KitchenWall
    {
        var wall = KitchenWall()
        func add(_ id: String, _ text: String, _ kind: Kind, _ weight: Double) {
            guard wall.words.count < maxWords, wall.opens[id] == nil else { return }
            wall.words.append(WallWord(id: id, text: NotesLandingPage.short(text), weight: weight))
            wall.opens[id] = kind
        }
        let openStock = stock.filter { !$0.isPrivate }
        let short = openStock.filter { $0.state == .out || $0.state == .low }.sorted { $0.state < $1.state }
        wall.low = short.map(\.name)
        let ready = dishes.filter { $0.cookable && !$0.isPrivate }
        wall.cookable = ready.map(\.title)
        // Low stock and cookable dishes first, woven so both kinds sit high on the wall.
        var rank = 0
        for index in 0 ..< max(short.count, ready.count) {
            if index < short.count {
                add(
                    "pantry:\(short[index].name.lowercased())",
                    short[index].name,
                    .pantry,
                    max(0.55, 1 - 0.05 * Double(rank))
                )
                rank += 1
            }
            if index < ready.count {
                add("recipe:\(ready[index].id.uuidString)", ready[index].title, .recipe(ready[index].id),
                    max(0.55, 0.98 - 0.05 * Double(rank)))
                rank += 1
            }
        }
        for (offset, dish) in dishes.enumerated() where !dish.isPrivate && !dish.cookable {
            add("recipe:\(dish.id.uuidString)", dish.title, .recipe(dish.id), max(0.1, 0.45 - 0.03 * Double(offset)))
        }
        for (offset, item) in openStock.enumerated() where item.state == .have {
            add("pantry:\(item.name.lowercased())", item.name, .pantry, max(0.05, 0.3 - 0.02 * Double(offset)))
        }
        wall.hidden = stock.count(where: \.isPrivate) + dishes.count(where: \.isPrivate)
        wall.stateLine = stateLine(tonight: tonight, start: start, cooking: cooking, cookable: ready.count)
        return wall
    }

    /// A cook running: its own line first. Planned: "Tacos tonight, start at 6:05." then shorter. Nothing planned:
    /// "Tonight? Nothing planned yet, you could make 4." and shorter (contract §12 empty state).
    static func stateLine(tonight: String?, start: String?, cooking: String?, cookable: Int) -> [String] {
        var forms: [String] = []
        if let cooking {
            forms.append(cooking)
        }
        if let tonight {
            if let start {
                forms.append("\(tonight) tonight, start at \(start).")
                forms.append("\(tonight) tonight, \(start).")
            }
            forms.append("\(tonight) tonight.")
            return forms
        }
        if cookable > 0 {
            forms.append("Tonight? Nothing planned yet, you could make \(cookable).")
        }
        forms.append("Tonight? Nothing planned yet.")
        forms.append("Nothing planned yet.")
        return forms
    }

    /// "Eggs and milk run out first." / "Eggs runs out first." Nothing low: nil.
    var lowLine: [LandingBrief.Form]? {
        guard let first = low.first else { return nil }
        if low.count >= 2 {
            let pair = "\(low[0]) and \(low[1])"
            return [LandingBrief.Form(text: "\(pair) run out first.", key: pair),
                    LandingBrief.Form(text: "\(first) runs out first.", key: first)]
        }
        return [LandingBrief.Form(text: "\(first) runs out first.", key: first)]
    }
}

// MARK: - The page

/// Kitchen's landing on the shared kit (landing contract §12): the word wall of pantry and recipe words (what runs
/// low and what you could cook first), the doors on the dial, one brief line, "Cook" (or "Plan tonight") at the foot.
/// Behind Settings › Review › "Landing pages" (default Off).
struct KitchenLandingPage: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openHomeLink) private var open
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var cookCover: KitchenCookCover?
    @State private var recipe: KitchenCookCover?
    @State private var focus = 0

    var body: some View {
        let _ = model.revision
        let front = KitchenFront(model: model, now: AppClock.now)
        let wall = load(front)
        LandingFrame(title: "Kitchen", accent: LandingAccent.kitchen, stateLine: wall.stateLine,
                     keystone: {
                         LandingKeystone(label: "Pantry and recipes") {
                             WordWallView(words: wall.words) { id in
                                 switch wall.opens[id] {
                                 case let .recipe(uuid): recipe = .init(id: uuid)
                                 case .pantry: open(.pantry)
                                 case nil: break
                                 }
                             }
                         }
                     },
                     doors: doors(front, wall), focus: $focus,
                     openDoor: { door in
                         switch door.id {
                         case "pantry", "leftovers": open(.pantry)
                         case "shopping": open(.groceries)
                         default: open(.recipes)
                         }
                     },
                     brief: { brief(front, wall) },
                     action: action(front),
                     onBack: { dismiss() })
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(item: $cookCover) { CookClockPage(cookID: $0.id) }
            .fullScreenCover(item: $recipe) { RecipeView(recipeID: $0.id) }
    }

    // MARK: Facts

    private func load(_ front: KitchenFront) -> KitchenWall {
        let ledger = PantryLedger(store: model.store, classes: model.classes)
        let stock = ledger.entries().map { KitchenWall.Stock(name: $0.label, state: $0.state, isPrivate: $0.isPrivate) }
        let covered = Set(TesseraCore.KitchenLanding(store: model.store, classes: model.classes).coveredRecipes()
            .map(\.id))
        let book = RecipeBook(store: model.store, classes: model.classes)
        let dishes = book.recipes().filter { !$0.isDeleted }
            .sorted { $0.updatedAt > $1.updatedAt }
            .map { recipe in
                KitchenWall.Dish(
                    id: recipe.id,
                    title: recipe.title,
                    isPrivate: RecipeCopy.isPrivate(recipe.title, model: model),
                    cookable: covered.contains(recipe.id)
                )
            }
        return KitchenWall.build(stock: stock, dishes: dishes, tonight: front.tonight?.title,
                                 start: front.tonight.map { HouseTime.clock($0.start) }, cooking: front.cooking?.line)
    }

    /// Pantry, Recipes, Shopping, Leftovers, Meal plan (contract §12). Leftovers has no model yet and opens Pantry.
    private func doors(_ front: KitchenFront, _ wall: KitchenWall) -> [DialDoor] {
        let dark = scheme == .dark
        let wine = dark ? Color(hex: 0xEE8E9C) : Color(hex: 0x9A2541)
        let slate = dark ? Color(hex: 0xA7BCD6) : Color(hex: 0x34506F)
        let planned = front.week.compactMap { day in day.meal.map { "\(day.weekday) \($0.title)" } }
        var doors = [
            DialDoor(id: "pantry", name: "Pantry", count: wall.low.isEmpty ? nil : "\(wall.low.count)",
                     color: wall.low.isEmpty ? Theme.Colors.ink : wine,
                     label: wall.low.isEmpty ? "Nothing running low" : "Running low", lines: Array(wall.low.prefix(3))),
            DialDoor(id: "recipes", name: "Recipes", count: front.saved > 0 ? "\(front.saved)" : nil,
                     color: LandingAccent.kitchen,
                     label: wall.cookable.isEmpty ? nil : "You can make \(wall.cookable.count) now",
                     lines: Array(wall.cookable.prefix(3))),
            DialDoor(id: "shopping", name: "Shopping", count: front.toGet > 0 ? "\(front.toGet)" : nil,
                     color: Theme.Colors.ink, label: front.pantryValue),
            DialDoor(id: "leftovers", name: "Leftovers", color: Theme.Colors.ink, label: "Kept in Pantry for now"),
            DialDoor(id: "plan", name: "Meal plan", count: planned.isEmpty ? nil : "\(planned.count)", color: slate,
                     label: planned.isEmpty ? "Nothing planned yet" : "Next \(front.week.count) days",
                     lines: Array(planned.prefix(3))),
        ]
        if wall.hidden > 0 {
            doors.append(DialDoor(id: "private", name: "Private", count: "\(wall.hidden)", color: slate,
                                  label: "Kept off the wall", lines: ["\(wall.hidden) kept private"]))
        }
        return doors
    }

    @ViewBuilder
    private func brief(_ front: KitchenFront, _ wall: KitchenWall) -> some View {
        if let cook = front.cooking {
            Button { cookCover = .init(id: cook.id) } label: {
                LandingBrief(cook.line)
                    .frame(minHeight: 44, alignment: .topLeading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Goes on with the cook")
        } else if let low = wall.lowLine {
            LandingBrief(forms: low)
        } else if let value = front.pantryValue {
            LandingBrief(value.prefix(1).uppercased() + value.dropFirst() + ".")
        }
    }

    /// Cook when a meal is planned tonight, else Plan tonight. Drag right: Paste a recipe.
    private func action(_ front: KitchenFront) -> LandingFootAction {
        let paste = LandingFootAction.Option(name: "Paste a recipe") { open(.pasteRecipe) }
        if let meal = front.tonight {
            return LandingFootAction(word: "Cook", hint: "Starts \(meal.title)", right: paste) { cook(meal) }
        }
        return LandingFootAction(word: "Plan tonight", hint: "Opens Recipes", right: paste) { open(.recipes) }
    }

    /// Cook: tonight's recipe starts at its size and its clock opens (the same as Cook on the recipe page).
    private func cook(_ meal: KitchenFront.Meal) {
        guard let recipe = meal.recipe else {
            open(.recipes)
            return
        }
        guard let cook = try? model.engine.perform(StartCooking(recipe: recipe, time: AppClock.now), by: .user).output
        else {
            TessVoice.shared.say("Didn't start that. Try again.")
            return
        }
        model.touch()
        cookCover = .init(id: cook.id)
    }
}

struct KitchenCookCover: Identifiable {
    let id: UUID
}

#if DEBUG
    /// `-kitchen`: the Kitchen landing on its own, with its doors opening as Home would open them.
    struct KitchenLandingHost: View {
        @State private var link: HomeLink?

        var body: some View {
            KitchenLandingPage()
                .environment(\.openHomeLink) { link = $0 }
                .fullScreenCover(item: $link) { $0.destination }
        }
    }
#endif
