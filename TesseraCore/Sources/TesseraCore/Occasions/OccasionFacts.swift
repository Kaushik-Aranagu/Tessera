import Foundation

/// Where an occasion's facts are going. Money is shown on the Occasion page in the app and nowhere else: Home,
/// widgets, the Lock Screen, text backups and every model get `.other` and never see a pool or an amount.
public enum OccasionSurface: Sendable {
    case occasionPage, other
}

/// One signature fact of an occasion: the linked app's own line about the thing linked ("3 left of 8").
public struct OccasionFact: Equatable, Sendable {
    public let app: AppID
    /// The linked thing the line is about (nil for the Training line, which is about the range).
    public let thing: UUID?
    public let text: String
}

/// What an occasion says about each app it links to (Together, piece 4). Derived on every read, never stored. A
/// private or walled thing is masked before any sentence is made and never named; a linked thing that is gone is
/// skipped.
@MainActor
public enum OccasionFacts {
    public static func facts(for occasion: ObjectRecord, engine: ActionEngine, now _: Date, surface: OccasionSurface,
                             calendar: Calendar = .current) -> [OccasionFact]
    {
        let store = engine.store
        let classes = engine.classes
        let contents = ListContents(store: store, classes: classes)
        var result: [OccasionFact] = []
        var training = false
        var trainingMasked = false
        for thing in store.linkedObjects("links", of: occasion) where !thing.isDeleted {
            guard let classDef = thing.classDef, let app = ClassResolver.app(for: classDef) else { continue }
            let walled = ObjectPrivacy.shownLabel(of: thing, in: store, classes: classes)
            func isA(_ key: SystemCatalog.Key) -> Bool {
                classes[key].map { ClassResolver.isSubclass(classDef, of: $0) } ?? false
            }
            switch app {
            case .lists where isA(.list):
                if walled != nil {
                    result.append(OccasionFact(app: app, thing: thing.id, text: ListContents.privateListLabel))
                    continue
                }
                let items = contents.items(of: thing)
                let text = LandingSentences.leftOf(left: items.count { !$0.isDone }, total: items.count) ?? "Empty"
                result.append(OccasionFact(app: app, thing: thing.id, text: text))
            case .kitchen where isA(.recipe):
                if walled != nil {
                    result.append(OccasionFact(app: app, thing: thing.id, text: ObjectPrivacy.recipeLabel))
                    continue
                }
                let count = Groceries(store: store, classes: classes).toBuy(for: thing.id)
                result.append(OccasionFact(app: app, thing: thing.id, text: "\(count) to get"))
            case .routines where isA(.routine):
                // A private routine is a private workout: no fact, never named.
                guard walled == nil else { continue }
                result.append(OccasionFact(app: app, thing: thing.id, text: thing.title))
            case .training:
                if walled != nil {
                    trainingMasked = true
                } else {
                    training = true
                }
            case .money where isA(.pool):
                // The one fact that carries an amount: the Occasion page only. Any other surface omits it entirely.
                guard surface == .occasionPage else { continue }
                let book = PoolBook(store: store, classes: classes)
                let text = PoolFormat.amount(book.balance(of: thing), currency: book.currency(of: thing))
                result.append(OccasionFact(app: app, thing: thing.id, text: text))
            default:
                continue
            }
        }
        if training, let count = sessions(in: occasion, store: store, classes: classes, calendar: calendar) {
            result.append(OccasionFact(app: .training, thing: nil, text: sessionsText(count)))
        } else if trainingMasked {
            result.append(OccasionFact(app: .training, thing: nil, text: ObjectPrivacy.routineLabel))
        }
        return result
    }

    /// Counted (not private) workouts with a logged exercise inside the occasion's days, start of the first day to
    /// the end of the last. Nil when the occasion has no dates.
    static func sessions(in occasion: ObjectRecord, store: ObjectStore, classes: [SystemCatalog.Key: ClassDef],
                         calendar: Calendar) -> Int?
    {
        guard let start = store.value("start", of: occasion)?.dateValue else { return nil }
        let last = store.value("end", of: occasion)?.dateValue ?? start
        let from = calendar.startOfDay(for: start)
        guard let to = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: last)) else { return nil }
        let stats = TrainingStats(store: store, classes: classes)
        let workouts = Set(stats.counted().filter { $0.session.date >= from && $0.session.date < to }
            .map(\.session.workoutID))
        return workouts.count
    }

    static func sessionsText(_ count: Int) -> String {
        switch count {
        case 0: "No sessions"
        case 1: "1 session"
        default: "\(count) sessions"
        }
    }
}
