import Foundation
import TesseraCore

/// What the You page says about him, read once from the store (Design 108 section 3, huddle B2): the last weigh-in,
/// the training totals and each lift's best, from `TrainingLedger`. Plain values, so the page's lines are testable
/// without a view.
struct MeFacts: Equatable {
    /// One exercise he has trained: its best estimated one-rep max and how many sessions it has.
    struct Best: Identifiable, Equatable {
        let id: UUID
        let name: String
        let bestE1RM: Double?
        let sessions: Int
    }

    /// His last weigh-in in kilograms (a private note today), nil with none. Never shown until he taps it.
    var weightKg: Double?
    /// Workouts with at least one working set.
    var workouts = 0
    /// The first of them, for "since March 2025".
    var firstWorkout: Date?
    /// Working sets across every workout (warm-ups left out).
    var workingSets = 0
    /// Every exercise trained in a plain workout, most-trained first. A private workout's sets never reach a best.
    var bests: [Best] = []

    static let empty = MeFacts()

    @MainActor
    static func read(_ model: AppModel) -> MeFacts {
        var facts = MeFacts()
        facts.weightKg = BodyWeight.lastKg(in: model.store)
        guard let root = model.classes[.exercise], let ledger = model.ledger else { return facts }
        var workouts: [UUID: Date] = [:]
        var privateWorkouts: [UUID: Bool] = [:]
        var bests: [Best] = []
        for exercise in ClassResolver.descendants(of: root) {
            // Only the class's own sessions: `sessions(of:)` folds subclasses in, and they get their own row.
            let sessions = ledger.sessions(of: exercise).filter { session in
                model.store.linkedClass("exercise", of: session.entry)?.id == exercise.id
            }
            guard !sessions.isEmpty else { continue }
            var plain = 0
            var best: Double?
            for session in sessions {
                workouts[session.workoutID] = min(workouts[session.workoutID] ?? session.date, session.date)
                facts.workingSets += session.sets.count
                let isPrivate = privateWorkouts[session.workoutID] ?? {
                    let masked = ObjectPrivacy.label(of: session.workout, in: model.store,
                                                     classes: model.classes) != nil
                    privateWorkouts[session.workoutID] = masked
                    return masked
                }()
                guard !isPrivate else { continue }
                plain += 1
                for set in session.sets where set.isE1RMEligible {
                    best = max(best ?? 0, set.e1RM)
                }
            }
            if plain > 0 {
                bests.append(Best(id: exercise.id, name: exercise.name, bestE1RM: best, sessions: plain))
            }
        }
        facts.workouts = workouts.count
        facts.firstWorkout = workouts.values.min()
        facts.bests = MeCopy.ordered(bests)
        return facts
    }
}
