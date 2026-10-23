import Foundation

/// The numbers that can say how they were made.
public enum NumberID: Hashable, Sendable {
    /// The weight the next set of an exercise opens at.
    case nextWeight(exercise: UUID)
    /// How long a routine usually takes.
    case sessionLength(routine: UUID)
    /// The count of dinners that are covered.
    case coversDinners
    /// The one dollar total in Money.
    case moneyAboutTotal
    /// A pool's balance.
    case poolBalance(pool: UUID)
    /// The month's spend in one currency.
    case monthSpend(currency: String)
    /// The longest finished run of weeks in a row with a session (never a running one; the word "streak" is only
    /// this case's name).
    case streak(habit: Habit)
    /// An exercise's best, as a one-rep estimate.
    case bestSet(exercise: UUID)

    public enum Habit: String, Hashable, Sendable {
        case training
    }
}

/// "Why this number" (Together sheet 144, switch whyNumbers): one plain sentence, computed on the phone from the same
/// facts that made the number. Nil when there is nothing to say or the number is not one this explains; the long press
/// then does nothing. Nothing here goes to Claude, a log, a backup or a widget. A private workout, routine or pool is
/// named by its label ("Private workout", "Private pool"), never its name; body, health and calorie numbers are not
/// explained at all.
@MainActor
public enum Explain {
    public static func number(_ id: NumberID, engine: ActionEngine, ecb: CurrencyRates? = nil, now: Date = .now,
                              calendar: Calendar = .current, unit: MassUnit = .kilograms, lakh: Bool = false) -> String?
    {
        let store = engine.store, classes = engine.classes
        switch id {
        case let .nextWeight(exercise): return nextWeight(exercise, store, classes, unit)
        case let .sessionLength(routine): return sessionLength(routine, store, classes)
        case .coversDinners: return coversDinners(store, classes)
        case .moneyAboutTotal: return aboutTotal(store, classes, ecb, now, calendar, lakh)
        case let .poolBalance(pool): return poolBalance(pool, store, classes)
        case let .monthSpend(currency): return monthSpend(currency, store, classes, now, calendar)
        case let .streak(habit): return run(habit, store, classes, now, calendar)
        case let .bestSet(exercise): return bestSet(exercise, store, classes, unit)
        }
    }

    // MARK: Training

    private static func nextWeight(_ id: UUID, _ store: ObjectStore, _ classes: [SystemCatalog.Key: ClassDef],
                                   _ unit: MassUnit) -> String?
    {
        guard let exercise = store.classDef(id: id) else { return nil }
        let ledger = TrainingLedger(store: store, classes: classes)
        guard let last = ledger.sessions(of: exercise).first, let top = last.sets.max(by: { $0.weight < $1.weight }),
              let next = ledger.nextTarget(for: exercise).weight else { return nil }
        // A private session is not described.
        guard ObjectPrivacy.shownLabel(of: last.workout, in: store, classes: classes) == nil else { return nil }
        let number = StatsMass.number(kg: next, unit: unit)
        let was = "\(StatsMass.number(kg: top.weight, unit: unit)) for \(StatsMass.trimmed(top.reps))"
        let gap = next - top.weight
        let tail = gap > 0.001
            ? "plus one \(StatsMass.number(kg: gap, unit: unit)) step."
            : "the same weight until every set reaches the top of the range."
        return "\(number): your last \(exercise.name), \(was), \(tail)"
    }

    private static func sessionLength(_ id: UUID, _ store: ObjectStore, _ classes: [SystemCatalog.Key: ClassDef])
        -> String?
    {
        guard let routine = store.object(id: id), !routine.isDeleted else { return nil }
        let stats = TrainingStats(store: store, classes: classes)
        // The landing hides a private routine's minutes, so the number has nothing to explain.
        guard ObjectPrivacy.shownLabel(of: routine, in: store, classes: classes) == nil,
              let minutes = stats.usualMinutes(of: routine) else { return nil }
        let count = stats.finishedCount(of: routine, limit: 3)
        let name = routine.title
        return "about \(HouseTime.minutes(minutes)): your last \(count) \(name) \(count == 1 ? "session" : "sessions")."
    }

    private static func bestSet(_ id: UUID, _ store: ObjectStore, _ classes: [SystemCatalog.Key: ClassDef],
                                _ unit: MassUnit) -> String?
    {
        guard let exercise = store.classDef(id: id) else { return nil }
        let stats = TrainingStats(store: store, classes: classes)
        let counted = stats.ledger.sessions(of: exercise).filter { stats.isCounted($0) }
        guard let best = counted.flatMap(\.sets).filter(\.isE1RMEligible).max(by: { $0.e1RM < $1.e1RM }) else {
            return nil
        }
        return "\(StatsMass.estimate(kg: best.e1RM, unit: unit)): your best \(exercise.name), "
            + "\(StatsMass.number(kg: best.weight, unit: unit)) for \(StatsMass.trimmed(best.reps)), as a one-rep estimate."
    }

    private static func run(_ habit: NumberID.Habit, _ store: ObjectStore, _ classes: [SystemCatalog.Key: ClassDef],
                            _ now: Date, _ calendar: Calendar) -> String?
    {
        switch habit {
        case .training:
            let stats = TrainingStats(store: store, classes: classes)
            guard let weeks = stats.habit(.year, now: now, calendar: calendar).bestRun else { return nil }
            return "\(weeks) weeks: the most weeks in a row with a session, counting only runs that have ended."
        }
    }

    // MARK: Kitchen

    private static func coversDinners(_ store: ObjectStore, _ classes: [SystemCatalog.Key: ClassDef]) -> String? {
        let covered = KitchenLanding(store: store, classes: classes).coveredRecipes()
        guard !covered.isEmpty else { return nil }
        let names = covered.map { recipe -> String in
            ObjectPrivacy.shownLabel(of: recipe, in: store, classes: classes) ?? recipe.title.lowercased()
        }
        let list = names.count == 1 ? names[0] : names.dropLast()
            .joined(separator: ", ") + " and " + names[names.count - 1]
        return "covers \(covered.count) \(covered.count == 1 ? "dinner" : "dinners"): \(list) "
            + "\(covered.count == 1 ? "has" : "have") all they need."
    }

    // MARK: Money (phone only)

    private static func aboutTotal(
        _ store: ObjectStore,
        _ classes: [SystemCatalog.Key: ClassDef],
        _ ecb: CurrencyRates?,
        _ now: Date,
        _ calendar: Calendar,
        _ lakh: Bool
    ) -> String? {
        let report = PoolReport(store: store, classes: classes, ecb: ecb, now: now, lakh: lakh)
        let about = report.about()
        guard let dollars = about.dollars, let from = about.ratesFrom else { return nil }
        let converted = report.totals()
            .filter { $0.currency != "USD" && !about.leftOut.contains($0.currency) && $0.amount != 0 }
        let words = (["dollars"] + converted.map { PoolReport.word($0.currency).lowercased() })
        let list = words.count == 2 ? "\(words[0]) plus \(words[1])" : words.dropLast()
            .joined(separator: ", ") + " plus " + words[words.count - 1]
        return "\(PoolFormat.wholeNumber(Decimal(dollars), lakh: lakh)): \(list) at the \(PoolReport.day(from, calendar)) rate."
    }

    private static func poolBalance(_ id: UUID, _ store: ObjectStore,
                                    _ classes: [SystemCatalog.Key: ClassDef]) -> String?
    {
        guard let pool = store.object(id: id), !pool.isDeleted,
              pool.classDef?.id == classes[.pool]?.id else { return nil }
        let book = PoolBook(store: store, classes: classes)
        let amount = PoolFormat.amount(book.balance(of: pool), currency: book.currency(of: pool), text: true)
        let label = ObjectPrivacy.poolLabel
        return "\(amount): what \(label) started with, plus what came in, minus what went out."
    }

    private static func monthSpend(_ currency: String, _ store: ObjectStore, _ classes: [SystemCatalog.Key: ClassDef],
                                   _ now: Date, _ calendar: Calendar) -> String?
    {
        let month = PoolReport(store: store, classes: classes, now: now).monthSpends(calendar: calendar)
        guard let total = month[currency] else { return nil }
        let word = PoolReport.word(currency).lowercased()
        return "\(PoolFormat.digits(total)): what you logged this month in \(word)."
    }
}
