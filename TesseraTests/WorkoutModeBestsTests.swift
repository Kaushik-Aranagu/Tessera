import Foundation
@testable import Tessera
import Testing
import TesseraCore

@Suite("Workout mode: new bests")
struct WorkoutModeBestsTests {
    let start = Date(timeIntervalSinceReferenceDate: 800_000_000)

    /// Bench with a ledger best estimate of 216 (a 185 × 5 set is 215.8, which shows as 216).
    func state(best: Double? = 216, weight: Double = 185, reps: Int = 5, unit: MassUnit = .pounds) -> WorkoutModeState {
        let sets = (0 ..< 3).map { _ in WorkoutModeState.PlannedSet(weight: weight, reps: reps) }
        var history = WorkoutModeState.LiftHistory()
        history.bestEstimate = best
        return WorkoutModeState(title: "Push A", unit: unit, startedAt: start, lifts: [
            .init(id: "b", name: "Bench press", restSeconds: 150, sets: sets, history: history),
        ])
    }

    @Test("An estimate above the best beats it; a tie does not; a rounded tie does not")
    func beats() {
        #expect(WorkoutModeState.beats(estimate: 220, best: 216))
        #expect(!WorkoutModeState.beats(estimate: 216, best: 216))
        #expect(!WorkoutModeState.beats(estimate: 215.8, best: 216))
        #expect(!WorkoutModeState.beats(estimate: 216.4, best: 216))
        #expect(WorkoutModeState.beats(estimate: 216.6, best: 216))
        #expect(!WorkoutModeState.beats(estimate: 300, best: nil))
    }

    @Test("A set whose estimate beats the ledger's best shows the line during the rest")
    func announces() {
        var state = state(best: 200)
        state.logSet(at: start)
        let best = state.restNewBest
        #expect(best?.number == "216")
        #expect(best?.line(unit: "lb") == "new best, est. 216 lb")
    }

    @Test("A tie with the best claims nothing")
    func tie() {
        var state = state(best: 216)
        state.logSet(at: start)
        #expect(state.restNewBest == nil)
    }

    @Test("A lift with no history has no best to beat")
    func noHistory() {
        var state = state(best: nil)
        state.logSet(at: start)
        #expect(state.restNewBest == nil)
    }

    @Test("The line clears when the rest ends")
    func clears() {
        var state = state(best: 200)
        state.logSet(at: start)
        #expect(state.restNewBest != nil)
        state.endRest(at: start.addingTimeInterval(5))
        #expect(state.restNewBest == nil)
    }

    @Test("One record is announced once: the next equal set does not claim it again")
    func once() {
        var state = state(best: 200)
        state.logSet(at: start)
        state.endRest(at: start.addingTimeInterval(5))
        state.logSet(at: start.addingTimeInterval(60))
        #expect(state.restNewBest == nil)
    }

    @Test("Kilograms estimate and show in kg")
    func kilograms() {
        var state = state(best: 100, weight: 100, reps: 5, unit: .kilograms)
        state.logSet(at: start)
        #expect(state.restNewBest?.line(unit: "kg") == "new best, est. 117 kg")
    }

    @Test("The Done board lists the session's real bests, or says steady work")
    func doneBoard() {
        var winner = state(best: 200)
        winner.logSet(at: start)
        winner.finish(at: start.addingTimeInterval(60))
        #expect(winner.doneBestLines == ["Bench press, est. 216 lb"])
        var steady = state(best: 300)
        steady.logSet(at: start)
        steady.finish(at: start.addingTimeInterval(60))
        #expect(steady.doneBestLines == ["No new bests, steady work"])
    }
}
