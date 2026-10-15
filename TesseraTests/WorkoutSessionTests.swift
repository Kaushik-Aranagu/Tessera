import Foundation
import SwiftData
@testable import Tessera
import TesseraCore
import Testing

@MainActor
struct WorkoutSessionTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    /// Held for the whole test: sessions keep an unowned reference to their model.
    let model: AppModel

    init() {
        model = AppModel(context: container.mainContext)
    }

    private func startedSession() throws -> (AppModel, WorkoutSession) {
        DemoData.prepare(model)
        let workout = try #require(model.tonightWorkout())
        model.startWorkout(workout)
        return try (model, #require(model.session))
    }

    @Test func setsOpenPrefilledSoOneHoldLogsThem() throws {
        let (_, session) = try startedSession()
        #expect(session.phase() == .set)
        #expect(session.currentSetNumber == 1)
        #expect(session.weight == 82.5 && session.reps == 8)
    }

    @Test func loggingSeatsTheSetAndTurnsTheDialIntoRest() throws {
        let (_, session) = try startedSession()
        session.rpe = 8
        session.logSet()
        let seated = try #require(session.lastSeated)
        #expect(seated.number == 1)
        #expect(seated.records.contains(.e1RM)) // 82.5 × 8 beats 82.5 × 7
        guard case .rest = session.phase() else {
            Issue.record("expected rest")
            return
        }
        let fraction = try #require(session.restFraction())
        #expect(fraction > 0.95 && fraction <= 1)
        session.extendRest(by: 15)
        #expect(session.restTotal == 195)
        session.skipRest()
        #expect(session.phase() == .set)
        #expect(session.currentSetNumber == 2)
        let entry = try #require(session.currentEntry)
        #expect(session.setRows(of: entry).first?.rpe == 8)
    }

    @Test func aSecondRecordHasToBeatTheFirst() throws {
        let (_, session) = try startedSession()
        session.logSet() // 82.5 × 8, a new best
        session.skipRest()
        #expect(!session.isPersonalRecord) // the same set again is not a new best
        session.reps = 9
        #expect(session.isPersonalRecord)
    }

    @Test func finishingAnExercisePagesToTheNextUnfinishedOne() throws {
        let (_, session) = try startedSession()
        let entry = try #require(session.currentEntry)
        for _ in 0 ..< session.targetSets(of: entry) {
            session.logSet()
            session.skipRest()
        }
        #expect(session.phase() == .exerciseDone)
        #expect(session.nextUnfinishedIndex == 1)
        session.select(entryAt: 1)
        #expect(session.currentExercise?.name == "Overhead Press")
        #expect(session.weight == 47.5)
    }

    @Test func undoRemovesTheLastSet() throws {
        let (_, session) = try startedSession()
        session.logSet()
        session.weight = 85
        session.undoLastSet()
        let entry = try #require(session.currentEntry)
        #expect(session.setRows(of: entry).isEmpty)
        #expect(session.restEndsAt == nil)
        #expect(session.weight == 82.5) // back to the target
    }

    @Test func ledgerRepsToBeatAndRecordKinds() throws {
        let (model, session) = try startedSession()
        let bench = try #require(model.classDef(.benchPress))
        let ledger = try #require(model.ledger)
        // Best is 82.5 × 7 → e1RM 101.75; at 82.5 kg that needs 8 reps.
        #expect(ledger.repsToBeatBestE1RM(weight: 82.5, for: bench, excludingWorkout: session.workout.id) == 8)
        #expect(ledger.recordsBeaten(weight: 85, reps: 7, for: bench).contains(.repMax(7)))
        #expect(ledger.recordsBeaten(weight: 60, reps: 5, for: bench).isEmpty)
    }
}
