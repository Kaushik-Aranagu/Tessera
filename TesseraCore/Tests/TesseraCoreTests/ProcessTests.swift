import Foundation
import SwiftData
@testable import TesseraCore
import Testing

@MainActor
struct ProcessTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let store: ObjectStore
    let engine: ActionEngine
    let table: ProcessTable
    let start = Date(timeIntervalSince1970: 1_792_000_000)

    init() throws {
        store = ObjectStore(context: container.mainContext)
        classes = try SystemCatalog.seed(in: container.mainContext)
        engine = ActionEngine(store: store, classes: classes)
        table = ProcessTable(engine: engine)
    }

    /// Push Day A with bench (2 × 8 @ 80) and overhead press (2 × 8 @ 45).
    func pushDay(_ title: String = "Push Day A") throws -> (workout: ObjectRecord, bench: ObjectRecord) {
        let workout = try store.create(#require(classes[.workout]), title: title)
        let bench = try engine.perform(AddExercise(workout: workout.id, exercise: #require(classes[.benchPress]).id,
                                                   targetSets: 2, targetReps: 8, targetWeight: 80), by: .user).output
        _ = try engine.perform(AddExercise(workout: workout.id, exercise: #require(classes[.barbellLift]).id,
                                           targetSets: 2, targetReps: 8, targetWeight: 45), by: .user)
        return (workout, bench)
    }

    @Test func startingAWorkoutStartsItsProcessWithANextStep() throws {
        let (workout, bench) = try pushDay()
        try engine.perform(StartWorkout(workout: workout.id, time: start), by: .user)

        let running = try #require(table.running())
        #expect(running.subject?.id == workout.id)
        #expect(running.ownerApp == "Workouts")
        #expect(running.nextStep == "Bench Press, set 1: 80 kg × 8")
        #expect(running.resumePoint == ResumePoint(focus: bench.id, index: 0, weight: 80, reps: 8))

        // Logging a set moves the next step on; after bench it moves to the next exercise.
        try engine.perform(LogSet(entry: bench.id, weight: 80, reps: 8), by: .user)
        #expect(table.running()?.nextStep == "Bench Press, set 2: 80 kg × 8")
        try engine.perform(LogSet(entry: bench.id, weight: 80, reps: 7), by: .user)
        #expect(table.running()?.nextStep == "Barbell Lift, set 1: 45 kg × 8")

        // Starting it again resumes the same process instead of making a second one.
        try engine.perform(StartWorkout(workout: workout.id), by: .user)
        #expect(table.all().count == 1)

        try engine.perform(FinishWorkout(workout: workout.id), by: .user)
        #expect(table.running() == nil)
        #expect(table.all().first?.state == .done)
    }

    @Test func onlyOneProcessRuns() throws {
        let (first, _) = try pushDay()
        let (second, _) = try pushDay("Pull Day A")
        try engine.perform(StartWorkout(workout: first.id, time: start), by: .user)
        try engine.perform(StartWorkout(workout: second.id, time: start.addingTimeInterval(60)), by: .user)

        #expect(table.running()?.subject?.id == second.id)
        #expect(table.ledger(now: start.addingTimeInterval(120)).map { $0.subject?.id } == [first.id])

        let firstProcess = try #require(table.process(for: first))
        try engine.perform(ResumeProcess(process: firstProcess.id), by: .user)
        #expect(table.running()?.subject?.id == first.id)
        #expect(table.all().filter { $0.state == .running }.count == 1)
    }

    @Test func ledgerHoldsUpToThreeRecentSuspendedProcesses() throws {
        let subjects = try (0 ..< 5).map { try store.create(#require(classes[.note]), title: "Note \($0)") }
        for (index, subject) in subjects.enumerated() {
            let time = start.addingTimeInterval(Double(index) * 86400)
            let process = try engine.perform(StartProcess(subject: subject.id, time: time), by: .user).output
            try engine.perform(SuspendProcess(process: process.id, nextStep: "Finish note \(index)", time: time),
                               by: .user)
        }
        // Notes 0 and 1 were last touched more than 3 days before `now`, so they have left Home.
        let now = start.addingTimeInterval(4.5 * 86400)
        #expect(table.ledger(now: now).map(\.nextStep) == ["Finish note 4", "Finish note 3", "Finish note 2"])
        #expect(table.fullList(now: now).map(\.nextStep) == ["Finish note 1", "Finish note 0"])
    }

    @Test func staleRulesWrapUpWorkoutsAndPutThingsAway() throws {
        let (workout, bench) = try pushDay()
        try engine.perform(StartWorkout(workout: workout.id, time: start), by: .user)
        try engine.perform(LogSet(entry: bench.id, weight: 80, reps: 8), by: .user)
        let process = try #require(table.running())
        try engine.perform(SuspendProcess(process: process.id, time: start), by: .user)

        let notes = try (0 ..< 2).map { index in
            let note = try store.create(#require(classes[.note]), title: "Idea \(index)")
            let process = try engine.perform(StartProcess(subject: note.id, time: start), by: .user).output
            try engine.perform(SuspendProcess(process: process.id, time: start), by: .user)
            return note
        }

        // 6 hours later only the workout is wrapped up.
        #expect(table.tidy(now: start.addingTimeInterval(6 * 3600)) == ["Saved Push Day A, 1 of 2 exercises"])
        #expect(store.value("endedAt", of: workout) == .date(start))
        #expect(table.process(for: workout) == nil)

        // A week later the notes go to Later, with one quiet line.
        #expect(table.tidy(now: start.addingTimeInterval(7 * 86400)) == ["Put two things away. They're in Later."])
        let laterSubjects: Set<UUID> = Set(table.later().compactMap { $0.subject?.id })
        #expect(laterSubjects == Set(notes.map(\.id)))

        // Put away is restorable.
        let later = try #require(table.later().first)
        try engine.perform(ResumeProcess(process: later.id), by: .user)
        #expect(table.running()?.id == later.id)
    }

    @Test func idleRunningProcessIsSuspended() throws {
        let (workout, _) = try pushDay()
        try engine.perform(StartWorkout(workout: workout.id, time: start), by: .user)
        #expect(table.suspendIfIdle(now: start.addingTimeInterval(5 * 60), idleLimit: 12 * 60) == nil)
        #expect(table.suspendIfIdle(now: start.addingTimeInterval(13 * 60), idleLimit: 12 * 60) != nil)
        #expect(table.running() == nil)
        #expect(table.ledger(now: start.addingTimeInterval(14 * 60)).first?.lastTouchedAt == start)
    }

    @Test func trailShowsTheLastThreeActionsOnTheSubject() throws {
        let (workout, bench) = try pushDay()
        try engine.perform(StartWorkout(workout: workout.id, time: start), by: .user)
        for reps in [8.0, 7, 6] {
            try engine.perform(LogSet(entry: bench.id, weight: 80, reps: reps), by: .user)
        }
        let process = try #require(table.running())
        // Sets are children of the entry, not of the workout; the trail is about the workout object itself.
        #expect(table.trail(of: process).first?.action == "startWorkout")
    }

    @Test func processActionsUndo() throws {
        let (workout, _) = try pushDay()
        let started = try engine.perform(StartWorkout(workout: workout.id, time: start), by: .user)
        engine.undo(started.record)
        #expect(table.all().isEmpty)
        #expect(store.value("startedAt", of: workout) == nil)
    }
}
