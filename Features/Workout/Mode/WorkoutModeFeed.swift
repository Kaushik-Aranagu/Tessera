import Foundation
import TesseraCore

/// Where the mode's state gets what the ledger and the routine know. Two seams keep the state free of the store:
/// `ModeHistory` (last time's same set, the best, the estimated max) and `WarmUpSource` (the routine's warm-up, which
/// waits on Core's #1463 API; until it merges the sample source stands in).
@MainActor
protocol ModeHistory {
    func history(for exercise: ClassDef, in unit: MassUnit) -> WorkoutModeState.LiftHistory
}

/// The ledger's answer: last time's working sets, the best set by estimated max, and that estimate.
@MainActor
struct LedgerModeHistory: ModeHistory {
    let ledger: TrainingLedger
    /// The live workout is left out, so its own sets are never "last time".
    let workoutID: UUID?

    func history(for exercise: ClassDef, in unit: MassUnit) -> WorkoutModeState.LiftHistory {
        let last = ledger.sessions(of: exercise, excludingWorkout: workoutID).first
        let sets = last?.sets.map {
            WorkoutModeState.LiftHistory.Set(weight: unit.fromKilograms($0.weight), reps: Int($0.reps.rounded()))
        } ?? []
        let best = ledger.bestSet(of: exercise, excludingWorkout: workoutID)
        let bestDate = ledger.sessions(of: exercise, excludingWorkout: workoutID)
            .first { $0.sets.contains { $0.id == best?.id } }?.date
        return WorkoutModeState.LiftHistory(
            lastTime: sets,
            best: best.map { .init(weight: unit.fromKilograms($0.weight), reps: Int($0.reps.rounded())) },
            bestDate: bestDate,
            bestEstimate: best.map { unit.fromKilograms($0.e1RM) }
        )
    }
}

/// The routine's warm-up (Core #1463): a timed block before the first lift ("Rower", 8 minutes, a line), not sets.
struct WarmUpPlan: Equatable, Sendable {
    var name: String
    var minutes: Int
    var note: String?
}

/// Where the warm-up comes from: Core's `TrainingStats.warmUp(of:)` in the app, nothing in tests.
protocol WarmUpSource {
    func warmUp(for workout: ObjectRecord, in model: AppModel) -> WarmUpPlan?
}

/// No warm-up: the mode starts on the first lift.
struct NoWarmUp: WarmUpSource {
    func warmUp(for _: ObjectRecord, in _: AppModel) -> WarmUpPlan? {
        nil
    }
}

/// Core's answer: the routine the workout came from, through `TrainingStats.warmUp(of:)` (nil for none or a private
/// routine).
struct CoreWarmUp: WarmUpSource {
    func warmUp(for workout: ObjectRecord, in model: AppModel) -> WarmUpPlan? {
        guard let routine = model.store.linkedObjects("routine", of: workout).first else { return nil }
        let stats = TrainingStats(store: model.store, classes: model.classes)
        return stats.warmUp(of: routine).map { WarmUpPlan(name: $0.name, minutes: $0.minutes, note: $0.note) }
    }
}

extension WorkoutModeState {
    /// Warm up 30 s; the rest of the rests come from the exercise (sheet 321: bench 2:30, press 2:00, row 1:30).
    static let warmUpRestSeconds = 30

    /// Builds the mode from a live workout: a lift per entry, sets from the plan and last time's prefill, history from
    /// the ledger, the warm-up from the routine. Private workouts read "Private workout" in the title.
    @MainActor
    static func make(from session: WorkoutSession, warmUp source: some WarmUpSource = CoreWarmUp(),
                     unit: MassUnit = Format.unit) -> WorkoutModeState
    {
        let history = LedgerModeHistory(ledger: session.ledger, workoutID: session.workout.id)
        var lifts: [Lift] = []
        if let warm = source.warmUp(for: session.workout, in: session.model) {
            lifts.append(Lift(id: "warmup", name: "Warm up", equipment: .stack, restSeconds: warmUpRestSeconds,
                              sets: [PlannedSet(weight: 0, reps: 0)], isWarmUp: true, warmUp: warm))
        }
        for entry in session.entries {
            guard let exercise = session.exerciseClass(of: entry) else { continue }
            let prefill = session.ledger.prefill(for: entry)
            let kilos = prefill.weight ?? 0
            let weight = unit.fromKilograms(kilos)
            let dial = session.weightDial(of: exercise)
            let rest = session.model.store.number("restSeconds", of: entry)
                ?? ClassResolver.field("restSeconds", of: exercise)?.defaultValue?.numericValue ?? 120
            let logged = session.setRows(of: entry).map {
                PlannedSet(weight: unit.fromKilograms($0.weight), reps: Int($0.reps),
                           done: Done(
                               weight: unit.fromKilograms($0.weight),
                               reps: Int($0.reps),
                               felt: nil,
                               at: session.startedAt
                           ))
            }
            let left = max(session.targetSets(of: entry) - logged.count, 0)
            let planned = (0 ..< left).map { _ in PlannedSet(weight: weight, reps: prefill.reps) }
            lifts.append(Lift(
                id: entry.id.uuidString, name: exercise.name,
                equipment: dial.platesPerSide(kilos) != nil ? .barbell : .stack,
                restSeconds: Int(rest), sets: logged + planned,
                history: history.history(for: exercise, in: unit)
            ))
        }
        var state = WorkoutModeState(title: session.shownTitle, unit: unit, startedAt: session.startedAt, lifts: lifts)
        state.isPrivate = session.isPrivate
        return state
    }
}
