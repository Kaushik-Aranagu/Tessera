import Foundation

/// Reads a cook session: its dishes in order and the plan derived from them. Nothing here writes. The plan is never
/// stored; the dishes keep only the numbers it cached (`offsetSec`, `heldSec`) for lists and the Live Activity.
@MainActor
public struct CookSessionBook {
    public let store: ObjectStore
    public let classes: [SystemCatalog.Key: ClassDef]

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) {
        self.store = store
        self.classes = classes
    }

    public func sessions() -> [ObjectRecord] {
        classes[.cookSession].map { store.objects(of: $0).filter { !$0.isDeleted } } ?? []
    }

    /// The session still under way (planned, running or paused), newest first.
    public func current() -> ObjectRecord? {
        sessions().filter { ["planned", "running", "paused"].contains(status(of: $0)) }
            .max { $0.createdAt < $1.createdAt }
    }

    public func status(of session: ObjectRecord) -> String {
        store.value("status", of: session)?.stringValue ?? "planned"
    }

    /// All dishes in order, dropped ones included.
    public func allDishes(of session: ObjectRecord) -> [ObjectRecord] {
        store.linkedObjects("dishes", of: session).filter { !$0.isDeleted }
            .sorted { (store.number("order", of: $0) ?? 0) < (store.number("order", of: $1) ?? 0) }
    }

    public func dishes(of session: ObjectRecord) -> [ObjectRecord] {
        allDishes(of: session).filter { store.value("isDropped", of: $0) != .bool(true) }
    }

    public func recipe(of dish: ObjectRecord) -> ObjectRecord? {
        store.linkedObjects("recipe", of: dish).first { !$0.isDeleted }
    }

    public func cook(of dish: ObjectRecord) -> ObjectRecord? {
        store.linkedObjects("cook", of: dish).first
    }

    /// The name a dish shows anywhere: the recipe's title, or "Private recipe".
    public func name(of dish: ObjectRecord) -> String {
        guard let cook = cook(of: dish) else { return recipe(of: dish)?.title ?? "A dish" }
        return ObjectPrivacy.cookTitle(cook, in: store)
    }

    func finish(of dish: ObjectRecord) -> CookPlan.Finish {
        switch store.value("finish", of: dish)?.stringValue {
        case "holdsWarm": .holdsWarm(minutes: Int(store.number("holdMinutes", of: dish) ?? 15))
        case "last": .last
        default: .standard
        }
    }

    /// The dishes as the plan takes them. A recipe that was deleted skips its dish.
    public func planDishes(of session: ObjectRecord) -> [CookPlan.Dish] {
        let recipes = RecipeBook(store: store, classes: classes)
        return dishes(of: session).enumerated().compactMap { index, dish in
            guard let recipe = recipe(of: dish) else { return nil }
            let timers = recipes.steps(of: recipe).map(\.timers)
            return CookPlan.Dish(
                id: dish.id, name: name(of: dish), order: index,
                local: CookTimeline.local(timers: timers.isEmpty ? [[]] : timers), finish: finish(of: dish),
                startedAt: store.value("startedAt", of: dish)?.dateValue
            )
        }
    }

    /// The plan for now. A planned session without a serve time starts when asked; paused, the clock stands still at
    /// the moment it stopped.
    public func plan(of session: ObjectRecord, now: Date = .now) -> CookPlan {
        let at = store.value("pausedAt", of: session)?.dateValue
            .flatMap { status(of: session) == "paused" ? $0 : nil } ?? now
        return CookPlan.make(dishes: planDishes(of: session), serveAt: store.value("serveAt", of: session)?.dateValue,
                             now: at, holdMax: store.number("holdMaxSec", of: session) ?? CookPlan.holdMaxDefault)
    }

    /// The step a dish is on (0 first) and how many it has.
    public func progress(of dish: ObjectRecord) -> (step: Int, of: Int) {
        let count = recipe(of: dish).map { RecipeBook(store: store, classes: classes).steps(of: $0).count } ?? 0
        return (Int(store.number("stepIndex", of: dish) ?? 0), count)
    }

    /// The timers still counting that belong to this session's dishes.
    public func timers(of session: ObjectRecord) -> [CookLog.Timer] {
        let cooks = Set(allDishes(of: session).compactMap { cook(of: $0)?.id })
        return CookLog(store: store, classes: classes).timers()
            .filter { $0.cook.map { cooks.contains($0.id) } ?? false }
    }
}

/// What Now and the Live Activity say about a running session (Part A PR 3). Names are masked; the Live Activity shows
/// one cook, the soonest timer and "+N" more, never a second row per dish.
public struct CookSessionLive: Equatable, Sendable {
    /// "Paprika chicken and Spaghetti", or "Private recipe and Spaghetti".
    public let title: String
    /// The soonest timer still counting: its label ("Step 3", or "Timer" for a private cook) and when it ends.
    public let soonestLabel: String?
    public let soonestEndsAt: Date?
    /// How many other timers are counting.
    public let more: Int
    /// "Cooking A and B, 12 min left." (the Now line) and the Live Activity's "+2".
    public let line: String
    public let moreWord: String?
    public let projectedServe: Date?
}

public extension CookSessionBook {
    /// The session as Now and the Live Activity read it. Nil unless it is running or paused.
    func live(of session: ObjectRecord, now: Date = .now, calendar _: Calendar = .current) -> CookSessionLive? {
        let state = status(of: session)
        guard state == "running" || state == "paused" else { return nil }
        let plan = plan(of: session, now: now)
        let names = plan.placements.sorted { $0.dish.order < $1.dish.order }.map(\.dish.name)
        let timers = timers(of: session).filter { $0.endsAt > now }
        let soonest = timers.first
        let label = soonest.map { timer in
            KitchenTimerAlerts.hidesLabel(timer.label, cook: timer.cook, in: store) ? "Timer" : timer.label
        }
        let finish = plan.placements.map(\.end).max()
        let minutes = finish.map { max(0, Int(($0.timeIntervalSince(now) / 60).rounded(.up))) }
        let more = max(0, timers.count - 1)
        return CookSessionLive(
            title: CookPlan.names(names), soonestLabel: label, soonestEndsAt: soonest?.endsAt, more: more,
            line: plan.running(minutesLeft: minutes), moreWord: more > 0 ? "+\(more)" : nil,
            projectedServe: plan.projectedServe
        )
    }
}

@MainActor
extension Transaction {
    /// Writes the numbers the plan cached on each dish: how long after the earliest start it begins, and how long it
    /// waits. Read on every replan; never the source of truth.
    mutating func cacheCookPlan(of session: ObjectRecord, now: Date) throws {
        let book = CookSessionBook(store: store, classes: classes)
        let plan = book.plan(of: session, now: now)
        guard let earliest = plan.placements.map(\.start).min() else { return }
        for place in plan.placements {
            guard let dish = store.object(id: place.dish.id) else { continue }
            try set("offsetSec", to: .number(place.start.timeIntervalSince(earliest)), on: dish)
            try set("heldSec", to: .number(place.heldSec), on: dish)
        }
    }
}
