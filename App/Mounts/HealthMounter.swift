import Foundation
import HealthKit
import TesseraCore

/// The Health mount's one reader of HealthKit (M4 slice 2): last night's sleep, today's steps and the resting heart
/// rate, read on foreground only. Health hides a refused read ("it simply appears as if there is no data"), so a
/// refusal and an empty store give the same result and the app never says "permission denied". A read that throws
/// (a locked store) is reported as `readFailed`, which changes nothing.
@MainActor
final class HealthMounter {
    private let store = HKHealthStore()
    private let engine: ActionEngine

    private static let sleep = HKCategoryType(.sleepAnalysis)
    private static let steps = HKQuantityType(.stepCount)
    private static let resting = HKQuantityType(.restingHeartRate)

    init(engine: ActionEngine) {
        self.engine = engine
    }

    /// From his tap only (Settings or the first Plan my day card).
    func requestAccess() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        try? await store.requestAuthorization(toShare: [], read: [Self.sleep, Self.steps, Self.resting])
    }

    @discardableResult
    func refresh(now: Date = .now, calendar: Calendar = .current) async -> Int? {
        guard HKHealthStore.isHealthDataAvailable() else { return nil }
        let inputs = await read(now: now, calendar: calendar)
        return try? engine.perform(SyncHealth(inputs: inputs, now: now, zone: calendar.timeZone.identifier),
                                   by: .system).output
    }

    private func read(now: Date, calendar: Calendar) async -> HealthInputs {
        let today = calendar.startOfDay(for: now)
        let windowStart = calendar.date(byAdding: .hour, value: -6, to: today) ?? today // 18:00 yesterday
        var inputs = HealthInputs()
        do {
            let sleepPredicate = HKQuery.predicateForSamples(withStart: windowStart, end: now)
            let sleepSamples = try await HKSampleQueryDescriptor(
                predicates: [.categorySample(type: Self.sleep, predicate: sleepPredicate)], sortDescriptors: []
            ).result(for: store)
            inputs.sleep = sleepSamples.compactMap { sample in
                guard let value = HKCategoryValueSleepAnalysis(rawValue: sample.value) else { return nil }
                let mapped: SleepValue? = switch value {
                case .inBed: .inBed
                case .awake: .awake
                case .asleepCore: .asleepCore
                case .asleepDeep: .asleepDeep
                case .asleepREM: .asleepREM
                case .asleepUnspecified: .asleepUnspecified
                @unknown default: nil
                }
                return mapped.map {
                    SleepSample(value: $0, start: sample.startDate, end: sample.endDate,
                                sourceBundle: sample.sourceRevision.source.bundleIdentifier,
                                productType: sample.sourceRevision.productType ?? "")
                }
            }
            let stepsPredicate = HKQuery.predicateForSamples(withStart: today, end: now)
            let statistics = try? await HKStatisticsQueryDescriptor(
                predicate: .quantitySample(type: Self.steps, predicate: stepsPredicate), options: .cumulativeSum
            ).result(for: store)
            inputs.stepsToday = statistics?.sumQuantity().map { Int($0.doubleValue(for: .count())) }
            let restingSamples = try await HKSampleQueryDescriptor(
                predicates: [.quantitySample(type: Self.resting,
                                             predicate: HKQuery.predicateForSamples(withStart: windowStart, end: now))],
                sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)], limit: 1
            ).result(for: store)
            if let latest = restingSamples.first {
                inputs.restingHeartRate = latest.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                inputs.restingHeartRateAt = latest.startDate
            }
        } catch {
            inputs.readFailed = true
        }
        return inputs
    }
}
