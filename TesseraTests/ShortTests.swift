import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// Short on the live set (Design 128): cut today to 45, 35 or 25 minutes.
@MainActor
struct ShortTests {
    private func started() throws -> (AppModel, WorkoutSession) {
        let container = TesseraSchema.makeContainer(inMemory: true)
        let model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        DemoData.prepare(model)
        let workout = try #require(model.tonightWorkout())
        model.startWorkout(workout)
        return try (model, #require(model.session))
    }

    private func items(_ sets: [Int], keeping first: Bool = true) -> [ShortPlan.Item] {
        sets.enumerated().map { index, count in
            ShortPlan.Item(id: UUID(), plannedSets: count, keeps: first && index == 0)
        }
    }

    @Test func theWordWalksAllThenFortyFiveThirtyFiveTwentyFiveThenAll() {
        #expect(ShortPlan.next(after: nil) == 45)
        #expect(ShortPlan.next(after: 45) == 35)
        #expect(ShortPlan.next(after: 35) == 25)
        #expect(ShortPlan.next(after: 25) == nil)
    }

    @Test func aBudgetDropsTheTailOfThePlan() {
        // 4, 3, 3, 3, 3 sets: 16 sets, about 40 minutes.
        let plan = items([4, 3, 3, 3, 3])
        #expect(ShortPlan.dropped(plan, minutes: nil).isEmpty)
        #expect(ShortPlan.dropped(plan, minutes: 45).isEmpty)
        #expect(ShortPlan.dropped(plan, minutes: 35) == [plan[4].id])
        #expect(ShortPlan.dropped(plan, minutes: 25) == [plan[3].id, plan[4].id])
    }

    @Test func theExerciseOnScreenAndStartedOnesNeverDrop() {
        let plan = items([4, 3, 3], keeping: true)
        #expect(ShortPlan.dropped(plan, minutes: 5) == [plan[1].id, plan[2].id], "the first is the one on screen")
        let started = [ShortPlan.Item(id: UUID(), plannedSets: 4, keeps: true),
                       ShortPlan.Item(id: UUID(), plannedSets: 4, keeps: true),
                       ShortPlan.Item(id: UUID(), plannedSets: 3, keeps: false)]
        #expect(ShortPlan.dropped(started, minutes: 25) == [started[2].id])
    }

    @Test func theReceiptSaysWhatHappened() {
        #expect(ShortPlan.receipt(minutes: 35, droppedCount: 1) == "Cut to 35 min.")
        #expect(ShortPlan.receipt(minutes: 45, droppedCount: 0) == "Cut to 45 min, nothing dropped.")
        #expect(ShortPlan.receipt(minutes: nil, droppedCount: 0) == "Back to the whole workout.")
    }

    @Test func shortCutsTheTailAndUndoPutsItBack() throws {
        let (model, session) = try started()
        defer { model.endWorkout() }
        let count = session.entries.count
        #expect(session.canShorten)
        let forty = try #require(session.stepShort())
        #expect(forty.text == "Cut to 45 min, nothing dropped.")
        let thirty = try #require(session.stepShort())
        #expect(thirty.text == "Cut to 35 min.")
        #expect(session.cutMinutes == 35)
        let last = try #require(session.entries.last)
        #expect(session.isCut(last))
        #expect(session.isFinished(last), "a cut exercise counts as done for today")
        #expect(session.entries.count == count, "nothing vanishes: the row fades in place")
        session.undoShort(thirty)
        #expect(session.cutMinutes == 45)
        #expect(!session.isCut(last))
    }

    @Test func aSetOnACutExerciseBringsItBack() throws {
        let (model, session) = try started()
        defer { model.endWorkout() }
        _ = session.stepShort()
        _ = session.stepShort()
        _ = session.stepShort()
        let cutIDs = session.cut
        #expect(cutIDs.count == 2)
        session.select(entryAt: session.entries.count - 1)
        let entry = try #require(session.currentEntry)
        #expect(session.isCut(entry))
        session.logSet()
        #expect(!session.isCut(entry))
    }

    @Test func finishingWithACutMarksTheDroppedExercisesSkipped() throws {
        let (model, session) = try started()
        defer { model.endWorkout() }
        _ = session.stepShort()
        _ = session.stepShort()
        let last = try #require(session.entries.last)
        session.logSet()
        session.finish()
        guard case .bool(true)? = model.store.value("skipped", of: last) else {
            Issue.record("the cut exercise should be marked skipped when the workout ends")
            return
        }
    }
}
