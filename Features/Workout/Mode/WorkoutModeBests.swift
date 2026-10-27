import Foundation

/// New bests in the workout mode (sheet 336). A set's Epley estimate beats the lift's best when its whole-unit value is
/// higher than the best's (ties do not, and a lift with no history has no best to beat, so its first sets claim
/// nothing). The best is the ledger's (`LiftHistory.bestEstimate`, which `LedgerModeHistory` fills from
/// `TrainingLedger.bestSet`), raised by any earlier set of the same lift this session, so one record is announced once.
/// Pure and in the display unit. Nothing here reaches the lock screen: `ModeLiveContent` has no field for it.
extension WorkoutModeState {
    struct NewBest: Equatable {
        var liftName: String
        /// The estimate, rounded to a whole unit.
        var estimate: Double

        /// "216", the number the screen sets large.
        var number: String {
            PlateLoad.number(estimate)
        }

        /// "new best, est. 216 lb" (the screen draws the unit at half size).
        func line(unit: String) -> String {
            "new best, est. \(number) \(unit)"
        }
    }

    /// Whether `estimate` beats `best`: by whole-unit value, so a tie (or a number that only rounds up to the best)
    /// does not. No best, nothing to beat.
    static func beats(estimate: Double, best: Double?) -> Bool {
        guard let best else { return false }
        return estimate.rounded() > best.rounded()
    }

    /// The best to beat on a lift before set `index`: the ledger's, or an earlier set this session if higher.
    private func bestToBeat(on lift: Lift, before index: Int) -> Double? {
        guard let ledger = lift.history.bestEstimate else { return nil }
        let earlier = lift.sets.prefix(index).compactMap(\.done).compactMap { Self.epley(
            weight: $0.weight,
            reps: $0.reps
        ) }
        return max(ledger, earlier.max() ?? 0)
    }

    /// The new best the set just logged made, if it did: shown during the rest after it, cleared when the rest ends.
    var restNewBest: NewBest? {
        guard case let .rest(_, _, liftIndex) = phase,
              let lastDone = lifts[liftIndex].sets.lastIndex(where: { $0.done != nil }),
              let done = lifts[liftIndex].sets[lastDone].done,
              let estimate = Self.epley(weight: done.weight, reps: done.reps) else { return nil }
        let lift = lifts[liftIndex]
        guard Self.beats(estimate: estimate, best: bestToBeat(on: lift, before: lastDone)) else { return nil }
        return NewBest(liftName: lift.name, estimate: estimate.rounded())
    }

    /// The session's real new bests, one per lift: its top estimate where that beat the ledger's best.
    var sessionBests: [NewBest] {
        lifts.compactMap { lift in
            guard let best = lift.history.bestEstimate,
                  let top = lift.sets.compactMap(\.done).compactMap({ Self.epley(weight: $0.weight, reps: $0.reps) })
                  .max(),
                  Self.beats(estimate: top, best: best) else { return nil }
            return NewBest(liftName: lift.name, estimate: top.rounded())
        }
    }

    /// The Done board's lines: each new best, or "No new bests, steady work".
    var doneBestLines: [String] {
        let bests = sessionBests
        guard !bests.isEmpty else { return ["No new bests, steady work"] }
        return bests.map { "\($0.liftName), est. \($0.number) \(unit.symbol)" }
    }
}
