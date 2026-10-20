@testable import Tessera
import TesseraCore
import Testing

/// "Tess names training days": the Review row and its switch read (Core's #1160).
@MainActor
struct DayNamingTests {
    @Test func theRowIsLiveOnByDefaultAndOnWorkout() throws {
        let row = try #require(ReviewChoices.all.first { $0.id == DayNames.reviewKey })
        #expect(row.name == "Tess names training days")
        #expect(row.defaultValue == "On" && row.values == ["On", "Off"])
        #expect(row.readiness == .live && !row.needsClaude)
        let workout = try #require(ReviewChoices.drawnPages().first { $0.word == "Workout" })
        #expect(workout.rows.contains { $0.id == DayNames.reviewKey })
    }

    @Test func onlyOffStopsIt() {
        #expect(DayNamingSwitch.isOn("On"))
        #expect(DayNamingSwitch.isOn(nil))
        #expect(!DayNamingSwitch.isOn("Off"))
    }

    @Test func aPlaceholderRoutineGetsARuleNameAndHisNameStopsIt() async throws {
        let model = AppModel(context: TesseraSchema.makeContainer(inMemory: true).mainContext)
        try ExerciseLibraryInstaller.install(shape: ExerciseLibraryInstaller.chosenShape, store: model.store,
                                             classes: model.classes)
        try StarterContent.installIfNeeded(store: model.store, classes: model.classes)
        let plan = try #require(model.store.object(id: StarterContent.planID))
        let routine = try #require(model.store.linkedObjects("routines", of: plan).first { $0.title == "Push A" })
        // His own name: never touched.
        #expect(await model.nameTrainingDays().isEmpty && routine.title == "Push A")
        // A placeholder title: Tess names it once from its exercises (no Claude on a throwaway store).
        routine.title = "New routine"
        #expect(await model.nameTrainingDays() == ["Push day"])
        #expect(routine.title == "Push day")
        #expect(await model.nameTrainingDays().isEmpty)
        // He renames it: Tess stops for good.
        routine.title = "Chest and shoulders"
        #expect(await model.nameTrainingDays().isEmpty && routine.title == "Chest and shoulders")
    }
}
