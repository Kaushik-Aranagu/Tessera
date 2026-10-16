import Foundation
@testable import TesseraCore
import Testing

@MainActor
struct ActionEngineTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let store: ObjectStore
    let engine: ActionEngine

    init() throws {
        store = ObjectStore(context: container.mainContext)
        classes = try SystemCatalog.seed(in: container.mainContext)
        engine = ActionEngine(store: store, classes: classes)
    }

    func benchEntry() throws -> (workout: ObjectRecord, entry: ObjectRecord) {
        let workout = try store.create(#require(classes[.workout]), title: "Push Day A")
        let entry = try engine.perform(
            AddExercise(workout: workout.id, exercise: #require(classes[.benchPress]).id, targetSets: 3),
            by: .user
        ).output
        return (workout, entry)
    }

    // MARK: Logging and undo

    @Test func logSetIsLoggedAndUndoable() throws {
        let (_, entry) = try benchEntry()
        let result = try engine.perform(LogSet(entry: entry.id, weight: 82.5, reps: 8, rpe: 8), by: .user)
        let set = result.output

        #expect(result.record.summary == "Logged bench press 82.5 × 8")
        #expect(result.record.actor == .user)
        #expect(result.record.objectIDs == [set.id])
        #expect(store.number("e1rm", of: set).map { ($0 * 100).rounded() / 100 } == 110) // 8 @ RPE 8 is a 10-rep effort
        #expect(entry.orderedChildren.map(\.id) == [set.id])

        #expect(engine.undo(result.record) == .applied)
        #expect(entry.orderedChildren.isEmpty)
        #expect(result.record.state == .undone)
        #expect(engine.undo(result.record) == .nothingToDo)

        #expect(engine.redo(result.record) == .applied)
        #expect(entry.orderedChildren.map(\.id) == [set.id])
        #expect(store.value("weight", of: set) == .mass(82.5))
    }

    @Test func editUndoRestoresTheOldValues() throws {
        let (_, entry) = try benchEntry()
        let set = try engine.perform(LogSet(entry: entry.id, weight: 80, reps: 8), by: .user).output
        let edit = try engine.perform(EditSet(set: set.id, weight: 85, reps: 5), by: .user)
        #expect(edit.record.summary == "Changed the set to 85 × 5")
        engine.undo(edit.record)
        #expect(store.value("weight", of: set) == .mass(80))
        #expect(store.value("reps", of: set) == .number(8))
    }

    @Test func editCanClearTheRPEAndUndoPutsItBack() throws {
        let (_, entry) = try benchEntry()
        let set = try engine.perform(LogSet(entry: entry.id, weight: 80, reps: 8, rpe: 8), by: .user).output
        let clear = try engine.perform(EditSet(set: set.id, clearRPE: true), by: .user)
        #expect(store.value("rpe", of: set) == nil)
        #expect(store.value("weight", of: set) == .mass(80))
        engine.undo(clear.record)
        #expect(store.value("rpe", of: set) == .number(8))
        #expect(throws: ActionError.self) {
            try engine.perform(EditSet(set: set.id, rpe: 7, clearRPE: true), by: .user)
        }
    }

    @Test func undoNeverOverwritesALaterChange() throws {
        let (_, entry) = try benchEntry()
        let set = try engine.perform(LogSet(entry: entry.id, weight: 80, reps: 8), by: .user).output
        let first = try engine.perform(EditSet(set: set.id, weight: 85), by: .tess)
        _ = try engine.perform(EditSet(set: set.id, weight: 90), by: .user)

        // Undoing Tess's edit can't put 80 back: the person has since set 90.
        let outcome = engine.undo(first.record)
        guard case let .partial(skipped) = outcome else { Issue.record("expected a conflict"); return }
        #expect(skipped.count == 1)
        #expect(store.value("weight", of: set) == .mass(90))
    }

    @Test func undoLatestByActorUndoesWhatTessDid() throws {
        let (_, entry) = try benchEntry()
        let mine = try engine.perform(LogSet(entry: entry.id, weight: 80, reps: 8), by: .user)
        let tess = try engine.perform(LogSet(entry: entry.id, weight: 80, reps: 7), by: .tess)
        _ = try engine.perform(CreateTask(title: "Stretch"), by: .user)

        #expect(engine.undoLatest(by: .tess)?.id == tess.record.id)
        #expect(entry.orderedChildren.map(\.id) == [mine.output.id])
        #expect(engine.history(of: tess.output.id).map(\.id) == [tess.record.id])
    }

    // MARK: Pending previews

    @Test func ghostCapturesCommitOrDiscard() throws {
        let preview = try engine.perform(CreateTask(title: "Dentist", minutes: 30), by: .tess, pending: true)
        let task = preview.output
        #expect(engine.isPending(task.id))
        #expect(!task.isDeleted)

        // Dismissed: the task disappears.
        try engine.discard(preview.record)
        #expect(task.isDeleted)
        #expect(!engine.isPending(task.id))
        #expect(throws: ActionError.notPending(preview.record.id)) { try engine.discard(preview.record) }

        // Left alone: it commits after the grace period.
        let second = try engine.perform(CreateTask(title: "Groceries"), by: .tess, pending: true)
        engine.commitExpired(now: second.record.createdAt.addingTimeInterval(1))
        #expect(second.record.state == .pending)
        engine.commitExpired(now: second.record.createdAt.addingTimeInterval(2))
        #expect(second.record.state == .committed)
        #expect(engine.pendingRecords().isEmpty)
    }

    // MARK: Validation and rollback

    @Test func invalidActionsWriteNothing() throws {
        let (_, entry) = try benchEntry()
        let before = engine.history().count
        #expect(throws: ActionError.self) { try engine.perform(LogSet(entry: entry.id, weight: 80, reps: 0), by: .tess)
        }
        #expect(throws: ActionError.self) {
            try engine.perform(LogSet(entry: entry.id, weight: 80, reps: 2.5), by: .tess)
        }
        #expect(throws: ActionError.wrongClass(entry.id, expected: "task")) {
            try engine.perform(SetTaskDone(task: entry.id), by: .tess)
        }
        let bench = try #require(classes[.benchPress])
        let muscle = try #require(classes[.muscle])
        #expect(throws: ActionError.self) {
            try engine.perform(AddExercise(workout: UUID(), exercise: bench.id), by: .tess)
        }
        #expect(throws: ActionError.wrongClass(muscle.id, expected: "exercise")) {
            try engine.perform(LogExercise(exercise: muscle.id, weight: 80, reps: 5), by: .tess)
        }
        #expect(engine.history().count == before)
        #expect(entry.orderedChildren.isEmpty)
    }

    @Test func aFailureHalfwayRollsBackWhatWasWritten() throws {
        struct Halfway: EngineAction {
            static let descriptor = ActionDescriptor(name: "halfway", summary: "Test", parameters: [])
            let taskClass: UUID
            func apply(_ transaction: inout Transaction) throws {
                let task = try transaction.create(transaction.classDef(.task), title: "Half")
                try transaction.set("isDone", to: .bool(true), on: task)
                throw ActionError.invalidArguments(action: "halfway", reason: "boom")
            }

            func summary(in _: ObjectStore) -> String {
                ""
            }
        }
        let taskClass = try #require(classes[.task])
        #expect(throws: ActionError.self) { try engine.perform(Halfway(taskClass: taskClass.id), by: .user) }
        #expect(store.objects(of: taskClass).isEmpty)
        #expect(engine.history().isEmpty)
    }

    // MARK: Quick Capture and tool calls

    @Test func logExerciseStartsAWorkoutAndReusesTheEntry() throws {
        let bench = try #require(classes[.benchPress])
        let first = try engine.perform(LogExercise(exercise: bench.id, weight: 80, reps: 10, sets: 3), by: .tess)
        #expect(first.output.count == 3)
        #expect(first.record.summary == "Logged bench press 3×10 at 80 kg")
        let second = try engine.perform(LogExercise(exercise: bench.id, weight: 82.5, reps: 8), by: .tess)

        let workoutClass = try #require(classes[.workout])
        let workouts = store.objects(of: workoutClass)
        #expect(workouts.count == 1)
        #expect(workouts[0].orderedChildren.count == 1)
        #expect(workouts[0].orderedChildren[0].orderedChildren.count == 4)
        #expect(second.output[0].parent?.id == first.output[0].parent?.id)

        // One undo removes the whole capture, including the workout it started.
        engine.undo(first.record)
        engine.undo(second.record)
        #expect(store.objects(of: workoutClass).isEmpty)
    }

    @Test func toolCallsDecodeValidateAndRun() throws {
        let (_, entry) = try benchEntry()
        let json = #"{"entry":"\#(entry.id.uuidString)","weight":80,"reps":8}"#
        let record = try engine.perform(named: "logSet", arguments: Data(json.utf8), by: .tess, pending: true)
        #expect(record.state == .pending)
        #expect(entry.orderedChildren.count == 1)

        let task = #"{"title":"Dentist","startsAt":"2026-10-16T15:00:00Z","minutes":45}"#
        try engine.perform(named: "createTask", arguments: Data(task.utf8), by: .tess)
        let taskClass = try #require(classes[.task])
        let created = try #require(store.objects(of: taskClass).first)
        #expect(store.value("length", of: created) == .duration(2700))
        #expect(store.value("startsAt", of: created)?.dateValue == ISO8601DateFormatter()
            .date(from: "2026-10-16T15:00:00Z"))

        #expect(throws: ActionError.unknownAction("launchRocket")) {
            try engine.perform(named: "launchRocket", arguments: Data("{}".utf8), by: .tess)
        }
        #expect(throws: ActionError.invalidArguments(action: "logSet", reason: "missing weight")) {
            try engine.perform(named: "logSet", arguments: Data(#"{"entry":"\#(entry.id)","reps":8}"#.utf8), by: .tess)
        }
    }

    @Test func registryDescribesEveryAction() throws {
        let names = ActionRegistry.descriptors.map(\.name)
        #expect(Set(names).count == names.count)
        #expect(ActionRegistry.catalog.contains("logSet(entry: object, weight: number, reps: integer, rpe?: number"))
        let tools = try JSONSerialization.jsonObject(with: ActionRegistry.toolDefinitionsJSON()) as? [[String: Any]]
        let logSet = try #require(tools?.first { $0["name"] as? String == "logSet" })
        let schema = try #require(logSet["input_schema"] as? [String: Any])
        #expect(schema["type"] as? String == "object")
        #expect(Set(schema["required"] as? [String] ?? []) == ["entry", "weight", "reps"])
        #expect(ActionRegistry.descriptors.filter(\.isDestructive).map(\.name).sorted() == [
            "deleteObject",
            "removeSlot",
        ])
    }

    @Test func deleteIsRecoverable() throws {
        let (workout, entry) = try benchEntry()
        _ = try engine.perform(LogSet(entry: entry.id, weight: 80, reps: 8), by: .user)
        let delete = try engine.perform(DeleteObject(object: workout.id), by: .user)
        #expect(workout.isDeleted && entry.isDeleted)
        engine.undo(delete.record)
        #expect(!workout.isDeleted && !entry.isDeleted)
        #expect(entry.orderedChildren.count == 1)
    }
}

@MainActor
struct ActionObserverTests {
    @Test func observersHearCommittedActionsOnly() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        var heard: [String] = []
        engine.observe { heard.append($0.action) }
        try engine.perform(CreateTask(title: "Now"), by: .user)
        let preview = try engine.perform(CreateTask(title: "Ghost"), by: .tess, pending: true)
        #expect(heard == ["createTask"])
        try engine.commit(preview.record)
        #expect(heard == ["createTask", "createTask"])
    }
}
