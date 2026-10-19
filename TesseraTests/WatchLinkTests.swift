import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// docs/design/watch-set-logging-105.md: the wrist's snapshot and commands, masked at source, and the phone applying
/// them through the same session calls as its own Done.
@MainActor
struct WatchLinkTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel

    init() {
        model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
    }

    @Test func aSnapshotAndACommandSurviveTheWire() throws {
        let snapshot = WatchSnapshot(phase: .rest, exercise: "Bench Press", setNumber: 4, setCount: 5, weight: 82.5,
                                     reps: 8, unit: "kg", weightStep: 2.5,
                                     restEndsAt: Date(timeIntervalSinceReferenceDate: 1000), restTotal: 120,
                                     sets: ["82.5 x 8"], isPrivate: false, revision: 3)
        #expect(try WatchSnapshot.decode(#require(snapshot.encoded())) == snapshot)
        for command in [WatchCommand.logSet(weight: 80, reps: 6), .undo, .extendRest(seconds: 15), .skipRest, .hello] {
            #expect(try WatchCommand.decode(#require(command.encoded())) == command)
        }
        #expect(WatchSnapshot.decode(Data("junk".utf8)) == nil)
    }

    @Test func numbersAndNamesReadLikeThePhone() {
        #expect(WatchSnapshot.line(weight: 82.5, reps: 8) == "82.5 x 8")
        #expect(WatchSnapshot.line(weight: 80, reps: 5) == "80 x 5")
        #expect(WatchSnapshot.shortNames("Incline Dumbbell Press") == ["Dumbbell Press", "Incline"])
        #expect(WatchSnapshot.shortNames("Bench Press") == ["Bench"])
        #expect(WatchSnapshot.shortNames("Deadlift").isEmpty)
    }

    @Test func noWorkoutIsIdle() {
        #expect(WatchSnapshotMapper.snapshot(of: nil) == .idle)
    }

    @Test func aRunningWorkoutShowsTheDialledSetAndTheSetsSoFar() throws {
        DemoData.prepare(model)
        model.startWorkout(try #require(model.tonightWorkout()))
        let session = try #require(model.session)
        var snapshot = WatchSnapshotMapper.snapshot(of: session)
        #expect(snapshot.phase == .set)
        #expect(snapshot.setNumber == 1)
        #expect(snapshot.weight == session.weight)
        #expect(snapshot.reps == Int(session.reps))
        #expect(snapshot.sets.isEmpty)
        #expect(!snapshot.exercise.isEmpty)

        session.logSet()
        snapshot = WatchSnapshotMapper.snapshot(of: session)
        #expect(snapshot.phase == .rest)
        #expect(snapshot.restEndsAt != nil)
        #expect(snapshot.sets.count == 1)
        #expect(snapshot.setNumber == 2)
    }

    @Test func aPrivateWorkoutNeverNamesItsExercise() throws {
        let routine = try #require(model.todaysRoutine())
        try model.engine.perform(RenameObject(object: routine.id, title: "Knee rehab day"), by: .user)
        model.startRoutine(routine)
        let snapshot = try WatchSnapshotMapper.snapshot(of: #require(model.session))
        #expect(snapshot.isPrivate)
        #expect(snapshot.exercise == "Private workout")
        #expect(!(snapshot.encoded().flatMap { String(data: $0, encoding: .utf8) } ?? "").lowercased().contains("rehab"))
    }

    @Test func theWristLogsAsetThroughTheSameSessionPathAsThePhone() throws {
        DemoData.prepare(model)
        model.startWorkout(try #require(model.tonightWorkout()))
        let session = try #require(model.session)
        let entry = try #require(session.currentEntry)
        WatchBridge.shared.start(model: model)
        WatchBridge.shared.applyForTesting(.logSet(weight: 60, reps: 7))
        let row = try #require(session.setRows(of: entry).last)
        #expect(row.weight == 60)
        #expect(row.reps == 7)
        #expect(model.engine.history(limit: 1).first?.action == "logSet")
        // Undo from the wrist takes it out through the op log.
        WatchBridge.shared.applyForTesting(.undo)
        #expect(session.setRows(of: entry).isEmpty)
    }
}
