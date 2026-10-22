import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// Busy and Similar on the live set (Design 128, 129).
@MainActor
struct SimilarBusyTests {
    private func started() throws -> (AppModel, WorkoutSession) {
        let container = TesseraSchema.makeContainer(inMemory: true)
        let model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        DemoData.prepare(model)
        let workout = try #require(model.tonightWorkout())
        model.startWorkout(workout)
        return try (model, #require(model.session))
    }

    @Test func busySendsTheExerciseToTheEndAndTheNextSlidesUp() throws {
        let (model, session) = try started()
        defer { model.endWorkout() }
        let first = try #require(session.currentExercise?.name)
        let count = session.entries.count
        #expect(session.hasOtherUnfinished)
        let receipt = try #require(session.markBusy())
        #expect(receipt.name == first)
        #expect(session.entries.count == count)
        #expect(session.entries.last.flatMap(session.exerciseClass(of:))?.name == first)
        #expect(session.currentExercise?.name != first, "the next one is on screen")
        #expect(session.busyExerciseIDs.count == 1)
        #expect(!session.currentIsBusy)
    }

    @Test func undoPutsTheOrderAndTheScreenBack() throws {
        let (model, session) = try started()
        defer { model.endWorkout() }
        let before = session.entries.map(\.id)
        let first = try #require(session.currentExercise?.name)
        let receipt = try #require(session.markBusy())
        session.undoBusy(receipt)
        #expect(session.entries.map(\.id) == before)
        #expect(session.currentExercise?.name == first)
        #expect(session.busyExerciseIDs.isEmpty)
    }

    @Test func aBusyOneComingRoundOffersSimilarNotAnotherBusy() throws {
        let (model, session) = try started()
        defer { model.endWorkout() }
        _ = try #require(session.markBusy())
        // Walk to the end of the order, where the busy one waits.
        session.select(entryAt: session.entries.count - 1)
        #expect(session.currentIsBusy)
        #expect(session.markBusy() == nil, "a busy exercise is not sent back again")
    }

    @Test func theSimilarGroupsAreNamedInWords() {
        #expect(SimilarSheet.title(.family) == "Same muscles, same pattern")
        #expect(SimilarSheet.title(.movement) == "Near")
    }

    @Test func theSwapHintNamesWhatTheActionDid() throws {
        let (model, session) = try started()
        defer { model.endWorkout() }
        let from = try #require(session.currentExercise?.name)
        let option = try #require(session.swapOptions().first)
        session.swap(to: option, forRoutine: true)
        #expect(session.swapHint == "Swapped in for \(from)")

        let (model2, session2) = try started()
        defer { model2.endWorkout() }
        let from2 = try #require(session2.currentExercise?.name)
        let option2 = try #require(session2.swapOptions().first)
        session2.swap(to: option2)
        #expect(session2.swapHint == "Just today, for \(from2)")
    }
}
