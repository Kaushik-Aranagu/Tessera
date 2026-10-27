import CoreGraphics
import Foundation
@testable import Tessera
import Testing

@Suite("Workout mode: changing lift wipes the board")
struct LiftWipeTests {
    let start = Date(timeIntervalSinceReferenceDate: 800_000_000)

    @Test("A swipe left sweeps right to left; a swipe right, left to right")
    func swipe() {
        #expect(EraserBand.Direction.forSwipe(dx: -80) == .rightToLeft)
        #expect(EraserBand.Direction.forSwipe(dx: 80) == .leftToRight)
    }

    @Test("A tap on a later lift wipes forward (the left-swipe direction), an earlier one back")
    func tap() {
        #expect(EraserBand.Direction.forTap(from: 0, to: 2) == .rightToLeft)
        #expect(EraserBand.Direction.forTap(from: 3, to: 1) == .leftToRight)
    }

    @Test("Right to left is the mirror of left to right, at 460 ms with the same ease")
    func mirror() {
        #expect(EraserBand.duration == 0.46)
        for time in stride(from: 0.0, through: 1.0, by: 0.25) {
            let forward = EraserBand.edge(time: time, width: 400, direction: .leftToRight)
            let back = EraserBand.edge(time: time, width: 400, direction: .rightToLeft)
            #expect(back.top == 400 - forward.top && back.bottom == 400 - forward.bottom)
        }
        let start = EraserBand.edge(time: 0, width: 400, direction: .rightToLeft)
        #expect(start.top == 400 && start.bottom == 400 + EraserBand.slant)
        let end = EraserBand.edge(time: 1, width: 400, direction: .rightToLeft)
        #expect(end.bottom == 0 && end.top == -EraserBand.slant)
    }

    @Test("Going left, all of the old board shows at the start and none at the end")
    func remaining() {
        let size = CGSize(width: 400, height: 300)
        let whole = EraserBand.remaining(time: 0, size: size, direction: .rightToLeft).boundingRect
        #expect(whole.minX <= 0 && whole.maxX >= 400)
        let none = EraserBand.remaining(time: 1, size: size, direction: .rightToLeft).boundingRect
        #expect(none.maxX <= 0)
    }

    func resting() -> WorkoutModeState {
        let sets = (0 ..< 2).map { _ in WorkoutModeState.PlannedSet(weight: 100, reps: 5) }
        var state = WorkoutModeState(title: "A", unit: .pounds, startedAt: start, lifts: [
            .init(id: "a", name: "Bench", restSeconds: 60, sets: sets),
            .init(id: "b", name: "Press", restSeconds: 60, sets: sets),
            .init(id: "c", name: "Row", restSeconds: 60, sets: sets),
        ])
        state.logSet(at: start)
        return state
    }

    @Test("Outside a rest, picking a lift turns to it at once")
    func plain() {
        var state = WorkoutModeState(title: "A", unit: .pounds, startedAt: start, lifts: [
            .init(id: "a", name: "Bench", restSeconds: 60, sets: [.init(weight: 1, reps: 1)]),
            .init(id: "b", name: "Press", restSeconds: 60, sets: [.init(weight: 1, reps: 1)]),
        ])
        state.select(lift: 1)
        #expect(state.focus == 1)
    }

    @Test("During a rest, picking a lift only queues it, and it takes effect when the rest ends")
    func queued() {
        var state = resting()
        state.select(lift: 2)
        #expect(state.focus == 0)
        #expect(state.queuedFocus == 2)
        // The rest shows what is queued as next.
        #expect(state.nextUp(after: 0)?.lift.name == "Row")
        state.endRest(at: start.addingTimeInterval(5))
        #expect(state.focus == 2)
        #expect(state.queuedFocus == nil)
    }

    @Test("A queued lift also takes effect when the rest runs out by itself")
    func queuedByTime() {
        var state = resting()
        state.select(lift: 1)
        state.tick(at: start.addingTimeInterval(61))
        #expect(state.focus == 1)
    }

    @Test("Without a queue the auto-turn is as before")
    func autoTurn() {
        var state = resting()
        state.endRest(at: start.addingTimeInterval(5))
        #expect(state.focus == 0)
    }

    @Test("Undo clears a queued lift")
    func undo() {
        var state = resting()
        state.select(lift: 2)
        state.undo(at: start.addingTimeInterval(3))
        #expect(state.queuedFocus == nil)
        #expect(state.focus == 0)
    }
}
