import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

@MainActor
struct CountsAndCaptureTests {
    @Test func monthCountsAndLogPrefixedCapture() async throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let ledger = TrainingLedger(store: store, classes: classes)
        let plan = try #require(store.object(id: StarterContent.planID))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let october = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 14, hour: 12)))

        // "log bench 80x8" from the Bar: grammar only, a ghost row.
        let capture = await TessCaptureEngine(engine: engine).capture(
            "log bench 80x8",
            context: TessContext(now: october)
        )
        #expect(capture.line == "Bench 8 reps at 80. Added to today.")
        let workoutClass = try #require(classes[.workout])
        let workout = try #require(store.objects(of: workoutClass).first)
        let record = try #require(capture.records.first)
        try engine.commit(record)
        try engine.perform(FinishWorkout(workout: workout.id, time: october), by: .user)

        let counts = ledger.monthCounts(containing: october, plan: plan, calendar: calendar)
        #expect(counts.done == 1)
        #expect(counts.planned == 27) // 6 routines a week over 31 days
        try store.set("sessionsPerWeek", to: .number(4), on: plan)
        #expect(ledger.monthCounts(containing: october, plan: plan, calendar: calendar).planned == 18)
    }
}
