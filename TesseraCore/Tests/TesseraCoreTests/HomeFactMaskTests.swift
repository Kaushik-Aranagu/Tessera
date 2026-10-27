import Foundation
@testable import TesseraCore
import Testing

/// Home's fact builders never print a private routine's or workout's raw title (they make the hero text and its
/// "Opens ..." hint): "Private workout" for a private one, the title as it is for a plain one.
@MainActor
@Suite(.oldWalls)
struct HomeFactMaskTests {
    static let ended = HomeDonePackTests.ended

    @Test(arguments: [("Push Day Q", "Push Day Q"), ("Knee rehab day", "Private workout"),
                      ("Weigh in 82.4 kg", "Private workout")])
    func everyWorkoutFactReadsTheMaskedTitle(_ raw: String, _ shown: String) throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let facts = HomeFacts(engine: engine, calendar: HomeDonePackTests.calendar)
        let plan = try #require(store.object(id: StarterContent.planID))
        let routine = try #require(store.linkedObjects("routines", of: plan).first)
        try engine.perform(RenameObject(object: routine.id, title: raw), by: .user)

        // Planned.
        #expect(facts.fact(planned: routine).title == shown)
        // Running (a process) and scheduled.
        let start = Self.ended.addingTimeInterval(-3600)
        let workout = try engine.perform(StartRoutine(routine: routine.id, time: start), by: .user).output
        let process = try #require(ProcessTable(engine: engine).running())
        let running = try #require(facts.fact(process: process))
        #expect(running.title == shown)
        try store.set("scheduledFor", to: .date(start), on: workout)
        #expect(facts.fact(scheduled: workout).title == shown)
        // Done.
        let entry = try #require(workout.orderedChildren.first)
        try engine.perform(LogSet(entry: entry.id, weight: 60, reps: 5, time: start), by: .user)
        try engine.perform(FinishWorkout(workout: workout.id, time: Self.ended), by: .user)
        let summary = try #require(TrainingLedger(store: store, classes: classes)
            .finishedWorkouts(on: Self.ended, calendar: HomeDonePackTests.calendar).first)
        let done = facts.fact(done: summary)
        #expect(done.title == shown)
        // The words never reach a line, and a private one never builds a Claude pack.
        for fact in [facts.fact(planned: routine), running, facts.fact(scheduled: workout), done] {
            let text = HomeLines.line(for: fact).text.lowercased()
            #expect(shown == raw || !(text.contains("knee") || text.contains("82.4")), "\(text)")
        }
        if shown != raw {
            #expect(HomeDonePack.build(done, dayLabel: "Thursday night", calendar: HomeDonePackTests.calendar,
                                       store: store) == .failure(.walled))
        }
    }
}
