import Foundation

/// Cooking as a process (kitchen slice 5). `StartCooking` makes a Cook (the recipe at a size) the running process,
/// with the step index as its resume point. Timers are objects with `endsAt`; several can run at once. Finishing
/// stamps the Cook, so a recipe knows when it was last cooked and how often.
@MainActor
public struct CookLog {
    public struct Timer: Identifiable {
        public let id: UUID
        public let object: ObjectRecord
        public let label: String
        public let startedAt: Date
        public let endsAt: Date
        public let cook: ObjectRecord?

        public func remaining(at now: Date) -> TimeInterval {
            max(0, endsAt.timeIntervalSince(now))
        }
    }

    public let store: ObjectStore
    public let classes: [SystemCatalog.Key: ClassDef]

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) {
        self.store = store
        self.classes = classes
    }

    /// Finished cooks of a recipe, newest first.
    public func cooks(of recipe: ObjectRecord) -> [(cook: ObjectRecord, at: Date)] {
        guard let cookClass = classes[.cook] else { return [] }
        return store.objects(of: cookClass).compactMap { cook in
            guard store.linkedObjects("recipe", of: cook).first?.id == recipe.id,
                  let at = store.value("cookedAt", of: cook)?.dateValue else { return nil }
            return (cook, at)
        }
        .sorted { $0.at > $1.at }
    }

    public func lastCooked(_ recipe: ObjectRecord) -> Date? {
        cooks(of: recipe).first?.at
    }

    /// The serving size a cook used.
    public func serves(of cook: ObjectRecord) -> Int? {
        store.number("serves", of: cook).map(Int.init)
    }

    /// Timers still counting (not stopped), soonest first. A timer past its end stays until stopped, at 0.
    public func timers(at _: Date = .now) -> [Timer] {
        guard let timerClass = classes[.kitchenTimer] else { return [] }
        return store.objects(of: timerClass).compactMap { object in
            guard store.value("isStopped", of: object) != .bool(true),
                  let ends = store.value("endsAt", of: object)?.dateValue else { return nil }
            return Timer(id: object.id, object: object, label: object.title,
                         startedAt: store.value("startedAt", of: object)?.dateValue ?? object.createdAt,
                         endsAt: ends, cook: store.linkedObjects("cook", of: object).first)
        }
        .sorted { $0.endsAt < $1.endsAt }
    }

    /// "Carbonara, third time this month." Counts, never judgement.
    public func finishLine(for recipe: ObjectRecord, at now: Date, calendar: Calendar = .current) -> String {
        // The month of his day, which turns at 4 am (gap hunt G23): a 1:30 am cook on the 1st is the last month's.
        let day = TesseraDay(calendar: calendar)
        let month = calendar.dateComponents([.year, .month], from: day.day(of: now))
        let thisMonth = cooks(of: recipe).count {
            calendar.dateComponents([.year, .month], from: day.day(of: $0.at)) == month
        }
        return "\(recipe.title), \(Self.ordinal(thisMonth)) time this month."
    }

    /// "first" to "ninth", then "10th", "11th", "12th", "13th", "21st", "22nd", "23rd", "31st".
    static func ordinal(_ number: Int) -> String {
        let words = ["", "first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth"]
        if number > 0, number < words.count {
            return words[number]
        }
        let suffix = switch (number % 100 / 10 == 1, number % 10) {
        case (false, 1): "st"
        case (false, 2): "nd"
        case (false, 3): "rd"
        default: "th"
        }
        return "\(number)\(suffix)"
    }
}

/// Starts cooking a recipe at a size: a Cook object becomes the running process (Now), resuming at step 0.
extension ObjectPrivacy {
    /// What a cook or recipe is called in an op summary, the day story and the cook's own title: its title, or
    /// "Private recipe" when the recipe is private by the recipe rule (G21b).
    @MainActor
    static func cookTitle(_ object: ObjectRecord, in store: ObjectStore) -> String {
        let recipe = store.linkedObjects("recipe", of: object).first ?? object
        let private_ = isPrivateRecipeTitle(recipe.title, lastWeightKg: BodyWeight.lastKg(in: store))
            || isPrivateRecipeTitle(object.title, lastWeightKg: BodyWeight.lastKg(in: store))
        return private_ ? recipeLabel : object.title
    }
}

public struct StartCooking: EngineAction {
    public static let descriptor = ActionDescriptor(name: "startCooking", summary: "Start cooking a recipe",
                                                    parameters: [
                                                        .init("recipe", .object, "The recipe"),
                                                        .init("serves", .integer, "At what size", required: false),
                                                    ])

    public var recipe: UUID
    public var serves: Int?
    public var time: Date?

    public init(recipe: UUID, serves: Int? = nil, time: Date? = nil) {
        self.recipe = recipe
        self.serves = serves
        self.time = time
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let recipe = try transaction.object(recipe, is: .recipe)
        let book = RecipeBook(store: transaction.store, classes: transaction.classes)
        // Already cooking this (running or set aside)? Pick that cook back up rather than starting a second one.
        if let cookClass = transaction.classes[.cook],
           let open = transaction.store.objects(of: cookClass).first(where: { cook in
               transaction.store.linkedObjects("recipe", of: cook).first?.id == recipe.id
                   && transaction.store.value("cookedAt", of: cook) == nil && transaction.openProcess(for: cook) != nil
           })
        {
            if let serves {
                try transaction.set("serves", to: .number(Double(serves)), on: open)
            }
            try StartProcess(subject: open.id, ownerApp: "Kitchen", time: time).apply(&transaction)
            return open
        }
        let cook = try transaction.create(transaction.classDef(.cook),
                                          title: ObjectPrivacy.cookTitle(recipe, in: transaction.store))
        try transaction.setLinks("recipe", on: cook, to: [recipe])
        if let size = serves ?? book.serves(recipe) {
            try transaction.set("serves", to: .number(Double(size)), on: cook)
        }
        let first = book.steps(of: recipe).first?.text
        try StartProcess(subject: cook.id, ownerApp: "Kitchen", nextStep: first, resumePoint: ResumePoint(index: 0),
                         time: time).apply(&transaction)
        return cook
    }

    public func summary(in store: ObjectStore) -> String {
        "Cooking \(store.object(id: recipe).map { ObjectPrivacy.cookTitle($0, in: store) } ?? "")"
    }
}

/// Moves a cook to a step (its resume point and next step).
public struct GoToCookStep: EngineAction {
    public static let descriptor = ActionDescriptor(name: "goToCookStep", summary: "Go to a step while cooking",
                                                    parameters: [
                                                        .init("cook", .object, "The cook in progress"),
                                                        .init("step", .integer, "The step index, 0 first"),
                                                    ])

    public var cook: UUID
    public var step: Int
    public var time: Date?

    public init(cook: UUID, step: Int, time: Date? = nil) {
        self.cook = cook
        self.step = step
        self.time = time
    }

    public func apply(_ transaction: inout Transaction) throws {
        let cook = try transaction.object(cook, is: .cook)
        guard let process = transaction.openProcess(for: cook),
              let recipe = transaction.store.linkedObjects("recipe", of: cook).first else { return }
        let steps = RecipeBook(store: transaction.store, classes: transaction.classes).steps(of: recipe)
        let index = max(0, min(step, steps.count - 1))
        try transaction.saveContext(process, resumePoint: ResumePoint(index: index),
                                    nextStep: steps.indices.contains(index) ? steps[index].text : nil, at: time ?? .now)
    }

    public func summary(in _: ObjectStore) -> String {
        "Step \(step + 1)"
    }
}

/// Starts a kitchen timer ("pasta", 10 min), optionally for a cook and its step.
public struct StartKitchenTimer: EngineAction {
    public static let descriptor = ActionDescriptor(name: "startKitchenTimer", summary: "Start a kitchen timer",
                                                    parameters: [
                                                        .init("label", .string, "What it's for, e.g. pasta"),
                                                        .init("minutes", .number, "How long"),
                                                        .init("cook", .object, "The cook it belongs to",
                                                              required: false),
                                                    ])

    public var label: String
    public var minutes: Double
    public var cook: UUID?
    public var time: Date?

    public init(label: String, minutes: Double, cook: UUID? = nil, time: Date? = nil) {
        self.label = label
        self.minutes = minutes
        self.cook = cook
        self.time = time
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        guard minutes > 0 else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "a timer needs a length")
        }
        guard minutes <= RecipeParser.maxTimerMinutes else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "a timer runs up to 24 hours")
        }
        let start = time ?? .now
        let name = label.trimmingCharacters(in: .whitespaces).isEmpty ? "Timer" : label
        let timer = try transaction.create(transaction.classDef(.kitchenTimer), title: name)
        try transaction.set("startedAt", to: .date(start), on: timer)
        try transaction.set("endsAt", to: .date(start.addingTimeInterval(minutes * 60)), on: timer)
        try transaction.set("minutes", to: .number(minutes), on: timer)
        if let cook {
            let cookObject = try transaction.object(cook, is: .cook)
            try transaction.setLinks("cook", on: timer, to: [cookObject])
            if let process = transaction.openProcess(for: cookObject) {
                try transaction.saveContext(process, resumePoint: nil, nextStep: nil, at: start)
            }
        }
        return timer
    }

    public func summary(in _: ObjectStore) -> String {
        "\(label) timer, \(minutes.formatted(.number.precision(.fractionLength(0 ... 1)))) min"
    }
}

/// Stops a timer (done or cancelled).
public struct StopKitchenTimer: EngineAction {
    public static let descriptor = ActionDescriptor(name: "stopKitchenTimer", summary: "Stop a kitchen timer",
                                                    parameters: [.init("timer", .object, "The timer")])

    public var timer: UUID

    public init(timer: UUID) {
        self.timer = timer
    }

    public func apply(_ transaction: inout Transaction) throws {
        try transaction.set("isStopped", to: .bool(true), on: transaction.object(timer, is: .kitchenTimer))
    }

    public func summary(in store: ObjectStore) -> String {
        "Stopped \(store.object(id: timer)?.title ?? "the timer")"
    }
}

/// Finishes cooking: stamps the Cook (so the recipe knows it was cooked), ends the process and stops its timers.
public struct FinishCooking: EngineAction {
    public static let descriptor = ActionDescriptor(name: "finishCooking", summary: "Finish cooking", parameters: [
        .init("cook", .object, "The cook in progress"),
        .init("note", .string, "How it went", required: false),
    ])

    public var cook: UUID
    public var note: String?
    public var time: Date?

    public init(cook: UUID, note: String? = nil, time: Date? = nil) {
        self.cook = cook
        self.note = note
        self.time = time
    }

    public func apply(_ transaction: inout Transaction) throws {
        let cook = try transaction.object(cook, is: .cook)
        let end = time ?? .now
        try transaction.set("cookedAt", to: .date(end), on: cook)
        if let note, !note.isEmpty {
            try transaction.set("note", to: .text(note), on: cook)
        }
        if let process = transaction.openProcess(for: cook) {
            try transaction.end(process, reason: .done, at: end)
        }
        for timer in CookLog(store: transaction.store, classes: transaction.classes).timers()
            where timer.cook?.id == cook.id
        {
            try transaction.set("isStopped", to: .bool(true), on: timer.object)
        }
        try closePlanTask(for: cook, at: end, in: &transaction)
    }

    /// The same write closes the plan task dated for this recipe on the same house day (4 am turnover): the earliest
    /// open one. No task, nothing else changes.
    @MainActor
    private func closePlanTask(for cook: ObjectRecord, at end: Date, in transaction: inout Transaction) throws {
        guard let recipe = transaction.store.linkedObjects("recipe", of: cook).first,
              let taskClass = transaction.classes[.task] else { return }
        let store = transaction.store
        let day = TesseraDay()
        let candidates = store.objects(of: taskClass).compactMap { task -> (task: ObjectRecord, when: Date)? in
            guard !task.isDeleted, store.value("isDone", of: task) != .bool(true),
                  store.linkedObjects("about", of: task).contains(where: { $0.id == recipe.id }),
                  let when = (store.value("startsAt", of: task) ?? store.value("due", of: task))?.dateValue,
                  day.isSameDay(when, end) else { return nil }
            return (task, when)
        }
        guard let chosen = candidates.min(by: { $0.when < $1.when }) else { return }
        try transaction.set("isDone", to: .bool(true), on: chosen.task)
        try transaction.set("doneAt", to: .date(end), on: chosen.task)
        try transaction.endTaskProcess(chosen.task, done: true)
    }

    public func summary(in store: ObjectStore) -> String {
        "Cooked \(store.object(id: cook).map { ObjectPrivacy.cookTitle($0, in: store) } ?? "it")"
    }

    public func receipt(in store: ObjectStore) -> String? {
        guard let object = store.object(id: cook) else { return nil }
        let recipe = store.linkedObjects("recipe", of: object).first ?? object
        if ObjectPrivacy.isPrivateRecipeTitle(recipe.title, lastWeightKg: BodyWeight.lastKg(in: store)) {
            return "\(ObjectPrivacy.recipeLabel) done."
        }
        return "\(object.title), done."
    }
}

/// Closes the cooks that were open when a restored copy was made, as not finished (G27): no `cookedAt`, so no COOKS
/// count, no "cooked" fact and no day-log row; their timers stop without ringing. Run by the launch after a restore,
/// as the system; not offered to Tess.
public struct CloseStaleCooks: EngineAction {
    public static let descriptor = ActionDescriptor(name: "closeStaleCooks",
                                                    summary: "Close cooks left open in a restored copy",
                                                    parameters: [.init("madeAt", .date, "When the copy was made")])

    public var madeAt: Date
    public var time: Date

    public init(madeAt: Date, at time: Date = .now) {
        self.madeAt = madeAt
        self.time = time
    }

    public func apply(_ transaction: inout Transaction) throws {
        guard let cookClass = transaction.classes[.cook] else { return }
        for cook in transaction.store.objects(of: cookClass)
            where transaction.store.value("cookedAt", of: cook) == nil
        {
            guard let process = transaction.openProcess(for: cook) else { continue }
            let started = transaction.store.value("startedAt", of: process)?.dateValue ?? process.createdAt
            guard started <= madeAt else { continue }
            try transaction.end(process, reason: .closed, at: time)
            for timer in CookLog(store: transaction.store, classes: transaction.classes).timers()
                where timer.cook?.id == cook.id
            {
                try transaction.set("isStopped", to: .bool(true), on: timer.object)
            }
        }
    }

    public func summary(in _: ObjectStore) -> String {
        "Closed cooks left open in a restored copy"
    }
}
