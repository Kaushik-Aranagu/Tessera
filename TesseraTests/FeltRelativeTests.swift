import Foundation
@testable import Tessera
import TesseraCore
import Testing

@Suite("Workout mode: Felt is relative to the start of the rest")
struct FeltRelativeTests {
    let start = Date(timeIntervalSinceReferenceDate: 800_000_000)

    func resting(unit: MassUnit = .pounds, weight: Double = 185) -> WorkoutModeState {
        let sets = (0 ..< 3).map { _ in WorkoutModeState.PlannedSet(weight: weight, reps: 5) }
        var state = WorkoutModeState(title: "Push A", unit: unit, startedAt: start, lifts: [
            .init(id: "b", name: "Bench press", restSeconds: 150, sets: sets),
        ])
        state.logSet(at: start)
        return state
    }

    @Test("Easy, then Hard, then Right gives 190, then 180, then 185 (lb)")
    func notCumulative() {
        var state = resting()
        state.apply(felt: .easy)
        #expect(state.current.sets.map(\.weight) == [185, 190, 190])
        state.apply(felt: .hard)
        #expect(state.current.sets.map(\.weight) == [185, 180, 180])
        state.apply(felt: .right)
        #expect(state.current.sets.map(\.weight) == [185, 185, 185])
    }

    @Test("In kilograms the step is 2.5 and it is not cumulative either")
    func kilograms() {
        var state = resting(unit: .kilograms, weight: 80)
        state.apply(felt: .easy)
        #expect(state.current.sets[1].weight == 82.5)
        state.apply(felt: .hard)
        #expect(state.current.sets[1].weight == 77.5)
        state.apply(felt: .right)
        #expect(state.current.sets[1].weight == 80)
    }

    @Test("The same answer twice does not stack")
    func twice() {
        var state = resting()
        state.apply(felt: .easy)
        state.apply(felt: .easy)
        #expect(state.current.sets[1].weight == 190)
    }

    @Test("The change is old to new while resting, and gone when the rest ends")
    func change() {
        var state = resting()
        #expect(state.restNextChange == nil)
        state.apply(felt: .easy)
        #expect(state.restNextChange?.old == 185 && state.restNextChange?.new == 190)
        state.apply(felt: .right)
        #expect(state.restNextChange == nil)
        state.apply(felt: .hard)
        state.endRest(at: start.addingTimeInterval(5))
        #expect(state.restNextChange == nil)
        #expect(state.restBaseline == nil)
    }

    @Test("A new rest starts from the weights as they are then")
    func newRest() {
        var state = resting()
        state.apply(felt: .easy)
        state.endRest(at: start.addingTimeInterval(5))
        state.logSet(at: start.addingTimeInterval(60))
        state.apply(felt: .hard)
        #expect(state.current.sets.map(\.weight) == [185, 190, 185])
    }

    @Test("Taking Felt back restores the weights from the start of the rest and clears the word")
    func undoFelt() {
        var state = resting()
        state.apply(felt: .easy)
        let taken = state.undoFelt()
        #expect(taken)
        #expect(state.current.sets.map(\.weight) == [185, 185, 185])
        #expect(state.current.sets[0].done?.felt == nil)
        #expect(state.restNextChange == nil)
        var idle = WorkoutModeState(title: "A", unit: .pounds, startedAt: start, lifts: [
            .init(id: "x", name: "X", restSeconds: 60, sets: [.init(weight: 1, reps: 1)]),
        ])
        let idleResult = idle.undoFelt()
        #expect(!idleResult)
    }

    @Test("Weights never go under zero")
    func floor() {
        var state = resting(weight: 2)
        state.apply(felt: .hard)
        #expect(state.current.sets[1].weight == 0)
    }
}
