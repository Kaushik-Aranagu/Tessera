import Foundation
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

    /// Gym day: after every set hit the top of the range, the live dial opens at the raised weight, not last week's.
    @Test func aRaisedTargetOpensTheLiveDial() throws {
        let routine = try #require(model.todaysRoutine())
        model.startRoutine(routine)
        var session = try #require(model.session)
        let entry = try #require(session.currentEntry)
        let slot = try #require(model.store.linkedObjects("slot", of: entry).first)
        let top = try #require(model.store.number("repMax", of: slot))
        for _ in 0 ..< 3 {
            try model.engine.perform(LogSet(entry: entry.id, weight: 60, reps: top), by: .user)
        }
        model.endWorkout()

        model.startRoutine(routine)
        session = try #require(model.session)
        #expect(session.weight > 60)
        #expect(session.targetReason == "From the plan")
    }

    @Test func setsOpenPrefilledSoOneHoldLogsThem() throws {
        let (_, session) = try startedSession()
        #expect(session.phase() == .set)
        #expect(session.currentSetNumber == 1)
        // Core's prefill: set 1 opens at last time's set 1 (82.5 × 7, three days ago).
        #expect(session.weight == 82.5 && session.reps == 7)
        #expect(session.targetReason == "Same as last time, 82.5 × 7")
        #expect(session.isAtPrefill)
        // Bench is plate-loaded: detents and plates come from Core's weight dial.
        #expect(session.detents.first == 20)
        #expect(session.detents.contains(82.5))
        #expect(session.platesPerSide == [25, 5, 1.25])
        // The plus and minus beside the dial step one load (a pair of 1.25s).
        session.stepWeight(up: true)
        #expect(session.weight == 85)
        session.stepWeight(up: false)
        session.stepWeight(up: false)
        #expect(session.weight == 80)
    }

    @Test func oneHoldOnThePrefillLogsItThroughLogNextSet() throws {
        let (model, session) = try startedSession()
        session.logSet()
        #expect(model.engine.history(limit: 1).first?.action == "logNextSet")
        // Set 2 keeps today's weight with last time's set-2 reps (82.5 × 6).
        #expect(session.weight == 82.5 && session.reps == 6)
        session.skipRest()
        session.reps = 8
        session.logSet()
        #expect(model.engine.history(limit: 1).first?.action == "logSet")
    }

    @Test func aFirstEverSessionOpensAtTheSlotTarget() throws {
        // No demo: his plan, no history.
        let routine = try #require(model.todaysRoutine())
        model.startRoutine(routine)
        let session = try #require(model.session)
        #expect(session.currentExercise?.name == "Bench Press")
        #expect(session.reps == 5) // the bottom of 4 × 5–8
        #expect(session.weight == 20) // nothing to go on: the empty bar
        #expect(session.targetReason == "First time. Start light, 5 reps")
        session.logSet()
        let entry = try #require(session.currentEntry)
        #expect(session.setRows(of: entry).count == 1)
        #expect(session.weight == 20 && session.reps == 5) // set 2 carries today's numbers
    }

    @Test func loggingSeatsTheSetAndTurnsTheDialIntoRest() throws {
        let (_, session) = try startedSession()
        session.rpe = 8
        session.logSet()
        let seated = try #require(session.lastSeated)
        #expect(seated.number == 1)
        #expect(seated.records.contains(.e1RM)) // 82.5 × 7 at RPE 8 is a 9-rep effort: beats 82.5 × 7
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

    @Test func recordHintComesFromCoreAndCelebratesOncePerExercise() throws {
        let (_, session) = try startedSession()
        #expect(session.recordHint == nil) // 82.5 × 7 is level with the best
        session.rpe = 7 // 7 reps with 3 in the tank is a 10-rep effort
        #expect(session.recordHint?.text == "best e1RM")
        session.rpe = nil
        session.weight = 85
        let hint = try #require(session.recordHint)
        #expect(hint.text == "beats 7RM" && hint.previous == "was 82.5 × 7")
        #expect(WorkoutLines.subline(session, phase: .set).0 == "set 1: beats 7RM, was 82.5 × 7")

        session.logSet()
        #expect(session.lastSeated?.records.isEmpty == false) // the one celebration
        #expect(WorkoutLines.tess(session, phase: session.phase(), summary: nil).hasPrefix("New best: 85 × 7."))
        session.skipRest()
        session.weight = 87.5
        session.reps = 7
        session.logSet()
        #expect(session.lastSeated?.records.isEmpty == true) // a second record this session stays quiet
    }

    @Test func aLoggedSetCanBeChangedOnTheDialAndTheChangeUndone() throws {
        let (model, session) = try startedSession()
        session.logSet() // 82.5 × 7
        session.skipRest()
        let entry = try #require(session.currentEntry)
        let first = try #require(session.setRows(of: entry).first)
        let next = (session.weight, session.reps)

        session.beginEditing(setID: first.id)
        #expect(session.isEditing && session.weight == 82.5 && session.reps == 7)
        session.weight = 85
        session.reps = 6
        session.saveEdit()
        #expect(model.engine.history(limit: 1).first?.action == "editSet")
        #expect(session.setRows(of: entry).first?.weight == 85)
        #expect(session.setRows(of: entry).first?.reps == 6)
        #expect(!session.isEditing && session.weight == next.0 && session.reps == next.1) // the next set is back
        #expect(session.editNote == "Set 1 is 85 × 6 now.")

        // Undo takes the latest action first: the edit, then the set.
        #expect(session.canUndoLast)
        session.undoLast()
        #expect(session.setRows(of: entry).first?.weight == 82.5)
        session.undoLast()
        #expect(session.setRows(of: entry).isEmpty)
    }

    @Test func aLoggedSetCanBeRemovedInEditAndTheRemovalUndone() throws {
        let (_, session) = try startedSession()
        session.logSet()
        session.skipRest()
        let entry = try #require(session.currentEntry)
        let first = try #require(session.setRows(of: entry).first)

        session.beginEditing(setID: first.id)
        session.removeEditing()
        #expect(session.setRows(of: entry).isEmpty)
        #expect(!session.isEditing)
        #expect(session.editNote == "Set 1 removed.")

        #expect(session.canUndoLast)
        session.undoLast()
        #expect(session.setRows(of: entry).count == 1)
    }

    @Test func removingTheSetYouAreRestingAfterEndsTheRest() throws {
        let (model, session) = try startedSession()
        session.logSet()
        #expect(session.restEndsAt != nil)
        let entry = try #require(session.currentEntry)
        let first = try #require(session.setRows(of: entry).first)
        session.beginEditing(setID: first.id)
        session.removeEditing()
        #expect(session.restEndsAt == nil)
        #expect(WorkoutSession(workout: session.workout, model: model).restEndsAt == nil)
    }

    @Test func aSecondRecordHasToBeatTheFirst() throws {
        let (_, session) = try startedSession()
        session.logSet() // 82.5 × 7, level with the best
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

    // MARK: Round 9

    @Test func undoWorksUntilTheNextSetIsLogged() throws {
        let (_, session) = try startedSession()
        session.logSet()
        let first = try #require(session.undoable)
        session.skipRest()
        session.logSet()
        #expect(session.undoable?.setID != first.setID)
        #expect(first.record.state == .committed) // the earlier set is no longer the undoable one
        session.weight = 60
        session.undoLastSet()
        let entry = try #require(session.currentEntry)
        #expect(session.setRows(of: entry).count == 1)
        #expect(!session.canUndo)
        #expect(session.weight == 82.5) // the undone set's numbers come back to fix and re-log
        #expect(session.phase() == .set)
    }

    @Test func effortIsHiddenUntilWantedAndFeedsTheHonestE1RM() throws {
        let (_, session) = try startedSession()
        #expect(!session.isEffortShown)
        #expect(session.rpe == nil)
        let plain = try #require(session.previewE1RM)
        session.rpe = 8
        let honest = try #require(session.previewE1RM)
        #expect(honest > plain) // 8 @ RPE 8 is a 10-rep effort
        session.logSet()
        #expect(session.rpe == nil) // each set starts without effort
    }

    @Test func restTakesFifteenMoreOrSkips() throws {
        let (_, session) = try startedSession()
        session.logSet()
        let before = try #require(session.restEndsAt)
        session.extendRest(by: 15)
        #expect(session.restEndsAt == before.addingTimeInterval(15))
        #expect(session.restNote == "+15. Drag again for more.")
        session.skipRest()
        #expect(session.phase() == .set)
        #expect(session.restNote == "Skipped. Set 2 is up.")
    }

    @Test func aHeavyFirstSetOffersADropForTheRest() throws {
        let (_, session) = try startedSession()
        session.rpe = 10 // two above the default target of 8
        session.logSet()
        let check = try #require(session.topSetCheck)
        #expect(check.suggested == 77.5)
        #expect(check.fromSet == 2 && check.toSet == 4)
        session.acceptTopSetCheck()
        #expect(session.weight == 77.5)
        session.skipRest()
        session.logSet()
        #expect(session.topSetCheck == nil) // it leaves when the next set is logged
        session.skipRest()
        #expect(session.weight == 77.5) // the remaining sets stay re-preset
    }

    @Test func aFirstSetAtTargetIsNotChecked() throws {
        let (_, session) = try startedSession()
        session.rpe = 9
        session.logSet()
        #expect(session.topSetCheck == nil)
    }

    @Test func reorderingIsForTodayAndKeepsTheCurrentExercise() throws {
        let (_, session) = try startedSession()
        let bench = try #require(session.currentEntry)
        let last = try #require(session.entries.last)
        session.move(entryID: last.id, to: 0)
        #expect(session.entries.first?.id == last.id)
        #expect(session.currentEntry?.id == bench.id)
        #expect(session.currentIndex == 1)
        // The plan's own order is untouched.
        #expect(session.workout.orderedChildren.last?.id == last.id)
    }

    @Test func swapsRankTheFamilyFirstThenTheMovement() throws {
        let (_, session) = try startedSession()
        let options = session.swapOptions()
        let names = options.map(\.exercise.name)
        #expect(names.contains("Dumbbell Bench Press"))
        #expect(names.contains("Cable Fly")) // the best of the wider movement keeps one row
        #expect(!names.contains("Overhead Press"))
        #expect(options.count == 4)
        let groups = options.map(\.group)
        #expect(groups == [.family, .family, .family, .movement])
        let dumbbell = try #require(options.first { $0.exercise.name == "Dumbbell Bench Press" })
        #expect(dumbbell.isEstimate && dumbbell.isPerHand)
        #expect(dumbbell.load == 32) // 82.5 × 0.4 = 33, on his rack (2 kg steps) the nearest dumbbell
    }

    @Test func swappingBeforeAnySetRelinksTheEntryThroughTheEngine() throws {
        let (model, session) = try startedSession()
        let entry = try #require(session.currentEntry)
        let dumbbell = try #require(session.swapOptions().first { $0.exercise.name == "Dumbbell Bench Press" })
        session.swap(to: dumbbell)
        #expect(session.currentEntry?.id == entry.id)
        #expect(session.currentExercise?.name == "Dumbbell Bench Press")
        #expect(session.swappedFrom == "Bench Press")
        #expect(session.isEstimatedLoad)
        #expect(session.weight == 32)
        #expect(model.engine.history(limit: 1).first?.action == "swapExercise")
    }

    @Test func swappingMidExerciseKeepsTheLoggedSetsWithTheOldOne() throws {
        let (_, session) = try startedSession()
        session.logSet()
        session.skipRest()
        let bench = try #require(session.currentEntry)
        let fly = try #require(session.swapOptions().first { $0.exercise.name == "Cable Fly" })
        session.swap(to: fly)
        #expect(session.currentEntry?.id != bench.id)
        #expect(session.currentExercise?.name == "Cable Fly")
        #expect(session.targetSets(of: bench) == 1)
        let swapped = try #require(session.currentEntry)
        #expect(session.targetSets(of: swapped) == 3)
        #expect(session.entries.firstIndex { $0.id == swapped.id } == 1) // right after bench, today only
    }

    @Test func finishingSummarisesInOneLine() throws {
        let (_, session) = try startedSession()
        session.reps = 8 // 82.5 × 8 beats 82.5 × 7
        session.logSet()
        session.skipRest()
        session.finish()
        #expect(session.finishedAt != nil)
        #expect(!session.canUndo)
        let summary = session.summary
        #expect(summary.sets == 1 && summary.exercises == 1)
        #expect(summary.line == "1 exercise, 1 set. New best: 82.5 × 8.")
        #expect(session.workout.title == "Push Day A")
    }

    // MARK: QA W1 / W2

    @Test func aSetTypedToTessIsTheLatestActionForUndo() throws {
        let (_, session) = try startedSession()
        session.logSet()
        #expect(session.canUndo)
        let entry = try #require(session.currentEntry)
        let held = try #require(session.setRows(of: entry).last)
        session.seatCaptured(setIDs: [held.id])
        #expect(!session.canUndo) // the live Undo no longer reaches back to the earlier held set
        #expect(session.lastEdit == nil && session.editNote == nil)
    }

    @Test func undoingTheSetBeingEditedLeavesAKeyOnScreen() throws {
        let (_, session) = try startedSession()
        session.logSet()
        let entry = try #require(session.currentEntry)
        let row = try #require(session.setRows(of: entry).last)
        session.beginEditing(setID: row.id)
        #expect(session.isEditing)
        session.undoLastSet()
        #expect(!session.isEditing)
    }
}

/// QA D4: the rest countdown survives the app being killed and relaunched mid-rest.
@MainActor
struct WorkoutRestRelaunchTests {
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

    @Test func aRelaunchMidRestKeepsTheCountdown() throws {
        let (model, session) = try startedSession()
        session.logSet()
        session.extendRest(by: 15)
        let endsAt = try #require(session.restEndsAt)
        // The latest op is still the set (the rest is bookkeeping, not an action).
        #expect(model.engine.history(limit: 1).first?.action == "logNextSet")
        // Killed and relaunched: the session is rebuilt from the same workout.
        let relaunched = WorkoutSession(workout: session.workout, model: model)
        #expect(relaunched.restEndsAt == endsAt)
        #expect(relaunched.restTotal == session.restTotal)
        #expect(relaunched.phase() == .rest(endsAt: endsAt))
        // Skipped rest stays skipped across a relaunch.
        session.skipRest()
        #expect(WorkoutSession(workout: session.workout, model: model).restEndsAt == nil)
    }

    @Test func aRestSurvivesASwapAndARelaunch() throws {
        let (model, session) = try startedSession()
        session.logSet()
        let endsAt = try #require(session.restEndsAt)
        let option = try #require(session.swapOptions().first)
        session.swap(to: option)
        #expect(session.restEndsAt == endsAt)
        #expect(WorkoutSession(workout: session.workout, model: model).restEndsAt == endsAt)
    }

    @Test func aRestThatEndedWhileTheAppWasGoneIsOver() throws {
        let (model, session) = try startedSession()
        session.logSet()
        let endsAt = try #require(session.restEndsAt)
        let point = ProcessTable(engine: model.engine).process(for: session.workout)?.resumePoint
        #expect(WorkoutSession.savedRest(in: point, at: endsAt.addingTimeInterval(-1))?.endsAt == endsAt)
        // Relaunched after the rest ran out: no rest, and it doesn't restart.
        #expect(WorkoutSession.savedRest(in: point, at: endsAt.addingTimeInterval(1)) == nil)
        var stale = try #require(point)
        stale.extras[WorkoutSession.RestKey.endsAt] = String(Date.now.addingTimeInterval(-30)
            .timeIntervalSinceReferenceDate)
        let process = try #require(ProcessTable(engine: model.engine).process(for: session.workout))
        let text = try #require(String(bytes: JSONEncoder().encode(stale), encoding: .utf8))
        try model.store.set("resumePoint", to: .text(text), on: process.object)
        let relaunched = WorkoutSession(workout: session.workout, model: model)
        #expect(relaunched.restEndsAt == nil)
        #expect(relaunched.phase() == .set)
    }
}
