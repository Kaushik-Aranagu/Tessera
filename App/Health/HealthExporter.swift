import Foundation
import HealthKit
import TesseraCore

/// Saves finished workouts to Apple Health (ship list slice 19): a traditional strength training workout with
/// its start and end, and Tessera's sets and volume as metadata. Listens to the engine, so finishing from live
/// mode, Siri, the Lock Screen or the 6-hour wrap-up all reach Health the same way.
@MainActor
final class HealthExporter {
    private let store = HKHealthStore()
    private let ledger: TrainingLedger
    private var authorized = false

    init(engine: ActionEngine) {
        ledger = TrainingLedger(store: engine.store, classes: engine.classes)
        engine.observe { [weak self] record in
            guard Self.exports(record.action), let self else { return }
            let workouts = record.objectIDs.compactMap { engine.store.object(id: $0) }
            for workout in workouts where workout.classDef.map({ self.isWorkout($0, engine: engine) }) == true {
                let summary = ledger.summary(of: workout)
                Task { await self.save(summary) }
            }
        }
    }

    /// The actions that finish a workout: a normal finish, and finish early from the running order.
    nonisolated static func exports(_ action: String) -> Bool {
        action == FinishWorkout.descriptor.name || action == FinishWorkoutEarly.descriptor.name
    }

    private func isWorkout(_ classDef: ClassDef, engine: ActionEngine) -> Bool {
        engine.classes[.workout].map { ClassResolver.isSubclass(classDef, of: $0) } ?? false
    }

    /// Asks once, the first time there's something to save. Health only shows the prompt the first time.
    private func authorize() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        if authorized {
            return true
        }
        do {
            try await store.requestAuthorization(toShare: [HKObjectType.workoutType()], read: [])
            authorized = store.authorizationStatus(for: .workoutType()) == .sharingAuthorized
        } catch {
            authorized = false
        }
        return authorized
    }

    func save(_ summary: WorkoutSummary) async {
        guard let start = summary.startedAt, let end = summary.endedAt, end > start, summary.sets > 0,
              await authorize() else { return }
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .indoor
        let builder = HKWorkoutBuilder(healthStore: store, configuration: configuration, device: .local())
        do {
            try await builder.beginCollection(at: start)
            try await builder.addMetadata([
                // Re-saving the same workout replaces it instead of duplicating it.
                HKMetadataKeySyncIdentifier: summary.id.uuidString,
                HKMetadataKeySyncVersion: Int(end.timeIntervalSince1970),
                HKMetadataKeyWorkoutBrandName: "Tessera",
                "TesseraSets": summary.sets,
                "TesseraVolumeKilograms": summary.volume,
            ])
            try await builder.endCollection(at: end)
            _ = try await builder.finishWorkout()
        } catch {
            // Health is a mirror; the workout is safe in Tessera either way.
        }
    }
}
