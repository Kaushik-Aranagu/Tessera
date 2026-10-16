import Foundation
import GRDB
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// docs/qa/review-data-safety.md (D1–D4) and QA's process findings (P1–P4).
@MainActor
struct DataSafetyTests {
    func setUp() throws -> (ObjectStore, ActionEngine, ObjectRecord) {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let plan = try #require(store.object(id: StarterContent.planID))
        let pushA = try #require(store.linkedObjects("routines", of: plan).first)
        return (store, engine, pushA)
    }

    @Test func undoLastSetTakesTheNewestSetFromAnyPathInTheRunningWorkout() throws {
        let (store, engine, pushA) = try setUp()
        // An older, finished workout with a typed set.
        let old = try engine.perform(StartRoutine(routine: pushA.id), by: .user).output
        let oldEntry = try #require(old.orderedChildren.first)
        try engine.perform(LogSet(entry: oldEntry.id, weight: 60, reps: 8), by: .user)
        try engine.perform(FinishWorkout(workout: old.id), by: .user)
        #expect(engine.undoLatestSet() == nil) // nothing running: never reach into a finished workout

        let workout = try engine.perform(StartRoutine(routine: pushA.id), by: .user).output
        let entry = try #require(workout.orderedChildren.first)
        try engine.perform(LogSet(entry: entry.id, weight: 20, reps: 5), by: .user) // typed
        try engine.perform(LogNextSet(entry: entry.id), by: .user) // the hold
        try engine.perform(LogNextSet(entry: entry.id, source: .lockScreen), by: .intent) // Lock Screen Done
        #expect(entry.orderedChildren.count == 3)
        let undone = try #require(engine.undoLatestSet())
        #expect(undone.action == "logNextSet")
        #expect(entry.orderedChildren.count == 2)
        #expect(oldEntry.orderedChildren.count == 1)
        _ = store
    }

    /// Research's undo audit: Siri's "Undo Last Set" took back all three sets of "3x10 bench 80" and the workout
    /// Quick Capture started for them. It takes back one set, every time, and never the workout.
    @Test func undoLastSetNeverTakesMoreThanOneSetOrTheWorkout() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let bench = try #require(classes[.benchPress])
        let logged = try engine.perform(LogExercise(exercise: bench.id, weight: 80, reps: 10, sets: 3), by: .tess)
        let entry = try #require(logged.output.first?.parent)
        let workout = try #require(entry.parent)

        let first = try #require(engine.takeBackLatestSet())
        #expect(first.number == 3)
        #expect(entry.orderedChildren.count { !$0.isDeleted } == 2)
        #expect(!workout.isDeleted)
        #expect(!entry.isDeleted)

        let second = try #require(engine.takeBackLatestSet())
        #expect(second.number == 2)
        #expect(entry.orderedChildren.count { !$0.isDeleted } == 1)
        #expect(!workout.isDeleted)

        // A single logged set is still undone through its own record, so the op log stays exact.
        let typed = try engine.perform(LogSet(entry: entry.id, weight: 82.5, reps: 8), by: .user)
        let undone = try #require(engine.takeBackLatestSet())
        #expect(undone.record.id == typed.record.id)
        #expect(entry.orderedChildren.count { !$0.isDeleted } == 1)
    }

    /// QA C2: an empty routine can't be started from any caller (Siri's StartRoutineIntent included).
    @Test func anEmptyRoutineCannotBeStarted() throws {
        let (store, engine, _) = try setUp()
        let empty = try engine.perform(CreateRoutine(title: "Nothing yet"), by: .user).output
        #expect(throws: ActionError.self) { try engine.perform(StartRoutine(routine: empty.id), by: .intent) }
        let workouts = try store.objects(of: #require(engine.classes[.workout]))
        #expect(!workouts.contains { $0.title == "Nothing yet" })
    }

    @Test func onlyDamageMovesTheStoreAside() throws {
        #expect(TesseraSchema.isDamaged(DatabaseError(resultCode: .SQLITE_CORRUPT)))
        #expect(TesseraSchema.isDamaged(DatabaseError(resultCode: .SQLITE_NOTADB)))
        #expect(!TesseraSchema.isDamaged(DatabaseError(resultCode: .SQLITE_FULL)))
        #expect(!TesseraSchema.isDamaged(DatabaseError(resultCode: .SQLITE_IOERR)))
        #expect(!TesseraSchema.isDamaged(DatabaseError(resultCode: .SQLITE_CANTOPEN)))
        // QA G2: a decode bug in our own code is not damage; the store stays where it is.
        #expect(!TesseraSchema.isDamaged(DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "bug"))))
        #expect(!TesseraSchema.isDamaged(CocoaError(.fileReadUnknown)))

        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("tessera.sqlite")
        try Data("my history".utf8).write(to: url)

        // A passing error: nothing moves, and a note is kept.
        TesseraSchema.clearLaunchNote()
        let (_, passing) = TesseraSchema.open(url) { _ in throw DatabaseError(resultCode: .SQLITE_FULL) }
        #expect(passing == .inMemoryFallback)
        #expect(try String(contentsOf: url, encoding: .utf8) == "my history")
        #expect(TesseraSchema.launchNote != nil)

        // Damage, and the fresh store won't open either: the backup goes back where it was.
        let (_, twice) = TesseraSchema.open(url) { _ in throw DatabaseError(resultCode: .SQLITE_NOTADB) }
        #expect(twice == .inMemoryFallback)
        #expect(try String(contentsOf: url, encoding: .utf8) == "my history")

        // Real damage: moved aside, fresh store.
        let (_, recovered) = TesseraSchema.open(url) { try TesseraContext(url: $0) }
        guard case let .recoveredWithBackup(backup) = recovered else {
            Issue.record("expected a backup")
            return
        }
        #expect(FileManager.default.fileExists(atPath: backup.appendingPathComponent("tessera.sqlite").path))
        TesseraSchema.clearLaunchNote()
    }

    @Test func aMigrationCanStillRunAfterSeeding() throws {
        // The old store's export, as if the first migration had failed and launch then seeded the new store.
        let source = ObjectStore.open(inMemory: true)
        let sourceClasses = try source.prepareCatalog()
        let sourceEngine = ActionEngine(store: source, classes: sourceClasses)
        try sourceEngine.perform(CreateNote(body: "History from before"), by: .user)
        let data = try TesseraExport(context: source.context).encoded()

        let seeded = ObjectStore.open(inMemory: true)
        _ = try seeded.prepareCatalog()
        #expect(throws: (any Error).self) { try TesseraExport.decode(data).restore(into: seeded.context) }
        // Used since: a task added before the migration landed.
        try ActionEngine(store: seeded, classes: seeded.prepareCatalog())
            .perform(CreateTask(title: "Added since"), by: .user)
        try TesseraExport.decode(data).restore(into: seeded.context, merging: true)
        let fresh = ObjectStore(context: seeded.context)
        let classes = try fresh.prepareCatalog()
        #expect(NoteList(store: fresh, classes: classes).recent().map(\.title) == ["History from before"])
        #expect(TaskList(store: fresh, classes: classes).all().map(\.title) == ["Added since"])
    }

    @Test func exportsKeepFractionalSeconds() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let note = try engine.perform(CreateNote(body: "A"), by: .user).output
        note.createdAt = Date(timeIntervalSince1970: 1_792_000_000.123)
        let data = try TesseraExport(context: store.context).encoded()
        let restored = ObjectStore.open(inMemory: true)
        try TesseraExport.decode(data).restore(into: restored.context)
        let copy = try #require(restored.object(id: note.id))
        #expect(abs(copy.createdAt.timeIntervalSince1970 - 1_792_000_000.123) < 0.001)
        // Old whole-second exports still read.
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = ExportDates.decoding
        #expect(try decoder.decode([Date].self, from: Data(#"["2026-10-15T10:00:00Z"]"#.utf8)).count == 1)
    }

    @Test func onlyWorkoutsGoIdleAndSetAsideWorkoutsResume() throws {
        let (store, engine, pushA) = try setUp()
        let table = ProcessTable(engine: engine)
        try engine.perform(AddGroceries(lines: ["milk"]), by: .user)
        let start = Date.now
        try engine.perform(StartShop(time: start), by: .user)
        // P1: a 15-minute shop isn't suspended.
        #expect(table.suspendIfIdle(now: start.addingTimeInterval(900), idleLimit: 780) == nil)
        #expect(table.running()?.subject?.id == Groceries.listID)

        // P2/P3: a workout set aside picks back up when a set is logged into it.
        let workout = try engine.perform(StartRoutine(routine: pushA.id), by: .user).output
        let running = try #require(table.running())
        try engine.perform(SuspendProcess(process: running.id), by: .user)
        #expect(table.openWorkout()?.subject?.id == workout.id)
        let entry = try #require(workout.orderedChildren.first)
        try engine.perform(LogNextSet(entry: entry.id, source: .lockScreen), by: .intent)
        #expect(table.running()?.subject?.id == workout.id)
        _ = store
    }

    @Test func theModelOnlyGetsPersonActions() {
        // P4: the models get an explicit, closed list (TessTools); no system actions.
        let names = Set(TessTools.all.map(\.name))
        #expect(!names.contains("rollForwardTasks") && !names.contains("deleteObject"))
        #expect(names.isSuperset(of: ["logSet", "createTask"]))
    }
}

/// QA's #80 verification (B1, B4, the restored comma-sets row).
@MainActor
struct CommaSetTests {
    @Test func eachCommaPartIsItsOwnSet() async throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let grammar = TessGrammar(store: store, classes: classes)
        let context = TessContext(now: .now, calendar: .current)
        // B1
        guard case let .sets(parts)? = grammar.parse("bench 80 for 8, 82.5 for 6", context: context) else {
            Issue.record("bench 80 for 8, 82.5 for 6 should be two sets")
            return
        }
        let read = parts.compactMap { part -> [Double]? in
            if case let .lift(_, _, reps, weight, _) = part {
                [weight, reps]
            } else {
                nil
            }
        }
        #expect(read == [[80, 8], [82.5, 6]])

        // The restored row: with an entry in focus, "80x8, 80x8, 80x6" is three sets into it.
        let plan = try #require(store.object(id: StarterContent.planID))
        let pushA = try #require(store.linkedObjects("routines", of: plan).first)
        let workout = try engine.perform(StartRoutine(routine: pushA.id), by: .user).output
        let entry = try #require(workout.orderedChildren.first)
        let focused = TessContext(now: .now, calendar: .current, entry: entry.id)
        guard case let .sets(three)? = grammar.parse("80x8, 80x8, 80x6", context: focused) else {
            Issue.record("80x8, 80x8, 80x6 should be three sets")
            return
        }
        #expect(three.count == 3)

        let tess = TessCaptureEngine(engine: engine)
        let capture = await tess.capture("80x8, 80x8, 80x6", context: focused)
        #expect(capture.records.count == 3)
        #expect(entry.orderedChildren.count == 3)

        // B4: all or nothing. The second set goes to an entry that's gone, so the first is taken back.
        let other = try #require(workout.orderedChildren.dropFirst().first)
        try engine.perform(DeleteObject(object: other.id), by: .user)
        let before = entry.orderedChildren.count
        let failed = tess.performSets([
            .set(entry: entry, weight: 80, reps: 8, kind: .working, phrase: .full),
            .set(entry: other, weight: 80, reps: 8, kind: .working, phrase: .full),
        ], context: focused)
        #expect(failed.records.isEmpty)
        #expect(entry.orderedChildren.count == before)
    }
}

/// QA M1 on #89: a migration retry into a seeded store doesn't double the starter plan.
@MainActor
struct MergeRetryTests {
    @Test func retryIntoASeededStoreKeepsOneStarterPlan() throws {
        let source = ObjectStore.open(inMemory: true)
        let sourceClasses = try source.prepareCatalog()
        try ActionEngine(store: source, classes: sourceClasses).perform(CreateNote(body: "Old note"), by: .user)
        let data = try TesseraExport(context: source.context).encoded()

        let seeded = ObjectStore.open(inMemory: true)
        _ = try seeded.prepareCatalog()
        let plan = try #require(seeded.object(id: StarterContent.planID))
        let routines = seeded.linkedObjects("routines", of: plan).count
        let pushA = try #require(seeded.linkedObjects("routines", of: plan).first)
        let slots = pushA.orderedChildren.count

        try TesseraExport.decode(data).restore(into: seeded.context, merging: true)
        let store = ObjectStore(context: seeded.context)
        let classes = try store.prepareCatalog()
        let mergedPlan = try #require(store.object(id: StarterContent.planID))
        #expect(store.linkedObjects("routines", of: mergedPlan).count == routines)
        #expect(try #require(store.linkedObjects("routines", of: mergedPlan).first).orderedChildren.count == slots)
        #expect(NoteList(store: store, classes: classes).recent().map(\.title) == ["Old note"])
    }
}
