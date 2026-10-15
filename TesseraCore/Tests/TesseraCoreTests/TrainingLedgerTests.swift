import Foundation
@testable import TesseraCore
import Testing

@MainActor
struct TrainingLedgerTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let store: ObjectStore
    let ledger: TrainingLedger
    let now = Date(timeIntervalSince1970: 1_792_000_000)

    init() throws {
        store = ObjectStore(context: container.mainContext)
        classes = try SystemCatalog.seed(in: container.mainContext)
        ledger = TrainingLedger(store: store, classes: classes)
    }

    /// Logs a finished workout `daysAgo` days before `now` with one entry per exercise.
    @discardableResult
    func workout(daysAgo: Double, _ entries: [(ClassDef, [(Double, Double)])],
                 warmups: [(Double, Double)] = []) throws -> ObjectRecord
    {
        let workout = try store.create(#require(classes[.workout]), title: "Push Day A")
        try store.set("endedAt", to: .date(now.addingTimeInterval(-daysAgo * 86400)), on: workout)
        for (exercise, sets) in entries {
            let entry = try store.create(#require(classes[.exerciseEntry]), parent: workout)
            try store.setClassLink("exercise", on: entry, to: exercise)
            for (weight, reps) in warmups {
                try ledger.logSet(weight: weight, reps: reps, isWarmup: true, in: entry)
            }
            for (weight, reps) in sets {
                try ledger.logSet(weight: weight, reps: reps, in: entry)
            }
        }
        return workout
    }

    @Test func sessionsAreNewestFirstAndSkipWarmups() throws {
        let bench = try #require(classes[.benchPress])
        try workout(daysAgo: 7, [(bench, [(80, 8), (80, 7)])], warmups: [(40, 10)])
        try workout(daysAgo: 3, [(bench, [(82.5, 6)])])

        let sessions = ledger.sessions(of: bench)
        #expect(sessions.map(\.sets.count) == [1, 2])
        #expect(sessions[1].volume == 80 * 8 + 80 * 7)
        #expect(abs(sessions[1].bestE1RM - 80 * (1 + 8.0 / 30)) < 0.0001)
        // Subclass sessions roll up into the parent class.
        #expect(try ledger.sessions(of: #require(classes[.barbellLift])).count == 2)
    }

    @Test func personalRecordsAndHints() throws {
        let bench = try #require(classes[.benchPress])
        try workout(daysAgo: 7, [(bench, [(80, 8), (80, 7)])])
        let today = try workout(daysAgo: 0, [(bench, [(100, 1)])])

        let records = ledger.records(for: bench, excludingWorkout: today.id)
        #expect(records.bestE1RM?.weight == 80)
        #expect(records.bestWeightByReps == [8: 80, 7: 80])
        #expect(records.bestSessionVolume == Double(80 * 15))

        // 80 × 9 beats the e1RM; there is no 9-rep record yet to beat.
        #expect(ledger.recordsBeaten(weight: 80, reps: 9, for: bench, excludingWorkout: today.id) == [.e1RM])
        // 82.5 × 7 beats both.
        #expect(ledger.recordsBeaten(weight: 82.5, reps: 7, for: bench, excludingWorkout: today.id) ==
            [.e1RM, .repMax(7)])
        // Equal is not a record.
        #expect(ledger.recordsBeaten(weight: 80, reps: 8, for: bench, excludingWorkout: today.id).isEmpty)
        // Fewest reps at 82.5 to beat 80 × 8 (e1RM 101.33): 82.5 × 8 = 104.5, 82.5 × 7 = 101.75.
        #expect(ledger.repsToBeatBestE1RM(weight: 82.5, for: bench, excludingWorkout: today.id) == 7)
        #expect(try ledger.repsToBeatBestE1RM(weight: 80, for: #require(classes[.muscle])) == nil)
    }

    @Test func nothingToBeatWithoutHistory() throws {
        let bench = try #require(classes[.benchPress])
        #expect(ledger.records(for: bench).isEmpty)
        #expect(ledger.recordsBeaten(weight: 200, reps: 5, for: bench).isEmpty)
        #expect(ledger.repsToBeatBestE1RM(weight: 60, for: bench) == nil)
    }

    @Test func trendCoversTheWindowOldestFirst() throws {
        let bench = try #require(classes[.benchPress])
        try workout(daysAgo: 120, [(bench, [(70, 8)])])
        try workout(daysAgo: 60, [(bench, [(75, 8)])])
        try workout(daysAgo: 2, [(bench, [(80, 8)])])
        let trend = ledger.trend(of: bench, days: 90, now: now)
        #expect(trend.map(\.volume) == [600, 640])
        #expect(trend.first.map { $0.date < trend[1].date } == true)
    }

    @Test func e1RMUsesTheSetClassFormula() throws {
        #expect(ledger.e1RM(weight: 100, reps: 0) == 100)
        let setClass = try #require(classes[.set])
        let field = try #require(setClass.ownFields?.first { $0.key == "e1rm" })
        field.expression = "weight * (36 / (37 - reps))" // Brzycki
        #expect(ledger.e1RM(weight: 100, reps: 1) == 100)
        let set = store.create(setClass)
        try store.set("weight", to: .mass(90), on: set)
        try store.set("reps", to: .number(1), on: set)
        #expect(store.number("e1rm", of: set) == 90)
        #expect(store.number("volume", of: set) == 90)
    }

    @Test func weeklySetsPerMuscleUsesClassLevelMuscles() throws {
        let bench = try #require(classes[.benchPress])
        let muscle = try #require(classes[.muscle])
        let chest = store.create(muscle, title: "Chest")
        let triceps = store.create(muscle, title: "Triceps")
        try store.setLinks("primaryMuscles", on: store.ensureClassObject(of: bench), to: [chest, triceps])
        let paused = ClassDef(name: "Paused Bench Press", parent: bench)
        container.mainContext.insert(paused)

        try workout(daysAgo: 0, [(bench, [(80, 8), (80, 8)]), (paused, [(70, 5)])], warmups: [(40, 10)])
        try workout(daysAgo: 21, [(bench, [(80, 8)])])

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let counts = ledger.weeklySetsPerMuscle(weekContaining: now, calendar: calendar)
        #expect(counts == [chest.id: 3, triceps.id: 3])
    }
}
