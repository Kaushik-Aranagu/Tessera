import SwiftUI
@testable import Tessera
import TesseraCore
import Testing

/// Sheet 73 A (docs/design/area-index.md): the index's live lines keep the context cap, and the rows sit where the
/// sheet puts them.
@MainActor
struct AreaIndexTests {
    @Test func aLiveLineKeepsSixWordsAndThirtyTwoCharacters() {
        #expect(AreaLines.capped("This week, 3 of 6 sessions") == "This week, 3 of 6 sessions")
        #expect(AreaLines.capped("one two three four five six seven") == "one two three four five six")
        let long = AreaLines.capped("Upper Body Hypertrophy Block A is on")
        #expect(long.count <= 32 && long.split(separator: " ").count <= 6, "\(long)")
        #expect(AreaLines.capped("Supercalifragilisticexpialidocious extra").count <= 32)
    }

    @Test func theRowsSitFromNinetySixOneHundredFourApart() {
        #expect(AreaIndexSheet.firstRow == 96 && AreaIndexSheet.rowPitch == 104 && AreaIndexSheet.height == 580)
    }

    @Test func eachAreaHasItsOwnColourAndTodayStaysInk() {
        #expect(AreaIndexSheet.areaColour(2) != AreaIndexSheet.areaColour(3))
        #expect(AreaIndexSheet.areaColour(1) == Theme.Colors.ink, "cobalt is Tess's voice only")
    }

    @Test func theQuietLinesReadPlainWhenNothingIsOn() {
        let container = TesseraSchema.makeContainer(inMemory: true)
        let model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        let now = Date(timeIntervalSince1970: 1_792_000_000)
        #expect(AreaLines.kitchen(model, now: now) == "Nothing cooking tonight")
        #expect(AreaLines.today(model, now: now).count <= 32)
    }

    @Test func aPrivateTaskAndAPrivateRoutineNeverPrintInTheIndex() throws {
        // QA and Design on #1055: the TODAY and TRAINING rows read through the masking accessors.
        let container = TesseraSchema.makeContainer(inMemory: true)
        let model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        let task = try model.engine.perform(CreateTask(title: "Pay Dr Lin rent 1200"), by: .user).output
        #expect(AreaLines.taskTitle(task.title, id: task.id, model: model) == "Private task")
        let plain = try model.engine.perform(CreateTask(title: "Call the bank"), by: .user).output
        #expect(AreaLines.taskTitle(plain.title, id: plain.id, model: model) == "Call the bank")
        // Seed a routine (the starter content may not): a private name must read "Private workout" in the row.
        DemoData.prepare(model)
        let routines = model.objects(of: .routine)
        #expect(!routines.isEmpty, "the test needs a routine to mean anything")
        for routine in routines {
            try model.engine.perform(RenameObject(object: routine.id, title: "Knee rehab day"), by: .user)
        }
        let now = Date(timeIntervalSince1970: 1_792_000_000)
        let line = AreaLines.training(model, now: now)
        #expect(!line.lowercased().contains("rehab"), "\(line)")
        #expect(ObjectPrivacy.routineTitle("Knee rehab day", in: model.store) == "Private workout")
    }
}
