import Foundation

// Words remember (Together, piece 3, switch `linkColours`): which app a class belongs to, and where a thing is
// mentioned. Both are derived on every read from the classes and the links, never stored. A private or walled thing
// reads "Private" in plain ink with nothing after it; a private thing that links to it never counts.

public extension ClassResolver {
    /// The app a class belongs to: Training (workouts, exercises, plans, sets, muscles, equipment), Kitchen
    /// (recipes, ingredients, cooks, timers, pantry places, cook sessions), Money (spends, pools, inflows, moves,
    /// rates), Notes, Lists (lists and items), Routines (routines). Nil for anything else (tasks, books, events,
    /// settings). A class under
    /// one of those (Bench Press under Exercise) belongs to the same app.
    static func app(for classDef: ClassDef) -> AppID? {
        for node in lineage(of: classDef).reversed() {
            guard let key = node.systemKey
                .flatMap({ SystemCatalog.Key(rawValue: String($0.dropFirst("system.".count))) })
            else { continue }
            if let app = appByKey[key] {
                return app
            }
        }
        return nil
    }

    private static let appByKey: [SystemCatalog.Key: AppID] = {
        var map: [SystemCatalog.Key: AppID] = [:]
        for key in [
            SystemCatalog.Key.activity,
            .exercise,
            .strengthExercise,
            .barbellLift,
            .benchPress,
            .muscle,
            .equipment,
            .workout,
            .exerciseEntry,
            .set,
            .slot,
            .plan,
        ] {
            map[key] = .training
        }
        for key in [SystemCatalog.Key.ingredient, .recipe, .recipeLine, .recipeStep, .cook, .kitchenTimer, .place,
                    .cookSession, .cookDish]
        {
            map[key] = .kitchen
        }
        for key in [SystemCatalog.Key.spend, .pool, .inflow, .poolMove, .rateNote] {
            map[key] = .money
        }
        // A routine is a Routines thing, as the app's Home reads it; Training keeps workouts, exercises and plans.
        map[.routine] = .routines
        map[.note] = .notes
        for key in [SystemCatalog.Key.list, .listItem] {
            map[key] = .lists
        }
        return map
    }()
}

/// Where a thing is mentioned: the app, how many of that app's objects link to it, and what a tap opens (the object
/// itself when there is exactly one, else the app).
public struct Mention: Equatable, Sendable {
    public let app: AppID
    public let count: Int
    public let opens: HomeSentence.Opens
}

/// How a thing's name is drawn.
public struct ThingWord: Equatable, Sendable {
    /// The name, or "Private" for a private or walled thing.
    public let text: String
    public let isPrivate: Bool
    public let app: AppID?
    /// The colour and underline of the app's accent: false for a private thing (plain ink, no underline colour).
    public var usesAppColour: Bool {
        !isPrivate && app != nil
    }
}

@MainActor
public extension ObjectStore {
    /// The apps whose objects link to `object`, with counts, in the order of `AppID.allCases`. Empty for a private or
    /// walled thing (no "Mentioned in"). A private source is not counted, so the list never shows it exists.
    func mentions(of object: ObjectRecord, classes: [SystemCatalog.Key: ClassDef]) -> [Mention] {
        guard ObjectPrivacy.shownLabel(of: object, in: self, classes: classes) == nil else { return [] }
        var sources: [AppID: [ObjectRecord]] = [:]
        for source in backlinks(to: object) {
            guard let app = source.classDef.flatMap({ ClassResolver.app(for: $0) }),
                  ObjectPrivacy.shownLabel(of: source, in: self, classes: classes) == nil else { continue }
            sources[app, default: []].append(source)
        }
        return AppID.allCases.compactMap { app in
            guard let list = sources[app], !list.isEmpty else { return nil }
            return Mention(app: app, count: list.count, opens: list.count == 1 ? .object(list[0].id) : .app(app))
        }
    }

    /// How a word for this thing is drawn: its name in its app's colour, or "Private" in plain ink.
    func thingWord(of object: ObjectRecord, classes: [SystemCatalog.Key: ClassDef]) -> ThingWord {
        if ObjectPrivacy.shownLabel(of: object, in: self, classes: classes) != nil {
            return ThingWord(text: "Private", isPrivate: true, app: nil)
        }
        return ThingWord(
            text: object.title,
            isPrivate: false,
            app: object.classDef.flatMap { ClassResolver.app(for: $0) }
        )
    }
}
