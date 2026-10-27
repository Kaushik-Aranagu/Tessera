import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// The finished workout's page words (Design 150): one sentence, one numbers line, the switch ships Off.
struct FinishedWorkoutTests {
    @Test func theSentenceNamesDateLengthSetsAndTheBest() {
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 21))
        #expect(FinishedWorkoutWords.sentence(date: date, minutes: 52, sets: 18, best: "Bench")
            == "Oct 21, 52 min, 18 sets. Bench was your best")
        #expect(FinishedWorkoutWords
            .sentence(date: date, minutes: 95, sets: 1, best: nil) == "Oct 21, 1 hr 35 min, 1 set")
    }

    @Test func theNumbersLineSaysWeightForReps() {
        #expect(FinishedWorkoutWords.dataLine([(80, 8), (80, 8), (82.5, 6)], unit: .kilograms)
            == "80 for 8, 80 for 8, 82.5 for 6")
    }

    @Test func theBestSetIsTheOneWithTheHighestEstimatedMax() {
        #expect(FinishedWorkoutWords.bestIndex([(80, 8), (82.5, 6), (85, 3)]) == 0)
        #expect(FinishedWorkoutWords.bestIndex([]) == nil)
    }

    @Test @MainActor func aWorkoutFromAPrivateRoutineIsPrivate() throws {
        let container = TesseraSchema.makeContainer(inMemory: true)
        let model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        let routine = try #require(model.todaysRoutine())
        try model.engine.perform(RenameObject(object: routine.id, title: "Knee rehab day"), by: .user)
        let workout = try model.engine.perform(StartRoutine(routine: routine.id, time: AppClock.now), by: .user).output
        #expect(FinishedWorkoutPage.privateLabel(of: workout, model: model) == ObjectPrivacy.routineLabel)
    }

    @Test @MainActor func aPlainWorkoutIsNotPrivate() throws {
        let container = TesseraSchema.makeContainer(inMemory: true)
        let model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        let routine = try #require(model.todaysRoutine())
        let workout = try model.engine.perform(StartRoutine(routine: routine.id, time: AppClock.now), by: .user).output
        #expect(FinishedWorkoutPage.privateLabel(of: workout, model: model) == nil)
    }

    @Test @MainActor func aPrivateWordInTheNotesKeepsThemOffThePage() {
        let container = TesseraSchema.makeContainer(inMemory: true)
        let model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        #expect(ObjectPrivacy.isPrivateWord("my therapy session went long", in: model.store))
        #expect(!ObjectPrivacy.isPrivateWord("felt strong today", in: model.store))
    }

    @Test func theSwitchShipsOff() throws {
        let choice = try #require(ReviewChoices.all.first { $0.id == "pagesV2" })
        #expect(choice.defaultValue == "Off")
        #expect(choice.readiness == .live)
    }
}
