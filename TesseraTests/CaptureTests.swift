import Foundation
@testable import Tessera
import TesseraCore
import Testing

@MainActor
struct CaptureTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel

    init() {
        model = AppModel(context: container.mainContext)
        DemoData.prepare(model)
    }

    private func taskTitles() -> [String] {
        model.objects(of: .task).map(\.title)
    }

    @Test func aCaptureIsAGhostUntilItDries() throws {
        let id = try #require(model.capture(title: "Call mum", startsAt: AppClock.now.addingTimeInterval(3600)))
        #expect(model.isGhost(id))
        #expect(taskTitles().contains("Call mum"))
        model.commitCapture()
        #expect(!model.isGhost(id))
        #expect(model.lastCapture != nil)
        #expect(taskTitles().contains("Call mum"))
    }

    @Test func droppingAGhostWritesNothing() throws {
        _ = try #require(model.capture(title: "Call mum", startsAt: AppClock.now.addingTimeInterval(3600)))
        model.discardCapture()
        #expect(!taskTitles().contains("Call mum"))
    }

    @Test func undoReversesACommittedCapture() throws {
        _ = try #require(model.capture(title: "Call mum", startsAt: AppClock.now.addingTimeInterval(3600)))
        model.commitCapture()
        model.undoLastCapture()
        #expect(!taskTitles().contains("Call mum"))
    }

    @Test func aSetTypedInTheBarSeatsInTheLiveWorkout() async throws {
        let workout = try #require(model.tonightWorkout())
        model.startWorkout(workout)
        let session = try #require(model.session)
        let entry = try #require(session.currentEntry)
        let line = await model.ask("log bench 80x8")
        #expect(!line.isEmpty)
        let record = try #require(model.pendingCapture)
        // In live mode the grammar logs into the current exercise (LogSet); on Home it's LogExercise.
        #expect(["logSet", "logExercise"].contains(record.action))
        // A ghost until it dries: the set is there, drawn wet.
        let ghost = try #require(session.setRows(of: entry).last)
        #expect(ghost.weight == 80 && ghost.reps == 8)
        #expect(model.isGhost(ghost.id))
        model.commitCapture()
        #expect(!model.isGhost(ghost.id))
        #expect(session.lastSeated?.setID == ghost.id) // it seats like a held set: stroke, rest, undo
        #expect(session.restEndsAt != nil)
    }

    @Test func aSetTypedOnHomeStartsAWorkoutThatShowsAsRunning() async throws {
        let other = TesseraSchema.makeContainer(inMemory: true)
        let fresh = AppModel(context: other.mainContext)
        _ = await fresh.ask("log bench 80x8")
        fresh.commitCapture()
        let session = try #require(fresh.session)
        #expect(session.entries.count == 1)
        #expect(!fresh.isWorkoutPresented)
    }

    @Test func undoAfterAMultiSetCaptureTakesBackEverySet() async throws {
        let workout = try #require(model.tonightWorkout())
        model.startWorkout(workout)
        let session = try #require(model.session)
        let entry = try #require(session.currentEntry)
        let before = session.setRows(of: entry).count
        _ = await model.ask("bench 80x8, 82.5x6")
        model.commitCapture()
        #expect(session.setRows(of: entry).count == before + 2)
        model.undoLastCapture()
        #expect(session.setRows(of: entry).count == before)
    }
}
