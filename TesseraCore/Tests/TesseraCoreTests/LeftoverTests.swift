import Foundation
@testable import TesseraCore
import Testing

/// Sheet 234: place categories, leftovers and their reminders, meals, the numbers kept on this phone, the photo file.
@MainActor
struct LeftoverTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine
    let book: LeftoverBook
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }

    func at(_ day: Int, _ hour: Int = 12, month: Int = 10) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour))!
    }

    init() throws {
        let classes = try store.prepareCatalog()
        self.classes = classes
        engine = ActionEngine(store: store, classes: classes)
        book = LeftoverBook(store: store, classes: classes)
        engine.zone = { TimeZone(identifier: "America/Los_Angeles")! }
        engine.now = { Date(timeIntervalSince1970: 1_792_000_000) }
        PantryPlaces(store: store, classes: classes).ensureDefaults()
    }

    func recipe(_ title: String, lines: [(String, Double, KitchenUnit, String)] = [("Rice", 200, .gram, "200 g rice")],
                serves: Double = 2) throws -> ObjectRecord
    {
        let recipe = try store.create(#require(classes[.recipe]), title: title)
        try store.set("serves", to: .number(serves), on: recipe)
        for (name, amount, unit, original) in lines {
            let line = try store.create(#require(classes[.recipeLine]), title: name, parent: recipe)
            try store.set("amount", to: .number(amount), on: line)
            try store.set("unit", to: .text(unit.rawValue), on: line)
            try store.set("original", to: .text(original), on: line)
            let ingredient = try store.create(#require(classes[.ingredient]), title: name)
            try store.setLinks("ingredient", on: line, to: [ingredient])
        }
        return recipe
    }

    // MARK: Place categories

    @Test func theDefaultPlacesCarryTheSheetsCategories() throws {
        let places = PantryPlaces(store: store, classes: classes)
        func sections(_ key: String) throws -> [String] {
            try places.sections(of: #require(store.object(id: PantryPlaces.defaultID(key))))
        }
        #expect(try sections("fridge") == ["Leftovers", "Dairy and eggs", "Vegetables", "Fruit"])
        #expect(try sections("freezer") == ["Cooked", "Meat and fish", "Vegetables", "Bread"])
        #expect(try sections("shelf") == ["Dal and lentils", "Grains and pasta", "Snacks", "Spices"])
        #expect(try sections("counter") == ["Fruit", "Vegetables"])
        #expect(PantryPlaces.toGetSections == ["For a recipe", "Next shop"])
    }

    @Test func aPlaceStillOnTheFirstVersionsWordsAdoptsTheNewOnesAndHisOwnStay() throws {
        let places = PantryPlaces(store: store, classes: classes)
        let fridge = try #require(store.object(id: PantryPlaces.defaultID("fridge")))
        try store.set("sections", to: .text("Door,Shelves,Drawer"), on: fridge)
        let freezer = try #require(store.object(id: PantryPlaces.defaultID("freezer")))
        try store.set("sections", to: .text("Top,Bottom"), on: freezer)
        #expect(places.adoptCategories() == 1)
        #expect(places.sections(of: fridge).first == "Leftovers")
        #expect(places.sections(of: freezer) == ["Top", "Bottom"])
        #expect(places.adoptCategories() == 0)
    }

    @Test func aThingWithNoCategoryGoesInTheLastSection() throws {
        let fridge = PantryPlaces.defaultID("fridge")
        let milk = try engine.perform(AddToPlace(name: "Milk", place: fridge, section: "Dairy and eggs"), by: .user)
            .output.ingredient
        let loose = try engine.perform(AddToPlace(name: "Mystery jar", place: fridge), by: .user).output.ingredient
        let place = try #require(store.object(id: fridge))
        let groups = PantryPlaces(store: store, classes: classes).grouped(in: place)
        #expect(groups.map(\.section) == ["Dairy and eggs", "Fruit"])
        #expect(groups.last?.ingredients.map(\.id) == [loose.id])
        #expect(groups.first?.ingredients.map(\.id) == [milk.id])
    }

    // MARK: Reminders

    @Test func remindersFireAtTenAndTonightAtEightNeverInTheQuietHours() {
        let day = at(20, 0)
        let morning = LeftoverReminders.fireDate(throwOutOn: day, reminder: .morning, now: at(17), calendar: calendar)
        #expect(morning == at(20, 10))
        let before = LeftoverReminders.fireDate(throwOutOn: day, reminder: .dayBefore, now: at(17), calendar: calendar)
        #expect(before == at(19, 10))
        // Its morning has gone by, still today before 8 PM: tonight.
        #expect(LeftoverReminders.fireDate(throwOutOn: day, reminder: .morning, now: at(20, 13), calendar: calendar)
            == at(20, 20))
        // After 8 PM, or a day gone by: nothing.
        #expect(LeftoverReminders.fireDate(throwOutOn: day, reminder: .morning, now: at(20, 21), calendar: calendar)
            == nil)
        #expect(LeftoverReminders.fireDate(throwOutOn: day, reminder: .morning, now: at(22), calendar: calendar) == nil)
        #expect(LeftoverReminders.fireDate(throwOutOn: day, reminder: .off, now: at(17), calendar: calendar) == nil)
        for hour in 0 ..< 24 {
            for reminder in [LeftoverReminder.morning, .dayBefore] {
                if let fire = LeftoverReminders.fireDate(throwOutOn: day, reminder: reminder, now: at(18, hour),
                                                         calendar: calendar)
                {
                    #expect(!LeftoverReminders.isQuiet(fire, calendar: calendar))
                }
            }
        }
    }

    // MARK: Putting away, eating, throwing out

    @Test func puttingAwayCooksALeftoverWithDefaultsAndAReminderId() throws {
        let shakshuka = try recipe("Shakshuka")
        let made = at(18)
        let result = try engine.perform(PutAwayLeftover(recipe: shakshuka.id, servings: 3, madeOn: made), by: .user)
        let entry = book.read(result.output.leftover)
        #expect(entry.title == "Shakshuka" && entry.servingsLeft == 3 && entry.portionLeft == nil)
        #expect(entry.place == .fridge && entry.reminder == .morning)
        #expect(entry.throwOutOn == calendar.date(byAdding: .day, value: 3, to: made))
        #expect(entry.notificationId == result.output.change.schedule && entry.notificationId != nil)
        #expect(result.record.receipt == "Shakshuka, put away in the fridge.")
        let frozen = try engine.perform(PutAwayLeftover(recipe: shakshuka.id, servings: 2, place: .freezer,
                                                        reminder: .off, madeOn: made), by: .user)
        let ice = book.read(frozen.output.leftover)
        #expect(ice.throwOutOn == calendar.date(byAdding: .day, value: 90, to: made) && ice.notificationId == nil)
        #expect(throws: ActionError.self) {
            try engine.perform(PutAwayLeftover(recipe: shakshuka.id, servings: 0), by: .user)
        }
        engine.undo(result.record)
        #expect(book.all().map(\.id) == [ice.id])
    }

    @Test func aLeftoverFromAPrivateRecipeReadsPrivateMeal() throws {
        let doctor = try recipe("Dr Lin's broth")
        let put = try engine.perform(PutAwayLeftover(recipe: doctor.id, servings: 2), by: .user)
        #expect(put.record.receipt == "Private meal, put away in the fridge.")
        #expect(book.read(put.output.leftover).title == ObjectPrivacy.mealLabel)
        let eaten = try engine.perform(EatServing(leftover: put.output.leftover.id, time: at(19)), by: .user)
        #expect(ObjectPrivacy.label(of: eaten.output.meal, in: store, classes: classes) == ObjectPrivacy.mealLabel)
        #expect(eaten.record.receipt?.contains("Lin") != true)
    }

    @Test func aDismissedMealLeavesNoNumbersBehind() throws {
        let rice = try recipe("Plain rice")
        let put = try engine.perform(PutAwayLeftover(recipe: rice.id, servings: 2), by: .user)
        let eaten = try engine.perform(EatServing(leftover: put.output.leftover.id, time: at(19)), by: .user,
                                       pending: true)
        #expect(book.nutrition(of: eaten.output.meal) != nil)
        try engine.discard(eaten.record)
        let rows = try store.objects(of: #require(classes[.mealNutrition])).filter { !$0.isDeleted }
        #expect(rows.isEmpty)
    }

    @Test func eatingServesOneAndWritesTheMealWithItsNumbersOnThisPhone() throws {
        let rice = try recipe("Plain rice", lines: [("Rice", 200, .gram, "200 g rice")], serves: 2)
        let put = try engine.perform(PutAwayLeftover(recipe: rice.id, servings: 2), by: .user)
        let leftover = put.output.leftover
        let first = try engine.perform(EatServing(leftover: leftover.id, time: at(19)), by: .user)
        let meal = first.output.meal
        #expect(first.record.receipt == "Plain rice, eaten.")
        #expect(store.value("source", of: meal) == .choice("cooked") && store.number("portionEaten", of: meal) == 1)
        #expect(store.value("estimateSource", of: meal) == .choice("device"))
        let numbers = try #require(book.nutrition(of: meal))
        // 200 g dry rice is 730 kcal; a serving of two is 365.
        #expect(abs(numbers.cal - 365) < 0.5)
        #expect(book.read(leftover).servingsLeft == 1 && first.output.change.cancel == nil)
        #expect(book.meals(on: at(19), calendar: calendar).map(\.id) == [meal.id])
        // The numbers are in no op: the op log never saw a calorie.
        #expect(first.record.ops.allSatisfy { op in
            if case let .create(_, classID, _, _) = op {
                classID != classes[.mealNutrition]?.id
            } else {
                true
            }
        })
        // Undo hides them with the meal; redo shows them again.
        engine.undo(first.record)
        #expect(book.nutrition(of: meal) == nil && book.read(leftover).servingsLeft == 2)
        engine.redo(first.record)
        #expect(book.nutrition(of: meal) != nil)
        // The last serving finishes the leftover and cancels its reminder.
        let last = try engine.perform(EatServing(leftover: leftover.id, time: at(20)), by: .user)
        #expect(last.output.change.cancel == put.output.change.schedule)
        #expect(book.all().isEmpty)
    }

    @Test func eatingTypedCaloriesAndMoreThanLeftAreHandled() throws {
        let stew = try recipe("Mystery stew", lines: [("Saffron buns", 2, .piece, "2 saffron buns")])
        let put = try engine.perform(PutAwayLeftover(recipe: stew.id, servings: 2), by: .user)
        // The table cannot count it: no numbers, unless he types them.
        let plain = try engine.perform(EatServing(leftover: put.output.leftover.id), by: .user)
        #expect(book.nutrition(of: plain.output.meal) == nil)
        let typed = try engine.perform(EatServing(leftover: put.output.leftover.id, calories: 450), by: .user)
        #expect(book.nutrition(of: typed.output.meal)?.cal == 450)
        #expect(store.value("estimateSource", of: typed.output.meal) == .choice("typed"))
        #expect(throws: ActionError.self) {
            try engine.perform(EatServing(leftover: put.output.leftover.id), by: .user)
        }
    }

    @Test func throwingOutCancelsTheReminder() throws {
        let rice = try recipe("Rice")
        let put = try engine.perform(PutAwayLeftover(recipe: rice.id, servings: 1), by: .user)
        let out = try engine.perform(ThrowOutLeftover(leftover: put.output.leftover.id), by: .user)
        #expect(out.output.cancel == put.output.change.schedule && out.output.schedule == nil)
        #expect(out.record.receipt == "Rice, thrown out." && book.all().isEmpty)
        engine.undo(out.record)
        #expect(book.all().count == 1)
    }

    @Test func movingOrChangingTheDayCancelsTheOldReminderAndAsksForANewOne() throws {
        let rice = try recipe("Rice")
        let put = try engine.perform(PutAwayLeftover(recipe: rice.id, servings: 1), by: .user)
        let old = put.output.change.schedule
        let moved = try engine.perform(MoveLeftover(leftover: put.output.leftover.id, place: .freezer), by: .user)
        #expect(moved.output.cancel == old && moved.output.schedule != nil && moved.output.schedule != old)
        #expect(book.read(put.output.leftover).place == .freezer)
        #expect(moved.record.receipt == "Rice, moved to the freezer.")
        let changed = try engine.perform(
            SetThrowOutDay(leftover: put.output.leftover.id, throwOutOn: at(30)),
            by: .user
        )
        #expect(changed.output.cancel == moved.output.schedule && changed.output.schedule != nil)
        #expect(book.read(put.output.leftover).throwOutOn == at(30))
        let pending = book.pendingReminders(now: at(1), calendar: calendar)
        #expect(try pending.map(\.id) == [#require(changed.output.schedule)] && pending.first?.fire == at(30, 10))
    }

    // MARK: Food from outside

    @Test func anOutsideMealKeepsQuartersAndNamesTheSentRowWhenClaudeEstimated() throws {
        let meal = try engine.perform(LogOutsideMeal(title: "Pizza at Sam's", calories: 900, proteinG: 35,
                                                     carbsG: 100, fatG: 40, estimateSource: .typed, quartersLeft: 2,
                                                     time: at(19)), by: .user)
        #expect(meal.record.receipt == "Pizza at Sam's, logged.")
        #expect(book.nutrition(of: meal.output.meal)?.proteinG == 35)
        let leftover = try #require(book.all().first)
        #expect(leftover.portionLeft == 2 && leftover.servingsLeft == nil && leftover.title == "Pizza at Sam's")
        let ate = try engine.perform(EatServing(leftover: leftover.id, portion: 1, calories: 225), by: .user)
        #expect(store.value("source", of: ate.output.meal) == .choice("outside"))
        #expect(try book.read(#require(store.object(id: leftover.id))).portionLeft == 1)
        // A Claude estimate without the sent-log row is refused; with it, the row is kept.
        #expect(throws: ActionError.self) {
            try engine.perform(LogOutsideMeal(title: "Salad", calories: 300, estimateSource: .claude), by: .user)
        }
        let guess = try engine.perform(LogOutsideMeal(title: "Salad", calories: 300, estimateSource: .claude,
                                                      sentLogId: "row-1"), by: .user)
        #expect(store.value("sentLogId", of: guess.output.meal) == .text("row-1"))
        #expect(throws: ActionError.self) { try engine.perform(LogOutsideMeal(title: "x", quartersLeft: 4), by: .user) }
        #expect(throws: ActionError.self) {
            try engine.perform(LogOutsideMeal(title: "sk-ant-api03-abcdefghijklmnopqrstuv"), by: .user)
        }
    }

    // MARK: Privacy

    @Test func aPrivateMealReadsPrivateAndTheNumbersAreInNoCopy() throws {
        let meal = try engine.perform(LogOutsideMeal(title: "Dinner paid $60 cash", calories: 500), by: .user).output
            .meal
        #expect(ObjectPrivacy.label(of: meal, in: store, classes: classes) == ObjectPrivacy.mealLabel)
        let rows = try store.objects(of: #require(classes[.mealNutrition]))
        #expect(rows.count == 1 && rows.allSatisfy { PrivateWords.isMirror($0) })
        let leftover = try engine.perform(LogOutsideMeal(title: "Burger", quartersLeft: 1), by: .user)
        _ = leftover
        #expect(book.all().allSatisfy { $0.title == "Burger" })
    }

    @Test func aMealPhotoIsAProtectedFileKeyedByTheMealAndNeverInABackup() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("meal-photos-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }
        let photos = MealPhotoStore(directory: dir, protection: [])
        let meal = UUID()
        let data = Data([1, 2, 3, 4])
        let url = try photos.save(data, for: meal)
        #expect(url.lastPathComponent == "\(meal.uuidString).jpg" && photos.load(for: meal) == data)
        let values = try url.resourceValues(forKeys: [.isExcludedFromBackupKey])
        #expect(values.isExcludedFromBackup == true)
        photos.delete(for: meal)
        #expect(photos.load(for: meal) == nil)
        #expect(MealPhotoStore(directory: dir).protection == .completeFileProtection)
    }

    @Test func everyActionDecodesFromItsName() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let id = UUID()
        func check<A: EngineAction>(_ action: A) throws {
            let decoded = try ActionRegistry.decode(name: A.descriptor.name, arguments: encoder.encode(action))
            #expect(decoded is A, "\(A.descriptor.name)")
        }
        try check(PutAwayLeftover(recipe: id, servings: 2))
        try check(EatServing(leftover: id))
        try check(ThrowOutLeftover(leftover: id))
        try check(MoveLeftover(leftover: id, place: .freezer))
        try check(SetThrowOutDay(leftover: id, throwOutOn: Date(timeIntervalSince1970: 1_700_000_000)))
        try check(LogOutsideMeal(title: "Pizza"))
    }
}
