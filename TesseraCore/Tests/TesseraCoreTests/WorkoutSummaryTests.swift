import Foundation
@testable import TesseraCore
import Testing

@MainActor
struct WorkoutSummaryTests {
    @Test func finishingGivesHomeASummaryWithRecords() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let ledger = TrainingLedger(store: store, classes: classes)
        let plan = try #require(store.object(id: StarterContent.planID))
        let pushA = try #require(store.linkedObjects("routines", of: plan).first)
        let start = Date(timeIntervalSince1970: 1_792_000_000)

        func session(daysAgo: Double, bench: [(Double, Double)]) throws -> ObjectRecord {
            let time = start.addingTimeInterval(-daysAgo * 86400)
            let workout = try engine.perform(StartRoutine(routine: pushA.id, time: time), by: .user).output
            let entry = try #require(workout.orderedChildren.first)
            for (weight, reps) in bench {
                try engine.perform(LogSet(entry: entry.id, weight: weight, reps: reps), by: .user)
            }
            try engine.perform(FinishWorkout(workout: workout.id, time: time.addingTimeInterval(3600)), by: .user)
            return workout
        }
        _ = try session(daysAgo: 7, bench: [(80, 8), (80, 7)])
        let today = try session(daysAgo: 0, bench: [(82.5, 8), (80, 8), (80, 8)])

        let summary = ledger.summary(of: today)
        #expect(summary.exercisesDone == 1 && summary.exercisesPlanned == 5)
        #expect(summary.sets == 3 && summary.volume == 82.5 * 8 + 80 * 16)
        #expect(summary.records.count == 1 && summary.records.first?.kind == .e1RM)
        #expect(summary.line == "1 of 5 exercises, 3 sets, 1 best.")
        #expect(summary.doneLine == "\(summary.title) done, 1 of 5 exercises.")
        #expect(summary.doneLine(in: store) == "\(summary.title) done, 1 of 5 exercises.")
        #expect(summary.duration == 3600)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        #expect(ledger.finishedWorkouts(on: start, calendar: calendar).map(\.id) == [today.id])
    }

    @Test func aPrivateRoutineTitleNeverPrintsInTheDoneLine() throws {
        // QA on #781: "Physio rehab" is a care word; Tess's done line says "Private workout".
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let plan = try #require(store.object(id: StarterContent.planID))
        let routine = try #require(store.linkedObjects("routines", of: plan).first)
        try engine.perform(RenameObject(object: routine.id, title: "Knee rehab day"), by: .user)
        let workout = try engine.perform(StartRoutine(routine: routine.id), by: .user).output
        try engine.perform(FinishWorkout(workout: workout.id), by: .user)
        let line = TrainingLedger(store: store, classes: classes).summary(of: workout).doneLine(in: store)
        #expect(line.hasPrefix("Private workout done,") && !line.lowercased().contains("rehab"), "\(line)")
    }

    @Test func theDoneLineAgreesInNumberAndSaysNothingOfZeroPlanned() throws {
        // QA on #781: "1 of 1 exercise", and a workout with nothing planned says "done." with no "0 of 0".
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let plan = try #require(store.object(id: StarterContent.planID))
        let routine = try #require(store.linkedObjects("routines", of: plan).first)
        let workout = try engine.perform(StartRoutine(routine: routine.id), by: .user).output
        let base = TrainingLedger(store: store, classes: classes).summary(of: workout)
        func line(done: Int, planned: Int) -> String {
            WorkoutSummary(id: base.id, workout: workout, title: "Push Day A", startedAt: nil, endedAt: nil,
                           exercisesDone: done, exercisesPlanned: planned, sets: 1, volume: 0, records: []).doneLine
        }
        #expect(line(done: 1, planned: 1) == "Push Day A done, 1 of 1 exercise.")
        #expect(line(done: 2, planned: 5) == "Push Day A done, 2 of 5 exercises.")
        #expect(line(done: 0, planned: 0) == "Push Day A done.")
    }
}
