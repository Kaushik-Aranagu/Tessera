@testable import Tessera
import TesseraCore
import TesseraTess
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
        // A name of his own: never touched.
        routine.title = "Bench day"
        _ = await model.nameTrainingDays()
        #expect(routine.title == "Bench day")
        // The starter's stock title ("Push A") is not a name he chose: Tess names it once.
        routine.title = "Push A"
        let named = await model.nameTrainingDays()
        #expect(named.contains("Push day") && routine.title == "Push day")
        // Named once; asked again only when its exercises change.
        #expect(await model.nameTrainingDays().isEmpty)
        // He renames it: Tess stops for good.
        routine.title = "Chest and shoulders"
        #expect(await model.nameTrainingDays().isEmpty && routine.title == "Chest and shoulders")
    }

    /// QA on #1170: the app's namer reads the phone's model, so a phone that has it never asks Claude; with no
    /// on-device closure yet it takes the rule name.
    @Test func aPhoneWithItsOwnModelNeverAsksClaude() async throws {
        let model = AppModel(context: TesseraSchema.makeContainer(inMemory: true).mainContext)
        #expect(model.dayNamer.onDeviceAvailable() == DayNamingSwitch.onDeviceModelReady())
        try ExerciseLibraryInstaller.install(shape: ExerciseLibraryInstaller.chosenShape, store: model.store,
                                             classes: model.classes)
        try StarterContent.installIfNeeded(store: model.store, classes: model.classes)
        let plan = try #require(model.store.object(id: StarterContent.planID))
        let routine = try #require(model.store.linkedObjects("routines", of: plan).first { $0.title == "Push A" })
        routine.title = "New routine"
        let namer = model.dayNamer
        var claudeAsked = false
        namer.allowed = { claudeAsked = true
            return true
        }
        namer.onDeviceAvailable = { true }
        let suggestion = try #require(await namer.suggest(for: routine, engine: model.engine))
        #expect(suggestion.source == .rules && suggestion.name == "Push day")
        #expect(!claudeAsked, "Claude's gate was read on a phone with its own model")
    }
}
