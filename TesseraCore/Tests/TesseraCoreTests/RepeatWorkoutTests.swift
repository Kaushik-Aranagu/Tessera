import Foundation
@testable import TesseraCore
import Testing

/// "Repeat this" on a finished workout (finished-workout page, sheet 150).
@MainActor
struct RepeatWorkoutTests {
    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine
    let now = Date(timeIntervalSince1970: 1_792_670_400)

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    func finished(title: String = "Push Day A", planned: Bool = true) throws -> ObjectRecord {
        let workout = try store.create(#require(engine.classes[.workout]), title: title)
        try store.set("endedAt", to: .date(now.addingTimeInterval(-86400)), on: workout)
        let ledger = TrainingLedger(store: store, classes: engine.classes)
        for (key, sets, weight) in [(SystemCatalog.Key.benchPress, 3.0, 80.0), (.barbellLift, 2.0, 60.0)] {
            let entry = try store.create(#require(engine.classes[.exerciseEntry]), parent: workout)
            try store.setClassLink("exercise", on: entry, to: #require(engine.classes[key]))
            if planned {
                try store.set("targetSets", to: .number(sets), on: entry)
                try store.set("targetReps", to: .number(8), on: entry)
                try store.set("targetWeight", to: .mass(weight), on: entry)
            }
            for _ in 0 ..< Int(sets) {
                try ledger.logSet(weight: weight + 2.5, reps: 6, in: entry)
            }
        }
        return workout
    }

    @Test func itStartsTodaysWorkoutWithTheSameEntriesAndTargetsAndNoSets() throws {
        let source = try finished()
        let copy = try engine.repeatWorkout(id: source.id, at: now)
        #expect(copy.id != source.id && copy.title == "Push Day A")
        let entries = copy.orderedChildren
        #expect(entries.count == 2)
        let ledger = TrainingLedger(store: store, classes: engine.classes)
        #expect(entries.map { store.number("targetSets", of: $0) } == [3, 2])
        #expect(entries.map { store.number("targetWeight", of: $0) } == [80, 60])
        #expect(entries
            .allSatisfy {
                store.number("targetReps", of: $0) == 8 && $0.orderedChildren.compactMap(ledger.loggedSet).isEmpty
            })
        #expect(store.value("startedAt", of: copy)?.dateValue == now && store.value("endedAt", of: copy) == nil)
        #expect(ProcessTable(engine: engine).running()?.subject?.id == copy.id)
        // The source is untouched.
        #expect(source.orderedChildren.allSatisfy { !$0.orderedChildren.isEmpty })
    }

    @Test func anEntryWithNoPlanTakesItsTargetsFromWhatWasDone() throws {
        let source = try finished(planned: false)
        let copy = try engine.repeatWorkout(id: source.id, at: now)
        let entries = copy.orderedChildren
        #expect(entries.map { store.number("targetSets", of: $0) } == [3, 2])
        #expect(entries.map { store.number("targetWeight", of: $0) } == [82.5, 62.5])
        #expect(entries.map { store.number("targetReps", of: $0) } == [6, 6])
    }

    @Test func theRoutineLinkAndTheSlotCarryOver() throws {
        let routine = try engine.perform(CreateRoutine(title: "Push A"), by: .user).output
        let source = try finished(title: "Push A")
        try store.setLinks("routine", on: source, to: [routine])
        let copy = try engine.repeatWorkout(id: source.id, at: now)
        #expect(store.linkedObjects("routine", of: copy).map(\.id) == [routine.id])
    }

    @Test func aPrivateWorkoutStaysPrivateWhenRepeated() throws {
        let titled = try finished(title: "Knee rehab day")
        let copy = try engine.repeatWorkout(id: titled.id, at: now)
        #expect(ObjectPrivacy.label(of: copy, in: store, classes: engine.classes) == "Private workout")
        // Private by its routine: the copy links the same routine, so it is private the same way.
        let secret = try engine.perform(CreateRoutine(title: "Knee rehab day"), by: .user).output
        let viaRoutine = try finished(title: "Session")
        try store.setLinks("routine", on: viaRoutine, to: [secret])
        let again = try engine.repeatWorkout(id: viaRoutine.id, at: now)
        #expect(ObjectPrivacy.label(of: again, in: store, classes: engine.classes) == "Private workout")
        // The receipt and the summary say nothing of the words.
        let made = try engine.perform(RepeatWorkout(workout: titled.id, time: now), by: .user)
        #expect(!made.record.summary.contains("Knee") && !(made.record.receipt ?? "").contains("Knee"))
    }

    @Test func anUnfinishedOrEmptyWorkoutIsRefusedAndWritesNothing() throws {
        let open = try store.create(#require(engine.classes[.workout]), title: "Open")
        #expect(throws: (any Error).self) { try engine.repeatWorkout(id: open.id) }
        let empty = try store.create(#require(engine.classes[.workout]), title: "Empty")
        try store.set("endedAt", to: .date(now), on: empty)
        #expect(throws: (any Error).self) { try engine.repeatWorkout(id: empty.id) }
        let workouts = try store.objects(of: #require(engine.classes[.workout])).filter { !$0.isDeleted }
        #expect(workouts.count == 2)
    }

    @Test func undoTakesTheNewWorkoutBack() throws {
        let source = try finished()
        let made = try engine.perform(RepeatWorkout(workout: source.id, time: now), by: .user)
        engine.undo(made.record)
        let workouts = try store.objects(of: #require(engine.classes[.workout])).filter { !$0.isDeleted }
        #expect(workouts.map(\.id) == [source.id] && ProcessTable(engine: engine).running() == nil)
    }
}
