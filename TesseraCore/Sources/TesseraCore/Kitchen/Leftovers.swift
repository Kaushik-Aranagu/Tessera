import Foundation

/// Leftovers and meals (sheet 234): cooked food put away, eaten by the serving, thrown out; food from outside. Words
/// about food only; the numbers behind a meal stay on this phone (`MealNutrition`), and nothing here goes to Claude.
public enum LeftoverPlace: String, Codable, Sendable, CaseIterable {
    case fridge, freezer
}

public enum LeftoverReminder: String, Codable, Sendable, CaseIterable {
    case morning, dayBefore, off
}

public enum EstimateSource: String, Codable, Sendable, CaseIterable {
    /// Counted on the phone from the food table.
    case device
    /// Typed by him.
    case typed
    /// Estimated by Claude: only with a sent-log row (`sentLogId`), only in lab mode with asksClaude on.
    case claude
}

/// One leftover as a screen reads it.
public struct LeftoverEntry: Identifiable, Equatable {
    public let id: UUID
    /// The source's words, or "Private meal".
    public let title: String
    public let source: UUID?
    public let madeOn: Date?
    /// Cooked: servings left. Outside: nil.
    public let servingsLeft: Double?
    /// Outside: quarters left, 1 to 4. Cooked: nil.
    public let portionLeft: Double?
    public let place: LeftoverPlace
    public let throwOutOn: Date?
    public let reminder: LeftoverReminder
    public let notificationId: String?
}

/// When a reminder fires (sheet 234): 10 AM on the day, or on the day before; a reminder whose 10 AM has gone by fires
/// at
/// 8 PM tonight ("tonight"); never between 11 PM and 7 AM.
public enum LeftoverReminders {
    public static let morningHour = 10
    public static let tonightHour = 20

    public static func fireDate(throwOutOn: Date, reminder: LeftoverReminder, now: Date,
                                calendar: Calendar) -> Date?
    {
        guard reminder != .off else { return nil }
        let day = calendar.startOfDay(for: throwOutOn)
        let base = reminder == .dayBefore ? calendar.date(byAdding: .day, value: -1, to: day) ?? day : day
        guard let morning = calendar.date(bySettingHour: morningHour, minute: 0, second: 0, of: base)
        else { return nil }
        if morning > now {
            return morning
        }
        // Its morning has gone by: still today, still before 8 PM, it is "tonight".
        if calendar.isDate(now, inSameDayAs: base) || calendar.isDate(now, inSameDayAs: throwOutOn),
           let tonight = calendar.date(bySettingHour: tonightHour, minute: 0, second: 0, of: now), tonight > now
        {
            return tonight
        }
        return nil
    }

    /// Never in the quiet window.
    public static func isQuiet(_ date: Date, calendar: Calendar) -> Bool {
        let hour = calendar.component(.hour, from: date)
        return hour >= 23 || hour < 7
    }
}

@MainActor
public struct LeftoverBook {
    public let store: ObjectStore
    public let classes: [SystemCatalog.Key: ClassDef]

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) {
        self.store = store
        self.classes = classes
    }

    public func read(_ object: ObjectRecord) -> LeftoverEntry {
        let shown = ObjectPrivacy.label(of: object, in: store, classes: classes) ?? object.title
        return LeftoverEntry(
            id: object.id, title: shown, source: store.linkedObjects("source", of: object).first?.id,
            madeOn: store.value("madeOn", of: object)?.dateValue,
            servingsLeft: store.number("servingsLeft", of: object),
            portionLeft: store.number("portionLeft", of: object),
            place: store.value("place", of: object)?.stringValue.flatMap(LeftoverPlace.init(rawValue:)) ?? .fridge,
            throwOutOn: store.value("throwOutOn", of: object)?.dateValue,
            reminder: store.value("reminder", of: object)?.stringValue.flatMap(LeftoverReminder.init(rawValue:))
                ?? .morning,
            notificationId: store.value("notificationId", of: object)?.stringValue.flatMap { $0.isEmpty ? nil : $0 }
        )
    }

    /// What is in the fridge and freezer now, soonest to throw out first.
    public func all() -> [LeftoverEntry] {
        guard let leftoverClass = classes[.leftover] else { return [] }
        return store.objects(of: leftoverClass).filter { !$0.isDeleted }.map(read).sorted {
            ($0.throwOutOn ?? .distantFuture, $0.title) < ($1.throwOutOn ?? .distantFuture, $1.title)
        }
    }

    /// The reminders the app should have scheduled now: id, when, and the words (the shown title).
    public func pendingReminders(now: Date, calendar: Calendar) -> [(id: String, fire: Date, title: String)] {
        all().compactMap { entry in
            guard let id = entry.notificationId, let throwOut = entry.throwOutOn,
                  let fire = LeftoverReminders.fireDate(throwOutOn: throwOut, reminder: entry.reminder, now: now,
                                                        calendar: calendar),
                  !LeftoverReminders.isQuiet(fire, calendar: calendar) else { return nil }
            return (id, fire, entry.title)
        }
    }

    /// What a meal's numbers are, when this phone has them and the meal still exists.
    public func nutrition(of meal: ObjectRecord) -> (cal: Double, proteinG: Double?, carbsG: Double?, fatG: Double?)? {
        guard !meal.isDeleted, let nutritionClass = classes[.mealNutrition],
              let row = store.objects(of: nutritionClass).first(where: {
                  !$0.isDeleted && store.value("entryId", of: $0)?.stringValue == meal.id.uuidString
              }), let cal = store.number("cal", of: row) else { return nil }
        return (cal, store.number("proteinG", of: row), store.number("carbsG", of: row),
                store.number("fatG", of: row))
    }

    /// Meals eaten on a day, oldest first.
    public func meals(on day: Date, calendar: Calendar) -> [ObjectRecord] {
        guard let mealClass = classes[.mealEntry] else { return [] }
        let tessera = TesseraDay(calendar: calendar)
        return store.objects(of: mealClass).filter {
            !$0.isDeleted && (store.value("when", of: $0)?.dateValue).map { tessera.isSameDay($0, day) } == true
        }.sorted { ($0.createdAt, $0.id.uuidString) < ($1.createdAt, $1.id.uuidString) }
    }
}

// MARK: - Writing

enum LeftoverWrites {
    static let defaultDaysFridge = 3
    static let defaultDaysFreezer = 90

    /// Writes the numbers behind a meal on this phone only (no op, no backup): undoing the meal hides them, redoing it
    /// shows them again.
    @MainActor
    static func writeNutrition(for meal: ObjectRecord, cal: Double, protein: Double?, carbs: Double?, fat: Double?,
                               store: ObjectStore, classes: [SystemCatalog.Key: ClassDef])
    {
        guard let nutritionClass = classes[.mealNutrition], cal.isFinite, cal >= 0 else { return }
        let row = store.create(nutritionClass, title: meal.id.uuidString)
        try? store.set("entryId", to: .text(meal.id.uuidString), on: row)
        try? store.set("cal", to: .number(cal), on: row)
        for (key, value) in [("proteinG", protein), ("carbsG", carbs), ("fatG", fat)] {
            if let value, value.isFinite, value >= 0 {
                try? store.set(key, to: .number(value), on: row)
            }
        }
    }

    /// A fresh id for the app's notification request.
    static func newNotificationId() -> String {
        "leftover-\(UUID().uuidString)"
    }
}

/// What an action did to a leftover's reminder: the request to cancel, and the one to schedule.
public struct LeftoverReminderChange: Equatable {
    public var cancel: String?
    public var schedule: String?
}

/// Cooked food put away: servings of a recipe, in the fridge or freezer, with a throw-out day and a reminder.
public struct PutAwayLeftover: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "putAwayLeftover", summary: "Put cooked food away",
        parameters: [
            .init("recipe", .object, "What was cooked"), .init("servings", .integer, "Servings put away"),
            .init("place", .string, "fridge or freezer", required: false),
            .init("throwOutOn", .date, "When it goes; 3 days (fridge) or 90 (freezer) when left out", required: false),
            .init("reminder", .string, "morning, dayBefore or off", required: false),
        ], isOfferedToModel: false
    )

    public var recipe: UUID
    public var servings: Int
    public var place: LeftoverPlace?
    public var throwOutOn: Date?
    public var reminder: LeftoverReminder?
    public var madeOn: Date?

    public init(recipe: UUID, servings: Int, place: LeftoverPlace? = nil, throwOutOn: Date? = nil,
                reminder: LeftoverReminder? = nil, madeOn: Date? = nil)
    {
        self.recipe = recipe
        self.servings = servings
        self.place = place
        self.throwOutOn = throwOutOn
        self.reminder = reminder
        self.madeOn = madeOn
    }

    public func apply(_ transaction: inout Transaction) throws -> LeftoverMade {
        let source = try transaction.object(recipe, is: .recipe)
        guard (1 ... 24).contains(servings) else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "refused: servings")
        }
        let made = madeOn ?? transaction.now
        let spot = place ?? .fridge
        let days = spot == .fridge ? LeftoverWrites.defaultDaysFridge : LeftoverWrites.defaultDaysFreezer
        let until = throwOutOn ?? transaction.calendar.date(byAdding: .day, value: days, to: made) ?? made
        let mode = reminder ?? .morning
        let leftover = try transaction.create(transaction.classDef(.leftover), title: source.title)
        try transaction.setLinks("source", on: leftover, to: [source])
        try transaction.set("madeOn", to: .date(made), on: leftover)
        try transaction.set("servingsLeft", to: .number(Double(servings)), on: leftover)
        try transaction.set("place", to: .choice(spot.rawValue), on: leftover)
        try transaction.set("throwOutOn", to: .date(until), on: leftover)
        try transaction.set("reminder", to: .choice(mode.rawValue), on: leftover)
        let id = mode == .off ? nil : LeftoverWrites.newNotificationId()
        if let id {
            try transaction.set("notificationId", to: .text(id), on: leftover)
        }
        return LeftoverMade(leftover: leftover, change: LeftoverReminderChange(cancel: nil, schedule: id))
    }

    public func summary(in store: ObjectStore) -> String {
        "Put \(store.object(id: recipe).map { PantryPlaces.shown($0, in: store) } ?? "food") away"
    }

    public func receipt(in store: ObjectStore, output: LeftoverMade) -> String? {
        let entry = LeftoverBook(store: store, classes: PrivateWords.systemClasses(in: store.context))
            .read(output.leftover)
        return "\(entry.title), put away in the \(entry.place.rawValue)."
    }

    public func receipt(in _: ObjectStore) -> String? {
        nil
    }
}

public struct LeftoverMade {
    public let leftover: ObjectRecord
    public let change: LeftoverReminderChange
}

/// What eating a serving did: the meal, and the reminder to cancel when it was the last.
public struct MealEaten {
    public let meal: ObjectRecord
    public let change: LeftoverReminderChange
}

/// Eats from a leftover: a MealEntry, a share of the numbers on this phone, and fewer servings (or quarters) left. The
/// last one finishes the leftover and cancels its reminder.
public struct EatServing: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "eatServing", summary: "Eat a serving of a leftover",
        parameters: [
            .init("leftover", .object, "The leftover"),
            .init("portion", .number, "Servings (cooked) or quarters (outside); 1 when left out", required: false),
            .init("calories", .number, "Typed calories for this meal", required: false),
            .init("time", .date, "Defaults to now", required: false),
        ], isOfferedToModel: false
    )

    public var leftover: UUID
    public var portion: Double?
    public var calories: Double?
    public var time: Date?

    public init(leftover: UUID, portion: Double? = nil, calories: Double? = nil, time: Date? = nil) {
        self.leftover = leftover
        self.portion = portion
        self.calories = calories
        self.time = time
    }

    public func apply(_ transaction: inout Transaction) throws -> MealEaten {
        let object = try transaction.object(leftover, is: .leftover)
        let store = transaction.store
        let eaten = portion ?? 1
        guard eaten > 0, eaten.isFinite else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "refused: portion")
        }
        let cooked = store.number("servingsLeft", of: object) != nil
        let key = cooked ? "servingsLeft" : "portionLeft"
        let left = store.number(key, of: object) ?? 0
        guard eaten <= left else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "refused: moreThanLeft")
        }
        let when = time ?? transaction.now
        let meal = try transaction.create(transaction.classDef(.mealEntry), title: object.title)
        try transaction.set("when", to: .date(when), on: meal)
        try transaction.set("source", to: .choice(cooked ? "cooked" : "outside"), on: meal)
        try transaction.set("portionEaten", to: .number(eaten), on: meal)
        try transaction.setLinks("leftover", on: meal, to: [object])
        var numbers: (cal: Double, protein: Double?, carbs: Double?, fat: Double?)?
        var estimate: EstimateSource?
        if let calories {
            numbers = (calories * eaten, nil, nil, nil)
            estimate = .typed
        } else if cooked, let recipe = store.linkedObjects("source", of: object).first,
                  let serving = Nutrition.perServing(recipe: recipe, store: store, classes: transaction.classes)
        {
            numbers = (serving.energyKcal * eaten, serving.protein.map { $0 * eaten },
                       serving.carbohydrate.map { $0 * eaten }, serving.fat.map { $0 * eaten })
            estimate = .device
        }
        if let estimate {
            try transaction.set("estimateSource", to: .choice(estimate.rawValue), on: meal)
        }
        let remaining = left - eaten
        var change = LeftoverReminderChange()
        if remaining <= 0 {
            // The last of it: the leftover is finished, its reminder with it.
            change.cancel = store.value("notificationId", of: object)?.stringValue.flatMap { $0.isEmpty ? nil : $0 }
            transaction.delete(object)
        } else {
            try transaction.set(key, to: .number(remaining), on: object)
        }
        if let numbers {
            LeftoverWrites.writeNutrition(for: meal, cal: numbers.cal, protein: numbers.protein,
                                          carbs: numbers.carbs, fat: numbers.fat, store: store,
                                          classes: transaction.classes)
        }
        return MealEaten(meal: meal, change: change)
    }

    public func summary(in store: ObjectStore) -> String {
        "Ate \(store.object(id: leftover).map { LeftoverBook.shown($0, in: store) } ?? "a serving")"
    }

    public func receipt(in store: ObjectStore, output: MealEaten) -> String? {
        "\(LeftoverBook.shown(output.meal, in: store)), eaten."
    }

    public func receipt(in _: ObjectStore) -> String? {
        nil
    }
}

extension LeftoverBook {
    /// A title as any surface outside the room says it.
    static func shown(_ object: ObjectRecord, in store: ObjectStore) -> String {
        let classes = PrivateWords.systemClasses(in: store.context)
        return ObjectPrivacy.shownLabel(of: object, in: store, classes: classes) ?? object.title
    }
}

/// Throws a leftover out. Its reminder is cancelled.
public struct ThrowOutLeftover: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "throwOutLeftover", summary: "Throw a leftover out",
        parameters: [.init("leftover", .object, "The leftover")], isOfferedToModel: false
    )

    public var leftover: UUID

    public init(leftover: UUID) {
        self.leftover = leftover
    }

    public func apply(_ transaction: inout Transaction) throws -> LeftoverReminderChange {
        let object = try transaction.object(leftover, is: .leftover)
        let id = transaction.store.value("notificationId", of: object)?.stringValue.flatMap { $0.isEmpty ? nil : $0 }
        transaction.delete(object)
        return LeftoverReminderChange(cancel: id, schedule: nil)
    }

    public func summary(in store: ObjectStore) -> String {
        "Threw out \(store.object(id: leftover).map { LeftoverBook.shown($0, in: store) } ?? "a leftover")"
    }

    public func receipt(in store: ObjectStore, output _: LeftoverReminderChange) -> String? {
        guard let object = store.object(id: leftover) else { return nil }
        return "\(LeftoverBook.shown(object, in: store)), thrown out."
    }

    public func receipt(in _: ObjectStore) -> String? {
        nil
    }
}

/// Moves a leftover between the fridge and the freezer. The old reminder is cancelled and a new one asked for.
public struct MoveLeftover: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "moveLeftover", summary: "Move a leftover",
        parameters: [.init("leftover", .object, "The leftover"), .init("place", .string, "fridge or freezer"),
                     .init("throwOutOn", .date, "A new throw-out day", required: false)],
        isOfferedToModel: false
    )

    public var leftover: UUID
    public var place: LeftoverPlace
    public var throwOutOn: Date?

    public init(leftover: UUID, place: LeftoverPlace, throwOutOn: Date? = nil) {
        self.leftover = leftover
        self.place = place
        self.throwOutOn = throwOutOn
    }

    public func apply(_ transaction: inout Transaction) throws -> LeftoverReminderChange {
        let object = try transaction.object(leftover, is: .leftover)
        try transaction.set("place", to: .choice(place.rawValue), on: object)
        if let throwOutOn {
            try transaction.set("throwOutOn", to: .date(throwOutOn), on: object)
        }
        return try LeftoverWrites.reschedule(object, in: &transaction)
    }

    public func summary(in store: ObjectStore) -> String {
        "Moved \(store.object(id: leftover).map { LeftoverBook.shown($0, in: store) } ?? "a leftover")"
    }

    public func receipt(in store: ObjectStore, output _: LeftoverReminderChange) -> String? {
        guard let object = store.object(id: leftover) else { return nil }
        return "\(LeftoverBook.shown(object, in: store)), moved to the \(place.rawValue)."
    }

    public func receipt(in _: ObjectStore) -> String? {
        nil
    }
}

/// Changes the throw-out day. The old reminder is cancelled and a new one asked for.
public struct SetThrowOutDay: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "setThrowOutDay", summary: "Change when a leftover goes",
        parameters: [.init("leftover", .object, "The leftover"), .init("throwOutOn", .date, "The new day")],
        isOfferedToModel: false
    )

    public var leftover: UUID
    public var throwOutOn: Date

    public init(leftover: UUID, throwOutOn: Date) {
        self.leftover = leftover
        self.throwOutOn = throwOutOn
    }

    public func apply(_ transaction: inout Transaction) throws -> LeftoverReminderChange {
        let object = try transaction.object(leftover, is: .leftover)
        try transaction.set("throwOutOn", to: .date(throwOutOn), on: object)
        return try LeftoverWrites.reschedule(object, in: &transaction)
    }

    public func summary(in store: ObjectStore) -> String {
        "Changed when \(store.object(id: leftover).map { LeftoverBook.shown($0, in: store) } ?? "a leftover") goes"
    }

    public func receipt(in store: ObjectStore, output _: LeftoverReminderChange) -> String? {
        guard let object = store.object(id: leftover) else { return nil }
        return "\(LeftoverBook.shown(object, in: store)), new day set."
    }

    public func receipt(in _: ObjectStore) -> String? {
        nil
    }
}

extension LeftoverWrites {
    /// Cancels the old request and asks for a new one (when the reminder is on).
    @MainActor
    static func reschedule(_ object: ObjectRecord, in transaction: inout Transaction) throws -> LeftoverReminderChange {
        let store = transaction.store
        let old = store.value("notificationId", of: object)?.stringValue.flatMap { $0.isEmpty ? nil : $0 }
        let mode = store.value("reminder", of: object)?.stringValue.flatMap(LeftoverReminder.init(rawValue:))
            ?? .morning
        let new = mode == .off ? nil : newNotificationId()
        try transaction.set("notificationId", to: new.map(FieldValue.text), on: object)
        return LeftoverReminderChange(cancel: old, schedule: new)
    }
}

/// Logs something eaten outside: the words, when, the numbers he typed or an estimate, and what is left (quarters).
public struct LogOutsideMeal: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "logOutsideMeal", summary: "Log a meal from outside",
        parameters: [
            .init("title", .string, "What it was"), .init("calories", .number, "Calories", required: false),
            .init("proteinG", .number, "Protein in grams", required: false),
            .init("carbsG", .number, "Carbs in grams", required: false),
            .init("fatG", .number, "Fat in grams", required: false),
            .init("estimateSource", .string, "device, typed or claude", required: false),
            .init("sentLogId", .string, "The sent-log row when Claude estimated", required: false),
            .init("quartersLeft", .integer, "1 to 3 quarters kept for later", required: false),
            .init("time", .date, "Defaults to now", required: false),
        ], isOfferedToModel: false
    )

    public var title: String
    public var calories: Double?
    public var proteinG: Double?
    public var carbsG: Double?
    public var fatG: Double?
    public var estimateSource: EstimateSource?
    public var sentLogId: String?
    public var quartersLeft: Int?
    public var time: Date?

    public init(title: String, calories: Double? = nil, proteinG: Double? = nil, carbsG: Double? = nil,
                fatG: Double? = nil, estimateSource: EstimateSource? = nil, sentLogId: String? = nil,
                quartersLeft: Int? = nil, time: Date? = nil)
    {
        self.title = title
        self.calories = calories
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.estimateSource = estimateSource
        self.sentLogId = sentLogId
        self.quartersLeft = quartersLeft
        self.time = time
    }

    public func apply(_ transaction: inout Transaction) throws -> MealEaten {
        let name = Self.descriptor.name
        let words = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !words.isEmpty, words.count <= 80, !looksLikeClaudeKey(words) else {
            throw ActionError.invalidArguments(action: name, reason: "refused: title")
        }
        // A Claude estimate always names the sent-log row that made it, and the key never reaches a field.
        if estimateSource == .claude, (sentLogId ?? "").isEmpty {
            throw ActionError.invalidArguments(action: name, reason: "refused: noSentRow")
        }
        if let quartersLeft, !(1 ... 3).contains(quartersLeft) {
            throw ActionError.invalidArguments(action: name, reason: "refused: quarters")
        }
        let when = time ?? transaction.now
        let meal = try transaction.create(transaction.classDef(.mealEntry), title: words)
        try transaction.set("when", to: .date(when), on: meal)
        try transaction.set("source", to: .choice("outside"), on: meal)
        try transaction.set("portionEaten", to: .number(1), on: meal)
        let source = estimateSource ?? (calories != nil ? .typed : nil)
        if let source {
            try transaction.set("estimateSource", to: .choice(source.rawValue), on: meal)
        }
        if let sentLogId, source == .claude {
            try transaction.set("sentLogId", to: .text(sentLogId), on: meal)
        }
        var change = LeftoverReminderChange()
        if let quartersLeft {
            let leftover = try transaction.create(transaction.classDef(.leftover), title: words)
            try transaction.setLinks("source", on: leftover, to: [meal])
            try transaction.set("madeOn", to: .date(when), on: leftover)
            try transaction.set("portionLeft", to: .number(Double(quartersLeft)), on: leftover)
            try transaction.set("place", to: .choice("fridge"), on: leftover)
            let until = transaction.calendar.date(byAdding: .day, value: LeftoverWrites.defaultDaysFridge, to: when)
            try transaction.set("throwOutOn", to: until.map(FieldValue.date), on: leftover)
            let id = LeftoverWrites.newNotificationId()
            try transaction.set("notificationId", to: .text(id), on: leftover)
            try transaction.setLinks("leftover", on: meal, to: [leftover])
            change.schedule = id
        }
        if let calories {
            LeftoverWrites.writeNutrition(for: meal, cal: calories, protein: proteinG, carbs: carbsG, fat: fatG,
                                          store: transaction.store, classes: transaction.classes)
        }
        return MealEaten(meal: meal, change: change)
    }

    public func summary(in _: ObjectStore) -> String {
        "Logged a meal from outside"
    }

    public func receipt(in store: ObjectStore, output: MealEaten) -> String? {
        "\(LeftoverBook.shown(output.meal, in: store)), logged."
    }

    public func receipt(in _: ObjectStore) -> String? {
        nil
    }
}

// MARK: - Photos

/// A meal's photo: a file in app storage with complete file protection, keyed by the meal's id. Never in the photo
/// library, a backup, a widget or a Tess line. Deleting the meal's photo deletes the file.
public struct MealPhotoStore {
    public let directory: URL
    public var protection: Data.WritingOptions

    public init(directory: URL, protection: Data.WritingOptions = .completeFileProtection) {
        self.directory = directory
        self.protection = protection
    }

    /// Application Support/Tessera/meal-photos.
    public static var defaultDirectory: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Tessera/meal-photos", isDirectory: true)
    }

    public func url(for meal: UUID) -> URL {
        directory.appendingPathComponent("\(meal.uuidString).jpg")
    }

    @discardableResult
    public func save(_ data: Data, for meal: UUID) throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var folder = directory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? folder.setResourceValues(values)
        var file = url(for: meal)
        try data.write(to: file, options: [.atomic, protection])
        try? file.setResourceValues(values)
        return file
    }

    public func load(for meal: UUID) -> Data? {
        try? Data(contentsOf: url(for: meal))
    }

    public func delete(for meal: UUID) {
        try? FileManager.default.removeItem(at: url(for: meal))
    }
}
