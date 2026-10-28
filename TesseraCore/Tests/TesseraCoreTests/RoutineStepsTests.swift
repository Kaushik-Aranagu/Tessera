import Foundation
@testable import TesseraCore
import Testing

/// The steps of a routine mode (sheets 323 and 329).
@MainActor
struct RoutineStepsTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine
    let steps: RoutineSteps

    init() throws {
        classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
        steps = RoutineSteps(store: store, classes: classes)
    }

    @Test func theSampleEveningReadsInOrderWithItsMoves() throws {
        let evening = try RoutineSample.evening(in: engine)
        let read = steps.steps(of: evening)
        #expect(read.map(\.title) == ["Tidy", "Stretch", "Read", "Journal", "Lights"])
        #expect(read.map(\.minutes) == [5, 6, 15, 5, 1])
        let stretch = read[1]
        #expect(stretch.moves.map(\.move) == ["Hips", "Shoulders", "Neck"])
        #expect(stretch.moves.map(\.seconds) == [120, 120, 120])
        #expect(stretch.moves[0].cue == "Knee over ankle, breathe out" && stretch.moves[0].breath == "out")
        #expect(stretch.seconds == 360 && read[0].seconds == 300)
        #expect(steps.totalMinutes(of: evening) == 32)
    }

    @Test func theDuskDarkensWithEachStepTended() {
        #expect(RoutineSteps.dusk(tended: 0, of: 5) == 0)
        #expect(RoutineSteps.dusk(tended: 2, of: 5) == 0.4)
        #expect(RoutineSteps.dusk(tended: 5, of: 5) == 1)
        #expect(RoutineSteps.dusk(tended: 9, of: 5) == 1 && RoutineSteps.dusk(tended: 1, of: 0) == 0)
    }

    @Test func aStepIsEditedKeptAndUndone() throws {
        let evening = try RoutineSample.evening(in: engine)
        let tidy = try #require(steps.steps(of: evening).first)
        let edit = try engine.perform(EditRoutineStep(step: tidy.id, minutes: 10, cue: ""), by: .user)
        #expect(edit.record.receipt == "Tidy changed")
        let after = try #require(steps.steps(of: evening).first)
        #expect(after.minutes == 10 && after.cue == nil && after.title == "Tidy")
        // A field left out stays.
        try engine.perform(EditRoutineStep(step: tidy.id, cue: "Just the table"), by: .user)
        #expect(steps.steps(of: evening).first?.minutes == 10 && steps.steps(of: evening).first?
            .cue == "Just the table")
        engine.undo(edit.record)
        #expect(steps.steps(of: evening).first?.minutes == 5)
    }

    @Test func badNumbersWordsAndParentsAreRefused() throws {
        let evening = try RoutineSample.evening(in: engine)
        let stretch = try #require(steps.steps(of: evening)[1].id)
        let tidy = try #require(steps.steps(of: evening).first)
        // A move takes seconds, a step takes minutes; the ranges hold.
        #expect(throws: ActionError.self) { try engine.perform(EditRoutineStep(step: tidy.id, seconds: 30), by: .user) }
        #expect(throws: ActionError.self) { try engine.perform(EditRoutineStep(step: tidy.id, minutes: 0), by: .user) }
        #expect(throws: ActionError.self) {
            try engine.perform(AddRoutineStep(parent: stretch, title: "Calves", seconds: 2), by: .user)
        }
        #expect(throws: ActionError.self) {
            try engine.perform(AddRoutineStep(parent: evening.id, title: "Lexapro dose", minutes: 5), by: .user)
        }
        #expect(throws: ActionError.self) {
            try engine.perform(
                AddRoutineStep(parent: evening.id, title: "Walk", minutes: 5,
                               cue: "sk-ant-api03-abcdefghijklmnopqrstuvwxyz0123456789"),
                by: .user
            )
        }
        #expect(throws: ActionError.self) {
            try engine.perform(
                AddRoutineStep(parent: evening.id, title: "Walk", minutes: 5, breath: "4-7-8"),
                by: .user
            )
        }
        // Not a routine or a step.
        let note = try engine.perform(CreateNote(body: "x"), by: .user).output
        #expect(throws: ActionError.self) {
            try engine.perform(AddRoutineStep(parent: note.id, title: "Walk"), by: .user)
        }
        #expect(steps.steps(of: evening).count == 5)
    }

    @Test func aPrivateRoutineShowsNoStepsAndItsStepsAreMasked() throws {
        let evening = try RoutineSample.evening(in: engine)
        evening.title = "Shoulder rehab and Lexapro"
        #expect(steps.steps(of: evening).isEmpty && steps.totalMinutes(of: evening) == 0)
        let step = try #require(evening.orderedChildren.first)
        #expect(ObjectPrivacy.shownLabel(of: step, in: store, classes: classes) != nil)
    }
}
