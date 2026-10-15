import Foundation

/// The 5-year fixture shape from ScaleTests: workouts × 5 exercise entries × 5 sets.
enum Fixture {
    static let workouts = ProcessInfo.processInfo.environment["SPIKE_WORKOUTS"].flatMap(Int.init) ?? 1500
    static let exercisesPerWorkout = 5
    static let setsPerEntry = 5
    static let epoch = 1_700_000_000.0

    static func workoutDate(_ day: Int) -> Date {
        Date(timeIntervalSince1970: epoch + Double(day) * 86400)
    }

    static func setValues(day: Int, set: Int, ids: FieldIDs) -> FieldValues {
        var values = FieldValues()
        values[ids.weight] = .mass(60 + Double(day % 40))
        values[ids.reps] = .number(Double(5 + set))
        values[ids.rpe] = .number(8)
        values[ids.kind] = .choice("working")
        values[ids.isWarmup] = .bool(false)
        return values
    }

    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return encoder
    }()
}

struct FieldIDs: Sendable {
    var weight: UUID, reps: UUID, rpe: UUID, kind: UUID, isWarmup: UUID, endedAt: UUID, exercise: UUID
}

/// One set as plain values, the training index's unit.
struct LoggedSet: Sendable {
    let id: UUID
    let weight: Double
    let reps: Double
    let rpe: Double?
    let e1RM: Double
}

struct EntryFact: Sendable {
    let entryID: UUID
    let workoutID: UUID
    let classID: UUID
    let date: Date
    let sets: [LoggedSet]
}

func e1RM(weight: Double, reps: Double) -> Double {
    weight * (1 + reps / 30)
}

func loggedSet(id: UUID, values: FieldValues, ids: FieldIDs) -> LoggedSet? {
    if values[ids.isWarmup] == .bool(true) { return nil }
    guard let weight = values[ids.weight]?.numericValue, let reps = values[ids.reps]?.numericValue else { return nil }
    return LoggedSet(id: id, weight: weight, reps: reps, rpe: values[ids.rpe]?.numericValue,
                     e1RM: e1RM(weight: weight, reps: reps))
}

// MARK: - Timing

let clock = ContinuousClock()

func ms(_ duration: Duration) -> Double {
    Double(duration.components.seconds) * 1000 + Double(duration.components.attoseconds) / 1e15
}

func measure<T>(_ name: String, _ work: () throws -> T) rethrows -> T {
    let start = clock.now
    let value = try work()
    result(name, ms(clock.now - start))
    return value
}

func result(_ name: String, _ value: Double) {
    print("RESULT \(name) \(String(format: "%.2f", value))")
}

func directorySize(_ url: URL) -> Int {
    let manager = FileManager.default
    guard let enumerator = manager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
    var total = 0
    for case let file as URL in enumerator {
        total += (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
    }
    return total
}
