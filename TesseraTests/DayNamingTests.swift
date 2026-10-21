import Foundation
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
        #expect(row.readiness == .live && row.needsClaude)
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
        // Push B is stock too and asks for the same plain name; whichever goes first has it, the other gets another.
        #expect(named.contains(routine.title) && routine.title != "Push A" && DayNames.isUsable(routine.title),
                "\(routine.title) \(named)")
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
        #expect(suggestion.source == .rules && suggestion.name == "Heavy chest")
        #expect(!claudeAsked, "Claude's gate was read on a phone with its own model")
    }

    /// QA on #1170: a pass cancelled while its call was out applies nothing.
    @Test func aCancelledPassAppliesNothing() async throws {
        #expect(DayNamingSwitch.mayApply(cancelled: false))
        #expect(!DayNamingSwitch.mayApply(cancelled: true))
        let model = AppModel(context: TesseraSchema.makeContainer(inMemory: true).mainContext)
        try ExerciseLibraryInstaller.install(shape: ExerciseLibraryInstaller.chosenShape, store: model.store,
                                             classes: model.classes)
        try StarterContent.installIfNeeded(store: model.store, classes: model.classes)
        let plan = try #require(model.store.object(id: StarterContent.planID))
        let routine = try #require(model.store.linkedObjects("routines", of: plan).first { $0.title == "Push A" })
        routine.title = "New routine"
        let pass = Task { @MainActor in
            withUnsafeCurrentTask { $0?.cancel() }
            return await model.nameTrainingDays()
        }
        #expect(await pass.value.isEmpty)
        #expect(routine.title == "New routine")
    }

    /// The on-device reply is tidied to the name, and anything Core's checks refuse falls back (nil).
    @Test func theOnDeviceReplyIsCheckedLikeClaudes() {
        #expect(DayNamingPrompt.cleaned("Heavy pull.\n") == "Heavy pull")
        #expect(DayNamingPrompt.cleaned("\"Back and biceps\"") == "Back and biceps")
        #expect(DayNamingPrompt.cleaned("The ultimate monster pump day!") == nil)
        #expect(DayNamingPrompt.cleaned("") == nil)
    }

    /// Only exercise names, muscle words and names to avoid go to the model.
    @Test func theFactsCarryOnlyThePack() throws {
        let model = AppModel(context: TesseraSchema.makeContainer(inMemory: true).mainContext)
        try ExerciseLibraryInstaller.install(shape: ExerciseLibraryInstaller.chosenShape, store: model.store,
                                             classes: model.classes)
        try StarterContent.installIfNeeded(store: model.store, classes: model.classes)
        let plan = try #require(model.store.object(id: StarterContent.planID))
        let routine = try #require(model.store.linkedObjects("routines", of: plan).first { $0.title == "Push A" })
        let pack = try #require(DayNames.pack(of: routine, store: model.store))
        let facts = DayNamingPrompt.facts(pack, avoid: ["Push day"])
        let data = try #require(facts.dropFirst("<facts>".count).dropLast("</facts>".count).data(using: .utf8))
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(Set(object.keys) == ["avoid", "exercises", "muscles"])
        #expect(object["exercises"] as? [String] == pack.exercises)
    }

    @Test func theAppPlugsTheOnDeviceNamer() {
        let model = AppModel(context: TesseraSchema.makeContainer(inMemory: true).mainContext)
        #expect(model.dayNamer.onDevice != nil)
    }

    /// Product on #1174: the instructions lead with specific names; the plain split comes last, as a fallback.
    @Test func specificNamesComeBeforeThePlainSplit() throws {
        let words = DayNamingPrompt.instructions
        let specific = try #require(words.range(of: "Heavy chest"))
        let plain = try #require(words.range(of: "fall back to a plain split"))
        #expect(specific.lowerBound < plain.lowerBound)
        #expect(words.contains("1 to 3 words, 22 characters or fewer"))
    }
}
