import Foundation

// Multi-dish Cook, Part A PR 2: the objects' actions. None is offered to the model; every one is one op with one
// UNDO. A dish's name is "Private recipe" wherever a line shows it. Nothing here starts a process: Now and the Live
// Activity read the session in PR 3.

enum CookSessionRules {
    static let maxDishes = 6

    @MainActor
    static func book(_ transaction: Transaction) -> CookSessionBook {
        CookSessionBook(store: transaction.store, classes: transaction.classes)
    }

    /// A cook for one dish: the recipe at a size, with no process of its own.
    @MainActor
    static func makeDish(recipe: ObjectRecord, servings: Int?, order: Int, session: ObjectRecord,
                         in transaction: inout Transaction) throws -> ObjectRecord
    {
        let recipes = RecipeBook(store: transaction.store, classes: transaction.classes)
        let title = ObjectPrivacy.cookTitle(recipe, in: transaction.store)
        let cook = try transaction.create(transaction.classDef(.cook), title: title)
        try transaction.setLinks("recipe", on: cook, to: [recipe])
        let size = RecipeLimits.serves(servings) ?? recipes.serves(recipe)
        if let size {
            try transaction.set("serves", to: .number(Double(size)), on: cook)
        }
        let dish = try transaction.create(transaction.classDef(.cookDish), title: title, parent: session)
        try transaction.setLinks("session", on: dish, to: [session])
        try transaction.setLinks("recipe", on: dish, to: [recipe])
        try transaction.setLinks("cook", on: dish, to: [cook])
        try transaction.set("order", to: .number(Double(order)), on: dish)
        if let size {
            try transaction.set("servings", to: .number(Double(size)), on: dish)
        }
        return dish
    }

    @MainActor
    static func setDishes(_ dishes: [ObjectRecord], on session: ObjectRecord,
                          in transaction: inout Transaction) throws
    {
        try transaction.setLinks("dishes", on: session, to: dishes)
    }

    /// Stops every timer a dish's cook still has counting.
    @MainActor
    static func stopTimers(of dish: ObjectRecord, in transaction: inout Transaction) throws {
        guard let cook = CookSessionBook(store: transaction.store, classes: transaction.classes).cook(of: dish) else {
            return
        }
        for timer in CookLog(store: transaction.store, classes: transaction.classes).timers()
            where timer.cook?.id == cook.id
        {
            try transaction.set("isStopped", to: .bool(true), on: timer.object)
        }
    }

    /// A dish's name from the store alone (a receipt has no classes): the recipe's title, or "Private recipe".
    @MainActor
    static func name(of dish: ObjectRecord, in store: ObjectStore) -> String {
        guard let cook = store.linkedObjects("cook", of: dish).first else { return dish.title }
        return ObjectPrivacy.cookTitle(cook, in: store)
    }

    /// The live dishes of a session, in order, from the store alone.
    @MainActor
    static func names(of session: ObjectRecord, in store: ObjectStore) -> [String] {
        store.linkedObjects("dishes", of: session)
            .filter { !$0.isDeleted && store.value("isDropped", of: $0) != .bool(true) }
            .sorted { (store.number("order", of: $0) ?? 0) < (store.number("order", of: $1) ?? 0) }
            .map { name(of: $0, in: store) }
    }

    @MainActor
    static func line(_ names: [String], _ tail: String) -> String {
        "\(CookPlan.names(names)), \(tail)."
    }
}

/// Plans several recipes in one session: one clock, one set of hands. UNDO removes the session, its dishes and their
/// cooks together.
public struct StartCookSession: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "startCookSession", summary: "Plan several dishes together",
        parameters: [
            .init("recipes", .json, "Ids of the recipes, in order"),
            .init("servings", .json, "Servings for each recipe, in the same order", required: false),
            .init("serveAt", .date, "When to eat; none means as soon as it can be", required: false),
        ], isOfferedToModel: false
    )

    public var recipes: [UUID]
    public var servings: [Int]?
    public var serveAt: Date?
    public var time: Date?

    public init(recipes: [UUID], servings: [Int]? = nil, serveAt: Date? = nil, time: Date? = nil) {
        self.recipes = recipes
        self.servings = servings
        self.serveAt = serveAt
        self.time = time
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let name = Self.descriptor.name
        guard !recipes.isEmpty, recipes.count <= CookSessionRules.maxDishes, Set(recipes).count == recipes.count else {
            throw ActionError.invalidArguments(action: name, reason: "plan one to six different recipes")
        }
        // A running workout is never suspended by a cook.
        if let workoutClass = transaction.classes[.workout], let processClass = transaction.classes[.process],
           transaction.store.objects(of: processClass).contains(where: { process in
               transaction.processState(process) == .running
                   && transaction.store.linkedObjects("subject", of: process).first?.classDef
                   .map { ClassResolver.isSubclass($0, of: workoutClass) } == true
           })
        {
            throw ActionError.invalidArguments(action: name, reason: StartCooking.workoutRunningReason)
        }
        let now = time ?? .now
        let objects = try recipes.map { try transaction.object($0, is: .recipe) }
        let session = try transaction.create(transaction.classDef(.cookSession), title: "Cooking")
        try transaction.set("status", to: .choice("planned"), on: session)
        // A serve time in the past is ignored.
        if let serveAt, serveAt > now {
            try transaction.set("serveAt", to: .date(serveAt), on: session)
        }
        var dishes: [ObjectRecord] = []
        for (index, recipe) in objects.enumerated() {
            let size = servings.flatMap { $0.indices.contains(index) ? $0[index] : nil }
            try dishes.append(CookSessionRules.makeDish(recipe: recipe, servings: size, order: index, session: session,
                                                        in: &transaction))
        }
        try CookSessionRules.setDishes(dishes, on: session, in: &transaction)
        try transaction.cacheCookPlan(of: session, now: now)
        return session
    }

    public func summary(in _: ObjectStore) -> String {
        "Several dishes planned"
    }

    public func receipt(in _: ObjectStore) -> String? {
        nil
    }

    public func receipt(in store: ObjectStore, output session: ObjectRecord) -> String? {
        CookSessionRules.line(CookSessionRules.names(of: session, in: store), "planned")
    }
}

/// Sets, changes or clears the serve time. UNDO puts the old one back.
public struct SetServeTime: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "setServeTime", summary: "Set when to eat",
        parameters: [
            .init("session", .object, "The cook session"),
            .init("serveAt", .date, "When to eat; none clears it", required: false),
        ],
        isOfferedToModel: false
    )

    public var session: UUID
    public var serveAt: Date?
    public var time: Date?

    public init(session: UUID, serveAt: Date?, time: Date? = nil) {
        self.session = session
        self.serveAt = serveAt
        self.time = time
    }

    public func apply(_ transaction: inout Transaction) throws {
        let object = try transaction.object(session, is: .cookSession)
        let now = time ?? .now
        // A serve time in the past is ignored.
        try transaction.set("serveAt", to: serveAt.flatMap { $0 > now ? FieldValue.date($0) : nil }, on: object)
        try transaction.cacheCookPlan(of: object, now: now)
    }

    public func summary(in _: ObjectStore) -> String {
        "Serve time set"
    }

    public func receipt(in store: ObjectStore) -> String? {
        guard let object = store.object(id: session),
              let at = store.value("serveAt", of: object)?.dateValue else { return "Serve time, cleared." }
        return "Serve at \(HouseTime.clock(at))."
    }
}

/// Adds a dish to a session, mid-cook or before. It is placed against the hands already busy.
public struct AddDish: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "addDish", summary: "Add a dish to the cook",
        parameters: [.init("session", .object, "The cook session"), .init("recipe", .object, "The recipe"),
                     .init("servings", .integer, "At what size", required: false)],
        isOfferedToModel: false
    )

    public var session: UUID
    public var recipe: UUID
    public var servings: Int?
    public var time: Date?

    public init(session: UUID, recipe: UUID, servings: Int? = nil, time: Date? = nil) {
        self.session = session
        self.recipe = recipe
        self.servings = servings
        self.time = time
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let object = try transaction.object(session, is: .cookSession)
        let book = CookSessionRules.book(transaction)
        guard ["planned", "running", "paused"].contains(book.status(of: object)) else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "that cook is over")
        }
        let existing = book.allDishes(of: object)
        let live = book.dishes(of: object)
        guard live.count < CookSessionRules.maxDishes else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "that is as many dishes as fit")
        }
        let target = try transaction.object(recipe, is: .recipe)
        guard !live.contains(where: { book.recipe(of: $0)?.id == target.id }) else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "that dish is already in")
        }
        let order = (existing.compactMap { transaction.store.number("order", of: $0) }.max() ?? -1) + 1
        let dish = try CookSessionRules.makeDish(recipe: target, servings: servings, order: Int(order), session: object,
                                                 in: &transaction)
        try CookSessionRules.setDishes(existing + [dish], on: object, in: &transaction)
        try transaction.cacheCookPlan(of: object, now: time ?? .now)
        return dish
    }

    public func summary(in _: ObjectStore) -> String {
        "Dish added"
    }

    public func receipt(in _: ObjectStore) -> String? {
        nil
    }

    public func receipt(in store: ObjectStore, output dish: ObjectRecord) -> String? {
        "\(CookSessionRules.name(of: dish, in: store)), added."
    }
}

/// Drops a dish: its timers stop without ringing and the plan closes up. UNDO brings it back.
public struct DropDish: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "dropDish", summary: "Drop a dish from the cook",
        parameters: [.init("dish", .object, "The dish")], isOfferedToModel: false
    )

    public var dish: UUID
    public var time: Date?

    public init(dish: UUID, time: Date? = nil) {
        self.dish = dish
        self.time = time
    }

    public func apply(_ transaction: inout Transaction) throws {
        let object = try transaction.object(dish, is: .cookDish)
        guard let session = transaction.store.linkedObjects("session", of: object).first else { return }
        try CookSessionRules.stopTimers(of: object, in: &transaction)
        try transaction.set("isDropped", to: .bool(true), on: object)
        if CookSessionRules.book(transaction).dishes(of: session).isEmpty {
            try transaction.set("status", to: .choice("dropped"), on: session)
        } else {
            try transaction.cacheCookPlan(of: session, now: time ?? .now)
        }
    }

    public func summary(in _: ObjectStore) -> String {
        "Dish dropped"
    }

    public func receipt(in store: ObjectStore) -> String? {
        guard let object = store.object(id: dish) else { return nil }
        return "\(CookSessionRules.name(of: object, in: store)), dropped."
    }
}

/// Moves a dish to a step. The first move starts the dish (and the session); a timed step starts its timer, with a
/// stable id so a revisited step reuses it; the step it left stops its timer.
public struct AdvanceDishStep: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "advanceDishStep", summary: "Go to a step in a dish",
        parameters: [.init("dish", .object, "The dish"), .init("step", .integer, "The step, 0 first")],
        isOfferedToModel: false
    )

    public var dish: UUID
    public var step: Int
    public var time: Date?

    public init(dish: UUID, step: Int, time: Date? = nil) {
        self.dish = dish
        self.step = step
        self.time = time
    }

    public static func timerID(dish: UUID, step: Int) -> UUID {
        SystemCatalog.stableID("cooktimer.\(dish.uuidString).\(step)")
    }

    public func apply(_ transaction: inout Transaction) throws {
        let object = try transaction.object(dish, is: .cookDish)
        let now = time ?? .now
        let book = CookSessionRules.book(transaction)
        guard let session = transaction.store.linkedObjects("session", of: object).first,
              let recipe = book.recipe(of: object) else { return }
        guard ["planned", "running"].contains(book.status(of: session)) else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "that cook is not running")
        }
        let steps = RecipeBook(store: transaction.store, classes: transaction.classes).steps(of: recipe)
        guard steps.indices.contains(step) else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "no such step")
        }
        if book.status(of: session) == "planned" {
            try transaction.set("status", to: .choice("running"), on: session)
            try transaction.set("startedAt", to: .date(now), on: session)
        }
        if transaction.store.value("startedAt", of: object) == nil {
            try transaction.set("startedAt", to: .date(now), on: object)
        }
        try CookSessionRules.stopTimers(of: object, in: &transaction)
        try transaction.set("stepIndex", to: .number(Double(step)), on: object)
        if let minutes = steps[step].offeredTimers.map(\.upperBound).max(), let cook = book.cook(of: object) {
            let id = Self.timerID(dish: dish, step: step)
            let timer: ObjectRecord = if let known = transaction.store.object(id: id), !known.isDeleted {
                known
            } else {
                try transaction.create(transaction.classDef(.kitchenTimer), title: "Step \(step + 1)", id: id)
            }
            try transaction.set("startedAt", to: .date(now), on: timer)
            try transaction.set("endsAt", to: .date(now.addingTimeInterval(minutes * 60)), on: timer)
            try transaction.set("minutes", to: .number(minutes), on: timer)
            try transaction.set("isStopped", to: .bool(false), on: timer)
            try transaction.setLinks("cook", on: timer, to: [cook])
        }
        try transaction.cacheCookPlan(of: session, now: now)
    }

    public func summary(in _: ObjectStore) -> String {
        "Step \(step + 1)"
    }

    public func receipt(in _: ObjectStore) -> String? {
        nil
    }
}

/// Pauses the whole session: every timer stops counting and the clock stands still.
public struct PauseCook: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "pauseCook", summary: "Pause the cook",
        parameters: [.init("session", .object, "The cook session")], isOfferedToModel: false
    )

    public var session: UUID
    public var time: Date?

    public init(session: UUID, time: Date? = nil) {
        self.session = session
        self.time = time
    }

    public func apply(_ transaction: inout Transaction) throws {
        let object = try transaction.object(session, is: .cookSession)
        let book = CookSessionRules.book(transaction)
        guard book.status(of: object) == "running" else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "that cook is not running")
        }
        try transaction.set("status", to: .choice("paused"), on: object)
        try transaction.set("pausedAt", to: .date(time ?? .now), on: object)
        for timer in book.timers(of: object) {
            try transaction.set("isStopped", to: .bool(true), on: timer.object)
        }
    }

    public func summary(in _: ObjectStore) -> String {
        "Cook paused"
    }

    public func receipt(in _: ObjectStore) -> String? {
        "Paused."
    }
}

/// Resumes a paused session: the gap is added to every running dish, every timer and the serve time, by id, so both
/// dishes move together.
public struct ResumeCook: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "resumeCook", summary: "Resume the cook",
        parameters: [.init("session", .object, "The cook session")], isOfferedToModel: false
    )

    public var session: UUID
    public var time: Date?

    public init(session: UUID, time: Date? = nil) {
        self.session = session
        self.time = time
    }

    public func apply(_ transaction: inout Transaction) throws {
        let object = try transaction.object(session, is: .cookSession)
        let book = CookSessionRules.book(transaction)
        guard book.status(of: object) == "paused",
              let pausedAt = transaction.store.value("pausedAt", of: object)?.dateValue
        else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "that cook is not paused")
        }
        let now = time ?? .now
        let gap = max(0, now.timeIntervalSince(pausedAt))
        let total = transaction.store.number("pausedTotalSec", of: object) ?? 0
        try transaction.set("pausedTotalSec", to: .number(total + gap), on: object)
        try transaction.set("pausedAt", to: nil, on: object)
        try transaction.set("status", to: .choice("running"), on: object)
        if let serve = transaction.store.value("serveAt", of: object)?.dateValue {
            try transaction.set("serveAt", to: .date(serve.addingTimeInterval(gap)), on: object)
        }
        for dish in book.dishes(of: object) {
            if let started = transaction.store.value("startedAt", of: dish)?.dateValue {
                try transaction.set("startedAt", to: .date(started.addingTimeInterval(gap)), on: dish)
            }
        }
        for dish in book.dishes(of: object) {
            guard let cook = book.cook(of: dish) else { continue }
            for timer in try transaction.store.objects(of: transaction.classDef(.kitchenTimer))
                where !timer.isDeleted && transaction.store.linkedObjects("cook", of: timer).first?.id == cook.id
                && transaction.store.value("isStopped", of: timer) == .bool(true)
                && transaction.store.value("endsAt", of: timer)?.dateValue.map({ $0 > pausedAt }) == true
            {
                if let ends = transaction.store.value("endsAt", of: timer)?.dateValue {
                    try transaction.set("endsAt", to: .date(ends.addingTimeInterval(gap)), on: timer)
                    try transaction.set("isStopped", to: .bool(false), on: timer)
                }
            }
        }
        try transaction.cacheCookPlan(of: object, now: now)
    }

    public func summary(in _: ObjectStore) -> String {
        "Cook resumed"
    }

    public func receipt(in _: ObjectStore) -> String? {
        "Back on."
    }
}

/// Finishes the session: one FinishCooking for each dish still in it, so every recipe knows it was cooked.
public struct FinishCookSession: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "finishCookSession", summary: "Finish the cook",
        parameters: [
            .init("session", .object, "The cook session"),
            .init("note", .string, "How it went", required: false),
        ],
        isOfferedToModel: false
    )

    public var session: UUID
    public var note: String?
    public var time: Date?

    public init(session: UUID, note: String? = nil, time: Date? = nil) {
        self.session = session
        self.note = note
        self.time = time
    }

    public func apply(_ transaction: inout Transaction) throws {
        let object = try transaction.object(session, is: .cookSession)
        let book = CookSessionRules.book(transaction)
        guard ["planned", "running", "paused"].contains(book.status(of: object)) else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "that cook is over")
        }
        var cooks: [ObjectRecord] = []
        for dish in book.dishes(of: object) {
            guard let cook = book.cook(of: dish) else { continue }
            cooks.append(cook)
            try FinishCooking(cook: cook.id, note: note, time: time, addsLoad: false).apply(&transaction)
        }
        // One load for the whole session: the largest serves in plates, a pan for each recipe, one board.
        try Sink.addCookLoad(for: cooks, source: object, at: time ?? transaction.now, in: &transaction)
        try transaction.set("status", to: .choice("done"), on: object)
    }

    public func summary(in _: ObjectStore) -> String {
        "Cook finished"
    }

    public func receipt(in store: ObjectStore) -> String? {
        guard let object = store.object(id: session) else { return nil }
        return CookSessionRules.line(CookSessionRules.names(of: object, in: store), "cooked")
    }
}
